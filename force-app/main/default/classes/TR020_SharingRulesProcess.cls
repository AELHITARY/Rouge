//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_SharingRulesProcess
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/11/2022
//-- Version     : 1.4
//-- * 
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_SharingRulesProcess {
    private static ID groupId = [SELECT id FROM Group WHERE Type = 'Organization'].id;
      
    /**
    * @description Méthode appelée par les triggers et pour le batch OpportunityPublicSharing
    * @param opportunityList Liste des projets
    * @param oldOpportunities Liste des projets (ancienne valeurs)
    */
    public static void OpportunityPublicSharingTrigger (List<Opportunity> opportunityList, Map<Id, Opportunity> oldOpportunities) {
        System.debug('### DEBUT TR020_SharingRulesProcess.OpportunityPublicSharingTrigger');       
        List<Opportunity> oppList = new List<Opportunity>();
        for (Opportunity opp : opportunityList) {
            if (!opp.publicSharing__c && !AlreadyUsed.isUsed('TR020_SharingRulesProcess.ChantierPublicSharingTrigger', opp.id)) {
                oppList.add(opp);
            }
        }       
        if (oppList.isEmpty())
            return;            
        try {
            OpportunityPublicSharing(oppList, oldOpportunities, Trigger.isUpdate, Trigger.isAfter);
        } catch(Exception e) {
            throw e;
        }
        System.debug('### FIN TR020_SharingRulesProcess.OpportunityPublicSharingTrigger');
    }
    /**
    * @description Méthode appelée par le batch OpportunityPublicSharing
    * @param opportunityList Liste des projets
    * @param oldOpportunities Liste des projets (ancienne valeurs)
    */
    public static void OpportunityPublicSharingBatch (List<Opportunity> opportunityList, Map<Id, Opportunity> oldOpportunities) {
        try {
            OpportunityPublicSharing(opportunityList, oldOpportunities, false, false);
        } catch(Exception e) {
            throw e;
        }
    }
  
    /**
    * @description Méthode permettant de définir le partage publique des projets
    * @param opportunityList Liste des projets
    * @param oldOpportunities Liste des projets (ancienne valeurs)
    * @param triggerIsUpdate True si le code est exécuté en Trigger Update (modification)
    * @param triggerIsAfter True si le code est exécuté en Trigger After
    */
    private static void OpportunityPublicSharing (List<Opportunity> opportunityList, Map<Id, Opportunity> oldOpportunities, Boolean triggerIsUpdate, Boolean triggerIsAfter) {
        System.debug('### DEBUT TR020_SharingRulesProcess.OpportunityPublicSharing');     
        // Initialisation des données
        List<OpportunityShare> sharesToCreate = new List<OpportunityShare>();
        List<Opportunity> opportunityToUpdate = new List<Opportunity>();
        Integer errorCount = 0;
        String errorMessage;
        System.debug('## opportunityList: '+opportunityList);     
        System.debug('## oldOpportunities: '+oldOpportunities);     
        System.debug('## triggerIsUpdate: '+triggerIsUpdate);     
        System.debug('## triggerIsAfter: '+triggerIsAfter);   

        try {
            // Construction Map des Oppotunités (projet)
            List<Opportunity> opportunitiesList = [SELECT Id, CreatedById, LastModifiedDate, StageName, SystemModstamp, publicSharing__c, callSource__c,
                                  nbTotalContrats__c, nbDevisVendusEnAttente__c, nbDevisVendusEnregistres__c,
                                  nbDevisVendusIncontournables__c, initialQuoteCPQCount__c
                                FROM Opportunity WHERE Id IN :opportunityList];

            /** A - Boucle sur les chantiers pour traitement **/
            for (Opportunity opportunity : opportunitiesList) {
                System.debug('## Opp: '+opportunity.Id+' - '+opportunity.StageName+' - '+opportunity.callSource__c+' - '+opportunity.publicSharing__c);     
                Decimal nbDevisVendu = 0;
                Datetime lastModified = null;

                // Check les champs devis, contrat
                if (opportunity.nbDevisVendusEnAttente__c != null) nbDevisVendu += opportunity.nbDevisVendusEnAttente__c;
                if (opportunity.nbDevisVendusEnregistres__c != null) nbDevisVendu += opportunity.nbDevisVendusEnregistres__c;
                if (opportunity.nbDevisVendusIncontournables__c != null) nbDevisVendu += opportunity.nbDevisVendusIncontournables__c;
                Decimal nbTotalContrats = (opportunity.nbTotalContrats__c != null) ? opportunity.nbTotalContrats__c : 0;
                Decimal nbDevisCPQVendu = (opportunity.initialQuoteCPQCount__c != null) ? opportunity.initialQuoteCPQCount__c : 0;
                System.debug('## nbDevisVendu: '+nbDevisVendu);   
                System.debug('## nbDevisCPQVendu: '+nbDevisCPQVendu);   
                System.debug('## nbTotalContrats: '+nbTotalContrats);   

                // Initialise date de Derniere modification en fonction de la méthode de lancement (trigger ou schedule)
                if(triggerIsUpdate && triggerIsAfter) {
                    lastModified = oldOpportunities.get(opportunity.Id).SystemModStamp;
                } else {
                    lastModified = opportunity.SystemModStamp;
                }
                System.debug('## lastModified: '+lastModified);  

                /** B - Critères de partage **/
                if (opportunity.StageName == 'Reporté' || opportunity.StageName == 'Vendu' || opportunity.StageName == 'Refus'  /** OPSR-01 - Le projet est dans l'une des étapes suivantes "Reporté", "Vendu", "Refus" **/
                    || (opportunity.callSource__c != null && !(opportunity.callSource__c.startsWith('26')) && !(opportunity.callSource__c.startsWith('15')) &&(lastModified <= Datetime.now().addDays(-30)))   /** OPSR-02 - Le projet n'a pas été modifié depuis 30 jours si origine du call du compte ne commence par par 26- ou 15- **/
                    || (opportunity.callSource__c != null && ((opportunity.callSource__c.startsWith('26')) || (opportunity.callSource__c.startsWith('15'))) && (lastModified <= Datetime.now().addDays(-120))) /** OPSR-02 - Le projet n'a pas été modifié depuis 4 mois si origne du call du compte commence par 26- ou 15-**/
                    || nbDevisVendu > 0 || nbDevisCPQVendu > 0         /** OPSR-03 - Il existe au moins 1 devis vendu **/
                    || nbTotalContrats > 0)                            /** OPSR-04 - Il existe au moins 1 contrat **/
                {
                    // Création de la régle de partage
                    System.debug('## Creation de la regles de partage pour le projet : ' + opportunity.Id);
                    OpportunityShare oppShare = new OpportunityShare();
                    oppShare.OpportunityAccessLevel = 'Edit';
                    oppShare.OpportunityId = opportunity.Id;
                    oppShare.UserOrGroupId = groupId;
                    sharesToCreate.add(oppShare);
                    // Mise à jour du champ publicSharing__c
                    if(!opportunity.publicSharing__c) {
                        opportunity.publicSharing__c = true;
                        opportunityToUpdate.add(opportunity);
                    }
                }
            }

            // Insertion des régles de partage
            if (!sharesToCreate.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(sharesToCreate, false);
                // Vérification des erreurs
                if(Test.isRunningTest()) {
                    results = Utils_HistoriqueBatchs.changeSaveResult(results, sharesToCreate);
                }              
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult result = results[index];
                    if (!result.isSuccess()) {
                        // Traitement des erreurs
                        errorCount++; 
                        for(Database.Error error : result.getErrors()) {
                            errorMessage = '* ' + sharesToCreate.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                        }
                        System.debug('## Error message: '+errorMessage);
                    }
                }
            }
            // Mise à jour des opportunités (Projets) si pas d'erreur sur le partage
            if (!opportunityToUpdate.isEmpty() && errorCount == 0) {
                Database.update(opportunityToUpdate, false);
            }
        } catch(Exception e) {
            System.debug('## ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN TR020_SharingRulesProcess.OpportunityPublicSharing');
    }
}