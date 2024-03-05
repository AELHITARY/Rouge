//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_SObjectPurge
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 05/11/2018
//-- Version     : 1.0
//-- * 1.0 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
global class BA_SObjectPurge implements Database.Batchable<SObject>, Database.Stateful {
    private String objectName;
    global BatchHistory__c batchHistoryStored {get;set;}
    
    public BA_SObjectPurge(String objName) {
        objectName = objName;
        if (this.batchHistoryStored == null){
            // Création de l'historique de batch
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_SObjectPurge_'+objName);
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à supprimer de l'objet 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('### START BA_SObjectPurge_'+objectName+'.start()');
        Database.QueryLocator results;
        
        try {
            Date today = Date.today();
            system.debug('## SObject: '+objectName);
            String soqlQuery = 'SELECT Id FROM '+objectName+' WHERE GDPR_dateExpiration__c < :today AND GDPR_dateExpiration__c != NULL';
            // Ajout de IsRecurrence = false pour TASK et EVENT            
            if(objectName == 'Event' || objectName == 'Task')
                soqlQuery += ' AND IsRecurrence = false';
            // Limite à 100 pour les tests pour éviter erreur de limites Salesforce
            if(Test.isRunningTest())
                soqlQuery += ' LIMIT 100';
            system.debug('## SOQL Query: '+soqlQuery);
            results = Database.getQueryLocator(soqlQuery);

            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);  

            system.debug('### END BA_SObjectPurge_'+objectName+'.start()');
        } 
        catch(Exception e) {
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch de purge de l\'objet '+objectName+': Erreur lors de l\'initialisation du batch', e);
        } 
        return results;
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        system.debug('## Scope size : '+scope.size());  
        system.debug('## Purge : '+scope); 
        Map<String, SObject> mapSObject = new Map<String, SObject>();
        Set<String> sId = new Set<String>();
        List<SObject> sObjectToUpdate = new List<SObject>();
        List<Database.DeleteResult> drList = new List<Database.DeleteResult>();
        Integer successCount = 0;

        try {
            batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());

            // Suppression
            /*if(!scope.isEmpty()) {
                drList = Database.delete(scope, false);
                Database.emptyRecycleBin(scope);     
                if(Test.isRunningTest())
                    Utils_HistoriqueBatchs.changeDeleteResult(drList, scope);       
            }
            
            // Verification des erreurs à la suppression
            for(Database.DeleteResult dr : drList) {
                if (!dr.isSuccess()){
                    sId.add('\''+dr.getId()+'\'');
                    batchHistoryStored = Utils_HistoriqueBatchs.updateTraceError(batchHistoryStored, dr.getId() + ': '+ dr.getErrors()[0].getStatusCode()+'\n');
                } else {
                    successCount++;
                }
            }
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;

            // Traitement des erreurs pour chaque record
            if(!sId.isEmpty() || Test.isRunningTest()) {
                String GDPR_erreurs = 'GDPR_erreurs__c';
                String GDPR_dernierEssai = 'GDPR_dernierEssai__c';
                String GDPR_nombreEssais = 'GDPR_nombreEssais__c';
                for(SObject record : database.query('SELECT ' + GDPR_erreurs + ', ' + GDPR_dernierEssai +', ' + GDPR_nombreEssais 
                                                    + ' FROM ' +objectName +' WHERE Id IN :sId')) {
                    mapSObject.put(record.id, record);                             
                }
                // Boucle sur toutes les erreurs
                if(!mapSObject.isEmpty() || Test.isRunningTest()){
                    for(Database.DeleteResult dr : drList) {
                        if (!dr.isSuccess()) {
                            SObject record = mapSObject.get(dr.getId());
                            // Operation échouée, récupération des messages et enregistrement dans les traces
                            for(Database.Error err : dr.getErrors()) {                   
                                record.put(GDPR_erreurs, err.getStatusCode() + ': ' + err.getMessage());
                                record.put(GDPR_dernierEssai, date.today());
                                Integer nbEssai = ((Integer) record.get(GDPR_nombreEssais)) == null ? 1 : (Integer) record.get(GDPR_nombreEssais) +1;
                                record.put(GDPR_nombreEssais, nbEssai);
                                sObjectToUpdate.add(record);
                                System.debug('## ERREUR suppression enregistrement : ' + err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('## Champs de l\'objet affectés par l\'erreur : ' + err.getFields());
                            }
                        }
                    }
                }
            }
            
            if(!sObjectToUpdate.isEmpty())
                update sObjectToUpdate;
            */
        }
        catch(Exception e) {
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch de purge de l\'objet '+objectName+': Erreur lors de l\'execution du batch', e);
        } 
    } 
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {     
        // Mise à jour des stats
        batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
    }
}