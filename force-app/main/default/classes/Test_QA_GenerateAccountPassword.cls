//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_GenerateAccountPassword
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/11/2020
//-- Version     : 1.0
//-- Description : Classe de tests de QA_GenerateAccountPassword
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_QA_GenerateAccountPassword {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {    
        // Création d'un compte
        Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
    }

    @isTest
    private static void test() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            List<Account> accList = [SELECT Id FROM Account LIMIT 1];

            Test.startTest();
            
            System.enqueueJob(new QA_GenerateAccountPassword(accList, true, true, true)); 

            Test.stopTest();
        }
    }
}