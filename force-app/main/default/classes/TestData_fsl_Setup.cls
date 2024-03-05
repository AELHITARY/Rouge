//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TestData_fsl_Setup
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2022
//-- Version     : 1.0
//-- Description : Préparer les données utilisé par les classes de test
//-- --------------------------------------------------------------------------------- --
@isTest
public class TestData_fsl_Setup {
    
    public static Account createAccount(){       
        String accPersoRtId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Account a = new Account(LastName='TestAccount',FirstName='TEST',PersonMailingCity='Paris',PersonMailingPostalCode='75116',
                                PersonMailingStreet='34 rue de la faisanderie',
                                AccountSource='WEB',Phone='0627105593',RecordTypeId=accPersoRtId);
        // Database.insert (a,false);
        insert a;
        return a;
    }
    
    public static WorkType createWorkType(){   
        List<WorkType> wkList = new List<WorkType>();   
        WorkType wt = new WorkType(Name='METRAGE',EstimatedDuration=1.0); //DEPRECATED
        WorkType wt2 = new WorkType(Name=Constants.ACTIVITY_TYPE_CONTROL,EstimatedDuration=1.0); 
        WorkType wt3 = new WorkType(Name=Constants.ACTIVITY_TYPE_INTERVENTION,EstimatedDuration=1.0); 
        WorkType wt4 = new WorkType(Name=Constants.ACTIVITY_TYPE_DIAGNOSTIC,EstimatedDuration=1.0); 
        wkList.add(wt);
        wkList.add(wt2);
        wkList.add(wt3);
        wkList.add(wt4);
        insert wkList;
        return wt;
    }
    
    public static OperatingHours createOperatingHours(){
        OperatingHours oh = new OperatingHours(/*fsl_dateOuverture__c = Date.newInstance(2017, 1, 1),*/Name='K/K Semaine type standard' ,TimeZone='Europe/Paris' );
        // Database.insert (oh,false);  
        insert oh;  
        return oh;
        
    }
    
    public static ServiceTerritory createDS(OperatingHours oh){  
        
        ServiceTerritory st = new ServiceTerritory(Name='DS',KparKReference__c='DS',OperatingHoursId=oh.Id,IsActive=true);           
        // Database.insert (st,false); 
        insert st; 
        system.debug('**st '+st.id);
        return st;
    }
    
    public static ServiceTerritory createDepot(ServiceTerritory parentST,OperatingHours oh){
        ServiceTerritory st = new ServiceTerritory(ParentTerritoryId=parentST.id,Name='Depot',KparKReference__c='DEP',OperatingHoursId=oh.Id,IsActive=true);
        // Database.insert (st,false);       
        insert st;
        return st;
    }
    
    public static Chantier__c createChantier(Account a){
        Chantier__c chantier = new Chantier__c(name='testChantier',rue__c='34 de la faisanderie',codePostal__c='75116',ville__c='Paris',departement__c='Ile de France',pays__c='France',proprietaire__c=a.id);
        // Database.insert (chantier,false);
        insert chantier;
        return chantier;
    }
    
    public static KContrat__c createContrat(Account a,Chantier__c chantier){       
        KContrat__c c = new KContrat__c(Name='TestContrat' ,numeroContrat__c='CTR', compte__c=a.id, chantier__c=chantier.id);           
        // Database.insert (c,false);
        insert c;
        return c;
    }
    
    public static WorkOrder createWorkOrder(Account a,WorkType w,ServiceTerritory st,KContrat__c c,OperatingHours oh){ 
        DateTime now=system.now();
        Id rtId = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
        
        WorkOrder wo= new WorkOrder(FSL_EXTERNALID__C='ParentWorkOrder',AccountId=a.Id, ContratK__c=c.id, WorkTypeId=w.id,ServiceTerritoryId=st.Id,STARTDATE=now.addDays(-30),ENDDATE=now.addDays(30),DURATIONTYPE='Minutes',
                                    DURATION=40,fsl_techFlagSynchro__c=Datetime.newInstance(2018, 2, 7, 10, 0, 0),FSL__VisitingHours__c = oh.id, fsl_chiffreAffaire__c = 300, RecordTypeId=rtId);           
        // Database.insert (wo,false);
        insert wo;
        return wo;
    }
    
