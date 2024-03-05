//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Pages_ClonageDevisEtLigne
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/12/2018
//-- Version     : 1.1
//-- * 1.1 : RQM-77 : Ajout du clonage en Devis TMC
//-- * 1.0 : Fusion des classes Test_Ctrl012_ClonerDevis et Test_Ctrl_ClonerLigneDevis
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Pages_ClonageDevisEtLigne{
    
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Récupération record type
        String accPersonRTId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        // Création enregistrement utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersonRTId, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

        // Creation produits
        List<Product2> prodList = new List<Product2>();
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
        Product2 prod2 = Utils_Test.createProduct('Produit Test 2','FFFET2','Fenetre','PVC',50,50,false);
        prod2.IsActive=false;
        prodList.add(prod);
        prodList.add(prod2);
        insert prodList;

        // Options référence
        List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
        ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,false);
        ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,false);
        refOptList.add(refOpt);
        refOptList.add(refOpt2);
        insert refOptList;

        // Creation devis
        Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
        devis.source__c = 'BAL VENDEUR';
        insert devis;
        /*Quote devis2 = Utils_Test.createQuote('Devis 2', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false); 
        devis2.source__c = 'BAL VENDEUR';
        insert devis2;*/

        // Ligne de devis
        QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);
        //QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(devis2.Id, '1', 30, 100, 1, 50.0, 50.0, prod2,true);

        // Options des produits
        List<Option__c> optList = new List<Option__c>();
        Option__c opt1 = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
        Option__c opt2 = Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,false);
        Option__c opt3 = Utils_Test.createOption(qli.Id,'3','Libellé Option 3',refOpt.Id,220,false);
        optList.add(opt1);
        optList.add(opt2);
        optList.add(opt3);
        insert optList;
    }

    @isTest
    private static void test_devis_ProduitsActif() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            // Récupération enregistrement du devis avec produit actif
            Quote devis = [SELECT Id FROM Quote WHERE Name='Devis 1' LIMIT 1];

            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl012_ClonerDevis ctrl = new Ctrl012_ClonerDevis(sc);
            ctrl.getBackUrl();
            ctrl.init();
            ctrl.cloner();
            ctrl.getMsgWarningDevisErrone();
            ctrl.getTest();
            Test.stopTest();
        }
    }

    @isTest
    private static void test_devis_ProduitsNonActif() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            // Récupération enregistrement du devis avec produit non actif
            Quote devis = [SELECT Id FROM Quote WHERE Name='Devis 1' LIMIT 1];

            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl012_ClonerDevis ctrl = new Ctrl012_ClonerDevis(sc);
            ctrl.isDevisTMC = true;
            ctrl.getBackUrl();
            ctrl.init();
            ctrl.cloner();
            ctrl.getTest();
            ctrl.getMsgWarningDevisErrone();
            Test.stopTest();
        }
    } 

    @isTest
    private static void test_devis_DevisTMC() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            // Récupération enregistrement du devis avec produit non actif
            Quote devis = [SELECT Id FROM Quote WHERE Name='Devis 1' LIMIT 1];

            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl012_ClonerDevis ctrl = new Ctrl012_ClonerDevis(sc);
            ctrl.isDevisTMC = true;
            ctrl.getBackUrl();
            ctrl.cloner();
            ctrl.getTest();
            Test.stopTest();
        }
    } 

    @isTest
    private static void test_devis_AvecOptions() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){            
            Test.startTest();
            
            // Récupération enregistrement du devis 
            Quote devis = [SELECT Id FROM Quote WHERE Name='Devis 1' LIMIT 1];
            
            ReferentielOptions__c refOpt = [SELECT Id, Debutvalidite__c, Finvalidite__c FROM ReferentielOptions__c WHERE Name='RefOption' LIMIT 1];
            refOpt.Debutvalidite__c = Date.today().addMonths(-1);
            refOpt.Finvalidite__c = Date.today().addYears(1);
            update refOpt;
            ReferentielOptions__c refOpt2 = [SELECT Id, Debutvalidite__c, Finvalidite__c FROM ReferentielOptions__c WHERE Name='RefOption2' LIMIT 1];
            refOpt2.Debutvalidite__c = Date.today().addYears(-2);
            refOpt2.Finvalidite__c = Date.today().addYears(-1);
            update refOpt2;
            
            // Test avec une option valide et invalide
            ApexPages.StandardController sc = new ApexPages.standardController(devis);
            Ctrl012_ClonerDevis ctrl = new Ctrl012_ClonerDevis(sc);
            ctrl.getBackUrl();
            ctrl.init();
            ctrl.cloner();
            ctrl.getMsgWarningDevisErrone();
            ctrl.isConfirm = true;
            ctrl.updateStatutErrone();
            ctrl.getTest();
            Test.stopTest();
        }
    }

    @isTest
    private static void test_ClonerLigneDevis() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            // Récupération enregistrement
            QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];

            // Clonage ligne de devis
            ApexPages.StandardController sc = new ApexPages.standardController(qli);
            Ctrl_ClonerLigneDevis ctrl = new Ctrl_ClonerLigneDevis(sc);
            ctrl.cloner();

            // Delete
            QuoteLineItem qliCloned = [SELECT Id FROM QuoteLineItem WHERE Id != :qli.Id LIMIT 1];
            delete qliCloned;

            Test.stopTest();
        }
    }
}