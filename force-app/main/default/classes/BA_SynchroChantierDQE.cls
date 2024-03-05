//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_SynchroChantierDQE
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/07/2018
//-- Version     : 1.2
//-- * 1.2 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.1 : Ajout filtre sur la date de modification
//-- --------------------------------------------------------------------------------- --
global class BA_SynchroChantierDQE implements Database.Batchable<sObject>, Database.Stateful {
    private static final Boolean EMAIL_ENABLED = PropertiesUtils.getBooleanValue('dqe.dedup.sync.email.enabled', true);
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_SynchroChantierDQE (){
        if (this.batchHistoryStored == null){
            // Création de l'historique de batch
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_SynchroChantierDQE');
        }
    }
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Integer dayDelayMin = PropertiesUtils.getIntegerValue('dqe.synchro.delai.reprise', 7);
        Datetime dateDelayMin = Datetime.now().addDays(-dayDelayMin); // Traite pas les enregistrements vieux de plus de X jours
        
        try {
            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT Id, aSynchroniserDQE__c FROM Chantier__c 
                                             WHERE SystemModstamp >= :dateDelayMin
                                               AND aSynchroniserDQE__c != null
                                               AND aSynchroniserDQE__c > 0
                                               AND isDeleted = FALSE]);
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            return results;
        } 
        catch(Exception e) {
            if (EMAIL_ENABLED) EmailUtils.reportException('[KUBE] Batch Synchronisation Chantier : Erreur lors de l\'initialisation du batch', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Chantier__c> scope) {
        system.debug('## Scope size: '+scope.size());  
        try {
            batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());

            if(scope!=null){
                ID jobID = system.enqueueJob(new QA_DQEChantier(scope, 'update', true, batchHistoryStored));
            }
            
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            if (EMAIL_ENABLED) EmailUtils.reportException('[KUBE] Batch Synchronisation Chantier : Erreur lors de la synchronisation des chantiers', e);
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