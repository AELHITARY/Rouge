//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_InsertCreditMemoFromInvoiceLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/09/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_InsertCreditMemoFromInvoiceLine {

    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset','Carpentry');   

    @testSetup 
    static void setup() {
        
        //Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        //PropertiesUtils.setStringValue('invoice.emailtemplate.name', 'Facture_Email_de_la_facture_au_client');
        // Création d'un contact et des comptes
        //Contact contact = Utils_Test.createContact('Test','Test',true);
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        // Création entite      
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);
        
        Chantier__c chantier = Utils_Test.createChantier('', a.Id, null, null, null, a.Id, null, 4, true);
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
        
        Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', customerOrder.Id, prod.Id, a.Id, false);
        asset1.Quantity = 1;
        insert asset1;
        OrderItem ordItem = Utils_Test.createOrderItem(customerOrder.Id, priceBookEntry.Id, asset1.Id, prod.Id, false);
        ordItem.name__c = 'TestOrderItem';
        ordItem.VATRate__c = 10;
        insert ordItem;
        
        // Creation facture
        Invoice__c invoice = Utils_Test.createInvoice('Facture', a.Id, entite.Id, null, entite.Id, chantier.Id, false); 
        invoice.customerOrder__c = customerOrder.Id;
        invoice.VATRate1__c = 10;
        invoice.VATRate2__c = 10;
        invoice.VATRate3__c = 10;
        insert invoice;
        
        InvoiceLine__c invLine = new InvoiceLine__c(invoice__c = invoice.Id, quantity__c = 1, asset__c = asset1.Id, 
                                                    pretaxAmount__c = 90, orderItem__c = ordItem.Id, VATRate__c = 10, VATAmount__c = 80);
        insert invLine;
    }

    @isTest
    private static void test_IVInsertCreditMemoFromInvoiceLine(){

        IV_InsertCreditMemoFromInvoiceLine.FlowInputParameters[] inputList = new IV_InsertCreditMemoFromInvoiceLine.FlowInputParameters[]{};
            

        /* Preparing Flow Action input list */
        InvoiceLine__c invoiceLine = [SELECT Id FROM InvoiceLine__c LIMIT 1];
        system.debug('####invoiceLine.Id : ' + invoiceLine.Id);
        IV_InsertCreditMemoFromInvoiceLine.FlowInputParameters input1 = new IV_InsertCreditMemoFromInvoiceLine.FlowInputParameters();
        input1.invoiceLineId = invoiceLine.Id;
        
        inputList.add(input1);
        
        Test.startTest();
            IV_InsertCreditMemoFromInvoiceLine.insertCreditMemoFromInvoiceLine(inputList);
        Test.stopTest();

    }
}