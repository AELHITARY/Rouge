//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Quote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/01/2023
//-- Version     : 1.2
//-- * Ajout de la création de deux lignes de devis dans la fonction test_devis_configure
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_Quote {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id rtDEVIS  = DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_ACONFIGURER);
    private static final Id rtERRONE  = DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_ERRONE);

    @testSetup 
    static void setup() {
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
        
        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true); 
        Utils_Test.createProduct('Produit CEE', 'CEEEEE', 'ISOLATION', 'ISOLATION', 50, 50, true); 
        //Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        
        // Options référence
        ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption',1,true);
        // Coefficient thermique
        Utils_Test.createCoeffTh(prod.Id,refOpt.Id,'Sw',1,'T',null,'Uv',2,'A','1',true);

        Chantier__c chantier = Utils_Test.createChantier('Chantier test', B2C1.Id,true);
        Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);
        Quote quote = Utils_Test.createQuote('Devis test', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        QuoteLineItem quoteLine = createQuoteLine(quote);
        insert quoteLine;
    }

    @isTest 
    static void test() {
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            Quote quote = [SELECT Id FROM Quote LIMIT 1];

            Test.startTest();

            quote.forcageEtat__c = 'Transmis';
            update quote;    
    
            quote.recordTypeId = rtERRONE;
            quote.forcageEtat__c = null;
            update quote; // Erroné
    
            quote.recordTypeId = rtDEVIS;
            update quote; // Non transmis
    
            insert createQuoteLine(quote); // A configurer

            quote.compte__c = null;
            update quote;
    
            Test.stopTest();
        }
    }

    @isTest 
    static void devis_configure() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            Test.startTest();
            Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
            Account B2C2 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test2@kpark.fr'))[0];
    
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
            Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);
    
            //Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            Quote quote = [SELECT Id FROM Quote LIMIT 1];
            
    
            QuoteLineItem quoteLine = createQuoteLine(quote);
            insert quoteLine; // A configurer
    
            quoteLine.aConfigurer__c = false;

            quoteLine.Quantity = 2;

            update quoteLine; // Non transmis
    
            quote.dateDevis__c = System.today()-1;
            update quote; // A configurer
    
            Test.stopTest();
        }
    }

    @isTest 
    static void testLigne() {
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
            Account B2C2 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test2@kpark.fr'))[0];
    
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
            Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);
    
            Test.startTest();
    
            Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            QuoteLineItem quoteLine = createQuoteLine(quote);
            quoteLine.Quantity = 2;
            quoteLine.tvaPourcentage__c = 20;
            insert quoteLine; // Relance calcul remise enseigne
            delete quoteLine; // Relance calcul "Produits des devis"
    
            Test.stopTest();
        }
    }

    @isTest 
    static void testLigne2() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            QuoteLineItem quoteLine = [SELECT Id FROM QuoteLineItem LIMIT 1];
    
            Test.startTest();

            quoteLine.Quantity = 2;
            update quoteLine;
            
            delete quoteLine; // Relance calcul "Produits des devis"
    
            Test.stopTest();
        }
    }

    @isTest 
    static void testCoeffThermique() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            QuoteLineItem quoteLine = [SELECT Id FROM QuoteLineItem LIMIT 1];
            ReferentielOptions__c refOpt = [SELECT Id FROM ReferentielOptions__c LIMIT 1];
    
            Test.startTest();
            
            // Create and update option
            Option__c op = Utils_Test.createOption(quoteLine.Id,'RefOption','Libellé Option 1',refOpt.Id,1,false);
            op.Valorisation__c = 100;
            insert op;
            op.Valorisation__c = 200;
            update op;
    
            Test.stopTest();
        }
    }

    @isTest 
    static void testDeleteOption() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            QuoteLineItem quoteLine = [SELECT Id FROM QuoteLineItem LIMIT 1];
            ReferentielOptions__c refOpt = [SELECT Id FROM ReferentielOptions__c LIMIT 1];
    
            Test.startTest();
            
            // Create and delete option
            Option__c op = Utils_Test.createOption(quoteLine.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            op.Valorisation__c = 100;
            insert op;
            delete op; 
    
            Test.stopTest();
        }
    }

    @isTest 
    static void devis_statut() {
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            Test.startTest();
            Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
            Account B2C2 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test2@kpark.fr'))[0];
    
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
            Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);
    
            Event event = Utils_Test.createEvent('R1',rtRDV,projet.id,B2C1.PersonContactId,null,'Effectué', false);
            event.resultatDuRDV__c = null;
            insert event;
    
            Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'CCM', null, true);
            quote.forcageEtat__c = 'Transmis';
            update quote;
    
            quote.recordTypeId = rtERRONE;
            quote.forcageEtat__c = null;
            update quote; // Erroné
    
            quote.recordTypeId = rtDEVIS;
            update quote; // Non transmis
    
            insert createQuoteLine(quote); // A configurer
    
            quote.dateTransmissionClient__c  = System.today();
            update quote; // Transmis
    
            quote.dateAcceptationClient__c = System.today();
            update quote; // Vendu en attente d\'enregistrement
    
            KIncontournable__c incontournable = Utils_Test.createIncontournable(quote,true);
            incontournable.statut__c = 'ENREGISTRE';
            update incontournable; // Vendu incontournable
    
            incontournable.statut__c = 'TERMINE';
            update incontournable; // Vendu en attente d\'enregistrement
    
            KContrat__c contrat = Utils_Test.createContrat(quote, true); // Vendu enregistré
    
            contrat.dateResiliation__c = System.today();
            update contrat; // Résilié
    
            delete quote;
    
            Test.stopTest();
        }
    }

    @isTest 
    static void devis_CEE() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            Test.startTest();            
            Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
            Account B2C2 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test2@kpark.fr'))[0];
    
            // Création enregistrement utile
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
            Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);
            Event event = Utils_Test.createEvent('R1',rtRDV,projet.id,B2C1.PersonContactId,null,'Effectué', false);
            event.resultatDuRDV__c = null;
            insert event;
    
            // Données CEE
            // Création d'un mapping Type de demande <-> RecordType
            Mapping__c mapping = new Mapping__c();
            mapping.name = '76 Zone H2';
            mapping.repository__c = 'zone_climatique';
            mapping.pickValue__c = '76';
            mapping.convertedValue__c = 'H2';
            insert mapping;
            PricebookEntry ceeProduct = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit CEE' LIMIT 1];
            Utils_Test.createCEECategorie(Date.today(), null, 1, 'H2', 1000, 5000, true); 
            Utils_Test.createCEEPrime(Date.today(), null, 'B', 'H2', ceeProduct.Product2Id, 10, true);
            Utils_Test.createCEEPrime(Date.today(), null, 'A', 'H3', ceeProduct.Product2Id, 500, true);
    
            
            Quote quoteTodel = [SELECT Id FROM Quote LIMIT 1];
            delete quoteTodel;
            // Création devis
            Quote quote = Utils_Test.createQuote('Devis 2', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'CCM', null, false);
            quote.revenusFiscaux__c = 5000;
            quote.nbPersonnes__c = 1;
            insert quote;
    
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, ceeProduct.Id, true);
    
            Test.stopTest();
    
            // TEST 
            qli = DAL.getQuoteLineItemById(qli.Id);
        }
    }

    @isTest 
    static void setRemises() { 
        UserContext context = UserContext.getContext(); 
            
        Test.startTest();
        
        TR022_Quote.setRemises(context);
        
        Test.stopTest();
    }

    @isTest 
    static void calculatePriceOptions() {
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            list <Option__c> optionList = new list<Option__c>();
            Test.startTest();
            // Création enregistrement utile
            Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            Account acc = Utils_Test.createAccount('Account UN', 'test', 'test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
            // Creation devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            // Ligne de devis et produit
            QuoteLineItem qli = createQuoteLine(devis);
            insert qli;
            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',2,true);
            // Options 
            Option__c op = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,true);
            op.Valorisation__c = 100;
            optionList.add(op);
    
            // Caclul du prix
            TR022_Option.calculatePrice(optionList);
            op.Option__c = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',3,true).Id;
            TR022_Option.calculatePrice(optionList);
            op.Option__c = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',4,true).Id;
            TR022_Option.calculatePrice(optionList);
            op.Option__c = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',5,true).Id;
            TR022_Option.calculatePrice(optionList);
            op.Option__c = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',6,true).Id;
            TR022_Option.calculatePrice(optionList);
            op.Option__c = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',7,true).Id;
            TR022_Option.calculatePrice(optionList);
            op.Option__c = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',8,true).Id;
            TR022_Option.calculatePrice(optionList);
    
            Test.stopTest();
            
            delete op;
        }
    }

    @isTest 
    static void setQLIRemiseEnseigne(){
        Test.startTest();
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        qli.Quantity = 2;
        update qli;
        Test.stopTest();
    }

    private static QuoteLineItem createQuoteLine(Quote quote) {        
        Product2 prod = [SELECT Id FROM Product2 WHERE Name='Produit Test' LIMIT 1];
        QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 1, 1.0, 1.0, prod, false);
        return line;
    }
}