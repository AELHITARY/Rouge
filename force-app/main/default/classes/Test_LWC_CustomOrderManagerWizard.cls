//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomOrderManagerWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/08/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CustomOrderManagerWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CustomOrderManagerWizard {
    private static final Id ORDER_CUSTOMER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final Id ORDER_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);

    @testSetup 
    static void setup() {

        // Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', RT_ACC_PERSO, null, 'Email', true);
        // Fournisseur
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, true);
        // Produit
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
        Product2 productTest2 = Utils_Test.createProduct('Test2', 'TEST2' , true);
        // Commande client
        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, true);
        // Actif
        Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, accountTest.Id,false);
        Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest2.Id, accountTest.Id,false);
        List<Asset> astList = new List<Asset>();
        astList.add(newAsset1);
        astList.add(newAsset2);
        insert astList;
        // Commande fournisseur
        Order newProviderOrder1 = Utils_Test.createProviderOrder(accountTest.Id, newCustomerOrder.Id, provider1.Id ,true);
        // Ligne commande fournisseur
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }
        OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, true);
        newProviderOrder1.transmissionDate__c=Date.today();
        update newProviderOrder1;
    }
    
    @isTest
    private static void getOrder(){
        
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> o = [SELECT Id FROM Order WHERE RecordTypeId = :ORDER_CUSTOMER_RTID LIMIT 1];
            System.assert(LWC_CustomOrderManagerWizard.getOrder(o[0].Id)!=null, 'Problème test TestGetOrder');
            Test.stopTest();
        }
    }

    @isTest
    private static void getCancellingReasons(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            LWC_CustomOrderManagerWizard.getCancellingReasons(null);
            Test.stopTest();
        }
    }

    @isTest
    private static void getProviderOrders(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> o = [SELECT Id FROM Order WHERE RecordTypeId = :ORDER_CUSTOMER_RTID LIMIT 1];
            System.assert(LWC_CustomOrderManagerWizard.getProviderOrders(o[0].Id).size()==1, 'Problème test TestGetProviderOrders');
            Test.stopTest();
        }
    }

    @isTest
    private static void getOrderItems(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> o = [SELECT Id FROM Order WHERE RecordTypeId = :ORDER_PROVIDER_RTID LIMIT 1];
            System.assert(LWC_CustomOrderManagerWizard.getOrderItems(o[0].Id).size()==1, 'Problème test TestGetOrderItems');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void updateOrderItems(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<OrderItem> oi = [SELECT Id FROM OrderItem LIMIT 1];
            List<Order> o = [SELECT Id FROM Order WHERE RecordTypeId = :ORDER_PROVIDER_RTID LIMIT 1];
            List<Map<String,String>> liste = new List<Map<String,String>>();
            Map<String,String> obj = new Map<String,String>();
            obj.put('Id',String.valueOf(oi[0].Id));
            obj.put('confirmationDate__c', String.valueOf(date.today()));
            obj.put('productCost__c','0.35');
            obj.put('estimatedProductCost__c','0.40');
            obj.put('cancellationDate__c',String.valueOf(date.today()));
            obj.put('shippingDate__c',String.valueOf(date.today()));
            obj.put('manufacturingStart__c',String.valueOf(date.today()));
            obj.put('billingDate__c',String.valueOf(date.today()));
            obj.put('manufacturingEnd__c',String.valueOf(date.today()));
            obj.put('deliveryDate__c',String.valueOf(date.today()));
            obj.put('contractualDeliveryDate__c',String.valueOf(date.today()));
            obj.put('estimatedDeliveryDate__c',String.valueOf(date.today()));
            obj.put('cancellationReason__c','Annulation client');
            obj.put('receivedDate__c',String.valueOf(date.today()));
            liste.add(obj);
            LWC_CustomOrderManagerWizard.updateOrderItems(liste, 1.2, 1.3, String.valueof(o[0].Id), true, true, 'Livraison');
            Test.stopTest();
        }
    }
}