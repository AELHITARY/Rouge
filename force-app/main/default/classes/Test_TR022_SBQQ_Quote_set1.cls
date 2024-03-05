/**
 * Created by 4C on 02/09/2020.
 *
 * @description Test class for initial case and bonus
 */

@IsTest
public with sharing class Test_TR022_SBQQ_Quote_set1 {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

    @IsTest
    public static void testNewQuoteWaitingProb() {

        Test.startTest();        
        UserContext.getContext().setByPassTriggers(true);
        User userManager = Utils_Test.createUser(false,'manager1', 'manager1@test.remvrp.com', 'man','ager', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassWorkflowRule__c = true;
        userSales.ByPassTrigger__c = 'TR020_WorkOrder;TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;BA_QuoteProcessCommissions;TR023_SBQQ__Quote;TR022_Order';
        update userSales;

        /**
         * Test quote is not processed if status is not at least 'Transmitted'
        */
        System.runAs(userSales){
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            

            // Mode de financement
            Referencial__c financialRef = new Referencial__c(Name = 'Comptant',
                    RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod'),
                    startDate__c = Date.today().addMonths(-12), financingType__c = 'Cash',
                    KparKReference__c = 'CASH', advancePayment1__c = 0);
            insert financialRef;

            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            // Price book
            Pricebook2 pBook = new Pricebook2(Name ='Test');
            insert pBook;
            PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
            insert priceBookEntry;

            // Création entite
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            Account magasinA = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);

            // Creation d'une équipe Rem VRP avec un vendeur, un responsable et un taux spécifique sur
            Utils_Test.createTeamTest(magasinA.Id, userManager.Id, userSales.Id, prod.Id, true, financialRef.Id);

            // **********************************************
            // Création d'un devis avec lignes de devis en statut non transmis

            // Création enregistrements pour devis
            System.debug('Creation devis');
            Opportunity opp = Utils_Test.createSBQQQuoteOpportunity(pBook.Id);
            opp.OwnerId = userSales.Id;
            update opp;

            // Creation devis
            SBQQ__Quote__c quote = Utils_Test.createCPQQuote(opp,Date.today(),0,false);
            quote.SBQQ__ExpirationDate__c = Date.today().addDays(14);
            quote.OwnerId = userSales.Id;
            insert quote;

            // Ligne de devis
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(quote.Id,30, 100, 2, prod,true);

            // Options des produits
            Utils_Test.createCPQOption(qli.Id,quote.Id,30, 100, 2, prod,true);
            Utils_Test.createCPQOption(qli.Id,quote.Id,30, 100, 2, prod,true);

            quote.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update quote;

            System.debug('devis.Status : '+quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : '+quote.SBQQ__LineItemCount__c);
            List<QuoteTransformer> quotes = new List<QuoteTransformer>();
            quotes.add(new QuoteTransformer(quote));

            // Création d'une commande (géré par les flows/process builders en prod)
            Order o = Utils_Test.createCustomerOrder(opp.AccountId, null, null, null, false);
            o.SBQQ__Quote__c = quote.Id;
            o.AccountId = opp.AccountId;
            o.Pricebook2Id = pBook.Id;
            o.EffectiveDate = Date.today();
            o.Status = Constants.ORDER_STATUS_REGISTERED;
            insert o;
            Map<Id, List<Order>> orderMap = new Map<Id, List<Order>>();
            List<Order> orList = new List<Order>();
            orList.add(o);
            orderMap.put(quote.Id, orList);

            TR022_SBQQ_Quote_Commission.NRV10CommissionContext context = TR022_SBQQ_Quote_Commission.prepareContext(quotes);
            context.ownerIds.add(userSales.Id);
            context.oppOwnerIds.add(userSales.Id);
            context.quoteInfos = quotes;
            context.quoteOrdersMap = orderMap;
            TR023_SBQQ_Quote_SalesCommission.processSalesCommissions(quotes, context);


            // Le devis ne doit pas avoir de commission associée car mauvais statut
            /*List<NRV10Commission__c> commissions = [SELECT Id FROM NRV10Commission__c WHERE quoteCPQ__c = :quote.Id];
            System.assert(commissions.isEmpty(), 'should not have commissions');

            // vérifie que le collaborateur associé au vendeur est bien créé
            List<Collaborator__c> collaborators = [SELECT Id FROM Collaborator__c WHERE user__c = :userSales.Id];
            System.assert(!collaborators.isEmpty(), 'Collaborator for userSales not created');*/
        }

        Test.stopTest();
    }

    /**
     * Test que les commissions previsionnelles sont crées sur une quote en statut Transmis
     */
    @IsTest
    public static void testBonusCalculation() {
        Test.startTest();

        User userManager = Utils_Test.createUser(false,'manager1', 'manager1@test.remvrp.com', 'man','ager', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassWorkflowRule__c = true;
        userSales.ByPassTrigger__c = 'TR020_WorkOrder;TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;BA_QuoteProcessCommissions;TR023_SBQQ__Quote;TR022_Order';
        userSales.sgid__c = 'sl1';
        update userSales;

        System.runAs(userSales){
            System.debug(' user context: ' + UserContext.getContext());

            Date twoMonthsBack = Date.today().addDays(5).addMonths(-2);
            Date oneMonthsBack = Date.today().addDays(5).addMonths(-1);
            Date nextMonthsBack = Date.today().addDays(5);

            // Mode de financement
            Referencial__c financialRef = new Referencial__c(Name = 'Comptant',
                    RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod'),
                    startDate__c = Date.today().addMonths(-12), financingType__c = 'Cash',
                    KparKReference__c = 'CASH', advancePayment1__c = 0);
            insert financialRef;

            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);

            // Price book
            Pricebook2 pBook = new Pricebook2(Name ='Test');
            insert pBook;
            PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
            insert priceBookEntry;

            // Création entite
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            Account magasinA = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);

            // Creation d'une équipe Rem VRP avec un vendeur, un responsable et un taux spécifique sur
            Utils_Test.createTeamTest(magasinA.Id, userManager.Id, userSales.Id, prod.Id, true, financialRef.Id);
            NRV10Calendar__c cal1 = new NRV10Calendar__c(commDate__c = twoMonthsBack);
            NRV10Calendar__c cal2 = new NRV10Calendar__c(commDate__c = oneMonthsBack);
            NRV10Calendar__c cal3 = new NRV10Calendar__c(commDate__c = nextMonthsBack);
            insert new List<SObject>{cal1, cal2, cal3};

            Id salesId = [SELECT Id FROM Collaborator__c WHERE user__c = :userSales.Id].Id;

            // Création d'un historique de commissions/CA suffisemment ancien pour permettre un calcul de bonus
            KMDC__c k1 = new KMDC__c(SGID__c = 'sl1', dateStats__c = twoMonthsBack.addDays(4), montantHT__c = 85.00, IDTiers__c = 'idt1');
            KMDC__c k2 = new KMDC__c(SGID__c = 'sl1', dateStats__c = twoMonthsBack.addDays(20), montantHT__c = 15.00, IDTiers__c = 'idt2');

            // Création d'un historique CA qui ne doit pas être pris en compte dans le calcul
            KMDC__c k3 = new KMDC__c(SGID__c = 'sl1', dateStats__c = oneMonthsBack.addDays(10), montantHT__c = 100.00, IDTiers__c = 'idt2');

            // Création d'une commission donnant lieu à un bonus
            NRV10Commission__c com3 = new NRV10Commission__c(user__c = salesId, status__c = Constants.COMMISSION_STATUS_COMMISSIONABLE,
                    comType__c = Constants.COMMISSION_TYPE_SALES, remuneration__c = 590.00,
                    calculationDate__c = oneMonthsBack, store__c = magasinA.Id);
            List<SObject> newCom = new List<SObject>{k1, k2, com3};
            insert newCom;

             // Création enregistrements pour devis
            System.debug('Creation devis');
            Opportunity opp = Utils_Test.createSBQQQuoteOpportunity(pBook.Id);
            opp.OwnerId = userSales.Id;
            update opp;

            // Creation devis
            SBQQ__Quote__c quote = Utils_Test.createCPQQuote(opp,Date.today(),0,false);
            quote.SBQQ__ExpirationDate__c = Date.today().addDays(14);
            quote.OwnerId = userSales.Id;
            insert quote;

            // Ligne de devis
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(quote.Id,30, 100, 2, prod,true);

            // Options des produits
            Utils_Test.createCPQOption(qli.Id,quote.Id,30, 100, 2, prod,true);
            Utils_Test.createCPQOption(qli.Id,quote.Id,30, 100, 2, prod,true);

            quote.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update quote;

            System.debug('devis.Status : '+quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : '+quote.SBQQ__LineItemCount__c);
            List<QuoteTransformer> quotes = new List<QuoteTransformer>();
            quotes.add(new QuoteTransformer(quote));

            TR022_SBQQ_Quote_Commission.NRV10CommissionContext ctx = new TR022_SBQQ_Quote_Commission.NRV10CommissionContext();
            ctx.ownerIds.add(userSales.Id);
            ctx.oppOwnerIds.add(userSales.Id);
            ctx.quoteInfos = quotes;
            //init the context for collaborators (quotes are not necessary for bonus)
            TR022_SBQQ_Quote_Commission.fillCollaboratorContext(ctx);

            TR023_SBQQ_Quote_BonusCommission.processBonusCommissions(ctx);


            // Le devis ne doit pas avoir de commission associée car mauvais statut
            /*
            List<NRV10Commission__c> commissions = [SELECT Id, remuneration__c FROM NRV10Commission__c WHERE user__c = :salesId AND comType__c = :Constants.COMMISSION_TYPE_BONUS];
            System.assert(!commissions.isEmpty(), 'should have commissions');
            // Le montant du bonus devrait être de 15€ car le cliché M-2 démarre à 100€, 590-100=490 donc un seul palier de franchi
            System.assertEquals(15.0,commissions.get(0).remuneration__c, 'Wrong bonus amount');
            */
        }

        Test.stopTest();

    }
}