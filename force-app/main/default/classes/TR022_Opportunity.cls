//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Opportunity
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 04/03/2019
//-- Version     : 1.0
//-- * 1.0 - Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Opportunity {
    
    /**
    * @description Méthode permettant de réinitialiser la configuration des lignes de devis si le propriétaire du devis a été modifié
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void changeQuoteLineItemConfigurer(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        List<Opportunity> opportunities = (List<Opportunity>) Trigger.new;
        Map<Id, Opportunity>  oldOpportunities = (Map<Id, Opportunity>) Trigger.oldMap;
        List<Id> opportunitiesId = new List<Id>();

        // On récupère les projets dont le propriétaire à changé
        for (Opportunity opportunity : opportunities) {
            Opportunity oldopportunity = oldOpportunities == null ? null : oldOpportunities.get(opportunity.id);

            if(opportunity.OwnerId != oldopportunity.OwnerId) {
                opportunitiesId.add(opportunity.Id);
            }
        }

        // On récupère les Postes de devis seulement des devis avec un statut non final
        if(!opportunitiesId.isEmpty()) {
            List<QuoteLineItem> quoteLineItemList = [SELECT id, Aconfigurer__c
                                                        FROM QuoteLineItem
                                                        WHERE quote.OpportunityId IN :opportunitiesId
                                                        AND quote.Status != :Constants.StatutDevisVenduEnregistre
                                                        AND quote.Status != :Constants.StatutDevisErrone
                                                        AND quote.Status != :Constants.StatutDevisExpire
                                                        AND quote.Status != :Constants.StatutDevisResilie
                                                        AND quote.Status != :Constants.StatutDevisVenduIncontournable
                                                        AND quote.Status != :Constants.StatutDevisVenduAttente
                                                        AND quote.Status != :Constants.StatutDevisTransmis];
            // Modification du flag "A Configurer"
            for (QuoteLineItem quoteItem : quoteLineItemList) {
                quoteItem.Aconfigurer__c = true;
            }

            if(!quoteLineItemList.isEmpty())
                update quoteLineItemList;
        }
    }
    
    /**
    * @description Méthode permettant de mettre à jour la date d'expiration GDPR du compte selon le projet
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void updateAccountStatus(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        try{
            Utils_CalculateStatus.refreshAccountStatusFromOpportunity(Trigger.new);        
        } catch(exception e) {
            system.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
    }
}