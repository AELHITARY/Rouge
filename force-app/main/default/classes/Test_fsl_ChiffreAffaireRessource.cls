//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : Test_fsl_ChiffreAffaireRessource
//-- Modifié par : CGI
//-- Modifié le  : 26/03/2018
//-- Version     : 1.0
//-- Description : Classe de test pour calcul les chiffres d'affaires des ressources
//-- --------------------------------------------------------------------------------- --
@isTest 
public class Test_fsl_ChiffreAffaireRessource {
    private static final Id SA_KUBE2_RT = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    
    @testSetup 
    public static void setup() {
        //préparer les données pour le test
        List<GlobalProperties__c> listeGP =TestData_fsl_Setup.createGlobalProperties();
       
        System.debug('**GlobalProperties__c'+listeGP);
        
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Demandé');
    }
    
    @isTest 
    public static void testInsertAssignedResource() {
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createTestCAWorkOrder(a,wt,st,c,oh);
        
        List<ServiceResource> sr= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
         
        Test.startTest();  
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = Date.today()+1;
        sa.SchedStartTime = Date.today()+1;
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;    

        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c = 'Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c = 'Secondaire';
        listeAR.add(ar2);*/
        
        insert listeAR;  
        
        Test.stopTest(); 
    }
    
    @isTest 
    public static void testUpdateAssignedResource() {
         
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createTestCAWorkOrder(a,wt,st,c,oh);
        
        List<ServiceResource> sr= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
        
        Test.startTest();   
        Profile[] pf = [SELECT Id FROM profile where Name LIKE '%Ressource%'];  
         
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = Date.today()+1;
        sa.SchedStartTime = Date.today()+1;
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;    

        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c = 'Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c = 'Secondaire';
        listeAR.add(ar2);*/
        insert listeAR; 
      
        Test.stopTest(); 
        // CA avant modification
         
        
        /*User u3=new User(firstname = 'firstname3', 
                         lastName = 'lastName3', 
                         email = 'firstname3.lastName3@example.com', 
                         Username = 'firstname3.lastName3@kpark.fr.fsl', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'test3',  
                         TimeZoneSidKey = 'Europe/Paris', 
                         LocaleSidKey = 'fr_FR_EURO', 
                         LanguageLocaleKey = 'fr', 
                         matriculeGC__c = 'testResource3',
                         IsActive = true,
                         ProfileId = pf[0].Id                         
                        );    
      insert u3;       
        
        ServiceResource newSR = new ServiceResource(fsl_matriculeGC__c='RES03',fsl_SGID__c='SGID03',name='MetreurTest3',ResourceType='T',RelatedRecordId=u3.id,IsActive=true);           
      insert newSR;
                
        
        ServiceTerritoryMember stm= new ServiceTerritoryMember(EffectiveStartDate=System.today(),ServiceResourceId=newSR.id,ServiceTerritoryId=st.id,TerritoryType='P',OperatingHoursId=oh.Id);               
        insert stm;   
        
        //AssignedResource newAR = [SELECT id,ServiceResourceId FROM AssignedResource where ServiceAppointmentId =:sa.Id and fsl_typeRessourceAttribuee__c = 'Principale' LIMIT 1];
        //System.debug('**newAR'+newAR.ServiceResourceId);
        ar1.ServiceResourceId = newSR.id;   
        update ar1; */
         
    }
    
    @isTest 
    public static void testDeleteAssignedResource() {
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createTestCAWorkOrder(a,wt,st,c,oh);
        
        List<ServiceResource> sr= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
         
        Test.startTest();
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = Date.today()+1;
        sa.SchedStartTime = Date.today()+1;
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;      

        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c = 'Principale';
        listeAR.add(ar1);
        AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c = 'Secondaire';
        listeAR.add(ar2);
        insert listeAR; 
        
        //delete ar2; 
        
        Test.stopTest();
    }
    
    @isTest 
    public static void testChangePeriodeSA() {
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createTestCAWorkOrder(a,wt,st,c,oh);
        
        List<ServiceResource> sr= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
         
        Test.startTest();
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = Date.today()+1;
        sa.SchedStartTime = Date.today()+1;
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;     

        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c = 'Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c = 'Secondaire';
        listeAR.add(ar2);*/
        insert listeAR; 
        Test.stopTest(); 
        //ServiceAppointment newSA = [SELECT SchedStartTime,SchedEndTime,Duration FROM ServiceAppointment where ParentRecordId =: wo.id]; 
        /*sa.SchedStartTime = wo.StartDate.addDays(40);               
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        update sa; */
        
        
    }
    
    @isTest 
    public static void testSuppresionWO() {
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createTestCAWorkOrder(a,wt,st,c,oh);
        
        List<ServiceResource> sr= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
         
        Test.startTest();
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = Date.today()+1;
        sa.SchedStartTime = Date.today()+1;
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;
        
        System.debug('ServiceAppointement inserted.');
               
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c = 'Principale';
        listeAR.add(ar1);
        
        System.debug('Add AssignedRessource 1.');
        
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c = 'Secondaire';
        listeAR.add(ar2);*/
        insert listeAR; 
        
        System.debug('AssignedRessourceList inserted.');
        
        //delete wo; 
        
        System.debug('WorkOrder deleted.');
        
        Test.stopTest(); 
        
    }
  
}