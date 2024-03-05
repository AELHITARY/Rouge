//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_AutoCreateWorkOrder
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/12/2021
//-- Version     : 1.2
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_AutoCreateWorkOrder {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_WO_SERVICE = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id RT_ORD_PROVIDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Id RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

    @testSetup 
    static void setup() {       
        // FSL
        FSL__Scheduling_Policy__c fslSp1 = Utils_Test.createSchedulingPolicy('Planification automatique',true);
        List<GlobalProperties__c> synchro= TestData_fsl_Setup.createGlobalProperties();  
        User [] u = TestData_fsl_Setup.createUser();
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);

        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, RT_REF_ENTITY, true, true, false, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, RT_REF_ENTITY, true, true, false, true, false);
        refList.add(refDep);
        refList.add(refMag);
        insert refList;
        
        // Compte
        List<Account> accToInsert = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        entiteDep.serviceTerritory__c = st.Id;
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        Account accountTest = Utils_Test.createAccount('Dupont','Jean','test@test.fr', RT_ACC_PERSO, 'Email',false);
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
        accToInsert.add(accountTest);
        accToInsert.add(entiteDep);
        accToInsert.add(entiteMag);
        accToInsert.add(provider1);
        insert accToInsert;

        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id, false);
        chantier.salesEntity__c = entiteMag.Id;
        chantier.serviceEntity__c = entiteDep.Id;
        insert chantier;

        Opportunity opp = Utils_Test.createOpportunity(accountTest, chantier, true);
            
        List<Product2> prodList = new List<Product2>();
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
        productTest1.isControllable__c=true;
        productTest1.isInstallable__c=true;
        prodList.add(productTest1);
        insert prodList;
        
        List<Order> orderList = new List<Order>();
        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, entiteMag.id, entiteDep.id, false);
        newCustomerOrder.EffectiveDate = Date.today();
        newCustomerOrder.salesEntity__c = entiteMag.Id;
        newCustomerOrder.serviceEntity__c = entiteDep.Id;
        orderList.add(newCustomerOrder);
        insert orderList;

        Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
        List<Asset> astList = new List<Asset>();
        astList.add(newAsset1);
        insert astList;
    }

    @isTest 
    static void testCreateWorkOrderDiagnostic() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        userTest.byPassValidationRule__c = true;
        update userTest;

        System.runAs(userTest) {
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];

            Test.startTest();
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo.WorkTypeId = wt1.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woli.productNonCompliance__c=case1.Id;
            woliList.add(woli);
            insert woliList;

            IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters[] inputList = new IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters[]{};
            IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters input = new IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters();
            input.pncId = case1.Id;
            inputList.add(input);

            IV_AutoCreateWorkOrder_Diagnostic.createWorkOrder_Diagnostic(inputList);

            Test.stopTest();
        }
    }

    @isTest 
    static void testDiagnostic() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];

            Test.startTest();
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;

            IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters[] inputList = new IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters[]{};
            IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters input = new IV_AutoCreateWorkOrder_Diagnostic.FlowInputParameters();
            input.pncId = case1.Id;
            inputList.add(input);

            IV_AutoCreateWorkOrder_Diagnostic.createWorkOrder_Diagnostic(inputList);

            Test.stopTest();
        }
    }

    @isTest 
    static void testDiagnostic2() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        userTest.byPassValidationRule__c = true;
        update userTest;

        System.runAs(userTest) {
            Account accountTest = [SELECT Id, contactParDefaut__c FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];

            Test.startTest();
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;

            FSL__Scheduling_Policy__c fslSp1 = [SELECT Id FROM FSL__Scheduling_Policy__c LIMIT 1];
            WorkOrder wo = IV_AutoCreateWorkOrder_Diagnostic.createWorkOrder(case1, wt2, accountTest.contactParDefaut__c, true);
            insert wo;
            ServiceAppointment sa = IV_AutoCreateWorkOrder_Diagnostic.createServiceAppointment(case1, wt2, wo.Id,accountTest.contactParDefaut__c, fslSp1.Id);

            Test.stopTest();
        }
    }

    @isTest 
    static void testCreateWorkOrderIntervention() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        userTest.byPassTrigger__c = 'TR020_Case';
        userTest.ByPassWorkflowRule__c = true;
        userTest.byPassValidationRule__c = true;
        update userTest;

        System.runAs(userTest) {
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            
            Test.startTest();

            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.diagnosticDate__c = date.today();
            case1.AssetId=newAsset1.Id;
            insert case1;

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo.WorkTypeId = wt1.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woli.productNonCompliance__c=case1.Id;
            woliList.add(woli);
            insert woliList;

            IV_AutoCreateWorkOrder_Intervention.FlowInputParameters[] inputList = new IV_AutoCreateWorkOrder_Intervention.FlowInputParameters[]{};
            IV_AutoCreateWorkOrder_Intervention.FlowInputParameters input = new IV_AutoCreateWorkOrder_Intervention.FlowInputParameters();
            input.pncId = case1.Id;
            inputList.add(input);

            IV_AutoCreateWorkOrder_Intervention.createWorkOrder_Intervention(inputList);

            Test.stopTest();
        }
    }

    @isTest 
    static void testIntervention() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(userTest) {
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];

            Test.startTest();
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;

            case1.diagnosticDate__c = date.today();
            update case1;

            IV_AutoCreateWorkOrder_Intervention.FlowInputParameters[] inputList = new IV_AutoCreateWorkOrder_Intervention.FlowInputParameters[]{};
            IV_AutoCreateWorkOrder_Intervention.FlowInputParameters input = new IV_AutoCreateWorkOrder_Intervention.FlowInputParameters();
            input.pncId = case1.Id;
            inputList.add(input);

            IV_AutoCreateWorkOrder_Intervention.createWorkOrder_Intervention(inputList);

            Test.stopTest();
        }
    }

    @isTest 
    static void testIntervention2() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        userTest.byPassValidationRule__c = true;
        update userTest;

        System.runAs(userTest) {
            Account accountTest = [SELECT Id, contactParDefaut__c FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];

            Test.startTest();
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;

            FSL__Scheduling_Policy__c fslSp1 = [SELECT Id FROM FSL__Scheduling_Policy__c LIMIT 1];
            WorkOrder wo = IV_AutoCreateWorkOrder_Intervention.createWorkOrder(case1, wt2, accountTest.contactParDefaut__c, true);
            insert wo;
            ServiceAppointment sa = IV_AutoCreateWorkOrder_Intervention.createServiceAppointment(case1, wt2, wo.Id,accountTest.contactParDefaut__c, fslSp1.Id);

            Test.stopTest();
        }
    }
}