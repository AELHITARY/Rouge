//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_TimeSheetCreation
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 29/07/2020
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest (SeeAllData=false)
private class Test_BA_TimeSheetCreation {
    private static final Id RT_WORK_ORDER_FSL = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    private static final Id SA_KUBE2_RT = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    
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
            OperatingHoursId=oh.Id,
            IsActive=true,
            KparKReference__c = '12324');           
        insert parentST; 
        
        
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
        /*KContrat__c c = new KContrat__c(
            Name='TestContrat' ,
            numeroContrat__c='CTR', 
            compte__c=a.id, 
            chantier__c=chantier.id);
        insert c;*/
        
        
        //Création d'un territoire 
        ServiceTerritory st = new ServiceTerritory(
            ParentTerritoryId=parentST.id,
            Name='Depot',
            OperatingHoursId=oh.Id,
            IsActive=true,
            KparKReference__c = '12314');     
        insert st;
        
        
        //Création d'un work type 
        WorkType wt = new WorkType(
            Name=Constants.ACTIVITY_TYPE_INTERVENTION,
            EstimatedDuration=1.0,
            fsl_dateOuverture__c = Date.newInstance(2017, 1, 1));
        insert wt;
        
        
        //Création d'un work order 
        DateTime now=system.now();
        WorkOrder wo= new WorkOrder(
            FSL_EXTERNALID__C='ParentWorkOrder',
            AccountId=a.Id, 
            //ContratK__c=c.id, 
            WorkTypeId=wt.id,
            City = 'toto',
            Street = '1 rue test',
            PostalCode = '12345',
            Country = 'France',
            ServiceTerritoryId=st.Id,
            STARTDATE=now.addDays(-31),
            ENDDATE=now.addDays(120),
            DURATIONTYPE='Minutes',
            DURATION=40,
            fsl_techFlagSynchro__c=Datetime.newInstance(2018, 2, 7, 10, 0, 0),
            FSL__VisitingHours__c = oh.id, 
            RecordTypeId = RT_WORK_ORDER_FSL,
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
        
        //Propriétés globales
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
        insert gpwo6;
        
        GlobalProperties__c gpwo7 = new GlobalProperties__c(
            Name = 'fsl.calculCA.calendrierService.debut',
            actif__c = true,
            dateValue__c = Date.newInstance(2019, 08, 26)
        );
        insert gpwo7;
        
        GlobalProperties__c gpwo8 = new GlobalProperties__c(
            Name = 'fsl.calculCA.calendrierService.fin1',
            actif__c = true,
            dateValue__c = Date.newInstance(2019, 09, 29)
        );
        insert gpwo8;*/
               
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Confirmé');
    }    
    
    @isTest 
    static void testScheduleTimeSheetCreation() {                
        Test.startTest();

        Schedule_TimeSheetCreation sh1 = new Schedule_TimeSheetCreation();
        String sch = '0 0 23 * * ?'; system.schedule('Test TimeSheetCreation', sch, sh1);
        
        Test.stopTest();
    }    
}