//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Asset
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 09/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_Asset {
    private static final String RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT); 
    private static final String RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final String RT_AST_COMPONENT = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_COMPONENT_RT);
    private static final String NCC_IMPOSSIBILITY_RTID = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Impossibility');
     
    
    @testSetup 
    static void setup() {
        String refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

        // Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', RT_ACC_PERSO, null, 'Email', true);
        // Création entite     
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, true);
        // Produit
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
        // Commande client
        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, null, entite.Id, entite.Id, false);
        newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
        newCustomerOrder.amount__c = 1000;
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
        // Garantie
        Entitlement newEntitlement = new Entitlement(Name = 'Entitlement Test', 
                                                    duration__c = 1, 
                                                    AccountId = accountTest.Id,
                                                    orderItem__c = oi.Id);
        insert newEntitlement;
    }
    
    @isTest 
    static void insertUpdateAsset(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

            Test.startTest();      
            // Actif
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, accountTest.Id, true);
            newAsset1.controlDate__c = Date.today();
            update newAsset1;
            newAsset1.providerOLINotCancelledCount__c  = 1;
            update newAsset1;
            newAsset1.providerOLINotCancelledDeliveredCount__c   = 1;
            update newAsset1;
            newAsset1.InstallDate = Date.today();
            update newAsset1;
            Test.stopTest();
        }
    }
    
    @isTest 
    static void insertCompetitorAsset(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

            Test.startTest();      
            // Actif
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, accountTest.Id, false);
            newAsset1.IsCompetitorProduct = true;
            insert newAsset1;
            Test.stopTest();
        }
    }
    
    @isTest 
    static void deleteAsset(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

            Test.startTest();      
            // Actif
            Asset newAsset = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, accountTest.Id, true);
            Asset newAssetChild = Utils_Test.createAsset(RT_AST_COMPONENT, 'Asset', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, accountTest.Id, false);
            newAssetChild.ParentId = newAsset.Id;
            insert newAssetChild;
            
            delete newAsset;
            Test.stopTest();
        }
    }
    
    @isTest 
    static void updateLegacyAsset(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];

            Test.startTest();      
            // Actif
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset', newCustomerOrder.Id, productTest1.Id, null, null, accountTest.Id, false);
            newAsset1.isLegacy__c = true;
            newAsset1.legacyReference__c = 'TEST';
            insert newAsset1;
            Test.stopTest();
        }
    }

    @isTest 
    static void testUpdateDurations(){
        User user = Utils_Test.createUser(false,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);


        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            OrderItem newOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, accountTest.Id, false);
            insert newAsset1;

            Test.startTest();
            // Order Non Compliance
            List<OrderNonCompliance__c> nccList = new List<OrderNonCompliance__c>();
            OrderNonCompliance__c ncc1 = Utils_Test.createOrderNonCompliance('nccTest', newCustomerOrder.Id, NCC_IMPOSSIBILITY_RTID,false);
            ncc1.startDate__c = Date.today().addDays(-4);
            ncc1.closeDate__c = Date.today();
            OrderNonCompliance__c ncc2 = Utils_Test.createOrderNonCompliance('nccTest', newCustomerOrder.Id, NCC_IMPOSSIBILITY_RTID,false);
            ncc2.startDate__c = Date.today().addDays(-1);
            ncc2.closeDate__c = Date.today().addDays(2);
            nccList.add(ncc1);
            nccList.add(ncc2);
            insert nccList;

            update newCustomerOrder;

            newAsset1.controlDate__c = Date.today().addDays(5);
            update newAsset1;

            Test.stopTest();
        } 
    }
}