    public static WorkOrder createTestCAWorkOrder(Account a,WorkType w,ServiceTerritory st,KContrat__c c,OperatingHours oh){ 
        DateTime now=system.now();
        WorkOrder wo= new WorkOrder(FSL_EXTERNALID__C='TestCAWorkOrder',AccountId=a.Id, ContratK__c=c.id, WorkTypeId=w.id,ServiceTerritoryId=st.Id,STARTDATE=now.addDays(-30),ENDDATE=now.addDays(60),DURATIONTYPE='Minutes',
                                    DURATION=40,fsl_techFlagSynchro__c=Datetime.newInstance(2018, 2, 7, 10, 0, 0),FSL__VisitingHours__c = oh.id, fsl_chiffreAffaire__c = 300);           
        //Database.insert (wo,false);
        insert wo;
        return wo;
    }
    
    public static WorkOrder createTestDesactivationWorkOrder(Account a,WorkType w,ServiceTerritory st,KContrat__c c,OperatingHours oh){ 
        DateTime now=system.now();
        WorkOrder wo= new WorkOrder(FSL_EXTERNALID__C='TestDesactivationWorkOrder',AccountId=a.Id, ContratK__c=c.id, WorkTypeId=w.id,ServiceTerritoryId=st.Id,STARTDATE=now.addDays(-1),ENDDATE=now.addDays(3),DURATIONTYPE='Minutes',
                                    DURATION=40,fsl_techFlagSynchro__c=Datetime.newInstance(2018, 2, 7, 10, 0, 0),FSL__VisitingHours__c = oh.id, fsl_chiffreAffaire__c = 300);           
        // Database.insert (wo,false);
        insert wo;
        return wo;
    }
    
    public static List<User> createUser(){       
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
        // Database.insert (listeUser,false);
        insert listeUser;
        return listeUser;
    }
    
    public static ServiceResource[] createServiceResource(User[] u){    
        List<ServiceResource> listeSR =new List<ServiceResource> ();
        ServiceResource sr1= new ServiceResource(fsl_matriculeGC__c='RES01',fsl_SGID__c='SGID01',name='MetreurTest',ResourceType='T',RelatedRecordId=u[0].id,IsActive=true,IsCapacityBased=true);           
        listeSR.add(sr1);
        ServiceResource sr2= new ServiceResource(fsl_matriculeGC__c='RES02',fsl_SGID__c='SGID02',name='PoseurTest',ResourceType='T',RelatedRecordId=u[1].id,IsActive=true);           
        listeSR.add(sr2);
        // Database.insert (listeSR,false);
        insert listeSR;
        return listeSR;
    }   
    
    
    public static List<ServiceTerritoryMember> createServiceTerritoryMember(ServiceResource[] sr,ServiceTerritory st,OperatingHours oh){       
        List<ServiceTerritoryMember> listeSTM=new List<ServiceTerritoryMember> ();
        ServiceTerritoryMember stm1= new ServiceTerritoryMember(EffectiveStartDate=Date.newInstance(2017, 1, 1),ServiceResourceId=sr[0].id,ServiceTerritoryId=st.id,TerritoryType='P',OperatingHoursId=oh.Id);           
        listeSTM.add(stm1);
        ServiceTerritoryMember stm2= new ServiceTerritoryMember(EffectiveStartDate=Date.newInstance(2017, 1, 1),ServiceResourceId=sr[1].id,ServiceTerritoryId=st.id,TerritoryType='P',OperatingHoursId=oh.Id);           
        listeSTM.add(stm2);        
        // Database.insert (listeSTM,false);  
        insert listeSTM;  
        return listeSTM;
    }
    
    
    public static SkillRequirement createSkillRequirement(WorkType wt){    
        Skill sk = [select id from Skill where MasterLabel = 'Bois' ];
        SkillRequirement skillr= new SkillRequirement( RelatedRecordId=wt.id,SkillId=sk.id,SkillLevel=1);           
        // Database.insert (skillr,false);
        insert skillr;
        return skillr;
    }
    
