/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-26          Class created.

*/
@IsTest
public class Test_FSL_FigerRDV_Recap {
    private static final Id SA_KUBE2_RT = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    
    //Data Setup
    @testSetup 
    static void testSetup(){
        List<GlobalProperties__c> synchro= TestData_fsl_Setup.createGlobalProperties();  
        
    }
    
    //Recup donnée + Affichage liste
    @isTest 
    static void testRecapFiger() {
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);                
        
        //Creation des utilisateurs 
        Profile[] pf= [Select Id from profile where Name LIKE '%Ressource%']; 
        
        List<User> listeUser=new List<User>();
        User u1=new User(firstname = 'Test', 
                         lastName = 'Resource1', 
                         email = 'test.resource1@example.com', 
                         Username = 'test.resource1@kpark.fr.fsl', 
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
                         Username = 'test.resource2@kpark.fr.fsl', 
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

        Test.startTest();
        
        //List<User> u = [SELECT Id FROM User];
        
        //Creation des ressources
        List<ServiceResource> listeSR =new List<ServiceResource> ();
        ServiceResource sr1= new ServiceResource(
            fsl_matriculeGC__c='RES01',
            fsl_SGID__c='SGID01',
            name='MetreurTest',
            ResourceType='T',
            RelatedRecordId=u1.id,
            IsActive=true,
            IsCapacityBased=true);           
        listeSR.add(sr1);
        
        ServiceResource sr2= new ServiceResource(
            fsl_matriculeGC__c='RES02',
            fsl_SGID__c='SGID02',
            name='PoseurTest',
            ResourceType='T',
            RelatedRecordId=u2.id,
            IsActive=true);           
        listeSR.add(sr2);
        insert listeSR;
        
        //List<ServiceResource> sr = [SELECT Id FROM ServiceResource];
        
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

        //Paramétrage de l'URL 
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        
        sr1.serviceTerritory__c = stm1.ServiceTerritoryId;
        sr1.IsActive = true;
        sr1.job__c = 'METREUR';
        update sr1;
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_Resource;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('listResId', sr1.Id);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
        ApexPages.currentPage().getParameters().put('action', 'F');
        
        //Création RDV 
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = WO.Id;
        sa.Subject = 'Harry Potter';
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.fsl_chiffreAffaire__c = 1000;
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;
        
        System.debug('ServiceAppointment created.');
        
        //Création ressource assignée
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr1.id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        insert ar1;
        
        System.debug('AssignedResource created.');
      
        //Instanciation de la classe        
        CTRL_FSL_FigerRDV_Recap  cffr = new CTRL_FSL_FigerRDV_Recap();

     
        cffr.confirmerUpdate();
        
        System.debug('end of confirmerUpdate.');

        Test.stopTest();
    } 
    
    //Recup donnée + Affichage liste
    @isTest 
    static void testRecapDefiger() {
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      

        //Creation des utilisateurs 
        Profile[] pf= [Select Id from profile where Name LIKE '%Ressource%']; 
        
        List<User> listeUser=new List<User>();
        User u1=new User(firstname = 'Test', 
                         lastName = 'Resource1', 
                         email = 'test.resource1@example.com', 
                         Username = 'test.resource1@kpark.fr.fsl', 
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
                         Username = 'test.resource2@kpark.fr.fsl', 
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
        
        Test.startTest();
        
        //List<User> u = [SELECT Id FROM User];
        
        //Creation des ressources
        List<ServiceResource> listeSR = new List<ServiceResource> ();
        ServiceResource sr1= new ServiceResource(
            fsl_matriculeGC__c='RES01',
            fsl_SGID__c='SGID01',
            name='MetreurTest',
            ResourceType='T',
            RelatedRecordId=u1.id,
            IsActive=true,
            IsCapacityBased=true);           
        listeSR.add(sr1);
        
        ServiceResource sr2 = new ServiceResource(
            fsl_matriculeGC__c='RES02',
            fsl_SGID__c='SGID02',
            name='PoseurTest',
            ResourceType='T',
            RelatedRecordId=u2.id,
            IsActive=true);           
        listeSR.add(sr2);
        insert listeSR;
        
        //List<ServiceResource> sr = [SELECT Id FROM ServiceResource];
        
        //Creation de membre de territoires
        List<ServiceTerritoryMember> listeSTM = new List<ServiceTerritoryMember> ();
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
        //Paramétrage de l'URL 
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        

        sr1.serviceTerritory__c = stm1.ServiceTerritoryId;
        sr1.IsActive = true;
        sr1.job__c = 'METREUR';
        update sr1;
        System.debug('SR TO UPDATE -----------' + sr1);
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_Resource;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('listResId', sr1.Id);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
        ApexPages.currentPage().getParameters().put('action', 'D');
        
        //Création RDV 

        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = WO.Id;
        sa.Subject = 'Harry Potter';
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.fsl_chiffreAffaire__c = 1000;
        //sa.FSL__Pinned__c = true;
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;
        
        //Création ressource assignée
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr1.id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        insert ar1;     
        //Instanciation de la classe        
        CTRL_FSL_FigerRDV_Recap  cffr = new CTRL_FSL_FigerRDV_Recap();

     
        cffr.confirmerUpdate();

        Test.stopTest();
    } 
}