//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomLookup
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/09/2020
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CustomLookup
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CustomLookup {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id accProRT = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_PRO_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

        // Création Sectorisation
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        Sectorisation__c sect2 = Utils_Test.createSectorisation(magCode, 'Magasin Test', 'D123', 'Depot 123', true);

        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        List<Account> accList = new List<Account>();
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
        accList.add(a);
        Account c = Utils_Test.createAccountPro('Dupont Jeanne','0123456789', accProRT, contact.Id,false);
        accList.add(c);
        insert accList;   
    }

    @isTest
    private static void test() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            LWC_CustomLookup.getResults('Account', Constants.ACCOUNT_PERSO_RT, 'Name', 
                                        'Name','LastName', 'AccountNumber', 'Dupont', '', 'Name ASC');

            Test.stopTest();
        }
    }

    @isTest
    private static void testCustomFilter() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            List<LWC_CustomLookup.LookupSearchResult> result = LWC_CustomLookup.getResults('Account', Constants.ACCOUNT_PERSO_RT, 'Name', 
                                                                                        'Name','', 'AccountNumber', 'Dupont', 'email__c = \'test@test.fr\'', '');
            result[0].getId();
            result[0].getSObjectType();
            result[0].getSubtitle();
            result[0].getTitle();

            Test.stopTest();
        }
    }
}