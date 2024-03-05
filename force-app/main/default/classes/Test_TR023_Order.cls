/**
 * Created by 4C on 14/10/2020.
 */

@IsTest
public with sharing class Test_TR023_Order {

    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT);         
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService'); 
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private final static String BYPASS_TRIGGER = 'TR021_Chantier;TR022_Chantier;TR023_ChantierTR020_User;TR020_WorkOrder;' +
            'TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;TR023_SBQQ__Quote;TR022_Order;' +
            'TR022_OrderItem;TR022_Account;TR024_Account;TR001_Dedoublonnage;TR021_Opportunity;TR022_Opportunity;' +
            'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040;TR023_ChangeOwner;';

    @TestSetup
    static void testSetup() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        UserContext.getContext().setByPassWorkflowRules(true);
        UserContext.getContext().setByPassValidationRules(true);

        User userManager = Utils_Test.createUser(false, 'manager1', 'manager1@test.remvrp.com', 'man', 'ager', null, null);
        User userSales = Utils_Test.createUser(false, 'Sales1', 'sales1@test.remvrp.com', 'sal', 'es', null, null);
        userSales.ByPassWorkflowRule__c = true;
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassTrigger__c = BYPASS_TRIGGER;
        update userSales;

        SBQQ.TriggerControl.disable();

        System.debug('Main user context : ' + UserContext.getContext());
        System.runAs(userSales) {
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            UserContext.getContext().setByPassWorkflowRules(true);
            UserContext.getContext().setByPassValidationRules(true);
            System.debug('Run as user context : ' + UserContext.getContext());

            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);

            // Price book
            Pricebook2 pBook = new Pricebook2(Name = 'Test');
            insert pBook;
            PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
            insert priceBookEntry;

            // Mode de financement
            Referencial__c financialRef = new Referencial__c(Name = Constants.QUOTE_PAIEMENT_COMPTANT,
                    RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod'),
                    startDate__c = Date.today().addMonths(-12), financingType__c = 'Cash',
                    KparKReference__c = 'CASH', advancePayment1__c = 0);
            insert financialRef;

            // Création entite
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            Account magasinA = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);

            // Création enregistrements pour devis
            Opportunity opp = Utils_Test.createSBQQQuoteOpportunity(pBook.Id);

            // Creation devis
            SBQQ__Quote__c quote = Utils_Test.createSBQQQuote(opp, userSales.Id, pBook.Id, priceBookEntry.Id, prod);

            SBQQ__QuoteLine__c qli = [
                    SELECT Id, SBQQ__EffectiveQuantity__c, SBQQ__ListTotal__c, SBQQ__CustomerPrice__c,
                            SBQQ__ComponentListTotal__c, SBQQ__Product__c, SBQQ__PackageListTotal__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :quote.Id
            ];

            System.debug('Création du devis');
            // Passage en non transmis
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_NOT_TRANSMITTED;
            update quote;

            System.debug('  -> passage en transmis');
            // puis passage en transmie
            quote.DateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            update quote;

            System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            quote.DateAcceptationClient__c = Date.today();
            quote.MoyenTransmissionClient__c = 'Par email';
            quote.financingMethod__c = financialRef.Id;
            quote.quoteIsValid__c = true;
            //update quote;

            System.debug('  -> passage en vendu enregistré');
            // puis passage en vendu enregistré
            quote.DateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            update quote;

            // Création d'une commande (géré par les flows/process builders en prod)
            Order o = new Order();
            o.SBQQ__Quote__c = quote.Id;
            o.AccountId = magasinA.Id;
            o.Pricebook2Id = pBook.Id;
            o.EffectiveDate = Date.today();
            o.Status = Constants.ORDER_STATUS_REGISTERED;
            insert o;

            // link quote to order
            quote.spilledCustomerOrder__c = o.Id;
            update quote;

            OrderItem oi = new OrderItem(OrderId = o.Id, PricebookEntryId = priceBookEntry.Id,
                    Product2Id = prod.Id, width__c = 80, height__c = 110, leaf__c = '2',
                    productType__c = 'Carpentry',
                    SBQQ__QuotedQuantity__c = 1, SBQQ__QuoteLine__c = qli.Id, UnitPrice = 125.0, Quantity = 1);
            insert oi;

            List<Order> orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status FROM Order WHERE SBQQ__Quote__c = :quote.Id];
            System.debug('Found ' + orders.size() + ' orders');
            System.assert(!orders.isEmpty(), 'No order found');

            o.Status = Constants.ORDER_STATUS_CONFIRMED;
            o.isInApprovalProcess__c = false;
            o.isRefused__c = false;
            update o;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);
        }
    }

    @IsTest
    static void testOrderQuoteLineCreationTrigger() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :userInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userSales = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Pricebook2 pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test' LIMIT 1];
        PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        Order order = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                InitialQuote__c, amendmentQuote__c, amending__c FROM Order LIMIT 1];
        List<SBQQ__QuoteLine__c> oldQuoteLines = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c];

        Test.startTest();

        //create amendment quote
        SBQQ__Quote__c amendment = Utils_Test.createSBQQQuote(opp, userSales.Id, pBook.Id, priceBookEntry.Id, prod, false, order, false);

        Test.stopTest();

        //After trigger fires, should have a new
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :amendment.Id];
        System.assert(quoteLines != null);

        System.assertEquals(oldQuoteLines.get(0).SBQQ__Quantity__c, quoteLines.get(0).SBQQ__Quantity__c);
    }
    
    @IsTest
    static void testOrderStatutGC() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :userInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userSales = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Pricebook2 pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test' LIMIT 1];
        PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        Order order = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                InitialQuote__c, amendmentQuote__c, amending__c FROM Order LIMIT 1];
        List<SBQQ__QuoteLine__c> oldQuoteLines = [SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c];
        Account a = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];

        Test.startTest();

        //create asset
        Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', order.Id, prod.Id, opp.AccountId, false);
        asset1.customerOrder__c = order.Id;
        asset1.chantier__c = opp.chantier__c;
        insert asset1;
        Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, a, null, opp.chantier__c, false);
        case1.AssetId=asset1.Id;
        case1.diagnosticDate__c = Date.today();
        case1.inStock__c = true;
        case1.requiredOrder__c = Constants.NCP_REQUIREDORDER_RECOMMANDE;
        insert case1;

        // Creation Rendez-vous
        List<WorkType> wkLlist = new List<WorkType>();
        WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
        WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
        WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
        wkLlist.add(wt1);
        wkLlist.add(wt2);
        wkLlist.add(wt3);
        insert wkLlist;

        WorkOrder wo = Utils_Test.createWorkOrder(wkRTId, false);
        wo.customerOrder__c = order.Id;
        wo.WorkTypeId = wt1.Id;
        insert wo;
        
        ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, SASARTId, false);
        sa1.Status='En cours';
        sa1.customerOrder__c = order.Id;
        sa1.ActualStartTime=Date.today();
        sa1.fsl_dateConfirmation__c=Date.today();
        sa1.dateConfirmationClient__c=Date.today();
        sa1.SchedEndTime=Date.today();
        sa1.SchedStartTime=Date.today();
        insert sa1;
        
        WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, asset1.Id, false);
        insert woli;
        
        System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{order.Id}));

        asset1.controldate__c=Date.today();
        update asset1;

        /*Order newProviderOrder1 = Utils_Test.createProviderOrder(a.Id, ord.Id, provider1.Id ,false);
        insert newProviderOrder1;*/

        System.enqueueJob(new QA_UpdateOrderStatusGC(new Set<Id>{order.Id}));

        Test.stopTest();
    }
}