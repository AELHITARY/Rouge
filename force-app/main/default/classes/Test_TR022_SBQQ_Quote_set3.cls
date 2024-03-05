/**
 * Created by 4C on 30/09/2020.
 *
 * @description Test class for amendments on quote (not running on 2020-10-07 because of soql limits
 */

@IsTest
public class Test_TR022_SBQQ_Quote_set3 {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private final static String BYPASS_TRIGGER = 'TR021_Chantier;TR022_Chantier;TR023_ChantierTR020_User;TR020_WorkOrder;' +
            'TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;TR023_SBQQ__Quote;TR022_Order;' +
            'TR022_OrderItem;TR022_Account;TR024_Account;TR001_Dedoublonnage;TR021_Opportunity;TR022_Opportunity;' +
            'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040;TR023_ChangeOwner;';

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
            quote.quoteIsValid__c = true;
            update quote;

            System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            quote.moyenTransmissionClient__c = 'Par email';
            quote.financingMethod__c = financialRef.Id;
            update quote;

            System.debug('  -> passage en vendu enregistré');
            // puis passage en vendu enregistré
            quote.dateTransmissionClient__c = Date.today();
            quote.dateAcceptationClient__c = Date.today();
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

            // Création de la commissions vendeur
            System.debug('Création de la commission vendeur');
            NRV10Commission__c comSales = new NRV10Commission__c();
            comSales.user__c = [SELECT Id FROM Collaborator__c WHERE user__c = :userSales.Id].Id;
            comSales.quoteCPQ__c = quote.Id;
            comSales.quoteLine__c = qli.Id;
            comSales.calculationDate__c = Date.today();
            comSales.comType__c = Constants.COMMISSION_TYPE_SALES;
            comSales.remuneration__c = 0.625;
            comSales.status__c = Constants.COMMISSION_STATUS_COMMISSIONED;
            comSales.initialCPQQuote__c = quote.Id;
            comSales.initialCPQQuoteLine__c = qli.Id;
            insert comSales;

            // Création de la commissions équipe
            System.debug('Création de la commission vendeur');
            NRV10Commission__c comTeam = new NRV10Commission__c();
            comTeam.user__c = [SELECT Id FROM Collaborator__c WHERE user__c = :userManager.Id].Id;
            comTeam.quoteCPQ__c = quote.Id;
            comTeam.quoteLine__c = qli.Id;
            comTeam.calculationDate__c = Date.today();
            comTeam.comType__c = Constants.COMMISSION_TYPE_TEAM;
            comTeam.remuneration__c = 0.01;
            comTeam.status__c = Constants.COMMISSION_STATUS_COMMISSIONED;
            comTeam.initialCPQQuote__c = quote.Id;
            comTeam.initialCPQQuoteLine__c = qli.Id;
            insert comTeam;

