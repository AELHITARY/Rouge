@isTest
private class Test_TR007_SetLastMeeting {
	static testMethod void TestTR007() {
		User uCurrentForecastUser = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null);

		// Récupération des Record Type
		RecordType accountRecordType = [Select id, Name from RecordType where sobjectType = 'Account' and isPersonType = true limit 1];
		RecordType chantierRecordType = [Select id, Name from RecordType where sobjectType = 'Chantier__c' and isActive = true limit 1];
		RecordType eventRecordType = [Select id, Name from RecordType where sobjectType = 'Event' and DeveloperName = :Constants.ACTIVITE_COMMERCIALE_RT];

		System.runAs(uCurrentForecastUser) {
			TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

			// Création enregistrement utile
			Account acc = TestCommon.createAccount(true, 'Account 1', accountRecordType.Id, 'Email', 'test@test.fr');
			Chantier__c chantier = TestCommon.createChantier('Chantier 1', chantierRecordType.Id);
			Opportunity opp = TestCommon.createOpportunity(acc.Id, chantier.Id);

			Datetime myDate = System.today().addMonths(1);
			//SEO 02/08/2013 recup personContactId sinon null
			acc = [Select PersonContactId From Account Where Id =:acc.Id];
       		Event event= new Event(WhoId = acc.PersonContactId,
       		ActivityDateTime = myDate,
       		StartDateTime = myDate,
       		Type = 'R1',
       		DurationInMinutes = 60,
       		RecordTypeId = eventRecordType.Id,
       		StatutRDV__c = 'Effectué',
       		ResultatduRDV__c = 'Devisable',
       		WhatId = opp.Id,
       		Subject = 'testobjet',
       		Couplepresent__c = 'Oui');

			Test.startTest();
       		insert event;
       		delete event;
			Test.stopTest();
		}
	}
}