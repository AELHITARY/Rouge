//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Quote
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 18/12/2021
//-- Version     : 1.7
//-- * 1.7 : RQM-77 : Ne pas autoriser les statuts vendu ou transmis si devis TMC
//-- * 1.63 : RQM-47 : Calcul de la prime CEE / Isolation des combles
//-- * 1.62 : Devis : Règles de validation et de mise à jour (Ancien bandeau / 2016)
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Quote {
    private static final Integer DELAI_EXPIRATION = PropertiesUtils.getIntegerValue('maintenance.devis.delaiExpiration', 30);
    private static final Integer DELAI_EXPIRATION_DEVIS = PropertiesUtils.getIntegerValue('maintenanceQuot.delaiExpirationDevis', -30);

    /**
    * @description Méthode exécutant les règles de validation pour les devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        Map<Id, Quote> oldQuotes = (Map<Id, Quote>)Trigger.oldMap;

        // Impossible à mettre dans une règle de validation car "Vous avez atteint le nombre maximal 10 de références d'objet dans Devis"
        List<Quote> newQuotes = new List<Quote>();
        List<Id> operationIds = new List<Id>();
        Map<Id, ReferentielOperation__c> operations = new Map<Id, ReferentielOperation__c>();
        List<String> quoteToCheckIdList = new List<String>();

        for (Quote newQuote : (List<Quote>)Trigger.new) {
            // newQuote.dateTransmissionClient__c.addError('DEBUG# Step 0 ==> ' + newQuote.dateTransmissionClient__c + ' / ' + newQuote.dateAcceptationClient__c + ' / ' + newQuote.lineItemCount + ' / ' + newQuote.lignesConfigurees__c);
            if (!AlreadyUsed.isUsed('TR020_Quote.applyValidationRules', newQuote.id)) {
                Quote oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.id);

                // newQuote.dateTransmissionClient__c.addError('DEBUG# Step 1 ==> ' + newQuote.dateTransmissionClient__c + ' / ' + newQuote.dateAcceptationClient__c + ' / ' + newQuote.lineItemCount + ' / ' + newQuote.lignesConfigurees__c);

                if (newQuote.operation__c != null && (Trigger.isInsert || newQuote.operation__c != oldQuote.operation__c))
                    operationIds.add(newQuote.operation__c);

                newQuotes.add(newQuote);
            }
        }

        if (newQuotes.isEmpty())
            return;

        if(!operationIds.isEmpty())
            operations = new Map<Id, ReferentielOperation__c>([SELECT id, origine__c, dateDebut__c, dateFinSaisie__c, magasins_DR_Est__c, 
                                                                    magasins_DR_IDF__c, magasins_DR_Nord__c, magasins_DR_Ouest__c
                                                                 FROM ReferentielOperation__c
                                                                 WHERE id IN :operationIds]);
        for (Quote newQuote : newQuotes) {
            Quote oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.id);

            if (newQuote.dateTransmissionClient__c != null && newQuote.LineItemCount != newQuote.lignesConfigurees__c+newQuote.cancelledLineCount__c)
              newQuote.dateTransmissionClient__c.addError(Label.quote_error_dateTransmissionInvalide);
            if (newQuote.dateAcceptationClient__c != null && newQuote.LineItemCount != newQuote.lignesConfigurees__c+newQuote.cancelledLineCount__c)
              newQuote.dateAcceptationClient__c.addError(Label.quote_error_dateAcceptationInvalide);

            ReferentielOperation__c operation = operations.get(newQuote.operation__c);
            if (operation == null)
               continue;
            /*
            Date createdDate = newQuote.createdDate.date();
            if (createdDate < operation.dateDebut__c || createdDate > operation.dateFinSaisie__c || newQuote.source__c != operation.origine__c)
              newQuote.operation__c.addError('Opération commerciale invalide (Origine ou période de saisie incorrecte)!');
            */
            if ((Trigger.isInsert || newQuote.modeFinancement__c != oldQuote.modeFinancement__c) &&
                (userContext != null && userContext.isSaleUser()) &&
                ('CLASSIQ - 20M GRATUIT (PROMO)'.equalsIgnoreCase(newQuote.modeFinancement__c) || 'PROMO - 36M 24M FOIRE'.equalsIgnoreCase(newQuote.modeFinancement__c)) &&
                ('FOIRE'.equalsIgnoreCase(newQuote.source__c)) &&
                (!String.isEmpty(userContext.getUser().libelleMagasin__c)) &&
                (!((!String.isEmpty(operation.magasins_DR_Est__c) && operation.magasins_DR_Est__c.contains(userContext.getUser().libelleMagasin__c)) ||
                  (!String.isEmpty(operation.magasins_DR_IDF__c) && operation.magasins_DR_IDF__c.contains(userContext.getUser().libelleMagasin__c)) ||
                  (!String.isEmpty(operation.magasins_DR_Nord__c) && operation.magasins_DR_Nord__c.contains(userContext.getUser().libelleMagasin__c)) ||
                  (!String.isEmpty(operation.magasins_DR_Ouest__c) && operation.magasins_DR_Ouest__c.contains(userContext.getUser().libelleMagasin__c))))) {
              newQuote.modeFinancement__c.addError(Label.quote_error_modeFinancementInvalide);
            }
        }
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        if (Trigger.isInsert)
            initIndicators(userContext);
        if(Trigger.isUpdate)
            applyProductsUpdateRules(userContext);
        applyDataUpdateRules(userContext);
        applyGDPRDateExpiration();
        applyStatusUpdateRules(userContext);
        applyPaiementRules();
    }

    private static void initIndicators(UserContext userContext) {
        for (Quote quote : (List<Quote>)Trigger.new) {
            quote.datePremierContrat__c           = null;
            quote.dateDernierContrat__c           = null;
            quote.statutPremierContrat__c         = null;
            quote.statutDernierContrat__c         = null;
            quote.totalHTContratsVendus__c        = null;
            quote.totalTTCContratsVendus__c       = null;
            quote.totalHTContratsResilies__c      = null;
            quote.totalTTCContratsResilies__c     = null;
            quote.nbContratsVendus__c             = null;
            quote.nbContratsResilies__c           = null;

            quote.datePremierIncontournable__c    = null;
            quote.dateDernierIncontournable__c    = null;
            quote.nbIncontournablesEnregistres__c = null;
            quote.nbIncontournablesEnCours__c     = null;
            quote.nbIncontournablesTermines__c    = null;
            quote.statutPremierIncontournable__c  = null;
            quote.statutDernierIncontournable__c  = null;

            quote.datePremierAppelSortant__c      = null;
            quote.dateDernierAppelSortant__c      = null;
            quote.nbAppelsSortants__c             = null;
            quote.datePremierTagAppel__c          = null;
            quote.dateDernierTagAppel__c          = null;
            quote.nbTagsAppel__c                  = null;
            quote.datePremierEmail__c             = null;
            quote.dateDernierEmail__c             = null;
            quote.nbEmails__c                     = null;
            quote.datePremierPhoning__c           = null;
            quote.dateDernierPhoning__c           = null;
            quote.nbPhonings__c                   = null;
        }
    }

    /**
    * @description Méthode exécutant les règles de mise à jour de champs pour les devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyDataUpdateRules(UserContext userContext) {
        List<Quote> newQuotes = new List<Quote>();
        Map<Id, Quote>  oldQuotes = (Map<Id, Quote>)Trigger.oldMap;
        Map<ID, Opportunity> opportunities =  new Map<ID, Opportunity>();
        List<Quote> updatedCEEQuoteList = new List<Quote>();
        List<CEE_Categorie__c> ceeCategorieList = new List<CEE_Categorie__c>();
        List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
        List<Quote> quotesWithQLI = new List<Quote>();
        Set<String> opportunityIDs = new Set<String>();
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        Map<String,List<QuoteLineItem>> qliMap = new Map<String,List<QuoteLineItem>>();
        Date dateDevisMin = Date.today();
        Date dateDevisMax = dateDevisMin.addDays(-100000);
        List<Decimal> nbPersonneDevisList = new List<Decimal>();
        List<String> zoneGeographiqueDevisList = new List<String>();
        Date dateExpiration = Date.today().addDays(DELAI_EXPIRATION);

        /** A - Initialisation des données intermédiaires **/
        for (Quote newQuote : (List<Quote>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR020_Quote.applyDataUpdateRules', newQuote.id)) {
                newQuotes.add(newQuote);
                if(String.isNotBlank(newQuote.OpportunityId))
                    opportunityIDs.add(newQuote.OpportunityId);
                // Récupération des lignes de devis seulement si ligne de devis
                if(newQuote.LineItemCount != 0) {
                    quotesWithQLI.add(newQuote);
                }
            }
            if(newQuote.referenceDate__c < dateDevisMin)
                dateDevisMin = newQuote.referenceDate__c;
            if(newQuote.referenceDate__c > dateDevisMax)
                dateDevisMax = newQuote.referenceDate__c;
            nbPersonneDevisList.add(newQuote.nbPersonnes__c);
            zoneGeographiqueDevisList.add(newQuote.zone__c);
        }
        
        // Récupération information opportunités
        if (!opportunityIDs.isEmpty())
            opportunities = new Map<ID, Opportunity>([SELECT AccountId, autreCompte__c, LeadSource, operation__c, Account.email__c, Account.telephoneDomicile__c, Account.nom__c,
                                                        Account.rue__c, chantier__r.rue__c, Account.ville__c, chantier__r.ville__c, Account.pays__c, chantier__r.pays__c,
                                                        Account.departement__c, chantier__r.departement__c, Account.codePostal__c, chantier__r.codePostal__c,
                                                        chantier__r.proprietaire__r.nom__c, chantier__r.locataire__r.nom__c, chantier__r.occupant__r.nom__c, chantier__r.codeDVReference__c
                                                        FROM Opportunity WHERE Id IN :opportunityIDs]);

        // Récupération des lignes de devis
        if (!quotesWithQLI.isEmpty()) {
            qliList = [SELECT Id, QuoteId, Quantity, Product2Id, PricebookEntry.Product2Id, PricebookEntry.Product2.SousFamille__c,
                                eligibleCEE__c, TVApourcentage__c, cancelledLine__c 
                        FROM QuoteLineItem WHERE QuoteId IN :quotesWithQLI];        
            for (Quote quote : quotesWithQLI) {
                List<QuoteLineItem> qliListByQuote = new List<QuoteLineItem>();
                for (QuoteLineItem qli : qliList) {
                    if(qli.QuoteId == quote.Id) qliListByQuote.add(qli);
                }
                qliMap.put(quote.Id, qliListByQuote);
            }
        }

        /*
          SOPRA STERIA : 03/10/2017 : Création d'un process builder : Devis - Actions création/modification
            ## ANNULE CAR LES PROCESS BUILDER FONT UNE REQUETE POUR CHAQUE MISE A JOUR INDIVIDUELLE
            ## Mise à jour des champs : compte__c, autreCompte__c, operation__c, premiereSource__c, premiereSourceCall__c,
            ##                          nbSources__c, nbSourcesCall__c, pctAcompteAttendu__c, acompteRemiseMetreur__c, acomptePreleveeCompte__c
        */

        /** B - Application des règles de mise à jour **/
        for (Quote newQuote : newQuotes) {
            Quote oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.id);
            Opportunity opportunity = opportunities.get(newQuote.OpportunityId);
            List<QuoteLineItem> qliListByQuote = qliMap.get(newQuote.id);

            if (newQuote.compte__c == null) {
                if (opportunity != null) {
                    newQuote.compte__c = opportunity.AccountId;
                    newQuote.autreCompte__c = opportunity.autreCompte__c;
                }
            }
            newQuote.operation__c = opportunity == null ? null : opportunity.operation__c;

            // Champs d'adresse
            if((Trigger.IsInsert || newQuote.OpportunityId != oldQuote.OpportunityId) && opportunity != null) {
                // Facturation
                if(opportunity.chantier__r != null) {
                    String nomChantier;
                    if(opportunity.chantier__r.occupant__r != null) 
                        nomChantier = opportunity.chantier__r.occupant__r.nom__c;
                    else if(opportunity.chantier__r.locataire__r != null) 
                        nomChantier = opportunity.chantier__r.locataire__r.nom__c;
                    else if(opportunity.chantier__r.proprietaire__r != null) 
                        nomChantier = opportunity.chantier__r.proprietaire__r.nom__c;
                    newQuote.ShippingName = nomChantier;
                    newQuote.ShippingStreet = opportunity.chantier__r.rue__c;
                    newQuote.ShippingPostalCode = opportunity.chantier__r.codePostal__c;
                    newQuote.ShippingCity = opportunity.chantier__r.ville__c;
                    newQuote.ShippingState = opportunity.chantier__r.departement__c;
                    newQuote.ShippingCountry = opportunity.chantier__r.pays__c;
                }
                // Demandeur
                if(opportunity.AccountId != null) {
                    newQuote.ShippingName = opportunity.Account.nom__c;
                    newQuote.BillingStreet = opportunity.Account.rue__c;
                    newQuote.BillingPostalCode = opportunity.Account.codePostal__c;
                    newQuote.BillingCity = opportunity.Account.ville__c;
                    newQuote.BillingState = opportunity.Account.departement__c;
                    newQuote.BillingCountry = opportunity.Account.pays__c;
                    newQuote.Email = opportunity.Account.email__c;
                    newQuote.Phone = opportunity.Account.telephoneDomicile__c;
                }
            }
            
            // Alimentation date de référence sur devis initial (non avenant) à la création
            if(Trigger.isInsert /*&& newQuote.amendmentQuote__c == false*/) {
                newQuote.ExpirationDate = dateExpiration;
            }
            if(Trigger.isInsert && newQuote.amendmentQuote__c == false) {
                newQuote.referenceDate__c = newQuote.dateDevis__c;
            }
            System.debug('## newQuote.referenceDate__c: '+newQuote.referenceDate__c);
            System.debug('## newQuote.dateDevis__c: '+newQuote.dateDevis__c);
            System.debug('## newQuote.ExpirationDate: '+newQuote.ExpirationDate);

            // Modification date de référence par rapport à la date du devis pour les devis non avenant et non cloné
            if(Trigger.isUpdate && oldQuote != null && newQuote.dateDevis__c != oldQuote.dateDevis__c 
                && newQuote.amendmentQuote__c == false && String.isBlank(newQuote.amendInitialQuote__c)) 
            {
                newQuote.referenceDate__c = newQuote.dateDevis__c;
            } else if(Trigger.isUpdate && oldQuote != null && newQuote.referenceDate__c != oldQuote.referenceDate__c 
                && newQuote.amendmentQuote__c == false && String.isBlank(newQuote.amendInitialQuote__c)) 
            {
                newQuote.dateDevis__c = newQuote.referenceDate__c;
            }
            
    /*
            // 13/12/2021 - JMU - Mise à jour de la date de référence
            if(newQuote.amendmentQuote__c){
                newQuote.referenceDate__c = newQuote.amendInitialQuote__r.dateDevis__c;
            } else {
                newQuote.referenceDate__c = newQuote.dateDevis__c;
            } 
    */

            /* Conversion via mapping impossible avec les workflows */
            if (newQuote.source__c == null && newQuote.callSource__c != null)
                newQuote.source__c = MappingUtils.getOrigineVenteFromCall(newQuote.callSource__c);

            if (newQuote.premiereSource__c == null && newQuote.source__c != null)
                newQuote.premiereSource__c = newQuote.source__c;
            if (newQuote.premiereSourceCall__c == null && newQuote.callSource__c != null)
                newQuote.premiereSourceCall__c = newQuote.callSource__c;
            if (oldQuote != null && newQuote.source__c != oldQuote.source__c)
                newQuote.nbSources__c = (newQuote.nbSources__c == null ? 0 : newQuote.nbSources__c) + 1;
            if (oldQuote!= null && newQuote.callSource__c != oldQuote.callSource__c)
                newQuote.nbSourcesCall__c = (newQuote.nbSourcesCall__c == null ? 0 : newQuote.nbSourcesCall__c) + 1;

            if (userContext != null && userContext.isCallUser())
                newQuote.lastModifiedByCall__c = userContext.getUser().id;
            if (userContext != null && userContext.isSaleUser())
                newQuote.lastModifiedBySale__c = userContext.getUser().id;

            if (newQuote.codePostalChantier__c != null)
                newQuote.zone__c = newQuote.codePostalChantier__c.substring(0,2);
            
            // Alimentation des acompte n°1 et 2 
            if (oldQuote != null && !String.isEmpty(newQuote.modeFinancement__c) 
                        && MappingUtils.getAcompteString(newQuote.modeFinancement__c) != null 
                        && (newQuote.mntAcompteAttendu__c == null || newQuote.Total_TTC_devis__c != oldQuote.Total_TTC_devis__c) 
                        && newQuote.Total_TTC_devis__c != null) {
                // Parser le mapping/acompte correspondant au mode de financement en vérifiant le séparateur point-virgule
                String getAcompte = MappingUtils.getAcompteString(newQuote.modeFinancement__c);
                String[] acomptesList = getAcompte.split(';');
                newQuote.mntAcompteAttendu__c = (newQuote.Total_TTC_devis__c != null) ? 
                                                (newQuote.Total_TTC_devis__c * Integer.valueOf(acomptesList[0])) / 100 : 
                                                null;
                // S'il existe un point-virgule, on alimente l'acompte 2, sinon, il est vidé
                if(acomptesList.size() == 2){
                    newQuote.mntAcompte2Attendu__c = (newQuote.Total_TTC_devis__c != null) ? 
                                                    (newQuote.Total_TTC_devis__c * Integer.valueOf(acomptesList[1])) / 100 : 
                                                    null;
                } else {
                    newQuote.mntAcompte2Attendu__c = null;
                }
            }

            // 27/02/2018 - JMU - RQM-47 - Ajout du recalcul des informations CEE
            if ((Trigger.isInsert && newQuote.revenusFiscaux__c != null && newQuote.nbPersonnes__c != null)
                || ((oldQuote != null && newQuote.revenusFiscaux__c != oldQuote.revenusFiscaux__c) || 
                (oldQuote != null && newQuote.nbPersonnes__c != oldQuote.nbPersonnes__c) || 
                (oldQuote != null && newQuote.codePostalChantier__c != oldQuote.codePostalChantier__c) || 
                (oldQuote != null && newQuote.referenceDate__c != oldQuote.referenceDate__c)))
                updatedCEEQuoteList.add(newQuote);

            // Cas ou tous les produits du devis ont une sous-famille égale à « ISOLATION »
            if(newQuote.Status == Constants.StatutDevisTransmis || newQuote.Status == Constants.StatutDevisVenduAttente || 
                newQuote.Status == Constants.StatutDevisVenduEnregistre || newQuote.Status == Constants.StatutDevisVenduIncontournable){
                
                Boolean produitNonIsole = false;
                if(qliListByQuote != null && !qliListByQuote.isEmpty()){
                    for(QuoteLineItem qli : qliListByQuote){
                        if(qli.PricebookEntry.Product2.SousFamille__c != 'ISOLATION') produitNonIsole = true;
                        if(!produitNonIsole){
                            if(newQuote.typeContrat__c == Constants.QUOTE_TYPECONTRAT_STANDARD){
                                newQuote.typeContrat__c = Constants.QUOTE_TYPECONTRAT_ISOLATION_STANDARD;
                            } else if(newQuote.typeContrat__c == Constants.QUOTE_TYPECONTRAT_FOIRE){
                                newQuote.typeContrat__c = Constants.QUOTE_TYPECONTRAT_ISOLATION_FOIRE;
                            }
                        }
                    }
                }
            }
        }

        // Mise à jour des informations CEE
        List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
        List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
        List<String> productIdList = new List<String>();
        List<String> tvaTypeList = new List<String>();
        if (!updatedCEEQuoteList.isEmpty()){
            List<mapping__c> mappingList = mapping__c.getall().values();
            List<QuoteLineItem> qliListCEE = new List<QuoteLineItem>();
            for (QuoteLineItem qli : qliList) {
                for(Quote q : updatedCEEQuoteList){
                    if(q.Id == qli.QuoteId && !qli.cancelledLine__c){
                        qliListCEE.add(qli);
                        productIdList.add(qli.product2Id);
                    }
                }
            }
            // Récupération des catégories/primes CEE dans la base, et des lignes de devis
            ceeCategorieList = [SELECT Id, debutValidite__c, finValidite__c, nbPersonnes__c, zone__c, pivotAB__c, pivotBC__c FROM CEE_Categorie__c];
            ceePrimeList = [SELECT Id, dateDebutValidite__c, dateFinValidite__c, categorie__c, montant__c, produit__c, zone__c FROM CEE_Prime__c];

            tvaList = [SELECT Id, Type__c, produit__c, dateDebut__c, dateFin__c, taux__c 
                        FROM TVA_Produit__c
                        WHERE produit__c IN :productIdList];

            for(TVA_Produit__c tva : tvaList){
                tvaTypeList.add(tva.Type__c);
            }

            ceeList = [SELECT Id, type__c, startDate__c, endDate__c, minIncomes__c, maxIncomes__c, personNumber__c, geography__c,  heatingModes__c, customerAmount__c, officialAmount__c, incomeType__c
                        FROM ESCIncentive__c
                        WHERE type__c IN :tvaTypeList AND startDate__c < :dateDevisMax 
                                        AND (endDate__c > :dateDevisMin OR endDate__c = null)
                                        AND personNumber__c IN :nbPersonneDevisList];

            /*for(ESCIncentive__c esci : ceeListTemp){
                if(zoneGeographiqueDevisList){
                    ceeList.add(esci);
                }
                
            }*/

            System.debug('## tvaTypeList: '+tvaTypeList);
            System.debug('## dateDevisMax: '+dateDevisMax);
            System.debug('## dateDevisMin: '+dateDevisMin);
            System.debug('## nbPersonneDevisList: '+nbPersonneDevisList);
            System.debug('## zoneGeographiqueDevisList: '+zoneGeographiqueDevisList);

            String DVElligibles = PropertiesUtils.getStringValue('cee.codesDVElligible', null);

            for (Quote quote : updatedCEEQuoteList) {
                // Recalcul de la zone
                /*String codeDepartement = quote.codePostalChantier__c.substring(0,2);
                for(Integer i=0;i<mappingList.size();i++){
                    if(mappingList[i].Repository__c == 'zone_climatique' && mappingList[i].PickValue__c == codeDepartement){
                        quote.zone__c = mappingList[i].ConvertedValue__c;
                    }
                }*/

                // Recalcul de la catégorie (ancien système)
                Boolean hasCategorie = false;
                for(CEE_Categorie__c ceeCat : ceeCategorieList){
                    System.debug('ceeCat.zone__c+quote.zone__c : '+ceeCat.zone__c+'/'+quote.zone__c); 
                    List<String> zoneList = new List<String>();
                    zoneList = ceeCat.zone__c.split('\\;');
                    for(String zonePrime : zoneList){
                        System.debug('zonePrime : '+zonePrime+'/'+quote.zone__c); 
                        if((ceeCat.debutValidite__c == null || quote.referenceDate__c >= ceeCat.debutValidite__c) && 
                            (ceeCat.finValidite__c == null || quote.referenceDate__c <= ceeCat.finValidite__c) && 
                            (ceeCat.nbPersonnes__c != null && quote.nbPersonnes__c == ceeCat.nbPersonnes__c) &&
                            (zonePrime != null && quote.zone__c != null && zonePrime == quote.zone__c)){
                            hasCategorie = true;
                            if(quote.revenusFiscaux__c <= ceeCat.pivotAB__c)
                                quote.categorie__c = 'A';
                            else if(quote.revenusFiscaux__c <= ceeCat.pivotBC__c)
                                quote.categorie__c = 'B';
                            else
                                quote.categorie__c = 'C';
                        }
                    }
                }

                // Si aucune catégorie CEE existe, la catégorie du devis ne doit pas être affichée
                if(!hasCategorie) {
                    quote.categorie__c = null;
                }

                // Recalcul des montants CEE
                Opportunity opportunity = opportunities.get(quote.OpportunityId);
                System.debug('## ceeList: '+ceeList);
                if(DVElligibles != null && opportunity != null && opportunity.chantier__r.codeDVReference__c != null && DVElligibles.CONTAINS(opportunity.chantier__r.codeDVReference__c)){
                    Utils_CEE.setQuoteCEE(qliListCEE, quote, ceeList, tvaList);
                } else {
                    Utils_CEE.setQuotePrimeCEE(qliListCEE, quote, ceePrimeList);
                }    
                
            }
        }
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Quote : applyStatusUpdateRules');
        List<Quote> newQuotes = (List<Quote>)Trigger.new;
        Map<Id, Quote> oldQuotes = (Map<Id, Quote>)Trigger.oldMap;
        Id RTErrone = DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_ERRONE);
        Date dateExpiration = Date.today().addDays(DELAI_EXPIRATION_DEVIS);

        for (Quote newQuote : newQuotes) {
            // Check des champs number 
            Decimal nbContratsVendus = (newQuote.nbContratsVendus__c != null) ? newQuote.nbContratsVendus__c : 0;
            Decimal nbContratsResilies = (newQuote.nbContratsResilies__c != null) ? newQuote.nbContratsResilies__c : 0;
            Decimal nbIncontournablesEnCours = (newQuote.nbIncontournablesEnCours__c != null) ? newQuote.nbIncontournablesEnCours__c : 0;
            Decimal nbIncontournablesEnregistres = (newQuote.nbIncontournablesEnregistres__c != null) ? newQuote.nbIncontournablesEnregistres__c : 0;

            // UR_K2_Quote_Status 
            if (String.isNotBlank(newQuote.forcageEtat__c)){
                newQuote.Status = newQuote.forcageEtat__c;
            } else if (newQuote.RecordType != null && RTErrone != null && newQuote.RecordTypeId == RTErrone){
                newQuote.Status = Constants.StatutDevisErrone;
            } else if (nbContratsVendus == 0 && nbContratsResilies > 0){
                newQuote.Status = Constants.StatutDevisResilie;
            } else if (!newQuote.devisTMC__c && nbContratsVendus > 0){
                newQuote.Status = Constants.StatutDevisVenduEnregistre;
                // Remise à 0 des valeurs CEE
                newQuote.revenusFiscaux__c = null;
                newQuote.nbPersonnes__c = null;
                newQuote.typeRevenu__c = null;
            } else if (!newQuote.devisTMC__c && (nbIncontournablesEnCours > 0 || nbIncontournablesEnregistres > 0)){
                newQuote.Status = Constants.StatutDevisVenduIncontournable;
            } else if (!newQuote.devisTMC__c && newQuote.dateAcceptationClient__c != null && newQuote.dateAcceptationClient__c > dateExpiration && newQuote.LineItemCount == newQuote.lignesConfigurees__c+newQuote.cancelledLineCount__c){
                newQuote.Status = Constants.StatutDevisVenduAttente;
            } else if (newQuote.expirationDate != null && newQuote.expirationDate < dateExpiration && nbContratsVendus == 0 && nbContratsResilies == 0){
                newQuote.Status = Constants.StatutDevisExpire;
            } else if (!newQuote.devisTMC__c && (newQuote.dateTransmissionClient__c != null || String.isNotBlank(newQuote.moyenTransmissionClient__c))){
                newQuote.Status = Constants.StatutDevisTransmis;
            } else if (newQuote.LineItemCount > 0 && newQuote.LineItemCount == newQuote.lignesConfigurees__c+newQuote.cancelledLineCount__c){
                newQuote.Status = Constants.StatutDevisNonTransmis;
            } else {
                newQuote.Status = Constants.StatutDevisAConfigurer;
            }
            System.debug('## Quote Status: '+newQuote.Status);
        }
        System.debug('### FIN TR020_Quote : applyStatusUpdateRules');
    }

    /**
    * @description Méthode pour vérifier le mode de financement et mettre à jour les indicateurs d'acompte
    */
    private static void applyPaiementRules() {
        List<Quote> newQuotes = (List<Quote>)Trigger.new;

        for (Quote newQuote : newQuotes) {
            // Check du mode de financement
            if(newQuote.modeFinancement__c == 'PAIEMENT COMPTANT' || newQuote.modeFinancement__c == 'ADMINISTRATION OU COLLECT. LOC.' || newQuote.modeFinancement__c == 'PASS TRAVAUX'){
                newQuote.acompteRemiseMetreur__c = true;
                newQuote.acomptePreleveeCompte__c = false;
            }
        }
    }
    
    /**
    * @description Méthode pour mettre à jour la date d'expiration GDPR selon le statut
    */
    private static void applyGDPRDateExpiration() {
        System.debug('### DEBUT TR020_Quote : applyGDPRDateExpiration');
        List<Quote> newQuotes = (List<Quote>)Trigger.new;

        for (Quote newQuote : newQuotes) {
            System.debug('## Quote Id: '+newQuote.Id);
            // GDPR
            newQuote.GDPR_DateExpiration__c = null;
            if(newQuote.dateAcceptationClient__c != null)
                newQuote.GDPR_DateExpiration__c = newQuote.dateAcceptationClient__c.addDays(365);
            if(String.isNotBlank(newQuote.Status) && Constants.QUOTE_STATUS_SOLD.containsIgnoreCase(newQuote.Status) && newQuote.dateAcceptationClient__c != null) 
                newQuote.GDPR_DateExpiration__c = newQuote.dateAcceptationClient__c.addDays(365);
            if (newQuote.Status == Constants.StatutDevisExpire || newQuote.Status == Constants.StatutDevisErrone  || newQuote.Status == Constants.StatutDevisResilie)
                newQuote.GDPR_DateExpiration__c = newQuote.CreatedDate.date().addDays(365);
            System.debug('## Quote GDPR_DateExpiration: '+newQuote.GDPR_DateExpiration__c);
        }
        System.debug('### FIN TR020_Quote : applyGDPRDateExpiration');
    }

    /**
    * @description Méthode pour mettre à jour le champ contenant le nom de tous les produits d'un devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyProductsUpdateRules(UserContext userContext) {
        List<Quote> quotes = (List<Quote>) Trigger.new;
        Map<Id, Quote>  oldQuotes = (Map<Id, Quote>) Trigger.oldMap;
        List<Quote> quotesId = new List<Quote>();

        // On récupère les ID des devis seulement si le champ changementProduits__c est différent et égale à true
        for (Quote quote : quotes) {
            Quote oldquote = oldQuotes == null ? null : oldQuotes.get(quote.id);
            if(quote.changementProduits__c == true && (quote.changementProduits__c != oldquote.changementProduits__c))
                quotesId.add(quote);
        }

        // On récupère les devis et on modifie le champ "Changement des Produits" pour le calcul des "Produits du devis"
        if(!quotesId.isEmpty()) {
            List<QuoteLineItem> quoteLineItemList = DAL.getQLIList(quotesId);
            for (Quote quote : quotesId) {
                System.debug('#### Changement produit pour devis ' + quote.Id); 
                String nomDuProduit = '';
                quote.produitsDuDevis__c = null;
                Map<Product2, Decimal> productMap = new Map<Product2, Decimal>();
                for (QuoteLineItem quoteLI : quoteLineItemList) {
                    // Si la ligne de devis correspond au devis
                    if(quoteLI.QuoteId == quote.Id) {
                        // On récupère tous les produits de la ligne de devis et on concatene les quantités pour les produits en double
                        Product2 prod = quoteLI.PricebookEntry.Product2;
                        if (!productMap.containsKey(prod))
                            productMap.put(prod, quoteLI.Quantity);
                        else {
                            Decimal quantity = productMap.get(prod) + quoteLI.Quantity;
                            productMap.put(prod, quantity);
                        }
                    }
                }

                // Construction du mémo en fonction des produits
                for (Product2 product : productMap.keySet()) {
                    nomDuProduit = (Integer) productMap.get(product)
                                        + ' x ' + product.sousFamille__c
                                        + ' ' + product.sousMatiere__c
                                        + ' (' + product.Reference__c+ ')';
                    if (quote.produitsDuDevis__c == null)
                        quote.produitsDuDevis__c = nomDuProduit;
                    else
                        quote.produitsDuDevis__c = quote.produitsDuDevis__c + ', ' + nomDuProduit;
                }
                quote.changementProduits__c = false;
            }
        }
    }
}