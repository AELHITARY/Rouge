//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_AlreadyUse
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_AlreadyUse {
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @isTest
    private static void test() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        Account account = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);

        Test.startTest();

        System.assertEquals(false, alreadyUsed.isUsed('Test_AlreadyUse', user.id));
        System.assertEquals(true,  alreadyUsed.isUsed('Test_AlreadyUse', user.id));
        System.assertEquals(true,  alreadyUsed.isUsed2('Test_AlreadyUse', user.id));

        System.assertEquals(false, alreadyUsed.isUsed('Test_AlreadyUse', account.id));
        System.assertEquals(true,  alreadyUsed.isUsed('Test_AlreadyUse', account.id));
        System.assertEquals(true,  alreadyUsed.isUsed2('Test_AlreadyUse', account.id));

        Test.stopTest();
    }
}