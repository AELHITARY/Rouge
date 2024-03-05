//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_AccountMerge
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 11/04/2017
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_AccountMerge { 

    @testSetup 
    static void setup() {
		Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Id rtB2B = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);
		Sectorisation__c defaultSectorisation = Utils_Test.createSectorisation();

        // Création des accounts
        List<Account> testAccts = new List<Account>();
        for(Integer i=0; i<=2; i++) {
            Account account = new Account(recordTypeId = rtB2C);
            account.salutation = 'M.';
            account.lastName = 'COMPTE PERSO'+i;
            account.firstName = 'Prénom'+i;
            account.accountCallSource__c = '17 - JPO';
            account.personMailingStreet = (i+7) + ' rue félix faure';
            account.personMailingPostalCode = '76320';
            account.personMailingCity = 'Saint-Pierre les Elbeuf';
            account.personMailingCountry = 'F';
            account.personHomePhone = '010203ADGJ';
            account.personMobilePhone = '060203ADGJ';
            account.personOtherPhone = '010204TEST';
            account.phone = '010204MPTW';
            account.fax = '010204MPTW';
            account.personEmail = 'test@kpark.fr'+i;
            account.AccountSource = 'CCM';
            account.PersonBirthdate = system.now().addYears(-20).date();
            account.Localisation__Latitude__s = 0;
            account.Localisation__Longitude__s = 0;
            account.iris__c = defaultSectorisation.iris__c;

            testAccts.add(account);
        }
        // Création des accounts Pro
        for(Integer i=0; i<=2; i++) {
            Account account = new Account(recordTypeId = rtB2B);
            account.Name = 'COMPTE PRO'+i;
            account.accountCallSource__c = '17 - JPO';
            account.BillingStreet = (i+7) + ' rue félix faure';
            account.BillingPostalCode = '76320';
            account.BillingCity = 'Saint-Pierre les Elbeuf';
            account.BillingCountry = 'F';
            account.phone = '010204MPTW';
            account.fax = '010204MPTW';
            account.AccountSource = 'CCM';
            account.Localisation__Latitude__s = 0;
            account.Localisation__Longitude__s = 0;
            account.iris__c = defaultSectorisation.iris__c;

            testAccts.add(account);
        }
        insert testAccts;
    }

	@isTest 
    static void test_ManualFusion_Perso() {
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+system.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);

        // Test compte personnel sans géolocalisation avec association de conjoint
        System.RunAs(user) {
            List<Account> accountList = [SELECT Id, personEmail, personHomePhone, personMobilePhone, phone, personOtherPhone, fax, parrain__c, FirstName, LastName, pays__c,
                                                Salutation, personMailingStreet, personMailingPostalCode, personMailingCity, personMailingState, personMailingCountry, RecordTypeId, conjoint__c,
                                                etage__c, codeAcces__c, complementAdresse__c, interphone__c, NPAI__c, methodeGeocodage__c,
                                                Localisation__Latitude__s, Localisation__Longitude__s, iris__c, adresseGeolocalisation__c,
                                                accountSource, accountCallSource__c
                                        FROM Account WHERE Name LIKE '%COMPTE PERSO%' LIMIT 2];
            Account account = accountList.get(0);
            Account accountDoublon = accountList.get(1);
			String doublonId=accountDoublon.Id;
			String maitreId=account.Id;

            GlobalProperties__c dqe = new GlobalProperties__c(name='dqe.dedup.compte.enabled',booleanValue__c = true, stringValue__c='MAG');
            insert dqe;

            // TEST
            Test.startTest();

            PageReference pageRef = Page.VF_AccountMerge;
			// Parametre doublon
			pageRef.getParameters().put('doublonKeyId', maitreId);
			pageRef.getParameters().put('detail', 'detail');
			pageRef.getParameters().put('doublonsId', doublonId);
			pageRef.getParameters().put('accountObject', JSON.serialize(accountDoublon));
			pageRef.getParameters().put('pAcc', 'true');
			pageRef.getParameters().put('cpt1', maitreId);

            List<String> fieldList = new List<String>{ 'complementAdresse__c','canalPrefere__c','Phone','Fax','fichiersOpposition__c','Description','typesTravaux__c', 'datePassageClient__c','NPAI__c','interetFacilitesReglements__c','mesuresGouvernementalesConnues__c','mesuresGouvernementalesUtilisees__c' };

            // Fusion manuel
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stdController = new ApexPages.standardController(account);
            Ctrl_AccountMerge ctrl = new Ctrl_AccountMerge(stdController);

            List<SelectOption> optionListTest = new List<SelectOption>();
            optionListTest = ctrl.getsalutationList();
            optionListTest = ctrl.getaccountCallSourceList();
            optionListTest = ctrl.getAccountSourceList();
            optionListTest = ctrl.getcanalPrefereList();
            optionListTest = ctrl.getfichierOpposition();
            optionListTest = ctrl.getCSPList();
            optionListTest = ctrl.getNPAIList();
            optionListTest = ctrl.getformeJuridiqueList();
            Ctrl_AccountMerge.manualMerge(new Map<String,String>{'lastName'=>'test'}, JSON.serialize(account), doublonId, maitreId, 'true', fieldList);

			// Cancel
			ctrl.typeURL='detail';
			ctrl.doublonsId=doublonId;
            ctrl.cancelMerge();
			
            Test.stopTest();
        }
    }	

	@isTest 
    static void test_ManualFusion_Pro() {
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+system.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);

        // Test compte personnel sans géolocalisation avec association de conjoint
        System.RunAs(user) {
            List<Account> accountList = [SELECT Id, personEmail, personHomePhone, personMobilePhone, phone, personOtherPhone, fax, parrain__c, FirstName, LastName, pays__c,
                                                Salutation, personMailingStreet, personMailingPostalCode, personMailingCity, personMailingState, personMailingCountry, RecordTypeId, conjoint__c,
                                                etage__c, codeAcces__c, complementAdresse__c, interphone__c, NPAI__c, methodeGeocodage__c,
                                                Localisation__Latitude__s, Localisation__Longitude__s, iris__c, adresseGeolocalisation__c,
                                                accountSource, accountCallSource__c
                                        FROM Account WHERE Name LIKE '%COMPTE PRO%' LIMIT 2];
            Account account = accountList.get(0);
            Account accountDoublon = accountList.get(1);
			String doublonId=accountDoublon.Id;
			String maitreId=account.Id;

            GlobalProperties__c dqe = new GlobalProperties__c(name='dqe.dedup.compte.enabled',booleanValue__c = true, stringValue__c='MAG');
            insert dqe;

            // TEST
            Test.startTest();

            PageReference pageRef = Page.VF_AccountMerge;
			// Parametre doublon
			pageRef.getParameters().put('doublonKeyId', maitreId);
			pageRef.getParameters().put('detail', 'edit');
			pageRef.getParameters().put('doublonsId', doublonId);
			pageRef.getParameters().put('accountObject', JSON.serialize(accountDoublon));
			pageRef.getParameters().put('pAcc', 'false');
			pageRef.getParameters().put('cpt1', maitreId);

            List<String> fieldList = new List<String>{ 'complementAdresse__c','canalPrefere__c','Phone','Fax','fichiersOpposition__c','Description','typesTravaux__c', 'datePassageClient__c','NPAI__c','interetFacilitesReglements__c','mesuresGouvernementalesConnues__c','mesuresGouvernementalesUtilisees__c' };

            // Fusion manuel
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stdController = new ApexPages.standardController(account);
            Ctrl_AccountMerge ctrl = new Ctrl_AccountMerge(stdController);
            Ctrl_AccountMerge.manualMerge(new Map<String,String>{'Name'=>'test'}, JSON.serialize(account), doublonId, maitreId, 'false', fieldList);

			// Cancel
			ctrl.typeURL='edit';
			ctrl.doublonsId=doublonId;
            ctrl.cancelMerge();
			
            Test.stopTest();
        }
    }
}