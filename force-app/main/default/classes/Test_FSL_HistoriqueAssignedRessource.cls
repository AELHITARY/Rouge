//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : Test_FSL_HistoriqueAssignedRessource
//-- Modifié par : CGI
//-- Modifié le  : 03/09/2019
//-- Version     : 1.0
//-- Description : Classe de test vérifier la création d'une ligne d'historique lors de la suppression d'une ressource sur un RDV
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_FSL_HistoriqueAssignedRessource {
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_WO_SERVICE = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    private static final Id RT_SA_KUBE2 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
 
    @testSetup
    public static void testSetup(){
        List<GlobalProperties__c> listeGP = TestData_fsl_Setup.createGlobalProperties();
       
        System.debug('**GlobalProperties__c'+listeGP);
        
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Demandé');

        
        Account accountTest = Utils_Test.createAccount('Dupont','Jean','test@test.fr', RT_ACC_PERSO, 'Email',true);
        List<GlobalProperties__c> synchro= TestData_fsl_Setup.createGlobalProperties();  
        User [] u = TestData_fsl_Setup.createUser();
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);

        /*
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        WorkOrder wo= TestData_fsl_Setup.createTestCAWorkOrder(a,wt,st,null,oh);
        
        //Creation des utilisateurs 
        Profile[] pf= [Select Id from profile where Name LIKE '%Ressource%']; 
        
        List<User> listeUser=new List<User>();
        User u1=new User(firstname = 'Test', 
                         lastName = 'Resource1', 
                         email = 'test.resource1@example.com', 
                         Username = 'test.resource1@kpark.fr.fsl.test', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'res1',  
                         TimeZoneSidKey = 'Europe/Paris', 
                         LocaleSidKey = 'fr_FR_EURO', 
                         LanguageLocaleKey = 'fr', 
                         matriculeGC__c = 'testResource1',
                         IsActive = true,
                         ProfileId = pf[0].Id,
                         dateEntree__c = Date.newInstance(2017, 1, 1)
                        );        
        listeUser.add(u1);
        
        User u2=new User(firstname = 'Test', 
                         lastName = 'Resource2', 
                         email = 'test.resource2@example.com', 
                         Username = 'test.resource2@kpark.fr.fsl.test', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'res2', 
                         TimeZoneSidKey = 'Europe/Paris', 
                         LocaleSidKey = 'fr_FR_EURO', 
                         LanguageLocaleKey = 'fr', 
                         matriculeGC__c = 'testResource2',
                         IsActive = true,
                         ProfileId = pf[0].Id,
                         dateEntree__c = Date.newInstance(2017, 1, 1)                                                 
                        );       
        listeUser.add(u2);
        insert listeUser;
        
        //Creation des ressources
        List<ServiceResource> listeSR =new List<ServiceResource> ();
        ServiceResource sr1= new ServiceResource(
            fsl_matriculeGC__c='RES01',
            fsl_SGID__c='SGID01',
            name='MetreurTest',
            ResourceType='T',
            RelatedRecordId=listeUser[0].id,
            IsActive=true,
            IsCapacityBased=true);           
        listeSR.add(sr1);
        
        ServiceResource sr2= new ServiceResource(
            fsl_matriculeGC__c='RES02',
            fsl_SGID__c='SGID02',
            name='PoseurTest',
            ResourceType='T',
            RelatedRecordId=listeUser[1].id,
            IsActive=true);           
        listeSR.add(sr2);
        insert listeSR;
        
        //Creation de membre de territoires
        List<ServiceTerritoryMember> listeSTM=new List<ServiceTerritoryMember> ();
        ServiceTerritoryMember stm1= new ServiceTerritoryMember(
            EffectiveStartDate=Date.newInstance(2017, 1, 1),
            ServiceResourceId=sr1.id,
            ServiceTerritoryId=st.id,
            TerritoryType='P',
            OperatingHoursId=oh.Id);           
        listeSTM.add(stm1);
        
        ServiceTerritoryMember stm2= new ServiceTerritoryMember(
            EffectiveStartDate=Date.newInstance(2017, 1, 1),
            ServiceResourceId=sr2.id,
            ServiceTerritoryId=st.id,
            TerritoryType='P',
            OperatingHoursId=oh.Id);           
        listeSTM.add(stm2); 
        insert listeSTM;  
        */
        
        /*GlobalProperties__c gpwo = new GlobalProperties__c(
            Name = 'fsl.platformEvent.sync.sa',
            actif__c = true,
            dateTimeValue__c = DateTime.newInstanceGmt(2019, 02, 20, 14, 50, 00)
        );
        insert gpwo;
        
        GlobalProperties__c gpwo2 = new GlobalProperties__c(
            Name = 'fsl.platformEvent.exception.email',
            actif__c = true,
            stringValue__c = 'test@gmail.com'
        );
        insert gpwo2;
        
        GlobalProperties__c gpwo3 = new GlobalProperties__c(
            Name = 'fsl.platformEvent.check.email',
            actif__c = true,
            stringValue__c = 'test@gmail.com'
        );
        insert gpwo3;    
        
        
        GlobalProperties__c gpwo4 = new GlobalProperties__c(
            Name = 'fsl.calculCA.calendrierService.debut',
            actif__c = true,
            dateTimeValue__c = Date.newInstance(2019, 07, 01)
        );
        insert gpwo4;
        
        GlobalProperties__c gpwo5 = new GlobalProperties__c(
            Name = 'fsl.calculCA.calendrierService.fin1',
            actif__c = true,
            dateTimeValue__c = Date.newInstance(2019, 07, 28)
        );
        insert gpwo5;
        
        GlobalProperties__c gpwo6 = new GlobalProperties__c(
            Name = 'fsl.calculCA.calendrierService.fin3',
            actif__c = true,
            dateTimeValue__c = Date.newInstance(2019, 09, 29)
        );
        insert gpwo6;*/
        
    }
    
    @isTest 
    static void testAssignedResource() {
        ServiceResource[] sr = [SELECT id FROM ServiceResource ]; 
        
        /*
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = WO.Id;
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.Status = 'Planifié';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        insert sa;
        */

        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
        
        List<WorkType> wtList = new List<WorkType>();
        WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, false);
        WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, false);
        WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, false);
        wtList.add(wt1);
        wtList.add(wt2);
        wtList.add(wt3);
        insert wtList;
        
        WorkOrder wo = Utils_Test.createWorkOrder(RT_WO_SERVICE, null, false);
        wo.WorkTypeId = wt2.Id;
        wo.AccountId = accountTest.Id;
        insert wo;
        ServiceAppointment sa = Utils_Test.createServiceAppointment(wo.Id, RT_SA_KUBE2, false);
        sa.ParentRecordId = WO.Id;
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.Status = 'Planifié';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        insert sa;
               
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c='Secondaire';
        listeAR.add(ar2);*/
        //Database.insert (listeAR,false);
        insert (listeAR); 
        System.debug('**assigneResource Type'+listeAR); 
        
        Test.startTest();
        
        //Supprimer AssignedResource secondaire
        //delete ar1;        
        
        Test.stopTest(); 
        
        //Vérifier qu'il y a bien un historique
        //List<HistoriqueAttributionRessource__c> listeHisto=[select id from HistoriqueAttributionRessource__c WHERE FSL_Rendez_vous_parent__c =: sa.id];        
        //System.assertNotEquals(0, listeHisto.size());         
    }
}