//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_RepriseRDVKube3
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/05/2023
//-- Version     : 1.0
//-- Description : Classe de tests de BA_RepriseRDVKube3
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_BA_RepriseRDVKube3 {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_WO_KUBE2 = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    private static final Id RT_WO_KUBE3 = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

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
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'En cours');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Terminé');
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
            entiteDep.migratedToK3__c = true;
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
            chantier.rue__c = 'TEST';
            chantier.departement__c = 'TEST';
            insert chantier;
            
            List<Product2> prodList = new List<Product2>();
            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
            productTest1.isControllable__c=true;
            prodList.add(productTest1);
            insert prodList;

            // Price book
            PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :productTest1.Id LIMIT 1];
            
            List<Order> orderList = new List<Order>();
            Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, entiteMag.id, entiteDep.id, false);
            newCustomerOrder.legacyReference__c = '0615157089';
            newCustomerOrder.isLegacy__c = true;
            orderList.add(newCustomerOrder);
            insert orderList;
            
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;

            OrderItem ordItem = Utils_Test.createOrderItem(newCustomerOrder.Id, priceBookEntry.Id, newAsset1.Id, productTest1.Id, false);
            ordItem.name__c = 'TestOrderItem';
            insert ordItem;
    }

    @isTest
    private static void testRepriseOneEntity(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account dep = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order ord = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'CustomerOrder' LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            Test.startTest();
            
            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);      
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();    
            WorkType wt = Utils_Test.createWorkType(Constants.WORKTYPE_METRAGE, true);

            ord.Status = 'Closed';
            update ord;
            
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
            wo.fsl_externalId__c = 'MET/0615157089/01';
            wo.FSL__VisitingHours__c = oh.id;
            insert wo;
            
            ServiceAppointment sa = [SELECT SchedStartTime, SchedEndTime, Duration FROM ServiceAppointment WHERE ParentRecordId =: wo.id]; 
            
            sa.fsl_externalId__c = 'MET/0615157089/01';
            sa.EarliestStartTime = Date.today();
            sa.SchedStartTime = Date.today();
            sa.Duration = 180.0;
            sa.fsl_dateConfirmation__c = date.today();
            Integer duration= Integer.valueOf(sa.Duration);        
            sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
            sa.ActualStartTime=Date.today();
            sa.ActualEndTime=Date.today();
            sa.Status = Constants.RDV_FSL_CONFIRME;
            update sa;

            // Batch
            BA_RepriseRDVKube3 ba= new BA_RepriseRDVKube3(dep.Id, false, new List<String>{'0615157089'});
            Database.executeBatch(ba);

            Test.stopTest();
        }
    }

    @isTest
    private static void testRepriseMultiEntity(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account dep = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order ord = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'CustomerOrder' LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            Test.startTest();
            
            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);      
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();             
            WorkType wt = Utils_Test.createWorkType(Constants.WORKTYPE_INSTALLATION, true);

            ord.Status = 'Closed';
            update ord;
            
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
            wo.fsl_externalId__c = 'INS/0615157089/01';
            wo.FSL__VisitingHours__c = oh.id;
            insert wo;
            
            ServiceAppointment sa = [SELECT SchedStartTime, SchedEndTime, Duration FROM ServiceAppointment WHERE ParentRecordId =: wo.id]; 
            
            sa.fsl_externalId__c = 'INS/0615157089/01';
            sa.EarliestStartTime = Date.today();
            sa.SchedStartTime = Date.today();
            sa.Duration = 180.0;
            sa.fsl_dateConfirmation__c = date.today();
            Integer duration= Integer.valueOf(sa.Duration);        
            sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
            sa.ActualStartTime=Date.today();
            sa.ActualEndTime=Date.today();
            sa.Status = Constants.RDV_FSL_CONFIRME;
            update sa;

            // Batch
            BA_RepriseRDVKube3 ba= new BA_RepriseRDVKube3(null, false, null);
            Database.executeBatch(ba);

            Test.stopTest();
        }
    }

    @isTest
    private static void testMigrationOneEntity(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account dep = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            Test.startTest();
            
            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);      
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();    
            WorkType wt = Utils_Test.createWorkType(Constants.WORKTYPE_METRAGE, true);
            Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, true);
            
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
            wo.fsl_externalId__c = 'MET/0615157089/01';
            wo.FSL__VisitingHours__c = oh.id;
            insert wo;
            
            ServiceAppointment sa = [SELECT SchedStartTime, SchedEndTime, Duration FROM ServiceAppointment WHERE ParentRecordId =: wo.id]; 
            
            sa.fsl_externalId__c = 'MET/0615157089/01';
            sa.EarliestStartTime = Date.today();
            sa.fsl_dateConfirmation__c = date.today();
            sa.Status = Constants.RDV_FSL_DEMANDE;
            update sa;

            // Batch
            BA_RepriseRDVKube3 ba= new BA_RepriseRDVKube3(dep.Id, true, null);
            Database.executeBatch(ba);

            Test.stopTest();
        }
    }
    @isTest
    private static void testRepriseWO(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account dep = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order ord = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'CustomerOrder' LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            Test.startTest();
            
            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);      
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();    
            WorkType wt = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, true);
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, null, false);
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
            wo.fsl_externalId__c = 'MET/0615157089/01';
            wo.FSL__VisitingHours__c = oh.id;
            wo.customerOrder__c = ord.id;
            insert wo;

            // Batch
            BA_RepriseWOKube3 ba = new BA_RepriseWOKube3(dep.Id);
            Database.executeBatch(ba);

            Test.stopTest();
        }
    }
}