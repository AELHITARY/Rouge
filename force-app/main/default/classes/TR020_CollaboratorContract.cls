//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_CollaboratorContract 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 18/12/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_CollaboratorContract {

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les contrats collaborateurs
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules() {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('@@@@ CollaboratorContract updaterules Start');
        Map<Id, CollaboratorContract__c> oldMap = (Map<Id, CollaboratorContract__c>)Trigger.oldMap;
        List<Id> collabIds = new List<Id>();
        List<Id> quoteIds = new List<Id>();

        // Parse contracts to list only those having updates in store assignment
        for (CollaboratorContract__c contract : (List<CollaboratorContract__c>)Trigger.new) {
            //process only if store assignment has changed
            if (oldMap.get(contract.Id).assignedTo__c == contract.assignedTo__c) {
                System.debug('@@ contract store assignment has not changed');
                continue;
            }

            if (!collabIds.contains(contract.collaborator__c)) {
                collabIds.add(contract.collaborator__c);
            }
        }

        System.debug('@@@ Need to process ' + collabIds.size() + ' collaborators');
        // List quotes Ids to reprocess
        if (!collabIds.isEmpty()) {
            for (NRV10Commission__c com : [SELECT Id, quoteCPQ__c, quote__c FROM NRV10Commission__c WHERE user__c IN :collabIds]) {
                if (com.quote__c != null && !quoteIds.contains(com.quote__c)) quoteIds.add(com.quote__c);
                if (com.quoteCPQ__c != null && !quoteIds.contains(com.quoteCPQ__c)) quoteIds.add(com.quoteCPQ__c);
            }
        }

        System.debug('@@@ Need to process ' + quoteIds.size() + ' quotes');
        // Launch commissions calculation if needed
        if (!quoteIds.isEmpty()) {
            System.debug('SBQQ__Quote_AfterUpdate launch remVRP commissions calculation for quotes ' + quoteIds);
            QA_QuoteProcessCommissions job = new QA_QuoteProcessCommissions(quoteIds);
            System.enqueueJob(job);
        }

    }

}