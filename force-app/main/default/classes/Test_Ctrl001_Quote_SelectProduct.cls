//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl001_Quote_SelectProduct
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 11/11/2016
//-- Version     : 1.2
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl001_Quote_SelectProduct {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Account UN', 'test', 'test@test.fr', rtB2C, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

        // Création famille et sous famille
        List<Familles__c> famList = new List<Familles__c>();
        Familles__c famille = new Familles__c(Name = 'Fenetre', libelle__c = 'Fenetre', code__c = 'FEN');
        famList.add(famille);
        Familles__c famille2 = new Familles__c(Name = 'Autre', libelle__c = 'Autre', code__c = 'AUT');
        famList.add(famille2);
        insert famList;
        SousFamilles__c ssfamille = new SousFamilles__c(Name = 'PVC', libelle__c = 'PVC', famille__c = 'FEN',code__c = 'PVC');
        insert ssfamille;

        // Creation produits
        Id pb = Test.getStandardPricebookId();
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2(Name = 'Produit Test', ProductCode = 'FFFETT', IsActive = true, Largeurminimum1vantail__c = 50,
                                        Longueurminimum1vantail__c = 50, Family = 'Fenetre', SousFamille__c = 'PVC');
        prodList.add(prod);
        //PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        //insert pbe;*/
        Product2 prod2 = new Product2(Name = 'Produit Test 2', ProductCode = 'FFFET2', IsActive = true, Largeurminimum1vantail__c = 50,
                                        Longueurminimum1vantail__c = 50, Family = 'Fenetre', SousFamille__c = 'PVC');
        prodList.add(prod2);
        insert prodList;
        //PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = pb, Product2Id = prod2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        //insert pbe2;*/
        //PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = pb, Product2Id = prod3.Id, UnitPrice = 50, IsActive = true, UseStandardPrice = false);
        //insert pbe3;*/

        // Options référence
        List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
        ReferentielOptions__c refOpt = new ReferentielOptions__c(Name='RefOption');
        refOptList.add(refOpt);
        ReferentielOptions__c refOpt2 = new ReferentielOptions__c(Name='RefOption2');
        refOptList.add(refOpt2);
        insert refOptList;

        // Coefficient thermique
        List<coeffTh__c> coeffThList = new List<coeffTh__c>();
        coeffTh__c coef1 = new coeffTh__c(dateDebut__c = Date.today().addDays(-1), famille__c = prod.Id, option1__c = refOpt.Id, option2__c = refOpt2.Id,
                                            coef1__c='Sw', valeurCoef1__c=1, unite1__c='T', coef2__c='Uv', valeurCoef2__c=2, unite2__c='A', idTiers__c='1');
        coeffThList.add(coef1);
        coeffTh__c coef2 = new coeffTh__c(dateDebut__c = Date.today().addDays(-1), famille__c = prod2.Id, option1__c = refOpt.Id,
                                            coef1__c='Sw', valeurCoef1__c=1, unite1__c='T', idTiers__c='2');
        coeffThList.add(coef2);
        insert coeffThList;

        // Creation devis
        Quote quote = new Quote(Status = Constants.StatutDevisAConfigurer,
                                Name = 'Devis 1',
                                datedevis__c = Date.today(),
                                OpportunityId = opp.Id,
                                modeFinancement__c = 'PAIEMENT COMPTANT',
                                mntAcompteAttendu__c = 100,
                                Total_TTC_devis__c = 1000,
                                Pricebook2Id = pb,
                                source__c = 'BAL VENDEUR');
        insert quote;

        //PBE
        PricebookEntry pbe; PricebookEntry pbe2; PricebookEntry pbe3;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :prod.Id OR Product2Id = :prod2.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == prod.Id) pbe = pbeSelected;
            else if(pbeSelected.Product2Id == prod2.Id) pbe2 = pbeSelected;
        }

        // Ligne de devis
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=2,Tarifhorsdimension__c=56.0, PricebookEntryId = pbe.Id,UnitPrice=56.0, TVAPourcentage__c = 0.2);
        qliList.add(qli);
        QuoteLineItem qli2 = new QuoteLineItem(QuoteId = quote.Id,Nombredevantaux__c = '1',Hauteur__c=100,Largeur__c=30,Quantity=1,Tarifhorsdimension__c=50.0, PricebookEntryId = pbe2.Id,UnitPrice=50.0, TVAPourcentage__c = 0.2);
        qliList.add(qli2);
        insert qliList;
        // Options des produits
        List<Option__c> optList = new List<Option__c>();
        Option__c option1 = new Option__c(Option__c=refOpt.Id, ligneDevis__c = qli.Id, PrixunitaireHT__c = 1, Libelleoption__c = 'Libellé Option 1', codeOption__c='1');
        optList.add(option1);
        Option__c option2 = new Option__c(Option__c=refOpt2.Id, ligneDevis__c = qli.Id, PrixunitaireHT__c = 1, Libelleoption__c = 'Libellé Option 2', codeOption__c='2');
        optList.add(option2);
        insert optList;
    }

    @isTest 
    static void test_SelectProduct_SaveAdd() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        
        System.runAs(user){
            // Récupération ID devis
            Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];
            PricebookEntry pBE = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];

            Test.startTest();

            // Création de la page et ajout des parametres
            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl001_Quote_SelectProduct ctrl = new Ctrl001_Quote_SelectProduct(sc);
            PageReference newPRpage = Page.VF001_Quote_SelectProduct;
            newPRpage.getParameters().put('retURL','asdf');
            newPRpage.getParameters().put('id',devis.Id);
            Test.setCurrentPage (newPRpage);

            // Initialise la page
            ctrl.keyWord='abc';
            ctrl.initPSS();
            ctrl.selectedIds = pBE.Id;

            // Initialise la grille des produits
            ctrl.initGrid();

            ctrl.qliList[0].Nombredevantaux__c='1';
            ctrl.qliList[0].Hauteur__c= 50;
            ctrl.qliList[0].Largeur__c= 50;

            // Sauvegarde
            ctrl.saveAndAdd();

            Test.stopTest();
        }
    }

    @isTest 
    static void test_SelectProduct_ModifySave() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        
        System.runAs(user){
            // Récupération ID devis
            Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];

            Test.startTest();

            // Création de la page et ajout des parametres
            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl001_Quote_SelectProduct ctrl = new Ctrl001_Quote_SelectProduct(sc);
            PageReference newPRpage = Page.VF001_Quote_SelectProduct;
            newPRpage.getParameters().put('retURL','asdf');
            newPRpage.getParameters().put('id',devis.Id);
            Test.setCurrentPage (newPRpage);

            // Initialise la page
            ctrl.keyWord='abc';
            ctrl.initPSS();

            // Initialise la grille des produits
            ctrl.initGrid();

            // Sauvegarde
            if(ctrl.qliList[0]!=null) {
                ctrl.qliList[0].Nombredevantaux__c='1';
                ctrl.save();
                ctrl.qliList[0].Nombredevantaux__c='2';
                ctrl.save();
            }

            Test.stopTest();
        }
    }

    @isTest 
    static void test_SelectProduct_Search() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        
        System.runAs(user){
            // Récupération ID devis
            Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];
            PricebookEntry pBE = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];

            Test.startTest();

            // Création de la page et ajout des parametres
            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl001_Quote_SelectProduct ctrl = new Ctrl001_Quote_SelectProduct(sc);
            PageReference newPRpage = Page.VF001_Quote_SelectProduct;
            newPRpage.getParameters().put('retURL','asdf');
            newPRpage.getParameters().put('id',devis.Id);
            Test.setCurrentPage (newPRpage);

            // Initialise la page
            ctrl.keyWord='abc';
            ctrl.initPSS();
            ctrl.selectedIds = pBE.Id;
            
            // Création des TVA
            TVA_Produit__c tvp = new TVA_Produit__c (Produit__c = pBE.Product2Id, Datedebut__c = Date.today().addDays(-1),
                                                        idTiers__c = '111', Taux__c = 5.5 );
            insert tvp;

            // Initialise la grille des produits
            ctrl.initGrid();

            ctrl.qliList[0].Nombredevantaux__c='1';
            ctrl.qliList[0].Hauteur__c= 50;
            ctrl.qliList[0].Largeur__c= 50;
            
            ctrl.getproductListIndex();
            ctrl.qliList = new List<QuoteLineItem>();
            ctrl.saveAndAdd();

            // Recherche
            ctrl.devis.Pricebook2Id = null;
            ctrl.initPSS();
            List<Product2> productList = ctrl.productList;
            ctrl.orderByChange = true;
            ctrl.orderByOrder='asc';
            ctrl.search();

            Test.stopTest();
        }
    }

    @isTest 
    static void test_SelectProduct_Utilitaire() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        
        System.runAs(user){
            // Récupération ID devis
            Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];
            PricebookEntry pBE = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];

            Test.startTest();

            // Création de la page et ajout des parametres
            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl001_Quote_SelectProduct ctrl = new Ctrl001_Quote_SelectProduct(sc);
            PageReference newPRpage = Page.VF001_Quote_SelectProduct;
            newPRpage.getParameters().put('retURL','asdf');
            newPRpage.getParameters().put('id',devis.Id);
            Test.setCurrentPage (newPRpage);

            // Initialise la page
            ctrl.keyWord='abc';
            ctrl.initPSS();
            ctrl.selectedIds = pBE.Id;

            // Utilitaire
            ctrl.getproductListIndex();
            ctrl.cancel();
            ctrl.addToQuote();

            Test.stopTest();
        }
    }

}