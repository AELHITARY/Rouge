//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_ServiceAppointment
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/04/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_ServiceAppointment {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_ORD_PROVIDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
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
        	
        	WorkType wt = utils_Test.createWorkType('Intervention', true);
        	
    }
    
    @isTest
    private static void testCreateSAKube3(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Test.startTest();
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];

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
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
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

            // Coverage des Validation rules APEX pour le statut "Terminé"
            sa1.cancellingComment__c = 'test';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingReason__c = 'Refus client';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualStartTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateConfirmation__c = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedStartTime = null;           
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            // Coverage des Validation rules APEX pour le statut "Debriefé"
            sa1.Status = Constants.RDV_FSL_DEBRIEFE;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            sa1.fsl_dateDebriefing__c=Date.today();
            sa1.cancellingDate__c=null;
            sa1.cancellingReason__c=null;
            sa1.cancellingComment__c = 'test';

            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingReason__c = 'Refus client';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualStartTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateConfirmation__c = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedStartTime = null;           
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            // Coverage des Validation rules APEX pour le statut "En cours"
            sa1.Status = Constants.RDV_FSL_ENCOURS;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.SchedEndTime=null;
            sa1.SchedStartTime=Date.today();
            sa1.fsl_dateDebriefing__c=null;
            sa1.cancellingComment__c='test';
            sa1.cancellingDate__c=null;
            sa1.cancellingReason__c=null;

            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingReason__c = 'Refus client';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualEndTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualStartTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateConfirmation__c = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedStartTime = null;           
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }  

            // Coverage des Validation rules APEX pour le statut "Confirmé"
            sa1.Status = Constants.RDV_FSL_CONFIRME;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.SchedEndTime=null;
            sa1.SchedStartTime=null;
            sa1.fsl_dateDebriefing__c=null;
            sa1.cancellingComment__c='test';
            sa1.cancellingDate__c=null;
            sa1.cancellingReason__c=null;

            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingReason__c = 'Refus client';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualEndTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualStartTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateConfirmation__c = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedStartTime = null;           
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }  

            // Coverage des Validation rules APEX pour le statut "Transmis"
            sa1.Status = Constants.RDV_FSL_TRANSMIS;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            sa1.dateTransmission__c=Date.today();
            sa1.fsl_dateConfirmation__c=null;
            sa1.SchedEndTime=null;
            sa1.SchedStartTime=null;
            sa1.fsl_dateDebriefing__c=null;
            sa1.cancellingComment__c='test';
            sa1.cancellingDate__c=null;
            sa1.cancellingReason__c=null;

            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingReason__c = 'Refus client';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualEndTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualStartTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateConfirmation__c = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.dateTransmission__c = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedStartTime = null;           
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }  

            // Coverage des Validation rules APEX pour le statut "Planifié"
            sa1.Status = Constants.RDV_FSL_PLANIFIE;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            sa1.dateTransmission__c=null;
            sa1.fsl_dateConfirmation__c=null;
            sa1.SchedEndTime=null;
            sa1.SchedStartTime=null;
            sa1.fsl_dateDebriefing__c=null;
            sa1.cancellingComment__c='test';
            sa1.cancellingDate__c=null;
            sa1.cancellingReason__c=null;

            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingReason__c = 'Refus client';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualEndTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualStartTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateConfirmation__c = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.dateTransmission__c = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedEndTime = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedStartTime = null;           
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }  

            // Coverage des Validation rules APEX pour le statut "Demandé"
            sa1.Status = Constants.RDV_FSL_DEMANDE;
            sa1.ActualEndTime=null;
            sa1.ActualStartTime=null;
            sa1.dateTransmission__c=null;
            sa1.fsl_dateConfirmation__c=null;
            sa1.SchedEndTime=null;
            sa1.SchedStartTime=null;
            sa1.fsl_dateDebriefing__c=null;
            sa1.cancellingComment__c='test';
            sa1.cancellingDate__c=null;
            sa1.cancellingReason__c=null;

            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingReason__c = 'Refus client';
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualEndTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.ActualStartTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateConfirmation__c = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.dateTransmission__c = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedEndTime = Date.today();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.SchedStartTime = Date.today();          
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }  

            // Coverage des Validation rules APEX pour le statut "Annulé"
            sa1.Status = Constants.RDV_FSL_ANNULE;
            sa1.fsl_dateDebriefing__c=null;
            sa1.cancellingDate__c=System.now();
            sa1.cancellingReason__c=null;

            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.cancellingDate__c = null;
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            sa1.fsl_dateDebriefing__c = System.now();
            try{
                insert sa1;
            } catch(Exception e) {
                system.debug(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            }

            // Création succès
            sa1.Status = Constants.RDV_FSL_TERMINE;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            sa1.fsl_dateDebriefing__c=null;
            sa1.cancellingComment__c=null;
            sa1.cancellingDate__c=null;
            sa1.cancellingReason__c=null;
            insert sa1;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUpdateSAKube3(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
                
        System.runAs(user){
            Test.startTest();
            
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];            

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
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, newCustomerOrder.Id, false);
            wo.AccountId = accountTest.Id;
            wo.WorkTypeId = wt2.Id;
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
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList; 
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, RT_SA_KUBE3, false);
            sa1.customerOrder__c = newCustomerOrder.Id;
            sa1.ServiceTerritoryId = st.Id;
            insert sa1;

            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            sa1.Status = Constants.RDV_FSL_PLANIFIE;
            update sa1;            

            List<AssignedResource> listeAR = new list<AssignedResource> ();
            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa1.id;
            ar1.ServiceResourceId = sr.id;
            ar1.fsl_typeRessourceAttribuee__c = 'Principale';
            listeAR.add(ar1);
            insert listeAR;

            sa1.Status = Constants.RDV_FSL_TRANSMIS;
            update sa1;    

            sa1.dateTransmission__c=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.dateConfirmationClient__c=Date.today();
            sa1.Status = Constants.RDV_FSL_TERMINE;
            //update sa1;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUpdateConfirmSAKube3(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Test.startTest();
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Intervention'];

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
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, newCustomerOrder.Id, false);
            wo.WorkTypeId = wt1.Id;
            wo.AccountId = accountTest.Id;
            wo.ServiceTerritoryId = st.Id;
            wo.Chantier__c = chantier.Id;
            wo.DurationType = 'Hours';
            wo.Duration = 1;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList; 
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, RT_SA_KUBE3, false);
            sa1.customerOrder__c = newCustomerOrder.Id;
            sa1.WorkTypeId = wt.Id;
            sa1.ServiceTerritoryId = st.Id;
            sa1.account__c = accountTest.Id;
            sa1.DurationType = 'Hours';
            sa1.Duration = 1;
            insert sa1;

            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            sa1.Status = Constants.RDV_FSL_PLANIFIE;
            update sa1;            

            List<AssignedResource> listeAR = new list<AssignedResource> ();
            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa1.id;
            ar1.ServiceResourceId = sr.id;
            ar1.fsl_typeRessourceAttribuee__c = 'Principale';
            listeAR.add(ar1);
            insert listeAR;

            sa1.dateTransmission__c=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.dateConfirmationClient__c=Date.today();
            update sa1;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUpdateDebriefSAKube3(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment';
        update user;
                
        System.runAs(user){
            Test.startTest();
            
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];

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
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, newCustomerOrder.Id, false);
            wo.WorkTypeId = wt1.Id;
            wo.AccountId = accountTest.Id;
            wo.ServiceTerritoryId = st.Id;
            wo.Chantier__c = chantier.Id;
            wo.DurationType = 'Minutes';
            wo.Duration = 1;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList; 
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, RT_SA_KUBE3, false);
            sa1.customerOrder__c = newCustomerOrder.Id;
            sa1.ServiceTerritoryId = st.Id;
            sa1.account__c = accountTest.Id;
            sa1.DurationType = 'Minutes';
            sa1.Duration = 1;
            insert sa1;

            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            sa1.Status = Constants.RDV_FSL_PLANIFIE;
            update sa1;            

            List<AssignedResource> listeAR = new list<AssignedResource> ();
            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa1.id;
            ar1.ServiceResourceId = sr.id;
            ar1.fsl_typeRessourceAttribuee__c = 'Principale';
            listeAR.add(ar1);
            insert listeAR;

            sa1.dateTransmission__c=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.dateConfirmationClient__c=Date.today();
            update sa1;
            sa1.ActualEndTime=Date.today();
            sa1.ActualStartTime=Date.today();
            update sa1;

            sa1.fsl_dateDebriefing__c=Date.today();
            sa1.Status = Constants.RDV_FSL_DEBRIEFE;
            update sa1;

            sa1.Status = Constants.RDV_FSL_DEMANDE;
            update sa1;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testCancelSAKube3(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            
            Test.startTest();
            
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];

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
            sa1.customerOrder__c = newCustomerOrder.Id;
            sa1.account__c = accountTest.Id;
            sa1.ServiceTerritoryId = st.Id;
            insert sa1;

            sa1.cancellingDate__c =Date.today();
            sa1.serviceReportToCreate__c = true;
            update sa1;

            /*sa1.cancellingDate__c = null;
            sa1.Status = Constants.RDV_FSL_DEMANDE;
            update sa1;
            sa1.Status = Constants.RDV_FSL_ANNULE;
            update sa1;*/

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testDeleteWOLIKube3(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Test.startTest();
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

            Case ncp = new Case(
                RecordTypeId = RT_PNC_INTERNALID,
                AccountId = accountTest.Id,
                AssetId = newAsset1.Id,
                chantier__c = chantier.Id,
                Subject = 'test',
                Description = 'test',
                requiredOrder__c = 'Non',
                Status = 'Nouveau',
                diagnosticDate__c = Date.today()
            );
            insert ncp;
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            insert newOrderItem1;
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, newCustomerOrder.Id, false);
            wo.WorkTypeId = wt2.Id;
            wo.AccountId = accountTest.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woli.productNonCompliance__c = ncp.Id;
            woliList.add(woli);
            WorkOrderLineItem woli2 =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset2.Id, false);
            woli2.Status=Constants.WOLI_FSL_TERMINE;
            woliList.add(woli2);
            insert woliList;
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, RT_SA_KUBE3, false);
            sa1.customerOrder__c = newCustomerOrder.Id;
            insert sa1;

            delete woli2;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testDeleteSAKube3(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = false;
        update user;
                
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
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            insert newOrderItem1;
            
            List<WorkType> wtList = new List<WorkType>();
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
            WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
            WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
            wtList.add(wt1);
            wtList.add(wt2);
            wtList.add(wt3);
            insert wtList;
            
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_KUBE3, newCustomerOrder.Id, false);
            wo.WorkTypeId = wt2.Id;
            wo.AccountId = accountTest.Id;
            insert wo;

            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, newAsset1.Id, false);
            woliList.add(woli);
            insert woliList;
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, RT_SA_KUBE3, false);
            sa1.customerOrder__c = newCustomerOrder.Id;
            sa1.account__c = null;
            insert sa1;
            delete sa1;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testCreateSAKube2(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
                
        System.runAs(user){
            Test.startTest();
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            
            
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
    
    @isTest
    private static void testUpdateCancelSAKube2(){
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
        
        ServiceAppointment sa = [SELECT SchedStartTime, cancellingDate__c, SchedEndTime, Duration FROM ServiceAppointment WHERE ParentRecordId =: wo.id]; 
        sa.cancellingDate__c = Date.today();
        sa.Status = Constants.RDV_FSL_ANNULE;
        update sa;

        Test.stopTest();
    }
    
    @isTest
    private static void testUpdateConfirmSAKube2(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment';
        update user;
                
        System.runAs(user){
            Test.startTest();
            
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];
            
            
            
            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);    
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();             
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
            wo.FSL__VisitingHours__c = oh.id;
            insert wo;
            
            ServiceAppointment sa = [SELECT SchedStartTime, SchedEndTime, Duration FROM ServiceAppointment WHERE ParentRecordId =: wo.id]; 

            sa.EarliestStartTime = Date.today();
            sa.SchedStartTime = Date.today();
            sa.Duration = 180.0;
            Integer duration= Integer.valueOf(sa.Duration);        
            sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
            update sa;
            
            /*List<AssignedResource> listeAR = new list<AssignedResource> ();
            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa.id;
            ar1.ServiceResourceId = sr.id;
            ar1.fsl_typeRessourceAttribuee__c = 'Principale';
            listeAR.add(ar1);
            insert listeAR;

            sa.fsl_dateConfirmation__c = date.today();
            update sa;*/

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUpdateDebriefSAKube2(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR021_KContrat';
        update user;
                
        System.runAs(user){
            Test.startTest();
            
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE KparKReference__c='DEP' LIMIT 1];                     

            KContrat__c contratSAV = TestData_fsl_Setup.createContrat(accountTest,chantier);  
            OperatingHours oh = TestData_fsl_Setup.createOperatingHours();              
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
            wo.FSL__VisitingHours__c = oh.id;
            insert wo;
            
            ServiceAppointment sa = [SELECT SchedStartTime, SchedEndTime, Duration FROM ServiceAppointment WHERE ParentRecordId =: wo.id]; 
            
            List<AssignedResource> listeAR = new list<AssignedResource> ();
            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa.id;
            ar1.ServiceResourceId = sr.id;
            ar1.fsl_typeRessourceAttribuee__c = 'Principale';
            listeAR.add(ar1);
            //insert listeAR;

            sa.EarliestStartTime = Date.today();
            sa.SchedStartTime = Date.today();
            sa.Duration = 180.0;
            sa.fsl_dateConfirmation__c = date.today();
            Integer duration= Integer.valueOf(sa.Duration);        
            sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
            sa.ActualStartTime=Date.today();
            sa.ActualEndTime=Date.today();
            //sa.Status = Constants.RDV_FSL_DEBRIEFE;
            update sa;

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUtils(){
        TR020_ServiceAppointment.calculActualDurationKube2(System.now(), System.now(), 0, 10);
        TR020_ServiceAppointment.calculActualDurationKube2(System.now(), System.now()+10, 0, 10);
        TR020_ServiceAppointment.calculDurationKube3(System.now(), System.now()+10, 'Minutes');
        TR020_ServiceAppointment.calculDurationKube3(System.now(), System.now()+10, 'Hours');
        TR020_ServiceAppointment.calculActualStartTime(System.now(), 30, 'Minutes');
        TR020_ServiceAppointment.calculActualStartTime(System.now(), 1, 'Hours');
    }
}