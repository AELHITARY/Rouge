//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_ObjectifsDashboard
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 21/07/2015
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_ObjectifsDashboard {	
	private static final RecordType rtRDV    = [SELECT id FROM RecordType WHERE name = 'FRA- Activité commerciale' LIMIT 1];
	private static final RecordType rtDEVIS  = [SELECT id FROM RecordType WHERE name = 'FRA- Devis A configurer' LIMIT 1];

	@testSetup static void setup() {
		TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

		// Création Sectorisation
		Sectorisation__c sect = New Sectorisation__c (codeRegion__c='R123',libelleRegion__c='Région 123',
													codeMagasin__c='M123',libelleMagasin__c='Magasin 123');
		insert sect;
	}
	
	@isTest static void test_atteinte_objectifs() {
		// Récupération profil RV
		Profile profilRV = [select id  from profile where Name LIKE '%RV%' limit 1];
		Profile profilVendeur = [select id  from profile where Name LIKE '%Vendeur%' limit 1];

		//creation utilisateur RV
		String testemail = 'puser'+system.now().format('hhmmss')+'@testemail.com';
		User userTestRV = new User(profileId = profilRV.id, username = testemail, email = testemail,
									emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
									languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
									alias='cspu', lastname='lastname',ByPassValidationRule__c = true, ByPassWorkflowRule__c= true, Division= 'VENTE');
		insert userTestRV;

		// Récupération des recordtypes
		RecordType accRecordType = [select id , Name, sobjectType from RecordType where sobjectType = 'Account' and isPersonType = true limit 1];

		System.RunAs(userTestRV) {
			PageReference pageRef = Page.VF_ObjectifsDashboard;

			String month = String.valueOf(Date.today().month());
			String year = String.valueOf(Date.today().year());
			system.debug('month ' + month);
			system.debug('year ' + year);

			// Création d'un compte
			List<Account> acc = new List<Account>{};
			Account a = new Account(Type='Contact',LastName='Dupont', FirstName='Jean',
									RecordTypeId=accRecordType.Id,PersonMailingPostalCode='12345',
									AccountSource = 'BAL VENDEUR', accountCallSource__c = null,
									PersonMailingCity='City123',PersonMailingCountry='Country123');
			acc.add(a);

			Account b = new Account(Type='Contact',LastName='Dupont', FirstName='Jeanne',
									RecordTypeId=accRecordType.Id,PersonMailingPostalCode='12345',
									PersonMailingCity='City123',PersonMailingCountry='Country123',
									AccountSource = 'PORTE A PORTE VENDEUR', accountCallSource__c = 'test',
									optinTelephoneDomicileKparK__c = true, optinTelephoneMobileKparK__c = true);
			acc.add(b);
			insert acc;
			Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, AccountSource, accountCallSource__c, PersonContactId FROM Account WHERE ID IN :acc]);
			Account B2C1 = accountMap.get(a.id);
			Account B2C2 = accountMap.get(b.id);

			// Creation des objectifs
			ObjectifsVendeur__c obj = new ObjectifsVendeur__c(anneeObjectif__c = Integer.valueOf(year), vendeur__c = userTestRV.Id, 
															moisObjectif__c = Constants.MONTHS[Date.today().month()-1],
															nbContactsActifsS1__c = 1,
															nbVentesS1__c = 5, chiffreAffaireVenduS1__c = 30);
			insert obj;

			// Création données
			Chantier__c chantier = createChantier(B2C1, null, null, null, null, null);
			insert chantier;
			chantier = ((List<Chantier__c>) SchemaUtils.executeQuery('Chantier__c', chantier.id))[0];
			Opportunity projet = createOpportunity(B2C1, B2C2, chantier);
			insert projet;

			Event eventR1 = createEvent(projet, B2C1);
			insert eventR1;
			Event eventR2 = createEvent(projet, B2C1);
			eventR2.Type = 'R2';
			insert eventR2;
			Event event1 = createEvent(projet, B2C1);
			event1.Type = 'Prospection physique';
			event1.nbBAL50__c = 2;
			event1.NbTAP51__c = 3;
			insert event1;
			Event event2 = createEvent(projet, B2C1);
			event2.Type = 'Phone';
			event2.NbPhone55__c = 2;
			insert event2;
			Event event3 = createEvent(projet, B2C1);
			event3.Type = 'Stand/Galerie Marchande';
			insert event3;
			Event event4 = createEvent(projet, B2C1);
			event4.Type = 'Foire';
			insert event4;
			Event event5 = createEvent(projet, B2C1);
			event5.Type = 'Stand/Marché';
			insert event5;

			Quote quote = createQuote(projet);
			quote.forcageEtat__c = 'Vendu en attente d\'enregistrement';
			quote.Status = 'Vendu en attente d\'enregistrement';
			quote.Total_TTC_devis__c = 3;
			quote.RemisevendeurglobaleDevise__c = 3;
			quote.dateAcceptationClient__c = Date.today();
            quote.source__c = 'BAL VENDEUR';
			insert quote;

			// TEST
			Test.startTest();
			Test.setCurrentPage(pageRef);
			Ctrl_ObjectifsDashboard ctrl = new Ctrl_ObjectifsDashboard();

			List<SelectOption> semaineOptions = ctrl.getsemaine();
			List<SelectOption> moisOptions = ctrl.mois;
			ctrl.insertUserStats();

			system.debug('ctrl.anneeActuelle ' + ctrl.anneeActuelle);
			system.debug('ctrl.moisActuel ' + ctrl.moisActuel);
			system.debug('ctrl.semaineActuelle ' + ctrl.semaineActuelle);
			String semaine = '1';
			ctrl.codeMagasinActuel='M123';

			List<String> vendeursIdList = new List<String>();
			vendeursIdList.add(userTestRV.Id);
			
			Ctrl_ObjectifsDashboard.getObjectifsMensuel(year, month, vendeursIdList);
			Ctrl_ObjectifsDashboard.getObjectifsVendeursHebdomadaire(year, month, semaine, ctrl.periodId, vendeursIdList);
			Ctrl_ObjectifsDashboard.getObjectifsVendeursMensuel(year, month, ctrl.fiscalSettingsId, vendeursIdList);

			semaine = '4';
			Ctrl_ObjectifsDashboard.getObjectifsMensuel(year, month, vendeursIdList);
			Ctrl_ObjectifsDashboard.getObjectifsVendeursMensuel(year, month, ctrl.fiscalSettingsId, vendeursIdList);
			Ctrl_ObjectifsDashboard.getObjectifsVendeursHebdomadaire(year, month, semaine, ctrl.periodId, vendeursIdList);

			semaine = '5';
			Ctrl_ObjectifsDashboard.getObjectifsVendeursHebdomadaire(year, month, semaine, ctrl.periodId, vendeursIdList);
			Test.stopTest();
		}
	}

	private static Chantier__c createChantier(Account proprietaire, Account autreProprietaire, Account locataire, Account autreLocataire, Account occupant, Account autreOccupant) {
		Chantier__c chantier = new Chantier__c();
		chantier.name = 'CHA - Test';
		chantier.rue__c = '1200 rue félix faure';
		chantier.codePostal__c = '76320';
		chantier.ville__c = 'Saint-Pierre les Elbeuf';
		chantier.pays__c = 'F';
		chantier.anneeConstruction__c = '2000';
		chantier.typeHabitation__c = 'Pavillon';
		chantier.typeResidence__c = 'Principale';
		if (proprietaire != null)
			chantier.proprietaire__c = proprietaire.id;
		if (autreProprietaire != null)
			chantier.autreProprietaire__c = autreProprietaire.id;
		if (locataire != null)
			chantier.locataire__c = locataire.id;
		if (autreLocataire != null)
			chantier.autreLocataire__c = autreLocataire.id;
		if (occupant != null)
			chantier.occupant__c = occupant.id;
		if (autreOccupant != null)
			chantier.autreOccupant__c = autreOccupant.id;
		chantier.x__c = 0;
		chantier.y__c = 0;
		chantier.Localisation__Latitude__s = 0;
		chantier.Localisation__Longitude__s = 0;
		chantier.iris__c = 'test';
		return chantier;
	}

	private static Opportunity createOpportunity(Account demandeur, Account autreDemandeur, Chantier__c chantier) {
		Opportunity opportunity = new Opportunity();
		opportunity.name = 'PRJ - Test';
		opportunity.accountId = demandeur.id;
		if (autreDemandeur != null)
			opportunity.autreCompte__c = autreDemandeur.id;
		opportunity.chantier__c = chantier.id;
		opportunity.type = 'Nouveau';
		opportunity.StageName = 'Analyse';
		opportunity.leadSource = demandeur.accountSource != null ? demandeur.accountSource : ((autreDemandeur != null && autreDemandeur.accountSource != null) ? autreDemandeur.accountSource : 'JPO');
		opportunity.callSource__c = demandeur.accountSource != null ? demandeur.accountCallSource__c : ((autreDemandeur != null && autreDemandeur.accountSource != null) ? autreDemandeur.accountCallSource__c : null);
		opportunity.closeDate = System.today() + 10;
		opportunity.probability = 10;
		return opportunity;
	}

	private static Event createEvent(Opportunity opportunity, Account demandeur) {
		Event event = new Event(recordTypeId = rtRDV.id);
		event.type = 'R1';
		event.activityDate = System.today();
		event.startDateTime = System.now();
		event.endDateTime = System.now();
		event.whatId = opportunity.id;
		event.whoId = demandeur.personContactId;
		event.couplePresent__c = 'Oui';
		event.decisionnaire__c = true;
		event.statutRDV__c = 'Effectué';
		event.resultatDuRDV__c = 'Devisable';
		return event;
	}

	private static Quote createQuote(Opportunity opportunity) {
		Quote quote = new Quote(recordTypeId = rtDEVIS.id);

		Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book', Description = 'Price Book Products', IsActive = true);
		insert pb;

		//Id pricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

		quote.OpportunityId = opportunity.Id;
		quote.Pricebook2Id = pb.Id;
		quote.Name = 'MyQuote';
		quote.compte__c = opportunity.accountId;
		quote.C2E__c = 'Oui';
		quote.moyenTransmissionClient__c = 'Par email';
		quote.autreCompte__c = opportunity.autreCompte__c;
		quote.modeFinancement__c = 'PAIEMENT COMPTANT';

		return quote;
	}
}