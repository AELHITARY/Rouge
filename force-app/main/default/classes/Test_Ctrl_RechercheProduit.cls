//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_RechercheProduit
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/10/2018
//-- Version     : 1.3
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_RechercheProduit {
    static Double longitude = 2.3354245000000446;
    static Double latitude = 48.8807489;

    @testSetup static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);

        // Récupération des Record Type
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        // Création enregistrement utile
        Account acc = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', accPersoRT, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
        chantier.Localisation__Latitude__s = latitude;
        chantier.Localisation__Longitude__s = longitude;
        insert chantier;

        //test 2eme chantier
        Chantier__c chantier2 = Utils_Test.createChantier('Chantier 2', acc.Id,false);
        chantier2.Localisation__Latitude__s = latitude;
        chantier2.Localisation__Longitude__s = longitude;
        insert chantier2;


        Opportunity opp = Utils_Test.createOpportunity(acc, chantier, true);
        KContrat__c contrat = Utils_Test.createContrat('Contrat', chantier2.Id, acc.Id, '0001', true);

        Opportunity opp2 = Utils_Test.createOpportunity(acc, chantier2, true);
        //KContrat__c contrat2 = Utils_Test.createContrat('Contrat2', chantier2.Id, acc.Id, '0001', true);
    }

    @isTest static void test_Search_WithOptions_Exacte() {
        //creation utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Creation de la liste des produits a chercher
            //Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            Test.startTest();

            Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            // Creation produit
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            // Creation devis avec option
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            
            insert devis;
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);

            // Options produit
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('OFEPVC0119','OFEPVC0119','OFEPVC0119',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('OFEPVC0120','OFEPVC0120','OFEPVC0120',1,false);
            ReferentielOptions__c refOpt3 = Utils_Test.createRefOption('OFEPVC0121','OFEPVC0121','OFEPVC0121',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            refOptList.add(refOpt3);
            insert refOptList;
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'OFEPVC0119','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'OFEPVC0120','Libellé Option 2',refOpt2.Id,10,false);
            Option__c opt3 = Utils_Test.createOption(qli.Id,'OFEPVC0121','Libellé Option 3',refOpt3.Id,220,false);
            insert optList;
            
            // Mise à jour devis en vendu
            devis.dateAcceptationClient__c = Date.today();
            devis.dateTransmissionClient__c = Date.today();
            devis.moyenTransmissionClient__c = 'En main propre chez le client';
            update devis; 
            
            Map<String, List<String>> produitOptions=new Map<String, List<String>>();
            List<String> listOption1 = new List<String>();
            //List<ReferentielOptions__c> optList = [SELECT Id FROM ReferentielOptions__c];
            listOption1.add(refOpt.Id);
            listOption1.add(refOpt2.Id);
            listOption1.add(refOpt3.Id);
            listOption1.add('1');
            //Product2 prod = [SELECT Id FROM ProducT2 WHERE ProductCode = 'FFFETT' LIMIT 1];
            produitOptions.put(prod.Id, listOption1);
            // Information de recherche
            Integer perimeter = 500;

            
            PageReference vf_recherche = Page.VF_RechercheProduit;
            Test.setCurrentPageReference (vf_recherche);
            Ctrl_RechercheProduit ctrl = new Ctrl_RechercheProduit();
            ctrl.getpaysList();
            // Recherche compte et récupération vendeurs
            String compteId = [SELECT id, Name FROM Account WHERE LastName = 'Account Un' LIMIT 1].Id;
            system.assertEquals(1, Ctrl_RechercheProduit.recupereCompte(compteId).size());
            Ctrl_RechercheProduit.getVendeursList();
          
            // Recherche avec produit.
            Ctrl_RechercheProduit.searchChantiersProducts(produitOptions, latitude, longitude, perimeter);
            Test.setCurrentPageReference(ctrl.newSearch());
            Test.setCurrentPageReference(ctrl.newSearchWithError());
            ctrl.insertUserStats();

            Test.stopTest();
        }
    }

    @isTest static void test_Search_WithOptions_Option() {
        //creation utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            
            // Creation produit
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            Test.startTest();
            // Creation devis avec option
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            
            insert devis;
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            
            // Options produit
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('OFEPVC0119','OFEPVC0119','OFEPVC0119',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('OFEPVC0120','OFEPVC0120','OFEPVC0120',1,false);
            ReferentielOptions__c refOpt3 = Utils_Test.createRefOption('OFEPVC0121','OFEPVC0121','OFEPVC0121',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            refOptList.add(refOpt3);
            insert refOptList;
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'OFEPVC0119','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'OFEPVC0120','Libellé Option 2',refOpt2.Id,10,false);
            Option__c opt3 = Utils_Test.createOption(qli.Id,'OFEPVC0121','Libellé Option 3',refOpt3.Id,220,false);
            insert optList;
            
            // Mise à jour devis en vendu
            devis.dateAcceptationClient__c = Date.today();
            devis.dateTransmissionClient__c = Date.today();
            devis.moyenTransmissionClient__c = 'En main propre chez le client';
            update devis;
            
            // Creation de la liste des produits a chercher
            Map<String, List<String>> produitOptions=new Map<String, List<String>>();
            List<String> listOption1 = new List<String>();
            //List<ReferentielOptions__c> optList = [SELECT Id FROM ReferentielOptions__c];
            listOption1.add(refOpt.Id);
            listOption1.add('');
            listOption1.add('');
            listOption1.add('1');
            //Product2 prod = [SELECT Id FROM ProducT2 WHERE ProductCode = 'FFFETT' LIMIT 1];
            produitOptions.put(prod.Id, listOption1);
            // Information de recherche
            Integer perimeter = 500;

            PageReference vf_recherche = Page.VF_RechercheProduit;
            Test.setCurrentPageReference (vf_recherche);
            Ctrl_RechercheProduit ctrl = new Ctrl_RechercheProduit();
            ctrl.getpaysList();
            // Recherche compte et récupération vendeurs
            String compteId = [SELECT id, Name FROM Account WHERE LastName = 'Account Un' LIMIT 1].Id;
            system.assertEquals(1, Ctrl_RechercheProduit.recupereCompte(compteId).size());
            Ctrl_RechercheProduit.getVendeursList();

            // Recherche avec produit.
            Ctrl_RechercheProduit.searchChantiersProducts(produitOptions, latitude, longitude, perimeter);
            Test.setCurrentPageReference(ctrl.newSearch());
            Test.setCurrentPageReference(ctrl.newSearchWithError());
            ctrl.insertUserStats();

            Test.stopTest();
        }
    }

    @isTest static void test_CheckFielsValues() {
        //creation utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            
            // Creation produit
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            Test.startTest();
            // Creation devis avec option
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            
            insert devis;
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            
            // Options produit
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('OFEPVC0119','OFEPVC0119','OFEPVC0119',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('OFEPVC0120','OFEPVC0120','OFEPVC0120',1,false);
            ReferentielOptions__c refOpt3 = Utils_Test.createRefOption('OFEPVC0121','OFEPVC0121','OFEPVC0121',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            refOptList.add(refOpt3);
            insert refOptList;
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'OFEPVC0119','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'OFEPVC0120','Libellé Option 2',refOpt2.Id,10,false);
            Option__c opt3 = Utils_Test.createOption(qli.Id,'OFEPVC0121','Libellé Option 3',refOpt3.Id,220,false);
            insert optList;
            
            // Mise à jour devis en vendu
            devis.dateAcceptationClient__c = Date.today();
            devis.dateTransmissionClient__c = Date.today();
            devis.moyenTransmissionClient__c = 'En main propre chez le client';
            update devis;

            PageReference vf_recherche = Page.VF_RechercheProduit;
            Test.setCurrentPageReference (vf_recherche);
            Ctrl_RechercheProduit ctrl = new Ctrl_RechercheProduit();

            // Init
            ctrl.rue = '';
            ctrl.prd1 = '';
            ctrl.opt11 = '';
            ctrl.opt12 = '';
            ctrl.opt13 = '';
            ctrl.prd2 = '';
            ctrl.opt21 = '';
            ctrl.opt22 = '';
            ctrl.opt23 = '';
            ctrl.prd3 = '';
            ctrl.opt31 = '';
            ctrl.opt32 = '';
            ctrl.opt33 = '';

            // Test sans paramètre
            system.assertEquals(null, ctrl.resultatProduit());
            // Test avec adresse mais sans produit
            ctrl.rue = '1 rue TEST';
            system.assertEquals(null, ctrl.resultatProduit());
            // Test avec adresse mais avec option 1 mais sans produit 1
            ctrl.rue = '1 rue TEST';
            ctrl.prd1 = '';
            ctrl.opt11 = 'OPTION11';
            system.assertEquals(null, ctrl.resultatProduit());
            // Test avec adresse mais avec option 2 mais sans produit 2
            ctrl.rue = '1 rue TEST';
            ctrl.prd1 = 'PRODUIT1';
            ctrl.prd2 = '';
            ctrl.opt21 = 'OPTION21';
            system.assertEquals(null, ctrl.resultatProduit());
            // Test avec adresse mais avec option 3 mais sans produit 3
            ctrl.rue = '1 rue TEST';
            ctrl.prd1 = 'PRODUIT1';
            ctrl.prd2 = 'PRODUIT2';
            ctrl.prd3 = '';
            ctrl.opt31 = 'OPTION31';
            system.assertEquals(null, ctrl.resultatProduit());
            // Test avec adresse mais avec deux meme produits
            ctrl.rue = '1 rue TEST';
            ctrl.prd1 = 'PRODUIT1';
            ctrl.opt11 = '';
            ctrl.prd2 = 'PRODUIT1';
            ctrl.opt21 = '';
            ctrl.prd3 = '';
            ctrl.opt31 = '';
            system.assertEquals(null, ctrl.resultatProduit());
            // Test sans produits
            ctrl.rue = '1 rue TEST';
            ctrl.prd1 = '';
            ctrl.opt11 = '';
            ctrl.prd2 = '';
            ctrl.opt21 = '';
            ctrl.prd3 = '';
            ctrl.opt31 = '';
            system.assertEquals(null, ctrl.resultatProduit());
            // Test OK
            ctrl.rue = '1 rue TEST';
            ctrl.prd1 = 'PRODUIT1';
            ctrl.opt11 = '';
            ctrl.prd2 = '';
            ctrl.opt21 = '';
            ctrl.prd3 = '';
            ctrl.opt31 = '';
            system.assertNotEquals(null, ctrl.resultatProduit());

            Test.stopTest();
        }
    }
    
    @isTest static void test_otherTests() {Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            
            // Creation produit
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            Test.startTest();
            // Creation devis avec option
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            
            insert devis;
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            
            // Options produit
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('OFEPVC0119','OFEPVC0119','OFEPVC0119',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('OFEPVC0120','OFEPVC0120','OFEPVC0120',1,false);
            ReferentielOptions__c refOpt3 = Utils_Test.createRefOption('OFEPVC0121','OFEPVC0121','OFEPVC0121',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            refOptList.add(refOpt3);
            insert refOptList;
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'OFEPVC0119','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'OFEPVC0120','Libellé Option 2',refOpt2.Id,10,false);
            Option__c opt3 = Utils_Test.createOption(qli.Id,'OFEPVC0121','Libellé Option 3',refOpt3.Id,220,false);
            insert optList;
            
            // Mise à jour devis en vendu
            devis.dateAcceptationClient__c = Date.today();
            devis.dateTransmissionClient__c = Date.today();
            devis.moyenTransmissionClient__c = 'En main propre chez le client';
            update devis;

        PageReference vf_recherche = Page.VF_RechercheProduit;
        Test.setCurrentPageReference (vf_recherche);
        Ctrl_RechercheProduit ctrl = new Ctrl_RechercheProduit();
        
        // Lookup Options
        //ReferentielOptions__c opt = [SELECT Id FROM ReferentielOptions__c WHERE codeoption__c = 'OFEPVC0119' LIMIT 1];
        ctrl.displayOptionId11 = refOpt.Id;
        ctrl.displayOptionId12 = refOpt.Id;
        ctrl.displayOptionId13 = refOpt.Id;
        ctrl.displayOptionId21 = refOpt.Id;
        ctrl.displayOptionId22 = refOpt.Id;
        ctrl.displayOptionId23 = refOpt.Id;
        ctrl.displayOptionId31 = refOpt.Id;
        ctrl.displayOptionId32 = refOpt.Id;
        ctrl.displayOptionId33 = refOpt.Id;
        ReferentielOptions__c opt11 = ctrl.optionSample11;
        ReferentielOptions__c opt12 = ctrl.optionSample12;
        ReferentielOptions__c opt13 = ctrl.optionSample13;
        ReferentielOptions__c opt21 = ctrl.optionSample21;
        ReferentielOptions__c opt22 = ctrl.optionSample22;
        ReferentielOptions__c opt23 = ctrl.optionSample23;
        ReferentielOptions__c opt31 = ctrl.optionSample31;
        ReferentielOptions__c opt32 = ctrl.optionSample32;
        ReferentielOptions__c opt33 = ctrl.optionSample33;
        List<ReferentielOptions__c> baseOptions = ctrl.baseOptions;
        
        // Lookup Produit
        //Product2 prod = [SELECT Id FROM ProducT2 WHERE ProductCode = 'FFFETT' LIMIT 1];
        ctrl.displayProductId1 = prod.Id;
        ctrl.displayProductId2 = prod.Id;
        ctrl.displayProductId3 = prod.Id;
        Product2 productSample = ctrl.productSample;
        Product2 productSample2 = ctrl.productSample2;
        Product2 productSample3 = ctrl.productSample3;
        ctrl.productCode1= 'FFFETT';
        ctrl.productCode2= 'FFFETT';
        ctrl.productCode3= 'FFFETT';
        
        Test.stopTest();
    }

    @isTest static void test_Search_MultipleChantiers() {
        //creation utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Creation de la liste des produits a chercher
            //Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            Test.startTest();

            List<Opportunity> opportunities = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity];
            // Creation produit
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            // Creation devis avec option
            List<Quote> devisList = new List<Quote>(); 
            Quote devis = Utils_Test.createQuote('Devis 1', null, opportunities[0], Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            Quote devis2 = Utils_Test.createQuote('Devis 2', null, opportunities[1], Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            devisList.Add(devis);
            devisList.Add(devis2);           
            insert devisList;
            
            // Ligne de devis
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,false);
            QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis2.Id, '1', 30, 100, 2, 56.0, 56.0, prod, false);
            qliList.Add(qli);
            qliList.Add(qli2);
            insert qliList;

            // Options produit
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('OFEPVC0119','OFEPVC0119','OFEPVC0119',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('OFEPVC0120','OFEPVC0120','OFEPVC0120',1,false);
            ReferentielOptions__c refOpt3 = Utils_Test.createRefOption('OFEPVC0121','OFEPVC0121','OFEPVC0121',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            refOptList.add(refOpt3);
            insert refOptList;
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'OFEPVC0119','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'OFEPVC0120','Libellé Option 2',refOpt2.Id,10,false);
            Option__c opt3 = Utils_Test.createOption(qli.Id,'OFEPVC0121','Libellé Option 3',refOpt3.Id,220,false);
            insert optList;
            
            // Mise à jour devis en vendu
            devis.dateAcceptationClient__c = Date.today();
            devis.dateTransmissionClient__c = Date.today();
            devis.moyenTransmissionClient__c = 'En main propre chez le client';
            update devis; 
            
            Map<String, List<String>> produitOptions=new Map<String, List<String>>();
            List<String> listOption1 = new List<String>();
            //List<ReferentielOptions__c> optList = [SELECT Id FROM ReferentielOptions__c];
            listOption1.add(refOpt.Id);
            listOption1.add(refOpt2.Id);
            listOption1.add(refOpt3.Id);
            listOption1.add('1');
            //Product2 prod = [SELECT Id FROM ProducT2 WHERE ProductCode = 'FFFETT' LIMIT 1];
            produitOptions.put(prod.Id, listOption1);
            // Information de recherche
            Integer perimeter = 500;

            
            PageReference vf_recherche = Page.VF_RechercheProduit;
            Test.setCurrentPageReference (vf_recherche);
            Ctrl_RechercheProduit ctrl = new Ctrl_RechercheProduit();
            ctrl.getpaysList();
            // Recherche compte et récupération vendeurs
            String compteId = [SELECT id, Name FROM Account WHERE LastName = 'Account Un' LIMIT 1].Id;
            system.assertEquals(1, Ctrl_RechercheProduit.recupereCompte(compteId).size());
            Ctrl_RechercheProduit.getVendeursList();
            
            //Associer produit avec contrat
            KContrat__c contrat = [SELECT id FROM KContrat__c LIMIT 1];
            contrat.produits__c = '6 x Fenetre ThermiK 2 (FETH2), 1 x Porte d\'Entree PVC (FORANA), 1 x FORFAIT CHANTIER Autre (FORFAIT A), 3 x Porte-Fenetre ThermiK 2 (PFTH2)';
            update contrat;
            
            // Recherche avec produit.
            Ctrl_RechercheProduit.searchChantiersProducts(produitOptions, latitude, longitude, perimeter);
            Test.setCurrentPageReference(ctrl.newSearch());
            Test.setCurrentPageReference(ctrl.newSearchWithError());
            ctrl.insertUserStats();

            Test.stopTest();
        }
    }   
}