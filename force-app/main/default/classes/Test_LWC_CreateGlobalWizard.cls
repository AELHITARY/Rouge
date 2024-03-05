//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CreateGlobalWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/08/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CreateGlobalWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CreateGlobalWizard {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

        // Création Sectorisation
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        Sectorisation__c secto = Utils_Test.createSectorisation('IRIS_'+Math.floor(Math.random()*10), 'MAG001Test', 'MAG Test', 'DEP001Test', 'DEP TEST','78560', 'LE PORT MARLY', true);

        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        List<Account> accList = new List<Account>();
        Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        chantier.telephoneDomicileProprietaires__c = '0123456789';
        chantier.sectorisation__c = secto.Id;
        chantier.codeMagasinTechnique__c = 'MAG001Test';
        update chantier;
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
    }

    @isTest
    private static void createAllObjects() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Map<String, String> accParams = new Map<String, String>();
            Map<String, String> chaParams = new Map<String, String>();
            Map<String, String> oppParams = new Map<String, String>();
            Map<String, String> quoParams = new Map<String, String>();
            Map<String, Boolean> objectsParams = new Map<String, Boolean>();

            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id, Name, Sectorisation__c FROM Chantier__c LIMIT 1];
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

            Account retrievedAcc = LWC_CreateGlobalWizard.getAccount(acc.Id);
            Chantier__c retrievedCha = LWC_CreateGlobalWizard.getChantier(cha.Id);
            Opportunity retrievedOpp = LWC_CreateGlobalWizard.getOpportunity(opp.Id);

            accParams.put('accId',retrievedAcc.Id);
            accParams.put('firstName','Jake');
            accParams.put('lastName','Peralta');
            accParams.put('civility','Mr.');
            accParams.put('accStreet','2 allée sisley');
            accParams.put('accPostalcode','78560');
            accParams.put('accState','Yvelines');
            accParams.put('accCity','Le Port Marly');
            accParams.put('accCountry','France');
            accParams.put('telDomicile','0101010101');
            accParams.put('source','BAL VENDEUR');

            chaParams.put('chaId',retrievedCha.Id);
            chaParams.put('chaStreet','2 allée sisley');
            chaParams.put('chaPostalcode','78560');
            chaParams.put('chaState','Yvelines');
            chaParams.put('chaCity','Le Port Marly');
            chaParams.put('chaCountry','France');

            oppParams.put('type','Nouveau');
            oppParams.put('datePrevisionelleSignature',String.valueOf(System.today().addDays(1)));

            quoParams.put('dateDevis',String.valueOf(System.today().addDays(-1)));

            objectsParams.put('hasChantier',true);
            objectsParams.put('hasOpportunity',true);
            objectsParams.put('hasQuote',true);
            objectsParams.put('createQuoteCPQ',false);

            LWC_CreateGlobalWizard.saveAllObjects(accParams, chaParams, oppParams, quoParams, null, objectsParams);

            Test.stopTest();
        }
    }

    @isTest
    private static void createAllObjects_CPQ() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Map<String, String> accParams = new Map<String, String>();
            Map<String, String> chaParams = new Map<String, String>();
            Map<String, String> oppParams = new Map<String, String>();
            Map<String, String> quoParams = new Map<String, String>();
            Map<String, Boolean> objectsParams = new Map<String, Boolean>();

            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id, Name, Sectorisation__c FROM Chantier__c LIMIT 1];
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

            Account retrievedAcc = LWC_CreateGlobalWizard.getAccount(acc.Id);
            Chantier__c retrievedCha = LWC_CreateGlobalWizard.getChantier(cha.Id);
            Opportunity retrievedOpp = LWC_CreateGlobalWizard.getOpportunity(opp.Id);

            accParams.put('accId',retrievedAcc.Id);
            accParams.put('firstName','Jake');
            accParams.put('lastName','Peralta');
            accParams.put('civility','Mr.');
            accParams.put('accStreet','2 allée sisley');
            accParams.put('accPostalcode','78560');
            accParams.put('accState','Yvelines');
            accParams.put('accCity','Le Port Marly');
            accParams.put('accCountry','France');
            accParams.put('telDomicile','0101010101');
            accParams.put('source','BAL VENDEUR');

            chaParams.put('chaId',retrievedCha.Id);
            chaParams.put('chaStreet','2 allée sisley');
            chaParams.put('chaPostalcode','78560');
            chaParams.put('chaState','Yvelines');
            chaParams.put('chaCity','Le Port Marly');
            chaParams.put('chaCountry','France');

            oppParams.put('type','Nouveau');
            oppParams.put('datePrevisionelleSignature',String.valueOf(System.today().addDays(1)));

            quoParams.put('dateDevis',String.valueOf(System.today().addDays(-1)));

            objectsParams.put('hasChantier',true);
            objectsParams.put('hasOpportunity',true);
            objectsParams.put('hasQuote',true);
            objectsParams.put('createQuoteCPQ',true);

            LWC_CreateGlobalWizard.saveAllObjects(accParams, chaParams, oppParams, null, quoParams, objectsParams);

            Test.stopTest();
        }
    }

    @isTest
    private static void createNewAccAndChantier() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Map<String, String> accParams = new Map<String, String>();
            Map<String, String> chaParams = new Map<String, String>();
            Map<String, String> oppParams = new Map<String, String>();
            Map<String, String> quoParams = new Map<String, String>();
            Map<String, Boolean> objectsParams = new Map<String, Boolean>();

            accParams.put('accId',null);
            accParams.put('firstName','Jake');
            accParams.put('lastName','Peralta');
            accParams.put('civility','Mr.');
            accParams.put('accStreet','2 allée sisley');
            accParams.put('accPostalcode','78560');
            accParams.put('accState','Yvelines');
            accParams.put('accCity','Le Port Marly');
            accParams.put('accCountry','France');
            accParams.put('telDomicile','0101010101');
            accParams.put('source','BAL VENDEUR');

            chaParams.put('chaId',null);
            chaParams.put('chaStreet','2 allée sisley');
            chaParams.put('chaPostalcode','78560');
            chaParams.put('chaState','Yvelines');
            chaParams.put('chaCity','Le Port Marly');
            chaParams.put('chaCountry','France');

            objectsParams.put('hasChantier',true);
            objectsParams.put('hasOpportunity',false);
            objectsParams.put('hasQuote',false);
            objectsParams.put('createQuoteCPQ',false);

            LWC_CreateGlobalWizard.saveAllObjects(accParams, chaParams, oppParams, quoParams, null, objectsParams);
            Test.stopTest();
        }
    }
}