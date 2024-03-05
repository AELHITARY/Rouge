//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_SigneaCircuit
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/03/2023
//-- Version     : 1.5
//-- * 1.5 : Ajout devis CPQ
//-- * 1.4 : KPKCRM_RQM-54 : Signature électronique des contrats de type Isolation des combles
//-- * 1.3 : Suppression du champ "Circuit de signature"
//-- * 1.2 : Correction des statuts Completed
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_SigneaCircuit {
    
    /**
    * @description Mise à jour des devis lors de la création/modification d'un circuit
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void updateQuotes(UserContext userContext) {
        System.debug('### DEBUT TR022_SigneaCircuit.updateQuotes');
        try {
            // A - Initialisation et alimentation des données intermédiaires
            List<Signea__Circuit__c> newCircuits = (List<Signea__Circuit__c>)Trigger.new;
            Set<Id> quoteIds = new Set<Id>();
            List<Quote> updatedQuotes = new List<Quote>();
            
            // Récupération des devis liés aux circuit de signature
            List<Quote> quotes = [SELECT Id, dateAcceptationClient__c, circuitSignatureDevis__c, circuitSignatureDevis__r.Signea__Status__c, circuitSignatureContrat__r.hasBeenLaunched__c,
                                  circuitSignatureContrat__c, circuitSignatureContrat__r.Signea__Status__c, circuitSignatureContrat__r.lancementAutomatique__c FROM Quote
                                  WHERE circuitSignatureDevis__c IN :newCircuits OR circuitSignatureContrat__c IN :newCircuits];
            
            // B - Traitements
            for (Quote devis : quotes) {
                System.debug('## Id: ' + devis.Id);
                System.debug('## Statut DIPC: ' + devis.circuitSignatureDevis__r.Signea__Status__c);
                System.debug('## Statut Contrat: ' + devis.circuitSignatureContrat__r.Signea__Status__c);
                // Vérification si le circuit de contrat doit être executé ou déjà terminé
                if(((devis.circuitSignatureContrat__r.hasBeenLaunched__c && !devis.circuitSignatureContrat__r.lancementAutomatique__c) || devis.circuitSignatureContrat__r.lancementAutomatique__c) 
                   && devis.circuitSignatureDevis__c != null 
                   && devis.circuitSignatureDevis__r.Signea__Status__c.equalsIgnoreCase('Completed')
                   && devis.circuitSignatureContrat__r.Signea__Status__c == 'Draft')
                {
                    if(!AlreadyUsed.isUsed('TR022_SigneaCircuit', devis.Id) || Test.isRunningTest()) {
                        quoteIds.add(devis.id);
                    }
                } else if(devis.circuitSignatureContrat__c != null && devis.circuitSignatureContrat__r.Signea__Status__c.equalsIgnoreCase('Completed'))
                {
                    if(!AlreadyUsed.isUsed('TR022_SigneaCircuit', devis.Id) || Test.isRunningTest()) {
                        devis.dateAcceptationClient__c = System.today();
                        updatedQuotes.add(devis);
                    }
                }
            }
            
            // C - Execution des circuits de contrat pour les devis dont le circuit est DRAFT
            if(!quoteIds.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Exec circuit contrat: ' + quoteIds);
                System.enqueueJob(new QA_LaunchSigneaCircuits(quoteIds));
            }
            // Mise à jour devis
            if (!updatedQuotes.isEmpty()){
                System.debug('## Up devis: ' + updatedQuotes);
                update updatedQuotes;
            }
            
            System.debug('### FIN TR022_SigneaCircuit.updateQuotes');
        } catch(Exception e) {
            System.debug('ERREUR # Signea : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            EmailUtils.reportException('[KUBE] Erreur déclencheur signature électronique', e);
        }
    }
    
    /**
    * @description Mise à jour des devis lors de la création/modification d'un circuit
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void updateCPQ_Quotes(UserContext userContext) {
        System.debug('### DEBUT TR022_SigneaCircuit.updateCPQ_Quotes');
        try {
            // A - Initialisation et alimentation des données intermédiaires
            List<Signea__Circuit__c> newCircuits = (List<Signea__Circuit__c>)Trigger.new;
            Set<Id> quoteIds = new Set<Id>();
            Set<Id> quoteAmendementsIds = new Set<Id>();
            List<SBQQ__Quote__c> updatedQuotes = new List<SBQQ__Quote__c>();
            
            // Récupération des devis liés aux circuit de signature
            List<SBQQ__Quote__c> quotes = [SELECT Id, dateAcceptationClient__c, circuitSignatureDevis__c, circuitSignatureDevis__r.Signea__Status__c, circuitSignatureContrat__r.hasBeenLaunched__c,
                                           circuitSignatureContrat__c, circuitSignatureContrat__r.Signea__Status__c, circuitSignatureContrat__r.lancementAutomatique__c, AmendmentQuote__c 
                                           FROM SBQQ__Quote__c
                                           WHERE circuitSignatureDevis__c IN :newCircuits OR circuitSignatureContrat__c IN :newCircuits];
            
            System.debug('quotes : ' + quotes);
            // B - Traitements
            for (SBQQ__Quote__c devis : quotes) {
                System.debug('## Id: ' + devis.Id);
                System.debug('## Statut DIPC: ' + devis.circuitSignatureDevis__r.Signea__Status__c);
                System.debug('## Statut Contrat: ' + devis.circuitSignatureContrat__r.Signea__Status__c);
                // Vérification si le circuit de contrat doit être executé ou déjà terminé
                if(((devis.circuitSignatureContrat__r.hasBeenLaunched__c && !devis.circuitSignatureContrat__r.lancementAutomatique__c) || devis.circuitSignatureContrat__r.lancementAutomatique__c) 
                   && devis.circuitSignatureDevis__c != null 
                   && devis.circuitSignatureDevis__r.Signea__Status__c.equalsIgnoreCase('Completed')
                   && (devis.circuitSignatureContrat__r.Signea__Status__c == 'Draft' || devis.circuitSignatureContrat__r.Signea__Status__c == 'Launch Failed'))
                {
                    if(!AlreadyUsed.isUsed('TR022_CPQ_SigneaCircuit', devis.Id) || Test.isRunningTest()) {
                        quoteIds.add(devis.id);
                    }
                } else if(devis.circuitSignatureContrat__c != null 
                    && devis.circuitSignatureContrat__r.Signea__Status__c.equalsIgnoreCase('Completed'))
                {
                    if(!AlreadyUsed.isUsed('TR022_CPQ_SigneaCircuit', devis.Id) || Test.isRunningTest()) {
                        devis.dateAcceptationClient__c = System.today();
                        if(devis.AmendmentQuote__c == false) {   
                            updatedQuotes.add(devis);
                        } else {
                            quoteAmendementsIds.add(devis.Id);
                        }
                    }
                }
            }
            
            // C - Execution des circuits de contrat pour les devis dont le circuit est DRAFT
            if(!quoteIds.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Exec circuit contrat: ' + quoteIds);
                System.enqueueJob(new QA_CPQ_LaunchSigneaCircuits(quoteIds));
            }
            // Mise à jour devis
            if (!updatedQuotes.isEmpty()){
                System.debug('## Up devis: ' + updatedQuotes);
                update updatedQuotes;
            }
            if (!quoteAmendementsIds.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Up devis avenants : ' + quoteAmendementsIds);
                System.enqueueJob(new QA_CPQ_UpdateStatusQuoteSold(quoteAmendementsIds));
            }
            
            System.debug('### FIN TR022_SigneaCircuit.updateCPQ_Quotes');
        } catch(Exception e) {
            System.debug('ERREUR # Signea : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            EmailUtils.reportException('[KUBE] Erreur déclencheur signature électronique', e);
        }
    }
}