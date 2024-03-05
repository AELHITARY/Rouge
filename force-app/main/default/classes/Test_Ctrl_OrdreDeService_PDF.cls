//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_OrdreDeService_PDF
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 01/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_OrdreDeService_PDF {

    @testSetup 
    static void setup() {
        String RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
        String customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', 'CustomerOrder');
        String RTDevNamePersonnalAcc = DAL.getRecordTypeIdByDevName('Account', 'PersonalAccount');
        Id RTDevNameAsset = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT);
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
        
        Asset assetCustomerOrder = Utils_Test.createAsset(RTDevNameAsset, 'assetCustomerOrder', newCustomerOrder.Id, null, accountTest.Id,false);
        assetCustomerOrder.leaf__c = '2';
        insert assetCustomerOrder;
        
        Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier1.Id, false);
        case1.AssetId=assetCustomerOrder.Id;
        insert case1;

        WorkOrder wo = Utils_Test.createWorkOrder(RTDevNameworkOrderService, true);
        
        WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, assetCustomerOrder.Id, true);
    }

    @isTest
    private static void test(){
        Test.startTest();
        String RTDevNameServiceAppointment = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
            ServiceAppointment sa = Utils_Test.createServiceAppointment(wo.Id, RTDevNameServiceAppointment,false);
            sa.ParentRecordId = wo.Id;
            insert sa;
            
            sa.SchedStartTime = Date.today();
            sa.SchedEndTime = Date.today();
            update sa;

            PageReference pageRef = Page.VF_OrdreDeService_PDF;
            Test.setCurrentPage(pageRef);
            Ctrl_OrdreDeService_PDF ctrl = new Ctrl_OrdreDeService_PDF(new ApexPages.StandardController(sa));
            ctrl.nombreParseur(15555555);
            ctrl.nombreParseur(15555555876.0);
        }

        Test.stopTest();
    }
}