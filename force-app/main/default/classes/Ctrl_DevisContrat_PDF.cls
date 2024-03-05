//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_DevisContrat_PDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/12/2022
//-- Version     : 1.4
//-- * 1.4 : Mise à jour pour utiliser champ Famille des produits
//-- * 1.3 : RQM-256 : Evolutions pré-Kube3
//-- * 1.2 : RQM-77 : PDF Depot seulement pour les devis TMC
//-- * 1.1 : RQM-47 : Calcul de la prime CEE / Isolation des combles
//-- * 1.0 : Init : Nouvelle version édition PDF du devis et contrat
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_DevisContrat_PDF {
    public Quote quote {get; set;}
    public Map<String, List<Option__c>> mapOptions {get;set;}
    // Liste des produits du devis/contrat
    public List<ProductItem> prodList {get; set;}
    public List<ProductItem> prodCreditList {get; set;}
    public List<ProductItem> prodNonCreditList {get; set;}
    private Map<Id, ProductItem> productItemMap;
    private Map<String, coeffTh__c> coeffThermiqueProduitMap;
    public Boolean isContrat {get; set;} // Parametre pour édition devis ou contrat
    public Boolean isDevis {get; set;} // Parametre pour édition DIPC ou Devis
    public Boolean isDevisDepot {get; set;}
    public Boolean isFoire {get; set;} // Parametre pour un document visant un devis Foire
    public Boolean isIsolation {get; set;} // Parametre pour les contrats de type isolation
    public Boolean isEligibleCreditImpot {get; set;} // Parametre pour les contrats de type isolation
    public Boolean isEligibleCEE {get; set;} // Parametre pour les devis avec montant CEE

    public Integer nbPortesEtFenetres {get; set;}
    public Decimal partPortesEtFenetresRenoves {get; set;}
    public Boolean forfaitA {get; set;}
    public Boolean forfaitB {get; set;}
    public Boolean forfaitC {get; set;}
    public Decimal prixForfaitA {get; set;}
    public Decimal prixForfaitB {get; set;}
    public Decimal prixForfaitC {get; set;}
    public String prixForfaitTotal {get; set;}
    public Boolean isSameAddress {get;set;}
    public Decimal remiseDevis {get;set;}
    public String totalNetHTContratText {get;set;}
    public String remiseDevisText {get;set;}
    public Decimal solde {get; set;}
    public Decimal pourcentageSolde {get; set;}
    public Integer dureeDevis {get; set;}
    public Date qualibatDate {get; set;}
    public String qualibatNumber {get; set;}
    public String qualibatSiret {get; set;}
    public String qualibatBIC {get; set;}
    public String qualibatIBAN {get; set;}
    public Boolean isRGEDisponible {get; set;}
    public Set<String> categorieGarantieList {get; set;}
    public Integer categorieListSize {get; set;}
    public String sitePartenaire {get; set;}
    public String telPartenaire {get; set;}
    public Date dateValiditeCCE {get; set;}

    /**
    * @description Constructeur
    * @return Ctrl_DevisContrat_PDF Controleur
    */
    public Ctrl_DevisContrat_PDF() {
        isDevis = false;
        isFoire = false;
        isDevisDepot = false;
        isIsolation = false;
        isEligibleCreditImpot = false;
        isEligibleCEE = false;
        String quoteId = Apexpages.currentPage().getParameters().get('qId');
        String typeEdition = Apexpages.currentPage().getParameters().get('type');
        if(Apexpages.currentPage().getParameters().get('doc') == 'sansnum') isDevis = true;
        if(Apexpages.currentPage().getParameters().get('type') == 'DevisDepot') isDevisDepot = true;
        isContrat = (typeEdition == 'contrat') ? true : false;
        List<Option__c> optionsList = new List<Option__c>();
        List<Quote> quoteList = new List<Quote>();

        try {
            // Init
            coeffThermiqueProduitMap = new Map<String, coeffTh__c>();
            prodList = new List<ProductItem>();
            prodCreditList = new List<ProductItem>();
            prodNonCreditList = new List<ProductItem>();
            productItemMap = new Map<Id, ProductItem>();
            forfaitA = false;
            forfaitB = false;
            forfaitC = false;
            prixForfaitA = 0;
            prixForfaitB = 0;
            prixForfaitC = 0;
            prixForfaitTotal = '0';
            nbPortesEtFenetres = 0;
            partPortesEtFenetresRenoves = 0;
            sitePartenaire = PropertiesUtils.getStringValue('document.kpark.site', 'www.kpark.fr');
            telPartenaire = PropertiesUtils.getStringValue('site.tel.support', ' ');
            dateValiditeCCE = PropertiesUtils.getDateValue('document.date.validite.offre.cce');

            quoteList = [SELECT numeroDevis__c, villeDemandeurs__c, dateDevis__c, referenceDate__c, BonusprojetPourcentage__c, RemisevendeurglobaleFormule__c, modeFinancement__c, mntAcompteAttendu__c, pctAcompteAttendu__c,
                          Total_TTC_devis__c, Total_TTC_hors_remise_enseigne__c, Remise_Enseigne_Options__c , villeChantier__c, tvaReduite_prv__c, ExpirationDate, delaiInstallationMin__c, delaiInstallationMax__c,
                          tvaReduite_pb__c, tvaReduite__c, tvaNormal_prv__c, tvaNormal_pb__c, tvaNormal__c, tvaIntermediaire_prv__c, tvaIntermediaire_pb__c, source__c, typeContrat__c, resteACharge__c,
                          tvaIntermediaire__c, totalTTCContrats__c, totalHTContrats__c, telephoneMobileDemandeurs__c, telephoneMobileChantier__c, acompteRemiseMetreur__c, acomptePreleveeCompte__c,
                          telephoneDomicileDemandeurs__c, telephoneDomicileChantier__c, telephoneDemandeurs__c, telephoneChantier__c, rueDemandeurs__c, mntAcompte2Attendu__c, pctAcompte2Attendu__c,
                          rueChantier__c, nomDemandeurs__c,nomChantier__c ,prenomDemandeurs__c, prenomChantier__c, paysDemandeurs__c, paysChantier__c, devisTMC__c, TotalHTRemise__c, TotalHTDevis__c,
                          emailDemandeurs__c, emailChantier__c, departementDemandeurs__c, departementChantier__c, codePostalDemandeurs__c, codePostalChantier__c, TotalTTClignes__c,
                          civiliteDemandeurs__c, civiliteChantier__c, autreTelephoneDemandeurs__c, autreTelephoneChantier__c, compte__r.complementAdresse__c,
                          TotalHTlignes__c ,RemisevendeurglobaleDeviseFormule__c, Bonus_projetFormule__c , Pricebook2Id, OpportunityId, C2E__c, Opportunity.Owner.FirstName, Opportunity.Owner.LastName, Opportunity.Chantier__r.Id,
                          Opportunity.chantier__r.complementAdresse__c, Opportunity.autreCompte__c, Opportunity.chantier__c, Opportunity.chantier__r.chauffages__c,
                          Opportunity.chantier__r.anneeConstruction__c, Opportunity.chantier__r.typeResidence__c, Opportunity.chantier__r.nbPortesEtFenetres__c, Opportunity.chantier__r.codeMagasinActuel__c,
                          Opportunity.chantier__r.typeHabitation__c, Opportunity.chantier__r.sectorisation__r.rueDepot__c, Opportunity.chantier__r.sectorisation__r.codePostalDepot__c, Opportunity.chantier__r.sectorisation__r.villeDepot__c,
                          Opportunity.chantier__r.sectorisation__r.telephoneDepot__c, Opportunity.chantier__r.sectorisation__r.telecopieDepot__c, 
                          Opportunity.chantier__r.etage__c, Opportunity.chantier__r.codeAcces__c, Opportunity.chantier__r.interphone__c, amendmentQuote__c, initialQuoteNumber__c,
                          Opportunity.chantier__r.sectorisation__r.emailDepot__c, quote.Opportunity.chantier__r.sectorisation__r.codeDepot__c, montantPrimeCEE__c,
                          natureLocaux__c, autreNatureLocaux__c, localisationTravaux__c, typeAdresse__c, autreTypeAdresse__c, naturesTravaux__c, elementsTravaux__c, milliemesLocalisationTravaux__c,
                          BillingCity, ShippingCity,Phone,ShippingPostalCode, Account.etage__c, Account.codeAcces__c, Account.interphone__c,
                          BillingStreet, ShippingStreet, BillingName,ShippingName, ShippingCountry, BillingCountry, Email, ShippingState,BillingState, BillingPostalCode
                        FROM Quote WHERE Id = :quoteId];

            // Si pas de devis, rien faire            
            if(String.isBlank(quoteId) || quoteList.isEmpty()) {
                throw new KubeException('## Devis non existant');
            } else {
                quote = quoteList.get(0);

                if(quote.typeContrat__c == Constants.QUOTE_TYPECONTRAT_FOIRE) 
                    isFoire = true;
                else if(String.isBlank(quote.typeContrat__c)) {
                    Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Quote').getDescribe().fields.getMap();
                    String defaultValue = String.valueOf(fieldsMap.get('typeContrat__c').getDescribe().getDefaultValue());
                    if(defaultValue == Constants.QUOTE_TYPECONTRAT_FOIRE) 
                        isFoire = true;
                } else if(quote.typeContrat__c == Constants.QUOTE_TYPECONTRAT_ISOLATION_STANDARD){
                    isIsolation = true;
                } else if(quote.typeContrat__c == Constants.QUOTE_TYPECONTRAT_ISOLATION_FOIRE){
                    isIsolation = true;
                    isFoire = true;
                }

                // Erreurs
                checkContext();

                // Calcul solde avec/sans prime
                if(quote.mntAcompteAttendu__c != null && quote.mntAcompte2Attendu__c != null && quote.Total_TTC_devis__c != null){
                    Decimal mtPrimeCee = (quote.montantPrimeCEE__c == null) ? 0 : quote.montantPrimeCEE__c;
                    solde = quote.Total_TTC_devis__c - quote.mntAcompteAttendu__c - quote.mntAcompte2Attendu__c - mtPrimeCee;
                    pourcentageSolde = MATH.ROUND(100 - (quote.pctAcompteAttendu__c == null ? (((quote.mntAcompteAttendu__c + quote.mntAcompte2Attendu__c - mtPrimeCee) * 100) / (quote.Total_TTC_devis__c - mtPrimeCee)) : quote.pctAcompteAttendu__c + quote.pctAcompte2Attendu__c));
                } else if(quote.mntAcompteAttendu__c != null && quote.Total_TTC_devis__c != null){
                    Decimal mtPrimeCee = (quote.montantPrimeCEE__c == null) ? 0 : quote.montantPrimeCEE__c;
                    solde = quote.Total_TTC_devis__c - quote.mntAcompteAttendu__c - mtPrimeCee;
                    pourcentageSolde = MATH.ROUND(100 - (quote.pctAcompteAttendu__c == null ? (((quote.mntAcompteAttendu__c - mtPrimeCee) * 100) / (quote.Total_TTC_devis__c - mtPrimeCee)) : quote.pctAcompteAttendu__c));
                } else {
                    solde = null;
                }
                // Récupération Lignes de devis avec filtre sur les lignes annulées
                List<QuoteLineItem> qliListTemp = DAL.getQuoteLineItemList(quoteId, 'SortOrder, PricebookEntry.Product2.Name, NumLigneText__c, PricebookEntry.Product2.Family');
                List<QuoteLineItem> qliList = new List<QuoteLineItem>();
                for(QuoteLineItem qli : qliListTemp){
                    if(!qli.cancelledLine__c){
                        qliList.add(qli);
                    }
                }
                // Récupération options
                optionsList = DAL.getOptionList(quoteId);

                /********* Coefficient thermique **********************/
                // Récupération des ID des options
                Set<String> optionsListId = new Set<String>();
                for (Option__c opt : optionsList) {
                    optionsListId.add(opt.Option__c);
                }
                // Récupération des ID des produits
                Set<String> produitsListId = new Set<String>();
                for (QuoteLineItem quoteLineItem : qliList) {
                    produitsListId.add(quoteLineItem.PricebookEntry.Product2.Id);
                }
                Map<String, Map<String, Option__c>> optionsByQuoteLineItem = new Map<String, Map<String, Option__c>>();
                for(QuoteLineItem qli : qliList) {
                    Map<String, Option__c> optionsMap  = new Map<String, Option__c>();
                    for(Option__c option : optionsList) {
                        if(qli.Id == option.ligneDevis__c) {
                            optionsMap.put(option.Codeoption__c, option);
                        }
                    }
                    optionsByQuoteLineItem.put(qli.Id, optionsMap);
                }
                // Construction de la MAP des coefficient thermique selon ID produits et options
                List<coeffTh__c> coeffThermiqueList = [SELECT Id, famille__c, option1__c, option1__r.Codeoption__c, option2__r.Codeoption__c, option3__r.Codeoption__c,
                                                        valeurCoef1__c, valeurCoef2__c, unite1__c, unite2__c, coef1__c, coef2__c FROM coeffTh__c
                                                        WHERE famille__c IN :produitsListId
                                                            AND dateDebut__c <= :quote.referenceDate__c
                                                            AND (dateFin__c= null OR dateFin__c >= :quote.referenceDate__c)
                                                            AND option1__c IN :optionsListId
                                                            AND (option2__c = null OR option2__c IN :optionsListId)
                                                            AND (option3__c = null OR option3__c IN :optionsListId)
                                                        ORDER BY dateDebut__c ASC, option2__c ASC NULLS LAST, option3__c ASC NULLS LAST];
                // Liste toutes les lignes de devis
                Set<QuoteLineItem> qliListOption1 = new Set<QuoteLineItem>();
                // Pour Options 2 ou 3
                for(QuoteLineItem qli : qliList) {
                    // On check l'eligibilité CEE
                    if(qli.eligibleCEE__c){
                        isEligibleCEE = true;
                    }
                    String produitID = qli.PricebookEntry.Product2.Id;
                    Map<String, Option__c> optionsMap  = new Map<String, Option__c>();
                    optionsMap = optionsByQuoteLineItem.get(qli.Id);
                    // Pour tous les coefficient, on map par rapport au produit de la ligne de devis
                    for(coeffTh__c coeffThermique : coeffThermiqueList) {
                        if(coeffThermique.famille__c == produitID) {
                            // Si option1 du coefficient correspond au produit
                            if(optionsMap.get(coeffThermique.option1__r.Codeoption__c) != null) {
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

                for(QuoteLineItem qli : qliListOption1) {
                    String produitID = qli.PricebookEntry.Product2.Id;
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

                /********* Autre **********************/
                // Construction Map des options
                mapOptions = new Map<String, List<Option__c>>();
                for (QuoteLineItem quoteLineItem : qliList) {
                    List<Option__c> optTemp = new List<Option__c>();
                    for (Option__c opt : optionsList) {
                        if(opt.ligneDevis__c == quoteLineItem.Id)
                            optTemp.add(opt);
                    }
                    mapOptions.put(quoteLineItem.Id, optTemp);
                }
                
                // Certificat RGE
                isRGEDisponible = true;
                for(CertificatRGE__c certif : CertificatRGE__c.getall().values()) {
                    if (quote.referenceDate__c != null && PropertiesUtils.getDateValue('signea.certificatQualibat') >= quote.referenceDate__c) {
                        qualibatDate = PropertiesUtils.getDateValue('signea.certificatQualibat');
                        qualibatNumber = String.ValueOf(PropertiesUtils.getIntegerValue('signea.certificatQualibat', 110106));
                        qualibatSiret = String.ValueOf(PropertiesUtils.getIntegerValue('signea.siretQualibat', null));
                    } else if (quote.Opportunity.chantier__r.sectorisation__r.codeDepot__c != null && quote.referenceDate__c != null &&
                                certif.codeDepot__c == quote.Opportunity.chantier__r.sectorisation__r.codeDepot__c &&
                                certif.dateDebutValidite__c <= quote.referenceDate__c &&
                                certif.dateFinValidite__c >= quote.referenceDate__c) {
                        qualibatDate = certif.dateFinValidite__c;
                        qualibatNumber = certif.numCertificat__c;
                        qualibatSiret = certif.numSiret__c;
                        qualibatBIC = certif.bic__c;
                        qualibatIBAN = certif.IBAN__c;
                    }
                }
                if(qualibatDate == null || qualibatNumber == null || qualibatNumber == '') isRGEDisponible = false;
                
                // Durée du devis
                if(quote.ExpirationDate != null && quote.dateDevis__c != null)
                    dureeDevis = quote.dateDevis__c.daysBetween(quote.ExpirationDate.addDays(1));
                // Adresse identique
                if((quote.rueChantier__c == quote.rueDemandeurs__c) && (quote.villeChantier__c == quote.villeDemandeurs__c ) && (quote.codePostalChantier__c == quote.codePostalDemandeurs__c ) &&
                   (quote.nomChantier__c == quote.nomDemandeurs__c) && (quote.prenomChantier__c == quote.prenomDemandeurs__c ) && (quote.civiliteChantier__c == quote.civiliteDemandeurs__c ))
                    isSameAddress = true;
                else
                    isSameAddress = false;

                // Remise
                remiseDevis = 0;
                remiseDevisText = '0';
                totalNetHTContratText = '0';
                Decimal remiseVendeur = 0;
                Decimal bonusProjet = 0;
                Decimal totalNetHTContrat = 0;
                remiseVendeur = (quote.RemisevendeurglobaleDeviseFormule__c == null) ? 0 : quote.RemisevendeurglobaleDeviseFormule__c;
                bonusProjet = (quote.Bonus_projetFormule__c == null) ? 0 : quote.Bonus_projetFormule__c;
                remiseDevis =  remiseVendeur - bonusProjet;
                if(quote.Total_TTC_devis__c == null)
                    remiseDevisText = nombreParseur(quote.TotalTTClignes__c + quote.Remise_Enseigne_Options__c);
                else 
                    remiseDevisText = nombreParseur(quote.TotalTTClignes__c - quote.Total_TTC_devis__c + quote.Remise_Enseigne_Options__c);

                for (QuoteLineItem qli : qliList) {
                    //parcours des produits pour trouver le / les forfaits puis recuperation du prix sur la qli associée
                    totalNetHTContrat = totalNetHTContrat + qli.prixHTTarifRemise__c;

                    if(qli.PricebookEntry.Product2.Name.equals('FORFAIT A')){
                        forfaitA = true;
                        // prixForfaitA = qli.TotalTTCligne__c;
                        prixForfaitA = qli.prixHTTarif__c;
                    }
                    if(qli.PricebookEntry.Product2.Name.equals('FORFAIT B')){
                        forfaitB = true;
                        // prixForfaitB = qli.TotalTTCligne__c;
                        prixForfaitB = qli.prixHTTarif__c;
                    }
                    if(qli.PricebookEntry.Product2.Name.equals('FORFAIT C')){
                        forfaitC = true;
                        // prixForfaitC = qli.TotalTTCligne__c;
                        prixForfaitC = qli.prixHTTarif__c;
                    }

                    // Construction objet produit
                    processProduct(qli);
                    System.debug('## Ajout du produit : '+qli.Id + ' / '+qli.PricebookEntry.Product2.Name);
                }
                prixForfaitTotal = nombreParseur(prixForfaitA + prixForfaitB + prixForfaitC);
                totalNetHTContratText = nombreParseur(totalNetHTContrat);
                if(nbPortesEtFenetres != 0) {
                    partPortesEtFenetresRenoves = (quote.opportunity.chantier__r.nbPortesEtFenetres__c == 0 || quote.opportunity.chantier__r.nbPortesEtFenetres__c == null) ? 0 : ((nbPortesEtFenetres / quote.opportunity.chantier__r.nbPortesEtFenetres__c) * 100).setScale(0, RoundingMode.HALF_EVEN);
                }

                // Garanties
                Set<String> categorieList = new Set<String>();
                for(QuoteLineItem qli : qliList) {
                    if(qli.dureeGarantie1__c != null && qli.dureeGarantie1__c != 0 ) categorieList.add(qli.libelleCategorieGarantie1__c);
                    if(qli.dureeGarantie2__c != null && qli.dureeGarantie2__c != 0 ) categorieList.add(qli.libelleCategorieGarantie2__c);
                    if(qli.dureeGarantie3__c != null && qli.dureeGarantie3__c != 0 ) categorieList.add(qli.libelleCategorieGarantie3__c);
                    if(qli.dureeGarantie4__c != null && qli.dureeGarantie4__c != 0 ) categorieList.add(qli.libelleCategorieGarantie4__c);
                    if(qli.dureeGarantie5__c != null && qli.dureeGarantie5__c != 0 ) categorieList.add(qli.libelleCategorieGarantie5__c);
                    if(qli.dureeGarantie6__c != null && qli.dureeGarantie6__c != 0 ) categorieList.add(qli.libelleCategorieGarantie6__c);
                    if(qli.dureeGarantie7__c != null && qli.dureeGarantie7__c != 0 ) categorieList.add(qli.libelleCategorieGarantie7__c);
                    if(qli.dureeGarantie8__c != null && qli.dureeGarantie8__c != 0 ) categorieList.add(qli.libelleCategorieGarantie8__c);
                    if(qli.dureeGarantie9__c != null && qli.dureeGarantie9__c != 0 ) categorieList.add(qli.libelleCategorieGarantie9__c);
                    if(qli.dureeGarantie10__c != null && qli.dureeGarantie10__c != 0 ) categorieList.add(qli.libelleCategorieGarantie10__c);
                }
                categorieGarantieList = categorieList;

                categorieListSize = categorieList.size();

                System.debug('categorieGarantieList : '+categorieGarantieList);

                /********* Init objets pour affichage **********************/
                initOptions(optionsList);
                System.debug('## Taille liste produits : '+prodList.size());
                System.debug('## Liste produits : '+prodList);
                
                System.debug('## Taille liste produits pour crédit : '+prodCreditList.size());
                System.debug('## Liste produits pour crédit : '+prodCreditList);
                
                System.debug('## Taille liste produits pas pour crédit : '+prodNonCreditList.size());
                System.debug('## Liste produits pas pour crédit : '+prodNonCreditList);
                
                for(ProductItem produitStocke : prodList){
                    if(!produitStocke.qli.elligibleCreditImpot__c)
                        prodNonCreditList = addUniqueProductToList(prodNonCreditList, produitStocke);
                    else if(produitStocke.qli.elligibleCreditImpot__c){
                        prodCreditList = addUniqueProductToList(prodCreditList, produitStocke);
                        isEligibleCreditImpot = true;
                    }
                }
            }

        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
            throw e;
        }
    }

    /**
    * @description Méthode pour traiter les produits de type porte/fenetre et autre (avec hauteur et largeur)
    * @param qli Ligne de devis à traiter
    */
    public void processProduct(QuoteLineItem qli) {
        ProductItem produit = new ProductItem(coeffThermiqueProduitMap);
        produit.qli = qli;
        produit.product2 = qli.PricebookEntry.Product2;

        // Vérification si fenetre ou porte
        Boolean isWindowOrDoor = (String.isNotBlank(produit.product2.Family) && (produit.product2.Family.containsIgnoreCase('FEN') 
                                    ||  produit.product2.Family.containsIgnoreCase('PORTE')));
        System.debug('## isWindowOrDoor: ' + isWindowOrDoor);

        if(isWindowOrDoor) {
            Integer quantite = (qli.Quantity == null) ? 0 : (Integer)qli.Quantity;
            System.debug('## quantite: ' + quantite);
            System.debug('## nbPortesEtFenetres: ' + nbPortesEtFenetres);
            nbPortesEtFenetres = nbPortesEtFenetres + quantite;
        }

        // Options
        if(mapOptions != null) {
            List<Option__c> options = new List<Option__c>();
            if(mapOptions.get(qli.Id) != null) options = mapOptions.get(qli.Id);
            for (Option__c option : options) {
                Boolean isOther = false;
                // Eco Subvention
                if(option.CodeOption__c != null && option.CodeOption__c.containsIgnoreCase(Constants.EcoPrime)) {
                  produit.ecoSubventionMontant = produit.ecoSubventionMontant + Math.abs(option.PrixHT__c);
                  produit.ecoSubvention = true;
                }
                // Définition des options (case à cocher)
                if(String.isNotBlank(option.Libelleoption__c)) {
                    if(option.Libelleoption__c.containsIgnoreCase('OSCILLO')) {
                        produit.oscilloBattant = true;
                    }
                    if((option.Libelleoption__c.containsIgnoreCase('SEMI RENOVATION') || option.Libelleoption__c.containsIgnoreCase('SEMI-RENOVATION'))) {
                        produit.poseSemi = true;
                    }
                    else if(option.Libelleoption__c.containsIgnoreCase('RENOVATION')) {
                        produit.poseExistant = true;
                    }
                    else if(option.Libelleoption__c.containsIgnoreCase('DEPOSE TOTALE')) {
                        produit.poseTotal = true;
                    }
                    // Si ce n'est pas une fenetre ou une porte, on définit l'option INSTALLATION comme autre
                    if(!isWindowOrDoor && option.Pack__c != null && option.Pack__c.containsIgnoreCase('INSTALLATION')) {
                        produit.installationAutre = option.Libelleoption__c;
                        produit.poseAutre = true;
                        isOther = true;
                    }
                }

                // Construction de la liste des autres options
                if(isOther) {
                    if(produit.otherOptions == '') {
                        produit.otherOptions = option.Libelleoption__c;
                    } else {
                        produit.otherOptions = produit.otherOptions + ', ' + option.Libelleoption__c;
                    }
                }
            }
        }
        prodList.add(produit);
        // Ajout des options pour les ligne de devis dans la MAP
        productItemMap.put(qli.Id, produit);
        System.debug('produit.coeffThermiqueProduitMap: '+produit.coeffThermiqueProduitMap);
    }

    /**
    * @description Alimentation des listes de produit pour le crédit d'impot (sans doublons)
    * @param prodList Liste des produits de la ligne
    * @param produit Produit à vérifier et à ajouter si pas de doublon dans prodList
    */
    public List<ProductItem> addUniqueProductToList(List<ProductItem> prodList, ProductItem produit) {
        Boolean isDoublon = false;
        for(ProductItem pi : prodList){
            System.debug('pi.qli.Modele__c : '+pi.qli.Modele__c);
            System.debug('produit.qli.Modele__c : '+produit.qli.Modele__c);
            
            System.debug('pi.optVersion : '+pi.optVersion);
            System.debug('produit.optVersion : '+produit.optVersion);
            
            System.debug('pi.optVersion.Libelleoption__c : '+pi.optVersion.Libelleoption__c);
            System.debug('produit.optVersion.Libelleoption__c : '+produit.optVersion.Libelleoption__c);
            if(produit.qli.Modele__c == pi.qli.Modele__c && produit.optVersion.Libelleoption__c == pi.optVersion.Libelleoption__c && produit.coeffThermiqueProduitMap == pi.coeffThermiqueProduitMap)
                isDoublon = true;
        }
        if(!isDoublon) 
            prodList.add(produit);
        System.debug('prodList : ' + prodList);
        return prodList;
    }

    /**
    * @description Parseur de nombre décimal
    * @param input Nombe décimal à convertir avec 2 chiffres après la virgule
    * @return String Nombre en chaine de caractère
    */
    public String nombreParseur(Decimal input) {
        String output;
        input = input.setScale(2, RoundingMode.HALF_EVEN);
        output = String.valueOf(input);
        output = output.replace('.', ',');
        if(output.length() > 6 && output.length() <= 9){
            output = output.substring(0, output.length() - 6) + ' ' + output.substring(output.length() - 6);
        } else if(output.length() > 9){
            output = output.substring(0, output.length() - 9) + ' ' + output.substring(output.length() - 9, output.length() - 6) + ' ' + output.substring(output.length() - 6);
        }
        return output;
    }

    /**
    * @description Fonction de vérifiaction du contexte - Affichage des messages d'erreur
    * @return Boolean True si pas d'erreur sinon False
    */
    private Boolean checkContext() {

        // Erreurs génériques
        // 01 - Pour un signataire principal B2B, il faut un contact par défaut
        // 02 - Pour un devis TMC, seul le PDF Depot est disponible
        Boolean errorContextTVA20 = quote.tvaIntermediaire__c == 0 && quote.tvaReduite__c == 0 && Apexpages.currentPage().getParameters().get('type') == null && Apexpages.currentPage().getParameters().get('doc') == null;
        Boolean errorContextTMC = quote.devisTMC__c && !isDevisDepot;
        Boolean found = errorContextTVA20 || errorContextTMC;

        if (found) {
            String message = '';
            if (errorContextTMC)
                message = 'Vous ne pouvez pas générer ce type de PDF pour un devis TMC (Toute Modification Comprise).';
            else if (errorContextTVA20)
                message = 'L\'attestation TVA n\'est pas nécessaire pour ce devis.';

            throw new KubeException(message);
        } else {
            return false;
        }
    }
    
    /**
    * @description Méthode d'ajout des options dans le produit de la sous classe ProductItem
    * @param optList Liste des options du devis
    */
    private void initOptions(List<Option__c> optList){
        for(Option__c opt : optList){
            if(productItemMap.get(opt.ligneDevis__c) != null) productItemMap.get(opt.ligneDevis__c).addOption(opt);
        }
    }
    
    /**
    * @description Méthode de récupération des informations formatés du devis et affichage dans le pied de page
    * @return Information du devis à afficher dans le pied de page
    */
    public String getInfoDevis(){
        Datetime now = Datetime.now();
        string info = now.format('yyyyMMddHHmm') +
                        (
                            (quote.opportunity.chantier__c == null || quote.opportunity.chantier__r.codeMagasinActuel__c == null) ?
                            'xxxx' :
                            quote.opportunity.chantier__r.codeMagasinActuel__c.right(4)
                        );

        Decimal ecart = (-1) * (quote.RemisevendeurglobaleFormule__c == null ? 0 : quote.RemisevendeurglobaleFormule__c);
        info += String.valueof(ecart.setScale(2));
        Decimal ecartEuro = (-1) * (quote.RemisevendeurglobaleDeviseFormule__c == null ? 0 : quote.RemisevendeurglobaleDeviseFormule__c);
        info += String.valueof(ecartEuro);
        return info;
    }

    /************************************************
    /******************** SOUS CLASSES **************
    /************************************************/
    public class ProductItem {
        public QuoteLineItem qli {get; set;}
        public Product2 product2 {get; set;}
        public List<OptionItem> optList {get; set;}
        public String emplacement {get; set;}
        public Boolean isPortail {get; set;}
        public Boolean oscilloBattant {get; set;}
        public String installationAutre {get; set;}
        public Boolean poseAutre {get; set;}
        public Boolean poseExistant {get; set;}
        public Boolean poseSemi {get; set;}
        public Boolean poseTotal {get; set;}
        public Boolean motorisation {get; set;}
        public Boolean ouvertureExt {get; set;}
        public Boolean ouvertureInt {get; set;}
        public Boolean ouvertureCoul {get; set;}
        public Boolean refoulementLat {get; set;}
        public Boolean refoulementPlaf {get; set;}
        public Boolean enroulement {get; set;}
        public Boolean sectionnelle {get; set;}
        public Boolean ecoSubvention {get; set;}
        public Decimal ecoSubventionMontant {get; set;}
        public String otherOptions {get; set;}
        public Option__c optVersion {get; private set;}
        public Map<String, coeffTh__c> coeffThermiqueProduitMap {get; private set;}

        // Constructeurs
        public ProductItem(Map<String, coeffTh__c> coeffProduitMap) {
            isPortail = false;
            oscilloBattant = false;
            poseExistant = false;
            poseSemi = false;
            poseTotal = false;
            motorisation = false;
            ouvertureExt = false;
            ouvertureInt = false;
            ouvertureCoul = false;
            refoulementLat = false;
            refoulementPlaf = false;
            enroulement = false;
            sectionnelle = false;
            ecoSubvention = false;
            poseAutre = false;
            ecoSubventionMontant = 0;
            installationAutre = '';
            otherOptions = '';
            optList = new List<OptionItem>();
            coeffThermiqueProduitMap = coeffProduitMap;
        }

        // Ajout d'une option pour le produit de la ligne de devis
        public void addOption(Option__c opt){
            Boolean optVers = false;
            if(opt.Option_de_Version__c){
                optVersion = opt;
                optVers = true;
            }
            optList.add(new OptionItem(opt, optVers));
        }

        // Récupération de la quantité
        public Integer getQuantity(){
            if(qli.quantity == null)
                return 0;
            return Integer.valueOf(qli.quantity);
        }

        // Récupération coefficient thermique de la ligne de devis
        public String getCoefThermique() {
            String coefficienThermiqueString = null;
            coeffTh__c coefficienThermiqueObject = new coeffTh__c();

            // Si des coefficient existe, récupération de la liste
            if(coeffThermiqueProduitMap != null) {
                coefficienThermiqueObject = coeffThermiqueProduitMap.get(qli.Id);
                if(coefficienThermiqueObject != null) {
                    coefficienThermiqueString = '';
                    // Construction du texte - Coefficient 1
                    if(coefficienThermiqueObject.coef1__c != '' && coefficienThermiqueObject.coef1__c != null && coefficienThermiqueObject.valeurCoef1__c != null) {
                        coefficienThermiqueString += coefficienThermiqueObject.coef1__c + ' = ' + String.valueOf(coefficienThermiqueObject.valeurCoef1__c).replace('.', ',');
                        if(coefficienThermiqueObject.unite1__c != '' && coefficienThermiqueObject.unite1__c != null)
                            coefficienThermiqueString += ' ' + coefficienThermiqueObject.unite1__c;
                        coefficienThermiqueString +=  ', ';
                    }
                    // Coefficient 2
                    if(coefficienThermiqueObject.coef2__c != '' && coefficienThermiqueObject.coef2__c != null && coefficienThermiqueObject.valeurCoef2__c != null) {
                        coefficienThermiqueString += coefficienThermiqueObject.coef2__c + ' = ' + String.valueOf(coefficienThermiqueObject.valeurCoef2__c).replace('.', ',');
                        if(coefficienThermiqueObject.unite2__c != '' && coefficienThermiqueObject.unite2__c != null)
                            coefficienThermiqueString += ' ' + coefficienThermiqueObject.unite2__c;
                        coefficienThermiqueString +=  ', ';
                    }

                    coefficienThermiqueString = coefficienThermiqueString.trim();
                    coefficienThermiqueString = coefficienThermiqueString.substring(0, (coefficienThermiqueString.length()-1));
                    coefficienThermiqueString = coefficienThermiqueString.trim();
                }
            }

            return coefficienThermiqueString;
        }

        // Retourne si c'est une option de version
        public Boolean getIsOptVers(){
            return (optVersion != null);
        }
    }

    public class OptionItem{
        public Option__c opt {get; private set;}
        public String description {get; private set;}
        public Boolean optionVersion {get; private set;}

        // Constructeur
        public OptionItem(Option__c option, boolean optVers) {
            opt = option;
            description = opt.LibelleOption__c;
            optionVersion = optVers;
        }
    }
}