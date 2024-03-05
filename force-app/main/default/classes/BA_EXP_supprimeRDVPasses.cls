//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_EXP_supprimeRDVPasses
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/07/2020
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
global class BA_EXP_supprimeRDVPasses implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    private static final Id RT_RDVCommercial = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id RT_RDVProspection = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_EXP_supprimeRDVPasses() {
        UserContext userCtx = UserContext.getContext(); 
        userCtx.setByPassValidationRules(true);
        userCtx.setByPassWorkflowRules(true);
        userCtx.setByPassTriggers(true); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;
        
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_EXP_supprimeRDVPasses');
        }
    }

    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {      
        System.debug('### DEBUT BA_EXP_supprimeRDVPasses : start');      
        try {
            if (!PropertiesUtils.getBooleanValue('maintenance.RDVASupprimer', Test.isRunningTest())){
                batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);
                return Database.getQueryLocator([SELECT id FROM Event WHERE isRecurrence = FALSE AND isDeleted = FALSE LIMIT 0]);
            }
            EmailUtils.mailToITSupport('[KUBE] Exploitation : Suppression des rendez-vous passés', 'Début des traitements.\n\nCordialement\n');

            Integer delaiSuppressionRDV = (Test.isRunningTest()) ? -7 : PropertiesUtils.getIntegerValue('maintenanceQuot.delaiSuppressionRDV', -15);
            Date dateRef = Date.today().addDays(delaiSuppressionRDV);
            DateTime dateTimeRef = DateTime.newInstance(dateRef, Time.newInstance(0, 0, 0, 0));
            System.debug('## dateTimeRef : '+dateTimeRef);
            System.debug('## dateRef : '+dateRef);

            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT id
                                                FROM Event
                                                WHERE isRecurrence = false
                                                  AND isDeleted = false
                                                  AND RecordTypeId != :RT_RDVCommercial
                                                  AND RecordTypeId != :RT_RDVProspection                                  
                                                  AND (StartDateTime <= :dateTimeRef OR ActivityDate  <= :dateRef)]);
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_EXP_supprimeRDVPasses : start');    
            return results;
        } 
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Exploitation : Suppression des rendez-vous passés : Erreur lors de l\'initialisation du batch', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        } 
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param rendezvous Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<Event> rendezvous) {
        System.debug('### DEBUT BA_EXP_supprimeRDVPasses : execute');    
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, rendezvous.size());
        System.debug('## scope (' + rendezvous.size() +')');

        try {
            if (!rendezvous.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(rendezvous, false);

                if(Test.isRunningTest())
                    results.addAll(Utils_HistoriqueBatchs.changeDeleteResult(results, rendezvous));

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
        } catch(Exception ex) {
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Suppression des rendez-vous passés', ex);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
        }
        System.debug('### FIN BA_EXP_supprimeRDVPasses : execute');       
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {      
        System.debug('### DEBUT BA_EXP_supprimeRDVPasses : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Exploitation : Suppression des rendez-vous passés',
                                           'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' rendez-vous passés ont été supprimés.\n\nCordialement\n');
            } 
            if(String.isNotEmpty(errorMessage) || Test.isRunningTest()) {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Exploitation : Suppression des rendez-vous passés',
                                               'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' rendez-vous passés ont été supprimés.\nLes erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                    Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ errorMessage);
            }
        }
        catch(Exception ex) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Suppression des rendez-vous passés', ex);
        }
        
        System.debug('### FIN BA_EXP_supprimeRDVPasses : finish');
    }
}