//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_CreateAndSendInvoice
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 14/04/2021
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_CreateAndSendInvoice {
    
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT);     

    @testSetup 
    static void setup() {
        
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setStringValue('invoice.emailtemplate.name', 'Facture_Email_de_la_facture_au_client');
        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        // Création entite      
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);
        
        Chantier__c chantier = Utils_Test.createChantier('TESTCHA', a.Id, null, null, null, a.Id, null, 4, true);
        Account entite = Utils_Test.createEntity('TEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);
        
        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        
        // Price book
        Pricebook2 pBook = new Pricebook2(Name ='Test');
        insert pBook;
        PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
        insert priceBookEntry;
        
        Order customerOrder = Utils_Test.createCustomerOrder(a.Id,false);
        //customerOrder.QuoteId = quote.Id;
        customerOrder.Pricebook2Id = pBook.Id;
        customerOrder.salesEntity__c = entite.Id;
        customerOrder.serviceEntity__c = entite.Id;
        customerOrder.chantier__c = chantier.Id;
        customerOrder.accountId = a.Id;
        customerOrder.billingCity = 'Paris';
        customerOrder.billingName__c = a.Id;
        customerOrder.billingPostalCode = '75000';
        customerOrder.shippingCity = 'Paris';
        customerOrder.ShippingPostalCode = '75000';
        customerOrder.shippingName__c = 'TEST';
        insert customerOrder;
        
        Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', customerOrder.Id, prod.Id, a.Id, true);
        OrderItem ordItem = Utils_Test.createOrderItem(customerOrder.Id, priceBookEntry.Id, asset1.Id, prod.Id, false);
        ordItem.name__c = 'TestOrderItem';
        insert ordItem;
        
        // Creation facture
        Invoice__c invoice = Utils_Test.createInvoice('Facture', a.Id, entite.Id, Date.today(), entite.Id, chantier.Id, false); 
        invoice.customerOrder__c = customerOrder.Id;
        insert invoice; 
    }

    @isTest
    private static void test_IVCreateAndSendInvoice(){

        IV_CreateAndSendInvoice.FlowInputParameters[] inputList = new IV_CreateAndSendInvoice.FlowInputParameters[]{};
            
        /* Testing Exception */
        IV_CreateAndSendInvoice.FlowInputParameters invalidInput = new IV_CreateAndSendInvoice.FlowInputParameters();
        invalidInput.recordId = '';
        invalidInput.docType = 'Facture';
        inputList.add(invalidInput);
        //EmailTemplate emailTemplate = new EmailTemplate(Name = 'TestTemplate', DeveloperName = 'Facture_Email_de_la_facture_au_client', TemplateType = 'custom', FolderId = '00lD0000001hPM1IAM');
		//insert emailTemplate;
        
        try {
            IV_CreateAndSendInvoice.createAndSendInvoice(inputList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.assert(e.getMessage().contains('Le paramètre recordId est vide'));
        }
        
        inputList.clear();

        /* Preparing Flow Action input list */
        Invoice__c fac = [SELECT Id FROM Invoice__c LIMIT 1];
        IV_CreateAndSendInvoice.FlowInputParameters input1 = new IV_CreateAndSendInvoice.FlowInputParameters();
        input1.recordId = fac.Id;
        invalidInput.docType = 'Facture';
        
        inputList.add(input1);
        
        Test.startTest();
            IV_CreateAndSendInvoice.createAndSendInvoice(inputList);
        Test.stopTest();

    }
}