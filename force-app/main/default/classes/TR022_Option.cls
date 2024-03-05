//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Option
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/20/2023
//-- Version     : 1.3
//-- * 1.3 : Ajout alimentation coefficient thermique sur les lignes
//-- * 1.2 : La date d'expiration est toujours à +14 pour les devis TMC
//-- * 1.1 : RQM-77 : La date d'expiration est toujours à +14 pour les devis TMC
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Option {

    /**
    * @description Méthode appelée par les trigger d'insertion/MAJ/delete des options pour mettre à jour la date d'expiration du devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void updateQuoteExpirationDate(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_Option.updateQuoteExpirationDate');
        Set<Id> quoteLineItemIds = new Set<Id>();
        Map<String, Date> devisExpirationDateMap = new Map<String, Date>();
        List<Option__c> optionsList = new List<Option__c>();
        List<Quote> quoteListToUpdate = new List<Quote>();
        Date quoteExpirationDate;
        List<Id> quoteIdList = new List<Id>();
        Quote quote = new Quote();

        // A - Initialisation et alimentation des données intermédiaires
        List<Option__c> newOptions = (List<Option__c>)Trigger.new;
        List<Option__c> optList = (newOptions != null) ? newOptions : (List<Option__c>)Trigger.old;
        for (Option__c opt : optList) {
            if(String.isNotBlank(opt.ligneDevis__c)) 
                quoteLineItemIds.add(opt.ligneDevis__c);
        }
        if(!quoteLineItemIds.isEmpty()) {
            optionsList = [SELECT Id, Option__c, Option__r.FinValidite__c, ligneDevis__c, ligneDevis__r.QuoteId, 
                            ligneDevis__r.Quote.ExpirationDate,
                            ligneDevis__r.Quote.referenceDate__c, ligneDevis__r.Quote.typeContrat__c, 
                            ligneDevis__r.Quote.devisTMC__c, ligneDevis__r.Quote.amendmentQuote__c
                            FROM Option__c WHERE ligneDevis__c IN :quoteLineItemIds];
        }

        // B - Calcul
        for (Option__c opt : optionsList) {
            System.debug('################### Option: ' + opt);
            System.debug('####### Reference Date: ' + opt.ligneDevis__r.Quote.referenceDate__c);
            System.debug('####### Expiration Date: ' + opt.ligneDevis__r.Quote.ExpirationDate);
            System.debug('####### Amendment: ' + opt.ligneDevis__r.Quote.amendmentQuote__c);
            System.debug('## Option__c: ' + opt.Option__c);
            System.debug('## Option__r.FinValidite__c: ' + opt.Option__r.FinValidite__c);

            // Calcul seulement si le devis  n'est pas un devis TMC et pas un avenant
            if(opt.ligneDevis__r.Quote.devisTMC__c == false && opt.ligneDevis__r.Quote.amendmentQuote__c == false) {
                // On récupère la date de validité de l'option
                Date refOptionValidateDate = (opt.Option__r.FinValidite__c != null) ? opt.Option__r.FinValidite__c : null;
                if(refOptionValidateDate != null) {
                    Integer daysDelaiExpiration = 14;

                    if(opt.ligneDevis__r.Quote.typeContrat__c == Constants.QUOTE_TYPECONTRAT_ISOLATION_STANDARD 
                        || opt.ligneDevis__r.Quote.typeContrat__c == Constants.QUOTE_TYPECONTRAT_ISOLATION_FOIRE) {
                        daysDelaiExpiration = PropertiesUtils.getIntegerValue('signea.circuit.defaultDelay.isolation', 30);
                    } else {
                        daysDelaiExpiration = PropertiesUtils.getIntegerValue('signea.circuit.defaultDelay.menuiserie', 14);
                    }
                        
                    // Si l'option se périme dans longtemps, on garde DateDeDevis + 14, sinon on prends la date limite de l'option
                    if(refOptionValidateDate > opt.ligneDevis__r.Quote.referenceDate__c.addDays(daysDelaiExpiration)) {
                        refOptionValidateDate = opt.ligneDevis__r.Quote.referenceDate__c.addDays(daysDelaiExpiration);
                    } else {
                        refOptionValidateDate = refOptionValidateDate;
                    }

                    // On récupère la dernière valeur enregistrée. Si la map est vide on prends DateDeDevis + 14
                    quoteExpirationDate = (devisExpirationDateMap.get(opt.ligneDevis__r.QuoteId)!= null) ? devisExpirationDateMap.get(opt.ligneDevis__r.QuoteId) : opt.ligneDevis__r.Quote.referenceDate__c.addDays(daysDelaiExpiration);

                    // On garde la date la plus rapprochée
                    if(quoteExpirationDate > refOptionValidateDate) {
                        devisExpirationDateMap.put(opt.ligneDevis__r.QuoteId, refOptionValidateDate);
                    } else {
                        devisExpirationDateMap.put(opt.ligneDevis__r.QuoteId, quoteExpirationDate);
                    }
                    System.debug('## daysDelaiExpiration: ' + daysDelaiExpiration);
                    System.debug('## refOptionValidateDate: ' + refOptionValidateDate);
                    System.debug('## Date référence devis: ' + opt.ligneDevis__r.Quote.referenceDate__c);
                    System.debug('## ExpirationDate devis: ' + quoteExpirationDate);
                }
            }
            if (Trigger.isDelete) {
                quoteIdList.add(opt.ligneDevis__r.QuoteId);
            }
        }
        System.debug('## devisExpirationDateMap: ' + devisExpirationDateMap);

        /*
        if(!quoteListToUpdate.isEmpty()){
            quote = DAL.getQuoteById(quoteIdList[0]);
            Utils_Configurator.recalculerTarifOptions(quote);
        }
        */

        // Mise à jour
        for(String quoteId : devisExpirationDateMap.keySet()){
            Quote devis = new Quote(Id = quoteId, ExpirationDate = devisExpirationDateMap.get(quoteId));
            quoteListToUpdate.add(devis);
        }
        if(!quoteListToUpdate.isEmpty()) {
            for(Quote q : quoteListToUpdate){
                System.debug('## q.referenceDate__c: ' + q.referenceDate__c);
                System.debug('## q.ExpirationDate : ' + q.ExpirationDate);
            }
            update quoteListToUpdate;
        }

        System.debug('### FIN TR022_Option.updateQuoteExpirationDate');
    }

    /**
    * @description Méthode appelée par les trigger d'insertion et MAJ (before) des options pour mettre à jour le prix
    * @param options Liste des options à mettre à jour
    */
    public static void calculatePrice (List<Option__c> options) {
        System.debug('### DEBUT TR022_Options.calculatePrice');
        Set<Id> quoteLineItemIds = new Set<Id> ();
        Set<Id> referentielOptionsIds = new Set<Id> ();
        Map<Id, QuoteLineItem> optionLineItem = new Map<Id, QuoteLineItem>();
        Map<Id, ReferentielOptions__c> referentielOptions = new Map<Id, ReferentielOptions__c>();

        for (Option__c opt : options) {
            if(String.isNotBlank(opt.ligneDevis__c)) {
                quoteLineItemIds.add (opt.ligneDevis__c);
            }
            if(String.isNotBlank(opt.Option__c)) {
                referentielOptionsIds.add (opt.Option__c);
            }
        }

        // SOQL - Récupération des lignes de devis (produits)
        if(!quoteLineItemIds.isEmpty()) {
            optionLineItem = DAL.getQuoteLineItemMap(quoteLineItemIds);
        }
        // SOQL - Récupération du référentiels des options
        if(!referentielOptionsIds.isEmpty()) {
            referentielOptions = DAL.getRefOptionsMap(referentielOptionsIds);
        }

        for (Option__c o : options) {
            System.debug('## Option: ' + o);
            ReferentielOptions__c refOption = referentielOptions.get(o.Option__c);
            if (refOption != null) {
                Double optionType = refOption.Typedeloption__c;
                System.debug('## Type option: ' + optionType);
  
                // Récupération des données du produit de l'option
                QuoteLineItem quoteLineItem = optionLineItem.get(o.ligneDevis__c);
                if (quoteLineItem != null) {
                    Double H = (quoteLineItem.Hauteur__c == null) ? 0 : quoteLineItem.Hauteur__c;
                    Double L = (quoteLineItem.Largeur__c == null) ? 0 : quoteLineItem.Largeur__c;
                    Double price = (quoteLineItem.unitprice == null) ? 0 : quoteLineItem.unitprice;
                    Double vantaux = (quoteLineItem.Nombredevantaux__c == null || quoteLineItem.Nombredevantaux__c.length() == 0) ? 0 : Integer.valueOf(quoteLineItem.Nombredevantaux__c);
            
                    o.Valorisation__c = (o.Valorisation__c == null) ? 0 : o.Valorisation__c;
            
                    if(Utils_Configurator.isReferencePromotion(refOption)) {
                        continue;
                    }
                    
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
        System.debug('### FIN TR022_Options.calculatePrice');
    }

    /**
    * @description Mise à jour du coefficient thermique
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void calculateCoefThermique(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR022_Option.calculateCoefThermique');
        List<QuoteLineItem> newQuoteLinesItems = new List<QuoteLineItem>();
        List<String> qliIdList = new List<String>();
        Map<String, coeffTh__c> coeffThermiqueProduitMap = new Map<String, coeffTh__c>();

        List<Option__c> optionsList = (List<Option__c>)Trigger.new;

        // Récupération quotelineitem
        for(Option__c opt : optionsList){
            qliIdList.add(opt.ligneDevis__c);
        }
        newQuoteLinesItems = [SELECT Id, PricebookEntryId, PricebookEntry.Product2Id, referenceDate__c 
                                FROM QuoteLineItem WHERE Id IN :qliIdList];
        System.debug('## newQuoteLinesItems: ' + newQuoteLinesItems.size());

        /********* Coefficient thermique **********************/
        // Récupération des ID des options
        Set<String> optionsListId = new Set<String>();
        for (Option__c opt : optionsList) {
            optionsListId.add(opt.Option__c);
        }
        System.debug('## optionsListId: ' + optionsListId.size());

        // Récupération des ID des produits
        Set<String> produitsListId = new Set<String>();
        for (QuoteLineItem qli : newQuoteLinesItems) {
            produitsListId.add(qli.PricebookEntry.Product2Id);
        }
        System.debug('## produitsListId: ' + produitsListId.size());

        Map<String, Map<String, Option__c>> optionsByQuoteLineItem = new Map<String, Map<String, Option__c>>();
        for(QuoteLineItem qli : newQuoteLinesItems) {
            Map<String, Option__c> optionsMap  = new Map<String, Option__c>();
            for(Option__c option : optionsList) {
                if(qli.Id == option.ligneDevis__c) {
                    optionsMap.put(option.Codeoption__c, option);
                }
            }
            optionsByQuoteLineItem.put(qli.Id, optionsMap);
        }
        System.debug('## optionsByQuoteLineItem: ' + optionsByQuoteLineItem);

        // Construction de la MAP des coefficient thermique selon ID produits et options
        List<coeffTh__c> coeffThermiqueList = [SELECT Id, famille__c, option1__c, option2__c, option3__c, option1__r.Codeoption__c, option2__r.Codeoption__c, option3__r.Codeoption__c,
                                                valeurCoef1__c, valeurCoef2__c, unite1__c, unite2__c, coef1__c, coef2__c, dateDebut__c, dateFin__c FROM coeffTh__c
                                                WHERE famille__c IN :produitsListId
                                                    AND option1__c IN :optionsListId
                                                    AND (option2__c = null OR option2__c IN :optionsListId)
                                                    AND (option3__c = null OR option3__c IN :optionsListId)
                                                ORDER BY dateDebut__c ASC, option2__c ASC NULLS LAST, option3__c ASC NULLS LAST];        
        System.debug('## coeffThermiqueList: ' + coeffThermiqueList);

        // Liste toutes les lignes de devis
        Set<QuoteLineItem> qliListOption1 = new Set<QuoteLineItem>();
        // Pour Options 2 ou 3
        for(QuoteLineItem qli : newQuoteLinesItems) {     
            System.debug('######### Check for coeff  for QLI: ' +qli.Id+ ' / '+qli.referenceDate__c);
            String produitID = qli.PricebookEntry.Product2Id;
            Map<String, Option__c> optionsMap  = new Map<String, Option__c>();
            optionsMap = optionsByQuoteLineItem.get(qli.Id);
            System.debug('## optionsMap: ' + optionsMap);

            // Pour tous les coefficient, on map par rapport au produit de la ligne de devis
            for(coeffTh__c coeffThermique : coeffThermiqueList) {
                System.debug('## Coeff: ' + coeffThermique.Id + ' / '+ coeffThermique.option1__r.Codeoption__c+' / '+coeffThermique.dateDebut__c+' / '+coeffThermique.dateFin__c);
                if(coeffThermique.famille__c == produitID) {
                    // Si option1 du coefficient correspond au produit
                    if(optionsMap.get(coeffThermique.option1__r.Codeoption__c) != null &&
                        coeffThermique.dateDebut__c <= qli.referenceDate__c &&
                        (coeffThermique.dateFin__c == null || coeffThermique.dateFin__c >= qli.referenceDate__c)) {
                        if( (coeffThermique.option2__c != null && optionsMap.get(coeffThermique.option2__r.Codeoption__c) != null) ||
                            (coeffThermique.option3__c != null && optionsMap.get(coeffThermique.option3__r.Codeoption__c) != null)
                        ) {
                            coeffThermiqueProduitMap.put(qli.Id, coeffThermique);
                            break;
                        } else {
                            qliListOption1.add(qli);
                        }
                    }
                }
            }
        }
        System.debug('## qliListOption1: ' + qliListOption1.size());
        System.debug('## coeffThermiqueProduitMap: ' + coeffThermiqueProduitMap);

        for(QuoteLineItem qli : qliListOption1) {
            String produitID = qli.PricebookEntry.Product2Id;
            Map<String, Option__c> optionsMap  = new Map<String, Option__c>();
            optionsMap = optionsByQuoteLineItem.get(qli.Id);
            // Pour tous les coefficient, on map par rapport au produit de la ligne de devis
            for(coeffTh__c coeffThermique : coeffThermiqueList) {
                if(coeffThermique.famille__c == produitID) {
                    // Si option1 du coefficient correspond au produit
                    if(optionsMap.get(coeffThermique.option1__r.Codeoption__c) != null &&
                        coeffThermique.option2__c == null && coeffThermique.option3__c == null
                    ) {
                        coeffThermiqueProduitMap.put(qli.Id, coeffThermique);
                        break;
                    }
                }
            }
        }

        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();
        for(QuoteLineItem qli : newQuoteLinesItems) {
            System.debug('######### Construct coeff for: ' +qli.Id+ ' / '+qli.referenceDate__c);
            String coefficienThermiqueString = null;
            coeffTh__c coefficienThermiqueObject = new coeffTh__c();

            // Si des coefficient existe, récupération de la liste
            if(coeffThermiqueProduitMap != null && coeffThermiqueProduitMap.get(qli.Id) != null) {
                coefficienThermiqueObject = coeffThermiqueProduitMap.get(qli.Id);
                if(coefficienThermiqueObject != null) {
                    coefficienThermiqueString = '';
                    // Construction du texte - Coefficient 1
                    if(String.isNotBlank(coefficienThermiqueObject.coef1__c) && coefficienThermiqueObject.valeurCoef1__c != null) {
                        coefficienThermiqueString += coefficienThermiqueObject.coef1__c + ' = ' + String.valueOf(coefficienThermiqueObject.valeurCoef1__c).replace('.', ',');
                        if(String.isNotBlank(coefficienThermiqueObject.unite1__c)) {
                            coefficienThermiqueString += ' ' + coefficienThermiqueObject.unite1__c;
                        }
                    }
                    // Coefficient 2                    
                    if(String.isNotBlank(coefficienThermiqueObject.coef2__c) && coefficienThermiqueObject.valeurCoef2__c != null) {
                        coefficienThermiqueString +=  ', ';
                        coefficienThermiqueString += coefficienThermiqueObject.coef2__c + ' = ' + String.valueOf(coefficienThermiqueObject.valeurCoef2__c).replace('.', ',');
                        if(String.isNotBlank(coefficienThermiqueObject.unite2__c)) {
                            coefficienThermiqueString += ' ' + coefficienThermiqueObject.unite2__c;
                        }
                    }
                    coefficienThermiqueString = coefficienThermiqueString.trim();
                }
            }
            System.debug('## Coeff on line: ' + coefficienThermiqueString);
            qli.thermalCoefficients__c = coefficienThermiqueString;
            qliToUpdate.add(qli);
        }

        System.debug('## qliToUpdate: ' + qliToUpdate.size());
        if(!qliToUpdate.isEmpty()){
            update qliToUpdate;
        }        

        System.debug('### FIN TR022_Option.calculateCoefThermique');
    }
}