@isTest(SeeAllData=true)
private class Test_TR02x_KIncontournable {

   private static final RecordType rtB2B    = [SELECT id FROM RecordType WHERE name = 'Compte professionnel' LIMIT 1];
   private static final RecordType rtB2C    = [SELECT id FROM RecordType WHERE name = 'Compte personnel' LIMIT 1];
   private static final RecordType rtRDV    = [SELECT id FROM RecordType WHERE name = 'FRA- Activité commerciale' LIMIT 1];
   private static final RecordType rtDEVIS  = [SELECT id FROM RecordType WHERE name = 'FRA- Devis A configurer' LIMIT 1];

   private static final Sectorisation__c defaultSectorisation = TestCommon.createSectorisation();

   static testMethod void testKIncontournable() {
     insert defaultSectorisation;
     User user = getUser();
     update user;

     System.runAs(user) {
       Account B2C1 = createAccountB2C();
       Account B2C2 = createAccountB2C();

       List<Account> accounts = new List<Account>();
       accounts.add(B2C1);
       accounts.add(B2C2);
       insert accounts;

       Map<Id, Account> accountMap = new Map<Id, Account>((List<Account>) SchemaUtils.executeQuery('Account', IDUtils.getIDs(accounts)));
       B2C1 = accountMap.get(B2C1.id);
       B2C2 = accountMap.get(B2C2.id);

       Chantier__c chantier = createChantier(B2C1, null, null, null, null, null);
       insert chantier;

       chantier = ((List<Chantier__c>) SchemaUtils.executeQuery('Chantier__c', chantier.id))[0];

       Opportunity projet = createOpportunity(B2C1, B2C2, chantier);

       insert projet;

       projet = ((List<Opportunity>) SchemaUtils.executeQuery('Opportunity', projet.id))[0];

       Test.startTest();
       Event event = createEvent(projet, B2C1);
       event.resultatDuRDV__c = null;

       insert event;

       /* >>> F.G., le 24/06/13 suite erreur dans DAL.getRemiseIncentive
       Quote quote = createQuote(projet);

       Test.startTest();
       insert quote;
          --- F.G., le 24/06/2013 suite erreur dans DAL.getRemiseIncentive */

       Quote quote = TestCommon.createDevis(null, 'MyQoute', date.today(), projet.Id);
       /* <<< F.G., le 24/06/13 suite erreur dans DAL.getRemiseIncentive */


       quote = ((List<Quote>) SchemaUtils.executeQuery('Quote', quote.id))[0];

       Test.stopTest();

       KIncontournable__c incontournable = createKIncontournable(quote);

       insert incontournable;



       incontournable.actif__c = True;
       incontournable.statut__c = 'EN COURS';
       update incontournable;

       incontournable.statut__c = 'ENREGISTRE';
       update incontournable;

       delete incontournable;


     }
   }

   private static Account createAccountB2B() {
     Account account = new Account(recordTypeId = rtB2B.id);

     account.name = 'Compte professionnel';
     account.accountCallSource__c = '15 - Campagne Marketing';
     account.billingStreet = '1200 rue félix faure';
     account.billingPostalCode = '76320';
     account.billingCity = 'Caudebec les Elbeuf';
     account.billingCountry = 'F';
     account.phone = '010203ADGJ';
     account.fax = '010204MPTW';

     account.x__c = 0;
     account.y__c = 0;
     account.Localisation__Latitude__s = 0;
     account.Localisation__Longitude__s = 0;
     account.iris__c = defaultSectorisation.iris__c;

     System.assertNotEquals(null, account.iris__c);

     return account;
   }

   private static Account createAccountB2C() {
     Account account = new Account(recordTypeId = rtB2C.id);

     account.salutation = 'M.';
     account.lastName = 'Nom';
     account.firstName = 'Prénom';
     account.accountCallSource__c = '17 - JPO';
     account.personMailingStreet = '1 rue félix faure';
     account.personMailingPostalCode = '76320';
     account.personMailingCity = 'Saint-Pierre les Elbeuf';
     account.personMailingCountry = 'F';
     account.personHomePhone = '010203ADGJ';
     account.personMobilePhone = '060203ADGJ';
     account.personOtherPhone = '010204TEST';
     account.phone = '010204MPTW';
     account.fax = '010204MPTW';
     account.personEmail = 'test@kpark.fr';

     account.x__c = 0;
     account.y__c = 0;
     account.iris__c = defaultSectorisation.iris__c;

     System.assertNotEquals(null, account.iris__c);

     return account;
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
     chantier.iris__c = defaultSectorisation.iris__c;

     System.assertNotEquals(null, chantier.iris__c);

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
   
//SEO 02/08/2013 Ajout du whoId
   private static Event createEvent(Opportunity opportunity, Account demandeur) {
     Event event = new Event(recordTypeId = rtRDV.id);

     event.type = 'R1';
     event.activityDate = System.today();
     event.startDateTime = System.now();
     event.endDateTime = System.now();
     event.whatId = opportunity.id;
     event.whoId = demandeur.personContactId;
     event.couplePresent__c = 'Oui';
     event.decisionnaire__c = True;
     event.statutRDV__c = 'Effectué';
     event.resultatDuRDV__c = 'Devisable';

     return event;
   }

   private static Quote createQuote(Opportunity opportunity) {
     Quote quote = new Quote(recordTypeId = rtDEVIS.id);

     Id pricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

     quote.OpportunityId = opportunity.Id;
     quote.Pricebook2Id = pricebookId;
     quote.Name = 'MyQuote';
     quote.compte__c = opportunity.accountId;
     quote.C2E__c = null;
     quote.moyenTransmissionClient__c = 'Par email';
     quote.autreCompte__c = opportunity.autreCompte__c;
     quote.modeFinancement__c = 'PAIEMENT COMPTANT';

     return quote;
  }

  private static KIncontournable__c createKIncontournable(Quote quote) {
     KIncontournable__c incontournable = new KIncontournable__c();

     incontournable.devis__c = quote.id;
     incontournable.actif__c = False;
     incontournable.dateEcheance__c = System.today() + 10;
     incontournable.dateIncontournable__c = System.today();
     incontournable.dateEnvoiCourrier__c = System.today();
     incontournable.nImprimeBdC__c = '01234';
     incontournable.nImprimeMdC__c = '98765';
     incontournable.nIncontournable__c = 'ICT/0102030405/01';
     incontournable.statut__c = 'TERMINE';

     return incontournable;
   }

   private static User getUser() {
     UserContext context = UserContext.getContext();
     User user = context.getUser();
     if (StringUtils.isEmpty(user.codeMagasin__c))
       user.codeMagasin__c = 'MAG0000';
     if (StringUtils.isEmpty(user.libelleMagasin__c))
       user.codeMagasin__c = 'Magasin 0000';
     if (StringUtils.isEmpty(user.codeDV__c))
       user.codeMagasin__c = 'DV0000';
     if (StringUtils.isEmpty(user.libelleDV__c))
       user.codeMagasin__c = 'DV 0000';
     if (StringUtils.isEmpty(user.codeDR__c))
       user.codeMagasin__c = 'DV0000';
     if (StringUtils.isEmpty(user.libelleDR__c))
       user.codeMagasin__c = 'DV 0000';
     return user;
   }
}