//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Quote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/07/2018
//-- Version     : 1.4
//-- * 1.4 : RQM-68 : Évolutions sur le PDF et Bonus Projet
//-- * 1.3 : RQM-47 : Calcul de la prime CEE / Isolation des combles
//-- * 1.2 : Migration des fonctions de la classe TR003_SetRemisesDevis
//-- * 1.1 : Correction du bug de sélection du bonus projet
//-- --------------------------------------------------------------------------------- --
public with sharing class TR022_Quote {

    /** 01 - Méthode appelée par le trigger **/
    public static void changeQuoteLineItemConfigurer(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        List<Quote> quotes = (List<Quote>) Trigger.new;
        Map<Id, Quote>  oldQuotes = (Map<Id, Quote>) Trigger.oldMap;
        List<Quote> quotesId = new List<Quote>();

        // On récupère les devis dont la date du devis ou l’origine ont changés
        for (Quote quote : quotes) {
            Quote oldquote = oldQuotes == null ? null : oldQuotes.get(quote.id);

            if (((quote.dateDevis__c != oldquote.dateDevis__c) || (quote.source__c != oldquote.source__c)) && 
                quote.Status != Constants.StatutDevisVenduEnregistre &&
                quote.Status != Constants.StatutDevisErrone &&
                quote.Status != Constants.StatutDevisVenduIncontournable &&
                quote.Status != Constants.StatutDevisVenduAttente &&
                quote.Status != Constants.StatutDevisTransmis)
                quotesId.add(quote);
        }

        // On récupère les Postes de devis seulement des devis avec la date du devis ou l’origine modifiés
        if(!quotesId.isEmpty()) {
            List<QuoteLineItem> quoteLineItemList = DAL.getQLIList(quotesId);
            // Modification du flag "A Configurer"
            for (QuoteLineItem quoteItem : quoteLineItemList) {
                quoteItem.Aconfigurer__c = true;
            }

            if(!quoteLineItemList.isEmpty())
                update quoteLineItemList;
        }
    }

    public static void setQuoteRecordType(List<KIncontournable__c> incontournables, String type) {
        /* Protection contre les appels incorrectement argumentés */
        System.assertNotEquals(null, incontournables, 'Liste des incontournables invalide (null) !');
        System.assertNotEquals(0, incontournables.size(), 'Liste des incontournables invalide (vide) !');
        System.assertNotEquals(null, type, 'Type du devis invalide (null) !');
        System.assertNotEquals(0, type.trim().length(), 'Type du devis invalide (vide) !');

        /* Récupération de l'ID du type d'enregistrement recherché */
        Id recordTypeID = DAL.getRecordTypeIdByDevName('Quote', type);

        /* Recherche des ID des foyers associés aux contrats */
        List<ID> quoteIDs = new list<ID>();

        for (KIncontournable__c incontournable : incontournables)
            if (incontournable.devis__c != null)
                quoteIDs.add(incontournable.devis__c);

        /* Récupèration de tous les devis pour lesquels le recordtype n'est pas celui défini */
        List<Quote> updatedQuotes = [SELECT id, recordTypeId FROM Quote WHERE id IN :quoteIDs AND recordTypeId <> :recordTypeID];

        if (!updatedQuotes.isEmpty()) {
            /* Alimentation du recordType */
            for (Quote quote : updatedQuotes)
                quote.recordTypeId = recordTypeID;

            /* Sauvegarde */
            update updatedQuotes;
        }
    }

    public static void setQuoteRecordType(List<KContrat__c> contrats, String type) {
        /* Protection contre les appels incorrectement argumentés */
        System.assertNotEquals(null, contrats, 'Liste des contrats invalide (null) !');
        System.assertNotEquals(0, contrats.size(), 'Liste des contrats invalide (vide) !');
        System.assertNotEquals(null, type, 'Type du devis invalide (null) !');
        System.assertNotEquals(0, type.trim().length(), 'Type du devis invalide (vide) !');

        /* Récupération de l'ID du type d'enregistrement recherché */
        Id recordTypeID = DAL.getRecordTypeIdByDevName('Quote', type);

        /* Recherche des ID des foyers associés aux contrats */
        List<ID> quoteIDs = new list<ID>();

        for (KContrat__c contrat : contrats)
            if (contrat.devis__c != null)
                quoteIDs.add(contrat.devis__c);

        /* Récupèration de tous les devis pour lesquels le recordtype n'est pas celui défini */
        List<Quote> updatedQuotes = [SELECT id, recordTypeId FROM Quote WHERE id IN :quoteIDs AND recordTypeId <> :recordTypeID];

        if (!updatedQuotes.isEmpty()) {
            /* Alimentation du recordType */
            for (Quote quote : updatedQuotes)
                quote.recordTypeId = recordTypeID;

            /* Sauvegarde */
            update updatedQuotes;
        }
    }

    /***** A - Mise à jour des Remises *****/
    public static void setRemises(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        system.debug('#### START TR022_Quote.setRemises');
        List<Quote> quotes = (List<Quote>) Trigger.new;
        Map<Id, Quote>  oldQuotes = (Map<Id, Quote>) Trigger.oldMap;
        List<Quote> quotesList = new List<Quote>();
        for(Quote quote : quotes) {         
            Quote oldQuote = oldQuotes == null ? null : oldQuotes.get(quote.id);
            if ((quote.TotalHTlignes__c != oldQuote.TotalHTlignes__c) || (quote.referenceDate__c != oldQuote.referenceDate__c)
                || (quote.PromotionDevise__c != oldQuote.PromotionDevise__c)) {
                quotesList.add(quote);
            }
        }

        // Mise à jour des remises
        if(!quotesList.isEmpty())
            setBonusAndRemises(quotesList);
            
        system.debug('#### END TR022_Quote.setRemises');
    }

    public static void setBonusAndRemises(List<Quote> quotesList) {
        system.debug('#### START TR022_Quote.setBonusAndRemises');
        Map<ID, Double> mapTotalHT = new Map<ID, Double>();
        Map<ID, Double> mapRemiseEnseigneHT = new Map<ID, Double>();
        Decimal borneInf;
        Decimal borneSup;

        /* >>> F.G., le 17/11/2014 - Anciens calculés non encore calculés lors de l'appel de cette méthode */        
        for (AggregateResult groupedResult : [SELECT quoteId, SUM(PrixHTTarif__c) totalHT, SUM(PromotionDevise__c) remiseEnseigneHT
                                              FROM QuoteLineItem WHERE quoteId IN :quotesList AND cancelledLine__c = false GROUP BY quoteId]) {
            system.debug('### groupedResult : ' + groupedResult);
            mapTotalHT.put((ID) groupedResult.get('quoteID'), (Double) groupedResult.get('totalHT'));
            mapRemiseEnseigneHT.put((ID) groupedResult.get('quoteID'), (Double) groupedResult.get('remiseEnseigneHT'));
        }
        /* <<< F.G., le 17/11/2014 */

        // Calcul des bornes pour les bonus
        for(Quote quote : quotesList) {
            if (mapTotalHT.containsKey(quote.id)) {
                Double totalHT = mapTotalHT.get(quote.id);
                Double remiseEnseigneHT = mapRemiseEnseigneHT.get(quote.id);
            
                if (totalHT != null && totalHT != 0) {
                    Double montantHT = totalHT + (remiseEnseigneHT == null ? 0.0 : remiseEnseigneHT);
                    if(borneInf == null || borneInf > montantHT)
                        borneInf = montantHT ;
                    if(borneSup == null || borneSup < montantHT)
                        borneSup = montantHT ;
                }
            }
        }
        system.debug('### Borne Inf : ' + borneInf + ' - Borne Sup : ' + borneSup);

        // Récupération des bonus projet et remises incentives
        List<BonusProjet__c> bonusProjetList = getQuotesBonusProjet(quotesList, borneInf, borneSup);
        List<Remise_Incentive__c> remisesIncentivesList = getQuotesRemiseIncentive(borneInf, borneSup);

        // Calcul
        if(mapTotalHT != null) {
            for(Quote quote : quotesList){
              if (mapTotalHT.containsKey(quote.id)) {
                Double totalHT = mapTotalHT.get(quote.id);
                Double remiseEnseigneHT = mapRemiseEnseigneHT.get(quote.id);            
                
                if (totalHT != null && totalHT != 0) {
                  Double montantHT = (totalHT == null ? 0 : totalHT) + (remiseEnseigneHT == null ? 0 : remiseEnseigneHT);            
                  quote.BonusprojetPourcentage__c = calculateRemiseBonus(quote, montantHT, bonusProjetList);
                  quote.RemiseincentivePourcentage__c = calculateRemiseInc(quote, montantHT, remisesIncentivesList);
                } 
              }           
            }
        }
        system.debug('#### END TR022_Quote.setBonusAndRemises');
    }

    /**
      * @description Mise à jour des remises CEE
      * @param userContext Contexte de l'utilisateur courant
      */
    public static void setMontantLignesDevisCEE(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        List<Quote> quotes = (List<Quote>) Trigger.new;
        Map<Id, Quote> oldQuotes = (Map<Id, Quote>) Trigger.oldMap;
        Map<ID, Opportunity> opportunities =  new Map<ID, Opportunity>();
        List<Quote> quotesList = new List<Quote>();
        Set<String> opportunityIDs = new Set<String>();
        Date dateDevisMin = Date.today();
        Date dateDevisMax = dateDevisMin.addDays(-100000);
        List<Decimal> nbPersonneDevisList = new List<Decimal>();
        List<String> zoneGeographiqueDevisList = new List<String>();
        Map<String,Decimal> montantCEEList = new Map<String,Decimal>();
        for(Quote quote : quotes) {         
            Quote oldQuote = oldQuotes == null ? null : oldQuotes.get(quote.id);
            if ((quote.zone__c != oldQuote.zone__c) || (quote.nbPersonnes__c != oldQuote.nbPersonnes__c) || // quote.categorie__c != oldQuote.categorie__c ||
                (quote.referenceDate__c != oldQuote.referenceDate__c) || (quote.revenusFiscaux__c != oldQuote.revenusFiscaux__c)) {
                quotesList.add(quote);
            }
            if(String.isNotBlank(quote.OpportunityId))
                    opportunityIDs.add(quote.OpportunityId);
            if(quote.referenceDate__c < dateDevisMin)
                dateDevisMin = quote.referenceDate__c;
            if(quote.referenceDate__c > dateDevisMax)
                dateDevisMax = quote.referenceDate__c;
            nbPersonneDevisList.add(quote.nbPersonnes__c);
            zoneGeographiqueDevisList.add(quote.zone__c);
        }

        // Récupération information opportunités
        if (!opportunityIDs.isEmpty())
            opportunities = new Map<ID, Opportunity>([SELECT AccountId, autreCompte__c, LeadSource, operation__c, Account.email__c, Account.telephoneDomicile__c, Account.nom__c,
                                                        Account.rue__c, chantier__r.rue__c, Account.ville__c, chantier__r.ville__c, Account.pays__c, chantier__r.pays__c,
                                                        Account.departement__c, chantier__r.departement__c, Account.codePostal__c, chantier__r.codePostal__c,
                                                        chantier__r.proprietaire__r.nom__c, chantier__r.locataire__r.nom__c, chantier__r.occupant__r.nom__c, chantier__r.codeDVReference__c
                                                        FROM Opportunity WHERE Id IN :opportunityIDs]);

        // Mise à jour des remises
        if(!quotesList.isEmpty()){
            system.debug('#### START TR022_Quote.setMontantLignesDevisCEE');
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            Set<String> quoteIds = new Set<String>();
            List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
            List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
            List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
            List<String> pricebookEntryIdList = new List<String>();
            List<String> productIdList = new List<String>();
            List<String> tvaTypeList = new List<String>();
            
            for(Quote q : quotesList){
                quoteIds.add(q.Id);
            }

            qliList = [SELECT Id, QuoteId, Quantity, Product2Id, PricebookEntryId, PricebookEntry.Product2Id, eligibleCEE__c, TVApourcentage__c
                    FROM QuoteLineItem WHERE QuoteId IN :quoteIds AND cancelledLine__c = false];
            for(QuoteLineItem qli : qliList){
                pricebookEntryIdList.add(qli.PricebookEntryId);
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
                        WHERE type__c IN :tvaTypeList AND startDate__c < :dateDevisMax 
                                        AND (endDate__c > :dateDevisMin OR endDate__c = null)
                                        AND personNumber__c IN :nbPersonneDevisList
                                        AND geography__c IN :zoneGeographiqueDevisList];

            String DVElligibles = PropertiesUtils.getStringValue('cee.codesDVElligible', '');

            for(Quote q : quotesList){
                if(Test.isRunningTest() == false) {
                    Opportunity opportunity = opportunities.get(q.OpportunityId);
                    if(DVElligibles != null && opportunity != null && opportunity.chantier__r != null && opportunity.chantier__r.codeDVReference__c != null 
                        && DVElligibles.contains(opportunity.chantier__r.codeDVReference__c))
                    {
                        //Utils_CEE.setQliCEE(qliList, q, ceeList, tvaList, null);
                    } else {
                        Utils_CEE.setQliPrimeCEE(qliList, q, ceePrimeList, null);
                    }        
                }
                /*for(QuoteLineItem qli : qliList){
                    Boolean hasPrime = false;
                    if(qli.eligibleCEE__c && qli.QuoteId == q.Id){
                        for(CEE_Prime__c ccePrime : ceePrimeList){
                            if((ccePrime.dateDebutValidite__c == null || q.referenceDate__c > ccePrime.dateDebutValidite__c) && 
                                    (ccePrime.dateFinValidite__c == null || q.referenceDate__c < ccePrime.dateFinValidite__c) && 
                                    (ccePrime.categorie__c != null && q.categorie__c == ccePrime.categorie__c) &&
                                    (ccePrime.zone__c != null && (ccePrime.zone__c).contains(q.zone__c)) && qli.PricebookEntry.Product2Id == ccePrime.produit__c){
                                hasPrime = true;
                                qli.montantCEE__c = ccePrime.montant__c;
                            }
                        }
                    }
                    // Si aucune prime CEE existe, la catégorie de la ligne doit être nulle
                    if(!hasPrime)
                        qli.montantCEE__c = null;
                }*/
            }
            update qliList;
            system.debug('#### END TR022_Quote.setMontantLignesDevisCEE');
        }
            
    }
    

    /***** B - Calculs intermédiaire *****/
    private static Decimal calculateRemiseBonus(Quote quote, Double montantHT, List<BonusProjet__c> bonusProjetList){
        Decimal coefficientRemiseBonus = 0;
        for (BonusProjet__c bp : bonusProjetList) {
            if (bp.Montantplancher__c <= montantHT && montantHT <= bp.Montantplafond__c && bp.Datedapplication__c <= quote.referenceDate__c) {
                coefficientRemiseBonus = bp.Coefficientremise__c;
                system.debug('### calculateRemiseBonus -  Id : ' + quote.Id + ' / montantHT : ' + montantHT + ' / Bonus Projet Pourcentage : ' + coefficientRemiseBonus);
                break;
            }
        }        
        return coefficientRemiseBonus;
    }

    private static Decimal calculateRemiseInc(Quote quote, Double montantHT, List<Remise_Incentive__c> remisesIncentivesList){
        Decimal coefficientRemiseBonus = 0;
        for (Remise_Incentive__c remise : remisesIncentivesList) {
            if (remise.Montantplancher__c <= montantHT && montantHT <= remise.Montantplafond__c && remise.CodeIncentive__c != null && Utils_Configurator.isProjetEligible(quote, remise.CodeIncentive__r)) {
                coefficientRemiseBonus = remise.Coefficientremise__c;
                system.debug('### calculateRemiseInc - Id : ' + quote.Id + ' / montantHT : ' + montantHT + ' / Remise Incentive Pourcentage : ' + coefficientRemiseBonus);
                break;
            }
        }     
        return coefficientRemiseBonus;
    }

    private static List<BonusProjet__c> getQuotesBonusProjet(List<Quote> quotesList, Decimal borneInf, Decimal borneSup){
        Date maxDateDevis = null;
        // Calcul de la date max et récupération des bonus
        for(Quote quote :quotesList){
            if(maxDateDevis==null || quote.referenceDate__c > maxDateDevis)
                maxDateDevis = quote.referenceDate__c;
        }
        system.debug('### getQuotesBonusProjet : ' + borneInf + ' / ' + borneSup + ' / ' + maxDateDevis);
        List<BonusProjet__c> bonus = DAL.getBonusProjet(borneInf, borneSup, maxDateDevis);
        system.debug('### getQuotesBonusProjet : ' + bonus.size());
        return bonus;
    }

    private static List<Remise_Incentive__c> getQuotesRemiseIncentive(Decimal borneInf, Decimal borneSup) {
        // Récupération des remises incentives
        system.debug('### getQuotesRemiseIncentive : ' + borneInf + ' / ' + borneSup);
        List<Remise_Incentive__c> remises = (borneInf != null) ? DAL.getRemiseIncentive(borneInf, borneSup) : new List<Remise_Incentive__c>();
        system.debug('### getQuotesRemiseIncentive : ' + remises.size());
        return remises;
    }
    
    public static void updateAccountStatus(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        system.debug('#### START TR022_Quote.updateAccountStatus');
        List<Quote> quotes = (List<Quote>) Trigger.new;
        try{
            // Account
            Set<Account> accSet = new Set<Account>();
            for(Quote devis : quotes) {
                if(String.isNotBlank(devis.AccountId)) accSet.add(new Account(Id=devis.AccountId));
                if(String.isNotBlank(devis.compte__c)) accSet.add(new Account(Id=devis.compte__c));
                if(String.isNotBlank(devis.autreCompte__c)) accSet.add(new Account(Id=devis.autreCompte__c));
            }
            List<Account> accList = new List<Account>();
            for(Account a : accSet)
                accList.add(a);
            //update accList;    
            // Opportunity
            /*List<Opportunity> oppList = new List<Opportunity>();
            for(Quote devis : quotes) {
                if(String.isNotBlank(devis.OpportunityId)) oppList.add(new Opportunity(Id=devis.OpportunityId));
            }
            update oppList;*/
            Utils_CalculateStatus.refreshAccountStatusFromQuote(quotes);
        } catch(exception e) {
            system.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
        system.debug('#### END TR022_Quote.updateAccountStatus');
    }
}