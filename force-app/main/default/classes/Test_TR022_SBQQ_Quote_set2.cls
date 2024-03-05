/**
 * Created by 4C on 07/10/2020.
 *
 * @description Test class for basic quote cases and no commission cases
 */

@IsTest
public with sharing class Test_TR022_SBQQ_Quote_set2 {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static User userManager;
    private static User userSales;
    private static Account magasinA;
    private static Product2 prod;
    private static Pricebook2 pBook;
    private static PricebookEntry priceBookEntry;
    private static Opportunity opp;
    private static Referencial__c financialRef;
    private static Referencial__c refMag;
    private static Id collabSaleId;
    private static Id collabMgrId;
    private static NRV10Team__c team;
    private static SBQQ__Quote__c quote;
    private static SBQQ__QuoteLine__c qli;

    @TestSetup
    static void testSetup() {
        UserContext.getContext().setByPassTriggers(true);
        UserContext.getContext().setByPassValidationRules(true);
        UserContext.getContext().setByPassWorkflowRules(true);
        User userManager = Utils_Test.createUser(false,'manager1', 'manager1@test.remvrp.com', 'man','ager', null, null);
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassWorkflowRule__c = true;
        userSales.ByPassTrigger__c = 'TR020_WorkOrder;TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;BA_QuoteProcessCommissions;TR023_SBQQ__Quote;TR022_Order;TR022_ContentVersion';
        update userSales;

        System.runAs(userSales) {
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            // Mode de financement
            Referencial__c financialRef = new Referencial__c(Name = Constants.QUOTE_PAIEMENT_COMPTANT,
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

    /**
     * @description Allow creation of a context with options, and load objects generated in setup
     *
     * @param withRemVrp if true, create a team RemVrp
     * @param withContract if true, create an employment contract for the sales
     * @param withQuotelines if true, create a quoteline for the quote
     * @param assignQuoteToDV if true, assign the quote to manager with role DV, if false, assign it to user sales
     */
    static void setupConfigurableContext(Boolean withRemVrp, Boolean withContract, Boolean withQuotelines, Boolean assignQuoteToDV) {
        userManager = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'manager1'];
        userSales = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        magasinA = [SELECT Id FROM Account WHERE Name = 'MAGTESTTEST'];
        prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test'];
        priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2Id = :pBook.Id];
        financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];

        System.runAs(userSales) {
            // Creation d'une équipe Rem VRP avec un vendeur, un responsable et un taux spécifique sur
            if (withRemVrp) Utils_Test.createTeamTest(magasinA.Id, userManager.Id, userSales.Id, prod.Id, withContract, financialRef.Id);
            NRV10Calendar__c cal1 = new NRV10Calendar__c(commDate__c = Date.today().addMonths(-12));
            NRV10Calendar__c cal2 = new NRV10Calendar__c(commDate__c = Date.today().addMonths(12));
            insert new List<SObject>{
                    cal1, cal2
            };

            // Création enregistrements pour devis
            opp = Utils_Test.createSBQQQuoteOpportunity(pBook.Id);
            opp.OwnerId = userManager.Id;
            update opp;

            // Creation devis
            quote = Utils_Test.createSBQQQuote(opp, assignQuoteToDV ? userManager.Id : userSales.Id, pBook.Id, priceBookEntry.Id, prod, true, null, withQuotelines);
        }
    }


    /**
     * Test que les commissions previsionnelles sont crées sur une quote en statut Transmis
     */
    @IsTest
    public static void testNewQuoteTransmitted() {
        UserContext.getContext().setByPassTriggers(true);
        UserContext.getContext().setByPassValidationRules(true);
        UserContext.getContext().setByPassWorkflowRules(true);

        setupConfigurableContext(true, true, true, false);

        System.runAs(userSales){
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            Test.startTest();

            SBQQ__QuoteLine__c qli = [SELECT Id, SBQQ__EffectiveQuantity__c, SBQQ__ListTotal__c, SBQQ__CustomerPrice__c,
                    SBQQ__ComponentListTotal__c, SBQQ__Product__c, SBQQ__PackageListTotal__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];

            // Contrôle que les formules ont bien été appliquées
            System.assertEquals(375.00, quote.MontantTotalTTC__c);
            System.assertEquals(375.00, quote.SBQQ__CustomerAmount__c);
            System.assertEquals(375.00, quote.SBQQ__ListAmount__c);
            System.assertEquals(3, qli.SBQQ__EffectiveQuantity__c);
            System.assertEquals(375.00, qli.SBQQ__ListTotal__c);
            System.assertEquals(375.00, qli.SBQQ__PackageListTotal__c);

            // Passage en non transmis
            quote.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update quote;

            // puis passage en transmie
            quote.DateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.StatutDevisTransmis;
            update quote;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);

            //System.debug('devis.ReferenceDate : ' + quote.referenceDate__c);
            //System.debug('devis.dateAcceptationClient : ' + quote.dateAcceptationClient__c);

            // Calcul de la commission vendeur
            TR022_SBQQ_Quote_Commission.processCommissions(new List<SBQQ__Quote__c>{quote});

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée car mauvais statut
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quoteCPQ__c FROM NRV10Commission__c];
            //System.assert(!commissions.isEmpty(), 'should have commissions');
            NRV10Commission__c salesCom1;
            NRV10Commission__c teamCom;
            for (NRV10Commission__c c : commissions) {
                System.debug(c);
                if (c.comType__c == Constants.COMMISSION_TYPE_SALES && c.quoteCPQ__c == quote.Id) salesCom1 = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) teamCom = c;
            }
            /*System.assert(salesCom1 != null, 'Sales commission not found');
            // Le total ligne doit être de 125€
            // Taux spécifique du produit à 0.5, donc 1 ligne de commissions
            // rem = 125 * 0.5 * 100 / 10000
            System.assertEquals(1.875, salesCom1.remuneration__c, 'wrong commission amount');
            System.assertEquals(Constants.COMMISSION_STATUS_PREVISIONEL, salesCom1.status__c, 'wrong sales commission status');

            System.assert(teamCom != null, 'Team commission not found');
            // com equipe = 10% du total com
            // = 0.625 * 3 / 100
            System.assertEquals(0.05625, teamCom.remuneration__c, 'wrong commission amount');
            System.assertEquals(Constants.COMMISSION_STATUS_PREVISIONEL, teamCom.status__c, 'wrong team commission status');*/
        }
    }


    /**
     * Test que les commissions ne sont pas générées si le collaborateur n'a pas de contrat de rémunération
     */
    @IsTest
    public static void testNewQuoteTransmittedCollabNoContract() {
        UserContext.getContext().setByPassTriggers(true);
        UserContext.getContext().setByPassValidationRules(true);
        UserContext.getContext().setByPassWorkflowRules(true);

        setupConfigurableContext(true, false, true, false);

        System.runAs(userSales){
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            Test.startTest();

            SBQQ__QuoteLine__c qli = [SELECT Id, SBQQ__EffectiveQuantity__c, SBQQ__ListTotal__c, SBQQ__CustomerPrice__c,
                    SBQQ__ComponentListTotal__c, SBQQ__Product__c, SBQQ__PackageListTotal__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];

            // Contrôle que les formules ont bien été appliquées
//            System.assertEquals(375.00, quote.MontantTotalTTC__c);
            System.assertEquals(375.00, quote.MontantTotalHTpostBP__c);
            System.assertEquals(375.00, quote.SBQQ__CustomerAmount__c);
            System.assertEquals(375.00, quote.SBQQ__ListAmount__c);
            System.assertEquals(3, qli.SBQQ__EffectiveQuantity__c);
            System.assertEquals(375.00, qli.SBQQ__ListTotal__c);
            System.assertEquals(375.00, qli.SBQQ__PackageListTotal__c);

            // Passage en non transmis
            quote.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update quote;

            // puis passage en transmie
            quote.dateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.StatutDevisTransmis;
            update quote;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);

            // Calcul de la commission vendeur
            TR022_SBQQ_Quote_Commission.processCommissions(new List<SBQQ__Quote__c>{quote});

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quoteCPQ__c FROM NRV10Commission__c];
            System.assert(commissions.isEmpty(), 'should not have commissions');
        }
    }


    /**
     * Test que les commissions ne sont pas générées s'il n'y a pas de contrat sur la période de signature
     */
    @IsTest
    public static void testNewQuoteTransmittedCollabNoContractOnPeriod() {
        UserContext.getContext().setByPassTriggers(true);
        UserContext.getContext().setByPassValidationRules(true);
        UserContext.getContext().setByPassWorkflowRules(true);

        setupConfigurableContext(true, true, true, false);

        System.runAs(userSales){
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            Test.startTest();

            SBQQ__QuoteLine__c qli = [SELECT Id, SBQQ__EffectiveQuantity__c, SBQQ__ListTotal__c, SBQQ__CustomerPrice__c,
                    SBQQ__ComponentListTotal__c, SBQQ__Product__c, SBQQ__PackageListTotal__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];

            // Contrôle que les formules ont bien été appliquées
            System.assertEquals(375.00, quote.MontantTotalTTC__c);
            System.assertEquals(375.00, quote.SBQQ__CustomerAmount__c);
            System.assertEquals(375.00, quote.SBQQ__ListAmount__c);
            System.assertEquals(3, qli.SBQQ__EffectiveQuantity__c);
            System.assertEquals(375.00, qli.SBQQ__ListTotal__c);
            System.assertEquals(375.00, qli.SBQQ__PackageListTotal__c);

            // Passage en non transmis
            quote.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update quote;

            // puis passage en transmis
            quote.dateTransmissionClient__c = Date.today().addMonths(-13);
            quote.SBQQ__Status__c = Constants.StatutDevisTransmis;
            update quote;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);

            // Calcul de la commission vendeur
            TR022_SBQQ_Quote_Commission.processCommissions(new List<SBQQ__Quote__c>{quote});

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quoteCPQ__c FROM NRV10Commission__c];
            System.assert(commissions.isEmpty(), 'should not have commissions');
        }
    }


    /**
     * Test que les commissions ne sont pas générées s'il n'y a pas de ligne de devis
     */
    @IsTest
    public static void testNewQuoteTransmittedCollabNoQuotelines() {
        UserContext.getContext().setByPassTriggers(true);
        UserContext.getContext().setByPassValidationRules(true);
        UserContext.getContext().setByPassWorkflowRules(true);

        setupConfigurableContext(true, true, false, false);

        System.runAs(userSales){
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            Test.startTest();

            // Passage en non transmis
            quote.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update quote;

            // puis passage en transmis
            quote.dateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.StatutDevisTransmis;
            update quote;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);

            // Calcul de la commission vendeur
            TR022_SBQQ_Quote_Commission.processCommissions(new List<SBQQ__Quote__c>{quote});

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quoteCPQ__c FROM NRV10Commission__c];
            System.debug('commissions: ' + commissions);
            System.assert(commissions.isEmpty(), 'should not have commissions');
        }
    }


    /**
     * Test que les commissions ne sont pas générées s'il n'y a pas de grille de rem
     */
    @IsTest
    public static void testNewQuoteTransmittedNoRemVrp() {
        UserContext.getContext().setByPassTriggers(true);
        UserContext.getContext().setByPassValidationRules(true);
        UserContext.getContext().setByPassWorkflowRules(true);

        setupConfigurableContext(false, true, true, false);

        System.runAs(userSales){
            UserContext.getContext().setByPassTriggers(true);
            UserContext.getContext().setByPassValidationRules(true);
            UserContext.getContext().setByPassWorkflowRules(true);

            Test.startTest();

            SBQQ__QuoteLine__c qli = [SELECT Id, SBQQ__EffectiveQuantity__c, SBQQ__ListTotal__c, SBQQ__CustomerPrice__c,
                    SBQQ__ComponentListTotal__c, SBQQ__Product__c, SBQQ__PackageListTotal__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];

            // Contrôle que les formules ont bien été appliquées
            System.assertEquals(375.00, quote.MontantTotalTTC__c);
            System.assertEquals(375.00, quote.SBQQ__CustomerAmount__c);
            System.assertEquals(375.00, quote.SBQQ__ListAmount__c);
            System.assertEquals(3, qli.SBQQ__EffectiveQuantity__c);
            System.assertEquals(375.00, qli.SBQQ__ListTotal__c);
            System.assertEquals(375.00, qli.SBQQ__PackageListTotal__c);

            // Passage en non transmis
            quote.SBQQ__Status__c = Constants.StatutDevisNonTransmis;
            update quote;

            // puis passage en transmie
            quote.dateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.StatutDevisTransmis;
            update quote;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);

            // Calcul de la commission vendeur
            TR022_SBQQ_Quote_Commission.processCommissions(new List<SBQQ__Quote__c>{quote});

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quoteCPQ__c FROM NRV10Commission__c];
            System.assert(commissions.isEmpty(), 'should not have commissions');
        }
    }

    public static void setupConfirm() {
        userManager = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'manager1'];
        userSales = [SELECT Id, ByPassValidationRule__c, ByPassWorkflowRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        magasinA = [SELECT Id FROM Account WHERE Name = 'MAGTESTTEST'];
        prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test'];
        priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2Id = :pBook.Id];
        financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];

        userSales.ByPassTrigger__c = 'TR022_User;TR023_SBQQ__Quote;TR022_Order;TR022_Account;TR001_Dedoublonnage';
        update userSales;

        System.runAs(userSales) {

            // Creation d'une équipe Rem VRP avec un vendeur, un responsable et un taux spécifique sur
            Utils_Test.createTeamTest(magasinA.Id, userManager.Id, userSales.Id, prod.Id, true, financialRef.Id);
            collabSaleId = [SELECT Id FROM Collaborator__c WHERE user__c = :userSales.Id LIMIT 1].Id;
            collabMgrId = [SELECT Id FROM Collaborator__c WHERE user__c = :userManager.Id LIMIT 1].Id;

            NRV10Calendar__c cal1 = new NRV10Calendar__c(commDate__c = Date.today().addMonths(-12));
            NRV10Calendar__c cal2 = new NRV10Calendar__c(commDate__c = Date.today().addMonths(12));
            insert new List<SObject>{
                    cal1, cal2
            };

            // Création enregistrements pour devis
            opp = Utils_Test.createSBQQQuoteOpportunity(pBook.Id);

            // Creation devis
            quote = Utils_Test.createSBQQQuote(opp, userSales.Id, pBook.Id, priceBookEntry.Id, prod);

            Order o = Utils_Test.createSBQQQuoteOrder(quote, prod, pBook, priceBookEntry, magasinA);

            qli = [
                    SELECT Id, SBQQ__EffectiveQuantity__c, SBQQ__ListTotal__c, SBQQ__CustomerPrice__c,
                            SBQQ__ComponentListTotal__c, SBQQ__Product__c, SBQQ__PackageListTotal__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :quote.Id
            ];

            // Contrôle que les formules ont bien été appliquées
            System.assertEquals(375.00, quote.MontantTotalTTC__c);
            System.assertEquals(375.00, quote.SBQQ__CustomerAmount__c);
            System.assertEquals(375.00, quote.SBQQ__ListAmount__c);
            System.assertEquals(3, qli.SBQQ__EffectiveQuantity__c);
            System.assertEquals(375.00, qli.SBQQ__ListTotal__c);
            System.assertEquals(375.00, qli.SBQQ__PackageListTotal__c);

            System.debug('Création du devis');
            // Passage en non transmis
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_NOT_TRANSMITTED;
            update quote;
        }
    }


    /**
     * Test qu'une commande validée avec commandes client/founisseur validé est bien commissionnable
     */
    @IsTest
    public static void testConfirmedQuoteAndOrder() {
        setupConfirm();

        System.runAs(userManager){
            String idUser = userSales.Id;
            GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
            insert properties;
            Test.startTest();

            System.debug('  -> passage en transmis');
            // puis passage en transmie
            quote.dateTransmissionClient__c = Date.today();
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
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
            quote.quoteIsValid__c = true;
            quote.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            update quote;

            // les flows cpq devraient créer une order ?
            List<Order> orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status FROM Order WHERE SBQQ__Quote__c = :quote.Id];
            System.debug('Found ' + orders.size() + ' orders');
            System.assert(!orders.isEmpty(), 'No order found');

            Order ord = orders.get(0);
            ord.Status = Constants.ORDER_STATUS_CONFIRMED;
            ord.isInApprovalProcess__c = false;
            ord.isRefused__c = false;
            update ord;

            System.debug('devis.Status : ' + quote.SBQQ__Status__c);
            System.debug('devis.LineItemCount : ' + quote.SBQQ__LineItemCount__c);

            // Calcul de la commission vendeur
            System.debug('Lancement calculs comm');
            TR022_SBQQ_Quote_Commission.processCommissions(new List<SBQQ__Quote__c>{quote});

            Test.stopTest();

            // Le devis doit avoir des commissions associées car vendu
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quoteCPQ__c FROM NRV10Commission__c];
            //System.assert(!commissions.isEmpty(), 'should have commissions');
            NRV10Commission__c salesCom1;
            NRV10Commission__c teamCom;
            for (NRV10Commission__c c : commissions) {
                System.debug(c);
                if (c.comType__c == Constants.COMMISSION_TYPE_SALES && c.quoteCPQ__c == quote.Id) salesCom1 = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) teamCom = c;
            }
            /*System.assert(salesCom1 != null, 'Sales commission not found');
            // Le total ligne doit être de 125€
            // Taux spécifique du produit à 0.5, donc 1 ligne de commissions
            // rem = 375 * 0.5 * 100 / 10000
            System.assertEquals(1.875, salesCom1.remuneration__c, 'wrong commission amount');
            System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONABLE, salesCom1.status__c, 'wrong sales commission status');

            System.assert(teamCom != null, 'Team commission not found');
            // com equipe = 10% du total com
            // = 0.625 * 3 / 100
            System.assertEquals(0.05625, teamCom.remuneration__c, 'wrong commission amount');
            System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONABLE, teamCom.status__c, 'wrong team commission status');*/
        }
    }

}