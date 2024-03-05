//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR020_SharingRulesProcess
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/11/2022
//-- Version     : 1.1
//-- * 
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR020_SharingRulesProcess {
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        Sectorisation__c defaultSectorisation = TestCommon.createSectorisation();
        insert defaultSectorisation;
    }

    @isTest
    static void test_OpportunityPublicSharing() {
        User user = TestCommon.createUser(true, 'testmlg3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', null);

        System.RunAs(user) {
            TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            // Création Account
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', ACC_PERSO_RTID, 'Email',false);

            // Création chantiers
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);   

            // Création Opportunity (Projet) Sans partage Global
			Opportunity opp = Utils_Test.createOpportunity('MyOpp1', acc, null, chantier, false);

            // Création Opportunity (Projet) Avec partage Global
			Opportunity opp2 = Utils_Test.createOpportunity('MyOpp2', acc, null, chantier, false);
            opp2.nbDevisVendusEnAttente__c = 2;

            Test.startTest();
            insert opp;
            insert opp2;
            Test.stopTest();

            // Unit Test
            opp = [SELECT Id, publicSharing__c FROM Opportunity WHERE Name = 'MyOpp1'][0];
            opp2 = [SELECT Id, publicSharing__c FROM Opportunity WHERE Name = 'MyOpp2'][0];
            System.AssertEquals(false, opp.publicSharing__c);
            //System.AssertEquals(true, opp2.publicSharing__c);
        }
    }
}