            // Création de la deuxieme commissions équipe
            System.debug('Création de la commission vendeur');
            NRV10Commission__c comTeam2 = new NRV10Commission__c();
            comTeam2.user__c = [SELECT Id FROM Collaborator__c WHERE user__c = :userManager.Id].Id;
            comTeam2.quoteCPQ__c = quote.Id;
            comTeam2.quoteLine__c = qli.Id;
            comTeam2.calculationDate__c = Date.today();
            comTeam2.comType__c = Constants.COMMISSION_TYPE_TEAM;
            comTeam2.remuneration__c = 0.00875;
            comTeam2.status__c = Constants.COMMISSION_STATUS_COMMISSIONABLE;
            comTeam2.initialCPQQuote__c = quote.Id;
            comTeam2.initialCPQQuoteLine__c = qli.Id;
            insert comTeam2;
        }
    }

    /**
     * Test qu'une commande avenant validée avec commandes client/founisseur validé est bien commissionnable,
     * que les commissions précédentes sont bien prises en compte et que la régularisation se fait bien.
     */
    @IsTest
    public static void testAmendmentQuote() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userManager = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c, ByPassTrigger__c FROM User WHERE Alias = 'manager1'];
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Pricebook2 pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test' LIMIT 1];
        PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Referencial__c financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT ];

        SBQQ.TriggerControl.disable();

        System.runAs(userManager) {
            UserContext.getContext().setByPassWorkflowRules(true);
            UserContext.getContext().setByPassValidationRules(true);

            List<Order> orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                    InitialQuote__c, amendmentQuote__c FROM Order WHERE SBQQ__Quote__c = :quote.Id];
            System.debug('Found ' + orders.size() + ' orders');
            System.assert(!orders.isEmpty(), 'No order found');

            Order ord = orders.get(0);

            Test.startTest();
            //****************************************
            //**** avenant
            //****************************************

            //create amendment quote
            SBQQ__Quote__c amendment = Utils_Test.createSBQQQuote(opp, userManager.Id, pBook.Id, priceBookEntry.Id, prod, false, ord, true);

            orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                    InitialQuote__c, amendmentQuote__c FROM Order WHERE amendmentQuote__c = :amendment.Id];
            System.debug('Found ' + orders.size() + ' orders');
            System.assert(!orders.isEmpty(), 'No order found');

            ord = orders.get(0);
            ord.SBQQ__Quote__c = quote.Id;
            update ord;
            System.debug('Updated order? ' + ord);

            // Passage en non transmis
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_NOT_TRANSMITTED;
            amendment.amendInitialQuote__c = quote.Id;
            amendment.previousQuote__c = quote.Id;
            update amendment;

            System.debug('  -> passage en transmis');
            // puis passage en transmie
            amendment.dateTransmissionClient__c = Date.today();
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            amendment.financingMethod__c = financialRef.Id;
            update amendment;

            amendment = [SELECT Id, MontantTotalTTC__c, SBQQ__CustomerAmount__c, SBQQ__ListAmount__c, opportunityOwner__c,
                    SBQQ__Status__c, AmendmentQuote__c, spilledCustomerOrder__c, commStatus__c, dateAcceptationClient__c,
                    ecartCotation__c, ecartCotationPercent__c, MontantTotalHTpostBP__c, SBQQ__DistributorDiscount__c, referenceDate__c,
                    dateTransmissionClient__c, OwnerId, financingMethod__r.Name, amendInitialQuote__c, previousQuote__c,
                    SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id = :amendment.Id]; // , techRemVRP__c

            List<SBQQ__QuoteLine__c> qlis = [SELECT Id, SBQQ__EffectiveQuantity__c, SBQQ__ListTotal__c, SBQQ__CustomerPrice__c,
                    SBQQ__ComponentListTotal__c, SBQQ__Product__c, SBQQ__PackageListTotal__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :amendment.Id];
            System.debug('amend quote line ids: ' + qlis);

            // Calcul de la commission vendeur
            System.debug('Lancement calculs comm');
            List<QuoteTransformer> quotes = new List<QuoteTransformer>{
                    new QuoteTransformer(amendment)
            };
            TR022_SBQQ_Quote_Commission.NRV10CommissionContext context = TR022_SBQQ_Quote_Commission.prepareContext(quotes);
            TR023_SBQQ_Quote_SalesCommission.processSalesCommissions(quotes, context);

            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            amendment.amendmentOrderApproved__c = true;
            amendment.techPB__c = false;
            update amendment;

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée car mauvais statut
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c, quantity__c,
                    remuneration__c, comType__c, quoteCPQ__c FROM NRV10Commission__c];
            System.assert(!commissions.isEmpty(), 'should have commissions');
            NRV10Commission__c salesCom1;
            NRV10Commission__c oldCom;
            NRV10Commission__c teamCom1;
            NRV10Commission__c oldTeamCom;
            NRV10Commission__c oldTeamCom2;
            for (NRV10Commission__c c : commissions) {
                System.debug(c);
                if (c.comType__c == Constants.COMMISSION_TYPE_SALES && c.quoteCPQ__c == amendment.Id && c.quantity__c == 1) salesCom1 = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_SALES && c.quoteCPQ__c == quote.Id) oldCom = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_TEAM && c.quoteCPQ__c == amendment.Id && c.quantity__c == 1) teamCom1 = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_TEAM && c.quoteCPQ__c == quote.Id && c.remuneration__c == 0.00875) oldTeamCom = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_TEAM && c.quoteCPQ__c == quote.Id && c.remuneration__c != 0.00875) oldTeamCom2 = c;
            }
            //System.assert(salesCom1 != null, 'Sales commission not found');
            //System.assertEquals(Constants.COMMISSION_STATUS_PREVISIONEL, salesCom1.status__c, 'wrong sales commission status');

            /*System.assert(oldCom != null, 'initial commission not found');
            System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONED, oldCom.status__c, 'wrong initial commission status');

            System.assert(teamCom1 != null, 'Sales commission not found');
            System.assertEquals(Constants.COMMISSION_STATUS_PREVISIONEL, teamCom1.status__c, 'wrong sales commission status');

            System.assert(oldTeamCom != null, 'initial commission not found');
            System.assertEquals(Constants.COMMISSION_STATUS_CANCELED, oldTeamCom.status__c, 'wrong team commission status');

            System.assert(oldTeamCom2 != null, 'initial commission2 not found');
            System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONED, oldTeamCom2.status__c, 'wrong team commission2 status');*/

            SBQQ.TriggerControl.enable();
        }
    }

}