/**
 * Created by 4C on 25/03/2021.
 */

@IsTest
public class Test_TR023_Order_Commission {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private final static String BYPASS_TRIGGER = 'TR021_Chantier;TR022_Chantier;TR023_ChantierTR020_User;TR020_WorkOrder;' +
            'TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;TR023_SBQQ__Quote;TR022_Order;' +
            'TR022_OrderItem;TR022_Account;TR024_Account;TR001_Dedoublonnage;TR021_Opportunity;TR022_Opportunity;' +
            'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040;TR023_ChangeOwner;TR020_Order;';

    @TestSetup
    static void setup() {
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
            
            // Creation provider acc
            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
            insert provider1;

            // Creation d'une équipe Rem VRP avec un vendeur, un responsable et un taux spécifique sur
            Utils_Test.createTeamTest(magasinA.Id, userManager.Id, userSales.Id, prod.Id, true, financialRef.Id);

            NRV10Calendar__c cal1 = new NRV10Calendar__c(commDate__c = Date.today().addMonths(-12));
            NRV10Calendar__c cal2 = new NRV10Calendar__c(commDate__c = Date.today().addMonths(12));
            insert new List<SObject>{
                    cal1, cal2
            };

            // **********************************************
            // Création d'un devis avec lignes de devis en statut non transmis

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
            quote.dateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            update quote;

            /*System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            quote.dateAcceptationClient__c = Date.today();
            quote.moyenTransmissionClient__c = 'Par email';
            quote.financingMethod__c = financialRef.Id;
            update quote;*/

            /*System.debug('  -> passage en vendu enregistré');
            // puis passage en vendu enregistré
            quote.dateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            update quote;*/

            // Création d'une commande (géré par les flows/process builders en prod)
            Order o = new Order();
            o.SBQQ__Quote__c = quote.Id;
            o.AccountId = magasinA.Id;
            o.Pricebook2Id = pBook.Id;
            o.EffectiveDate = Date.today();
            o.Status = Constants.ORDER_STATUS_REGISTERED;
            insert o;
            
            Order newProviderOrder1 = Utils_Test.createProviderOrder(magasinA.Id, o.Id, provider1.Id ,false);  
            newProviderOrder1.Pricebook2Id = pBook.Id;      
            insert newProviderOrder1;
            
            List<OrderItem> oiList = new List<OrderItem>();
            
            OrderItem oiProvider = new OrderItem(OrderId = newProviderOrder1.Id, PricebookEntryId = priceBookEntry.Id,
                    Product2Id = prod.Id, width__c = 80, height__c = 110, leaf__c = '2',
                    productType__c = 'Carpentry', confirmationDate__c = Date.today(), status__c = 'Confirmé',
                    SBQQ__QuotedQuantity__c = 1, SBQQ__QuoteLine__c = qli.Id, UnitPrice = 125.0, Quantity = 1);
            oiList.add(oiProvider);

            // link quote to order
            //quote.spilledCustomerOrder__c = o.Id;
            //update quote;

            OrderItem oi = new OrderItem(OrderId = o.Id, PricebookEntryId = priceBookEntry.Id,
                    Product2Id = prod.Id, width__c = 80, height__c = 110, leaf__c = '2',
                    productType__c = 'Carpentry',
                    SBQQ__QuotedQuantity__c = 1, SBQQ__QuoteLine__c = qli.Id, UnitPrice = 125.0, Quantity = 1);
            oiList.add(oi);
            insert oiList;

            /*List<Order> orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status FROM Order WHERE SBQQ__Quote__c = :quote.Id];
            System.debug('Found ' + orders.size() + ' orders');
            System.assert(!orders.isEmpty(), 'No order found');*/

            o.Status = Constants.ORDER_STATUS_CONFIRMED;
            o.isInApprovalProcess__c = false;
            o.isRefused__c = false;
            update o;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);
        }
    }

    @IsTest
    public static void testProcessCommission() {
        List<Order> orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status FROM Order];
        System.debug('Found ' + orders.size() + ' orders');
        System.assert(!orders.isEmpty(), 'No order found');

        Test.startTest();

        System.debug('set Order as Validated');
        orders[0].Status = Constants.ORDER_STATUS_VALIDATED;
        update orders[0];

        Test.stopTest();


        Id batchClassId = [SELECT Id FROM ApexClass WHERE Name = 'QA_QuoteProcessCommissions'].Id;

        List<AsyncApexJob> jobs = [
                SELECT Id, ApexClassId
                FROM AsyncApexJob
                WHERE ApexClassId = :batchClassId
        ];

        //should now contains the quote
        //System.assert(!jobs.isEmpty());
    }
}