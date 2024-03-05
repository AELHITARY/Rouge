//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomOrderLockerWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/04/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CustomOrderLockerWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CustomOrderLockerWizard {

    @testSetup 
    static void setup() {
        String customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', 'CustomerOrder');
        String RTDevNamePersonnalAcc = DAL.getRecordTypeIdByDevName('Account', 'PersonalAccount');
        Id RTDevNameAsset = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT);
        String RTDevNameServiceAppointment = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
        String RTDevNameworkOrderService = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
        
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', RTDevNamePersonnalAcc, null, 'Email', true);
        
        //Chantier
        Chantier__c chantier1 = Utils_Test.createChantier('chantier1', accountTest.Id, null, false);
        chantier1.rue__c='1234 rue';
        insert chantier1;
        
        //Commande cliente
        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, false);
        newCustomerOrder.chantier__c=chantier1.Id;
        insert newCustomerOrder;
        
        Asset assetCustomerOrder = Utils_Test.createAsset(RTDevNameAsset, 'assetCustomerOrder', newCustomerOrder.Id, null, accountTest.Id,true);
        
        // FSL
        WorkOrder wo = Utils_Test.createWorkOrder(RTDevNameworkOrderService, newCustomerOrder.Id, true);
        WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, assetCustomerOrder.Id, true);
        ServiceAppointment sa = Utils_Test.createServiceAppointment(wo.Id,RTDevNameServiceAppointment, true);
    }

    @isTest
    private static void TestGetOrdersFromRecordId(){
        //LWC_CustomOrderLockerWizard.getOrdersFromRecordId
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
        Test.startTest();
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Order customerOrder = [SELECT Id FROM Order LIMIT 1];
        

        List<Order> test1 = LWC_CustomOrderLockerWizard.getOrdersFromRecordId(chantier.Id);
        List<Order> test2 = LWC_CustomOrderLockerWizard.getOrdersFromRecordId(customerOrder.Id);

        //System.assert(test1.size()==1,'Problème test TestGetOrdersFromRecordId');
        System.assert(test2.size()==1,'Problème test TestGetOrdersFromRecordId');
        Test.stopTest();
        }
    }

    @isTest
    private static void TestGetServiceAppointments(){
        //LWC_CustomOrderLockerWizard.getServiceAppointments
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
        Test.startTest();
        Order customerOrder = [SELECT Id FROM Order LIMIT 1];
        List<String> ordersId = new List<String>();
        ordersId.add(customerOrder.Id);
        List<LWC_CustomOrderLockerWizard.SAObject> test1 = LWC_CustomOrderLockerWizard.getServiceAppointments(ordersId[0]);
        Test.stopTest();
        }
    }

    @isTest
    private static void TestLockOrder(){
        //LWC_CustomOrderLockerWizard.lockOrder
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            Order customerOrder = [SELECT Id FROM Order LIMIT 1];
            Asset asset = [SELECT Id FROM Asset LIMIT 1];
            List<String> assetsList = new List<String>();
            assetsList.add(asset.Id);
            List<String> ordersId = new List<String>();
            ordersId.add(customerOrder.Id);
            LWC_CustomOrderLockerWizard.SAObject saobj = new LWC_CustomOrderLockerWizard.SAObject(
                '1','2','3','4','5','6','7');
            
            List<ServiceAppointment> salist= [SELECT Id FROM ServiceAppointment LIMIT 1];
            List<LWC_CustomOrderLockerWizard.SAObject> test1 = new List<LWC_CustomOrderLockerWizard.SAObject>();
            test1.add(saobj);
            LWC_CustomOrderLockerWizard.getAssetsFromRecordId(customerOrder.Id);
            try{
                LWC_CustomOrderLockerWizard.lockOrder(assetsList, ordersId[0], test1);
            }
            catch(Exception e){}
        }
    }

    @isTest
    private static void testSAObject(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            LWC_CustomOrderLockerWizard.SAObject saobj = new LWC_CustomOrderLockerWizard.SAObject(
                '1','2','3','4','5','6','7');
            /*saobj.getId();
            saobj.getAction();
            saobj.getAppointmentNumber();
            saobj.getDuration();
            saobj.getParentRecord();
            saobj.getSubject();
            saobj.getWorkType();*/   
            Test.stopTest();
        }
    }
}