//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_SharingRulesBatch
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/11/2022
//-- Version     : 1.1
//-- * 
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_SharingRulesBatch {  
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @isTest 
    static void test_Schedule_SharingRulesBatch() {
		// Récupération des profils et roles
		Profile profilCall = [SELECT id FROM Profile WHERE Name LIKE '%Call%' limit 1];

		// Création des utilisateurs
		User userCall = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', profilCall.id);
		userCall.ByPassTrigger__c = 'TR010_Account';
		update userCall;

		System.RunAs(userCall) {
			//Compte
			Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
			insert accountTest;
			// Chantier
			Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
			insert chantier;
			// Opportunity
			Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
		}

		Test.startTest();

		Schedule_SharingRulesBatch sh1 = new Schedule_SharingRulesBatch();
		sh1.JOB_EMAIL_FINISHED = true;
        String sch = '0 0 23 * * ?';
        String jobId = System.schedule('Test Schedule_SharingRulesBatch', sch, sh1);

		Test.stopTest();

		// Get the information from the CronTrigger API object
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
    }

    @isTest 
    static void test_Batch_SharingRulesBatch() {
		// Récupération des profils et roles
		Profile profilCall = [SELECT id FROM Profile WHERE Name LIKE '%Call%' limit 1];

		// Création des utilisateurs
		User userCall = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', profilCall.id);
		userCall.ByPassTrigger__c = 'TR010_Account';
		update userCall;

		System.RunAs(userCall) {
			//Compte
			Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
			insert accountTest;
			// Chantier
			Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
			insert chantier;
			// Opportunity
			Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
		}

		Test.startTest();

        BA002_OpportunitySharingRules batchOpportunity = new BA002_OpportunitySharingRules();
        Database.executeBatch(batchOpportunity, 100);

		Test.stopTest();
    }
}