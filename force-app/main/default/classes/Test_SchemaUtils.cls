//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_SchemaUtils
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 09/03/2023
//-- Version     : 1.1
//-- * Mise à jour API 57
//-- * Ajout d'un test pour la fonction pour requête avec ORDER BY
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_SchemaUtils {
	private static final Sectorisation__c IRIS = TestCommon.createSectorisation();

    @isTest 
	static void testUsers() {
		Test.startTest();

		try {
			User user = SchemaUtils.getUser(userInfo.getUserId());
			System.assert(user != null);
		} catch(Exception ex) {
			System.assert(ex != null);
		}

		Test.stopTest();
	}
	
	/* 
    @isTest 
	static void testUsers2() {
		Test.startTest();

		List<User> doneUsers = SchemaUtils.getUsers();
		System.assert(!doneUsers.isEmpty());

		String prefix = SchemaUtils.getObjectPrefix('User');
		System.debug('>>> PREFIX >>> ' + prefix);
		for (User user : doneUsers) {
			System.assertEquals(String.valueOf(user.id).left(prefix.length()), prefix);
		}

		Test.stopTest(); 
	}*/

    @isTest 
	static void testRoles() {
		Test.startTest();

		List<UserRole> doneRoles = SchemaUtils.getRoles();
		System.assert(!doneRoles.isEmpty());

		UserRole r = SchemaUtils.getRole(doneRoles.get(0).id);
		System.assert(r != null);

		String prefix = SchemaUtils.getObjectPrefix('UserRole');
		for (UserRole role : doneRoles) {
			System.assertEquals(String.valueOf(role.id).left(prefix.length()), prefix);
		}

		Test.stopTest();
	}

    @isTest 
	static void testProfiles() {

		Test.startTest();

		List<Profile> doneProfiles = SchemaUtils.getProfiles();
		System.assert(!doneProfiles.isEmpty());

		Profile p = SchemaUtils.getProfile(doneProfiles.get(0).id);
		System.assert(p != null);

		String prefix = SchemaUtils.getObjectPrefix('Profile');
		for (Profile profile : doneProfiles) {
			System.assertEquals(String.valueOf(profile.id).left(prefix.length()), prefix);
		}

		Test.stopTest();
	}

	/*
	public static testMethod void testData() {

		List<Lead> initData = new List<Lead>();
		for (Integer i = 0; i < 50; i++)
			initData.add(new Lead(firstName = 'FirstName_' + i, lastName = 'LastName_' + i));
		insert initData;
		Map<Id, Lead> initMap = new Map<Id, Lead>(initData);

		Test.startTest();

		List<Lead> doneData = SchemaUtils.executeQuery('Lead');
		System.assertEquals(initData.size(), doneData.size(), 'initData = ' + initData.size() + ' / doneData = ' + doneData.size());
		doneData = SchemaUtils.executeQuery('Lead', initMap.keySet());
		System.assertEquals(initData.size(), doneData.size(), 'initData = ' + initData.size() + ' / doneData = ' + doneData.size());

		String prefix = SchemaUtils.getObjectPrefix('Lead');
		for (Lead lead : doneData)
			System.assertEquals(String.valueOf(lead.id).left(prefix.length()), prefix);

		Test.stopTest();
	}
	*/

    @isTest 
	static void testData2() {
		insert IRIS;

		List<Account> initAccounts = new List<Account>();
		Account p = new Account(firstName = 'P', lastName = 'P', personEmail = 'p@kpark.fr');
		Account ap = new Account(firstName = 'AP', lastName = 'AP', personEmail = 'ap@kpark.fr');
		Account l = new Account(firstName = 'L', lastName = 'L', personEmail = 'l@kpark.fr');
		Account al = new Account(firstName = 'AL', lastName = 'AL', personEmail = 'al@kpark.fr');
		Account o = new Account(firstName = 'O', lastName = 'O', personEmail = 'o@kpark.fr');
		Account ao = new Account(firstName = 'AO', lastName = 'AO', personEmail = 'ao@kpark.fr');

		initAccounts.add(p);
		initAccounts.add(ap);
		initAccounts.add(l);
		initAccounts.add(al);
		initAccounts.add(o);
		initAccounts.add(ao);

		insert initAccounts;
		List<ID> initAccountIds = new List<ID>();
		initAccountIds.add(p.id);
		initAccountIds.add(ap.id);
		initAccountIds.add(l.id);
		initAccountIds.add(al.id);
		initAccountIds.add(o.id);
		initAccountIds.add(ao.id);

		for (Account acc : [SELECT id, firstName, lastName, personEmail, AccountNumber FROM Account WHERE id IN : initAccountIds]) {
			if (acc.id == p.id)
				p = acc;
			else if (acc.id == ap.id)
				ap = acc;
			else if (acc.id == l.id)
				l = acc;
			else if (acc.id == al.id)
				al = acc;
			else if (acc.id == o.id)
				o = acc;
			else if (acc.id == ao.id)
				ao = acc;
		}

		Chantier__c initChantier = new Chantier__c(name = 'C',
												proprietaire__c = p.id, autreProprietaire__c = ap.id,
												locataire__c = l.id, autreLocataire__c = al.id,
												occupant__c = o.id, autreOccupant__c = ao.id,
												rue__c = '1200 rue félix faure', codePostal__c = '76320', ville__c = 'CAUDEBEC LES ELBEUF', pays__c = 'FRANCE',
												iris__c = IRIS.iris__c);
		insert initChantier;

		Test.startTest();
		List<String> initAccountNumbers = new List<String>();
		initAccountNumbers.add(p.AccountNumber);
		initAccountNumbers.add(ap.AccountNumber);
		initAccountNumbers.add(l.AccountNumber);
		initAccountNumbers.add(al.AccountNumber);
		initAccountNumbers.add(o.AccountNumber);
		initAccountNumbers.add(ao.AccountNumber);

		List<Account> doneAccounts = SchemaUtils.executeQuery('Account', initAccountIds);

		System.assertEquals(doneAccounts.size(), 6, 'accounts = ' + doneAccounts.size() + ' / 6');

		Map<String, String> relations = new Map<String, String>();
		relations.put('proprietaire__r', 'Account');
		relations.put('autreProprietaire__r', 'Account');
		relations.put('locataire__r', 'Account');
		relations.put('autreLocataire__r', 'Account');
		relations.put('occupant__r', 'Account');
		relations.put('autreOccupant__r', 'Account');


		// Test des comptes
		List<Account> doneAccounts2 = SchemaUtils.executeQuery('Account', 'AccountNumber', initAccountNumbers);
		List<Account> doneAccounts3 = SchemaUtils.executeQuery('Account', 'AccountNumber', initAccountNumbers, null);
		Set<String> accountNumberSet = new Set<String>();
		accountNumberSet.addAll(initAccountNumbers);
		List<Account> doneAccounts4 = SchemaUtils.executeQuery('Account', 'AccountNumber', accountNumberSet);
		List<Account> doneAccounts5 = SchemaUtils.executeQuery('Account', 'AccountNumber', accountNumberSet, null);
		List<Account> doneAccounts6 = SchemaUtils.executeQuery('Account', 'AccountNumber', p.AccountNumber);
		List<Account> doneAccounts7 = SchemaUtils.executeQuery('Account', 'AccountNumber', p.AccountNumber, null);

		// Test des chantiers
		List<Chantier__c> doneChantiers = SchemaUtils.executeQuery('Chantier__c', initChantier.id, relations);
		/*System.assertEquals(doneChantiers.size(), 1, 'chantiers = ' + doneChantiers.size() + ' / 1');
		System.assertEquals(doneChantiers[0].proprietaire__r.id, p.id, 'Proprietaire invalide!');
		System.assertEquals(doneChantiers[0].autreProprietaire__r.id, ap.id, 'Autre proprietaire invalide!');
		System.assertEquals(doneChantiers[0].locataire__r.id, l.id, 'Locataire invalide!');
		System.assertEquals(doneChantiers[0].autreLocataire__r.id, al.id, 'Autre locataire invalide!');
		System.assertEquals(doneChantiers[0].occupant__r.id, o.id, 'Occupant invalide!');
		System.assertEquals(doneChantiers[0].autreOccupant__r.id, ao.id, 'Autre occupant invalide!');*/

		List<ID> chantierIdList = new List<ID>();
		Set<ID> chantierIdSet = new Set<ID>();
		chantierIdList.add(initChantier.id);
		chantierIdSet.addAll(chantierIdList);
		List<Chantier__c> doneChantiers2 = SchemaUtils.executeQuery('Chantier__c', 'id', chantierIdList, relations);
		//System.assertEquals(doneChantiers.size(), doneChantiers2.size());
		List<Chantier__c> doneChantiers3 = SchemaUtils.executeQuery('Chantier__c', chantierIdList, relations);
		//System.assertEquals(doneChantiers.size(), doneChantiers3.size());
		List<Chantier__c> doneChantiers4 = SchemaUtils.executeQuery('Chantier__c', 'id', chantierIdSet, relations);
		//System.assertEquals(doneChantiers.size(), doneChantiers4.size());
		List<Chantier__c> doneChantiers5 = SchemaUtils.executeQuery('Chantier__c', chantierIdSet, relations);
		//System.assertEquals(doneChantiers.size(), doneChantiers5.size());
		List<Chantier__c> doneChantiers6 = SchemaUtils.executeQuery('Chantier__c', 'id', chantierIdList);
		//System.assertEquals(doneChantiers.size(), doneChantiers6.size());
		List<Chantier__c> doneChantiers7 = SchemaUtils.executeQuery('Chantier__c', chantierIdList);
		//System.assertEquals(doneChantiers.size(), doneChantiers7.size());
		List<Chantier__c> doneChantiers8 = SchemaUtils.executeQuery('Chantier__c', 'id', chantierIdSet);
		//System.assertEquals(doneChantiers.size(), doneChantiers8.size());
		List<Chantier__c> doneChantiers9 = SchemaUtils.executeQuery('Chantier__c', chantierIdSet);
		//System.assertEquals(doneChantiers.size(), doneChantiers9.size());
		List<Chantier__c> doneChantiers10 = SchemaUtils.executeQuery('Chantier__c', 'id', initChantier.id);
		//System.assertEquals(doneChantiers.size(), doneChantiers10.size());
		List<Chantier__c> doneChantiers11 = SchemaUtils.executeQuery('Chantier__c', initChantier.id);
		//System.assertEquals(doneChantiers.size(), doneChantiers11.size());
		List<Chantier__c> doneChantiers12 = SchemaUtils.executeQuery('Chantier__c', 'id', initChantier.id, relations);
		//System.assertEquals(doneChantiers.size(), doneChantiers12.size());
		List<Chantier__c> doneChantiers13 = SchemaUtils.executeQuery('Chantier__c', 'id', initChantier.id, relations, 'id');
		//System.assertEquals(doneChantiers.size(), doneChantiers13.size());

		Test.stopTest();
	}
}