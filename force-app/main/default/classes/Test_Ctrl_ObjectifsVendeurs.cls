//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_ObjectifsVendeurs
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 08/09/2014 - 14:30
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_ObjectifsVendeurs {

	public static testMethod void test_Ctrl_ObjectifsVendeursWithRV() {
		// Récupération profil RV
		Profile profilRV = [select id  from profile where Name LIKE '%RV%' limit 1];
		Profile profilVendeur = [select id  from profile where Name LIKE '%Vendeur%' limit 1];

		// Création Sectorisation
		Sectorisation__c sect = New Sectorisation__c (codeRegion__c='R123',libelleRegion__c='Région 123',
														codeMagasin__c='M123',libelleMagasin__c='Magasin 123');
		insert sect;

		//creation utilisateur RV
		String testemail = 'puser'+system.now().format('hhmmss')+'@testemail.com';
		User userTestRV = new User(profileId = profilRV.id, username = testemail, email = testemail,
								emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
								languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
								alias='cspu', lastname='lastname',ByPassValidationRule__c = false, ByPassWorkflowRule__c= true);
		insert userTestRV;

		String testemail2 = 'puser2'+system.now().format('hhmmss')+'@testemail.com';
		User userTestVendeur = new User(profileId = profilVendeur.id, username = testemail2, email = testemail2,
								emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
								languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
								alias='cspu', lastname='lastname',ByPassValidationRule__c = false, ByPassWorkflowRule__c= true);
		insert userTestVendeur;

		System.RunAs(userTestRV) {
			List<ObjectifsVendeur__c> objList = new List<ObjectifsVendeur__c>();
			Map<String, ObjectifsVendeur__c> mapObjVendeurs = new Map<String, ObjectifsVendeur__c>();
			List<String> vendeursIdList = new List<String>();
			List<Map<String,String>> arguments = new List<Map<String,String>>();

			Test.startTest();

			// Récupération des objectifs
			objList = [SELECT Id FROM ObjectifsVendeur__c];
			System.assertEquals(0, objList.size()); // Test : pas d'objectifs

			PageReference pageRef = Page.VF_ObjectifsVendeurs;
			Test.setCurrentPageReference (pageRef);
			Ctrl_ObjectifsVendeurs ctrl = new Ctrl_ObjectifsVendeurs();
			ctrl.getsemaine();
			ctrl.insertUserStats();

			// Variables pour la date
			String moisActuel = '8';
			String anneeActuelle = '2014';
			String semaineActuelle = '1';

			// Récupération des vendeurs et des objectifs
			List<User> userMagasins = Ctrl_ObjectifsVendeurs.getActiveVendeurs('M123');
			System.assertEquals(2, userMagasins.size()); // Test : 2 vendeurs dans le magasin
			for(user user : userMagasins) {
				vendeursIdList.add(user.Id);
			}

			// Création et récupération des objectifs
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.createObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			System.assertNotEquals(0, mapObjVendeurs.size()); // Test : 2 Objectifs

			// Mise à jour des objectifs
			for (String userId : vendeursIdList){
				Map<String, String> values = new Map<String, String>();
				values.put('contactActif', '1');
				values.put('contactPassif', '2');
				values.put('ventes', '3');
				values.put('caVendu', '10');
				values.put('id', userId);
				arguments.add(values);
			}
			Ctrl_ObjectifsVendeurs.updateObjectifs(anneeActuelle, moisActuel, semaineActuelle, ctrl.fiscalSettingsId, arguments);

			// Récupération des objectifs
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.getObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			System.assertNotEquals(0, mapObjVendeurs.size()); // Test : 2 Objectifs
			for (String userId : vendeursIdList){
				if(mapObjVendeurs.get(userId) != null) {
					ObjectifsVendeur__c obj = mapObjVendeurs.get(userId);
					// Récupère que les indicateurs de la semaine 1 (semaineActuelle égale 1)
					System.assertEquals(1, obj.nbContactsActifsS1__c); // Test : contactActif
					System.assertEquals(3, obj.nbVentesS1__c); // Test : ventes
					System.assertEquals(10, obj.chiffreAffaireVenduS1__c); // Test : caVendu
				}
			}

			// Création et récupération des objectifs
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.createObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			System.assertNotEquals(0, mapObjVendeurs.size()); // Test : 2 Objectifs
			// Variables pour la date
			moisActuel = '1';
			anneeActuelle = '2014';
			semaineActuelle = '3';
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.createObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			Ctrl_ObjectifsVendeurs.updateObjectifs(anneeActuelle, moisActuel, semaineActuelle, ctrl.fiscalSettingsId, arguments); // Mise à jour des objectifs

			Test.stopTest();
		}
	}

	public static testMethod void test_Ctrl_ObjectifsVendeursWithAdmin() {
		// Récupération profil RV
		Profile profilAdmin = [select id  from profile where Name LIKE '%Administrateur%' limit 1];
		Profile profilVendeur = [select id  from profile where Name LIKE '%Vendeur%' limit 1];

		// Création Sectorisation
		Sectorisation__c sect = New Sectorisation__c (codeRegion__c='R123',libelleRegion__c='Région 123',
														codeMagasin__c='M123',libelleMagasin__c='Magasin 123');
		insert sect;

		//creation utilisateur RV
		String testemail = 'puser'+system.now().format('hhmmss')+'@testemail.com';
		User userAdmin = new User(profileId = profilAdmin.id, username = testemail, email = testemail,
								emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
								languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = null,
								alias='cspu', lastname='lastname',ByPassValidationRule__c = false, ByPassWorkflowRule__c= true);
		insert userAdmin;

		String testemail2 = 'puser2'+system.now().format('hhmmss')+'@testemail.com';
		User userTestVendeur = new User(profileId = profilVendeur.id, username = testemail2, email = testemail2,
								emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
								languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
								alias='cspu', lastname='lastname',ByPassValidationRule__c = false, ByPassWorkflowRule__c= true);
		insert userTestVendeur;

		System.RunAs(userAdmin) {
			List<ObjectifsVendeur__c> objList = new List<ObjectifsVendeur__c>();
			Map<String, ObjectifsVendeur__c> mapObjVendeurs = new Map<String, ObjectifsVendeur__c>();
			List<String> vendeursIdList = new List<String>();
			List<Map<String,String>> arguments = new List<Map<String,String>>();

			Test.startTest();

			// Récupération des objectifs
			objList = [SELECT Id FROM ObjectifsVendeur__c];
			System.assertEquals(0, objList.size()); // Test : pas d'objectifs

			PageReference pageRef = Page.VF_ObjectifsVendeurs;
			Test.setCurrentPageReference (pageRef);
			Ctrl_ObjectifsVendeurs ctrl = new Ctrl_ObjectifsVendeurs();
			ctrl.getsemaine();
			ctrl.insertUserStats();

			// Variables pour la date
			String moisActuel = '6';
			String anneeActuelle = '2014';
			String semaineActuelle = '2';

			// Récupération des vendeurs et des objectifs
			List<User> userMagasins = Ctrl_ObjectifsVendeurs.getActiveVendeurs('M123');
			System.assertEquals(1, userMagasins.size()); // Test : 1 vendeur dans le magasin
			for(user user : userMagasins) {
				vendeursIdList.add(user.Id);
			}

			// Création et récupération des objectifs
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.createObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			System.assertNotEquals(0, mapObjVendeurs.size()); // Test : 1 Objectifs

			// Mise à jour des objectifs
			for (String userId : vendeursIdList){
				Map<String, String> values = new Map<String, String>();
				values.put('contactActif', '1');
				values.put('contactPassif', '2');
				values.put('ventes', '3');
				values.put('caVendu', '10');
				values.put('id', userId);
				arguments.add(values);
			}
			Ctrl_ObjectifsVendeurs.updateObjectifs(anneeActuelle, moisActuel, semaineActuelle, ctrl.fiscalSettingsId, arguments);

			// Récupération des objectifs
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.getObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			System.assertNotEquals(0, mapObjVendeurs.size()); // Test : 1 Objectifs
			for (String userId : vendeursIdList){
				if(mapObjVendeurs.get(userId) != null) {
					ObjectifsVendeur__c obj = mapObjVendeurs.get(userId);
					// Récupère que les indicateurs de la semaine 2 (semaineActuelle égale 2)
					System.assertEquals(1, obj.nbContactsActifsS2__c); // Test : contactActif
					System.assertEquals(3, obj.nbVentesS2__c); // Test : ventes
					System.assertEquals(10, obj.chiffreAffaireVenduS2__c); // Test : caVendu
				}
			}

			// Création et récupération des objectifs
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.createObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			System.assertNotEquals(0, mapObjVendeurs.size()); // Test : 1 Objectifs
			// Variables pour la date
			moisActuel = '12';
			anneeActuelle = '2014';
			semaineActuelle = '4';
			mapObjVendeurs = Ctrl_ObjectifsVendeurs.createObjectifsVendeurs(anneeActuelle, moisActuel, vendeursIdList);
			Ctrl_ObjectifsVendeurs.updateObjectifs(anneeActuelle, moisActuel, semaineActuelle, ctrl.fiscalSettingsId, arguments); // Mise à jour des objectifs

			Test.stopTest();
		}
	}
}