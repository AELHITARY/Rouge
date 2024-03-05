//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Pages_Triptyque
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/01/2021
//-- Version     : 1.0
//-- Description : Classe de tests des pages Triptyque et Triptyque_Analytique
//-- * 1.0 : CRM-228, Fusion avec Test_Pages_Triptyque et Test_Ctrl_Triptyque_Analytique
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Pages_Triptyque {
    private static final Id rtPersonAcc = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id rtDEVIS = DAL.getRecordTypeIdByDevName('Quote', 'FRA- Devis A configurer');
    
    @testSetup 
    static void setup() {
        // Récupération Role
        String codeMagasin = 'M123';
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('usercontext.cache.enabled', false);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation(codeMagasin, codeMagasin, codeMagasin, codeMagasin,false);
        sect.codeRegion__c='R123';
        sect.libelleRegion__c='Région 123';
        insert sect;
        // Création de document LOGO
        Document doc = Utils_Test.createDocument('Logo', Constants.KparK_logo_NB, true);
    }

	@isTest 
	static void triptyque() {
		// Récupération profil RV
		Profile profilRV = [select id  from profile where Name LIKE '%RV%' limit 1];
		Profile profilVendeur = [select id  from profile where Name LIKE '%Vendeur%' limit 1];

		//creation utilisateur RV
		String testemail = 'puser'+System.now().format('hhmmss')+'@testemail.com';
		User userTestRV = new User(profileId = profilRV.id, username = testemail, email = testemail,
									emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
									languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
									alias='cspu', lastname='lastname',ByPassValidationRule__c = true, ByPassWorkflowRule__c= true, Division= 'VENTE');
		insert userTestRV;

		String testemail2 = 'puser2'+System.now().format('hhmmss')+'@testemail.com';
		User userTestVendeur = new User(profileId = profilVendeur.id, username = testemail2, email = testemail2,
										emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
										languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
										alias='cspu', lastname='lastname',ByPassValidationRule__c = true, ByPassWorkflowRule__c= true, Division= 'VENTE');
		insert userTestVendeur;

		System.RunAs(userTestRV) {
			PageReference pageRef = Page.VF_Triptyque;

			String month = String.valueOf(Date.today().month());
			String year = String.valueOf(Date.today().year());
			System.debug('month ' + month);
			System.debug('year ' + year);

			// Création d'un compte
			List<Account> acc = new List<Account>{};
			Account a = new Account(Type='Contact',LastName='Dupont', FirstName='Jean',
									RecordTypeId=rtPersonAcc,PersonMailingPostalCode='12345',
									AccountSource = 'BAL VENDEUR', accountCallSource__c = null,
									PersonMailingCity='City123',PersonMailingCountry='Country123');
			acc.add(a);

			Account b = new Account(Type='Contact',LastName='Dupont', FirstName='Jeanne',
									RecordTypeId=rtPersonAcc,PersonMailingPostalCode='12345',
									PersonMailingCity='City123',PersonMailingCountry='Country123',
									AccountSource = 'PORTE A PORTE VENDEUR', accountCallSource__c = 'test',
									optinTelephoneDomicileKparK__c = true, optinTelephoneMobileKparK__c = true);
			acc.add(b);
			insert acc;
			Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, AccountSource, accountCallSource__c, PersonContactId FROM Account WHERE ID IN :acc]);
			Account B2C1 = accountMap.get(a.id);
			Account B2C2 = accountMap.get(b.id);

			// Creation des objectifs
			ObjectifsVendeur__c obj = new ObjectifsVendeur__c(anneeObjectif__c = Integer.valueOf(year), vendeur__c = userTestRV.Id, moisObjectif__c = Constants.MONTHS[Date.today().month()-1],
															nbContactsActifsS1__c = 1,
															nbVentesS1__c = 5, chiffreAffaireVenduS1__c = 30);
			insert obj;

			// Création données
			Chantier__c chantier = createChantier(B2C1);
			insert chantier;
			chantier = ((List<Chantier__c>) SchemaUtils.executeQuery('Chantier__c', chantier.id))[0];
			Opportunity projet = createOpportunity(B2C1, B2C2, chantier);
			insert projet;

			Event eventR1 = createEvent(projet, B2C1);
			insert eventR1;
			Event eventR2 = createEvent(projet, B2C1);
			eventR2.Type = 'R2';
			insert eventR2;

			List<Event> evtList = new List<Event>();
			Event event1 = createEvent(projet, B2C1);
			event1.Type = 'Prospection physique';
			event1.nbBAL50__c = 2;
			event1.NbTAP51__c = 3;
			evtList.add(event1);
			Event event2 = createEvent(projet, B2C1);
			event2.Type = 'Phone';
			event2.NbPhone55__c = 2;
			evtList.add(event2);
			Event event3 = createEvent(projet, B2C1);
			event3.Type = 'Stand/Galerie Marchande';
			evtList.add(event3);
			Event event4 = createEvent(projet, B2C1);
			event4.Type = 'Foire';
			evtList.add(event4);
			Event event5 = createEvent(projet, B2C1);
			event5.Type = 'Stand/Marché';
			evtList.add(event5);
			insert evtList;

			Test.startTest();

			Quote quote = createQuote(projet);
			quote.forcageEtat__c = 'Vendu en attente d\'enregistrement';
			quote.Status = 'Vendu en attente d\'enregistrement';
			quote.Total_TTC_devis__c = 3;
			quote.RemisevendeurglobaleDevise__c = 3;
			quote.dateAcceptationClient__c = Date.today();
			insert quote;

			// TEST
			Test.setCurrentPage(pageRef);
			Ctrl_Triptyque ctrl = new Ctrl_Triptyque();

			List<SelectOption> semaineOptions = ctrl.getsemaine();
			List<SelectOption> moisOptions = ctrl.mois;
			ctrl.insertUserStats();

			String semaine = '1';
			ctrl.codeMagasinActuel='M123';

			List<String> vendeursIdList = new List<String>();
			List<String> vendeurUserId = new List<String>();

			vendeursIdList.add(userTestRV.Id);
			vendeurUserId.add(userTestRV.Id);
			Ctrl_Triptyque.getObjectifsVendeursMensuel(year, month, vendeursIdList);
			Ctrl_Triptyque.getObjectifsVendeurs(year, month, semaine, ctrl.periodId, vendeurUserId);

			Ctrl_Triptyque.getMensuelData(month, year, ctrl.fiscalSettingsId, ctrl.periodId, vendeursIdList);
			Ctrl_Triptyque.getHebdomadaireData(semaine, month, year, ctrl.periodId, vendeursIdList);

			ctrl.vendeursList.add(userTestRV);
			semaine = '4';
			//Ctrl_Triptyque.getHebdomadaireData(semaine, month, year, ctrl.periodId, vendeursIdList);
			Ctrl_Triptyque.getObjectifsVendeursMensuel(year, month, vendeursIdList);
			Ctrl_Triptyque.getMensuelData(month, year, ctrl.fiscalSettingsId, ctrl.periodId, vendeursIdList);

			semaine = '5';
			Ctrl_Triptyque.getHebdomadaireData(semaine, month, year, ctrl.periodId, vendeursIdList);
			// Indicateur
			Ctrl_Triptyque.getNumberRDVInfo(vendeursIdList, 'M123');
			ctrl.triptyqueAnalytique();
			ctrl.objVendeurs();
			Test.stopTest();
		}
	}

    @isTest 
    static void triptyque_exportPDF() {
		// Récupération profil RV
		Profile profilRV = [select id  from profile where Name LIKE '%RV%' limit 1];
		Profile profilVendeur = [select id  from profile where Name LIKE '%Vendeur%' limit 1];

		//creation utilisateur RV
		String testemail = 'puser'+System.now().format('hhmmss')+'@testemail.com';
		User userTestRV = new User(profileId = profilRV.id, username = testemail, email = testemail,
									emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
									languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
									alias='cspu', lastname='lastname',ByPassValidationRule__c = true, ByPassWorkflowRule__c= true, Division= 'VENTE');
		insert userTestRV;

		String testemail2 = 'puser2'+System.now().format('hhmmss')+'@testemail.com';
		User userTestVendeur = new User(profileId = profilVendeur.id, username = testemail2, email = testemail2,
										emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
										languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
										alias='cspu', lastname='lastname',ByPassValidationRule__c = true, ByPassWorkflowRule__c= true, Division= 'VENTE');
		insert userTestVendeur;

		System.RunAs(userTestRV) {
			PageReference pageRef = Page.VF_Triptyque;

			String month = String.valueOf(Date.today().month());
			String year = String.valueOf(Date.today().year());
			System.debug('month ' + month);
			System.debug('year ' + year);

			// Création d'un compte
			List<Account> acc = new List<Account>{};
			Account a = new Account(Type='Contact',LastName='Dupont', FirstName='Jean',
									RecordTypeId=rtPersonAcc,PersonMailingPostalCode='12345',
									AccountSource = 'BAL VENDEUR', accountCallSource__c = null,
									PersonMailingCity='City123',PersonMailingCountry='Country123');
			acc.add(a);

			Account b = new Account(Type='Contact',LastName='Dupont', FirstName='Jeanne',
									RecordTypeId=rtPersonAcc,PersonMailingPostalCode='12345',
									PersonMailingCity='City123',PersonMailingCountry='Country123',
									AccountSource = 'PORTE A PORTE VENDEUR', accountCallSource__c = 'test',
									optinTelephoneDomicileKparK__c = true, optinTelephoneMobileKparK__c = true);
			acc.add(b);
			insert acc;
			Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, AccountSource, accountCallSource__c, PersonContactId FROM Account WHERE ID IN :acc]);
			Account B2C1 = accountMap.get(a.id);
			Account B2C2 = accountMap.get(b.id);

			// Creation des objectifs
			ObjectifsVendeur__c obj = new ObjectifsVendeur__c(anneeObjectif__c = Integer.valueOf(year), vendeur__c = userTestRV.Id, moisObjectif__c = Constants.MONTHS[Date.today().month()-1],
															nbContactsActifsS1__c = 1,
															nbVentesS1__c = 5, chiffreAffaireVenduS1__c = 30);
			insert obj;

			// Création données
			Chantier__c chantier = createChantier(B2C1);
			insert chantier;
			chantier = ((List<Chantier__c>) SchemaUtils.executeQuery('Chantier__c', chantier.id))[0];
			Opportunity projet = createOpportunity(B2C1, B2C2, chantier);
			insert projet;

			Event eventR1 = createEvent(projet, B2C1);
			insert eventR1;
			Event eventR2 = createEvent(projet, B2C1);
			eventR2.Type = 'R2';
			insert eventR2;

			List<Event> evtList = new List<Event>();
			Event event1 = createEvent(projet, B2C1);
			event1.Type = 'Prospection physique';
			event1.nbBAL50__c = 2;
			event1.NbTAP51__c = 3;
			evtList.add(event1);
			Event event2 = createEvent(projet, B2C1);
			event2.Type = 'Phone';
			event2.NbPhone55__c = 2;
			evtList.add(event2);
			Event event3 = createEvent(projet, B2C1);
			event3.Type = 'Stand/Galerie Marchande';
			evtList.add(event3);
			Event event4 = createEvent(projet, B2C1);
			event4.Type = 'Foire';
			evtList.add(event4);
			Event event5 = createEvent(projet, B2C1);
			event5.Type = 'Stand/Marché';
			evtList.add(event5);
			insert evtList;

			Quote quote = createQuote(projet);
			quote.forcageEtat__c = 'Vendu en attente d\'enregistrement';
			quote.Status = 'Vendu en attente d\'enregistrement';
			quote.Total_TTC_devis__c = 3;
			quote.RemisevendeurglobaleDevise__c = 3;
			quote.dateAcceptationClient__c = Date.today();
			insert quote;

			// TEST
			Test.startTest();
			Test.setCurrentPage(pageRef);
			Ctrl_Triptyque ctrl = new Ctrl_Triptyque();

			List<SelectOption> semaineOptions = ctrl.getsemaine();
			List<SelectOption> moisOptions = ctrl.mois;
			String semaine = '1';
			ctrl.codeMagasinActuel='M123';

			List<String> vendeursIdList = new List<String>();
			List<String> vendeurUserId = new List<String>();

			vendeursIdList.add(userTestRV.Id);
			vendeurUserId.add(userTestRV.Id);
			ctrl.vendeursList.add(userTestRV);
			semaine = '5';
			// Export PDF
			Id logoId = ctrl.getLogoKparKId();
			ctrl.formatValeursExport();
			ctrl.exportPDF();

			Test.stopTest();
		}
	}
	
	@isTest 
	static void triptyque_analytique() {
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

        String testemail2 = 'puser2'+system.now().format('hhmmss')+'@testemail.com';
        User userTestVendeur = new User(profileId = profilVendeur.id, username = testemail2, email = testemail2,
                                        emailencodingkey = 'ISO-8859-1', localesidkey = 'fr_FR',
                                        languagelocalekey = 'fr', timezonesidkey = 'Europe/Paris', CodeMagasin__c = 'M123',
                                        alias='cspu', lastname='lastname',ByPassValidationRule__c = true, ByPassWorkflowRule__c= true, Division= 'VENTE');
        insert userTestVendeur;

        System.RunAs(userTestRV) {
            PageReference pageRef = Page.VF_Triptyque_Analytique;

            String month = String.valueOf(Date.today().month());
            String year = String.valueOf(Date.today().year());
            system.debug('month ' + month);
            system.debug('year ' + year);

            // Création d'un compte
            List<Account> acc = new List<Account>{};
            Account a = new Account(Type='Contact',LastName='Dupont', FirstName='Jean',
                                    RecordTypeId=rtPersonAcc,PersonMailingPostalCode='12345',
                                    AccountSource = 'BAL VENDEUR', accountCallSource__c = null,
                                    PersonMailingCity='City123',PersonMailingCountry='Country123');
            acc.add(a);

            Account b = new Account(Type='Contact',LastName='Dupont', FirstName='Jeanne',
                                    RecordTypeId=rtPersonAcc,PersonMailingPostalCode='12345',
                                    PersonMailingCity='City123',PersonMailingCountry='Country123',
                                    AccountSource = 'PORTE A PORTE VENDEUR', accountCallSource__c = 'test',
                                    optinTelephoneDomicileKparK__c = true, optinTelephoneMobileKparK__c = true);
            acc.add(b);
            insert acc;
            Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, AccountSource, accountCallSource__c, PersonContactId FROM Account WHERE ID IN :acc]);
            Account B2C1 = accountMap.get(a.id);
            Account B2C2 = accountMap.get(b.id);

            // Creation des objectifs
            ObjectifsVendeur__c obj = new ObjectifsVendeur__c(anneeObjectif__c = Integer.valueOf(year), vendeur__c = userTestRV.Id, moisObjectif__c = Constants.MONTHS[Date.today().month()-1],
                                                            nbContactsActifsS1__c = 1,
                                                            nbVentesS1__c = 5, chiffreAffaireVenduS1__c = 30);
            insert obj;

            // Création données
            Chantier__c chantier = createChantier(B2C1);
            insert chantier;
            chantier = ((List<Chantier__c>) SchemaUtils.executeQuery('Chantier__c', chantier.id))[0];
            Opportunity projet = createOpportunity(B2C1, B2C2, chantier);
            insert projet;

            Event eventR1 = createEvent(projet, B2C1);
            insert eventR1;
            Event eventR2 = createEvent(projet, B2C1);
            eventR2.Type = 'R2';
            insert eventR2;			
			
			List<Event> evtList = new List<Event>();
			Event event1 = createEvent(projet, B2C1);
			event1.Type = 'Prospection physique';
			event1.nbBAL50__c = 2;
			event1.NbTAP51__c = 3;
			evtList.add(event1);
			Event event2 = createEvent(projet, B2C1);
			event2.Type = 'Phone';
			event2.NbPhone55__c = 2;
			evtList.add(event2);
			Event event3 = createEvent(projet, B2C1);
			event3.Type = 'Stand/Galerie Marchande';
			evtList.add(event3);
			Event event4 = createEvent(projet, B2C1);
			event4.Type = 'Foire';
			evtList.add(event4);
			Event event5 = createEvent(projet, B2C1);
			event5.Type = 'Stand/Marché';
			evtList.add(event5);
			insert evtList;

            Quote quote = createQuote(projet);
            quote.forcageEtat__c = 'Vendu en attente d\'enregistrement';
            quote.Status = 'Vendu en attente d\'enregistrement';
            quote.Total_TTC_devis__c = 3;
            quote.RemisevendeurglobaleDevise__c = 3;
            quote.dateAcceptationClient__c = Date.today();
            insert quote;

            // TEST
            Test.startTest();
            Test.setCurrentPage(pageRef);
            Ctrl_Triptyque_Analytique ctrl = new Ctrl_Triptyque_Analytique();

            String deb = ctrl.dateDebut;
            String fin = ctrl.dateFin;
            ctrl.insertUserStats();

            ctrl.codeMagasinActuel='M123';

            List<String> vendeursIdList = new List<String>();
            List<String> vendeurUserId = new List<String>();

            vendeursIdList.add(userTestRV.Id);
            vendeurUserId.add(userTestRV.Id);

            Ctrl_Triptyque_Analytique.getHebdomadaireData(deb, fin, vendeursIdList);

            deb = '01/01/2000';
            fin = '01/01/2016';
            Ctrl_Triptyque_Analytique.getHebdomadaireData(deb, fin, vendeursIdList);

            ctrl.vendeursList.add(userTestRV);
            Ctrl_Triptyque_Analytique.getHebdomadaireData(deb, fin, vendeursIdList);

            // Export PDF
            Id logoId = ctrl.getLogoKparKId();
            ctrl.formatValeursExport(deb, fin);
            ctrl.exportPDF();

            ctrl.setDeb();
            ctrl.setFin();
            ctrl.triptyqueSuiviHebdo();
            ctrl.objVendeurs();

            Test.stopTest();
        }
    }

	private static Chantier__c createChantier(Account proprietaire) {
		Chantier__c chantier = Utils_Test.createChantier('CHA - Test', proprietaire.id, null, null, null, null, null, false);
		return chantier;
	}

	private static Opportunity createOpportunity(Account demandeur, Account autreDemandeur, Chantier__c chantier) {
		Opportunity opportunity = Utils_Test.createOpportunity(demandeur, autreDemandeur, chantier, false);
		return opportunity;
	}

	private static Event createEvent(Opportunity opportunity, Account demandeur) {
		Event event = Utils_Test.createEvent('R1', rtActiviteCommerciale, opportunity.Id, demandeur.personContactId, null, false);
		event.statutRDV__c = 'Effectué';
		event.resultatDuRDV__c = 'Devisable';
		return event;
	}

	private static Quote createQuote(Opportunity opportunity) {
		return Utils_Test.createQuote('MyQuote', rtDEVIS, opportunity, null, Date.today(), 1000, 0, 'CCM', null, false);
	}
}