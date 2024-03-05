//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_InvoiceAdjustAmount
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2022
//-- Version     : 1.0
//-- Description : Classe de tests de IV_InvoiceAdjustAmount
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_InvoiceAdjustAmount {
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    private static final String RT_INV_INVOICE = DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_INVOICE_RT); 

    @testSetup 
    static void setup() {
        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', RT_ACC_PERSO, 'Email',true);
        
        // Création entite        
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             RT_REF_ENTITY, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', 
                                                 refMag.Id, false);
        
        
        Account ent = Utils_Test.createEntity('MAGTESTTESTD', 'MAGTESTTESTD', Date.today(), '0123456789', null, false);
        List<Account> accList = new List<Account>();
        accList.add(entite);
        accList.add(ent);
        insert accList;
        Chantier__c chant = Utils_Test.createChantier('test',ent.Id,true);
        // Produit
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }
        // Commande client
        Order newCustomerOrder = Utils_Test.createCustomerOrder(a.Id, chant.Id, entite.Id, entite.Id, false);
        newCustomerOrder.amount__c = 5;
        newCustomerOrder.pretaxAmount__c = 3;
        newCustomerOrder.VATAmount__c = 3;
        insert newCustomerOrder;
        // Ligne Commande
        List<OrderItem> oiList = new List<OrderItem>();
        OrderItem oi = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, false);
        oi.Quantity = 2;
        oi.pretaxAmount__c = 3;
        oi.VATAmount__c = 3;
        oi.amount__c = 5;
        oiList.add(oi);
        insert oiList;
    }

    @isTest
    private static void testAdjust() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

            Test.startTest();

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            InvoiceLine__c invLine1 = Utils_Test.createInvoiceLine(inv.Id, null, null, newOrderItem.Id, 'TEST', 5,10, 1, false);
            invLine1.pretaxAmount__c = 1;
            invLine1.VATAmount__c = 1;
            invLine1.amount__c = 2;
            insert invLine1;
            InvoiceLine__c invLine2 = Utils_Test.createInvoiceLine(inv.Id, null, null, newOrderItem.Id, 'TEST2', 5,10, 1, false);
            invLine2.pretaxAmount__c = 100;
            invLine2.VATAmount__c = 100;
            invLine2.amount__c = 200;
            insert invLine2;

            // Test
            List<IV_InvoiceAdjustAmount.FlowInputParameters> inputList = new List<IV_InvoiceAdjustAmount.FlowInputParameters>(); 
            IV_InvoiceAdjustAmount.FlowInputParameters input = new IV_InvoiceAdjustAmount.FlowInputParameters();
            input.invoiceId = inv.Id;
            inputList.add(input);
            IV_InvoiceAdjustAmount.adjustInvoicesAmounts(inputList);

            Test.stopTest();
        }
    }
}