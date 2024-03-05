//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_QuoteCPQGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/08/2021
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_QuoteCPQGeneratePDF
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private with sharing class Test_LWC_QuoteCPQGeneratePDF {
     //omar
     // Mock class to simulate callout response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Add desired mock response body as required
            res.setBody('mock_response_body');
            return res;
        }
    }

	@testSetup 
    static void setup() {
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Id RTDevNameReferencial = DAL.getRecordTypeIdByDevName('Referencial__c', 'CustomerCancellationReason');
       
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', accPersoRT, null, 'Email', true);
        
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);

        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c=secto.Id;
        chantier.heatingMode__c='Collectif';
        insert chantier;

        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
        
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        Referencial__c ref = Utils_Test.createReferencial('ref','ref', Date.today(), Date.today(), RTDevNameReferencial, false, false, false, false, false);
        ref.KparKReference__c= PropertiesUtils.getStringValue('ref.motifAnnulationKparK.code', 'RSL-0016');
        insert ref;

        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);
        
        ContentDocumentLink cdl = Utils_Test.createFile('test', cpqQuoteLine.Id, Blob.valueOf('content'), true);
        Id contentVer = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].Id;
        ContentDistribution cdistrib = Utils_Test.createContentDistribution('test', contentVer, true);
    }

    @isTest
    static void testRenderQuoteDocumentPDF() {
        // Fetch the quote record ID
    	SBQQ__Quote__c cpqQuoteTest = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

    	// Setting the mock callout
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    

        // Setting the mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Start Test
        Test.startTest();
        
        // Call your method
        Id quoteId = cpqQuoteTest.Id;
        String result = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(quoteId, 'testFilename.pdf', 'DIP');
        
        Test.stopTest();
        
        // Now, write assertions to check the expected behavior
        System.assertNotEquals(null, result, 'The result should not be null');
    }
    
    
    
    
    
    
    //omar
    
    
    
    
    

    @isTest
    private static void testRenderDIP(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        System.runAs(user){
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            Test.startTest();
            LWC_QuoteCPQGeneratePDF.QuoteObject qo = new LWC_QuoteCPQGeneratePDF.QuoteObject();
            LWC_QuoteCPQGeneratePDF.QuoteLineObject glo = new LWC_QuoteCPQGeneratePDF.QuoteLineObject();
            SBQQ__Quote__c cpqQuote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
            
            LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(cpqQuote.Id, 'test', 'DIP');
            Blob blobDIPC = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(cpqQuote.Id, 'test', 'DIP');
            LWC_QuoteCPQGeneratePDF.linkDocumentToRecordForSignea(cpqQuote.Id, 'test', blobDIPC, 'DIP');

            Test.stopTest();
        }
    }

    @isTest
    private static void testRenderContrat(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        System.runAs(user){
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            Test.startTest();
            LWC_QuoteCPQGeneratePDF.QuoteObject qo = new LWC_QuoteCPQGeneratePDF.QuoteObject();
            LWC_QuoteCPQGeneratePDF.QuoteLineObject glo = new LWC_QuoteCPQGeneratePDF.QuoteLineObject();
            SBQQ__Quote__c cpqQuote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];

            LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(cpqQuote.Id, 'test', 'Contrat');
            Blob blobDIPC = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(cpqQuote.Id, 'test', 'Contrat');
            LWC_QuoteCPQGeneratePDF.linkDocumentToRecordForSignea(cpqQuote.Id, 'test', blobDIPC, 'Contrat');

            Test.stopTest();
        }
    }

    @isTest
    private static void testAlreadyDocument(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        System.runAs(user){
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            Test.startTest();
            LWC_QuoteCPQGeneratePDF.QuoteObject qo = new LWC_QuoteCPQGeneratePDF.QuoteObject();
            LWC_QuoteCPQGeneratePDF.QuoteLineObject glo = new LWC_QuoteCPQGeneratePDF.QuoteLineObject();
            SBQQ__Quote__c cpqQuote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
            
            ContentDocumentLink cdl = Utils_Test.createFile('test', cpqQuote.Id, Blob.valueOf('content'), true);
            ContentVersion contentVer = [SELECT Id, category__c FROM ContentVersion LIMIT 1];
            contentVer.category__c = 'Contrat';
            update contentVer;

            LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(cpqQuote.Id, 'test', 'Contrat');

            Test.stopTest();
        }
    }

    @isTest
    private static void testConstructWarrantiesMap(){
        Test.startTest();
        //(String categorie, String libelle, Decimal duration, Map<String, List<WarrantyObject>> warrantiesMap)
        LWC_QuoteCPQGeneratePDF.constructWarrantiesMap('cat','lib',0.5, new Map<String, List<LWC_QuoteCPQGeneratePDF.WarrantyObject>>());
        Test.stopTest();
    }

    @isTest
    private static void testCustomPictograms(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        System.runAs(user){
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            Test.startTest();
            LWC_QuoteCPQGeneratePDF.QuoteObject qo = new LWC_QuoteCPQGeneratePDF.QuoteObject();
            LWC_QuoteCPQGeneratePDF.QuoteLineObject glo = new LWC_QuoteCPQGeneratePDF.QuoteLineObject();
            SBQQ__Quote__c cpqQuote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
            Product2 product = [SELECT Id FROM Product2 LIMIT 1];


            Product2 product2 = Utils_Test.createProduct('Produit Test 2', 'FFFETT2');
            product2.image__c = 'https://image-test-default';
            update product2;


            List<SBQQ__QuoteLine__c> cpqQuoteLineList = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c newCpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, product2, false);
            newCpqQuoteLine.NombreVantaux__c = '2';
            cpqQuoteLineList.Add(newCpqQuoteLine);
            SBQQ__QuoteLine__c newCpqQuoteLine2 = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, product2, false);
            newCpqQuoteLine2.NombreVantaux__c = '1';
            cpqQuoteLineList.Add(newCpqQuoteLine2);
            SBQQ__QuoteLine__c newCpqQuoteLine3 = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, product, false);
            newCpqQuoteLine3.NombreVantaux__c = '2';
            cpqQuoteLineList.Add(newCpqQuoteLine3);
            insert cpqQuoteLineList;

            List<Product2> productOptionList = new List<Product2>();
            Product2 productOption1 = Utils_Test.createProduct('Produit Option 1', 'OPTION1',false);
            Product2 productOption2 = Utils_Test.createProduct('Produit Option 2', 'OPTION2',false);
            Product2 productOption3 = Utils_Test.createProduct('Produit Option 3', 'OPTION3',false);
            Product2 productOption4 = Utils_Test.createProduct('Produit Option 4', 'OPTION4',false);

            productOptionList.Add(productOption1);
            productOptionList.Add(productOption2);
            productOptionList.Add(productOption3);
            productOptionList.Add(productOption4);

            insert productOptionList;

            List<SBQQ__QuoteLine__c> cpqOptionList = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c option1 = Utils_Test.createCPQOption(newCpqQuoteLine.Id, cpqQuote.Id, 100, 100, 1, productOption1, false);
            SBQQ__QuoteLine__c option2 = Utils_Test.createCPQOption(newCpqQuoteLine.Id, cpqQuote.Id, 100, 100, 1, productOption2, false);
            SBQQ__QuoteLine__c option3 = Utils_Test.createCPQOption(newCpqQuoteLine.Id, cpqQuote.Id, 100, 100, 1, productOption3, false);
            SBQQ__QuoteLine__c option4 = Utils_Test.createCPQOption(newCpqQuoteLine.Id, cpqQuote.Id, 100, 100, 1, productOption4, false);

            cpqOptionList.Add(option1);
            cpqOptionList.Add(option2);
            cpqOptionList.Add(option3);
            cpqOptionList.Add(option4);
            insert cpqOptionList;

            //System.debug('## insert newCpqQuoteLine :'+newCpqQuoteLine);
            List<CustomProductPictogram__c> customPictogramList = new List<CustomProductPictogram__c>();
            CustomProductPictogram__c customPictogram = new CustomProductPictogram__c(product__c = product2.Id,
                                                                                        leaf__c = '2',
                                                                                        pictogramFileLink__c = 'https://image-test',
                                                                                        productOptionLevel1__c = productOption1.Id);
            CustomProductPictogram__c customPictogram2 = new CustomProductPictogram__c(product__c = product2.Id,
                                                                                        leaf__c = '2',
                                                                                        pictogramFileLink__c = 'https://image-test',
                                                                                        productOptionLevel1__c = productOption1.Id,
                                                                                        productOptionLevel2__c = productOption2.Id);
            CustomProductPictogram__c customPictogram3 = new CustomProductPictogram__c(product__c = product2.Id,
                                                                                        leaf__c = '2',
                                                                                        pictogramFileLink__c = 'https://image-test',
                                                                                        productOptionLevel1__c = productOption1.Id,
                                                                                        productOptionLevel2__c = productOption2.Id,
                                                                                        productOptionLevel3__c = productOption3.Id);
            CustomProductPictogram__c customPictogram4 = new CustomProductPictogram__c(product__c = product2.Id,
                                                                                        leaf__c = '2',
                                                                                        pictogramFileLink__c = 'https://image-test',
                                                                                        productOptionLevel1__c = productOption1.Id,
                                                                                        productOptionLevel2__c = productOption2.Id,
                                                                                        productOptionLevel3__c = productOption3.Id,
                                                                                        productOptionLevel4__c = productOption4.Id);
            CustomProductPictogram__c customPictogram5 = new CustomProductPictogram__c(product__c = product.Id,
                                                                                        leaf__c = '2',
                                                                                        pictogramFileLink__c = 'https://image-test');
            CustomProductPictogram__c customPictogram6 = new CustomProductPictogram__c(product__c = product2.Id, pictogramFileLink__c = 'https://image-test');


            customPictogramList.Add(customPictogram);
            customPictogramList.Add(customPictogram2);
            customPictogramList.Add(customPictogram3);
            customPictogramList.Add(customPictogram4);
            customPictogramList.Add(customPictogram5);
            customPictogramList.Add(customPictogram6);                                                                        
            insert customPictogramList;
            System.debug('## insert customPictogram :'+customPictogram);
            try{
                LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(cpqQuote.Id, 'test', 'DIP');
            	Blob blobDIPC = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(cpqQuote.Id, 'test', 'DIP');
            	LWC_QuoteCPQGeneratePDF.linkDocumentToRecordForSignea(cpqQuote.Id, 'test', blobDIPC, 'DIP');
            } catch(Exception e) {
            	
        	} 
           

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUtils() {
        Test.startTest();
        LWC_QuoteCPQGeneratePDF.generateAuraException('TEST');
        Test.stopTest();
    }
     
}