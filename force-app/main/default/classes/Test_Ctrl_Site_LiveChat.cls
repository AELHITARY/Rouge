//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Site_LiveChat
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 11/04/2017
//-- Version     : 1.0
//-- * 
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Site_LiveChat {

    static testMethod void test_LiveAgentPreChat(){
        // Création d'un utilisateur
        User user = Utils_Test.createAdminUser();

        // Test compte personnel sans géolocalisation avec association de conjoint
        System.RunAs(user) {
            
            Test.startTest();
            
            Ctrl_Site_LiveChat pcc = new Ctrl_Site_LiveChat();
            pcc.clientName = 'Test Test';
            pcc.clientFirstName = 'TEST';
            pcc.email = 'test@test.com';
            pcc.clickChat();
            
            Test.stopTest();
        }
    }
}