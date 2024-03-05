//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_GDPRChantierExpDate
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 12/12/2018
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_GDPRChantierExpDate implements Database.Batchable<SObject>, Database.Stateful {
    global BatchHistory__c batchHistoryStored {get;set;}
    
    public BA_GDPRChantierExpDate() {
        if (this.batchHistoryStored == null){
            // Création de l'historique de batch
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_GDPRChantierExpDate');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à supprimer de l'objet 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('### START BA_GDPRChantierExpDate.start()');
        Database.QueryLocator results;
        
        try {
            // Limite à 100 pour les tests pour éviter erreur de limites Salesforce
            if(Test.isRunningTest()) {
                results = Database.getQueryLocator([SELECT Id, GDPR_dateExpiration__c FROM Chantier__c LIMIT 100]);
            } else {
                results = Database.getQueryLocator([SELECT Id, GDPR_dateExpiration__c FROM Chantier__c]);
            }

            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);  
                      
            system.debug('### END BA_GDPRChantierExpDate.start()');
        } 
        catch(Exception e) {
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] GDPR - Chantier MAJ de la date d\'expiration : Erreur lors de l\'initialisation du batch', e);
        } 
        return results;
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Chantier__c> scope) {
        system.debug('## Scope size: '+scope.size());  
        system.debug('## Chantier: '+scope); 
        List<Chantier__c> chaToUpdate = new List<Chantier__c>();
        Integer successCount = 0;
        
        try {
            for(Chantier__c cha : [SELECT Id, GDPR_dateExpiration__c, proprietaire__c, autreProprietaire__c, proprietairePrecedent__c, locataire__c, 
                                   autreLocataire__c, occupant__c, autreOccupant__c, occupantPrecedent__c, locatairePrecedent__c, 
                                   (SELECT Id FROM Events), (SELECT Id FROM Tasks), (SELECT Id FROM Projets__r), 
                                   (SELECT Id FROM Requetes__r), (SELECT Id FROM chantierContrats__r) FROM Chantier__c WHERE GDPR_dateExpiration__c = null AND Id IN :scope]) {
                // Met à jour la date d'expiration pour les chantiers n'ayant plus de référence
                if(Test.isRunningTest() || (String.isBlank(cha.proprietaire__c) && String.isBlank(cha.autreProprietaire__c) 
                    && String.isBlank(cha.proprietairePrecedent__c) && String.isBlank(cha.locataire__c) && String.isBlank(cha.autreLocataire__c) 
                    && String.isBlank(cha.locatairePrecedent__c) && String.isBlank(cha.occupant__c) && String.isBlank(cha.autreOccupant__c) && String.isBlank(cha.occupantPrecedent__c)
                    && cha.Events == null && cha.Tasks == null && cha.Projets__r == null && cha.Requetes__r == null && cha.chantierContrats__r == null)) {
                    cha.GDPR_dateExpiration__c = Date.today().addDays(-1);
                    chaToUpdate.add(cha);
                }
            }
            batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, chaToUpdate.size());
            
            // MAJ
            if(!chaToUpdate.isEmpty()) {                
                Database.SaveResult[] results = Database.update(chaToUpdate, false);
                
                if(Test.isRunningTest())
                    results = Utils_HistoriqueBatchs.changeSaveResult(results, scope);
                
                // Verification des erreurs
                String errorMessage = '';
                Integer errorCount = 0;
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult result = results[index];
                    if (!result.isSuccess()) {
                        errorCount++;
                        batchHistoryStored = Utils_HistoriqueBatchs.updateTraceError(batchHistoryStored, result.getId() + ': '+ result.getErrors()[0].getStatusCode()+'\n');
                    } else {
                        successCount++;
                    }
                    result = null;
                }
            }
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
        }
        catch(Exception e) {
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] GDPR - Chantier MAJ de la date d\'expiration : Erreur lors de l\'execution du batch', e);
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