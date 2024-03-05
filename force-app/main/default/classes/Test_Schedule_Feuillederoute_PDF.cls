//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_Feuillederoute_PDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/07/2018
//-- Version     : 1.3
//-- * 1.3 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.2 : Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_Feuillederoute_PDF {

    @testSetup static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('MAG0056', 'Magasin 123', 'D123', 'Depot 123', true);
        // Création de document LOGO
        Document doc = Utils_Test.createDocument('Logo', Constants.KparK_logo_NB, true);
    }

	@isTest static void test_Schedule_Feuillederoute() {
		// Récupération profil RV et groupe
		Profile profilRV = [select id  from profile where Name = 'K/K - RV - Mobile' limit 1];
		Profile profilVendeur = [select id  from profile where Name LIKE '%Vendeur%' limit 1];

		// Récupération du rôle necessaire
		UserRole role = [SELECT id FROM UserRole WHERE Name LIKE '%- MAG -%' LIMIT 1];

		system.debug('role : '+role);

		// Création utilisateurs
		User userTestVendeur = Utils_Test.createUser(false,'testVD', 'MyTestUserNameVD@test.sfd.test', 'MyTestUserNameVD','MyTestUserNameVD', profilVendeur.Id, null);
		User userTestRV = Utils_Test.createUser(false,'testRV', 'MyTestUserNameRV@test.sfd.test', 'MyTestUserNameRV','MyTestUserNameRV', profilRV.Id, role.Id);

		// récupération du groupe spécifique
	    List<Group> userGroupList = [SELECT Id, Type, DeveloperName, RelatedId FROM Group WHERE DeveloperName = 'Utilisateurs_pilote'];

        //Ajout de l'utilisateur RV en tant que membre du groupe
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = userTestVendeur.Id;
        grpMem1.GroupId = userGroupList[0].Id;
        Insert grpMem1; 
		
		// Récupération Record Type
    	Id rtPerson = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_PERSO_RT);

		system.runAs(userTestRV){        

			// Création enregistrements utile
			Account acc = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtPerson, 'Email', true);
			Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);
			// Mise à jour localisation
			chantier.codeMagasinTechnique__c = 'MAG0056';
			chantier.Localisation__Latitude__s = 12;
			chantier.Localisation__Longitude__s = 12;
			update chantier;

			//Chantier__c test = [SELECT Id FROM Chantier__c WHERE codeMagasinTechnique__c IN :codeMagasins AND OwnerId IN :userList]
			// Création Contrats SAV, Pose et Metrage
			List<KContrat__c> contratToUpdate = new List<KContrat__c>();
			KContrat__c contratMetrage = Utils_Test.createContrat('Contrat Metrage', chantier.Id, acc.Id, '0002', false);
			contratMetrage.cartoMetrageDuJour__c = Date.today();
			contratToUpdate.add(contratMetrage);
			KContrat__c contratPose = Utils_Test.createContrat('Contrat Pose', chantier.Id, acc.Id, '0003', false);
			contratPose.cartoInstallationDuJour__c = Date.today();
			contratToUpdate.add(contratPose);
			KContrat__c contratIntSav = Utils_Test.createContrat('Contrat Int SAV', chantier.Id, acc.Id, '0004', false);
			contratIntSav.cartoInterventionSAVDuJour__c = Date.today();
			contratToUpdate.add(contratIntSav);
			insert contratToUpdate;
		}
		system.runAs(userTestRV){
			// Exécution du test
			Test.StartTest();

			Schedule_Feuillederoute_PDF schedule = new Schedule_Feuillederoute_PDF();
			String jobId = system.schedule('Test Schedule_SharingRulesBatch', '0 0 23 * * ?', schedule);
			BA_FeuillederoutePDF ba = new BA_FeuillederoutePDF();
			Id batchId = Database.executeBatch(ba);

			Test.stopTest();
		
			// Récupération des informations et vérification
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
			system.assertEquals(0, ct.TimesTriggered);
		}
	}
}