//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomProviderOrderLegacyWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/04/2021
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CustomProviderOrderLegacyWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CustomProviderOrderLegacyWizard {

    @testSetup 
    static void setup() {
        String customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
        String providerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);

        String RTDevNamePersonnalAcc = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        String RTDevNameProvider = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);

        Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT);

        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', RTDevNamePersonnalAcc, null, 'Email', false);
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RTDevNameProvider, null , null, false);
        Account provider2 = Utils_Test.createAccountPro('PROVIDERTWO','0123456789', RTDevNameProvider, null , null, false);
        List<Account> accList = new List<Account>();
        accList.add(accountTest);
        accList.add(provider1);
        accList.add(provider2);
        insert accList;

        Id pBook = Test.getStandardPricebookId();
        Product2 productReprise = Utils_Test.createProduct('REPRISE GC', 'REPRISEGC' , false);
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
        Product2 productTest2 = Utils_Test.createProduct('Test2', 'TEST2' , false);
        List<Product2> prodList = new List<Product2>();
        prodList.add(productReprise);
        prodList.add(productTest1);
        prodList.add(productTest2);
        insert prodList;

        //PBE
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }

        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, true);
        Order newProviderOrder1 = Utils_Test.createProviderOrder(accountTest.Id, provider1.Id ,true);
        Order newProviderOrder2 = Utils_Test.createProviderOrder(accountTest.Id, provider2.Id ,false);
        newProviderOrder2.EndDate = Date.today();
        insert newProviderOrder2;

        Asset newAssetReprise = Utils_Test.createAsset(assetEntityRT, 'TestReprise', null, productReprise.Id, accountTest.Id,false);
        Asset newAsset1 = Utils_Test.createAsset(assetEntityRT, 'Test1', newCustomerOrder.Id, productTest1.Id, accountTest.Id,false);
        Asset newAsset2 = Utils_Test.createAsset(assetEntityRT, 'Test2', newCustomerOrder.Id, productTest2.Id, accountTest.Id,false);
        List<Asset> assetList = new List<Asset>();
        assetList.add(newAssetReprise);
        assetList.add(newAsset1);
        assetList.add(newAsset2);
        insert assetList;
        
        Product_Provider__c pp1 = Utils_Test.createProductProvider(provider1.Id, productTest1.Id, false);
        Product_Provider__c pp2 = Utils_Test.createProductProvider(provider1.Id, productTest2.Id, false);
        List<Product_Provider__c> ppList = new List<Product_Provider__c>();
        ppList.add(pp1);
        ppList.add(pp2);
        insert ppList;

        OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset2.Id, null, false);
        OrderItem newOrderItem2 = Utils_Test.createOrderItem(newProviderOrder2.Id, pbEntry.Id, newAssetReprise.Id, productReprise.Id, false);
        List<OrderItem> oiList = new List<OrderItem>();
        oiList.add(newOrderItem1);
        oiList.add(newOrderItem2);
        insert oiList;
    }

    @isTest
    private static void TestGetCustomerOrder() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            List<Order> customerOrder = [SELECT Id, RecordType.DeveloperName, Name FROM Order WHERE RecordType.DeveloperName='CustomerOrder'];
            System.assert(customerOrder.size()==1,'Erreur donnée');
            System.assert(LWC_CustomProviderOrderLegacyWizard.getCustomerOrder(customerOrder.get(0).Id)!=null, 'LWC_CustomProviderOrderLegacyWizard.getCustomerOrder');
            Test.stopTest();
        }
    }
    @isTest
    public static void TestHasOrderItemRepriseGC(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> providerOrder1 = [SELECT Id, RecordType.DeveloperName, Name, EffectiveDate FROM Order WHERE EndDate=null AND RecordType.DeveloperName='ProviderOrder'];
            List<Order> providerOrder2 = [SELECT Id, RecordType.DeveloperName, Name, EndDate FROM Order WHERE EndDate!=null AND RecordType.DeveloperName='ProviderOrder'];
            
            LWC_CustomProviderOrderLegacyWizard.hasOrderItemRepriseGC(providerOrder1.get(0).Id);
            LWC_CustomProviderOrderLegacyWizard.hasOrderItemRepriseGC(providerOrder2.get(0).Id);
            

            Test.stopTest();
        }
    }

    @isTest
    public static void TestGetAssets(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> customerOrder = [SELECT Id, RecordType.DeveloperName, Name FROM Order WHERE RecordType.DeveloperName='CustomerOrder'];
            List<Account> provider = [SELECT Id, Name FROM Account WHERE Name='PROVIDERONE'];
            List<String> assetsIds = new List<String>();
            List<Asset> assets = LWC_CustomProviderOrderLegacyWizard.getAssets(customerOrder.get(0).Id, provider.get(0).Id);
            for(Asset ast : assets) {
                assetsIds.add(ast.Id);
            }
            LWC_CustomProviderOrderLegacyWizard.getAssetsByDefault(assetsIds, customerOrder.get(0).Id, provider.get(0).Id);

            Test.stopTest();
        }
    }


    @isTest
    public static void testGetOrderLines(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> providerOrder2 = [SELECT Id, RecordType.DeveloperName, Name, EndDate FROM Order WHERE EndDate!=null AND RecordType.DeveloperName='ProviderOrder'];
            List<Asset> assets = [SELECT Id, Product2.Name, Name, Product2Id, location__c, Quantity, leaf__c, height__c, width__c FROM Asset WHERE Product2.Name!='REPRISE GC'];
            List<OrderItem> ois = LWC_CustomProviderOrderLegacyWizard.getOrderLines(providerOrder2.get(0).Id, assets, 2, 100, 100, null,null,null,null,null,null,null);
            System.assert(ois.size()==2,'Erreur testGetOrderLines');
            Test.stopTest();
        }
    }

    @isTest
    public static void testCreateOrderItems(){
    //public static String createOrderItems(List<OrderItem> newOrderItems, List<Asset> selectedAssets, String orderId, String providerReference){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> providerOrder2 = [SELECT Id, RecordType.DeveloperName, Name, EndDate FROM Order WHERE EndDate!=null AND RecordType.DeveloperName='ProviderOrder'];
            List<Asset> assets = [SELECT Id, Product2.Name, Name, Product2Id, location__c, Quantity, leaf__c, height__c, width__c FROM Asset WHERE Product2.Name!='REPRISE GC'];
            List<OrderItem> ois = LWC_CustomProviderOrderLegacyWizard.getOrderLines(providerOrder2.get(0).Id, assets, 2, 100, 100, '12345','12345',Date.today(),Date.today(),Date.today(),Date.today(),Date.today());
            List<OrderItem> ois2 = new List<OrderItem>();
            try{
                LWC_CustomProviderOrderLegacyWizard.createOrderItems(ois, assets, providerOrder2.get(0).Id, '21412125',Date.today(), ois2);
            }
            catch(Exception e) {}
            Test.stopTest();
        }
    }

    @isTest

    public static void testUpdateDatatableOrderItems(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Order> providerOrder2 = [SELECT Id, RecordType.DeveloperName, Name, EndDate FROM Order WHERE EndDate!=null AND RecordType.DeveloperName='ProviderOrder'];
            List<Asset> assets = [SELECT Id, Product2.Name, Name, Product2Id, location__c, Quantity, leaf__c, height__c, width__c FROM Asset WHERE Product2.Name!='REPRISE GC'];
            List<OrderItem> ois = LWC_CustomProviderOrderLegacyWizard.getOrderLines(providerOrder2.get(0).Id, assets, 2, 100, 100, null,null,null,null,null,null,null);
            Map<String,String> draft1 = new Map<String,String>();
            draft1.put('orderItemNumber__c','1');
            draft1.put('estimatedProductCost__c','1000');
            draft1.put('confirmationDate__c',String.valueOf(date.today()));
            draft1.put('estimatedDeliveryDate__c',String.valueOf(date.today()));
            draft1.put('deliveryDate__c',String.valueOf(date.today()));
            draft1.put('billingDate__c',String.valueOf(date.today()));

            draft1.put('billingNumber__c','1');
            draft1.put('deliveryNumber__c','1');
            draft1.put('productCost__c','1');

            List<Map<String,String>> newValues = new List<Map<String,String>>();
            newValues.add(draft1);
            LWC_CustomProviderOrderLegacyWizard.updateDatatableOrderItems(newValues,ois);
            Test.stopTest();
        }
    }
}