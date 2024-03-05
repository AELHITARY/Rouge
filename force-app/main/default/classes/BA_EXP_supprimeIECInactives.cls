//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_EXP_supprimeIECInactives
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/07/2020
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
global class BA_EXP_supprimeIECInactives implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_EXP_supprimeIECInactives() {
        UserContext userCtx = UserContext.getContext(); 
        userCtx.setByPassValidationRules(true);
        userCtx.setByPassWorkflowRules(true);
        userCtx.setByPassTriggers(true); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_EXP_supprimeIECInactives');
        }
    }

    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {     
        System.debug('### DEBUT BA_EXP_supprimeIECInactives : start');       
        try {
            if (!PropertiesUtils.getBooleanValue('maintenance.instancesASupprimer', Test.isRunningTest())){
                batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);
                return Database.getQueryLocator([SELECT id, Name, nInstance__c FROM KInstance__c WHERE isDeleted = false AND actif__c  = false LIMIT 0]);
            }
            EmailUtils.mailToITSupport('[KUBE] Exploitation : Suppression des instances inactives','Début des traitements.\n\nCordialement\n');

            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT id, Name, nInstance__c FROM KInstance__c
                                              WHERE isDeleted = false
                                                AND actif__c  = false]);
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_EXP_supprimeIECInactives : start');    
            return results;
        } 
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Exploitation : Suppression des instances inactives : Erreur lors de l\'initialisation du batch', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param instances Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<KInstance__c> instances) {
        System.debug('### DEBUT BA_EXP_supprimeIECInactives : execute');    
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, instances.size());
        System.debug('## scope (' + instances.size() +')');

        try {
            if (!instances.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(instances, false);

                if(Test.isRunningTest())
                    results.addAll(Utils_HistoriqueBatchs.changeDeleteResult(results, instances));
            
                for (Integer index = 0; index < results.size(); index++) {
                    Database.DeleteResult result = results[index];
                    if (!result.isSuccess()) {
                        // Traitement des erreurs
                        errorCount++; 
                        for(Database.Error error : result.getErrors()) {
                            errorMessage += '* ' + result.getId() + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                        }
                        System.debug('## Error message : '+errorMessage);
                    } else {
                        successCount++;
                    }
                }
                batchHistoryStored.nombreTraite__c = successCount;
            }  
        }
        catch(Exception ex) {
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : suppression des instances inactives', ex);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
        }
        System.debug('### FIN BA_EXP_supprimeICTInactifs : execute');    
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_EXP_supprimeICTInactifs : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Exploitation : Suppression des instances inactives',
                                     'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' instances(K) ont été supprimées.\n\nCordialement\n');
            } 
            if(String.isNotEmpty(errorMessage) || Test.isRunningTest()) {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Exploitation : Suppression des instances inactives',
                                     'Bonjour,\n\n' + errorCount + ' instances(K) n\'ont pas pu être supprimées.\nLes erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ errorMessage);
            }
        }
        catch(Exception ex) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : suppression des instances inactives', ex);
        }
        
        System.debug('### FIN BA_EXP_supprimeICTInactifs : finish');
    }
}