//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_QuoteLineItem
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 27/01/2023
//-- Version     : 1.2
//-- * 1.2 : Ajout vérification suppression des lignes
//-- * 1.1 : RQM-47 : Calcul de la prime CEE / Isolation des combles
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public with sharing class TR020_QuoteLineItem {
    
    /**
    * @description Méthode exécutant les différentes règles de validation pour les lignes de devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_QuoteLineItem.applyValidationRules');        
        List<QuoteLineItem> oldQLIs = (List<QuoteLineItem>)Trigger.old;
        List<QuoteLineItem> newQLIs = (List<QuoteLineItem>)Trigger.new;
        List<String> orderItemIds = new List<String>();
                
        for(QuoteLineItem oldQLI : oldQLIs){
            /*if(oldQLI.amendedOrderProduct__c != null && (Trigger.isDelete || Trigger.isUpdate) && Trigger.isBefore){
                orderItemIds.add(oldQLI.amendedOrderProduct__c);
            }*/

            if(oldQLI.quoteLineDeletable__c == false && Trigger.isDelete && Trigger.isBefore) {
                System.debug('## Cannot delete QuoteLine: ' + oldQLI.Id);
                oldQLI.addError(Label.quote_error_cantDeleteQuoteLine);
            }  
        }
        
        // JMU 21/10/2022 : Suprimmée à la demande de Daniel 
        /*
        // Vérification des actifs controlés et création d'une map par ligne
        Map<String, List<Asset>> mapOrderItemAssets = new Map<String, List<Asset>>();
        if(!orderItemIds.isEmpty()) {
            List<Asset> assets = [SELECT Id, controlDate__c, orderItem__c FROM Asset WHERE orderItem__c IN :orderItemIds];
            for(String orderitemId : orderItemIds) {
                List<Asset> assetList = new List<Asset>();
                for(Asset ast : assets) {
                    if(ast.orderItem__c == orderitemId) {
                        assetList.add(ast);
                    }
                }
                mapOrderItemAssets.put(orderitemId, assetList);
            }
        }       
        
        //Interdiction de suppression & de modification
        for(QuoteLineItem oldQLI : oldQLIs){
            // Ne pas supprimer si l'actif est verrouillé
            List<Asset> assets = mapOrderItemAssets.get(oldQLI.amendedOrderProduct__c);
            if(oldQLI.amendedOrderProduct__c != null && assets != null){
                for(Asset assetControlled : assets) {
                    if(assetControlled.controlDate__c != null && Trigger.isDelete && Trigger.isBefore) {
                        oldQLI.addError('La ligne de devis ne peux pas être supprimée car un actif a déjà été contrôlé');
                    } else if(assetControlled.controlDate__c != null && Trigger.isUpdate && Trigger.isBefore) {
                        oldQLI.addError('La ligne de devis ne peux pas être modifiée car un actif a déjà été contrôlé');
                    }
                }
            }
        }*/
        
        System.debug('### FIN TR020_QuoteLineItem.applyValidationRules');
    }

    /**
    * @description Méthode exécutant les différentes règles de mise à jour pour les lignes de devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_QuoteLineItem.applyUpdateRules');
        /*if (!Trigger.isExecuting)
            return;*/

        /** A - Initialisation des données intermédiaires **/
        List<QuoteLineItem> quoteLinesItemsRemise = new List<QuoteLineItem>();
        List<QuoteLineItem> quoteLinesItemsCEE = new List<QuoteLineItem>();
        Map<Id, QuoteLineItem>  oldQuoteLinesItems = (Map<Id, QuoteLineItem>)Trigger.oldMap;
        List<QuoteLineItem> newQuoteLinesItems = (List<QuoteLineItem>)Trigger.new;

        Map<Id, List<Option__c>> options = new Map<Id, List<Option__c>>();
        Map<Id, Quote> quoteList =  new Map<Id, Quote>();
        /*List<String> quoteIdsList =  new List<String>();

        // Récupération des options des QuoteLineItem
        List<Option__c> optionsQuoteLineItemList = DAL.getOptionListByqli(newQuoteLinesItems);
        for (QuoteLineItem newQuoteLineItem : newQuoteLinesItems) {
            quoteIdsList.add(newQuoteLineItem.QuoteId);
        }

        // récupération des devis associés
        quoteList = new Map<Id, Quote>([SELECT Id, Total_TTC_devis__c, TotalTTClignes__c, Remise_Enseigne_Options__c FROM Quote WHERE Id IN :quoteIdsList]);*/

        /** B - Application des règles de mise à jour **/
        for (QuoteLineItem newQuoteLineItem : (List<QuoteLineItem>)Trigger.new) {
            QuoteLineItem oldQuoteLineItem = oldQuoteLinesItems == null ? null : oldQuoteLinesItems.get(newQuoteLineItem.id);
            Decimal remiseVendeurProrata = 0;
            System.debug('## newQuote quantity:'+newQuoteLineItem.Quantity);
            //System.debug('#AlreadyUsed :'+AlreadyUsed.isUsed('TR020_QuoteLineItem.applyUpdateRules', newQuoteLineItem.id));
            if (!AlreadyUsed.isUsed('TR020_QuoteLineItem.applyUpdateRules', newQuoteLineItem.id)) {
                // Remise enseigne
                System.debug('#applyUpdate');
                if ((Trigger.isUpdate && (newQuoteLineItem.tvaPourcentage__c != oldQuoteLineItem.tvaPourcentage__c || newQuoteLineItem.Quantity != oldQuoteLineItem.Quantity))) {
                    quoteLinesItemsRemise.add(newQuoteLineItem);
                }
                // Prime CEE
                /*if ((Trigger.isInsert && newQuoteLineItem.eligibleCEE__c) 
                    || (Trigger.isUpdate && ((newQuoteLineItem.eligibleCEE__c && newQuoteLineItem.eligibleCEE__c != oldQuoteLineItem.eligibleCEE__c) 
                        || (newQuoteLineItem.PricebookEntryId != oldQuoteLineItem.PricebookEntryId && newQuoteLineItem.eligibleCEE__c)))) {
                    quoteLinesItemsCEE.add(newQuoteLineItem);
                } else if(!newQuoteLineItem.eligibleCEE__c)
                    newQuoteLineItem.montantCEE__c = null;*/
                if(!newQuoteLineItem.eligibleCEE__c)
                    newQuoteLineItem.montantCEE__c = null;
                else 
                    quoteLinesItemsCEE.add(newQuoteLineItem);
            }
        }

        // Calcul de la remise
        System.debug('## remise:'+quoteLinesItemsRemise);
        if (!quoteLinesItemsRemise.isEmpty()) {
            setQLIRemiseEnseigne(quoteLinesItemsRemise);
        }

        // Calcul de la prime CEE
        if (!quoteLinesItemsCEE.isEmpty()) {
            setMontantLignesDevisCEE(quoteLinesItemsCEE);
        }
        System.debug('### FIN TR020_QuoteLineItem.applyUpdateRules');
    }

    /**
    * @description Mise à jour de la remise enseigne pour les lignes de devis
    * @param newQuoteLinesItems Liste des lignes de devis
    */
    private static void setQLIRemiseEnseigne(List<QuoteLineItem> newQuoteLinesItems) {
        system.debug('#### START TR020_QuoteLineItem.setQLIRemiseEnseigne');
        Map<Id, List<Option__c>> options = new Map<Id, List<Option__c>>();
        Map<Id, Quote> quoteList =  new Map<Id, Quote>();
        List<String> quoteIdsList =  new List<String>();

        system.debug('## newQuoteLinesItems:' +newQuoteLinesItems);
        // Récupération des options des QuoteLineItem
        List<Option__c> optionsQuoteLineItemList = DAL.getOptionListByqli(newQuoteLinesItems);
        for (QuoteLineItem newQuoteLineItem : newQuoteLinesItems) {
            List<Option__c> optList = new List<Option__c>();
            for (Option__c opt : optionsQuoteLineItemList) {
                if(opt.ligneDevis__c == newQuoteLineItem.Id)
                    optList.add(opt);
            }
            options.put(newQuoteLineItem.Id, optList);
        }

        /** B - Application des règles de mise à jour **/
        for (QuoteLineItem newQuoteLineItem : newQuoteLinesItems) {
            Decimal remiseEnseigne = 0;

            // Calcul de la remise enseigne
            for(Option__c option : options.get(newQuoteLineItem.Id)){
                if(Utils_Configurator.isRemiseEnseigne(option)) {
                    remiseEnseigne = (remiseEnseigne + ((option.PrixHT__c * newQuoteLineItem.Quantity) * (1 + (newQuoteLineItem.tvaPourcentage__c / 100)))).setScale(2);
                }
            }

            newQuoteLineItem.remise_enseigne__c = remiseEnseigne;
        }
        system.debug('#### END TR020_QuoteLineItem.setQLIRemiseEnseigne');
    }

    /**
    * @description Mise à jour des remises CEE pour les lignes de devis
    * @param newQuoteLinesItems Liste des lignes de devis
    */
    private static void setMontantLignesDevisCEE(List<QuoteLineItem> newQuoteLinesItems) {
        system.debug('#### START TR020_QuoteLineItem.setMontantLignesDevisCEE');
        Set<String> quoteIds = new Set<String>();
        Set<String> pricebookEntryIdList = new Set<String>();
        Set<String> productIdList = new Set<String>();
        Set<String> tvaTypeList = new Set<String>();
        List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
        List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
        List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
        Map<Id, Id> quoteIdToOpportunityId = new Map<Id,Id>();

        List<Quote> quoteList = new List<Quote>();
        for(QuoteLineItem qli : newQuoteLinesItems){
            quoteIds.add(qli.QuoteId);
            pricebookEntryIdList.add(qli.PricebookEntryId);
            system.debug(qli.product2Id);
        }

        Map<ID,PricebookEntry> pricebookEntryList = new Map<ID, PricebookEntry>([SELECT Id, Product2Id FROM PricebookEntry WHERE id IN :PricebookEntryIdList]);
        for(String key : pricebookEntryList.keySet()){
            productIdList.add(pricebookEntryList.get(key).Product2Id);
        }

        // Récupération des primes présentes dans la base
        ceePrimeList = [SELECT Id, dateDebutValidite__c, dateFinValidite__c, categorie__c, montant__c, produit__c, zone__c FROM CEE_Prime__c];
        tvaList = [SELECT Id, Type__c, produit__c, dateDebut__c, dateFin__c, taux__c 
                        FROM TVA_Produit__c
                        WHERE produit__c IN :productIdList];

        for(TVA_Produit__c tva : tvaList){
            tvaTypeList.add(tva.Type__c);
        }

        ceeList = [SELECT Id, type__c, startDate__c, endDate__c, minIncomes__c, maxIncomes__c, personNumber__c, geography__c, heatingModes__c, customerAmount__c, officialAmount__c, incomeType__c
                    FROM ESCIncentive__c
                    WHERE type__c IN :tvaTypeList];

        // Récupération données pour calcul
        quoteList = [SELECT Id, zone__c, categorie__c, dateDevis__c, referenceDate__c, nbPersonnes__c, revenusFiscaux__c, OpportunityId, 
                            Opportunity.Chantier__r.heatingMode__c, Opportunity.Chantier__r.codeDVReference__c 
                    FROM Quote WHERE Id IN :quoteIds];
        for(Quote q : quoteList){
            quoteIdToOpportunityId.put(q.Id, q.OpportunityId);
        }

        List<Id> oppsIdList = quoteIdToOpportunityId.values();
        Map<Id,Opportunity> oppsMap = new Map<Id,Opportunity>([SELECT Id, chantier__r.sectorisation__c, chantier__r.heatingMode__c, chantier__r.codeDVReference__c FROM Opportunity WHERE Id =:oppsIdList]);
        //Map<ID,PricebookEntry> pricebookEntryList = new Map<ID, PricebookEntry>([SELECT Id, Product2Id FROM PricebookEntry WHERE id IN :PricebookEntryIdList]);
        //system.debug('TEST1 : '+ceePrimeList + ' '+pricebookEntryList);
        String DVElligibles = PropertiesUtils.getStringValue('cee.codesDVElligible', null);

        for(Opportunity op : oppsMap.values()){
            System.debug('## op.chantier__r.codeDVReference__c : '+ op.chantier__r.codeDVReference__c);
            System.debug('## op.chantier__r.sectorisation__c : '+ op.chantier__r.sectorisation__c);
        }
        

        //opp = [SELECT Id, chantier__r.heatingMode__c FROM Opportunity WHERE Id = :q.OpportunityId LIMIT 1];
        System.debug('## oppsIdList : '+oppsIdList);
        System.debug('## oppsMap : '+oppsMap);


        // Calcul de la prime CEE
        for(Quote quote : quoteList){
            System.debug('## quote.OpportunityId '+quote.OpportunityId);
            System.debug('## oppsMap.get(quote.OpportunityId) '+oppsMap.get(quote.OpportunityId));
            System.debug('## DVElligibles '+DVElligibles);
            
            Opportunity opportunity = oppsMap.get(quote.OpportunityId);
            if(DVElligibles != null && opportunity != null && opportunity.chantier__r != null  && opportunity.chantier__r.codeDVReference__c != null 
                && DVElligibles.CONTAINS(opportunity.chantier__r.codeDVReference__c))
            {
                //System.debug('quote.Opportunity.Chantier__r.heatingMode__c : '+quote.Opportunity.Chantier__r.heatingMode__c);
                Utils_CEE.setQliCEE(newQuoteLinesItems, quote, ceeList, tvaList, pricebookEntryList);
            } else {
                Utils_CEE.setQliPrimeCEE(newQuoteLinesItems, quote, ceePrimeList, pricebookEntryList);
            }
        }   
        system.debug('#### END TR020_QuoteLineItem.setMontantLignesDevisCEE');
    }
}