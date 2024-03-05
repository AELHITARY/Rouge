//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_DevisContrat_PDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/12/2022
//-- Version     : 1.3
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_DevisContrat_PDF {

    @testSetup 
    static void setup() {
        // Récupération Record Type
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email', true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier, true);

        //Utils_Test.createCoeffTh(prod2.Id,refOpt.Id,'Sw',1,'T','2',true);
        //Utils_Test.createOption(qli2.Id,'3','Libellé Option 3',refOpt.Id,220,true);
    }

    @isTest
    private static void test_PDF_devis() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
        // Récupération ID devis
        //Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];
        System.runAs(userTest) {
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            //Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,true);
            //Product2 prod3 = Utils_Test.createProduct('FORFAIT A','FORFAIT A','Autre','AUT',50,50,true);
            
            // Options référence
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            insert refOptList;
            // Coefficient thermique
            Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',refOpt2.Id,'Uv',2,'A','1',true);

            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, false);
            devis.typeContrat__c = null;
            insert devis;

            Test.startTest();
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);
            // Options des produits
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,false);
            optList.add(opt1);
            optList.add(opt2);
            insert optList;

            // Création de la page et ajout des parametres
            PageReference pagePDF = Page.VF_DevisContrat_PDF;
            pagePDF.getParameters().put('qId', devis.Id);
            pagePDF.getParameters().put('type', 'devis');
            Test.setCurrentPage(pagePDF);

            // Création controleur
            Ctrl_DevisContrat_PDF ctrl = new Ctrl_DevisContrat_PDF();
            ctrl.getInfoDevis();

            Test.stopTest();

            // Verification
            system.assertNotEquals(null, ctrl.quote);
            system.assertEquals(false, ctrl.isContrat);
        }
    }

    @isTest
    private static void test_PDF_devis_sans_lignes() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
        // Récupération ID devis
        //Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];
        System.runAs(userTest) {
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            //Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,true);
            //Product2 prod3 = Utils_Test.createProduct('FORFAIT A','FORFAIT A','Autre','AUT',50,50,true);
            
            // Options référence
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            insert refOptList;
            // Coefficient thermique
            Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',refOpt2.Id,'Uv',2,'A','1',true);

            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, false);
            devis.typeContrat__c = null;
            insert devis;

            Test.startTest();
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);

            // Création de la page et ajout des parametres
            PageReference pagePDF = Page.VF_DevisContrat_PDF;
            pagePDF.getParameters().put('qId', devis.Id);
            pagePDF.getParameters().put('type', 'devis');
            Test.setCurrentPage(pagePDF);

            // Création controleur
            Ctrl_DevisContrat_PDF ctrl = new Ctrl_DevisContrat_PDF();
            ctrl.getInfoDevis();
            //ctrl.getCoefThermique();

            Test.stopTest();

            // Verification
            system.assertNotEquals(null, ctrl.quote);
            system.assertEquals(false, ctrl.isContrat);
            //system.assertEquals(2, ctrl.prodList.size());
            if(ctrl.prodList.size() > 0) {
                ctrl.prodList[0].getCoefThermique();
                system.assertNotEquals(0, ctrl.prodList[0].getQuantity());
            }
        }
    }

    @isTest
    private static void test_PDF_contrat() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
        // Récupération ID devis
        //Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];
        System.runAs(userTest) {
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            //Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,true);
            //Product2 prod3 = Utils_Test.createProduct('FORFAIT A','FORFAIT A','Autre','AUT',50,50,true);
            
            // Options référence
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            insert refOptList;
            // Coefficient thermique
            Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',refOpt2.Id,'Uv',2,'A','1',true);
            
            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, false);
            devis.typeContrat__c = null;
            insert devis;

            Test.startTest();
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);
            // Options des produits
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,false);
            optList.add(opt1);
            optList.add(opt2);
            insert optList;

            // Création de la page et ajout des parametres
            PageReference pagePDF = Page.VF_DevisContrat_PDF;
            pagePDF.getParameters().put('qId', devis.Id);
            pagePDF.getParameters().put('type', 'contrat');
            Test.setCurrentPage(pagePDF);

            // Création controleur et test
            Ctrl_DevisContrat_PDF ctrl = new Ctrl_DevisContrat_PDF();
            ctrl.prodList[0].getCoefThermique();
            ctrl.prodList[0].getQuantity();
            ctrl.prodList[0].getIsOptVers();

            Test.stopTest();

            // Verification
            system.assertNotEquals(null, ctrl.quote);
            system.assertEquals(true, ctrl.isContrat);
            //system.assertEquals(2, ctrl.prodList.size());
            if(ctrl.prodList.size() > 0) {
                ctrl.prodList[0].getCoefThermique();
                system.assertNotEquals(0, ctrl.prodList[0].getQuantity());
            }

        }
    }

    @isTest
    private static void test_PDF_devisTMC() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        Opportunity opp = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
        //Quote devis = [SELECT Id FROM Quote WHERE Name = 'Devis 1'];
        System.runAs(userTest) {
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            //Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,true);
            //Product2 prod3 = Utils_Test.createProduct('FORFAIT A','FORFAIT A','Autre','AUT',50,50,true);
            
            // Options référence
            List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
            refOptList.add(refOpt);
            refOptList.add(refOpt2);
            insert refOptList;
            // Coefficient thermique
            Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',refOpt2.Id,'Uv',2,'A','1',true);
            
            // Test avec devis TMC
            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, false);
            devis.typeContrat__c = null;
            insert devis;
            Test.startTest();
            
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
            //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);
            // Options des produits
            List<Option__c> optList = new List<Option__c>();
            Option__c opt1 = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            Option__c opt2 = Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,false);
            optList.add(opt1);
            optList.add(opt2);
            insert optList;        
            devis.dateAcceptationClient__c = null;    
            devis.dateTransmissionClient__c = null;
            devis.moyenTransmissionClient__c = '';
            devis.devisTMC__c = true;
            update devis;

            

            // Création de la page et ajout des parametres
            PageReference pagePDF = Page.VF_DevisContrat_PDF;
            pagePDF.getParameters().put('qId', devis.Id);
            pagePDF.getParameters().put('type', 'contrat');
            Test.setCurrentPage(pagePDF);
    
            try {
                // Erreur car non possible si PDF != depot
                Ctrl_DevisContrat_PDF ctrl = new Ctrl_DevisContrat_PDF();
            } catch(Exception e) {

            }

            Test.stopTest();
        }
    }
}