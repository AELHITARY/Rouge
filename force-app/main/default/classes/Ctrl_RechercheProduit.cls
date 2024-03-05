//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_RechercheProduit
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/11/2020
//-- Version     : 1.3
//-- * 1.3 : RQM-70 : Evolution pour utilisation de leaflet
//-- * 1.2 : Modification champs produit/option
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_RechercheProduit {
    private static final Integer MAX_RESULTS  = PropertiesUtils.getIntegerValue('tabview.view.maxcount', 10);
    private static final integer mapDotLimits = Constants.MAP_DOT_LIMITS;

    public String cp{get; set;}
    public String ville{get; set;}
    public String rue{get; set;}
    public String pays{get; set;}
    public String departement{get; set;}
    public Decimal perimetre{get; set;}

    public Chantier__c unChantier {get { return unChantier;}set;}{unChantier = new Chantier__c(OwnerId=Userinfo.getUserId());}

    public String opt11 {get;set;}
    public String opt12 {get;set;}
    public String opt13 {get;set;} 
    public String opt21 {get;set;}
    public String opt22 {get;set;}
    public String opt23 {get;set;}
    public String opt31 {get;set;}
    public String opt32 {get;set;}
    public String opt33 {get;set;}
    public String prd1 {get;set;}
    public String prd2 {get;set;}
    public String prd3 {get;set;}

    public Double adresse_latitude {get; set;}
    public Double adresse_longitude {get; set;}
    public String licenceDQE {get; set;}
    public String autocompletionType {get; set;}
    public String country {get; set;}   
    public List<SelectOption> getpaysList() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(' ',' '));
        for(String code : GeoUtils.PAYS_CODE_MAP.keySet()) {
            options.add(new SelectOption(code,GeoUtils.PAYS_CODE_MAP.get(code)));
        }
        return options;
    }
    // Google
    public String googleKeyAPI {get; set;}
    transient public GoogleMapsSettings__c googleMapsSettings { get; private set; }
    public String walkMeURL { get; set; }

    // ERRORS
    public Utils_logger log {get; set;}

    // CODE PRODUIT
    public List<Product2> product {get; set;}
    public List<Product2> baseProducts {get; set;} {
        baseProducts = [SELECT Id, Name FROM Product2 LIMIT 10];
    }

    public String productCode1 {get;set;}
    public String productCode2 {get;set;}
    public String productCode3 {get;set;}
    public String displayProductId1 {get; set;}
    public String displayProductId2 {get; set;}
    public String displayProductId3 {get; set;}
    public String displayProductName1 {get; set;}
    public String displayProductName2 {get; set;}
    public String displayProductName3 {get; set;}

    public Product2 productSample {get{
        if(displayProductId1 != null){
            List<Product2> productList = new List<Product2>();
            productList = [SELECT Id, Name FROM Product2 WHERE Id = :displayProductId1 LIMIT 10];
            if(!productList.isEmpty()) productSample = productList[0];
        }
        return productSample;
    } set;} {
        /*productSample = new Product2();
        product = baseProducts;
        if(productSample == null && !product.isEmpty() && displayProductId1 == null) productSample = product[0];
        else {
            product = [SELECT Id, Name FROM Product2 WHERE Id = :displayProductId1 LIMIT 10];
            if(!product.isEmpty()) productSample = product[0];
        }*/
    }
    public Product2 productSample2 {get{
        if(displayProductId2 != null){
            List<Product2> productList = new List<Product2>();
            productList = [SELECT Id, Name FROM Product2 WHERE Id = :displayProductId2 LIMIT 10];
            if(!productList.isEmpty()) productSample2 = productList[0];
        }
        return productSample2;
    } set;}
    public Product2 productSample3 {get{
        if(displayProductId3 != null){
            List<Product2> productList = new List<Product2>();
            productList = [SELECT Id, Name FROM Product2 WHERE Id = :displayProductId3 LIMIT 10];
            if(!productList.isEmpty()) productSample3 = productList[0];
        }
        return productSample3;
    } set;}

    // CODE OPTION
    public List<ReferentielOptions__c> option {get; set;}
    public List<ReferentielOptions__c> baseOptions {get; set;} {
        baseOptions = [SELECT Id, Name FROM ReferentielOptions__c LIMIT 10];
    }
    public String optionCode11 {get;set;}
    public String optionCode12 {get;set;}
    public String optionCode13 {get;set;}
    public String optionCode21 {get;set;}
    public String optionCode22 {get;set;}
    public String optionCode23 {get;set;}
    public String optionCode31 {get;set;}
    public String optionCode32 {get;set;}
    public String optionCode33 {get;set;}
    public String displayOptionId11 {get; set;}
    public String displayOptionId12 {get; set;}
    public String displayOptionId13 {get; set;}
    public String displayOptionId21 {get; set;}
    public String displayOptionId22 {get; set;}
    public String displayOptionId23 {get; set;}
    public String displayOptionId31 {get; set;}
    public String displayOptionId32 {get; set;}
    public String displayOptionId33 {get; set;}
    public ReferentielOptions__c optionSample11 {get{
        if(displayOptionId11 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId11 LIMIT 10];
            if(!optionList.isEmpty()) optionSample11 = optionList[0];
        }
        return optionSample11;
    } set;}
    public ReferentielOptions__c optionSample12 {get{
        if(displayOptionId12 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId12 LIMIT 10];
            if(!optionList.isEmpty()) optionSample12 = optionList[0];
        }
        return optionSample12;
    } set;}
    public ReferentielOptions__c optionSample13 {get{
        if(displayOptionId13 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId13 LIMIT 10];
            if(!optionList.isEmpty()) optionSample13 = optionList[0];
        }
        return optionSample13;
    } set;}
    public ReferentielOptions__c optionSample21 {get{
        if(displayOptionId21 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId21 LIMIT 10];
            if(!optionList.isEmpty()) optionSample21 = optionList[0];
        }
        return optionSample21;
    } set;}
    public ReferentielOptions__c optionSample22 {get{
        if(displayOptionId22 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId22 LIMIT 10];
            if(!optionList.isEmpty()) optionSample22 = optionList[0];
        }
        return optionSample22;
    } set;}
    public ReferentielOptions__c optionSample23 {get{
        if(displayOptionId23 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId23 LIMIT 10];
            if(!optionList.isEmpty()) optionSample23 = optionList[0];
        }
        return optionSample23;
    } set;}
    public ReferentielOptions__c optionSample31 {get{
        if(displayOptionId31 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId31 LIMIT 10];
            if(!optionList.isEmpty()) optionSample31 = optionList[0];
        }
        return optionSample31;
    } set;}
    public ReferentielOptions__c optionSample32 {get{
        if(displayOptionId32 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId32 LIMIT 10];
            if(!optionList.isEmpty()) optionSample32 = optionList[0];
        }
        return optionSample32;
    } set;}
    public ReferentielOptions__c optionSample33 {get{
        if(displayOptionId33 != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId33 LIMIT 10];
            if(!optionList.isEmpty()) optionSample33 = optionList[0];
        }
        return optionSample33;
    } set;}

    /**
    * @description Constructeur
    */
    public Ctrl_RechercheProduit(){
        walkMeURL = PropertiesUtils.getStringValue('walkme.snippet.url', '');
        googleKeyAPI = PropertiesUtils.getStringValue('google.api.key', '');
        perimetre = PropertiesUtils.getIntegerValue('search.products.perimeter', 500);

        log = new Utils_logger();

        // Récupération des paramètres
        googleMapsSettings = GoogleMapsSettings__c.getValues('cartographie');
        // Récupération paramètre global DQE
        licenceDQE = PropertiesUtils.getStringValue('dqe.adresse.licence', '');
        autocompletionType = PropertiesUtils.getStringValue('function.provider.AddressAutocomplete', 'dqe');
        if(String.isBlank(country)) 
            country='FRA';
    }

    /**
    * @description Affichage page de résultat
    */
    public PageReference resultatProduit(){
        if(validationDesChamps()) {
            Pagereference VF_resultat = Page.VF_ResultatProduit;
            return VF_resultat;
        } else {
            return null;
        }
    }

    /**
    * @description Nouvelle recherche
    */
    public PageReference newSearch(){
        Pagereference VF_recherche = Page.VF_RechercheProduit;
        log.clear();
        return VF_recherche;
    }

    /**
    * @description Nouvelle recherche avec erreur sans produits
    */
    public PageReference newSearchWithError(){
        Pagereference VF_recherche = Page.VF_RechercheProduit;
        log.addErrorMessage(System.label.search_products_pas_resultats);
        return VF_recherche;
    }

    /**
    * @description Fonction appelé lors l'ouverture de la page
    */
    public void insertUserStats() {
        Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurRechercheParProduits__c');
    }

    /**
    * @description REMOTEACTION - Récupération des informations du compte saisie dans le champ prospect/client
    * @param IdCompte Id du compte
    * @return Liste contenant les informations du compte
    */
    @RemoteAction
    public static List<Account> recupereCompte(String IdCompte) {
        try{
            return [SELECT Name, rue__c, ville__c, codePostal__c, pays__c,
                        Localisation__Latitude__s, Localisation__Longitude__s FROM Account WHERE Id = :IdCompte];
        } catch(exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Recherche des chantiers selon les critères re recherche
    * @param IdCompte Id du compte
    * @return Liste contenant les informations du compte
    */
    @RemoteAction
    public static Set<Resultat> searchChantiersProducts(Map<String, List<String>> produitWithOptionsIds, Double adresse_latitude, Double adresse_longitude, Integer perimetre){
        System.debug('### DEBUT searchChantiersProducts');

        try{
            List<Chantier__c> listChantiers = new List<Chantier__c>();
            Map<ID,Chantier__c> mapChantiers = new Map<ID,Chantier__c>();
            Set<Resultat> ListResultats = new Set<Resultat>();
            Set<ID> accountIds = new Set<ID>();
            Set<ID> chantierIds = new Set<ID>();
            Set<ID> chantierForKcontratIds = new Set<ID>();
            Set<ID> opportunityIds = new Set<ID>();
            Set<ID> quoteIds = new Set<ID>();
            Set<ID> quoteLineItemIds = new Set<ID>();
            Integer nbRecords = 0;

            Map<Id,set<string>> MapQuoteCorres = new Map<Id,set<string>>();
            Map<ID,string> MapOppCorres = new Map<ID,string>();
            Map<Id, Set<String>> MapContratCorres = new Map<Id, Set<String>>();
            Map<Id, String> mapContratCorrespondance = new Map<Id, String>();
            Map<String, List<String>> produitWithOptions = new Map<String, List<String>>();

            Decimal perimetreTemp = (Decimal.valueof(perimetre)/1000);
            System.debug('## adresse_latitude: ' + adresse_latitude);
            System.debug('## adresse_longitude: ' + adresse_longitude);
            System.debug('## perimetre: ' + perimetre);
            System.debug('## perimetreTemp: ' + perimetreTemp);

            // Récupération des chantiers dans le secteur
            String soqlQueryCha ='SELECT Id ';
                    soqlQueryCha+=' FROM Chantier__c';
                    soqlQueryCha+=' WHERE DISTANCE(Localisation__c, GEOLOCATION ('+adresse_latitude+','+adresse_longitude+'), \'km\') < '+ perimetreTemp + ' LIMIT ' + mapDotLimits;
            // Exécution de la requête
            System.debug('## Select Chantier: ' + soqlQueryCha);
            List<Chantier__c> listChantier = Database.query(soqlQueryCha);
            System.debug('## listChantier: ' + listChantier);

            // Récupération des projet
            List<Opportunity> listOpp = [SELECT Id FROM Opportunity WHERE chantier__c IN :listChantier];
            System.debug('## listOpp: ' + listOpp);

            // Récupération des produits présent dans les devis (vérification des devis)
            Map<Id, QuoteLineItem> mapQuoteLineItems = new Map<Id ,QuoteLineItem>([SELECT Id, quoteId, Quote.Status, Quote.OpportunityId, PricebookEntry.Product2.Reference__c, Product2Id
                                                                                    FROM QuoteLineItem WHERE Product2Id IN :produitWithOptionsIds.keySet() 
                                                                                    AND Quote.OpportunityId IN :listOpp]);
            System.debug('## mapQuoteLineItems '+ mapQuoteLineItems);
            for(String idProduit : mapQuoteLineItems.keySet()){
                produitWithOptions.put(mapQuoteLineItems.get(idProduit).PricebookEntry.Product2.Reference__c, produitWithOptionsIds.get(mapQuoteLineItems.get(idProduit).Product2Id));
            }
            if(!mapQuoteLineItems.isEmpty()){
                quoteIds.clear();
                for (QuoteLineItem qli :mapQuoteLineItems.values()){
                    Set<string> prodset= new Set<string>();
                    Integer i = 0;
                    List<String> prod = new List<String>(produitWithOptions.keySet());
                    for(String nomProduit : produitWithOptions.keySet()){
                        if(qli.PricebookEntry.Product2.Reference__c== nomProduit){
                            quoteIds.add(qli.quoteId);
                            if(prod[i] == nomProduit && nomProduit != ''){
                                String produitCorrespondString = 'Produit'+produitWithOptions.get(nomProduit)[3];
                                prodset.add(produitCorrespondString);
                                MapQuoteCorres.put(qli.quoteId, prodset);

                                opportunityIds.add(qli.quote.OpportunityId);
                                String QuoteCorres = '';
                                for(string str : MapQuoteCorres.get(qli.quoteId)) {
                                    QuoteCorres += str;
                                }
                                MapOppCorres.put(qli.quote.OpportunityId, QuoteCorres);
                            }
                        }
                        i++;
                    }
                }
                System.debug('*** MapOppCorres '+MapOppCorres);

                Map<ID, Opportunity> mapOpportunities = new Map<ID, Opportunity>([SELECT Id, numeroProjet__c, accountid, autreCompte__c, chantier__c 
                                                                                    FROM Opportunity where Id IN :opportunityIds LIMIT :mapDotLimits]);
                for(Opportunity opp : mapOpportunities.values()){
                    accountIds.add(opp.accountid);
                    chantierIds.add(opp.chantier__c);
                }

                /*** traitement des chantiers ***********************************************************/
                // Récupération des chantiers
                String chantierId = '';
                if(!chantierIds.isEmpty()) {
                    for(Id chan : chantierIds) {
                        if(chan != null)
                            chantierId += '\'' + chan + '\',';
                    }
                    System.debug('chantierId : ' + chantierId);
                    chantierId = chantierId.substring(0, (chantierId.length()-1));
                    
                    String soqlQuery ='SELECT Id, Name, autreLocataire__c, locataire__c, autreOccupant__c, autreProprietaire__c,';
                        soqlQuery+=' adresseGeolocalisation__c,';
                        soqlQuery+=' civiliteProprietaires__c, prenomProprietaires__c, nomProprietaires__c,';
                        soqlQuery+=' civiliteLocataires__c, prenomLocataires__c, nomLocataires__c,';
                        soqlQuery+=' civiliteOccupants__c, prenomOccupants__c, nomOccupants__c,';
                        soqlQuery+=' locatairePrecedent__c, occupant__c, occupantPrecedent__c,';
                        soqlQuery+=' proprietaire__c, proprietairePrecedent__c, Localisation__Latitude__s, Localisation__Longitude__s,';
                        soqlQuery+=' rue__c, codePostal__c, ville__c';
                        soqlQuery+=' FROM Chantier__c';
                        soqlQuery+=' WHERE ID IN (' + chantierId + ') AND DISTANCE (Localisation__c, GEOLOCATION ('+adresse_latitude+','+adresse_longitude+'),\'km\') < '+ perimetreTemp + ' LIMIT ' + mapDotLimits;

                    // Exécution de la requête
                    listChantiers = database.query(soqlQuery);
                    System.debug('listchantier size:'+listChantiers.size());

                    // Reconstruction des comptes
                    Map<ID, Account> mapComptes = new Map<ID, Account>([SELECT Id, AccountNumber from Account where Id IN :accountIds]);
                    System.debug('*** mapComptes '+mapComptes);
                    if(!mapOpportunities.isEmpty()){
                        //construction du résultat/////////////////////////////////////////////////////
                        for (Chantier__c cht : listChantiers){
                            for (Opportunity oppt : mapOpportunities.values()){
                                if (cht.id == oppt.Chantier__c){
                                    for(Account acc : mapComptes.values()){
                                        if(acc.id == oppt.accountid && nbRecords < MAX_RESULTS){
                                            Resultat res = new Resultat(cht,oppt,acc);
                                            res.Correspondance=MapOppCorres.get(oppt.Id);
                                            ListResultats.add(res);
                                            nbRecords++;
                                        }
                                    }
                                }
                            }
                            System.debug('ListResultats:'+ListResultats);        
                            // voir s'il ne faut pas prioriser Les Devis et si pas de réponse pour un chantier chercher dans les Kcontrats
                            // Construction de la liste des chantiers qui n'ont pas eu de résultat sur les produits
                            for(Resultat res : ListResultats){
                                if (res.idChantier!= cht.id)
                                    chantierForKcontratIds.add(cht.id);
                            }
                        }
                        System.debug('chantierForKcontratIds:'+chantierForKcontratIds);
                    }

                    /*** traitement des contrats ***********************************************************/
                    // Récupération des contrats avec les produits sélectionnés
                    Map<ID, KContrat__c> mapKContrat = new Map<ID, KContrat__c>([SELECT Id, produits__c, compte__c, autreCompte__c 
                                                                                    FROM KContrat__c WHERE chantier__c IN :chantierForKcontratIds]);
                    System.debug('mapKContrat : '+mapKContrat);
                    if(!mapKContrat.isEmpty()){
                        // Vérification de la présence des produits
                        for(KContrat__c contrat : mapKContrat.values()) {
                            Set<String> prodset2 = new Set<String>();
                            Integer i = 0;
                            if (!StringUtils.isEmpty(contrat.produits__c)) {
                                List<String> contratProduits = contrat.produits__c.split(',');
                                for(String nomProduit : produitWithOptions.keySet()){
                                    System.debug('###### contratProduits : '+contratProduits);
                                    for(String ligneProduit : contratProduits) {
                                        System.debug('AVANT ligneProduit : '+ligneProduit);
                                        String produitContrat = ligneProduit.substring((ligneProduit.indexOf('(')+1), ligneProduit.indexOf(')'));
                                        System.debug('APRES ligneProduit : '+ligneProduit);
                                        if(produitContrat.equalsignorecase(nomProduit)){
                                            String produitCorrespondString = 'Produit'+produitWithOptions.get(nomProduit)[3];
                                            prodset2.add(produitCorrespondString);
                                            MapContratCorres.put(contrat.Id, prodset2);

                                            accountIds.add(contrat.compte__c);
                                            accountIds.add(contrat.autreCompte__c);
                                            String contratCorres = '';
                                            for(string str : MapContratCorres.get(contrat.Id)) {
                                                contratCorres += str;
                                            }
                                            mapContratCorrespondance.put(contrat.Id, contratCorres);
                                        }
                                    }
                                    i++;
                                }
                            }
                        }

                        // Reconstruction des comptes
                        mapComptes.putAll([SELECT Id, AccountNumber FROM Account WHERE Id IN :accountIds]);

                        // Construction du résultat
                        for (Chantier__c cht : mapChantiers.values()){
                            for (KContrat__c contrat : mapKContrat.values()){
                                if (cht.id == contrat.chantier__c){
                                    for(Account acc : mapComptes.values()){
                                        if((acc.id == contrat.compte__c || acc.id == contrat.autreCompte__c)  && nbRecords < MAX_RESULTS){
                                            Resultat res = new Resultat(cht, null, acc, contrat);
                                            res.Correspondance=mapContratCorrespondance.get(contrat.Id);
                                            ListResultats.add(res);
                                            nbRecords++;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    /*** traitement des options ***********************************************************/
                    Set<String> allOptionsSet = new Set<String>();
                    for (String nomProduit : produitWithOptions.keySet()) {
                        allOptionsSet.addAll(produitWithOptions.get(nomProduit));
                    }
                    System.debug('Option Set ' + allOptionsSet);
                    allOptionsSet.remove(''); // Suppression du vide (un champ vide n'est pas null mais vide)
                    allOptionsSet.remove('1');
                    allOptionsSet.remove('2');
                    allOptionsSet.remove('3');
                    System.debug('Option Set ' + allOptionsSet);

                    if(!allOptionsSet.isEmpty()) {
                        // Récupération des lignes de devis pour chercher les options
                        for (QuoteLineItem qli : mapQuoteLineItems.values()){
                            quoteLineItemIds.add(qli.id);
                        }

                        Map<ID,Option__c> mapOptions = new Map<ID, Option__c>([SELECT Codeoption__c, ligneDevis__c, ligneDevis__r.PricebookEntry.Product2.Reference__c, Option__r.Id
                                                                                FROM Option__c WHERE ligneDevis__c IN :quoteLineItemIds AND Option__r.Id IN :allOptionsSet]);
                        Map<ID, Set<String>> mapQuoteLineItemsCorrespond = new Map<ID, Set<String>>();
                        System.debug('MAPOPTION ' + mapOptions);

                        if (!mapOptions.isEmpty()){
                            Integer j=0;
                            Set<string> optionset= new Set<string>();
                            String optionCorrespondString;
                            String quoteLineItemId;
                            for (String nomProduit : produitWithOptions.keySet()) {
                                Integer nbOptionExact = 0;
                                for (String idOption : produitWithOptions.get(nomProduit)) {
                                    for(Option__c opt : mapOptions.values()) {
                                        if(String.valueOf(opt.Option__r.Id) == idOption && opt.ligneDevis__r.PricebookEntry.Product2.Reference__c== nomProduit) {
                                            System.debug('nbOptionExact ' + nbOptionExact + ' '+opt.Codeoption__c);
                                            nbOptionExact++;
                                            optionCorrespondString = 'Option'+produitWithOptions.get(nomProduit)[3];
                                            optionset.add(optionCorrespondString);
                                            quoteLineItemId = opt.ligneDevis__c;
                                            mapQuoteLineItemsCorrespond.put(quoteLineItemId, optionset);
                                        }
                                    }
                                }
                                System.debug('nbOptionExact total ' + nbOptionExact);
                                if (nbOptionExact == 3) {
                                    optionset.clear();
                                    optionCorrespondString = 'Exacte'+produitWithOptions.get(nomProduit)[3];
                                    optionset.add(optionCorrespondString);
                                }
                                j++;
                            }
                            System.debug('*** MAPOPTION key ' + mapQuoteLineItemsCorrespond);

                            //récupération des lignes de devis ok
                            //Redescendre l'information sur la correspondance jusqu'a l'opportunité
                            mapQuoteLineItems.clear();
                            mapQuoteLineItems.putAll([SELECT Id, quoteId, Quote.Status, Quote.OpportunityId, PricebookEntry.Product2.Reference__c
                                                            FROM QuoteLineItem WHERE Id in :mapQuoteLineItemsCorrespond.keySet()]);

                            for (QuoteLineItem qli : mapQuoteLineItems.values()){
                                quoteIds.add(qli.quoteId);
                                for(string strQuote : MapQuoteCorres.get(qli.quoteId)) {
                                    for(string strCorrespondance : mapQuoteLineItemsCorrespond.get(qli.Id)) {
                                        System.debug('*** CORRES key ' + strCorrespondance.substring(strCorrespondance.length()-1)+'= '+strQuote.substring(strQuote.length()-1));
                                        if(strCorrespondance.substring(strCorrespondance.length()-1) == strQuote.substring(strQuote.length()-1)){
                                            MapQuoteCorres.put(qli.quoteId, mapQuoteLineItemsCorrespond.get(qli.Id));
                                        }
                                    }
                                }
                            }
                            System.debug('***QUOTE key ' + MapQuoteCorres);
                            //liste Devis Ok
                            Map<ID, Quote> mapQuotes = new Map<ID, Quote>([SELECT Id, opportunityId FROM Quote WHERE Id IN :quoteIds]);
                            for(Quote devis : mapQuotes.values()){
                                String QuoteCorres = '';
                                for(string str : MapQuoteCorres.get(devis.ID)) {
                                    QuoteCorres += str;
                                }
                                MapOppCorres.put(devis.opportunityId, QuoteCorres);
                            }
                            System.debug('OPPORTUNITE key ' + MapOppCorres);

                            //mise à jour du résultat
                            for (Resultat res : ListResultats){
                                if(res.projet!=null) {
                                    String newCorres = MapOppCorres.get(res.projet.id);
                                    String oldCorres = res.Correspondance;
                                    System.debug('CORRES ' + newCorres.substring(0,newCorres.length()-1)+' '+oldCorres.substring(0,oldCorres.length()-1));
                                    if(newCorres.substring(0,newCorres.length()-1) == 'Exacte' || (newCorres.substring(0,newCorres.length()-1) == 'Option' && oldCorres.substring(0,oldCorres.length()-1) != 'Exacte'))
                                    System.debug('UPDATE CORRES key ' + MapOppCorres.get(res.projet.id) + ' '+res.Correspondance);
                                    res.Correspondance = MapOppCorres.get(res.projet.id);
                                }
                            }
                        }
                    }
                }
            }
            System.debug('### FIN searchChantiersProducts');
            return ListResultats;
        } catch(exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Récupération des vendeurs selon le type d'utilisateur (Vendeur ou RV/RVJ)
    * @return Liste contenant les informations des vendeurs
    */
    @RemoteAction
    public static List<User> getVendeursList() {
        System.debug('### DEBUT getVendeursList');
        try {
            List<User> userToReturn = new List<User>();
            List<User> vendeursList = DAL_Cartographie.getVendeursList(null, userInfo.getUserId());
            for(User vendeur : vendeursList){
                if(vendeur.localisationLatitude__c != null)
                    userToReturn.add(vendeur);
            }
            System.debug('### FIN getVendeursList');
            return userToReturn;
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Validation des champs obligatoire
    */
    private Boolean validationDesChamps(){
        System.debug('### DEBUT validationDesChamps');
        try{
            System.debug('## rue: ' + rue);
            System.debug('## cp: ' + cp);
            System.debug('## ville: ' + ville);
            System.debug('## departement: ' + departement);
            System.debug('## pays: ' + pays);

            //vérification des champs obligatoires
            if (String.isNotBlank(rue)) rue = rue.trim();
            if (String.isNotBlank(cp)) cp = cp.trim();
            if (String.isNotBlank(ville)) ville = ville.trim();
            if (String.isNotBlank(departement)) departement = departement .trim();
            if (String.isNotBlank(pays)) pays = pays.trim();

            if (String.isBlank(rue)) {
                log.addErrorMessage(System.label.AdresseNonValideGeoloc);
                return false;
            }
            if(String.isBlank(prd1)) {
                if(String.isNotBlank(opt11) || String.isNotBlank(opt12) || String.isNotBlank(opt13)) {
                    log.addErrorMessage(System.label.search_products_option_sans_produit);
                    return false;
                }
            }
            if(String.isBlank(prd2)) {
                if(String.isNotBlank(opt21) || String.isNotBlank(opt22) || String.isNotBlank(opt23)) {
                    log.addErrorMessage(System.label.search_products_option_sans_produit);
                    return false;
                }
            }
            if(String.isBlank(prd3)) {
                if(String.isNotBlank(opt31) || String.isNotBlank(opt32) || String.isNotBlank(opt33)) {
                    log.addErrorMessage(System.label.search_products_option_sans_produit);
                    return false;
                }
            }
            // Pas deux fois le même produit
            if((String.isNotBlank(prd1) && String.isNotBlank(prd2) && prd1.equals(prd2)) 
                || (String.isNotBlank(prd1) && String.isNotBlank(prd3) && prd1.equals(prd3)) 
                || (String.isNotBlank(prd2) && String.isNotBlank(prd3) && prd2.equals(prd3))) {
                log.addErrorMessage(System.label.search_products_meme_produit);
                return false;
            }
            // Pas de produits
            if(String.isBlank(prd1) && String.isBlank(prd2) && String.isBlank(prd3)) {
                log.addErrorMessage(System.label.search_products_pas_de_produit);
                return false;
            }
            log.clear();
            System.debug('### FIN validationDesChamps');
            return true;
        } catch(Exception e) {
            log.addErrorMessage(e.getMessage());
            return false;
        }
    }

    /**
    *
    *   Stockage de résultat.
    *
    **/
    public class Resultat {
        public Id idChantier{get;set;}
        public Chantier__c chantier { get; set; }
        public Opportunity projet {get; set;}
        public Account compte {get; set;}
        public KContrat__c contrat {get; set;}
        public String Name { get; private set;}
        public String Correspondance{get; set;}

        public Resultat (Chantier__c cha,Account acc) {
            chantier = cha;
            idChantier= cha.Id;
            compte = acc;
            getNameChantier();
        }

        public Resultat (Chantier__c cha, Opportunity opp, Account acc){
            idChantier= cha.Id;
            chantier = cha;
            projet = opp;
            compte = acc;
            getNameChantier();
        }

        public Resultat (Chantier__c cha, Opportunity opp, Account acc, KContrat__c cont){
            idChantier= cha.Id;
            chantier = cha;
            projet = opp;
            compte = acc;
            contrat = cont;
            getNameChantier();
        }

        // Récupération du nom de l'interlocuteur du Chantier
        private void getNameChantier() {
            if(chantier.proprietaire__c != null || chantier.autreProprietaire__c != null) {
                Name = StringUtils.trimToEmpty(chantier.civiliteProprietaires__c) + ' ';
                Name += StringUtils.trimToEmpty(chantier.prenomProprietaires__c) + ' ' + StringUtils.trimToEmpty(chantier.nomProprietaires__c).toUpperCase();
            }
            else if (chantier.locataire__c != null || chantier.autreLocataire__c != null) {
                Name = StringUtils.trimToEmpty(chantier.civiliteLocataires__c) + ' ';
                Name += StringUtils.trimToEmpty(chantier.prenomLocataires__c) + ' ' + StringUtils.trimToEmpty(chantier.nomLocataires__c).toUpperCase();
            }
            else if (chantier.occupant__c != null || chantier.autreOccupant__c != null) {
                Name = StringUtils.trimToEmpty(chantier.civiliteOccupants__c) + ' ';
                Name += StringUtils.trimToEmpty(chantier.prenomOccupants__c) + ' ' + StringUtils.trimToEmpty(chantier.nomOccupants__c).toUpperCase();
            }
            else {
                Name = '';
            }
        }
    }
}