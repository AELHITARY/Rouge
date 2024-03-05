//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_EinsteinPipelineCSV
//-- Modifi? par : SOPRA STERIA
//-- Modifi? le  : 02/11/2020
//-- Version     : 1.0
//-- Description : Classe de tests pour Schedule_EinsteinPipelineCSV et BA_EinsteinPipelineCSV
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_EinsteinPipelineCSV {
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id refFinModeRT = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod');
    private static final Id refSourceRT = DAL.getRecordTypeIdByDevName('Referencial__c', 'Source');
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id modifiableQuoteRT = DAL.getRecordTypeIdByDevName('SBQQ__Quote__c', Constants.QUOTE_SALES_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('einstein.csv.pipeline.createFile', true);
        PropertiesUtils.setStringValue('einstein.csv.pipeline.emailTo', 'test@test.fr');

        // Cr?ation Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true); 

        // Cr?ation d'un compte, chantier, projet
        Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', rtB2C, 'FAX', true);
        Chantier__c cha = Utils_Test.createChantier('Chantier 1', account.Id, true);
        Opportunity opp = Utils_Test.createOpportunity(account, null, cha, true);
        
        GlobalProperties__c ohProp = new GlobalProperties__c ();
        ohProp.Name='fsl.operatingHours.defaultName';
        ohProp.stringValue__c='Par D?faut'; 
        insert ohProp;
        
        //Cr?ation horaires
        OperatingHours oh = new OperatingHours(
            //fsl_dateOuverture__c = Date.newInstance(2017, 1, 1),
            Name='Par D?faut' ,
            TimeZone='Europe/Paris' );
        insert oh;  

        // Cr?ation entite
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account magasinA = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);

        // Mode de financement
        Referencial__c financialRef = Utils_Test.createReferencial('Comptant', 'CASH',  Date.today().addMonths(-12), null, refFinModeRT, false, false, false, false, false);
        financialRef.financingType__c = 'Cash';
        financialRef.advancePayment1__c = 0;
        insert financialRef;

        // Source
        Referencial__c sourceRef = Utils_Test.createReferencial('WEB', 'WEB',  Date.today().addMonths(-12), null, refSourceRT, false, false, false, false, false);
        sourceRef.usableForSales__c = true;
        insert sourceRef;

        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);

        // Price book
        Id pBookId = Test.getStandardPricebookId();
        PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // Creation devis
        SBQQ__Quote__c quote = Utils_Test.createCPQQuote('Test', modifiableQuoteRT, opp, null, Date.today(), 125, 50, sourceRef.Name, null, false);
        quote.sourceRef__c = sourceRef.Id;
        quote.financingMethod__c = financialRef.Id;
        quote.chantier__c = cha.Id;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PricebookId__c = pBookId;
        insert quote;
        quote = [SELECT Id, chantier__c, financingMethod__c, sourceRef__c, SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];

        // Creation commande
        //Order ord = Utils_Test.createCustomerOrder(quote, pBookId, false);
        Order ord = new Order(SBQQ__Quote__c = quote.Id,
                            AccountId = quote.SBQQ__Account__c,
                            chantier__c = quote.chantier__c,
                            source__c = quote.sourceRef__c,
                            financingMethod__c = quote.financingMethod__c,
                            Pricebook2Id = pBookId,
                            EffectiveDate = Date.today(),
                            Status = Constants.ORDER_STATUS_REGISTERED,
                            legacyReference__c = 'te');
        insert ord;
    }

    @isTest 
    static void testBatch() {
        // Ex?cution du test
        Test.StartTest();

        BA_EinsteinPipelineCSV ba = new BA_EinsteinPipelineCSV();
        Database.executeBatch(ba);

        Test.stopTest();

    }

    @isTest 
    static void testSchedule() {
        // Ex?cution du test
        Test.StartTest();

        String jobId = System.schedule('Schedule_EinsteinPipelineCSV', '0 0 * * * ?', new Schedule_EinsteinPipelineCSV() );
        Schedule_EinsteinPipelineCSV schedule = new Schedule_EinsteinPipelineCSV();
        schedule.execute(null);

        Test.stopTest();

    }
}