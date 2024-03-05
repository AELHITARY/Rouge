//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_InsertCreditMemoFromInvoice
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_InsertCreditMemoFromInvoice {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final String RT_INV_INVOICE = DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_INVOICE_RT); 
    private static final Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset','Carpentry');   

    @testSetup 
    static void setup() {
        Id RTDevNameReferencial = DAL.getRecordTypeIdByDevName('Referencial__c', 'CustomerCancellationReason');
        
        // Création ref   
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');
        List<Referencial__c> refList = new List<Referencial__c>();  
        Referencial__c ref = Utils_Test.createReferencial('ref','ref', Date.today(), Date.today(), RTDevNameReferencial, false, false, false, false, false);
        ref.KparKReference__c = PropertiesUtils.getStringValue('ref.motifAnnulationKparK.code', 'RSL-0016');
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, false);
        refList.add(ref);
        refList.add(refMag);
        insert refList;
        // Création compte/entité
        List<Account> accList = new List<Account>();        
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        accList.add(a);
        accList.add(entite);
        insert accList;
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('', a.Id, null, null, null, a.Id, null, 4, true);
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
        OrderItem ordItem = Utils_Test.createOrderItem(customerOrder.Id, priceBookEntry.Id, asset1.Id, prod.Id, false);
        ordItem.name__c = 'TestOrderItem';
        ordItem.VATRate__c = 10;
        ordItem.pretaxAmount__c = 500;
        ordItem.VATAmount__c = 500;
        ordItem.amount__c = 1000;
        insert ordItem;
        
        // Creation facture
        Invoice__c invoice  = Utils_Test.createInvoice('Facture', a.Id, entite.Id, null, entite.Id, chantier.Id, customerOrder.Id, RT_INV_INVOICE, true);
        InvoiceLine__c invLine = Utils_Test.createInvoiceLine(invoice.Id, null, asset1.Id, ordItem.Id, 'TEST2', 5,10, 1, false);
        invLine.pretaxAmount__c = 5;
        invLine.VATAmount__c = 5;
        invLine.amount__c = 10;
        insert invLine;
    }

    @isTest
    private static void test_IVInsertCreditMemoFromInvoice(){

        IV_InsertCreditMemoFromInvoice.FlowInputParameters[] inputList = new IV_InsertCreditMemoFromInvoice.FlowInputParameters[]{};
            

        /* Preparing Flow Action input list */
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        System.debug('####invoice.Id : ' + invoice.Id);
        IV_InsertCreditMemoFromInvoice.FlowInputParameters input1 = new IV_InsertCreditMemoFromInvoice.FlowInputParameters();
        input1.invoiceId = invoice.Id;
        
        inputList.add(input1);
        
        Test.startTest();
            IV_InsertCreditMemoFromInvoice.insertCreditMemoFromInvoice(inputList);
        Test.stopTest();

    }
}