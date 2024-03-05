//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl003_SelectionOption
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2021
//-- Version     : 2.0
//-- * Ajout des tests pour les options PARRAINAGE et OPCLI
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl003_SelectionOption {

    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup 
    static void setup() {
        Id accountRecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        
        // Création des objets
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accountRecordTypeId, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('', acc.Id, null, null, null, acc.Id, null, 4, true);
        Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
    }

    @isTest 
    static void test_Ctrl003(){
        User uCurrentForecastUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);

        System.runAs(uCurrentForecastUser){
            Opportunity o = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            Product2 product = Utils_Test.createProduct('test', '1234', 'Fenetre', 'PVC', 50, 50, true); 
            PricebookEntry pe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id];
            // Création objet
            Quote q = Utils_Test.createQuote('Devis 1', null, o, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            q.source__c = 'BAL VENDEUR';
            q.callSource__c = 'BAL VENDEUR';
            insert q;
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(q.Id, '2', 100, 100, 2, 100, 100, pe.Id, false);
            insert qli;

            Apexpages.currentPage().getParameters().put('qliId',qli.id);
            Ctrl003_SelectionOption ctrl003 = new Ctrl003_SelectionOption(new Apexpages.Standardcontroller(qli));

            createOptions(product);

            Test.startTest();
            Apexpages.currentPage().getParameters().put('qliId',qli.id);
            ctrl003 = new Ctrl003_SelectionOption(new Apexpages.Standardcontroller(qli));
            ctrl003.versionLibelle = 'test9';
            ctrl003.initOptionVersionList();
            ctrl003.optionVersionLibelle = 'test13';
            for(Ctrl003_SelectionOption.SelectableOption so : ctrl003.selectableOptionList){
                so.selected = true;
                so.opt.Quantite__c = 1;
                so.getIsRadio();
                so.getClassName();
                so.getCodeOpt();
                so.getIsEditable();
                so.getIsSubstituable();
            }
            ctrl003.AjouterOPT();
            ctrl003.Annuler();
            ctrl003.getLoseModif();
            ctrl003.getChooseOpt();
            ctrl003.getChooseVersion();
            ctrl003.getIncompatibleOpt();
            ctrl003.getIncompatibilites();
            ctrl003.getIncompatibleOptVers();

            Apexpages.currentPage().getParameters().put('qliId',qli.id);
            ctrl003 = new Ctrl003_SelectionOption(new Apexpages.Standardcontroller(qli));
            Test.stopTest();
        }
    }

    @isTest 
    static void test_Ctrl003_parrainage(){
        User uCurrentForecastUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);

        System.runAs(uCurrentForecastUser){
            Opportunity o = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            Product2 product = TestCommon.createProduct('test', '1234');
            PricebookEntry pe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id];
            
            Test.startTest();
            // Création devis type PARRAINAGE
            Quote q = Utils_Test.createQuote('Devis 1', null, o, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            insert q; 
            //TestCommon.createPricebookEntry(product);
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(q.Id, '2', 100, 100, 2, 100, 100, pe.Id, false);
            QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(q.Id, '2', 100, 100, 2, 100, 100, pe.Id, false);
            qliList.add(qli);
            qliList.add(qli2);
            insert qliList;
            //Quote q = [SELECT Id,source__c,callSource__c FROM Quote LIMIT 1];
            q.source__c = 'PARRAINAGE VENDEUR';
            update q;
            //Product2 product = [SELECT Id FROM Product2 LIMIT 1];
            //QuoteLineItem qli1 = [SELECT Id FROM QuoteLineItem LIMIT 1];
            //QuoteLineItem qli2 = [SELECT Id FROM QuoteLineItem WHERE Id!=:qli1.Id LIMIT 1];
            createOptions(product);

            // Ajout premiere option PARRAINAGE - OK
            Apexpages.currentPage().getParameters().put('qliId',qli.id);
            Ctrl003_SelectionOption ctrl003 = new Ctrl003_SelectionOption(new Apexpages.Standardcontroller(qli));
            ctrl003.versionLibelle = 'test9';
            ctrl003.initOptionVersionList();
            ctrl003.optionVersionLibelle = 'test13';
            for(Ctrl003_SelectionOption.SelectableOption so : ctrl003.selectableOptionList){
                so.selected = true;
                so.opt.Quantite__c = 1;
            }
            ctrl003.AjouterOPT();

            // Ajout deuxième option PARRAINAGE - ERREUR
            Apexpages.currentPage().getParameters().put('qliId',qli2.id);
            ctrl003 = new Ctrl003_SelectionOption(new Apexpages.Standardcontroller(qli2));
            ctrl003.versionLibelle = 'test9';
            ctrl003.initOptionVersionList();
            ctrl003.optionVersionLibelle = 'test13';
            for(Ctrl003_SelectionOption.SelectableOption so : ctrl003.selectableOptionList){
                so.selected = true;
                so.opt.Quantite__c = 1;
            }
            ctrl003.AjouterOPT();
            Test.stopTest();
        }
    }

    @isTest 
    static void test_Ctrl003_opcli(){
        User uCurrentForecastUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);

        System.runAs(uCurrentForecastUser){
            Opportunity o = [SELECT id, Name, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            Product2 product = Utils_Test.createProduct('test', '1234', 'Fenetre', 'PVC', 50, 50, true); 
            PricebookEntry pe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id];
            // Création devis type différent de PARRAINAGE
            Test.startTest();
            Quote q = Utils_Test.createQuote('Devis 1', null, o, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            insert q; 
            //TestCommon.createPricebookEntry(product);
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(q.Id, '2', 100, 100, 2, 100, 100, pe.Id, false);
            QuoteLineItem qli2 = Utils_Test.createQuoteLineItem(q.Id, '2', 100, 100, 2, 100, 100, pe.Id, false);
            qliList.add(qli);
            qliList.add(qli2);
            insert qliList;
            //Quote q = [SELECT Id,source__c,callSource__c FROM Quote LIMIT 1];
            q.source__c = 'BAL VENDEUR';
            q.callSource__c = 'BAL VENDEUR';
            update q;
            //Product2 product = [SELECT Id FROM Product2 LIMIT 1];
            //QuoteLineItem qli1 = [SELECT Id FROM QuoteLineItem LIMIT 1];
            //QuoteLineItem qli2 = [SELECT Id FROM QuoteLineItem WHERE Id!=:qli1.Id LIMIT 1];
            createOptions(product);

            // Ajout premiere option OPCLI - OK
            Apexpages.currentPage().getParameters().put('qliId',qli.id);
            Ctrl003_SelectionOption ctrl003 = new Ctrl003_SelectionOption(new Apexpages.Standardcontroller(qli));
            ctrl003.versionLibelle = 'test9';
            ctrl003.initOptionVersionList();
            ctrl003.optionVersionLibelle = 'test13';
            for(Ctrl003_SelectionOption.SelectableOption so : ctrl003.selectableOptionList){
                so.selected = true;
                so.opt.Quantite__c = 1;
            }
            ctrl003.AjouterOPT();

            // Pas d'ajout option OPCLI - ERREUR
            Apexpages.currentPage().getParameters().put('qliId',qli2.id);
            ctrl003 = new Ctrl003_SelectionOption(new Apexpages.Standardcontroller(qli2));
            ctrl003.versionLibelle = 'test9';
            ctrl003.initOptionVersionList();
            ctrl003.optionVersionLibelle = 'test13';
            ctrl003.AjouterOPT();
            Test.stopTest();
        }
    }

    // Fonction de création d'options pour un produits
    //---------------------------------------------------
    private static void createOptions(Product2 p) {
        Revision_Pack__c rp = new Revision_Pack__c();
        rp.Datedapplication__c = Date.today().addDays(-1);
        rp.CodeProduit__c = p.Id;
        insert rp;
        List<ReferentielOptions__c> refOptList = new List<ReferentielOptions__c>();
        for(Integer i=1; i<=6; i++)
            refOptList.add(TestCommon.createRefOpt('test'+i, i,'test'+i));
        refOptList.add(TestCommon.createRefOpt('PARRAINAGE', 2,'PARRAINAGE'));
        refOptList.add(TestCommon.createRefOpt('OPCLI', 2,'OPCLI'));

        // Création options
        ReferentielOptions__c version = TestCommon.createRefOpt('test9', 1,'test9');
        ReferentielOptions__c packOption = TestCommon.createRefOpt('test10', 1,'test10');
        ReferentielOptions__c categOption = TestCommon.createRefOpt('test11', 1,'test11');
        ReferentielOptions__c pereOptversion = TestCommon.createRefOpt('test12', 1,'test12');
        ReferentielOptions__c optversion = TestCommon.createRefOpt('test13', 1,'test13');
        ReferentielOptions__c optROOT = TestCommon.createRefOpt('ROOT', 1,'test14');
        Pack__c VersionPack = TestCommon.createPack(optROOT.id,  version.id, null,rp.id);
        Pack__c Pack = TestCommon.createPack(version.id,  packOption.id, Constants.typeRegrPack,rp.id);
        Pack__c categPack = TestCommon.createPack(packOption.id,  categOption.id, Constants.typeRegrPack,rp.id);
        Pack__c pereOptVersPack = TestCommon.createPack(version.id,  pereOptversion.id, Constants.typeRegrOptVers,rp.id);
        Pack__c optVersPack = TestCommon.createPack(pereOptversion.id,  optversion.id, Constants.typeRegrOptVers,rp.id);
        List<Pack__c> optPack = new List<Pack__c>();
        for(Integer i=0; i < refOptList.size(); i++)
            optPack.add(TestCommon.createPack(categOption.id,  refOptList[i].id, Constants.typeRegrCateg,rp.id));
    }
}