    public static List<GlobalProperties__c> createGlobalProperties(){
        List<GlobalProperties__c> Properties= new List<GlobalProperties__c> ();
        GlobalProperties__c synchroWO = new GlobalProperties__c ();
        synchroWO.Name='fsl.platformEvent.sync.wo';
        synchroWO.dateTimeValue__c=Datetime.newInstance(2018, 2, 1, 15, 0, 0); 
        Properties.add(synchroWO);
        
        GlobalProperties__c synchroSA = new GlobalProperties__c ();
        synchroSA.Name='fsl.platformEvent.sync.sa';
        synchroSA.dateTimeValue__c=Datetime.newInstance(2018, 2, 1, 15, 0, 0); 
        Properties.add(synchroSA);
        
        GlobalProperties__c responsableError = new GlobalProperties__c ();
        responsableError.Name='fsl.platformEvent.exception.email';
        responsableError.stringValue__c='keman.wu@cgi.com'; 
        Properties.add(responsableError);
        
        GlobalProperties__c responsableCheck = new GlobalProperties__c ();
        responsableCheck.Name='fsl.platformEvent.check.email';
        responsableCheck.stringValue__c='keman.wu@cgi.com'; 
        Properties.add(responsableCheck);
        
        GlobalProperties__c calendrierServiceDebut = new GlobalProperties__c ();
        calendrierServiceDebut.Name='fsl.calculCA.calendrierService.debut';
        calendrierServiceDebut.dateValue__c = FieldServiceUtils.calculDebutCalendarService(); 
        Properties.add(calendrierServiceDebut);
        
        GlobalProperties__c calendrierServiceFin1 = new GlobalProperties__c ();
        calendrierServiceFin1.Name='fsl.calculCA.calendrierService.fin1';
        calendrierServiceFin1.dateValue__c = FieldServiceUtils.calculFinCalendarService(1);    
        Properties.add(calendrierServiceFin1); 
        
        /*GlobalProperties__c calendrierServiceFin3 = new GlobalProperties__c ();
        calendrierServiceFin3.Name='fsl.calculCA.calendrierService.fin3';
        calendrierServiceFin3.dateValue__c = FieldServiceUtils.calculFinCalendarService(3);    
        Properties.add(calendrierServiceFin3);   */    
        
        
        GlobalProperties__c responsableErrorimport = new GlobalProperties__c ();
        responsableErrorimport.Name='fsl.import.exception.email';
        responsableErrorimport.actif__c = false;
        responsableErrorimport.stringValue__c='keman.wu@cgi.com';  
        Properties.add(responsableErrorimport);   
        
        // Database.insert (Properties,false);
        insert(Properties);
        return Properties;
    }
    
    public static List<mapping__c> createGlobalProperties1(){
        List<mapping__c> Properties= new List<mapping__c> ();
        
        List<mapping__c> mapping = new List<mapping__c> ();
        mapping__c profil = new mapping__c ();
        profil.ConvertedValue__c= 'K/K - FSL Ressource';
        profil.Name= 'FSLProfil_003';
        profil.PickValue__c= 'Ressource planifiable interne';
        profil.Repository__c= 'FSLProfil';
        Properties.add(profil);
        
        mapping__c autorisation1 = new mapping__c ();
        autorisation1.ConvertedValue__c= 'FSL_Resource_Permissions';
        autorisation1.Name= 'FSLAutorisation_001';
        autorisation1.PickValue__c= 'Ressource planifiable interne';
        autorisation1.Repository__c= 'FSLAutorisation';
        Properties.add(autorisation1);
        
        mapping__c autorisation2 = new mapping__c ();
        autorisation2.ConvertedValue__c= 'FSL_Resource_License';
        autorisation2.Name= 'FSLAutorisation_002';
        autorisation2.PickValue__c= 'Ressource planifiable interne';
        autorisation2.Repository__c= 'FSLAutorisation';
        Properties.add(autorisation2);
        
        mapping__c autorisation3 = new mapping__c ();
        autorisation3.ConvertedValue__c= 'FSL_Mobile_License';
        autorisation3.Name= 'FSLAutorisation_003';
        autorisation3.PickValue__c= 'Ressource planifiable interne';
        autorisation3.Repository__c= 'FSLAutorisation';
        Properties.add(autorisation3);
        
        // Database.insert (Properties,false);
        insert Properties;
        return Properties;
    }
    
    public static ResourcePreference createResourcePreference(ServiceResource[] sr,WorkOrder wo){
        ResourcePreference preference = new ResourcePreference ();
        preference.ServiceResourceId = sr[0].id;
        preference.RelatedRecordId = wo.id;
        // Database.insert (preference,false);
        insert preference;
        return preference;
    }
    
    public static ServiceResourceCapacity createServiceResourceCapacity(ServiceResource[] sr){
        ServiceResourceCapacity src = new ServiceResourceCapacity ();
        src.ServiceResourceId = sr[0].id;
        src.StartDate = system.now().Date();
        src.EndDate = system.now().Date();
        src.CapacityInHours = 5;
        // Database.insert (src,false);
        insert src;
        return src;
    }
    
    public static ServiceResourceSkill createServiceResourceSkill(ServiceResource[] sr){
        Skill sk = [SELECT id FROM Skill WHERE MasterLabel = 'Métrage' LIMIT 1];
        ServiceResourceSkill srs = new ServiceResourceSkill ();
        srs.ServiceResourceId = sr[0].id;
        srs.SkillId = sk.id;
        srs.EffectiveStartDate = system.now().Date();
        // Database.insert (srs,false);
        insert srs;
        return srs;
    }
}