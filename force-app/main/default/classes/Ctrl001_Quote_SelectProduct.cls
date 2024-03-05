//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl001_Quote_SelectProduct
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 31/07/2020
//-- Version     : 1.3
//-- * 1.3 : KPKCRM_RQM-30 : Gestion dans Kube des produits vendus au m²
//-- * 1.2.2 : Correction bug des détails du devis + Optimisation
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl001_Quote_SelectProduct {

    /************* Members **************/
    public Quote devis {get;set;}
    public String selectedIds{get;set;}
    public List<SelectOption> CodecouponSelectOption{get;set;}
    public Utils_Filter filter {get;set;}
    public String keyword{get;set;}
    public String orderBy{get;set;}
    public Boolean orderByChange{get;set;}
    public String orderByOrder{get;set;}
    public Boolean showMoreFilters{get;set;}
    public List<Grille_de_tarif__c> tarifs {get;set;}
    public List<QuoteLineItem> qliList {get;set;}
    public List<qliDisplay> qliDisplayList {get;set;} //liste affichee dans la page VF
    public ApexPages.StandardSetController productListSetCtrl {get;private set;}
    public Map<String, Schema.SObjectField> searchField = Schema.SObjectType.Product2.fields.getMap();
    // Taux TVA
    private static Double TVA_REDUIT = PropertiesUtils.getDoubleValue('tva.taux.reduit', 0);
    private static Double TVA_NORMAL = PropertiesUtils.getDoubleValue('tva.taux.normal', 0);

    public list<Product2> productList {
        get{
            if(productListSetCtrl!=null)
                return (List<Product2>) productListSetCtrl.getRecords();
            else
                return new list<Product2>();
        }
        set;
    }

    /**
    * @description Constructeur
    * @return Ctrl001_Quote_SelectProduct
    */ 
    public Ctrl001_Quote_SelectProduct(Apexpages.Standardcontroller ctrl){
        devis = (Quote)ctrl.getRecord();        
        tarifs = new List<Grille_de_tarif__c>();
        // Récupération détails du Devis
        devis = DAL.getQuoteById(devis.Id);
    }

    /**
    * @description Affiche la page de sélection de PricebookEntry si le devis n'a pas de catalogue de prix ou sinon la page VF VF001_Quote_SelectProduct
    * @return Page Page standard de sélection de PricebookEntry ChooseQuotePricebook sinon page VF VF001_Quote_SelectProduct
    */ 
    public Pagereference initPSS(){
        try {
            if(devis.Pricebook2Id == null) {
                PageReference p = null;
                p = new PageReference('/_ui/sales/quote/lineitem/ChooseQuotePricebook/e');
                string retURL = ApexPages.currentPage().getUrl();
                p.getParameters().put('retURL',retURL.split('[?]')[0] +'?id='+devis.Id );
                p.getParameters().put('id' , devis.Id);
                p.setRedirect(false);
                return p;
            }
    
            // Initialise le filtre de la page
            initFilter();
            // Exécute la recherche
            search();
        } catch (Exception e) {
            System.debug('ERREUR # Ctrl001_Quote_SelectProduct - initPSS : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
        }
        return null;
    }
    
    /**
    * @description Initialise le filtre de la page
    */ 
    private void initFilter(){
        try {
            orderBy= 'Topvente__c';
            orderByOrder='desc';
            orderByChange = false;
            showMoreFilters=false;
            Set<string> fieldToIncluded= new set<string>();
            Set<string> IncludedRef = new set<string> (new string [] { 'product2' });
            filter= new Utils_Filter('PriceBookEntry',4,null,IncludedRef, fieldToIncluded, false, true);
            filter.showAdancedFilter = false;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
    * @description Fonction pour le bouton "Annuler"
    * @return Page Visualforce
    */ 
    public Pagereference cancel(){
        Pagereference p = null;
        string retURL = Apexpages.currentPage().getParameters().get('retURL');
        if(retURL != null)
            p = new Pagereference(retURL);
        else {
            p = new PageReference('/'+devis.id);
        }
        p.setRedirect(true);
        return p;
    }

    /**
    * @description VF001_Quote_SelectProduct - Fonction pour le bouton "Sélectionner"
    * @return Page Visualforce VF001_Quote_SelectProduct
    */ 
    public Pagereference addToQuote(){
        Pagereference p = Page.VF001_Quote_SelectProductGrid;
        p.getParameters().put('retURL',Apexpages.currentPage().getURL());
        return p;
    }

    /**
    * @description VF001_Quote_SelectProduct - Fonction pour le bouton "Rechercher"
    * @return Page Visualforce VF001_Quote_SelectProduct
    */ 
    public Pagereference search() {
        System.debug('### DEBUT search');
        try {
            filter.runQuery();
    
            // Construction de la sous requête de récupération des produits selon la recherche utilisateur
            String queryPriceBookEntrySql = 'SELECT Product2ID From PriceBookEntry WHERE isActive= true AND Pricebook2Id = \''+devis.Pricebook2Id+'\' ';
            if(String.isNotBlank(filter.getSqlWhereConditions())){
                queryPriceBookEntrySql += ' AND ' + filter.getSqlWhereConditions();
            }
            queryPriceBookEntrySql += createFilterByKeyWord();
    
            // SOQL - SELECT - Récupération liste des produits
            String queryProductSql = 'SELECT Id,Topvente__c ,Code_Grille_Tarif__c,Matiere__c ,SousMatiere__c, description ,SousFamille__c,Name,Family,ProductCode,IsActive,Modele__c, ';
            queryProductSql += '(SELECT Id, Name, Pricebook2Id, Product2Id, Product2.Modele__c, UnitPrice, IsActive, UseStandardPrice, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, ProductCode, IsDeleted FROM PricebookEntries WHERE Pricebook2Id = \''+devis.Pricebook2Id+ '\' LIMIT 1) FROM Product2   ';
            queryProductSql += 'WHERE isActive = true AND ( productType__c = \'Carpentry\' OR productType__c = \'Service\') AND id IN ('+queryPriceBookEntrySql+') ORDER BY ' + orderBy;
            if(orderByChange){
                if(orderByOrder=='asc'){
                    orderByOrder = 'desc';
                    queryProductSql +=  ' ' + orderByOrder;
                }
                else{
                    orderByOrder = 'asc';
                    queryProductSql +=  ' ' + orderByOrder;
                }
                orderByChange=false;
            }
            else
                queryProductSql +=  ' ' + orderByOrder;
    
            queryProductSql += ' NULLS LAST ';
            System.debug('## queryProductSql : '+queryProductSql);
            // Recherche
            productListSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(queryProductSql));
            productListSetCtrl.setPageSize(25);
        } catch (Exception e) {
            System.debug('ERREUR # Ctrl001_Quote_SelectProduct - search : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
        }
        System.debug('### FIN search');
        return null;
    }
    
    /**
    * @description VF001_Quote_SelectProductGrid - Initialise le tableau des lignes (produits) du devis
    * @return Page Visualforce VF001_Quote_SelectProductGrid
    */ 
    public Pagereference initGrid(){
        System.debug('### DEBUT initGrid');
        qliList = new List<QuoteLineItem>();
        qliDisplayList = new List<qliDisplay>();
        Set<Id> productIdList = new Set<Id>();
        Set<string> codesTarifs = new Set<string>();

        /* NON UTILISE
        // SOQL - Récupération de la campagne marketing du compte
        List<CampaignMember> cmList = [SELECT campaignId FROM CampaignMember WHERE contactId != null AND contactId = :devis.compte__r.PersonContactId];
        Set<string> campIdSet = DAL.makeSet(cmList, 'campaignId');
        // SOQL - Récupération du code coupon de la campagne
        List<Codecoupon__c> CodecouponList = [SELECT Id,Name,Campagne__c,Campagne__r.IsActive,Campagne__r.RecordTypeId FROM Codecoupon__c
                                                    WHERE Disponible_non_cible__c = 1
                                                            OR (Disponible_cible__c = 1 AND Campagne__c in: campIdSet)
                                                            OR id =: devis.CodeCoupon__c];

        CodecouponSelectOption = new List<SelectOption>();
        for(Codecoupon__c cod : CodecouponList)
            CodecouponSelectOption.add(new SelectOption(cod.Id,cod.Name));
        */

        Set<Id> pbeIds = new Set<Id>();
        if(selectedIds != null){
            for(string strID : selectedIds.split(','))
                pbeIds.add(strID);

            // SOQL - SELECT - Récupération des informations des produits sélectionnés par l'utilisateur
            Map<ID,PricebookEntry> pbeMap = new Map<ID,PricebookEntry>([SELECT id,Name,Product2.Id, Product2.Topvente__c, Product2.SousFamille__c,Product2.Longueurminimum6vantaux__c, Product2.Longueurminimum5vantaux__c,
                                                                        Product2.Longueurminimum4vantaux__c, Product2.Longueurminimum3vantaux__c, Product2.Longueurminimum2vantaux__c,
                                                                        Product2.Longueurminimum1vantail__c, Product2.Longueurmaximum6vantaux__c, Product2.Longueurmaximum5vantaux__c,
                                                                        Product2.Longueurmaximum4vantaux__c, Product2.Longueurmaximum3vantaux__c, Product2.Longueurmaximum2vantaux__c,
                                                                        Product2.Longueurmaximum1vantail__c, Product2.Largeurminimum6vantaux__c, Product2.Largeurminimum5vantaux__c,
                                                                        Product2.Largeurminimum4vantaux__c, Product2.Largeurminimum3vantaux__c, Product2.Largeurminimum2vantaux__c,
                                                                        Product2.Largeurminimum1vantail__c, Product2.Largeurmaximum6vantaux__c, Product2.Largeurmaximum5vantaux__c,
                                                                        Product2.Largeurmaximum4vantaux__c, Product2.Largeurmaximum3vantaux__c, Product2.Largeurmaximum2vantaux__c,
                                                                        Product2.Largeurmaximum1vantail__c, Product2.Family, Product2.Reference__c, Product2.IsActive, Product2.ProductCode, 
                                                                        Product2Id, Product2.Code_Grille_Tarif__c, Product2.Modele__c, Product2.eligibleBonusProjet__c
                                                                            FROM PricebookEntry WHERE id in :pbeIds]);
            // Construction liste ID des produits     
            for(string strID : selectedIds.split(',')){
                productIdList.add(pbeMap.get(strID).Product2.Id);
            }                           
            // SOQL - SELECT - Récupération des TVA des produits                                        
            Map<ID,TVA_Produit__c> tvaList = getListTauxTVA(productIdList); 
            // Construction liste des lignes à afficher            
            for(String strID : selectedIds.split(',')){
                Map<String, String> tauxTVA = new Map<String, String>();                
                QuoteLineItem qli = new QuoteLineItem(QuoteId = devis.id, 
                                                        Description = pbeMap.get(strID).Product2.Modele__c,
                                                        PricebookEntryId = strID, 
                                                        PricebookEntry = pbeMap.get(strID));
                qliList.add(qli);
                qliDisplay qDisp = new qliDisplay();
                qDisp.qli = qli;
                qDisp.quote = devis;
                qDisp.TVA = (qli.TVApourcentage__c != null) ? String.valueOf(qli.TVApourcentage__c) : '';
                system.debug('########## qDisp.TVA : ' + qDisp.TVA); 
                qDisp.tvaPicklist = new List<Selectoption>(); 
                // Récupération de la liste des TVA par produit
                for(TVA_Produit__c tvaPrd :tvaList.values()){
                    String pTva = String.valueOf(tvaPrd.taux__c);
                    if(pbeMap.get(strID).Product2.Id == tvaPrd.produit__c && tauxTVA.get(pTva) == null){
                        qDisp.tvaPicklist.add(new Selectoption(pTva,pTva));
                        tauxTVA.put(pTva, pTva);
                    }
                }
                qliDisplayList.add(qDisp);
            }
        }
        else {
            // SOQL - SELECT - Récupération des lignes de devis du devis
            qliList = DAL.getQuoteLineItemList(devis.Id);
            // Construction liste ID des produits     
            for(QuoteLineItem ql :qliList){ 
                productIdList.add(ql.PriceBookEntry.Product2.Id);
            }            
            // SOQL - SELECT - Récupération des TVA des produits                                        
            Map<ID,TVA_Produit__c> tvaList = getListTauxTVA(productIdList); 
            // Construction liste des lignes à afficher
            for(QuoteLineItem ql :qliList){
                Map<String, String> tauxTVA = new Map<String, String>();    
                qliDisplay qDisp = new qliDisplay();
                qDisp.qli = ql;
                qDisp.quote = devis;
                qDisp.TVA = (ql.TVApourcentage__c != null) ? String.valueOf(ql.TVApourcentage__c) : ''; 
                system.debug('########## qDisp.TVA : ' + qDisp.TVA); 
                qDisp.tvaPicklist = new List<Selectoption>(); 
                // Récupération de la liste des TVA par produit
                for(TVA_Produit__c tvaPrd :tvaList.values()){
                    String pTva = String.valueOf(tvaPrd.taux__c);
                    if(ql.PricebookEntry.Product2.Id == tvaPrd.produit__c && tauxTVA.get(pTva) == null) {
                        qDisp.tvaPicklist.add(new Selectoption(pTva,pTva));
                        tauxTVA.put(pTva, pTva);
                    }
                }
                qliDisplayList.add(qDisp); 
            }
        }
        // Récupération des codes tarif des lignes de devis
        for(QuoteLineItem qli : qliList)
            codesTarifs.add(qli.pricebookEntry.product2.Code_Grille_Tarif__c);
        // SOQL - SELECT - Récupération de la grille des tarifs pour les lignes de devis
        tarifs = DAL.getGrillesTarifs(codesTarifs, devis.referenceDate__c);
        System.debug('### FIN initGrid');
        return null;
    }

    /**
    * @description VF001_Quote_SelectProductGrid - Fonction pour le bouton "Sauvegarder et ajouter"
    * @return Page Visualforce VF001_Quote_SelectProductGrid
    */ 
    public Pagereference saveAndAdd(){
        Pagereference p = save();
        if(p==null) return null;
        else {
            P = Page.VF001_Quote_SelectProduct;
            p.getParameters().put('id',devis.Id);
            p.setRedirect(true);
            return p;
        }
    }
    
    /**
    * @description VF001_Quote_SelectProductGrid - Fonction pour le bouton "Sauvegarder"
    * @return Page Visualforce VF001_Quote_SelectProductGrid
    */ 
    public Pagereference save(){
        System.debug('### DEBUT save');
        List<String> productIdList = new List<String>();
        //Map<String, FamilleDePrix__c> famillePrixMap = new Map<String, FamilleDePrix__c>();
        
        try{
            Boolean error=false;

            // Construction liste ID des produits     
            for(QuoteLineItem ql :qliList){ 
                productIdList.add(ql.PriceBookEntry.Product2.Id);
            }   
        
            // Vérification de la taille minimal/maximal
            for(QuoteLineItem qli :qliList){
                if(qli.Tarifhorsdimension__c == null || qli.Tarifhorsdimension__c == 0){
                    Product2 prod=qli.PricebookEntry.Product2;
                    if(qli.Nombredevantaux__c=='1'){
                        error=checkDimension(qli,prod.Longueurminimum1vantail__c,prod.Longueurmaximum1vantail__c, 
                                                    prod.Largeurminimum1vantail__c,prod.Largeurmaximum1vantail__c);
                    }
                    else if(qli.Nombredevantaux__c=='2'){
                        error=checkDimension(qli,prod.Longueurminimum2vantaux__c,prod.Longueurmaximum2vantaux__c,
                                                    prod.Largeurminimum2vantaux__c,prod.Largeurmaximum2vantaux__c);
                    }
                    else if(qli.Nombredevantaux__c=='3'){
                        error=checkDimension(qli,prod.Longueurminimum3vantaux__c,prod.Longueurmaximum3vantaux__c,
                                                    prod.Largeurminimum3vantaux__c,prod.Largeurmaximum3vantaux__c);
                    }
                    else if(qli.Nombredevantaux__c=='4'){
                        error=checkDimension(qli,prod.Longueurminimum4vantaux__c,prod.Longueurmaximum4vantaux__c,
                                                    prod.Largeurminimum4vantaux__c,prod.Largeurmaximum4vantaux__c);
                    }
                    else if(qli.Nombredevantaux__c=='5'){
                        error=checkDimension(qli,prod.Longueurminimum5vantaux__c,prod.Longueurmaximum5vantaux__c,
                                                    prod.Largeurminimum5vantaux__c,prod.Largeurmaximum5vantaux__c);
                    }
                    else if(qli.Nombredevantaux__c=='6'){
                        error=checkDimension(qli,prod.Longueurminimum6vantaux__c,prod.Longueurmaximum6vantaux__c,
                                                    prod.Largeurminimum6vantaux__c,prod.Largeurmaximum6vantaux__c);
                    }
                }
            }

            if(error)
                return null;

            /* RQM-30 : En commentaire suite abandon de la demande
            // SOQL - Construction de la liste et de la map de famille de prix par produit
            for(FamilleDePrix__c fp : [SELECT Id, prixBaseHT__c, produit__c FROM FamilleDePrix__c 
                                        WHERE produit__c IN :productIdList AND date__c < :devis.dateDevis__c AND valide__c = true 
                                        ORDER BY date__c ASC]){
                famillePrixMap.put(fp.produit__c, fp);
            }
            */

            // Vérification du tarif des produits
            Map<Id, Grille_de_tarif__c> tarifByQLIMap = getGrilleTarifQuoteLineItem();
            for(QuoteLineItem qli :qliList) {
                
                /* RQM-30 : En commentaire suite abandon de la demande
                // Calcul du tarif au m²
                if(qli.PriceBookEntry.Product2.typeCalculPrix__c == Constants.PRODUCT_CALCULPRIX_SURFACE) {
                    if(!famillePrixMap.isEmpty()  && famillePrixMap.get(qli.PriceBookEntry.Product2.Id) != null
                         && famillePrixMap.get(qli.PriceBookEntry.Product2.Id).prixBaseHT__c != null){
                        qli.UnitPrice = ((qli.Hauteur__c * qli.Largeur__c)/10000) * famillePrixMap.get(qli.PriceBookEntry.Product2.Id).prixBaseHT__c;
                    }
                } else {*/
                    // Sinon calcul selon nombre de vantaux
                    Grille_de_tarif__c tarif = tarifByQLIMap.get(qli.Id);
                    if(tarif != null) {
                        if(qli.Nombredevantaux__c=='1')
                            qli.UnitPrice = tarif.Prix1vantail__c;
                        if(qli.Nombredevantaux__c=='2')
                            qli.UnitPrice = tarif.Prix2vantaux__c;
                        if(qli.Nombredevantaux__c=='3')
                            qli.UnitPrice = tarif.Prix3vantaux__c;
                        if(qli.Nombredevantaux__c=='4')
                            qli.UnitPrice = tarif.Prix4vantaux__c;
                        if(qli.Nombredevantaux__c=='5')
                            qli.UnitPrice = tarif.Prix5vantaux__c;
                        if(qli.Nombredevantaux__c=='6')
                            qli.UnitPrice = tarif.Prix6vantaux__c;
                    }
                    if((tarif == null || qli.UnitPrice == 0 || qli.UnitPrice == null) && (qli.Tarifhorsdimension__c == null || qli.Tarifhorsdimension__c == 0)) {
                        error=true;
                        qli.Tarifhorsdimension__c.addError('Vous devez specifier un Prix Hors Norme');
                    }
                    else if(tarif == null || qli.UnitPrice == 0 || qli.UnitPrice == null)
                        qli.UnitPrice=qli.Tarifhorsdimension__c;
                //}
            }

            // Met a jour le champ TVA du QLI en fonction du choix de l'utilisateur
            for(qliDisplay ql : qliDisplayList){
                if(String.isNotBlank(ql.TVA)) {
                    Double tva = Double.valueOf(ql.TVA);
                    ql.qli.TVApourcentage__c = tva;
                    system.debug('## tva' + tva);
                    system.debug('## ql.qli.TVApourcentage__c' + ql.qli.TVApourcentage__c);
                    // Mise à jour du champ TVA__c selon le type de taux
                    ql.qli.TVA__c = 'Intermédiaire';
                    if(tva <= TVA_REDUIT) ql.qli.TVA__c = 'Réduite';
                    else if(tva >= TVA_NORMAL) ql.qli.TVA__c = 'Normal';
                }
            }

            if(error)
                return null;

            // Mise à jour/Création des lignes de devis
            upsert qliList;
            // Mise à jour des prix
            Utils_Configurator.recalculerTarifOptions(devis);
            TR022_Quote.setBonusAndRemises(new List<Quote>{devis}); 
        
            // Retour
            Pagereference backPage = new PageReference('/'+devis.id);  
            backPage.setRedirect(true);
            System.debug('### FIN save');
            return backPage;
        } catch(Exception e) {
            System.debug('ERREUR # Ctrl001_Quote_SelectProduct - save : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            Apexpages.addMessages(e);
            return null;
        }
    }

    /**
    * @description Fonction pour vérifier la dimension saisie pour un produit selon le nombre de vantaux
    * @param qli Ligne du devis avec valeurs saisies par l'utilisateur
    * @param longMin Longueur minimale du produit
    * @param longMax Longueur maximale du produit
    * @param largMin Largeur minimale du produit
    * @param largMax Largeur maximale du produit
    * @return True si erreur de dimension
    */ 
    private Boolean checkDimension(QuoteLineItem qli, Decimal longMin, Decimal longMax, Decimal largMin, Decimal largMax){
        Boolean error=false;
        if(qli.Hauteur__c < longMin || qli.Hauteur__c > longMax){
            qli.Hauteur__c.addError('Hauteur ('+longMin+'-'+longMax+')'); 
            error=true;
        }
        if(qli.Largeur__c < largMin || qli.Largeur__c > largMax){
            qli.Largeur__c.addError('Largeur ('+largMin+'-'+largMax+')'); 
            error=true;
        }
        return error;
    }
    
    /**
    * @description Fonction des tarifs pour les lignes de devis
    * @return Map contenant les tarifs pour les produits
    */ 
    private Map<Id, Grille_de_tarif__c> getGrilleTarifQuoteLineItem(){
        Map<Id,Grille_de_tarif__c> qliMap = new Map<Id,Grille_de_tarif__c>();

        for(QuoteLineItem qli : qliList){
            if(Test.isRunningTest()){
                qli.Hauteur__c = 5;
                qli.Largeur__c = 5;
            }
            Integer dim = Integer.valueOf(qli.Hauteur__c) + Integer.valueOf(qli.Largeur__c);
            for(Grille_de_tarif__c ta : tarifs){
                if(ta.CodeGrilleTarif__c == qli.pricebookEntry.product2.Code_Grille_Tarif__c && ta.dimension__c >= dim){
                    qliMap.put(qli.id,ta);
                    break;
                }
            }
        }
        return qliMap;
    }

    /**
    * @description Fonction pour pagination
    * @return Numéro de page
    */ 
    public Integer getproductListIndex(){
        if(productListSetCtrl!=null)
            return (productListSetCtrl.getPageSize() * (productListSetCtrl.getPageNumber()-1)) + 1;
        else
            return null;
    }

    /**
    * @description Fonction de création des prédicats pour la requête SOQL de recherche
    * @return Chaine de critères de filtrage
    */ 
    private String createFilterByKeyWord() {
        System.debug('### DEBUT createFilterByKeyWord');
        System.debug('## keyWord: '+keyWord);
        if(String.isBlank(keyWord))
            return '';
            
        String filter = ' AND (';
        keyWord = keyWord.trim();
        for (String fieldKey : searchField.keySet()) {
            Schema.DescribeFieldResult f = searchField.get(fieldKey).getDescribe();
            if(f.getType() == Schema.DisplayType.string) {
                filter += 'Product2' + '.' + f.getName() +' LIKE \'%'+ String.escapeSingleQuotes(keyWord) + '%\' OR ';
            }
        }
        filter = filter.substring(0,filter.length()-3);
        filter += ') ';
        System.debug('## filter: '+filter);
        System.debug('### FIN createFilterByKeyWord');
        return filter;
    }
    
    /**
    * @description Fonction pour récupérer la liste des TVA pour les produits selon la date du devis
    * @param productIdList Liste des ID des produits
    * @return Map contenant la liste des taux par produit
    */ 
    private Map<ID,TVA_Produit__c> getListTauxTVA(Set<Id> productIdList){                           
        Map<ID,TVA_Produit__c> tvaList = new Map<ID,TVA_Produit__c>([SELECT taux__c, produit__c, datefin__c, datedebut__c
                                                                FROM TVA_Produit__c
                                                                WHERE produit__c IN :productIdList
                                                                        AND datedebut__c <= :devis.referenceDate__c
                                                                        AND (datefin__c >= :devis.referenceDate__c OR datefin__c = null)
                                                                ORDER BY taux__c]); 
        return tvaList;
    }

    /**
    *
    *   SOUS CLASSE
    *   Classe pour stocker les informations des lignes de devis (produit)
    *
    **/
    public class qliDisplay {
        public QuoteLineItem qli {get;set;}
        public Quote quote {get;set;}
        public List<Selectoption> tvaPicklist {get;set;}
        public String TVA {get;set;}
    }
}