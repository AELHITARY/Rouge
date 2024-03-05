/**
 * Created by 4C on 14/10/2020.
 */

@IsTest
public without sharing class Test_TR023_SBQQ_QuoteLine {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private final static String BYPASS_TRIGGER = 'TR021_Chantier;TR022_Chantier;TR023_ChantierTR020_User;TR020_WorkOrder;' +
            'TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;TR023_SBQQ__Quote;TR022_Order;' +
            'TR022_OrderItem;TR022_Account;TR024_Account;TR001_Dedoublonnage;TR021_Opportunity;TR022_Opportunity;' +
            'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040;TR023_ChangeOwner;' +
            'TR023_Order;TR023_SBQQ__Quote';

    @TestSetup
    static void testSetup() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        UserContext.getContext().setByPassWorkflowRules(true);
        UserContext.getContext().setByPassValidationRules(true);

        Utils_Test.createUser(false, 'manager1', 'manager1@test.remvrp.com', 'man', 'ager', null, null);
        User userSales = Utils_Test.createUser(false, 'Sales1', 'sales1@test.remvrp.com', 'sal', 'es', null, null);
        userSales.ByPassWorkflowRule__c = true;
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassTrigger__c = BYPASS_TRIGGER;
        update userSales;

        SBQQ.TriggerControl.disable();

        System.debug('Main user context : ' + UserContext.getContext());
        System.runAs(userSales) {
            UserContext.getContext().setByPassWorkflowRules(true);
            UserContext.getContext().setByPassValidationRules(true);
            System.debug('Run as user context : ' + UserContext.getContext());

            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);
            Product2 prod2 = Utils_Test.createProduct('Produit Test2', 'FFALU06_R', 'Fenetre', 'PVC', 50, 50, true);

            // Price book
            Pricebook2 pBook = new Pricebook2(Name = 'Test');
            insert pBook;
            PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
            PricebookEntry priceBookEntry2 = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod2.Id, IsActive = true);
            insert new List<PricebookEntry>{priceBookEntry, priceBookEntry2};

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
            System.debug('  -> quote.quoteIsValid__c : ' + quote.quoteIsValid__c);
            // puis passage en transmie
            quote.quoteIsValid__c = true;
            quote.dateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            quote.dateAcceptationClient__c = null;
            update quote;

            System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            quote.dateAcceptationClient__c = Date.today();
            quote.moyenTransmissionClient__c = 'Par email';
            quote.financingMethod__c = financialRef.Id;

            System.debug('  -> passage en vendu enregistré');
            // puis passage en vendu enregistré
            //quote.dateTransmissionClient__c = Date.today();
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
            //System.assert(!orders.isEmpty(), 'No order found');

            o.Status = Constants.ORDER_STATUS_CONFIRMED;
            o.isInApprovalProcess__c = false;
            o.isRefused__c = false;
            update o;

            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', magasinA.Id,true);
            Asset newAsset = new Asset(Name = 'Asset Test', customerOrder__c = o.Id, orderItem__c = oi.Id, AccountId = magasinA.Id, chantier__c = chantier.Id);
            insert newAsset;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);
        }
    }


    @IsTest
    static void testModifyAfterAmendment() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userSales = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c,
                ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];

        SBQQ.TriggerControl.disable();

        System.runAs(userSales) {
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Pricebook2 pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test' LIMIT 1];
            PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
            Order order = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                    InitialQuote__c, amendmentQuote__c, amending__c FROM Order LIMIT 1];
            OrderItem orderItem = [SELECT Id, OrderId, assetAmendableCount__c, locationPrecision__c,
                    height__c, width__c, leaf__c, UnitPrice, PricebookEntryId, SBQQ__QuotedQuantity__c,
                    Product2Id, SBQQ__QuoteLine__c, SBQQ__QuotedListPrice__c, SBQQ__RequiredBy__c
            FROM OrderItem WHERE OrderId = :order.Id];
            SBQQ__Quote__c oldQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            SBQQ__QuoteLine__c oldQuoteLine = [SELECT Id, CoefficientThermique__c, DateValiditeTarif__c,
                    ExcluBonusProjet__c, ExclusionPromo__c,  
                    IdPromotionRetenue__c, IndexParent__c,
                    SBQQ__Quantity__c, PrixUnitaireHTManuel__c, KBMAXSB__Id__c,
                    MethodePrixOption__c, NbTauxReduits__c, quoteLineLabelManual__c,
                    SBQQ__AdditionalDiscount__c, SBQQ__AdditionalQuantity__c, SBQQ__Bundle__c,
                    SBQQ__ComponentListTotal__c, SBQQ__SubscriptionScope__c, SBQQ__ComponentSubscriptionScope__c,
                    SBQQ__ComponentTotal__c, SBQQ__Discount__c, SBQQ__DistributorDiscount__c,
                    SBQQ__NonDiscountable__c, SBQQ__Number__c, SBQQ__OptionType__c, SBQQ__OriginalPrice__c,
                    SBQQ__PackageProductCode__c, SBQQ__PartnerDiscount__c, SBQQ__PartnerPrice__c,
                    SBQQ__PriceEditable__c, SBQQ__PricingMethod__c, SBQQ__ProductOption__c,
                    SBQQ__ProratedListPrice__c, SBQQ__ProratedPrice__c, SBQQ__RegularPrice__c,
                    SBQQ__SubscriptionBase__c, SBQQ__SubscriptionCategory__c, SBQQ__SubscriptionPercent__c,
                    SBQQ__AdditionalDiscountAmount__c,
                    SBQQ__ListPrice__c, SBQQ__PricingMethodEditable__c, SBQQ__RequiredBy__c, SBQQ__Bundled__c,
                    AssetAmendableCount__c
            FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :oldQuote.Id LIMIT 1];
            Referencial__c financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];

            Test.startTest();

            //create amendment quote
            SBQQ__Quote__c amendment = Utils_Test.createSBQQQuote(opp, userSales.Id, pBook.Id, priceBookEntry.Id, prod, false, order, true);

            // création de la nouvelle quoteline d'avenant
            SBQQ__QuoteLine__c ql = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :amendment.Id];
            ql.AmendedQLValidated__c = true;
            ql.AmendedOrderProduct__c = orderItem.Id;
            ql.AssetAmendableCount__c = orderItem.assetAmendableCount__c;
            ql.CoefficientThermique__c = oldQuoteLine.CoefficientThermique__c;
            ql.DateValiditeTarif__c = oldQuoteLine.DateValiditeTarif__c;
            ql.ExcluBonusProjet__c = oldQuoteLine.ExcluBonusProjet__c;
            ql.ExclusionPromo__c = oldQuoteLine.ExclusionPromo__c;
            ql.Hauteur__c = orderItem.height__c;
            ql.IdPromotionRetenue__c = oldQuoteLine.IdPromotionRetenue__c;
            ql.IndexParent__c = oldQuoteLine.IndexParent__c;
            ql.SBQQ__Quantity__c = oldQuoteLine.SBQQ__Quantity__c;
            ql.KBMAXSB__Id__c = oldQuoteLine.KBMAXSB__Id__c;
            ql.Largeur__c = orderItem.width__c;
            ql.MethodePrixOption__c = oldQuoteLine.MethodePrixOption__c;
            ql.NbTauxReduits__c = oldQuoteLine.NbTauxReduits__c;
            ql.NombreVantaux__c = orderItem.leaf__c;
            ql.quoteLineLabelManual__c = oldQuoteLine.quoteLineLabelManual__c;
            ql.PrixUnitaireHTManuel__c = oldQuoteLine.PrixUnitaireHTManuel__c;
            ql.SBQQ__Bundle__c = oldQuoteLine.SBQQ__Bundle__c;
            ql.SBQQ__ComponentListTotal__c = oldQuoteLine.SBQQ__ComponentListTotal__c;
            ql.SBQQ__ComponentSubscriptionScope__c = oldQuoteLine.SBQQ__ComponentSubscriptionScope__c;
            ql.SBQQ__ComponentTotal__c = oldQuoteLine.SBQQ__ComponentTotal__c;
            ql.SBQQ__NetPrice__c = orderItem.UnitPrice;
            ql.SBQQ__AdditionalDiscountAmount__c = oldQuoteLine.SBQQ__AdditionalDiscountAmount__c;
            ql.SBQQ__AdditionalQuantity__c = oldQuoteLine.SBQQ__AdditionalQuantity__c;
            ql.SBQQ__Discount__c = oldQuoteLine.SBQQ__Discount__c;
            ql.SBQQ__DistributorDiscount__c = oldQuoteLine.SBQQ__DistributorDiscount__c;
            ql.SBQQ__ListPrice__c = oldQuoteLine.SBQQ__ListPrice__c;
            ql.SBQQ__CustomerPrice__c = orderItem.UnitPrice;
            ql.SBQQ__NonDiscountable__c = oldQuoteLine.SBQQ__NonDiscountable__c;
            ql.SBQQ__Number__c = oldQuoteLine.SBQQ__Number__c;
            ql.SBQQ__OptionType__c = oldQuoteLine.SBQQ__OptionType__c;
            ql.SBQQ__OriginalPrice__c = oldQuoteLine.SBQQ__OriginalPrice__c;
            ql.SBQQ__PackageProductCode__c = oldQuoteLine.SBQQ__PackageProductCode__c;
            ql.SBQQ__PartnerPrice__c = oldQuoteLine.SBQQ__PartnerPrice__c;
            ql.SBQQ__PriceEditable__c = oldQuoteLine.SBQQ__PriceEditable__c;
            ql.SBQQ__PricebookEntryId__c = orderItem.PricebookEntryId;
            ql.SBQQ__PricingMethodEditable__c = oldQuoteLine.SBQQ__PricingMethodEditable__c;
            ql.SBQQ__PricingMethod__c = oldQuoteLine.SBQQ__PricingMethod__c;
            ql.SBQQ__ProductOption__c = oldQuoteLine.SBQQ__ProductOption__c;
            ql.SBQQ__Product__c = orderItem.Product2Id;
            ql.SBQQ__ProratedListPrice__c = oldQuoteLine.SBQQ__ProratedListPrice__c;
            ql.SBQQ__ProratedPrice__c = oldQuoteLine.SBQQ__ProratedPrice__c;
            ql.SBQQ__Quantity__c = oldQuoteLine.SBQQ__Quantity__c;
            ql.SBQQ__RegularPrice__c = oldQuoteLine.SBQQ__RegularPrice__c;
            ql.SBQQ__SubscriptionBase__c = oldQuoteLine.SBQQ__SubscriptionBase__c;
            ql.SBQQ__SubscriptionCategory__c = oldQuoteLine.SBQQ__SubscriptionCategory__c;
            ql.SBQQ__SubscriptionPercent__c = oldQuoteLine.SBQQ__SubscriptionPercent__c;
            ql.SBQQ__SubscriptionScope__c = oldQuoteLine.SBQQ__SubscriptionScope__c;
            if (orderItem.SBQQ__RequiredBy__c != null) ql.SBQQ__Bundled__c = true;

            update ql;

            // mise à jour order product pour prise en compte par le process
            orderItem.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
            orderItem.SBQQ__QuoteLine__c = ql.Id;
            update orderItem;

            System.debug('  -> passage en transmis');
            // puis passage en transmie
            amendment.DateTransmissionClient__c = Date.today();
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            amendment.quoteIsValid__c = true;
            update amendment;

            System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            amendment.DateAcceptationClient__c = Date.today();
            amendment.MoyenTransmissionClient__c = 'Par email';
            amendment.financingMethod__c = financialRef.Id;
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            amendment.techPB__c = false;
            amendment.amendmentOrderApproved__c = true;
            update amendment;

            //trigger runs here and launch the process

            Test.stopTest();

            OrderItem oItem = [SELECT Id, StatutDeRevision__c, SBQQ__QuoteLine__c FROM OrderItem WHERE SBQQ__QuoteLine__c = :ql.Id];
            //System.assert(oItem != null);
            //System.assertEquals(Constants.ORDERITEM_STATUTREVISION_UPDATED, oItem.StatutDeRevision__c);
        }
    }

    @IsTest
    static void testNewOrderProductAfterAmendment() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userSales = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c,
                ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Pricebook2 pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        Product2 prod2 = [SELECT Id FROM Product2 WHERE Name = 'Produit Test2'];
        PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id AND Product2Id = :prod.Id];
        PricebookEntry priceBookEntry2 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id AND Product2Id = :prod2.Id];
        Order order = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                InitialQuote__c, amendmentQuote__c, amending__c FROM Order LIMIT 1];
        OrderItem orderItem = [SELECT Id, OrderId, assetAmendableCount__c, locationPrecision__c,
                height__c, width__c, leaf__c, UnitPrice, PricebookEntryId, SBQQ__QuotedQuantity__c,
                Product2Id, SBQQ__QuoteLine__c, SBQQ__QuotedListPrice__c, SBQQ__RequiredBy__c
        FROM OrderItem WHERE OrderId = :order.Id];
        SBQQ__Quote__c oldQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Referencial__c financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];

        SBQQ.TriggerControl.disable();

        System.runAs(userSales) {

            Test.startTest();

            //create amendment quote
            SBQQ__Quote__c amendment = Utils_Test.createSBQQQuote(opp, userSales.Id, pBook.Id, priceBookEntry.Id, prod, false, order, false);
            order.amendingInProgress__c = true;
            order.Status = 'AmendmentInProgress';
            update order;

            // mise à jour order product pour prise en compte par le process
            orderItem.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
            update orderItem;

            // création de la nouvelle quoteline d'avenant
            SBQQ__QuoteLine__c ql = Utils_Test.createCPQQuoteLineItem(amendment.Id, 80, 110, 1, prod2, false);
            ql.SBQQ__PricebookEntryId__c = priceBookEntry2.Id;
            ql.AmendedQLValidated__c = true;
            ql.OrderProductCreated__c = false;
            ql.SBQQ__Quantity__c = 1;
            ql.SBQQ__CustomerPrice__c = 125.0;
            ql.SBQQ__ProratedListPrice__c = 125.0;
            ql.SBQQ__CarryoverLine__c = false;
            ql.SBQQ__Existing__c = false;
            ql.SBQQ__NetPrice__c = 125.0;

            insert ql;

            System.debug('  -> passage en transmis');
            // puis passage en transmie
            amendment.DateTransmissionClient__c = Date.today();
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            amendment.quoteIsValid__c = true;
            update amendment;

            System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            amendment.DateAcceptationClient__c = Date.today();
            amendment.MoyenTransmissionClient__c = 'Par email';
            amendment.financingMethod__c = financialRef.Id;
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            amendment.techPB__c = false;
            amendment.amendmentOrderApproved__c = true;
            update amendment;

            //trigger runs here and launch the process

            Test.stopTest();
        }
    }
}