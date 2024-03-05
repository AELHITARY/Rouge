//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_Options
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 11/02/2016
//-- Version     : 1.1
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR001_Options {

    public static void calculatePrice(List<Option__c> options) {
        system.debug('#### START TR001_Options.calculatePrice');
        Set<Id> quoteLineItemIds = new Set<Id> ();
        Set<Id> referentielOptionsIds = new Set<Id> ();
        Map<Id, QuoteLineItem> optionLineItem = new Map<Id, QuoteLineItem>();
        Map<Id, ReferentielOptions__c> referentielOptions = new Map<Id, ReferentielOptions__c>();

        for (Option__c opt : options) {
            quoteLineItemIds.add (opt.ligneDevis__c);
            referentielOptionsIds.add (opt.Option__c);
        }

        // SOQL - Récupération des lignes de devis (produits)
        if(!quoteLineItemIds.isEmpty())
            optionLineItem = DAL.getQuoteLineItemMap(quoteLineItemIds);
        // SOQL - Récupération du référentiels des options
        if(!referentielOptionsIds.isEmpty())
            referentielOptions = DAL.getRefOptionsMap(referentielOptionsIds);

        for (Option__c o : options) {
            system.debug('#### Option : ' + o);
            ReferentielOptions__c refOption = referentielOptions.get(o.Option__c);
            if (refOption != null) {
                Double optionType = refOption.Typedeloption__c;
                system.debug('#### Type option : ' + optionType);
  
                // Récupération des données du produit de l'option
        QuoteLineItem quoteLineItem = optionLineItem.get(o.ligneDevis__c);
        if (quoteLineItem != null) {
          Double H = (quoteLineItem.Hauteur__c == null) ? 0 : quoteLineItem.Hauteur__c;
          Double L = (quoteLineItem.Largeur__c == null) ? 0 : quoteLineItem.Largeur__c;
          Double price = (quoteLineItem.unitprice == null) ? 0 : quoteLineItem.unitprice;
          Double vantaux = (quoteLineItem.Nombredevantaux__c == null || quoteLineItem.Nombredevantaux__c.length() == 0) ? 0 : Integer.valueOf(quoteLineItem.Nombredevantaux__c);
    
          o.Valorisation__c = (o.Valorisation__c == null) ? 0 : o.Valorisation__c;
    
          if(Utils_Configurator.isReferencePromotion(refOption))
            continue;
            
          // Calcul du prix de l'option selon son type
          if      (2 == optionType) o.PrixunitaireHT__c = o.Valorisation__c / 100 * price;
          else if (3 == optionType) o.PrixunitaireHT__c = o.Valorisation__c;
          else if (4 == optionType) o.PrixunitaireHT__c = o.Valorisation__c * H * L/10000;
          else if (5 == optionType) o.PrixunitaireHT__c = o.Valorisation__c * L / 100;
          else if (6 == optionType) o.PrixunitaireHT__c = o.Valorisation__c * (H + L) / 100;
          else if (7 == optionType) o.PrixunitaireHT__c = vantaux * o.Valorisation__c;
          else if (8 == optionType) o.PrixunitaireHT__c = o.Valorisation__c * h / 100;
        }
      }
    }
    system.debug('#### END TR001_Options.calculatePrice');
  }
}