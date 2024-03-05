//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_EXP_expireDevis
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/07/2020
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
global class BA_EXP_expireDevis implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_EXP_expireDevis() {
        UserContext userCtx = UserContext.getContext(); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;

        userCtx.setByPassValidationRules(true);
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_EXP_expireDevis');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        System.debug('### DEBUT BA_EXP_expireDevis : start');
        try {
            if (!PropertiesUtils.getBooleanValue('maintenance.devisAExpirer', Test.isRunningTest())){
                batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);
                return Database.getQueryLocator([SELECT id, expirationDate, status FROM Quote WHERE status = :Constants.StatutDevisVenduAttente LIMIT 0]);
            }

            EmailUtils.mailToITSupport('[KUBE] Exploitation : Expirations des devis', 'Début des traitements.\n\nCordialement\n');           
            Integer DELAI_EXPIRATION_DEVIS = PropertiesUtils.getIntegerValue('maintenanceQuot.delaiExpirationDevis', -30);
            //Integer QUANTITE_EXPIRATION_DEVIS = PropertiesUtils.getIntegerValue('maintenanceQuot.qteExpirationDevis', 1000);
            Date dateExpiration = Date.today().addDays(DELAI_EXPIRATION_DEVIS);
            System.debug('## dateExpiration: '+dateExpiration);

            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT id, ExpirationDate, Status
                            FROM Quote
                            WHERE (dateAcceptationClient__c <= :dateExpiration AND Status = :Constants.StatutDevisVenduAttente)
                               OR ((ExpirationDate < LAST_N_DAYS:3 OR 
                                (amendmentQuote__c = :true AND LastModifiedDate < :dateExpiration)) 
                                AND (Status = :Constants.StatutDevisTransmis    OR
                                Status = :Constants.StatutDevisNonTransmis OR
                                Status = :Constants.StatutDevisAConfigurer))]);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_EXP_expireDevis : start');
            return results;
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Exploitation : Expirations des devis : Erreur lors de l\'initialisation du batch', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param quotes Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<Quote> quotes) {
        System.debug('### DEBUT BA_EXP_expireDevis : execute');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, quotes.size());
        System.debug('## scope (' + quotes.size() +')');

        try {
            if (!quotes.isEmpty()) {
                for (Quote quote : quotes) {
                    quote.Status = Constants.StatutDevisExpire;
                }  
                Database.SaveResult[] results = Database.update(quotes, false);

                if(Test.isRunningTest()) {
                    results = Utils_HistoriqueBatchs.changeSaveResult(results, quotes);
                }
            
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult result = results[index];
                    if (!result.isSuccess()) {
                        errorCount++; 
                        // Traitement des erreurs
                        errorCount++; 
                        for(Database.Error error : result.getErrors()) {
                            errorMessage += '* ' + quotes.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                        }
                        System.debug('## Error message : '+errorMessage);
                    } else {
                        successCount++;
                    }
                } 
                batchHistoryStored.nombreTraite__c = successCount;
            }       
        }
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Expirations des devis', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
        }
        System.debug('### FIN BA_EXP_expireDevis : execute');
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_EXP_expireDevis : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Exploitation : Expirations des devis',
                                    'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' devis ont expiré à ' + Date.today().format() + '.\n\nCordialement\n');
            } else {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Exploitation : Expirations des devis',
                                    'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' devis ont expiré à ' + Date.today().format() + '.\n' + errorCount + ' devis n\'ont pas pu être expirés le ' + Date.today().format() + '.\nLes erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage);
            }
        }
        catch(Exception e) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Expirations des devis', e);
        }
        
        System.debug('### FIN BA_EXP_expireDevis : finish');
    }
}