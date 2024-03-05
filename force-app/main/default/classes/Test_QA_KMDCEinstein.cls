//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_KMDCEinstein
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/11/2022
//-- Version     : 1.0
//-- Description : Classe de tests pour QA_KMDCEinstein
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_QA_KMDCEinstein {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    private static final Id accEntityRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT);  
    
    private final static String BYPASS_TRIGGER = 'TR021_Chantier;TR022_Chantier;TR023_Chantier;TR020_User;TR020_WorkOrder;' +
            'TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;TR023_SBQQ__Quote;TR022_Order;' +
            'TR022_OrderItem;TR022_Account;TR024_Account;TR001_Dedoublonnage;TR021_Opportunity;TR022_Opportunity;' +
            'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040;TR023_ChangeOwner;';
    
    @testSetup 
    static void setup() {
        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
        a.RCSCity__c = 'Paris';
        a.RCSNumber__c = '12345';
        a.shareCapital__c = 12345;
        a.Ownership = 'SARL';
        insert a;
        // Création entite     
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        entite.Name = 'TEST';
        entite.RCSCity__c = 'Paris';
        entite.RCSNumber__c = '12345';
        entite.shareCapital__c = 12345;
        entite.Ownership = 'SARL';
        insert entite;

        // Création chantier et projet
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', a.Id,true);
        Opportunity opp = Utils_Test.createOpportunity(a, null, chantier,true);

        // Création cloture KparK
        List<CustomClosing__c> closList = new List<CustomClosing__c>();
        Datetime dstart = Datetime.newInstance(Date.today().year()-1,Date.today().month(),Date.today().day(),0,0,0);
        Datetime dend = Datetime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()+1,0,0,0);
        closList.add(new CustomClosing__c(businessStartDate__c = dstart, businessEndDate__c = dend,
                                            month__c = 2,
                                            quarter__c = 2,
                                            serviceStartDate__c = dstart, serviceEndDate__c = dend,
                                            weekOfMonth__c = 2,
                                            weekOfYear__c = 2,
                                            year__c = Date.today().year()));
        insert closList;

        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test2', 'FFFETTT', 'Fenetre', 'PVC', 50, 50, true);
        // Collaborateur
        Utils_Test.createCollaborator(null, 'TEST', 'VENDEUR', 'VENDEUR_MAG001TEST', false);
    }

    @isTest
    private static void testInvoice() {
        // Récupération des données de test
        Account a = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
        Account entite = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];

        Test.startTest();
        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        
        // Price book
        Pricebook2 pBook = new Pricebook2(Name ='Test');
        insert pBook;
        PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
        insert priceBookEntry;
        
        Order customerOrder = Utils_Test.createCustomerOrder(a.Id, false);
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
        invoice.publishedDate__c = Date.today();
        insert invoice;

        System.enqueueJob(new QA_KMDCEinstein('Invoice', new List<Sobject>{invoice}, null, null));

        Test.stopTest();
    }

    @isTest
    private static void testCreditMemo() {
        // Récupération des données de test
        Account a = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
        Account entite = [SELECT Id,KparKReference__c,Name FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];

        Test.startTest();

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
        insert ordItem;
        
        // Creation facture
        Invoice__c invoice = Utils_Test.createInvoice('Facture', a.Id, entite.Id, null, entite.Id, chantier.Id, false); 
        invoice.customerOrder__c = customerOrder.Id;
        invoice.seller__c = entite.Id;
        insert invoice;
        InvoiceLine__c invLine = new InvoiceLine__c(invoice__c = invoice.Id, quantity__c = 1, asset__c = asset1.Id, 
                                                    pretaxAmount__c = 90, orderItem__c = ordItem.Id);
        insert invLine; 
        // Creation avoir
        CreditMemo__c creditMemo = Utils_Test.createCreditMemo(a.Id, entite.Id, invoice.Id, chantier.Id, Date.today(), false); 
        creditMemo.customerOrder__c = customerOrder.Id;
        creditMemo.publishedDate__c = Date.today();        
        creditMemo.creditMemoReference__c = 'FAC/2023/XXXXX';
        insert creditMemo;
		
        // Création KFacture
        KFacture__c kfac = new KFacture__c(
            codeFacture__c = 'FAC/2023/XXXXX',
            typeFacture__c = true);
        insert kfac;
        System.enqueueJob(new QA_KMDCEinstein('CreditMemo', new List<Sobject>{creditMemo}, null, null));

        Test.stopTest();
    }

    @isTest
    private static void testQuoteCPQ() {
        // Récupération des données de test
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];

        Test.startTest();

        // Creation devis
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);

        // passage en non transmis
        cpqQuote.quoteIsValid__c = true;
        update cpqQuote;

        // puis passage en transmis
        cpqQuote.dateTransmissionClient__c = Date.today();
        cpqQuote.moyenTransmissionClient__c = 'Par email';
        update cpqQuote;

        // puis passage en vendu
        cpqQuote.dateAcceptationClient__c = Date.today();
        cpqQuote.SBQQ__Ordered__c = true;
        update cpqQuote;

        // Valid commande
        Order customerOrder = [SELECT Id FROM Order LIMIT 1];
        customerOrder.isValid__c = true;
        customerOrder.isInApprovalProcess__c = false;
        update customerOrder;

        List<Order> orderList = [SELECT Id FROM Order];
        System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));

        // Annulation        
        customerOrder.cancellingDate__c = Date.today();
        customerOrder.isReopen__c = false;
        update customerOrder;

        System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));

        // Réouverture
        customerOrder.cancellingDate__c = null;
        customerOrder.isReopen__c = true;
        update customerOrder;

        System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));

        QA_KMDCEinstein.getNumberFromCode('MAG0002');
        Test.stopTest();
    }

    @isTest
    private static void testAmendmentQuoteCPQ() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = BYPASS_TRIGGER;
        user.SGID__c = 'VENDEUR_MAG001TEST';
        update user;
        
        System.runAs(user){
            Test.startTest();
            // Récupération des données de test            
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE reference__c = 'FFFETTT' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
        
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :prod.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == prod.Id) pbEntry = pbeSelected;
            }

            // Collaborateur
            Collaborator__c collab = [SELECT Id, user__c, reference__c FROM Collaborator__c LIMIT 1];
            collab.user__c = user.Id;
            update collab;

            SBQQ.TriggerControl.disable();

            //Test.startTest();

            // Creation devis
            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);

            // passage en non transmis
            cpqQuote.quoteIsValid__c = true;
            update cpqQuote;

            // puis passage en transmis
            cpqQuote.dateTransmissionClient__c = Date.today();
            cpqQuote.moyenTransmissionClient__c = 'Par email';
            update cpqQuote;

            // puis passage en vendu
            cpqQuote.dateAcceptationClient__c = Date.today();
            cpqQuote.SBQQ__Ordered__c = true;
            update cpqQuote;
            
            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.SBQQ__Quote__c = cpqQuote.Id;
            insert customerOrder;
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, prod.Id, false);        
            oi.SBQQ__QuoteLine__c = cpqQuoteLine.Id;
            insert oi;

            // Valid commande
            customerOrder.isValid__c = true;
            customerOrder.isInApprovalProcess__c = false;
            customerOrder.SBQQ__Quote__c = cpqQuote.Id;
            update customerOrder;

            // TEST KMDC
            List<Order> orderList = [SELECT Id FROM Order];
            System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));

            // Avenant
            SBQQ__Quote__c cpqQuoteAv = Utils_Test.createCPQQuote(opp, Date.today(),1, false);
            cpqQuoteAv.amendInitialQuote__c = cpqQuote.Id;
            cpqQuoteAv.AmendmentQuote__c = true;
            insert cpqQuoteAv;
            SBQQ__QuoteLine__c cpqQuoteLine2 = Utils_Test.createCPQQuoteLineItem(cpqQuoteAv.Id ,100, 100, 2, prod, true);

            //MAJ
            customerOrder.amendmentQuote__c = cpqQuoteAv.Id;
            customerOrder.amending__c = true;
            update customerOrder;

            // Passage en non transmis
            cpqQuoteAv.SBQQ__Status__c = Constants.QUOTE_STATUS_NOT_TRANSMITTED;
            cpqQuoteAv.amendInitialQuote__c = cpqQuote.Id;
            cpqQuoteAv.previousQuote__c = cpqQuote.Id;
            cpqQuoteAv.amendmentQuote__c = true;
            update cpqQuoteAv;

            // puis passage en transmis
            cpqQuoteAv.dateTransmissionClient__c = Date.today();
            cpqQuoteAv.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            update cpqQuoteAv;

            System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));

            Test.stopTest();
        }
    }

    @isTest
    private static void testQuote() {
        // Récupération des données de test
        Account a = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Account entite = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];

        Test.startTest();

        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);
        
        // Price book
        Pricebook2 pBook = new Pricebook2(Name ='Test');
        insert pBook;
        PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
        insert priceBookEntry;

        // Creation devis
        Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, 'CCM', null, true);
        QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 1, 1.0, 1.0, prod, true);
        
        Order customerOrder = Utils_Test.createCustomerOrder(a.Id,false);
        customerOrder.QuoteId = quote.Id;
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
        
        OrderItem ordItem = Utils_Test.createOrderItem(customerOrder.Id, priceBookEntry.Id, null, prod.Id, true);

        // Valid commande
        customerOrder.isValid__c = true;
        update customerOrder;

        List<Order> orderList = [SELECT Id FROM Order];
        System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));

        // Annulation        
        customerOrder.cancellingDate__c = Date.today();
        customerOrder.isReopen__c = false;
        update customerOrder;

        System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));
        
        // Réouverture
        customerOrder.cancellingDate__c = null;
        customerOrder.isReopen__c = true;
        update customerOrder;

        System.enqueueJob(new QA_KMDCEinstein('Quote', orderList, null, null));
        
        QA_KMDCEinstein.getNumberFromCode('MAG0002');
        Test.stopTest();
    }
    @isTest
    private static void testCoverage() {
        // Récupération des données de test
        Account a = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
        Account entite = [SELECT Id, KparKReference__c, Name FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];

        Test.startTest();
        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        
        // Price book
        Pricebook2 pBook = new Pricebook2(Name ='Test');
        insert pBook;
        PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
        insert priceBookEntry;
        
        Order customerOrder = Utils_Test.createCustomerOrder(a.Id, false);
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
        invoice.publishedDate__c = Date.today();
        invoice.invoiceReference__c = 'FAC/2023/XXXX';
        //invoice.seller__c = entite.Id;
        insert invoice;
        
        // Création KFacture
        KFacture__c kfac = new KFacture__c(
            codeFacture__c = 'FAC/2023/XXXX',
            typeFacture__c = true);
        insert kfac;
		System.enqueueJob(new QA_KMDCEinstein('Invoice', new List<Sobject>{invoice}, null, null));
        
        QA_KMDCEinstein.getMaxDate(Date.newinstance(2023, 1, 1), Date.newinstance(2023, 2, 2));
        Test.stopTest();
    }
}