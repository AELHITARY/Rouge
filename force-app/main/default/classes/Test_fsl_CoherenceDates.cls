//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_fsl_CoherenceDates
//-- Modifié par : CGI
//-- Modifié le  : 01/03/2018
//-- Version     : 1.0
//-- Description : Classe de test pour vérifier la cohérence des dates entre différents objet
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_fsl_CoherenceDates {

    @testSetup 
    static void setup() {
        //préparer les données pour le test
         List<GlobalProperties__c> listeGP =TestData_fsl_Setup.createGlobalProperties();
        List<mapping__c> listeGP1 =TestData_fsl_Setup.createGlobalProperties1();
    }

    @isTest 
    public static void testVerificationSetup() {

         /*List<User> lstUser= [select id, matriculeGC__c from user where matriculeGC__c LIKE '%testResource%'];
         System.assertEquals(2,lstUser.size());
         List<Account> listAccount = [select id,name from Account where Name='TestAccount'];
         System.assertEquals(1,listAccount.size());
         List<WorkType> listWorkType = [select id,name from WorkType where Name='METRAGE'];
         System.assertEquals(1,listWorkType.size());
         List<Skill> lstSkill = [select id from Skill where MasterLabel = 'Métrage'];
         System.assertEquals(1,lstSkill.size());
         List<SkillRequirement> listSkillRequirement = [select id from SkillRequirement where skillId IN : lstSkill];
         System.assertEquals(2,listSkillRequirement.size());
         List<OperatingHours> listOperatingHours = [select id,name from OperatingHours where Name='K/K Semaine type standard'];
         System.assertEquals(1,listOperatingHours.size());
         List<ServiceTerritory> listDS = [select id,name from ServiceTerritory where Name='DS'];
         System.assertEquals(1,listDS.size());
         List<ServiceTerritory> listDepot = [select id,name from ServiceTerritory where Name='Depot'];
         System.assertEquals(1,listDepot.size());
         List<Chantier__c> listChantier = [select id,name from Chantier__c where Name='testChantier'];
         System.assertEquals(1,listChantier.size());
         List<KContrat__c> listContrat = [select id,name from KContrat__c where Name='TestContrat'];
         System.assertEquals(1,listContrat.size());
         List<WorkOrder> listWorkOrder = [select id from WorkOrder where FSL_EXTERNALID__C='ParentWorkOrder'];
         System.assertEquals(1,listWorkOrder.size());
         List<ServiceResource> listServiceResource = [select id from ServiceResource where fsl_matriculeGC__c like '%RES0%'];
         System.assertEquals(2,listServiceResource.size());
         List<ServiceTerritoryMember> listServiceTerritoryMember = [select id from ServiceTerritoryMember where ServiceResourceId in :listServiceResource];
         System.assertEquals(2,listServiceTerritoryMember.size());*/
    }
    
    // Refonte GC : Test obsolète depuis la suppression des dates d'ouverture et de fermeture
    /*@isTest static void testServiceTerritory() {  
        Test.startTest();
        
        ServiceTerritory st = [select fsl_dateOuverture__c,fsl_dateFermeture__c from ServiceTerritory where Name='Depot'] ;       
        st.fsl_dateFermeture__c = st.fsl_dateOuverture__c.addDays(2);         
        
        
        try{
            //modifier la date fin de ServiceTerritory
            Database.update (st,false);         
        }catch(Exception e){
            System.debug('**Error ST** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown1 =  e.getMessage().contains(Label.fsl_errorDatesWorkOrderServiceTerritory);
            if(expectedExceptionThrown1)
                System.assertEquals(true,expectedExceptionThrown1);
            Boolean expectedExceptionThrown2 =  e.getMessage().contains(Label.fsl_errorDatesServiceAppointmentServiceTerritory);
            if(expectedExceptionThrown2)
                System.assertEquals(true,expectedExceptionThrown2);
            Boolean expectedExceptionThrown3 =  e.getMessage().contains(Label.fsl_errorDatesServiceTerritoryServiceTerritoryMember);
            if(expectedExceptionThrown3)
                System.assertEquals(true,expectedExceptionThrown3);
        }     
        
        Test.stopTest();             
    }*/
    
    @isTest 
    public static void testServiceAppointment() { 
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier = TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr = TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);

        Test.startTest();
        
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(sr,wo);
        ServiceResourceCapacity src = TestData_fsl_Setup.createServiceResourceCapacity(sr);
        ServiceResourceSkill srs = TestData_fsl_Setup.createServiceResourceSkill(sr);
        
        ServiceAppointment sa = [select SchedStartTime,SchedEndTime,Duration from ServiceAppointment where ParentRecordId =: wo.id]; 
        sa.SchedStartTime = wo.StartDate;
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration); 
        Database.update (sa,false);      
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
        Database.insert (listeAR,false);       
        
        try{
            //modifier la date fin planifiée de ServiceAppointment            
            ServiceAppointment sa1 = [select SchedStartTime,SchedEndTime,Duration from ServiceAppointment where ParentRecordId =: wo.id]; 
            sa1.SchedStartTime = wo.StartDate.addDays(2);               
            sa1.SchedEndTime = sa1.SchedStartTime.addMinutes(duration); 
                      
            Database.update (sa1,false);             
        }catch(Exception e){
            System.debug('**Error SA** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown =  e.getMessage().contains(Label.fsl_errorDatesAssignedResourceServiceAppointment);
            if(expectedExceptionThrown)
                System.assertEquals(true,expectedExceptionThrown);            
        }         
        
        Test.stopTest();                
    }
    
    
    @isTest 
    public static void testWorkOrder() { 
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier = TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr = TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
        
        Test.startTest();
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(sr,wo);
        ServiceResourceCapacity src = TestData_fsl_Setup.createServiceResourceCapacity(sr);
        ServiceResourceSkill srs = TestData_fsl_Setup.createServiceResourceSkill(sr);
        
        //wo.StartDate = System.now().addDays(5);   
        wo.StartDate = DateTime.newInstance(2000, 1, 1); 
        Integer duration= Integer.valueOf(wo.Duration); 
        wo.EndDate = wo.StartDate.addMinutes(duration); 
        
        ServiceAppointment sa = [select EarliestStartTime,DueDate from ServiceAppointment where ParentRecordId =: wo.id];   
        System.debug('** WO '+wo.StartDate +' - '+ wo.EndDate);  
        System.debug('** SA '+sa.EarliestStartTime +' - '+ sa.DueDate);
        
        try{
            //modifier la date fin de WorkOrder
            Database.update (wo,false);            
        }catch(Exception e){
            System.debug('**Error WO** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown1 =  e.getMessage().contains(Label.fsl_errorDatesServiceAppointmentWorkOrder);
            if(expectedExceptionThrown1)
                System.assertEquals(true,expectedExceptionThrown1);  
            Boolean expectedExceptionThrown2 =  e.getMessage().contains(Label.fsl_errorDatesResourcePreferenceWorkOrder);
            if(expectedExceptionThrown2)
                System.assertEquals(true,expectedExceptionThrown2);   
        }         
        Test.stopTest();                
    }
    
    @isTest 
    public static void testUser() {
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier = TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr = TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
        Test.startTest();   
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(sr,wo);
        ServiceResourceCapacity src = TestData_fsl_Setup.createServiceResourceCapacity(sr);
        ServiceResourceSkill srs = TestData_fsl_Setup.createServiceResourceSkill(sr);   
        
        User u1 = [select dateEntree__c,dateSortie__c from User where lastName = 'Resource1'];
        u1.dateEntree__c = System.now().Date().addDays(5);   
        u1.dateSortie__c =  u1.dateEntree__c.addDays(1);
             
        ServiceAppointment sa = [select id,fsl_techFlagSynchro__c,status,EarliestStartTime,Duration from ServiceAppointment where parentRecordId=: wo.Id];   
        sa.SchedStartTime = sa.EarliestStartTime;       
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.EarliestStartTime.addMinutes(duration); 
              
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
        
        System.debug('**assigneResource Type'+listeAR);  
        
        //Créer une absence pour la ressource secondaire
        ResourceAbsence testAbsence = new ResourceAbsence ();        
        testAbsence.Start = System.now();
        testAbsence.End = testAbsence.Start.addHours(5);
        testAbsence.ResourceId = sr[0].id;
        testAbsence.assignedResource__c = ar1.id;
        testAbsence.Type = 'Renfort';
        Database.insert (testAbsence,false);
        
        try{
            Database.update (sa,false);
            Database.insert (listeAR,false); 
            //modifier la date d'entrée et sortie d'utilisateur
            Database.update (u1,false);            
        }catch(Exception e){
            System.debug('**Error user** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown1 =  e.getMessage().contains(Label.fsl_errorDatesUserServiceResourceCapacity);
            if(expectedExceptionThrown1)
                System.assertEquals(true,expectedExceptionThrown1);               
            Boolean expectedExceptionThrown2 =  e.getMessage().contains(Label.fsl_errorDatesUserServiceResourceSkill);
            if(expectedExceptionThrown2)
                System.assertEquals(true,expectedExceptionThrown2); 
            Boolean expectedExceptionThrown3 =  e.getMessage().contains(Label.fsl_errorDatesUserServiceTerritoryMember);
            if(expectedExceptionThrown3)
                System.assertEquals(true,expectedExceptionThrown3);  
            Boolean expectedExceptionThrown4 =  e.getMessage().contains(Label.fsl_errorDatesUserResourceAbsence);
            if(expectedExceptionThrown4)
                System.assertEquals(true,expectedExceptionThrown4); 
            Boolean expectedExceptionThrown5 =  e.getMessage().contains(Label.fsl_errorDatesResourcePreferenceWorkOrder);
            if(expectedExceptionThrown5)
                System.assertEquals(true,expectedExceptionThrown5);  
            Boolean expectedExceptionThrown6 =  e.getMessage().contains(Label.fsl_errorDatesAssignedResourceServiceAppointment);
            if(expectedExceptionThrown6)
                System.assertEquals(true,expectedExceptionThrown6); 
        }  
        
        Test.stopTest();                
    }
    
    @isTest 
    public static void testOperatingHours() { 
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier = TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr = TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> stm = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
       // Pour que le test passe, il faut désactiver le process "FSL_Assignation du type d'enregistrement Région/Dépôt"
        Test.startTest();
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(sr,wo);
        ServiceResourceCapacity src = TestData_fsl_Setup.createServiceResourceCapacity(sr);
        ServiceResourceSkill srs = TestData_fsl_Setup.createServiceResourceSkill(sr);  
             
        //oh.fsl_dateFermeture__c = System.now().Date().addDays(2); 
        
        
        try{
            //modifier la date debut et fin de OperatingHours
            Database.update (oh,false);            
        }catch(Exception e){
            System.debug('**Error operationg hours** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown1 =  e.getMessage().contains(Label.fsl_errorDatesOperatingHoursWorkOrder);
            if(expectedExceptionThrown1)
                System.assertEquals(true,expectedExceptionThrown1);  
            Boolean expectedExceptionThrown2 =  e.getMessage().contains(Label.fsl_errorDatesOperatingHoursServiceTerritoryMember);
            if(expectedExceptionThrown2)
                System.assertEquals(true,expectedExceptionThrown2); 
            Boolean expectedExceptionThrown3 =  e.getMessage().contains(Label.fsl_errorDatesOperatingHoursServiceTerritory);
            if(expectedExceptionThrown3)
                System.assertEquals(true,expectedExceptionThrown3);             
        }    
        
        Test.stopTest();                
    }
    
    @isTest 
    public static void testResourcePreference() {  
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier = TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr = TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
        Test.startTest();    
        ResourcePreference preference = TestData_fsl_Setup.createResourcePreference(sr,wo);
        ServiceResourceCapacity src = TestData_fsl_Setup.createServiceResourceCapacity(sr);
        ServiceResourceSkill srs = TestData_fsl_Setup.createServiceResourceSkill(sr);
            
        Profile[] pf= [Select Id from profile where Name LIKE '%Ressource%']; 
        User u3=new User(firstname = 'firstname3', 
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
                         ProfileId = pf[0].Id,
                         dateEntree__c = System.now().Date().addDays(10),
                         dateSortie__c = System.now().Date().addDays(13)
                        );        
        Database.insert (u3,false);
        ServiceResource sr1= new ServiceResource(fsl_matriculeGC__c='RES03',fsl_SGID__c='SGID03',name='MetreurTest3',ResourceType='T',RelatedRecordId=u3.id,IsActive=true);           
        Database.insert (sr1,false);
        preference.ServiceResourceId = sr1.id; 
        
        try{    
            //ajouter la préférence ressource 
            Database.update (preference,false);              
        }catch(Exception e){
            System.debug('**Error ResourcePreference** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown1 =  e.getMessage().contains(Label.fsl_errorDatesResourcePreferenceWorkOrder);
            System.assertEquals(true,expectedExceptionThrown1);                      
        }   
        
        
        Test.stopTest();                
    }
    
    
    @isTest
    public static void testAssignedResource() {   
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier = TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr = TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
        Test.startTest();
        ResourcePreference preference = TestData_fsl_Setup.createResourcePreference(sr,wo);
        ServiceResourceCapacity src = TestData_fsl_Setup.createServiceResourceCapacity(sr);
        ServiceResourceSkill srs = TestData_fsl_Setup.createServiceResourceSkill(sr);
        
        ServiceAppointment sa = [select SchedStartTime,SchedEndTime,Duration from ServiceAppointment where ParentRecordId =: wo.id]; 
        sa.SchedStartTime = wo.StartDate;
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);  
        
        
        Profile[] pf = [Select Id from profile where Name LIKE '%Ressource%']; 
        List<User> listeUser = new List<User>();
        User u3=new User(firstname = 'firstname3', 
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
                         ProfileId = pf[0].Id,
                         dateEntree__c = System.now().Date().addDays(10),
                         dateSortie__c = System.now().Date().addDays(13)
                        );    
        listeUser.add(u3);
        User u4=new User(firstname = 'firstname4', 
                         lastName = 'lastName4', 
                         email = 'firstname4.lastName4@example.com', 
                         Username = 'firstname4.lastName4@kpark.fr.fsl', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'test4',  
                         TimeZoneSidKey = 'Europe/Paris', 
                         LocaleSidKey = 'fr_FR_EURO', 
                         LanguageLocaleKey = 'fr', 
                         matriculeGC__c = 'testResource4',
                         IsActive = true,
                         ProfileId = pf[0].Id,
                         dateEntree__c = System.now().Date().addDays(10),
                         dateSortie__c = System.now().Date().addDays(13)
                        ); 
        listeUser.add(u4);
        Database.insert (listeUser,false);
        
        List<ServiceResource> listeSR =new List<ServiceResource> ();
        ServiceResource sr1 = new ServiceResource(fsl_matriculeGC__c='RES03',fsl_SGID__c='SGID03',name='MetreurTest3',ResourceType='T',RelatedRecordId=listeUser[0].id,IsActive=true);           
        listeSR.add(sr1);
        ServiceResource sr2 = new ServiceResource(fsl_matriculeGC__c='RES04',fsl_SGID__c='SGID04',name='MetreurTest4',ResourceType='T',RelatedRecordId=listeUser[1].id,IsActive=true);
        listeSR.add(sr2);
        Database.insert (listeSR,false);
        
        ServiceTerritory st1 = [select id from ServiceTerritory where Name='Depot'];   
        List<ServiceTerritoryMember> listeSTM1=new List<ServiceTerritoryMember> ();
        ServiceTerritoryMember stm1= new ServiceTerritoryMember(EffectiveStartDate=System.today(),ServiceResourceId=listeSR[0].id,ServiceTerritoryId=st1.id,TerritoryType='P',OperatingHoursId=oh.Id);           
        listeSTM1.add(stm1);
        ServiceTerritoryMember stm2= new ServiceTerritoryMember(EffectiveStartDate=System.today(),ServiceResourceId=listeSR[1].id,ServiceTerritoryId=st1.id,TerritoryType='P',OperatingHoursId=oh.Id);           
        listeSTM1.add(stm2);        
        Database.insert (listeSTM1,false);      
        
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = listeSR[0].id;
        ar1.fsl_typeRessourceAttribuee__c = 'Principale';
        listeAR.add(ar1);
        AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = listeSR[1].id;
        ar2.fsl_typeRessourceAttribuee__c = 'Secondaire';
        listeAR.add(ar2);              
        
        try{
            //attribuer une ressource à rdv
            Database.update (sa,false);             
            Database.insert (listeAR,false);
        }catch(Exception e){
            System.debug('**Error AssignedResource** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown =  e.getMessage().contains(Label.fsl_errorDatesAssignedResourceServiceAppointment);           
            System.assertEquals(true,expectedExceptionThrown);            
        }     
        
        Test.stopTest();                
    }
    
}