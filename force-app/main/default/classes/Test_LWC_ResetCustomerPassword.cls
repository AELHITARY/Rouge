//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_ResetCustomerPassword
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 01/12/2020
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_ResetCustomerPassword
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_ResetCustomerPassword {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id accProRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);

    @testSetup 
    static void setup() {        

        // Création d'un contact et des comptes
        Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
        acc.Type = 'Client';
        acc.forcageType__c = 'Client';
        insert acc;

        Contact contact = Utils_Test.createContact('Test','Test',true);
        Account acc2 = Utils_Test.createAccountPro('Test', '0123456789', accProRT, contact.Id, false) ;
        acc2.Type = 'Client';
        acc2.forcageType__c = 'Client';
        insert acc2;
    }

    @isTest
    private static void testAccount() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account LIMIT 1];

            Test.startTest();
            
            LWC_ResetCustomerPassword.resetCustomerPassword('Account', acc.Id);

            Test.stopTest();
        }
    }

    @isTest
    private static void testContact() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Contact cont = [SELECT Id FROM Contact LIMIT 1];

            Test.startTest();
            
            LWC_ResetCustomerPassword.resetCustomerPassword('Contact', cont.Id);

            Test.stopTest();
        }
    }
}