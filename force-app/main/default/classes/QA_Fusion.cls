//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_Fusion 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/07/2018
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_Fusion implements Queueable {

    public void execute(QueueableContext context){
        system.debug('### START QA_Fusion.execute()');
        TacheFusion__c tskFuActuelle = null;
        Map<String, String> accToMerge = new Map<String, String>();
        Map<String, String> chaToMerge = new Map<String, String>();
        Map<String, TacheFusion__c> tskToOperate = new Map<String, TacheFusion__c>();
        BatchHistory__c batchHistoryStored = new BatchHistory__c();
        try {
            // Vérification de l'objet pour fusion
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('QA_Fusion');
            Integer nbLimit = PropertiesUtils.getIntegerValue('dqe.merge.batchFusion.limit',5);
            for (TacheFusion__c tskFu : [SELECT Id,IDConserve__c,IDSupprime__c,objet__c FROM TacheFusion__c 
                                                WHERE estTermine__c = false AND IDConserve__c!=null AND IDSupprime__c!=null LIMIT :nbLimit]) {
                tskFuActuelle = tskFu;
                tskFu.dateFusion__c=Datetime.now();
                tskFu.estTermine__c=true;
                if(tskFu.objet__c=='Compte') 
                    accToMerge.put(tskFu.IDConserve__c, tskFu.IDSupprime__c);
                if(tskFu.objet__c=='Chantier') 
                    chaToMerge.put(tskFu.IDConserve__c, tskFu.IDSupprime__c);
                tskToOperate.put(tskFu.IDConserve__c, tskFu);
            } 
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            tskFuActuelle = null;
            batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, accToMerge.size()+chaToMerge.size());
            // Fusion des enregistrements - Account
            if(!accToMerge.isEmpty()) {
                Map<String, Account> accMap = new Map<String, Account>([SELECT Id, IsPersonAccount FROM Account WHERE Id IN :accToMerge.keySet()]);
                for(String accId : accToMerge.keySet()) {
                    system.debug('## Compte ID Maitre : '+accId);
                    system.debug('## Compte ID Slave : '+accToMerge.get(accId));
                    tskFuActuelle = tskToOperate.get(accId);
                    Account acc = new Account(Id=accId);
                    Utils_Dedoublonnage.autoMergeAccount(acc,accToMerge.get(accId),accMap.get(accId).IsPersonAccount,false);
                }
            }
            tskFuActuelle = null;
            // Fusion des enregistrements - Chantier__c         
            if(!chaToMerge.isEmpty()) {
                for(String chaId : chaToMerge.keySet()) {
                    system.debug('## Chantier ID Maitre : '+chaId);
                    system.debug('## Chantier ID Slave : '+chaToMerge.get(chaId));
                    tskFuActuelle = tskToOperate.get(chaId);
                    Chantier__c cha = new Chantier__c(Id=chaId);
                    Utils_Dedoublonnage.autoMergeChantier(cha,chaToMerge.get(chaId),false);
                }
            }
            tskFuActuelle = null;
            // Update tache fusion
            String errorMessage = '';
            Integer errorCount = 0;
            Integer successCount = 0;
            Database.SaveResult[] results = Database.update(tskToOperate.values(), false);

            if(Test.isRunningTest())
                results = Utils_HistoriqueBatchs.changeSaveResult(results, tskToOperate.values());
        
            for (Integer index = 0; index < results.size(); index++) {
                Database.SaveResult result = results[index];
                if (!result.isSuccess()) {
                    errorCount++;
                    TacheFusion__c tache = tskToOperate.values()[index];                       
                    errorMessage += errorCount + ' - ' + tache + '\n';
                    for(Database.Error error : result.getErrors()) {
                        errorMessage += '      * ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                    }
                    batchHistoryStored.traceErreurs__c += errorCount + ' - ' + tache + '\n';
                } else {
                    successCount++;
                }
            } 
            batchHistoryStored.nombreTraite__c = successCount;
            batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored); 
        } catch(Exception e) {
            EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de l\'exécution du batch de fusion', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            if(tskFuActuelle != null){
                tskFuActuelle.dateFusion__c=null;
                tskFuActuelle.erreur__c = e.getMessage();
                tskFuActuelle.exception__c=e.getTypeName();
                tskFuActuelle.trace__c=e.getStackTraceString();
                update tskFuActuelle;
                // Relance du batch (Sauf en TEST car impossible limite Salesforce)
                if(!Test.isRunningTest() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()))
                    system.enqueueJob(new QA_Fusion());
            }           
            //throw e;
        }
        system.debug('### END QA_Fusion.execute()');
    }
}