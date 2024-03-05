//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Utils_CEE
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_Utils_CEE {  
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id EVT_RDV_RT = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);

    @testSetup 
    static void testSetup() {
        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        refList.add(refDep);
        refList.add(refMag);
        insert refList;
        // Création entite     
        List<Account> accList = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        //Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(accountTest);
        insert accList;
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c = secto.Id;
        chantier.heatingMode__c = 'Individuel Electrique';
        insert chantier;
        // Opportunity
        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
    }

    @isTest 
    static void testCPQQuoteCEE() {

        // Création d'un mapping Type de demande <-> RecordType
        Mapping__c mapping = new Mapping__c();
        mapping.name = '76 Zone H2';
        mapping.repository__c = 'zone_climatique';
        mapping.pickValue__c = '76';
        mapping.convertedValue__c = 'H2';
        insert mapping;

        // Creation Incentive CEE
        ESCIncentive__c esc = new ESCIncentive__c(type__c = 'Menuiserie',
                                                startDate__c = Date.today(),
                                                minIncomes__c = 0,
                                                maxIncomes__c = 3000,
                                                personNumber__c = 2,
                                                geography__c = 'H2',
                                                KparKReference__c = 'ESC',
                                                officialAmount__c = 100,
                                                heatingModes__c = 'Individuel Electrique',
                                                customerAmount__c = 1000);
        insert esc;

        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;
        
        // Creation TVA
        TVA_Produit__c tva = Utils_Test.createTVAProduit(prod.Id, Date.today(), 5.5, '11', true);
        
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        // Devis CEE
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, false);
        cpqQuote.RevenusFiscaux__c = 1000;
        cpqQuote.NombrePersonnes__c = 2;
        cpqQuote.Zone__c = 'H2';
        cpqQuote.SBQQ__ShippingPostalCode__c = '13100';
        cpqQuote.typeDeTaux__c = 'Réduit';
        insert cpqQuote;
        // Ligne devis CEE
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, false);
        cpqQuoteLine.eligibleCEE__c = true;
        cpqQuoteLine.SBQQ__CustomerPrice__c = 125.0;
        cpqQuoteLine.SBQQ__ProratedListPrice__c = 125.0;
        cpqQuoteLine.SBQQ__Quantity__c = 1;
        cpqQuoteLine.SBQQ__BundledQuantity__c = 1;
        insert cpqQuoteLine;
        SBQQ__QuoteLine__c cpqQuoteLineOpt = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, false);
        cpqQuoteLineOpt.SBQQ__RequiredBy__c = cpqQuoteLine.Id;
        insert cpqQuoteLineOpt;

        // MAJ montant CEE
        Utils_CEE.setQuoteCEE(new List<SBQQ__QuoteLine__c>{cpqQuoteLine}, cpqQuote, new List<ESCIncentive__c>{esc}, new List<TVA_Produit__c>{tva});
        Utils_CEE.setQliCEE(new List<SBQQ__QuoteLine__c>{cpqQuoteLine}, cpqQuote, new List<ESCIncentive__c>{esc}, new List<TVA_Produit__c>{tva});

        Test.stopTest();
    }
    
    @isTest 
    static void testQuoteCEE() {
        // Création enregistrement utile
        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Event event = Utils_Test.createEvent('R1', EVT_RDV_RT, opp.id, opp.Account.PersonContactId, null, 'Effectué', false);
        event.resultatDuRDV__c = null;
        insert event;

        // Création d'un mapping Type de demande <-> RecordType
        Mapping__c mapping = new Mapping__c();
        mapping.name = '76 Zone H2';
        mapping.repository__c = 'zone_climatique';
        mapping.pickValue__c = '76';
        mapping.convertedValue__c = 'H2';
        insert mapping;

        // Creation Incentive CEE
        ESCIncentive__c esc = new ESCIncentive__c(type__c = 'Menuiserie',
                                                startDate__c = Date.today(),
                                                minIncomes__c = 0,
                                                maxIncomes__c = 3000,
                                                personNumber__c = 2,
                                                geography__c = 'H2',
                                                KparKReference__c = 'ESC',
                                                officialAmount__c = 100,
                                                heatingModes__c = 'Individuel Electrique',
                                                customerAmount__c = 1000);
        insert esc;

        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;
        PricebookEntry ceeProduct = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name='Produit Test' LIMIT 1];
        
        // Creation TVA
        TVA_Produit__c tva = Utils_Test.createTVAProduit(prod.Id, Date.today(), 5, '11', true);

        // Données CEE
        Utils_Test.createCEECategorie(Date.today(), null, 1, 'H2', 1000, 5000, true); 
        List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
        ceePrimeList.add(Utils_Test.createCEEPrime(Date.today(), null, 'A', 'H2', prod.Id, 10, false)); 
        ceePrimeList.add(Utils_Test.createCEEPrime(Date.today(), null, 'B', 'H3', prod.Id, 500, false)); 
        insert ceePrimeList;

        Test.startTest();

        // Création devis
        Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'CCM', null, false);
        quote.revenusFiscaux__c = 1000;
        quote.nbPersonnes__c = 2;
        quote.zone__c = 'H2';
        quote.categorie__c = 'A';
        insert quote;

        // Ligne de devis
        QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, ceeProduct.Id, false);
        qli.TVApourcentage__c = 5;
        insert qli;
        
        Utils_CEE.setQuoteCEE(new List<QuoteLineItem>{qli}, quote, new List<ESCIncentive__c>{esc}, new List<TVA_Produit__c>{tva});
        Utils_CEE.setQliCEE(new List<QuoteLineItem>{qli}, quote, new List<ESCIncentive__c>{esc}, new List<TVA_Produit__c>{tva}, null);
        Utils_CEE.setQuotePrimeCEE(new List<QuoteLineItem>{qli}, quote, ceePrimeList);
        Utils_CEE.setQliPrimeCEE(new List<QuoteLineItem>{qli}, quote, ceePrimeList, null);

        Test.stopTest();
    }
}