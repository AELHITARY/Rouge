//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_WorkOrderAndLineItem
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/02/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_WorkOrderAndLineItem {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_ORD_PROVIDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Id RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id RT_WO_SERVICE = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id RT_WO_KUBE2 = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    private static final Id RT_SA_KUBE3 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');

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
            Account accountTestAutreProp = Utils_Test.createAccount('Bertrand', 'Paul','test@test.fr', RT_ACC_PERSO, 'Email',false);
            Account accountTestOccupant = Utils_Test.createAccount('Jean','Michel','test@test.fr', RT_ACC_PERSO, 'Email',false);
            Account accountTestAutreOccupant = Utils_Test.createAccount('Bernard','Thierry','test@test.fr', RT_ACC_PERSO, 'Email',false);
            Account accountTestLocataire = Utils_Test.createAccount('Blanchard','Sylvie','test@test.fr', RT_ACC_PERSO, 'Email',false);
            Account accountTestAutreLocataire = Utils_Test.createAccount('Martin','Mathilde','test@test.fr', RT_ACC_PERSO, 'Email',false);
            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
            accToInsert.add(accountTest);
            accToInsert.add(accountTestAutreProp);
            accToInsert.add(accountTestOccupant);
            accToInsert.add(accountTestAutreOccupant);
            accToInsert.add(accountTestLocataire);
            accToInsert.add(accountTestAutreLocataire);
            accToInsert.add(entiteDep);
            accToInsert.add(entiteMag);
            accToInsert.add(provider1);
            insert accToInsert;
            
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id, accountTestAutreProp.Id,
                                                                            accountTestLocataire.Id, accountTestAutreLocataire.Id, 
                                                                            accountTestOccupant.Id, accountTestAutreOccupant.Id, false);
            chantier.serviceEntity__c = entiteDep.id;
            chantier.salesEntity__c = entiteMag.id;
            chantier.complementAdresse__c = 'TEST';
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
    private static void testCreateWOKube3(){
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
            
            Test.startTest();
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo.AccountId = accountTest.Id;
            wo.WorkTypeId = wt1.Id;
            wo.chantier__c = chantier.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testWOKube3Chantier(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            
            Test.startTest();
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;

            // Test différent contact chantier
            chantier.occupant__c = null;
            update chantier;

            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo.AccountId = accountTest.Id;
            wo.WorkTypeId = wt1.Id;
            wo.chantier__c = chantier.Id;
            insert wo;

            chantier.occupant__c = null;
            chantier.autreOccupant__c = null;            
            update chantier;
            
            WorkOrder wo2 = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo2.AccountId = accountTest.Id;
            wo2.WorkTypeId = wt1.Id;
            wo2.chantier__c = chantier.Id;
            insert wo2;

            chantier.occupant__c = null;
            chantier.autreOccupant__c = null;   
            chantier.locataire__c = null;           
            update chantier;
            
            WorkOrder wo3 = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo3.AccountId = accountTest.Id;
            wo3.WorkTypeId = wt1.Id;
            wo3.chantier__c = chantier.Id;
            insert wo3;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUpdateWOLI_PNC(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
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
            wo.WorkTypeId = wt2.Id;
            //wo.AccountId = accountTest.Id;
            wo.chantier__c = chantier.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            insert woliList;

            woli.productNonCompliance__c=case1.Id;
            update woli;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUpdateWOLI_Asset(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            
            Test.startTest();
            
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
            wo.AccountId = accountTest.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            insert woliList;

            woli.Status = 'Terminé';
            update woli;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUpdateWOLI_Asset2(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            
            Test.startTest();
            
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
            wo.AccountId = accountTest.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            insert woliList;

            woli.Status = 'Annulé';
            update woli;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testDeleteWO(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            
            Test.startTest();
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, newCustomerOrder.Id, false);
            wo.AccountId = accountTest.Id;
            wo.WorkTypeId = wt1.Id;
            wo.chantier__c = chantier.Id;
            insert wo;

            // TEST
            delete wo;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testSAKube2(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            Test.startTest();
            
            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);            
            WorkType wt = TestData_fsl_Setup.createWorkType();
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE2, null, false);
            wo.AccountId = accountTest.Id;
            wo.WorkTypeId = wt.Id;
            wo.ServiceTerritoryId = st.Id;
            wo.Chantier__c = chantier.Id;
            wo.StartDate=Date.today();
            wo.EndDate=Date.today()+30;
            wo.Duration=2;
            wo.DurationType='Hours';
            wo.Subject='TEST';
            wo.ContratK__c = contratSAV.Id;
            insert wo;

            Test.stopTest();
        }
    }
}