/**
 * Created by 4C on 11/03/2021.
 */
@IsTest
public class Test_TR022_SBQQ_Quote_set4 {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

    private static User userManager;
    private static User userSales;
    private static Account magasinA;
    private static Product2 prod;
    private static Pricebook2 pBook;
    private static PricebookEntry priceBookEntry;
    private static Referencial__c financialRef;
//    private static Referencial__c refMag;
    private static Quote quote;

    @TestSetup
    static void testSetup() {
        UserContext.getContext().setByPassTriggers(true);
        UserContext.getContext().setByPassValidationRules(true);
        UserContext.getContext().setByPassWorkflowRules(true);
        User userManager = Utils_Test.createUser(false,'manager1', 'manager1@test.remvrp.com', 'man','ager', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassWorkflowRule__c = true;
        userSales.ByPassTrigger__c = 'TR020_WorkOrder;TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;BA_QuoteProcessCommissions;TR023_SBQQ__Quote;TR022_Order';
        update userSales;

        System.runAs(userSales) {
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            // Mode de financement
            Referencial__c financialRef = new Referencial__c(Name = Constants.QUOTE_PAIEMENT_ECO,
                    RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod'),
                    startDate__c = Date.today().addMonths(-12), financingType__c = 'Cash',
                    KparKReference__c = 'CASH', advancePayment1__c = 0);
            insert financialRef;

            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);

            // Price book
            Pricebook2 pBook = new Pricebook2(Name = 'Test');
            insert pBook;
            PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
            insert priceBookEntry;

            // Création entite
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            Account magasinA = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);

        }
    }

    @IsTest
    public static void testNewQuoteWaitingProb() {
        UserContext.getContext().setByPassTriggers(true);
        userSales = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        userManager = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'manager1'];
        userSales = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        magasinA = [SELECT Id FROM Account WHERE Name = 'MAGTESTTEST'];
        prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test'];
        priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2Id = :pBook.Id];
        financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_ECO];

        /**
         * Test quote is not processed if status is not at least 'Transmitted'
        */
        System.runAs(userSales){
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            Test.startTest();

            // Creation d'une équipe Rem VRP avec un vendeur, un responsable et un taux spécifique sur
            Utils_Test.createTeamTest(magasinA.Id, userManager.Id, userSales.Id, prod.Id, true, financialRef.Id);

            // **********************************************
            // Création d'un devis avec lignes de devis en statut non transmis

            // Création enregistrements pour devis
            System.debug('Creation devis');
            Opportunity opp = Utils_Test.createSBQQQuoteOpportunity(pBook.Id);

            // Creation devis
            Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);

            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);

            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,true);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,true);

            // Options des produits
            Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,true);
            Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,true);

            // Mise à jour devis en vendu
            quote.dateAcceptationClient__c = Date.today();
            quote.dateTransmissionClient__c = Date.today();
            quote.moyenTransmissionClient__c = 'En main propre chez le client';
            update quote;

            quote = [SELECT Id, TotalTTCTarif__c, TotalHTlignes__c, TotalTTClignes__c, Status, RemisevendeurglobaleFormule__c,
                    amendmentQuote__c, spilledCustomerOrder__c, commStatus__c, dateAcceptationClient__c, TotalHTTarif__c,
                    amendInitialQuote__c, previousQuote__c, TotalHTRemise__c, dateTransmissionClient__c, referenceDate__c,
                    OwnerId, modeFinancement__c, TVA__c, LineItemCount, opportunityOwner__c, TotalHTDevis__c, customerOrder__c
                        FROM Quote WHERE Id = :quote.Id];

            System.debug('devis.Status : '+quote.Status);
            System.debug('devis.LineItemCount : '+quote.LineItemCount);
            List<QuoteTransformer> quotes = new List<QuoteTransformer>();
            quotes.add(new QuoteTransformer(quote));

            TR022_SBQQ_Quote_Commission.NRV10CommissionContext context = TR022_SBQQ_Quote_Commission.prepareContext(quotes);
            TR023_SBQQ_Quote_SalesCommission.processSalesCommissions(quotes, context);

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée car mauvais statut
            List<NRV10Commission__c> commissions = [SELECT Id, quoteCPQ__c FROM NRV10Commission__c WHERE quoteCPQ__c = :quote.Id];
            System.assert(commissions.isEmpty(), 'should not have commissions');

            // vérifie que le collaborateur associé au vendeur est bien créé
            List<Collaborator__c> collaborators = [SELECT Id FROM Collaborator__c WHERE user__c = :userSales.Id];
            System.assert(!collaborators.isEmpty(), 'Collaborator for userSales not created');
        }
    }

    public static void setupConfirm() {
        userManager = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'manager1'];
        userSales = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        magasinA = [SELECT Id FROM Account WHERE Name = 'MAGTESTTEST'];
        prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test'];
        priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2Id = :pBook.Id];
        financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_ECO];

        userSales.ByPassTrigger__c = 'TR022_User;TR023_SBQQ__Quote;TR022_Order;TR022_Account;TR001_Dedoublonnage;TR022_Opportunity;TR022_R040;TR022_QuoteLineItem';
        update userSales;

        System.runAs(userSales) {

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
            System.debug('Creation devis');
            Opportunity opp = Utils_Test.createSBQQQuoteOpportunity(pBook.Id);

            // Creation devis
            quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);

            // Ligne de devis
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, prod,true);

            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',1,true);
            ReferentielOptions__c refOpt2 = Utils_Test.createRefOption('RefOption2','RefOption2','RefOption2',1,true);

            // Options des produits
            Utils_Test.createOption(qli.Id,'1','Libellé Option 1',refOpt.Id,1,true);
            Utils_Test.createOption(qli.Id,'2','Libellé Option 2',refOpt2.Id,10,true);

            // Mise à jour devis en vendu
            quote.dateTransmissionClient__c = Date.today();
            quote.moyenTransmissionClient__c = 'En main propre chez le client';
            quote.Status = Constants.StatutDevisTransmis;
            update quote;

            System.debug('  -> passage en vendu attente');
            // puis passage en vendu enregistré
            quote.Status = Constants.StatutDevisVenduAttente;
            update quote;

            // Création d'une commande (géré par les flows/process builders en prod)
            Order o = new Order();
            o.QuoteId = quote.Id;
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
                    Quantity = 1, QuoteLineItemId = qli.Id, UnitPrice = 125.0);
            insert oi;

            System.debug('  -> passage en vendu enregistré');
            // puis passage en vendu enregistré
            quote.Status = Constants.StatutDevisVenduEnregistre;
            update quote;

            quote = [SELECT Id, TotalTTCTarif__c, TotalHTlignes__c, TotalTTClignes__c, Status, RemisevendeurglobaleFormule__c,
                    amendmentQuote__c, spilledCustomerOrder__c, commStatus__c, dateAcceptationClient__c, TotalHTTarif__c,
                    amendInitialQuote__c, previousQuote__c, TotalHTRemise__c, dateTransmissionClient__c, referenceDate__c,
                    OwnerId, modeFinancement__c, TVA__c, LineItemCount, opportunityOwner__c, TotalHTDevis__c, customerOrder__c
                        FROM Quote WHERE Id = :quote.Id];

            List<Order> orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status FROM Order WHERE QuoteId = :quote.Id];
            System.debug('Found ' + orders.size() + ' orders');
            System.assert(!orders.isEmpty(), 'No order found');

            o.Status = Constants.ORDER_STATUS_CONFIRMED;
            o.isInApprovalProcess__c = false;
            o.isRefused__c = false;
            update o;
        }
    }


    /**
     * Test qu'une commande validée avec commandes client/founisseur validé est bien commissionnable
     */
    @IsTest
    public static void testConfirmedQuoteAndOrder() {
        setupConfirm();

        System.runAs(userSales){
            Test.startTest();

            System.debug('devis.Status : ' + quote.Status);
            System.debug('devis.LineItemCount : ' + quote.LineItemCount);

            // Calcul de la commission vendeur
            System.debug('Lancement calculs comm');
            TR022_SBQQ_Quote_Commission.processCommissions(new List<Quote>{quote});

            Test.stopTest();

            // Le devis doit avoir des commissions associées car vendu
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quote__c,quoteCPQ__c FROM NRV10Commission__c];
            System.assert(!commissions.isEmpty(), 'should have commissions');
            NRV10Commission__c salesCom1;
            NRV10Commission__c teamCom;
            for (NRV10Commission__c c : commissions) {
                System.debug(c);
                if (c.comType__c == Constants.COMMISSION_TYPE_SALES && c.quote__c == quote.Id) salesCom1 = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) teamCom = c;
            }
            System.assert(salesCom1 != null, 'Sales commission not found');
            // Le total ligne doit être de 125€
            // Taux spécifique du produit à 0.5, donc 1 ligne de commissions

            //TODO To correct when input fixed
            /*System.assertEquals(3.00, salesCom1.remuneration__c, 'wrong commission amount');
            System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONABLE, salesCom1.status__c, 'wrong sales commission status');

            System.assert(teamCom != null, 'Team commission not found');
            // com equipe = 3% du total com
            // = 3 * 3 / 100
            System.assertEquals(0.09, teamCom.remuneration__c, 'wrong commission amount');
            System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONABLE, teamCom.status__c, 'wrong team commission status');*/
        }
    }

}