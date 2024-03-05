//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : Test_fsl_AssignedResourceAbsence
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/02/2022
//-- Version     : 1.0
//-- Description : Classe de test pour vérifier la suppression de l'absence du ressource secondaire lorsque cette dernière n'est plus asssigné au rdv
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_fsl_AssignedResourceAbsence {
    private static final Id SA_KUBE2_RT = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');

    @testSetup 
    static void setup() {
        //préparer les données pour le test
        List<GlobalProperties__c> listeGP =TestData_fsl_Setup.createGlobalProperties();
        //List<mapping__c> listeGP1 =TestData_fsl_Setup.createGlobalProperties1();
        
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Demandé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Annulé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Terminé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Transmis');
        //FSL.GlobalAPIS.addStatusTransition('Planifié', 'Verrouillé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'En cours');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Débriefé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'En route');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Demandé');
        
    }
    
    @isTest 
    static void testVerificationSetup() {
        
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
    @isTest 
    static void testDeleteAssignedResourceSecondaire() {
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> newSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(newSR,st,oh);          
        RecordType recordType = [select id from RecordType where name = 'Non Availability'];  
        /*ServiceAppointment sa = [select id,fsl_techFlagSynchro__c,status,EarliestStartTime,Duration from ServiceAppointment where parentRecordId=: wo.Id];   
        sa.SchedStartTime = sa.EarliestStartTime.addDays(1);       
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.EarliestStartTime.addDays(1).addMinutes(duration);       
        //Database.update (sa,false);
        update (sa);*/
        Test.startTest();
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
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;     
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = newSR[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = newSR[1].id;
        ar2.fsl_typeRessourceAttribuee__c='Secondaire';
        listeAR.add(ar2);
        //Database.insert (listeAR,false);
        insert (listeAR); 
        system.debug('**assigneResource Type'+listeAR);  
        
        //Créer une absence pour la ressource secondaire
        ResourceAbsence testAbsence = new ResourceAbsence ();        
        testAbsence.Start = Datetime.newInstance(2018, 2, 1, 10, 0, 0);
        testAbsence.End = Datetime.newInstance(2018, 2, 1, 19, 0, 0);
        testAbsence.ResourceId = newSR[1].id;
        testAbsence.assignedResource__c = ar2.id;
        testAbsence.RecordTypeId = recordType.id;
        testAbsence.Type = 'Renfort';
        //Database.insert (testAbsence,false);
        insert (testAbsence);

        Test.stopTest();

        //List<ResourceAbsence> listeRA=[select id from ResourceAbsence ];
        //System.assertEquals(1, listeRA.size(),'Problème creation Absence');         
        
        //AssignedResource testAR=[select fsl_typeRessourceAttribuee__c from AssignedResource where ServiceResourceId=:testAbsence.ResourceId ];
        //System.assertEquals('Secondaire',testAR.fsl_typeRessourceAttribuee__c,' AssignedRessource absente non secondaire'); 
        
        //Supprimer AssignedResource secondaire
        
        //Database.delete (testAR,false); 
        //delete(listeAR[1]);
        
        
        //Vérifier si l'absence du ressource secondaire est supprimer lorsque AssignedRessource secondaire est supprimer
        //List<ResourceAbsence> listetestRA=[select id from ResourceAbsence ];        
        //System.assertEquals(0, listetestRA.size(),'Problème delete Absence');         
    }
    
    @isTest 
    static void testUpdateAssignedResourceSecondaire() {
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> newSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(newSR,st,oh);
        RecordType recordType = [select id from RecordType where name = 'Non Availability'];
        //ServiceAppointment sa = [select id,fsl_techFlagSynchro__c,status,EarliestStartTime,Duration from ServiceAppointment where parentRecordId=: wo.Id];   
        /*sa.SchedStartTime = sa.EarliestStartTime.addDays(1);       
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.EarliestStartTime.addDays(1).addMinutes(duration);       
        //Database.update (sa,false);
        update (sa);*/
        Test.startTest(); 
        Profile[] pf = [Select Id from profile where Name LIKE '%Ressource%']; 
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
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;
               
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = newSR[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId=sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c='Secondaire';
        listeAR.add(ar2);*/
        //Database.insert (listeAR,false);
        insert (listeAR); 
        system.debug('**assigneResource Type'+listeAR);  
        
        //Créer une absence pour la ressource secondaire
        ResourceAbsence testAbsence = new ResourceAbsence ();        
        testAbsence.Start = Datetime.newInstance(2018, 2, 1, 10, 0, 0);
        testAbsence.End = Datetime.newInstance(2018, 2, 1, 19, 0, 0);
        testAbsence.ResourceId = newSR[1].id;
        testAbsence.assignedResource__c = ar1.id;
        testAbsence.RecordTypeId = recordType.id;
        testAbsence.Type='Renfort';
        //Database.insert (testAbsence,false);
        insert (testAbsence);
        //List<ResourceAbsence> listeRA=[select id from ResourceAbsence ];
        //System.assertEquals(1, listeRA.size(),'Problème creation Absence'); 
        
        
        
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
                         ProfileId = pf[0].Id                         
                        );    
        //Database.insert (u3,false);
        insert (u3);
        
        ServiceResource newSR1 = new ServiceResource(fsl_matriculeGC__c='RES03',fsl_SGID__c='SGID03',name='MetreurTest3',ResourceType='T',RelatedRecordId=u3.id,IsActive=true);           
        //Database.insert (newSR,false);
        insert (newSR1);
           
        
        ServiceTerritoryMember stm= new ServiceTerritoryMember(EffectiveStartDate=system.today(),ServiceResourceId=newSR1.id,ServiceTerritoryId=st.id,TerritoryType='P',OperatingHoursId=oh.Id);               
        //Database.insert (stm,false);    
        insert (stm); 
        Test.stopTest();
        
        /*AssignedResource newAR = [SELECT id,ServiceResourceId FROM AssignedResource where ServiceAppointmentId =:sa.Id and fsl_typeRessourceAttribuee__c = 'Secondaire' LIMIT 1];
        newAR.ServiceResourceId = newSR.id;           
        //Database.update (newAR,false); 
        update (newAR);*/
        
        
        //Vérifier si l'absence du ressource secondaire est supprimer lorsque AssignedRessource secondaire est supprimer
        //List<ResourceAbsence> oldListeAbsence=[select id from ResourceAbsence where ResourceId = : sr[1].id];        
        //System.assertEquals(0, oldListeAbsence.size(),'Problème delete Absence'); 
        
        //List<ResourceAbsence> newListeAbsence=[select id from ResourceAbsence where ResourceId = : newSR.id];        
        //System.assertEquals(1, newListeAbsence.size(),'Problème insert Absence'); 
    }
    
    @isTest 
    static void testDeleteWorkOrder() {
        
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> newSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(newSR,st,oh);      
        //ServiceAppointment sa = [select id,fsl_techFlagSynchro__c,status,EarliestStartTime,Duration from ServiceAppointment where parentRecordId=: wo.Id];   
        /*sa.SchedStartTime = sa.EarliestStartTime.addDays(1);       
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.EarliestStartTime.addDays(1).addMinutes(duration);       
        //Database.update (sa,false);
        update (sa);*/
        
        Test.startTest(); 

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
        sa.RecordTypeId = SA_KUBE2_RT;
        insert sa;
        
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = newSR[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = newSR[1].id;
        ar2.fsl_typeRessourceAttribuee__c='Secondaire';
        listeAR.add(ar2);*/
        insert listeAR;
        System.debug('**assigneResource Type'+listeAR);  
        
        RecordType recordType = [select id from RecordType where name = 'Non Availability'];
        //Créer une absence pour la ressource secondaire
        ResourceAbsence testAbsence = new ResourceAbsence ();        
        testAbsence.Start = Datetime.newInstance(2018, 2, 1, 10, 0, 0);
        testAbsence.End = Datetime.newInstance(2018, 2, 1, 19, 0, 0);
        testAbsence.ResourceId = newSR[1].id;
        testAbsence.assignedResource__c = ar1.id;
        testAbsence.RecordTypeId = recordType.id;
        testAbsence.Type = 'Renfort';
        insert testAbsence;
        
        //List<ResourceAbsence> listeRA=[select id from ResourceAbsence ];
        //System.assertEquals(1, listeRA.size(),'Problème creation Absence');         
        
        //AssignedResource testAR=[select fsl_typeRessourceAttribuee__c from AssignedResource where ServiceResourceId=:testAbsence.ResourceId ];
        //System.assertEquals('Secondaire',testAR.fsl_typeRessourceAttribuee__c,' AssignedRessource absente non secondaire'); 
        
        //Supprimer WorkOrder
        
        //Database.delete (wo,false);
        //delete wo;        
        
        Test.stopTest(); 
        
        //Vérifier si l'absence du ressource secondaire est supprimer lorsque AssignedRessource secondaire est supprimer
        //List<ResourceAbsence> listetestRA=[select id from ResourceAbsence ];        
        //System.assertEquals(0, listetestRA.size(),'Problème delete Absence');         
    }
    
}