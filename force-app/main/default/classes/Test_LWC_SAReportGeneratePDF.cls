//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_SAReportGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/03/2023
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_SAReportGeneratePDF
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_SAReportGeneratePDF {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_ORD_PROVIDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Id RT_WO_KUBE3 = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
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
            List<ServiceResource> listeSR = TestData_fsl_Setup.createServiceResource(u);       
            List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Annulé');
            FSL.GlobalAPIS.addStatusTransition('Demandé', 'Débriefé');
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

            PropertiesUtils.setBooleanValue('merkure.api.debug', true);

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
            accToInsert.add(accountTest);
            accToInsert.add(entiteDep);
            accToInsert.add(entiteMag);
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
            
            List<Order> orderList = new List<Order>();
            Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, entiteMag.id, entiteDep.id, false);
            orderList.add(newCustomerOrder);
            insert orderList;
            
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;
    }

    @isTest
    private static void testGenerate() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            Test.startTest();
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, newCustomerOrder.Id, false);
            wo.AccountId = accountTest.Id;
            wo.WorkTypeId = wt1.Id;
            wo.ServiceTerritoryId = st.Id;
            wo.Chantier__c = chantier.Id;
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
            sa1.account__c = accountTest.Id;
            sa1.Status = Constants.RDV_FSL_TERMINE;
            sa1.ServiceTerritoryId = st.Id;
            sa1.customerOrder__c = newCustomerOrder.Id;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.dateConfirmationClient__c=Date.today();
            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            sa1.FSL__Schedule_Mode__c = 'Automatic';
            insert sa1;

            try{
                LWC_SAReportGeneratePDF.renderSADocumentPDF(sa1.Id, 'Test SA');
            }
            catch(Exception e){ }

            Test.stopTest();
        }
    }

    @isTest
    private static void testLinkDocumentToRecordError(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        Test.startTest();
        System.runAs(user){
            try{
                LWC_SAReportGeneratePDF.linkDocumentToRecord(null, null, null);
            }
            catch(Exception e){

            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testGetSAInformationError(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        Test.startTest();
        System.runAs(user){
            try{
                LWC_SAReportGeneratePDF.getSAInformation(null);
            }
            catch(Exception e){

            }
        }
        Test.stopTest();
    }
}