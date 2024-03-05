//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomWorkOrderWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/06/2023
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CustomWorkOrderWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CustomWorkOrderWizard {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_WO_SERVICE = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id RT_ORD_PROVIDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Id RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final String RDV_DEBRIEFE = Constants.RDV_FSL_DEBRIEFE;
    private static final String RDV_ENCOURS = Constants.RDV_FSL_ENCOURS;
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');

    

    @testSetup 
    static void setup() {
            // FSL
            FSL__Scheduling_Policy__c fslSp1 = Utils_Test.createSchedulingPolicy('test',true);
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
            
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
            chantier.serviceEntity__c = entiteDep.id;
            chantier.salesEntity__c = entiteMag.id;
            insert chantier;
            
            List<Product2> prodList = new List<Product2>();
            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
            productTest1.isControllable__c=true;
            prodList.add(productTest1);
            Product2 productTest2 = Utils_Test.createProduct('Test2', 'TEST2' , false);
            prodList.add(productTest2);
            insert prodList;
            
            List<Order> orderList = new List<Order>();
            Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, entiteMag.id, entiteDep.id, false);
            orderList.add(newCustomerOrder);
            
            Order newProviderOrder1 = Utils_Test.createProviderOrder(accountTest.Id, newCustomerOrder.Id, provider1.Id ,false);
            orderList.add(newProviderOrder1);
            insert orderList;

            newProviderOrder1 = [SELECT Id,RecordType.developerName FROM Order WHERE provider__c = :provider1.Id LIMIT 1];
            System.debug('## newProviderOrder1 type:'+newProviderOrder1.RecordType.developerName);
            
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test2', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            astList.add(newAsset2);
            insert astList;
            
            List<Product_Provider__c> ppList = new List<Product_Provider__c>();
            Product_Provider__c pp1 = Utils_Test.createProductProvider(provider1.Id, productTest1.Id, false);
            Product_Provider__c pp2 = Utils_Test.createProductProvider(provider1.Id, productTest2.Id, false);
            ppList.add(pp1);
            ppList.add(pp2);
            insert ppList;
    }

    @isTest
    private static void testUtils(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            
            LWC_CustomWorkOrderWizard.checkPermissions();
            LWC_CustomWorkOrderWizard.generateAuraException('TESt');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetWorkTypeControl(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id, Chantier__c FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id, Chantier__c FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c WHERE Name ='Chantier 1' LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
        
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset2.Id;
            insert case1;
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            wt1.FSL__Due_Date_Offset__c = 10800;
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo.WorkTypeId = wt1.Id;
            insert wo;

            case1.diagnosticDate__c = date.today();
            update case1;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woli.productNonCompliance__c=case1.Id;
            woliList.add(woli);
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList;

            AfterSalesService__c sav = new AfterSalesService__c(workSite__c = chantier.Id);
            insert sav;

            LWC_CustomWorkOrderWizard.getWorkType(String.valueOf(newCustomerOrder.Id),'Order',false);
            LWC_CustomWorkOrderWizard.getWorkType(String.valueOf(chantier.Id),'Chantier__c',false);
            LWC_CustomWorkOrderWizard.getWorkType(String.valueOf(sav.Id),'AfterSalesService__c',false);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetWorkTypeIntervention(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
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
            wo.WorkTypeId = wt2.Id;
            insert wo;

            case1.diagnosticDate__c = date.today();
            update case1;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woli.productNonCompliance__c=case1.Id;
            woliList.add(woli);
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList;

            AfterSalesService__c sav = new AfterSalesService__c(workSite__c = chantier.Id);
            insert sav;

            LWC_CustomWorkOrderWizard.getWorkType(String.valueOf(newCustomerOrder.Id),'Order',false);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetWorkTypeDiag(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
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
            wo.WorkTypeId = wt3.Id;
            insert wo;

            case1.diagnosticDate__c = date.today();
            update case1;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woli.productNonCompliance__c=case1.Id;
            woliList.add(woli);
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList;

            AfterSalesService__c sav = new AfterSalesService__c(workSite__c = chantier.Id);
            insert sav;

            LWC_CustomWorkOrderWizard.getWorkType(String.valueOf(newCustomerOrder.Id),'Order',false);
            LWC_CustomWorkOrderWizard.getWorkType(String.valueOf(chantier.Id),'Chantier__c',false);
            LWC_CustomWorkOrderWizard.getWorkType(String.valueOf(sav.Id),'AfterSalesService__c',false);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetProducts(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
                          
            LWC_CustomWorkOrderWizard.getProducts(String.valueOf(newCustomerOrder),'Order', Constants.ACTIVITY_TYPE_CONTROL, true);
            LWC_CustomWorkOrderWizard.getProducts(String.valueOf(newCustomerOrder),'Order', Constants.ACTIVITY_TYPE_CONTROL, false);
            LWC_CustomWorkOrderWizard.getProducts(String.valueOf(chantier.Id),'Chantier__c',Constants.ACTIVITY_TYPE_DIAGNOSTIC, true);
            LWC_CustomWorkOrderWizard.getProducts(String.valueOf(chantier.Id),'Chantier__c',Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetProductsNonCompliance(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;
            
            List<String> assetsId = new List<String>();
            assetsId.add(newAsset1.Id);
            assetsId.add(newAsset2.Id);
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_CONTROL, newCustomerOrder.Id, false, true,'');
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_INTERVENTION, newCustomerOrder.Id, false, true,'');
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_INTERVENTION, null, false, true,'');
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_DIAGNOSTIC, newProviderOrder1.Id, true, true,'');
            
            List<String> assetsIdList = new List<String>();
            List<String> casesIdList = new List<String>(); 
            
            assetsIdList.add(case1.AssetId);
            casesIdList.add(case1.Id);
            
            LWC_CustomWorkOrderWizard.initSubWorkType(Constants.ACTIVITY_TYPE_CONTROL, casesIdList, newCustomerOrder.Id);
            LWC_CustomWorkOrderWizard.initSubWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, casesIdList, newCustomerOrder.Id);
            LWC_CustomWorkOrderWizard.initSubWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, casesIdList, newCustomerOrder.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetNCPByDefault(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            List<String> casesId = new List<String>();
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            casesId.add(case1.Id);
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;

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

            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woli.productNonCompliance__c = case1.Id;
            insert woli;
            
            LWC_CustomWorkOrderWizard.getNCPByDefault(casesId, Constants.ACTIVITY_TYPE_INTERVENTION);
            LWC_CustomWorkOrderWizard.getNCPByDefault(casesId, Constants.ACTIVITY_TYPE_DIAGNOSTIC);
            
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetSkills(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
                        
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];
            
            ProductSkill__c pk1 = Utils_Test.createProductSkill(skillsList[0].Id, 1, productTest1.Id, true);
            
            SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt1.Id, true);
            
            List<String> assetsId = new List<String>();
            List<Asset> assetList = [SELECT Id FROM Asset];
            for(Asset a : assetList){
                assetsId.add(a.Id);
            }   
            LWC_CustomWorkOrderWizard.getSkills(assetsId,Constants.ACTIVITY_TYPE_CONTROL ,true);

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetTechnicians(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
                        
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;

            AfterSalesService__c sav = new AfterSalesService__c(workSite__c = chantier.Id);
            insert sav;

            try{
                LWC_CustomWorkOrderWizard.getTechnicians(newCustomerOrder.Id, 'Order', 'Test', null);
                LWC_CustomWorkOrderWizard.getTechnicians(chantier.Id, 'Chantier__c', 'Test', null);
                LWC_CustomWorkOrderWizard.getTechnicians(sav.Id, 'AfterSalesService__c', 'Test', null);
            }
            catch(Exception e){}

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testCalculateEarliestStartDateChantier(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            
            List<String> assetsId = new List<String>();
            assetsId.add(newAsset1.Id);
            assetsId.add(newAsset2.Id);
            List<String> casesId = new List<String>();
            casesId.add(case1.Id);
            LWC_CustomWorkOrderWizard.calculateEarliestStartDateChantier(assetsId, casesId);

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testCreateWorkOrderChantier(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
                        
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];
            SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt1.Id, true);
            
            //List<Chantier__c> chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            List<String> assetsId = new List<String>();
            List<Asset> assetList = new List<Asset>();
            assetsId.add(newAsset1.Id);
            assetsId.add(newAsset2.Id);
            List<String> casesId = new List<String>();
            casesId.add(case1.Id);
            
            Map<String, String> mapParameters = new Map<String, String>();
            mapParameters.put('workType', Constants.ACTIVITY_TYPE_CONTROL);
            mapParameters.put('workOrderEarliestStartDate', '2020-01-01');
            mapParameters.put('workOrderStartDate', '2020-01-01');
            mapParameters.put('workOrderVisitingStartHour','10:00');
            mapParameters.put('workOrderVisitingEndHour','19:00');
            mapParameters.put('workOrderVisitingDays','Lundi');
            
            List<Map<String, String>> skills = new List<Map<String, String>>();
            Map<String, String> oneSkill = new Map<String, String>();
            //List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 1];
            oneSkill.put('id', skillsList[0].Id);
            oneSkill.put('value','1');
            //oneSkill.put('id','');
            skills.add(oneSkill);
            
            List<Map<String, String>> ressources = new List<Map<String,String>>();
            Map<String,String> oneRess = new Map<String,String>();
            oneRess.put('id','');
            oneRess.put('value','');
            LWC_CustomWorkOrderWizard.createWorkOrder(chantier.Id, assetsId, skills, ressources, casesId, mapParameters);
                

            Test.stopTest();            
        }
    }
    
    @isTest
    private static void testCreateWorkOrderCustomerOrder(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1'];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource srList = [SELECT Id FROM ServiceResource LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;
            

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;

            
            List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];            
            ProductSkill__c pk1 = Utils_Test.createProductSkill(skillsList[0].Id, 1, productTest1.Id, true);            
            SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt1.Id, true);

            FSL__Scheduling_Policy__c fslSp1 = [SELECT Id FROM FSL__Scheduling_Policy__c LIMIT 1];
            
            //List<Order> customerOrder = [SELECT Id FROM Order WHERE RecordType.DeveloperName='CustomerOrder' LIMIT 1];
            List<String> assetsId = new List<String>();
            List<String> casesId = new List<String>();
            casesId.add(case1.Id);
            
            Map<String, String> mapParameters = new Map<String, String>();
            mapParameters.put('workType', Constants.ACTIVITY_TYPE_CONTROL);
            mapParameters.put('workOrderEarliestStartDate', '2020-01-01');
            mapParameters.put('workOrderStartDate', '2020-01-01');
            mapParameters.put('workOrderVisitingStartHour','10:00');
            mapParameters.put('workOrderVisitingEndHour','19:00');
            mapParameters.put('workOrderVisitingDays','Lundi');
            mapParameters.put('workOrderServiceNote','test');
            mapParameters.put('workOrderPriority','LOW');
            mapParameters.put('workOrderSchedulingPolicyId',fslSp1.Id);
            mapParameters.put('workOrderMinimumCrewSize ','2');
            
            List<Map<String, String>> skills = new List<Map<String, String>>();
            Map<String, String> oneSkill = new Map<String, String>();
            //List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 1];
            oneSkill.put('id', skillsList[0].Id);
            //oneSkill.put('id','');
            
            List<Map<String, String>> resources = new List<Map<String,String>>();
            Map<String,String> oneRess = new Map<String,String>();
            oneRess.put('id',srList.Id);
            oneRess.put('value','Preferred');
            resources.add(oneRess);

            LWC_CustomWorkOrderWizard.createWorkOrder(newCustomerOrder.Id, assetsId, skills, resources, casesId, mapParameters);

            Test.stopTest();            
        }            
    }
    
    @isTest
    private static void testCreateWorkOrderCustomerOrderDiag(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1'];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource srList = [SELECT Id FROM ServiceResource LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;
            

            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;

            
            List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];            
            ProductSkill__c pk1 = Utils_Test.createProductSkill(skillsList[0].Id, 1, productTest1.Id, true);            
            SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt3.Id, true);

            FSL__Scheduling_Policy__c fslSp1 = [SELECT Id FROM FSL__Scheduling_Policy__c LIMIT 1];
            
            //List<Order> customerOrder = [SELECT Id FROM Order WHERE RecordType.DeveloperName='CustomerOrder' LIMIT 1];
            List<String> assetsId = new List<String>();
            List<String> casesId = new List<String>();
            casesId.add(case1.Id);
            
            Map<String, String> mapParameters = new Map<String, String>();
            mapParameters.put('workType', Constants.ACTIVITY_TYPE_CONTROL);
            mapParameters.put('workOrderEarliestStartDate', '2020-01-01');
            mapParameters.put('workOrderStartDate', '2020-01-01');
            mapParameters.put('workOrderVisitingStartHour','10:00');
            mapParameters.put('workOrderVisitingEndHour','19:00');
            mapParameters.put('workOrderVisitingDays','Lundi');
            mapParameters.put('workOrderServiceNote','test');
            mapParameters.put('workOrderPriority','LOW');
            mapParameters.put('workOrderSchedulingPolicyId',fslSp1.Id);
            mapParameters.put('workOrderMinimumCrewSize ','2');
            
            List<Map<String, String>> skills = new List<Map<String, String>>();
            Map<String, String> oneSkill = new Map<String, String>();
            //List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 1];
            oneSkill.put('id', skillsList[0].Id);
            //oneSkill.put('id','');
            
            List<Map<String, String>> resources = new List<Map<String,String>>();
            Map<String,String> oneRess = new Map<String,String>();
            oneRess.put('id',srList.Id);
            oneRess.put('value','Preferred');
            resources.add(oneRess);

            LWC_CustomWorkOrderWizard.createWorkOrder(newCustomerOrder.Id, assetsId, skills, resources, casesId, mapParameters);

            Test.stopTest();            
        }            
    }
    
    @isTest
    private static void testCreateServiceAppointment(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, false);
            wo.WorkTypeId = wt1.Id;
            insert wo;
            
            
            /*List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];
            
            ProductSkill__c pk1 = Utils_Test.createProductSkill(skillsList[0].Id, 1, productTest1.Id, true);
            
            SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt1.Id, true);
            
            FSL__Scheduling_Policy__c fslSp1 = Utils_Test.createSchedulingPolicy('test',true);*/
            PropertiesUtils.setStringValue('fsl.wizard.priority.urgence.name', 'CRITIQUE');
            Map<String,String> mapParam= new Map<String,String>();
            //Chantier__c[] chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            //WorkOrder[] wo = [SELECT Id, AccountId,ContactId,Street,City,PostalCode,Country FROM WorkOrder LIMIT 1];
            PropertiesUtils.setStringValue('fsl.wizard.schedPolicy.urgence.name', 'Urgence');
            PropertiesUtils.setStringValue('fsl.wizard.schedPolicy.normal.name', 'Planification automatique');
            try{
                // Création du RDV
                ServiceAppointment saToUpdate = new ServiceAppointment();
                saToUpdate = LWC_CustomWorkOrderWizard.createServiceAppointment(wo, chantier.Id, 2, mapParam);
                upsert saToUpdate;
            }
            catch(Exception e){}
            //Test 2 
            
            String workOrderPriority = mapParam.put('workOrderPriority', 'CRITIQUE');
            try{
                // Création du RDV
                ServiceAppointment saToUpdate = new ServiceAppointment();
                saToUpdate = LWC_CustomWorkOrderWizard.createServiceAppointment(wo, chantier.Id, 2, mapParam);
                upsert saToUpdate;
            }
            catch(Exception e){}

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testGetEntityWorkTypeParameters(){  
        Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
        
        Test.startTest();
        
        List<WorkType> wtList = new List<WorkType>();
        WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
        wtList.add(wt1);
        insert wtList;

        EntityWorkTypeParameters__c entWT = new EntityWorkTypeParameters__c();
        entWT.workType__c = wt1.Id;
        entWT.estimatedDuration__c = 2;
        entWT.autoSchedulingDelay__c = 5;
        entWT.entity__c = ent.Id;
        entWT.dueDateDelay__c = 4;
        insert entWT;

        LWC_CustomWorkOrderWizard.getEntityWorkTypeParameters(wt1.Id, ent.Id);

        Test.stopTest();
    }

    
    @isTest
    private static void testGetPreferenceTypePickListValues(){  
        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
        Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
        Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                        FROM PricebookEntry 
                                        WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }
        
        Test.startTest();
        Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
        case1.AssetId=newAsset1.Id;
        insert case1;
        
        OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
        newOrderItem1.case__c=case1.Id;
        insert newOrderItem1;

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
        
        List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];
        
        ProductSkill__c pk1 = Utils_Test.createProductSkill(skillsList[0].Id, 1, productTest1.Id, true);
        
        SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt1.Id, true);
        
        FSL__Scheduling_Policy__c fslSp1 = Utils_Test.createSchedulingPolicy('test',true);
        LWC_CustomWorkOrderWizard.getPreferenceTypePickListValues();
        Test.stopTest();
    }
    
    @isTest
    private static void testClassSkillResult(){  
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

        Test.startTest();
        
        List<WorkType> wtList = new List<WorkType>();
        WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
        WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
        WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
        wtList.add(wt1);
        wtList.add(wt2);
        wtList.add(wt3);
        insert wtList;
        
        
        List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];
        ProductSkill__c pk1 = Utils_Test.createProductSkill(skillsList[0].Id, 1, productTest1.Id, true);
        SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt1.Id, true);
        LWC_CustomWorkOrderWizard.SkillResult sr = new LWC_CustomWorkOrderWizard.SkillResult('id','name',10);
        sr.getId();
        sr.getName();
        sr.getValue();
        Test.stopTest();
    }

    @isTest
    private static void testCheckForServiceAppointmentDebriefed(){

        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];    

        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        System.runAs(user){
            WorkType wt = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, true);
            AfterSalesService__c sav = new AfterSalesService__c(workSite__c = chantier.Id);
            insert sav;

            List<WorkOrder> woList = new List<WorkOrder>();
            WorkOrder wo = Utils_Test.createWorkOrder(wkRTId, false);
            wo.afterSalesService__c = sav.Id;
            wo.WorkTypeId = wt.Id;
            woList.Add(wo);
            
            WorkOrder wo2 = Utils_Test.createWorkOrder(wkRTId, false);
            wo2.afterSalesService__c = sav.Id;
            wo2.WorkTypeId = wt.Id;
            woList.Add(wo2);

            insert woList;
            
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, SASARTId, false);
            sa1.Status=RDV_ENCOURS;
            sa1.afterSalesService__c = sav.Id;
            sa1.ActualStartTime=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.dateConfirmationClient__c=Date.today();
            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            saList.Add(sa1);

            ServiceAppointment sa2 = Utils_Test.createServiceAppointment(wo2.Id, SASARTId, false);
            sa2.Status=RDV_DEBRIEFE;
            sa2.afterSalesService__c = sav.Id;
            sa2.ActualStartTime=Date.today();
            sa2.fsl_dateConfirmation__c=Date.today();
            sa2.dateConfirmationClient__c=Date.today();
            sa2.SchedEndTime=Date.today();
            sa2.SchedStartTime=Date.today();
            saList.Add(sa2);
            
            insert saList;

            Assert.areEqual(false,LWC_CustomWorkOrderWizard.checkForServiceAppointmentDebriefed(sav.Id));
        }
        Test.stopTest();

    }

    @isTest
    private static void testInitDueDate(){
        Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];

        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, true);

            EntityWorkTypeParameters__c entWT = new EntityWorkTypeParameters__c();
            entWT.workType__c = wt1.Id;
            entWT.estimatedDuration__c = 2;
            entWT.autoSchedulingDelay__c = 5;
            entWT.entity__c = ent.Id;
            entWT.dueDateDelay__c = 4;
            insert entWT;

            Datetime today = Datetime.valueOf(Date.today()+' 00:00:00');

            Assert.areEqual(Datetime.valueOf(today.addMonths(4).format('yyyy-MM-dd hh:mm:ss')),LWC_CustomWorkOrderWizard.initDueDate(Date.today(),entWT.Id));
        }
        Test.stopTest();
    }
}