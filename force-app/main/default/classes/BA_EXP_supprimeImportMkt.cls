//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_EXP_supprimeImportMkt
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/07/2020
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
global class BA_EXP_supprimeImportMkt implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    private static final Id RT_IMPORT_EXTERNE        = DAL.getRecordTypeIdByDevName('Import__c', Constants.RT_IMPORT_EXTERNE);
    private static final Id RT_FICHE_CONTACT         = DAL.getRecordTypeIdByDevName('Import__c', Constants.RT_IMPORT_CONTACT);
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_EXP_supprimeImportMkt() {
        UserContext userCtx = UserContext.getContext(); 
        userCtx.setByPassValidationRules(true);
        userCtx.setByPassWorkflowRules(true);
        userCtx.setByPassTriggers(true); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;
        
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_EXP_supprimeImportMkt');
        }
    }

    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        System.debug('### DEBUT BA_EXP_supprimeImportMkt : start');        
        
        try {
            if (!PropertiesUtils.getBooleanValue('maintenance.ImportMktASupprimer', Test.isRunningTest())){
                batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);
                return Database.getQueryLocator([SELECT id, RecordTypeId FROM Import__c WHERE isDeleted = FALSE LIMIT 2]);
            }
            EmailUtils.mailToITSupport('[KUBE] Exploitation : Suppression des imports marketing','Début des traitements.\n\nCordialement\n');
            Integer delaiSupprImport = (Test.isRunningTest()) ? 1 : PropertiesUtils.getIntegerValue('maintenance.delaiSuppressionImportMkt', -8) ;
            Date dateRef = Date.today().addDays(delaiSupprImport);
            DateTime dateTimeRef = DateTime.newInstance(dateRef, Time.newInstance(0, 0, 0, 0));
            System.debug('## dateTimeRef : '+dateTimeRef);

            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT Id, RecordTypeId, CreatedDate, Name,
                                                    versioningCompte__c, compte__r.lastModifiedDate,
                                                    versioningChantier__c, chantier__r.lastModifiedDate,
                                                    versioningProjet__c, projet__r.lastModifiedDate,
                                                    versioningRDV__c, idRDV__c
                                             FROM Import__c
                                             WHERE isDeleted = false
                                               AND dateIntegration__c <= :dateTimeRef]);
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            System.debug('## it.hasNext() : '+it.hasNext());     
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_EXP_supprimeImportMkt : start');     
            return results;
        } 
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Exploitation : Suppression des imports marketing : Erreur lors de l\'initialisation du batch', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        } 
    }

     /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param imports Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<Import__c> imports) {
        System.debug('### DEBUT BA_EXP_supprimeImportMkt : execute');    
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, imports.size());
        System.debug('## scope (' + imports.size() +')');

        try {
            if (!imports.isEmpty()) {
                List<Import__c> importsToDelete = new List<Import__c>();
                Set<ID> RDVIds = new Set<ID>();
                
                for (Import__c item : imports) {
                    System.debug('## item.RecordTypeId : '+item.RecordTypeId);
                    System.debug('## item : '+item);
                    if (item.RecordTypeId == RT_IMPORT_EXTERNE)
                       importsToDelete.add(item);
                    else if (item.RecordTypeId == RT_FICHE_CONTACT) {
                         if (item.versioningCompte__c   != item.compte__r.LastModifiedDate.getTime()   ||
                             item.versioningChantier__c != item.chantier__r.LastModifiedDate.getTime() ||
                             item.versioningProjet__c   != item.projet__r.LastModifiedDate.getTime())
                             importsToDelete.add(item);
                         else if (item.idRDV__c != null)
                              RDVIds.add(item.idRDV__c);
                    }
                }
        
                if (!RDVIds.isEmpty()) {
                    Map<ID, Event> rMap = new Map<ID, Event>([SELECT id, LastModifiedDate FROM Event WHERE id IN :RDVIds]);
                    for (Import__c item : imports) {
                        if (item.RecordTypeId == RT_FICHE_CONTACT && item.idRDV__c != null) {
                           Event RDV = rMap.get(item.idRDV__c);
                           if (RDV != null && item.versioningRDV__c != RDV.LastModifiedDate.getTime())
                              importsToDelete.add(item);
                        }
                    }
                }

                batchHistoryStored.nombreATraiter__c += importsToDelete.size();
                if (!importsToDelete.isEmpty()) {
                    Database.DeleteResult[] results = Database.delete(importsToDelete, false);

                    if(Test.isRunningTest())
                        results.addAll(Utils_HistoriqueBatchs.changeDeleteResult(results, importsToDelete));
           
                   for (Integer index = 0; index < results.size(); index++) {
                        Database.DeleteResult result = results[index];
                        if (!result.isSuccess()) {
                            errorCount++;
                            Import__c importItem = imports[index];                                    
                            errorMessage += errorCount + ' - ' + importItem .Name + ' - ' + importItem .CreatedDate + '\n';
                            for(Database.Error error : result.getErrors()) {
                                errorMessage += '      * ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                            }
                            System.debug('## Error message : '+errorMessage);
                        } else {
                            successCount++;
                        }
                    }
                }
                batchHistoryStored.nombreTraite__c = successCount;
            }
        }
        catch(Exception ex) {
            System.debug('ERREUR : ' + ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Suppression des imports marketing', ex);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
        }
        System.debug('### FIN BA_EXP_supprimeImportMkt : execute'); 
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_EXP_supprimeImportMkt : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Exploitation : Suppression des imports marketing',
                                    'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' imports marketing ont été supprimés.\n\nCordialement\n');
            } 
            if(String.isNotEmpty(errorMessage) || Test.isRunningTest()) {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Exploitation : Suppression des imports marketing',
                                        'Bonjour,\n\n' + batchHistoryStored.nombreATraiter__c + ' imports marketing auraient dû être supprimées.\nCependant, les erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ errorMessage);
            }
        }
        catch(Exception ex) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Suppression des imports marketing', ex);
        }
        
        System.debug('### FIN BA_EXP_supprimeImportMkt : finish');
    }
}