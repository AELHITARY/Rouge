@isTest(SeeAllData=true)
private class Test_TR02x_KInstance {
    
    private static final RecordType rtB2B    = [SELECT id FROM RecordType WHERE name = 'Compte professionnel' LIMIT 1];
    private static final RecordType rtB2C    = [SELECT id FROM RecordType WHERE name = 'Compte personnel' LIMIT 1];
    private static final RecordType rtRDV    = [SELECT id FROM RecordType WHERE name = 'FRA- Activité commerciale' LIMIT 1];
    private static final RecordType rtDEVIS  = [SELECT id FROM RecordType WHERE name = 'FRA- Devis A configurer' LIMIT 1];
    
    private static final Sectorisation__c defaultSectorisation = TestCommon.createSectorisation();
    
    static testMethod void testKInstance() {
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
            
            
            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
            Pricebook2 pBook = new Pricebook2(Name ='Test');
            insert pBook;
            PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
            insert priceBookEntry;
            
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
            
            
            Quote quote = createQuote(projet);
            quote.moyenTransmissionClient__c = 'Par email';
            quote.delaiInstallationMax__c = 2;
            quote.delaiInstallationMin__c = 2;
            
            insert quote;
            
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '2', 180, 180,1,300, 200, priceBookEntry.Id, true);
            
            
            quote.dateAcceptationClient__c = date.today();
            update quote;
            
            Test.stopTest();
            quote = ((List<Quote>) SchemaUtils.executeQuery('Quote', quote.id))[0];
            
            KContrat__c contrat = createKContrat(B2C1, B2C2, chantier, quote);
            
            insert contrat;
            
            KInstance__c instance = createKInstance(contrat);
            
            insert instance;
            
            
            
            instance.actif__c = True;
            instance.dateSortie__c = null;
            instance.statut__c = 'En cours';
            update instance;
            
            delete instance;
            
            
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
        account.Localisation__Latitude__s = 0;
        account.Localisation__Longitude__s = 0;
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
        
        Id pricebookId = [SELECT Id FROM Pricebook2 WHERE Name ='Test' LIMIT 1].Id;
        
        quote.OpportunityId = opportunity.Id;
        quote.Pricebook2Id = pricebookId;
        quote.Name = 'MyQuote';
        quote.compte__c = opportunity.accountId;
        //quote.C2E__c = 'Oui';
        quote.source__c = 'BAL VENDEUR';
        quote.moyenTransmissionClient__c = 'Par email';
        quote.autreCompte__c = opportunity.autreCompte__c;
        quote.modeFinancement__c = 'PAIEMENT COMPTANT';
        quote.Total_TTC_devis__c = 123;
        
        return quote;
    }
    
    private static KContrat__c createKContrat(Account compte, Account autreCompte, Chantier__c chantier, Quote devis) {
        KContrat__c contrat = new KContrat__c();
        
        contrat.compte__c = compte.id;
        contrat.autreCompte__c = autreCompte.id;
        contrat.chantier__c = chantier.id;
        contrat.devis__c = devis.id;
        contrat.montantECS__c = -50;
        contrat.montantHT__c = 5000;
        contrat.montantTTC__c = 7000;
        contrat.dateSignature__c = System.today();
        contrat.numeroContrat__c = 'CNT/0102030405';
        contrat.libelleStatutContrat__c = 'Test';
        
        return contrat;
    }
    
    private static KInstance__c createKInstance(KContrat__c contrat) {
        KInstance__c instance = new KInstance__c();
        
        instance.contrat__c = contrat.id;
        instance.actif__c = False;
        instance.dateEcheance__c = System.today() + 10;
        instance.dateEntree__c = System.today() - 1;
        instance.dateSortie__c = System.today();
        instance.nInstance__c = 'IEC/0102030405/01';
        instance.statut__c = 'Terminé';
        
        return instance;
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