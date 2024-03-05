//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_CreditMemo
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 08/02/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_CreditMemo {
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final String RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final String RT_CRED_INVOICE = DAL.getRecordTypeIdByDevName('CreditMemo__c',Constants.CREDITMEMO_INVOICECREDITMEMO_RT); 
    private static final String RT_INV_INVOICE = DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_INVOICE_RT); 

    @testSetup 
    static void setup() {
        // Création ref  
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        refList.add(refDep);
        refList.add(refMag);
        insert refList;
        // Création entite     
        List<Account> accList = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        //Compte
        Account a = Utils_Test.createAccount('name', 'name', 'test@test.fr', RT_ACC_PERSO, null, 'Email', false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(a);
        insert accList;
        // Chantier
        Chantier__c chant = Utils_Test.createChantier('test', a.Id, false);
        chant.serviceEntity__c = entiteDep.Id;
        chant.salesEntity__c = entiteMag.Id;
        chant.heatingMode__c = 'Individuel Electrique';
        insert chant;
        // Produit
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
        // Commande client
        Order newCustomerOrder = Utils_Test.createCustomerOrder(a.Id, chant.Id, entiteMag.Id, entiteDep.Id, false);
        newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
        newCustomerOrder.amount__c = 1000;
        newCustomerOrder.serviceEntity__c = entiteDep.Id;
        newCustomerOrder.salesEntity__c = entiteMag.Id;
        insert newCustomerOrder;
        // Ligne Commande
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }
        OrderItem oi = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, true);
        // Actif        
        Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset', newCustomerOrder.Id, productTest1.Id, oi.Id, null, a.Id, true);
    }

    @isTest
    private static void testValidation() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            Asset ast = [SELECT Id FROM Asset LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

            Test.startTest();

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            Utils_Test.createInvoiceLine(inv.Id, null, ast.Id, newOrderItem.Id, 'TEST', 5, 10, 1, true);
            inv.invoiceDate__c = Date.today();
            update inv;

            // Création avoir
            CreditMemo__c cred = Utils_Test.createCreditMemo(acc.Id, entite.Id, inv.Id, chant.Id, null, newCustomerOrder.Id, RT_CRED_INVOICE, true);
            // MAJ
            cred.creditMemoDate__c = Date.today();
            update cred;

            Test.stopTest();
        }
    }

    @isTest
    private static void testRefuse() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            Asset ast = [SELECT Id FROM Asset LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

            Test.startTest();

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            Utils_Test.createInvoiceLine(inv.Id, null, ast.Id, newOrderItem.Id, 'TEST', 5, 10, 1, true);
            inv.invoiceDate__c = Date.today();
            update inv;

            // Création avoir
            CreditMemo__c cred = Utils_Test.createCreditMemo(acc.Id, entite.Id, inv.Id, chant.Id, null, newCustomerOrder.Id, RT_CRED_INVOICE, true);
            // MAJ
            cred.isRefused__c = true;
            update cred;

            Test.stopTest();
        }
    }

    @isTest
    private static void testDelete() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];

            Test.startTest();

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            
            // Création avoir
            CreditMemo__c cred = Utils_Test.createCreditMemo(acc.Id, entite.Id, inv.Id, chant.Id, null, newCustomerOrder.Id, RT_CRED_INVOICE, true);

            try {
                delete cred;
            } catch(Exception ex) {}

            Test.stopTest();
        }
    }

    @isTest
    private static void testDeleteCredLine() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            Asset ast = [SELECT Id FROM Asset LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

            Test.startTest();

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            InvoiceLine__c invLine = Utils_Test.createInvoiceLine(inv.Id, null, ast.Id, newOrderItem.Id, 'TEST', 5, 10, 1, true);
            
            // Création avoir
            CreditMemo__c cred = Utils_Test.createCreditMemo(acc.Id, entite.Id, inv.Id, chant.Id, null, newCustomerOrder.Id, RT_CRED_INVOICE, true);
            // Creation ligne avoir
            CreditMemoLine__c credLine = Utils_Test.createCreditMemoLine(cred.Id, inv.Id, invLine.Id, prod.Id, ast.Id, newOrderItem.Id, 'TEST', 10, 50, true);
            credLine.description__c = 'TEST';
            update credLine;

            try {
                delete credLine;
            } catch(Exception ex) {}

            Test.stopTest();
        }
    }
}