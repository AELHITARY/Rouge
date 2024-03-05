//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Site_ConfirmationClientRDV
//-- Modifié par : Franck GOURDEAUX
//-- Modifié le  : 03/05/2023
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Site_ConfirmationClientRDV {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_ORD_CUSTOMER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final Id RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id RT_PNC_INTERNALID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id RT_WO_KUBE3 = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id RT_WO_KUBE2 = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    private static final Id RT_SA_KUBE3 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final Id RT_SA_KUBE2 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');

    @testSetup 
    static void setup() {
            // FSL
            FSL__Scheduling_Policy__c fslSp1 = Utils_Test.createSchedulingPolicy('test',true);
            List<GlobalProperties__c> synchro= TestData_fsl_Setup.createGlobalProperties();  
            User [] u = TestData_fsl_Setup.createUser();
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();            
            ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
            ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);            
            List<ServiceResource> listeSR = TestData_fsl_Setup.createServiceResource(u);       
            List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Annulé');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Débriefé');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Transmis');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'Confirmé');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'Demandé');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'Annulé');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'Terminé');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'Transmis');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'En cours');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'Débriefé');
            FSL.GlobalAPIS.addStatusTransition('Planifié', 'En route');
            FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Planifié');
            FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Demandé');
            FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Débriefé');
            FSL.GlobalAPIS.addStatusTransition('Transmis', 'Terminé');
            FSL.GlobalAPIS.addStatusTransition('Terminé', 'Débriefé');
            FSL.GlobalAPIS.addStatusTransition('Débriefé', 'Demandé');

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
            accountTest.personMailingStreet = '150 rue gallieni';
            accountTest.personMailingPostalCode = '92100';
            accountTest.personMailingCity = 'Boulogne Billancourt';
            accountTest.personMailingCountry = 'France';
            accToInsert.add(accountTest);
            accToInsert.add(entiteDep);
            accToInsert.add(entiteMag);
            insert accToInsert;
            
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
            chantier.serviceEntity__c = entiteDep.id;
            chantier.salesEntity__c = entiteMag.id;
            chantier.rue__c = '150 rue gallieni';
            chantier.codePostal__c = '92100';
            chantier.ville__c = 'Boulogne Billancourt';
            chantier.pays__c = 'France';
            insert chantier;
            
            List<Product2> prodList = new List<Product2>();
            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
            productTest1.isControllable__c=true;
            prodList.add(productTest1);
            Product2 productTest2 = Utils_Test.createProduct('Test2', 'TEST2' , false);
            prodList.add(productTest2);
            insert prodList;
            
            Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, entiteMag.id, entiteDep.id, false);
            insert newCustomerOrder;
            
            List<Asset> astList = new List<Asset>();
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test2', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);            
            astList.add(newAsset1);
            astList.add(newAsset2);
            insert astList;
    }

    @isTest
    private static void testKube2() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_CUSTOMER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];      
    
            Test.startTest();
                
            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);      
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();    
            WorkType wt = Utils_Test.createWorkType(Constants.WORKTYPE_METRAGE, true);
            
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
            wo.FSL__VisitingHours__c = oh.id;
            insert wo;
            
            ServiceAppointment sa = [SELECT SchedStartTime, SchedEndTime, Duration FROM ServiceAppointment WHERE ParentRecordId =: wo.id];         
            sa.WorkTypeId = wt.Id;
            sa.ServiceTerritoryId = st.Id;
            sa.Chantier__c = chantier.Id;
            sa.customerOrder__c = newCustomerOrder.Id;        
            sa.SchedStartTime = DateTime.now().addHours(1);
            sa.SchedEndTime   = DateTime.now().addHours(2);
            update sa;
    
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            insert woliList; 
    
            sa.fsl_dateConfirmation__c = Date.today();
            sa.Status = Constants.RDV_FSL_TRANSMIS;
            update sa;    
    
            PageReference newPRPage  = Page.VF_Site_ConfirmationClientRDV;
            newPRPage.getParameters().put('rdvId',sa.Id);
            Test.setCurrentPage (newPRPage);
    
            Ctrl_Site_COnfirmationClientRDV ctrl = new Ctrl_Site_COnfirmationClientRDV();            
            Ctrl_Site_COnfirmationClientRDV.confirmRDV(sa.Id);
    
            Test.stopTest();    
        }    
    }

    @isTest
    private static void testKube3() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_CUSTOMER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
    
            Test.startTest();
    
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            insert wt1;
                
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, newCustomerOrder.Id, false);
            wo.AccountId = accountTest.Id;
            wo.WorkTypeId = wt1.Id;
            wo.ServiceTerritoryId = st.Id;
            wo.Chantier__c = chantier.Id;
            wo.customerOrder__c = newCustomerOrder.Id;
            wo.StartDate=Date.today();
            wo.EndDate=Date.today()+30;
            wo.Duration=2;
            wo.DurationType='Hours';
            wo.Subject='TEST';
            insert wo;
    
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            insert woliList; 
                
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, RT_SA_KUBE3, false);
            sa1.WorkTypeId = wt1.Id;
            sa1.ServiceTerritoryId = st.Id;
            sa1.Chantier__c = chantier.Id;
            sa1.customerOrder__c = newCustomerOrder.Id;
            sa1.SchedStartTime = DateTime.now().addHours(1);
            sa1.SchedEndTime   = DateTime.now().addHours(2);
            insert sa1;
    
            sa1.dateTransmission__c = Date.today();
            sa1.Status = Constants.RDV_FSL_TRANSMIS;
            update sa1;    
    
            PageReference newPRPage  = Page.VF_Site_ConfirmationClientRDV;
            newPRPage.getParameters().put('rdvId',sa1.Id);
            Test.setCurrentPage (newPRPage);
    
            Ctrl_Site_COnfirmationClientRDV ctrl = new Ctrl_Site_COnfirmationClientRDV();            
            Ctrl_Site_COnfirmationClientRDV.confirmRDV(sa1.Id);
    
            Test.stopTest();     
        }   
    }
}