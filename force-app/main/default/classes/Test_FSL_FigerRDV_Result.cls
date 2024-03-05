/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-26          Class created.

*/
@IsTest
public class Test_FSL_FigerRDV_Result {
    
    //Data Setup
    @testSetup
    public static void testSetup(){
        
        //Création d'un compte 
        Account a = new Account(
            Name='TestAccount',
            BillingCity='Paris',
            BillingPostalCode='75116',
            BillingStreet='34 rue de la faisanderie',
            AccountSource='WEB',
            Phone='0627105593'); 
        insert a;

        //Création horaires
        OperatingHours oh = new OperatingHours(
            //fsl_dateOuverture__c = Date.newInstance(2017, 1, 1),
            Name='K/K Semaine type standard' ,
            TimeZone='Europe/Paris' );
        insert oh;  
        
        //Création du dépot
        ServiceTerritory parentST = new ServiceTerritory(
            Name='DS',
            KparKReference__c='DS',
            OperatingHoursId=oh.Id,
            IsActive=true);
        //Création d'un territoire 
        ServiceTerritory st = new ServiceTerritory(
            ParentTerritoryId=parentST.id,
            Name='Depot',
            KparKReference__c='DEP',
            OperatingHoursId=oh.Id,
            IsActive=true);
        List<ServiceTerritory> stList = new List<ServiceTerritory>();
        stList.add(parentST);
        stList.add(st);
        insert st;
        
        
        //Création d'un chantier
        Chantier__c chantier = new Chantier__c(
            name='testChantier',
            rue__c='34 de la faisanderie',
            codePostal__c='75116',
            ville__c='Paris',
            departement__c='Ile de France',
            pays__c='France',
            proprietaire__c=a.id);
        insert chantier;

        
        //Création d'un contrat 
        KContrat__c c = new KContrat__c(
            Name='TestContrat' ,
            numeroContrat__c='CTR', 
            compte__c=a.id, 
            chantier__c=chantier.id);
        insert c;        
        
        //Création d'un work type 
        WorkType wt = new WorkType(
            Name='METRAGE',
            EstimatedDuration=1.0);
        insert wt;
        
        
        //Création d'un work order 
        DateTime now=system.now();
        WorkOrder wo= new WorkOrder(
            FSL_EXTERNALID__C='ParentWorkOrder',
            AccountId=a.Id, 
            ContratK__c=c.id, 
            WorkTypeId=wt.id,
            ServiceTerritoryId=st.Id,
            STARTDATE=now.addDays(-10),
            ENDDATE=now.addDays(10),
            DURATIONTYPE='Minutes',
            DURATION=40,
            fsl_techFlagSynchro__c=Datetime.newInstance(2018, 2, 7, 10, 0, 0),
            FSL__VisitingHours__c = oh.id, 
            fsl_chiffreAffaire__c = 300);
        insert wo;
        
        
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
        
        //List<User> u = [SELECT Id FROM User];
        
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
        
        //List<ServiceResource> sr = [SELECT Id FROM ServiceResource];
        
    }
    
    //Recup donnée + Affichage liste
    public static testmethod void testResultFiger()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        //Création RDV 
        WorkOrder WO = [SELECT Id FROM WorkOrder LIMIT 1][0];
        
        
        Test.startTest();
        List<ServiceAppointment> lSa = new List<ServiceAppointment>();
        
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = WO.Id;
        sa.Subject = 'Harry Potter';
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.Status = 'Confirmé';
        sa.fsl_dateConfirmation__c = date.today();
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.fsl_chiffreAffaire__c = 1000;
        sa.FSL__Pinned__c = true;
        lSa.add(sa);
        
        ServiceAppointment sa2 = new ServiceAppointment ();
        sa2.ParentRecordId = WO.Id;
        sa2.Subject = 'Harry Potter';
        sa2.EarliestStartTime = Date.today();
        sa2.SchedStartTime = Date.today();
        sa2.Duration = 180.0;
        sa2.Status = 'Confirmé';   
        sa2.fsl_dateConfirmation__c = date.today();  
        sa2.SchedEndTime = sa2.SchedStartTime.addMinutes(duration);
        sa2.fsl_chiffreAffaire__c = 1000;
        sa2.FSL__Pinned__c = false;
        lSa.add(sa2);
        insert lSa;
        

        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listSa', sa.Id +'~' + sa2.Id);
        ApexPages.currentPage().getParameters().put('action', 'F');
      
        //Instanciation de la classe        
        CTRL_FSL_FigerRDV_Result  cffr = new CTRL_FSL_FigerRDV_Result();

     
        cffr.displayListServiceAppointment();
        
        Test.stopTest();
       
        System.assertEquals('F',cffr.typeTraitement);
        System.assertEquals(1, cffr.nbSaUpdated);
        System.assertEquals(1, cffr.nbSaNotUpdated);
    } 
    
    //Recup donnée + Affichage liste
    public static testmethod void testResultDefiger()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        //Création RDV 
        WorkOrder WO = [SELECT Id FROM WorkOrder LIMIT 1][0];
        
        Test.startTest();
        List<ServiceAppointment> lSa = new List<ServiceAppointment>();
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = WO.Id;
        sa.Subject = 'Harry Potter';
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.Status = 'Confirmé';
        sa.fsl_dateConfirmation__c = date.today(); 
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.fsl_chiffreAffaire__c = 1000;
        sa.FSL__Pinned__c = false;
        lSa.add(sa);
        
        ServiceAppointment sa2 = new ServiceAppointment ();
        sa2.ParentRecordId = WO.Id;
        sa2.Subject = 'Harry Potter';
        sa2.EarliestStartTime = Date.today();
        sa2.SchedStartTime = Date.today();
        sa2.Duration = 180.0;
        sa2.Status = 'Confirmé';     
        sa2.fsl_dateConfirmation__c = date.today(); 
        sa2.SchedEndTime = sa2.SchedStartTime.addMinutes(duration);
        sa2.fsl_chiffreAffaire__c = 1000;
        sa2.FSL__Pinned__c = true;
        lSa.add(sa2);
        insert lSa;

        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listSa', sa.Id + '~' + sa2.Id);
        ApexPages.currentPage().getParameters().put('action', 'D');
      
        //Instanciation de la classe        
        CTRL_FSL_FigerRDV_Result  cffr = new CTRL_FSL_FigerRDV_Result();

     
        cffr.displayListServiceAppointment();
        
        Test.stopTest();
       
        System.assertEquals('D',cffr.typeTraitement);
        System.assertEquals(1, cffr.nbSaUpdated);
        System.assertEquals(1, cffr.nbSaNotUpdated);
    } 
}