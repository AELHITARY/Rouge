@isTest
private class Test_LWC_CustomAssetLockerWizard {
    @testSetup 
    static void setup() {

        String customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', 'CustomerOrder');

        String RTDevNamePersonnalAcc = DAL.getRecordTypeIdByDevName('Account', 'PersonalAccount');

        String RTDevNameServiceAppointment = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
        
        String RTDevNameworkOrderService = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');

        Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT);

        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', RTDevNamePersonnalAcc, null, 'Email', true);
               
        //Commande cliente
        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, true);

        //chantier
        Chantier__c chantier1 = Utils_Test.createChantier('chantier1', accountTest.Id, null, false);
        chantier1.rue__c='1234 rue';
        insert chantier1;


        //Asset
        Asset assetCustomerOrder = Utils_Test.createAsset(assetEntityRT, 'assetCustomerOrder', newCustomerOrder.Id, null, accountTest.Id,true);

        Asset asset = Utils_Test.createAsset(assetEntityRT, 'asset', null, null, accountTest.Id,true);

        Asset assetChantier = Utils_Test.createAsset(assetEntityRT, 'Test3', null, null, accountTest.Id,false);
        assetChantier.chantier__c = chantier1.Id;
        insert assetChantier;

        WorkOrder wo = Utils_Test.createWorkOrder(RTDevNameworkOrderService, true);

        WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, asset.Id, true);

        ServiceAppointment sa = Utils_Test.createServiceAppointment(woli.Id,RTDevNameServiceAppointment,true);
    }

    @isTest
    private static void testGetAssetsFromRecordId() {
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
        Asset asset = [SELECT Id FROM Asset WHERE Name='asset' LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Order customerOrder = [SELECT Id FROM Order LIMIT 1];
        

        List<Asset> test1 = LWC_CustomAssetLockerWizard.getAssetsFromRecordId(asset.Id);
        List<Asset> test2 = LWC_CustomAssetLockerWizard.getAssetsFromRecordId(chantier.Id);
        List<Asset> test3 = LWC_CustomAssetLockerWizard.getAssetsFromRecordId(customerOrder.Id);

        System.assert(test1.size()==1,'Problème test testGetAssetsFromRecordId');
        System.assert(test2.size()==1,'Problème test testGetAssetsFromRecordId');
        System.assert(test3.size()==1,'Problème test testGetAssetsFromRecordId');
        }
        Test.stopTest();

    }

    @isTest
    private static void testGetServiceAppointments() {
        Test.startTest();

        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
        Asset asset = [SELECT Id FROM Asset WHERE Name='asset' LIMIT 1];
        List<String> assetsId = new List<String>();
        assetsId.add(asset.Id);
        List<LWC_CustomAssetLockerWizard.SAObject> test1 = LWC_CustomAssetLockerWizard.getServiceAppointments(assetsId);
    
        }
        Test.stopTest();

    }

    @isTest
    private static void testLockAsset(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<Asset> asset = [SELECT Id FROM Asset WHERE Name='asset' LIMIT 1];
            List<WorkOrder> wo = [SELECT Id FROM WorkOrder LIMIT 1];
            
            List<String> assetIdList = new List<String>();
            assetIdList.add(asset[0].Id);
            
            LWC_CustomAssetLockerWizard.SAObject saobj = new LWC_CustomAssetLockerWizard.SAObject(
                '1','2','3','4','5','6','7','8');
            List<LWC_CustomAssetLockerWizard.SAObject> salist= new List<LWC_CustomAssetLockerWizard.SAObject>();
            salist.add(saobj);
            try{
                LWC_CustomAssetLockerWizard.lockAsset(assetIdList, salist);
            }
            catch(Exception e){}
        }
        Test.stopTest();

    }
    @isTest
    private static void testSAObject(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
        Test.startTest();
        LWC_CustomAssetLockerWizard.SAObject saobj = new LWC_CustomAssetLockerWizard.SAObject(
            '1','2','3','4','5','6','7','8');
            /*saobj.getId();
            saobj.getAction();
            saobj.getAppointmentNumber();
            saobj.getDuration();
            saobj.getParentRecord();
            saobj.getStatus();
            saobj.getSubject();
            saobj.getWorkType();*/   
        Test.stopTest();
        }
    }
}