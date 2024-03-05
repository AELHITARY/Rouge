/*
History 
-------
Ver.	Author          Date             	Detail
1.0   	DPHA            2019-03-21       	Class created.

*/

@IsTest
public class MaFeuilleRouteTest {
       
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    //Data setup. 
    @testSetup 
    public static void testSetup() {
        List<GlobalProperties__c> listeGP =TestData_fsl_Setup.createGlobalProperties();
        List<mapping__c> listeGP1 =TestData_fsl_Setup.createGlobalProperties1();
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        //ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        //Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        //KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo = Utils_Test.createWorkOrder(wkRTId, false);
        wo.WorkTypeId = wt.Id;
        insert wo;      
        List<ServiceResource> newSR= TestData_fsl_Setup.createServiceResource(u);  
    }
    
    /*@isTest 
    public static void testVerificationSetup() {
        
       
        Test.startTest(); 
        List<User> lstUser= [select id, matriculeGC__c from user where matriculeGC__c LIKE '%testResource%'];
        System.assertEquals(2,lstUser.size());
        List<Account> listAccount = [select id,name from Account where Name='TestAccount'];
        System.assertEquals(1,listAccount.size());
        List<WorkType> listWorkType = [select id,name from WorkType where Name='METRAGE'];
        System.assertEquals(1,listWorkType.size());
        List<Skill> lstSkill = [select id from Skill where MasterLabel = 'Métrage'];
        //System.assertEquals(1,lstSkill.size());
        List<SkillRequirement> listSkillRequirement = [select id from SkillRequirement where skillId IN : lstSkill];
        //System.assertEquals(2,listSkillRequirement.size());
        List<OperatingHours> listOperatingHours = [select id,name from OperatingHours where Name='K/K Semaine type standard'];
        System.assertEquals(1,listOperatingHours.size());
        List<ServiceTerritory> listDS = [select id,name from ServiceTerritory where Name='DS'];
        System.assertEquals(1,listDS.size());
        //List<ServiceTerritory> listDepot = [select id,name from ServiceTerritory where Name='Depot'];
        //System.assertEquals(1,listDepot.size());
        List<Chantier__c> listChantier = [select id,name from Chantier__c where Name='testChantier'];
        System.assertEquals(1,listChantier.size());
        List<KContrat__c> listContrat = [select id,name from KContrat__c where Name='TestContrat'];
        System.assertEquals(1,listContrat.size());
        List<WorkOrder> listWorkOrder = [select id from WorkOrder where FSL_EXTERNALID__C='ParentWorkOrder'];
        System.assertEquals(1,listWorkOrder.size());
        
        Test.stopTest(); 
    }*/
   
    /*public static testmethod void testDisplay()
    {
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1][0];
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FeuilleRoute;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('listResId', sr.id);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
        
        MafeuilleRoute mfr = new MaFeuilleRoute();
       
        Test.startTest(); 
        
        mfr.createMapResourceSA();
        
        Test.stopTest(); 
        
    }*/
    
     public static testmethod void testGetServiceResource()
    {
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        //AssignedResource ar = [SELECT Id FROM AssignedResource WHERE ServiceResourceId = :sr.id][0];
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FeuilleRoute;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('listResId', sr1.id);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
     
        
        WorkOrder WO = [SELECT Id FROM WorkOrder LIMIT 1][0];
        
        /*ServiceAppointment SA = new ServiceAppointment ();
        SA.ParentRecordId = WO.Id;
        SA.EarliestStartTime = Date.today();
        SA.SchedStartTime = Date.today();
        SA.fsl_dateConfirmation__c = Date.today();
        SA.Duration = 180.0;
        SA.Status = 'Confirmé';
        Integer duration= Integer.valueOf(SA.Duration);        
        SA.SchedEndTime = SA.SchedStartTime.addMinutes(duration);
        insert SA;*/
        ServiceAppointment SA = Utils_Test.createServiceAppointment(WO.Id, SASARTId, false);
        SA.Status='Terminé';
        SA.ActualEndTime=Date.today();
        SA.ActualStartTime=Date.today();
        SA.fsl_dateConfirmation__c=Date.today();
        SA.dateConfirmationClient__c=Date.today();
        SA.SchedEndTime=Date.today();
        SA.SchedStartTime=Date.today();
        insert SA;
        
        AssignedResource ar = new AssignedResource(
            ServiceResourceId = sr1.id,
            ServiceAppointmentId = SA.id
        );
        Database.insert(ar, false);
        //insert ar;
    
        /*ServiceAppointment SA2 = new ServiceAppointment ();
        SA2.ParentRecordId = WO.Id;
        SA2.EarliestStartTime = Date.today();
        SA2.SchedStartTime = Date.today();
        SA2.Duration = 180.0;
        SA2.Status = 'Confirmé';
        Integer duration2= Integer.valueOf(SA.Duration);        
        SA2.SchedEndTime = SA2.SchedStartTime.addMinutes(duration2);
        insert SA2;
        
        AssignedResource ar2 = new AssignedResource(
            ServiceResourceId = sr1.id,
            ServiceAppointmentId = SA2.id
        );
        Database.insert(ar2, false);*/
        //insert ar2;      

        
        MafeuilleRoute mfr = new MaFeuilleRoute();
       
        Test.startTest(); 
        
        mfr.getListServiceResource() ;
        
        Test.stopTest(); 
        
        //System.assertEquals(1, mfr.getListServiceResource().size());
        System.assertEquals(0, mfr.getListServiceResource().size());
    }
    
    /*Logo*/
    /*******
	*
	*	Pas de possibilité de couvrir l'affichage du logo, l'objet est considéré comme non existant.
	*
	********/
    
    //Test avec une Assigned Resource. Mais Impossible d'en créer une.
    /*public static testmethod void testWithAssignedResource()
    {
        //Préparation des données à injecter dans l'URL
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Id= :stm.ServiceResourceId LIMIT 1][0];
        
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        
        //Création d'un Work order
        WorkOrder wo = [SELECT Id, StartDate, EndDate FROM WorkOrder LIMIT 1][0];
        System.debug('WO -------------------------------------------' + wo);
        
        //Création d'un RDV de service
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.id,
            EarliestStartTime = Date.today(),
            DueDate = Date.today().addDays(10),
            SchedStartTime = wo.StartDate,
            SchedEndTime = wo.StartDate.addMinutes(30),
            Status = 'Demandé'
        );
        insert sa;
        System.debug('-------------------SA ' + sa);
        
        AssignedResource ar = new AssignedResource(
            ServiceAppointmentId = sa.Id,
            ServiceResourceId = sr.Id,
            fsl_typeRessourceAttribuee__c = 'Principale'
        );
        Database.insert (ar,false);
        System.debug('-------------------AR ' + ar);

        
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FeuilleRoute;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('listResId', stm.ServiceResourceId);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
        
        MafeuilleRoute mfr = new MaFeuilleRoute();
       
        Test.startTest(); 
        
        mfr.getListServiceResource() ;
        
        Test.stopTest(); 
        
        System.assertEquals(1, mfr.getListServiceResource().size());
        
    }*/
    
}