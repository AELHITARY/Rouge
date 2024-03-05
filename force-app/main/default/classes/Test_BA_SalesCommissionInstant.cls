/**
 * Created by Gregory Quinet on 06/10/2020.
 */

@IsTest
public with sharing class Test_BA_SalesCommissionInstant {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static Date twoMonthsBack = Date.today().addDays(5).addMonths(-2);
    private static Date oneMonthsBack = Date.today().addDays(5).addMonths(-1);

    @TestSetup
    static void setup() {
        UserContext.getContext().setByPassWorkflowRules(true);
        UserContext.getContext().setByPassValidationRules(true);
        User userManager = Utils_Test.createUser(false,'manager1', 'manager1@test.remvrp.com', 'man','ager', null, null);
        userManager.sgid__c = 'mng1';
        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        userSales.ByPassWorkflowRule__c = true;
        userSales.sgid__c = 'sl1';
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassTrigger__c = 'TR020_User;TR020_WorkOrder;TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;TR022_Order;TR022_Account;TR001_Dedoublonnage';
        update new List<User> {userManager, userSales};

        System.runAs(userSales) {
            UserContext.getContext().setByPassWorkflowRules(true);
            UserContext.getContext().setByPassValidationRules(true);

            // Creation produits
            Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);

            // Price book
            Pricebook2 pBook = new Pricebook2(Name = 'Test');
            insert pBook;
            PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
            insert priceBookEntry;

            // Mode de financement
            Referencial__c financialRef = new Referencial__c(Name = 'Comptant',
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
            Id collabSaleId = [SELECT Id FROM Collaborator__c WHERE user__c = :userSales.Id LIMIT 1].Id;
            Id collabMgrId = [SELECT Id FROM Collaborator__c WHERE user__c = :userManager.Id LIMIT 1].Id;

            NRV10Calendar__c cal1 = new NRV10Calendar__c(commDate__c = twoMonthsBack);
            NRV10Calendar__c cal2 = new NRV10Calendar__c(commDate__c = oneMonthsBack);
            NRV10Calendar__c cal3 = new NRV10Calendar__c(commDate__c = Date.today());
            insert new List<SObject>{cal1, cal2, cal3};

            // Création d'un historique de commissions/CA suffisemment ancien pour permettre un calcul de bonus
            KMDC__c k1 = new KMDC__c(SGID__c = 'sl1', dateStats__c = twoMonthsBack.addDays(4), montantHT__c = 85.00, IDTiers__c = 'idt1');
            KMDC__c k2 = new KMDC__c(SGID__c = 'sl1', dateStats__c = twoMonthsBack.addDays(20), montantHT__c = 15.00, IDTiers__c = 'idt2');
            // Création d'un historique CA qui ne doit pas être pris en compte dans le calcul
            KMDC__c k3 = new KMDC__c(SGID__c = 'sl1', dateStats__c = oneMonthsBack.addDays(10), montantHT__c = 100.00, IDTiers__c = 'idt3');

            // Création de commissions à prendre dans le calcul
            NRV10Commission__c com1 = new NRV10Commission__c(user__c = collabSaleId, status__c = Constants.COMMISSION_STATUS_COMMISSIONABLE,
                    comType__c = Constants.COMMISSION_TYPE_SALES, remuneration__c = 590.00, calculationDate__c = Date.today().addDays(-5));
            NRV10Commission__c com2 = new NRV10Commission__c(user__c = collabMgrId, status__c = Constants.COMMISSION_STATUS_COMMISSIONABLE,
                    comType__c = Constants.COMMISSION_TYPE_TEAM, remuneration__c = 25.00, calculationDate__c = Date.today().addDays(-1));
            NRV10Commission__c com3 = new NRV10Commission__c(user__c = collabSaleId, status__c = Constants.COMMISSION_STATUS_PREVISIONEL,
                    comType__c = Constants.COMMISSION_TYPE_BONUS, remuneration__c = 132.00, calculationDate__c = Date.today().addDays(-1));

            // Création d'une commission de regul d'instantané précédent
            NRV10Commission__c com4 = new NRV10Commission__c(user__c = collabSaleId, status__c = Constants.COMMISSION_STATUS_REGULARIZABLE,
                    comType__c = Constants.COMMISSION_TYPE_REPORT, remuneration__c = -800.00, calculationDate__c = oneMonthsBack);

            insert new List<SObject> {k1, k2, k3, com1, com2, com3, com4};
        }
    }


    @IsTest
    static void testBatchInstant() {
        Test.startTest();

        List<NRV10Commission__c> commissions = [SELECT Id, user__c, store__c, status__c,
                remuneration__c, comType__c FROM NRV10Commission__c];
        System.assert(!commissions.isEmpty(), 'should have commissions');
        NRV10Commission__c salesCom1;
        NRV10Commission__c teamCom;
        NRV10Commission__c bonusCom;
        List<NRV10Commission__c> regulCom = new List<NRV10Commission__c>();
        for (NRV10Commission__c c : commissions) {
            System.debug(c);
            if (c.comType__c == Constants.COMMISSION_TYPE_SALES) salesCom1 = c;
            if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) teamCom = c;
            if (c.comType__c == Constants.COMMISSION_TYPE_BONUS) bonusCom = c;
            if (c.comType__c == Constants.COMMISSION_TYPE_REPORT) regulCom.add(c);
        }
        System.assert(salesCom1 != null, 'Sales commission not found');
        System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONABLE, salesCom1.status__c, 'wrong sales commission status');

        System.assert(teamCom != null, 'Team commission not found');
        System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONABLE, teamCom.status__c, 'wrong team commission status');

        System.assert(bonusCom != null, 'Bonus commission not found');
        System.assertEquals(Constants.COMMISSION_STATUS_PREVISIONEL, bonusCom.status__c, 'wrong bonus commission status');

        System.assertEquals(1, regulCom.size(), 'Report commissions not found');
        System.assertEquals(Constants.COMMISSION_STATUS_REGULARIZABLE, regulCom.get(0).status__c, 'wrong report commission status');

        Database.executeBatch(new BA_SalesCommissionInstant());

        Test.stopTest();

        regulCom = new List<NRV10Commission__c>();
        commissions = [SELECT Id, user__c, store__c, status__c,
                remuneration__c, comType__c, calculationDate__c FROM NRV10Commission__c];
        System.assert(!commissions.isEmpty(), 'should have commissions');
        for (NRV10Commission__c c : commissions) {
            System.debug(c);
            if (c.comType__c == Constants.COMMISSION_TYPE_SALES) salesCom1 = c;
            if (c.comType__c == Constants.COMMISSION_TYPE_TEAM) teamCom = c;
            if (c.comType__c == Constants.COMMISSION_TYPE_BONUS) bonusCom = c;
            if (c.comType__c == Constants.COMMISSION_TYPE_REPORT) regulCom.add(c);
        }

        System.assert(salesCom1 != null, 'Sales commission not found');
        System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONED, salesCom1.status__c, 'wrong sales commission status');

        System.assert(teamCom != null, 'Team commission not found');
        System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONED, teamCom.status__c, 'wrong team commission status');

        System.assert(bonusCom != null, 'Bonus commission not found');
        System.assertEquals(Constants.COMMISSION_STATUS_COMMISSIONED, bonusCom.status__c, 'wrong bonus commission status');

        System.assertEquals(2, regulCom.size(), 'All report commissions not found');
        Boolean regulatedOk = false;
        Boolean newRegulOk = false;
        for (NRV10Commission__c reg : regulCom) {
            if (reg.status__c == Constants.COMMISSION_STATUS_REGULATED) regulatedOk = true;
            if (reg.status__c == Constants.COMMISSION_STATUS_REGULARIZABLE && reg.calculationDate__c == Date.today()) newRegulOk = true;
        }
        System.assert(regulatedOk && newRegulOk, 'wrong report commissions status');

        NRV10Calendar__c snapshot = [SELECT Id, commDate__c FROM NRV10Calendar__c WHERE commDate__c = :Date.today()];
        System.debug('look for document linked to snapshot id: ' + snapshot.Id);
        List<ContentDocumentLink> cdls = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :snapshot.Id];
        System.assert(cdls != null, 'Document link not found');
        System.assertEquals(5, cdls.size(), 'Document links does not contain 5 element');

        ContentVersion[] cv = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId = :cdls.get(0).ContentDocumentId];
        System.assert(cv != null, 'CSV file not found');
        System.assert(cv[0].VersionData.size() > 0, 'File content is empty');
        System.debug('File content : ');

        List<Id> docIds = new List<Id>();
        for (ContentDocumentLink cdl : cdls) {
            docIds.add(cdl.ContentDocumentId);
        }
        for (ContentVersion contentv : [SELECT Id, VersionData, Title FROM ContentVersion WHERE ContentDocumentId IN :docIds]) {
            System.debug('Attached file content for file ' + contentv.Title);
            System.debug(EncodingUtil.base64Decode(EncodingUtil.base64Encode(contentv.VersionData)).toString());
        }
    }
}