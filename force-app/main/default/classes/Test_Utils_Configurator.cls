//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Utils_Configurator
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/12/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
@isTest
private class Test_Utils_Configurator {
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

	@testSetup 
	static void setup() {
		Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
		PropertiesUtils.setBooleanValue('dqe.geocoder.enabled', true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
        Mapping__c maping = new Mapping__c(Name = 'TEST', repository__c ='origine', pickValue__c = 'BAL VENDEUR', convertedValue__c= '50');
        insert maping;

        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('MAG0123', 'Magasin 123', 'DEP123', 'Depot 123', true); 

        // Création entite
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
        Utils_Test.createEntity('Magasin 123', 'MAG0123', Date.today(), '0123456789', refMag.Id, true);    
        
        // Creation enregistrements
        Account acc = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtB2C, 'Email', false);
        acc.sectorisation__c = sect.Id;
        insert acc;
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
        chantier.sectorisation__c = sect.Id;
        insert chantier;
        
        // Creation produits
        Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);         
    }

    @isTest 
    static void test() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.codeMagasin__c = 'MAG0123';
        update user;

        System.runAs(user){
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account WHERE RecordTypeId = :rtB2C LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 LIMIT 1];            
            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
			
			// Exécution du test
			Test.startTest();

            Quote devis = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, true);
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.id, '2', 90, 150, 1, 1.0, 1.0, prod, true);
            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',2,false);
            refOpt.DebutValidite__c = Date.today().addDays(-3);
            refOpt.FinValidite__c = Date.today().addDays(3);
            insert refOpt;
            // Options 
            Option__c op = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            op.Valorisation__c = 100;
            insert op;

            Utils_Configurator.recalculerTarifOptions(devis);

            delete op;

			Test.stopTest();
		}
    }

    @isTest 
    static void testPromo() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.codeMagasin__c = 'MAG0123';
        update user;

        System.runAs(user){
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account WHERE RecordTypeId = :rtB2C LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 LIMIT 1];            
            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);			

            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',2,false);
            refOpt.OptionPromotionnelle__c = true;
            refOpt.Debutvalidite__c = Date.today().addDays(-3);
            refOpt.FinValidite__c = Date.today().addDays(3);
            insert refOpt;
            // Incentive
            Incentive__c inc = new Incentive__c();
            inc.DebutValidite__c = Date.today().addDays(-3);
            inc.FinValidite__c = Date.today().addDays(3);
            inc.Magasinselligibles__c = 'MAG0123';
            inc.OriginesElligibles__c = '50';
            insert inc;
            // IncentivePromotion
            IncentivePromotion__c incPromo = new IncentivePromotion__c();
            incPromo.Codeincentive__c = inc.Id;
            incPromo.CodeOption__c = refOpt.Id;
            incPromo.ModeValorisation__c = true;
            incPromo.ValorisationPromotion__c = 10;
            incPromo.Actif__c = true;
            insert incPromo;

			// Exécution du test
            Test.startTest();

            Quote devis = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, true);
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.id, '2', 90, 150, 1, 1.0, 1.0, prod, true);
            
            // Options 
            Option__c op = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            op.Valorisation__c = 100;
            insert op;

            Utils_Configurator.recalculerTarifOptions(devis);

			Test.stopTest();
		}
    }
    @isTest 
    static void testIncentive() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.codeMagasin__c = 'MAG0123';
        update user;

        System.runAs(user){
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account WHERE RecordTypeId = :rtB2C LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 LIMIT 1];            
            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);            
            
            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',2,false);
            refOpt.OptionPromotionnelle__c = true;
            refOpt.Debutvalidite__c = Date.today().addDays(-3);
            refOpt.FinValidite__c = Date.today().addDays(3);
            insert refOpt;
            // Incentive
            Incentive__c inc = new Incentive__c();
            inc.DebutValidite__c = Date.today().addDays(-3);
            inc.FinValidite__c = Date.today().addDays(3);
            inc.Magasinselligibles__c = 'MAG0123';
            inc.OriginesElligibles__c = '50';
            insert inc;
            // IncentivePromotion
            IncentivePromotion__c incPromo = new IncentivePromotion__c();
            incPromo.Codeincentive__c = inc.Id;
            incPromo.CodeOption__c = refOpt.Id;
            incPromo.ModeValorisation__c = true;
            incPromo.ValorisationPromotion__c = 10;
            incPromo.Actif__c = true;
            insert incPromo;

			// Exécution du test
			Test.startTest();

            Quote devis = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, true);
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.id, '2', 90, 150, 1, 1.0, 1.0, prod, true);

            Utils_Configurator.isProjetEligible(devis, inc);
            Utils_Configurator.recalculerTarifOptions(devis);

			Test.stopTest();
		}
    }

    @isTest 
    static void testOther() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.codeMagasin__c = 'MAG0123';
        update user;

        System.runAs(user){
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account WHERE RecordTypeId = :rtB2C LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 LIMIT 1];            
            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
			
			// Exécution du test
			Test.startTest();

            Quote devis = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'BAL VENDEUR', null, true);
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.id, '2', 90, 150, 1, 1.0, 1.0, prod, true);
            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',2,true);
            // Options 
            Option__c op = Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,false);
            op.Valorisation__c = 100;
            insert op;

            Utils_Configurator.getCodeMagasinNum(null);
            Utils_Configurator.getCodeMagasinNum('MAG0011');
            Utils_Configurator.isRemiseEnseigne(op);
            Utils_Configurator.isReferencePromotion(refOpt);
            Utils_Configurator.isOPMarket(op);

			Test.stopTest();
		}
    }    
/*
    @isTest 
    static void testCEE() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.codeMagasin__c = 'MAG0123';
        update user;

        System.runAs(user){
            Account acc = [SELECT Id, AccountSource, accountCallSource__c, PersonContactId FROM Account WHERE RecordTypeId = :rtB2C LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 LIMIT 1];            
            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
    
            // Création enregistrement utile
            Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
            Event event = Utils_Test.createEvent('R1',rtRDV,projet.id,acc.PersonContactId,null,'Effectué', false);
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
            Utils_Test.createProduct('Produit CEE', 'CEEEEE', 'ISOLATION', 'ISOLATION', 50, 50, true); 
            PricebookEntry ceeProduct = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit CEE' LIMIT 1];
            Utils_Test.createCEECategorie(Date.today(), null, 1, 'H2', 1000, 5000, true); 
            CEE_Prime__c cee1 = Utils_Test.createCEEPrime(Date.today(), null, 'B', 'H2', ceeProduct.Product2Id, 10, true);
            CEE_Prime__c cee2 = Utils_Test.createCEEPrime(Date.today(), null, 'A', 'H3', ceeProduct.Product2Id, 500, true);
    
            Test.startTest();
    
            // Création devis
            Quote devis = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'CCM', null, false);
            devis.revenusFiscaux__c = 5000;
            devis.nbPersonnes__c = 1;
            insert devis;    
            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(devis.Id, '1', 30, 100, 2, 56.0, 56.0, ceeProduct.Id, true);

            //TEST
            Map<ID,PricebookEntry> pricebookEntryList = new Map<ID,PricebookEntry>();
            pricebookEntryList.put(ceeProduct.Id, ceeProduct);
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            qliList.add(qli);
            List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
            ceePrimeList.add(cee1);
            ceePrimeList.add(cee2);

            Utils_Configurator.setQliPrimeCEE(qliList, devis, ceePrimeList, pricebookEntryList);
            Utils_Configurator.setQuotePrimeCEE(qliList, devis, ceePrimeList);
    
            Test.stopTest();
        }
    }*/
}