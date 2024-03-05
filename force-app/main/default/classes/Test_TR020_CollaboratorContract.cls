/**
 * Created by 4C on 16/11/2020.
 */

@IsTest
private class Test_TR020_CollaboratorContract {

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
        User userManager2 = Utils_Test.createUser(false, 'manager2', 'manager2@test.remvrp.com', 'man2', 'ager2', null, null);
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

            // Création des référentiels Job RV Et vendeur
            Id refRT = DAL.getRecordTypeIdByDevName('Referencial__c', 'Job');
            Referencial__c refJobRv = Utils_Test.findOrCreateReferencial('RV', 'RV', Date.today().addMonths(-12), null,
                    refRT, true, true, true, true, true);
            Referencial__c refJobVendeur = Utils_Test.findOrCreateReferencial('Vendeur', 'Vendeur', Date.today().addMonths(-12),
                    null, refRT, true, true, true, true, true);

            // Création entite
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            Account magasinA = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(),
                    '0123456789', refMag.Id, true);

            //second magasin
            Referencial__c refMag2 = Utils_Test.createReferencial('Magasin2', 'MAG2', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            Account magasinB = Utils_Test.createEntity('MAGTESTTEST2', 'MAGTESTTEST2', Date.today(),
                    '01234567892', refMag2.Id, true);

            // Creation d'une équipe Rem VRP avec un vendeur, un responsable et un taux spécifique sur
            Utils_Test.createTeamTest(magasinA.Id, userManager.Id, userSales.Id, prod.Id, true, financialRef.Id);

            // Creation du second manager sur le second magasin
            NRV10GridRevision__c ctGridRev = [SELECT Id FROM NRV10GridRevision__c WHERE Name = 'Contract1'];
            NRV10GridRevision__c ctGridRevMgr = [SELECT Id FROM NRV10GridRevision__c WHERE Name = 'ContractMgr1'];

            Collaborator__c manager2 = Utils_Test.createCollaborator(userManager2.Id, 'test2', 'manager2', 'mng2', false);
            Utils_Test.createEmploymentContract('contract 2m', Date.today().addMonths(-12), null,
                    manager2.Id, ctGridRevMgr.Id, magasinB.Id, refJobRv.Id);

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
            comSales.status__c = Constants.COMMISSION_STATUS_COMMISSIONABLE;
            insert comSales;

            // Création de la commissions équipe
            System.debug('Création de la commission vendeur');
            NRV10Commission__c comTeam = new NRV10Commission__c();
            comTeam.user__c = [SELECT Id FROM Collaborator__c WHERE user__c = :userManager.Id].Id;
            comTeam.quoteCPQ__c = quote.Id;
            comTeam.quoteLine__c = qli.Id;
            comTeam.calculationDate__c = Date.today();
            comTeam.comType__c = Constants.COMMISSION_TYPE_TEAM;
            comTeam.remuneration__c = 0.01875;
            comTeam.status__c = Constants.COMMISSION_STATUS_COMMISSIONABLE;
            insert comTeam;
        }
    }

    /**
     * Test qu'une commande validée avec commandes client/founisseur validé est bien commissionnable
     */
    @IsTest
    public static void testUpdateContract() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userSales = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        userSales.ByPassWorkflowRule__c = false;
        update userSales;
        userSales = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c, ByPassTrigger__c FROM User WHERE Alias = 'Sales1'];
        User userManagerB = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c, ByPassTrigger__c FROM User WHERE Alias = 'manager2'];
        Collaborator__c managerB = [SELECT Id FROM Collaborator__c WHERE user__c = :userManagerB.Id];
        Account magasinB = [SELECT Id FROM Account WHERE Name = 'MAGTESTTEST2'];
//        Referencial__c financialRef = [SELECT Id, Name FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];

        SBQQ.TriggerControl.disable();

        System.runAs(userSales) {
            UserContext.getContext().setByPassWorkflowRules(false);
            UserContext.getContext().setByPassValidationRules(true);

            Test.startTest();

            CollaboratorContract__c contract = [SELECT Id, assignedTo__c FROM CollaboratorContract__c WHERE collaborator__r.reference__c = 'sl1'];
            contract.assignedTo__c = magasinB.Id;

            // Mise à jour du contrat et déclenchement du trigger
            update contract;

            Test.stopTest();

            // Le devis ne doit pas avoir de commission associée car mauvais statut
            List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                    remuneration__c, comType__c, quoteCPQ__c, financingMethodName__c FROM NRV10Commission__c];
            System.assert(!commissions.isEmpty(), 'should have commissions');
            //System.assertEquals(3, commissions.size(), 'should have 3 commissions');
            //System.assertEquals(2, commissions.size(), 'should have 2 commissions');
            NRV10Commission__c salesCom;
            NRV10Commission__c teamCom;
            NRV10Commission__c malusCom;
            for (NRV10Commission__c c : commissions) {
                System.debug(c);
                if (c.comType__c == Constants.COMMISSION_TYPE_SALES) salesCom = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) teamCom = c;
                if (c.comType__c == Constants.COMMISSION_TYPE_MALUS) malusCom = c;
            }
            System.assert(salesCom != null, 'Sales commission not found');
            //System.assertEquals(magasinB.Id, salesCom.store__c, 'wrong sales commission store Id');

            //System.assert(malusCom != null, 'Malus commission not found');
            //System.assertEquals(financialRef.Name, malusCom.financingMethodName__c, 'wrong malus commission paiement method');
            //System.assertEquals(Constants.QUOTE_PAIEMENT_COMPTANT, malusCom.financingMethodName__c, 'wrong malus commission paiement method');

            //System.assert(teamCom != null, 'Sales commission not found');
            //System.assertEquals(magasinB.Id, teamCom.store__c, 'wrong team commission store id');
            //System.assertEquals(managerB.Id, teamCom.user__c, 'wrong manager Id');

            SBQQ.TriggerControl.enable();
        }
    }

}