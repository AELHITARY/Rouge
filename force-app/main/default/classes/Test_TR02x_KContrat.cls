//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_KContrat
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/07/2018
//-- Version     : 1.2
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_KContrat {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);

    @isTest static void testKContrat() {
     
      User user = getUser();
      update user;

      System.runAs(user) {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);            
        // Création enregistrements utile
        Account B2C1 = Utils_Test.createAccount('Nom', 'Prénom', 'test@kpark.fr', rtB2C,'Email',false);
        B2C1.personHomePhone = '010203ADGJ';
        B2C1.personMobilePhone = '060203ADGJ';
        B2C1.personOtherPhone = '010204TEST';
        B2C1.phone = '010204MPTW';
        B2C1.fax = '010204MPTW';
        B2C1.Localisation__Latitude__s = 0;
        B2C1.Localisation__Longitude__s = 0;
        B2C1.iris__c = sect.iris__c;
        System.assertNotEquals(null, B2C1.iris__c);

        Account B2C2 = Utils_Test.createAccount('Nom Deux', 'Prénom Deux', 'test2@kpark.fr', rtB2C,'Email',false);
        B2C2.personHomePhone = '010203ADGJ';
        B2C2.personMobilePhone = '060203ADGJ';
        B2C2.personOtherPhone = '010204TEST';
        B2C2.phone = '010204MPTW';
        B2C2.fax = '010204MPTW';
        B2C2.Localisation__Latitude__s = 0;
        B2C2.Localisation__Longitude__s = 0;
        B2C2.iris__c = sect.iris__c;
        System.assertNotEquals(null, B2C2.iris__c);

        List<Account> accounts = new List<Account>();
        accounts.add(B2C1);
        accounts.add(B2C2);
        insert accounts;

        Chantier__c chantier = createChantier(B2C1, null, null, null, null, null, sect);
        insert chantier;

        chantier = ((List<Chantier__c>) SchemaUtils.executeQuery('Chantier__c', chantier.id))[0];

        Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);
        projet = ((List<Opportunity>) SchemaUtils.executeQuery('Opportunity', projet.id))[0];
        Opportunity prj = [SELECT Id, Account.contactParDefaut__c FROM Opportunity LIMIT 1];

        // Creation produits / Options référence
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,true);

        Test.startTest();
        Event event = Utils_Test.createEvent('R1', rtActiviteCommerciale, projet.Id, prj.Account.contactParDefaut__c, user.Id, false);
        event.resultatDuRDV__c = null;
        insert event;

        // Creation devis / qli
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, prod,false);
        qli.dureeGarantie1__c = 1;
        qli.dureeGarantie2__c = 2;
        qli.dureeGarantie3__c = 3;
        qli.dureeGarantie4__c = 4;
        qli.dureeGarantie5__c = 5;
        qli.dureeGarantie6__c = 6;
        qli.dureeGarantie7__c = 7;
        qli.dureeGarantie8__c = 8;
        qli.dureeGarantie9__c = 9;
        qli.dureeGarantie10__c = 10;
        insert qli;

        Test.stopTest();
        quote = ((List<Quote>) SchemaUtils.executeQuery('Quote', quote.id))[0];

        // Options des produits
        Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,true);

        quote.dateAcceptationClient__c = System.today();
        update quote;

        KContrat__c contrat = Utils_Test.createContrat(quote, true);

        contrat.dateSignature__c = System.today().addYears(-100);
        contrat.dateResiliation__c = System.today();
        update contrat;

        delete contrat;
      }
    }
    
    @isTest static void testKContrat2() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);            
        // Création enregistrements utile
        Account B2C1 = Utils_Test.createAccount('Nom', 'Prénom', 'test@kpark.fr', rtB2C,'Email',false);
        B2C1.personHomePhone = '010203ADGJ';
        B2C1.personMobilePhone = '060203ADGJ';
        B2C1.personOtherPhone = '010204TEST';
        B2C1.phone = '010204MPTW';
        B2C1.fax = '010204MPTW';
        B2C1.Localisation__Latitude__s = 0;
        B2C1.Localisation__Longitude__s = 0;
        B2C1.iris__c = sect.iris__c;
        System.assertNotEquals(null, B2C1.iris__c);

        List<Account> accounts = new List<Account>();
        accounts.add(B2C1);
        insert accounts;

        Chantier__c chantier = createChantier(B2C1, null, null, null, null, null, sect);
        insert chantier;

        chantier = ((List<Chantier__c>) SchemaUtils.executeQuery('Chantier__c', chantier.id))[0];

        Opportunity projet = Utils_Test.createOpportunity(B2C1, null, chantier, true);
        projet = ((List<Opportunity>) SchemaUtils.executeQuery('Opportunity', projet.id))[0];
        Opportunity prj = [SELECT Id, Account.contactParDefaut__c FROM Opportunity LIMIT 1];
        Event event = Utils_Test.createEvent('R1', rtActiviteCommerciale, projet.Id, prj.Account.contactParDefaut__c, UserInfo.getUserId(), false);
        event.resultatDuRDV__c = null;
        insert event;

        // Creation devis / qli
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        quote = ((List<Quote>) SchemaUtils.executeQuery('Quote', quote.id))[0];

        Test.startTest();

        KContrat__c contrat = Utils_Test.createContrat(quote, true);
        contrat.dateResiliation__c = System.today();
        update contrat;
        
        Test.stopTest();
    }

    private static Chantier__c createChantier(Account proprietaire, Account autreProprietaire, Account locataire, Account autreLocataire, 
                                             Account occupant, Account autreOccupant, Sectorisation__c defaultSectorisation) {
       Chantier__c chantier = new Chantier__c();

       chantier.name = 'CHA - Test';

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

       chantier.Localisation__Latitude__s = 0;
       chantier.Localisation__Longitude__s = 0;
       chantier.iris__c = defaultSectorisation.iris__c;

      System.assertNotEquals(null, chantier.iris__c);

      return chantier;
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