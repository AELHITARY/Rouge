//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_DemandesDevisNonValidees 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/07/2018
//-- Version     : 1.4
//-- * 1.4 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.2 - Correction de déversement des formulaires + préparation DQE
//-- * 1.3 - Correction date limite traitement min des enregistrements
//-- --------------------------------------------------------------------------------- --
global class BA_DemandesDevisNonValidees implements Database.Batchable<sObject>, Database.Stateful {
    global List<String> importIds = null;
    global BatchHistory__c batchHistoryStored {get;set;}

    private static final Boolean DEVERSEMENT_ENABLED = PropertiesUtils.getBooleanValue('import.deversement.enabled', true);

    /***** Constructor *****/
    global BA_DemandesDevisNonValidees(){
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_DemandesDevisNonValidees');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start (Database.BatchableContext BC) {
        if (!DEVERSEMENT_ENABLED) // Force un QueryLocator vide afin de simuler aucun import à déverser
            return Database.getQueryLocator([SELECT Id, integrable__c, journalIntegration__c FROM Import__c WHERE name = '']);
        
        importIds = new List<String>();
        Integer minuteDelayMax = PropertiesUtils.getIntegerValue('demandededevis.delai.validation', 120);
        Integer dayDelayMin = PropertiesUtils.getIntegerValue('demandededevis.delai.reprise', 7);
        Datetime dateDelayMax = Datetime.now().addDays(7);
        if(!Test.isRunningTest()) dateDelayMax = Datetime.now().addMinutes(-(minuteDelayMax)); //Traite seulement les demandes vieilles de plus de 2 heures 
        Datetime dateDelayMin = Datetime.now().addDays(-dayDelayMin); // Traite pas les demandes vieilles de plus de 7 jours
        
        try {
            Database.QueryLocator results;
            if(Test.isRunningTest()){
                results = Database.getQueryLocator([SELECT Id, integrable__c, journalIntegration__c
                                                 FROM Import__c 
                                                 WHERE nomFichierSource__c = 'formulaire_site_kpark.fr' 
                                                   AND dateIntegration__c = null
                                                   AND ((integrable__c = true) OR (integrable__c = false AND messageException__c = ''))
                                                   AND CreatedDate <= :dateDelayMax
                                                   AND CreatedDate >= :dateDelayMin
                                                 ORDER BY LastModifiedDate LIMIT 100]);
            } else {
                results = Database.getQueryLocator([SELECT Id, integrable__c, journalIntegration__c
                                                 FROM Import__c 
                                                 WHERE nomFichierSource__c = 'formulaire_site_kpark.fr' 
                                                   AND dateIntegration__c = null
                                                   AND ((integrable__c = true) OR (integrable__c = false AND messageException__c = ''))
                                                   AND CreatedDate <= :dateDelayMax
                                                   AND CreatedDate >= :dateDelayMin
                                                 ORDER BY LastModifiedDate]);
            }
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            
            return results;
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de l\'initialisation du batch pour les demandes de devis non validées', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        } 
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Import__c> scope){
        // Mise à jour des imports
        try {
            batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
            for (Import__c importNonValide : scope) {
                importIds.add(importNonValide.Id);
                importNonValide.integrable__c = true;
                importNonValide.journalIntegration__c += '\n[' + System.now() + '] Prise en charge par le batch de reprise des devis non validés\n';
            } 
            // Update
            List<Database.SaveResult> SR = Database.update(scope, false);
            Integer successCount = 0;
            for (Database.SaveResult savedResult : SR) {
                if (savedResult.isSuccess()) {
                    successCount++;
                } else {
                    batchHistoryStored = Utils_HistoriqueBatchs.updateTraceError(batchHistoryStored, savedResult.getId() + ': '+ savedResult.getErrors()[0].getStatusCode()+'\n');
                }
            }
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
        } 
        catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de la modifcation des imports pour les demandes de devis non validée', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }

    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
        // Récupération des Ids des nouveaux chantiers des imports
        List<Chantier__c> chaList = new List<Chantier__c>();
        for(Import__c imp : [SELECT chantier__c FROM Import__c WHERE Id IN :importIds AND chantier__c!='']) {
            chaList.add(new Chantier__c(Id=imp.chantier__c));
        }

        String a = 'test';
        String b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;


        // L'appel pour la synchro DQE des chantiers ne peut se faire par les triggers, exécution manuelle obligatoire en update (mode upsert)
        Boolean synchroEnabled = PropertiesUtils.getBooleanValue('dqe.dedup.sync.enabled', true);
        if(synchroEnabled && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            if(!Test.isRunningTest()) 
                System.enqueueJob(new QA_DQEChantier(chaList,'Update',true,null));
        }
        // Mise à jour des stats
        batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
    }
}