//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : Test_fsl_PlatformEvent
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 29/07/2022
//-- Version     : 1.0
//-- Description : Classe de test pour la synchronisation via Platform Event
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_fsl_PlatformEvent {

    @testSetup 
    static void setup() {
        //préparer les données pour le test
        List<GlobalProperties__c> synchro= TestData_fsl_Setup.createGlobalProperties();  
        
        /*ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = wo.Id;
        sa.Subject = 'Harry Potter';
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.fsl_chiffreAffaire__c = 1000;
        insert sa;*/
    }
    
    @isTest 
    static void testInsertWorkOrder() {
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);

        Test.startTest();    

        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(listeSR,wo);
        List<DemandeRDV__e> events = new List<DemandeRDV__e>(); 
        DateTime now=System.now();
        String startDate=FieldServiceUtils.ConversionDateString(now.addDays(1));
        String endDate1=FieldServiceUtils.ConversionDateString(DateTime.newInstance(2018, 4, 1, 10, 0, 0));
        String endDate2=FieldServiceUtils.ConversionDateString(now.addDays(3));
        DemandeRDV__e insertEvent1 = new DemandeRDV__e(FSL_EXTERNALID__C='ChildWorkOrder',
                                                      FSL_ACCOUNTEXTERNAL__C=a.AccountNumber,
                                                      FSL_PARENTWORKORDEREXTERNAL__C='ParentWorkOrder',
                                                      FSL_SERVICETERRITORYEXTERNAL__C='DEP',
                                                      FSL_WORKTYPEEXTERNAL__C='METRAGE',
                                                      FSL_CHIFFREAFFAIRE__C=2090,
                                                      FSL_CONTRATKEXTERNAL__C='NEWCTR',
                                                      FSL_DURATIONTYPE__C='Minutes',
                                                      FSL_DURATION__C=40,
                                                      FSL_ENDDATE__C=endDate1,
                                                      FSL_MONTANTATTENDU__C=850,
                                                      FSL_MONTANTCONTRAT__C=1000,
                                                      FSL_SOLDECLIENT__C=2000,
                                                      FSL_NOMBREINTERVENANTS__C=1,
                                                      FSL_PRIORITY__C='FAIBLE',
                                                      FSL_STARTDATE__C=null,
                                                      FSL_SUBJECT__C='PE_test1',
                                                      FSL_DOCUMENTSATTENDUS__C='AVI;TVA',
                                                      FSL_SKILLEXTERNAL__C='ELECTRICITE:1',
                                                      FSL_STREET__C='34 rue de la faisanderie',
                                                      FSL_POSTALCODE__C='75016',
                                                      FSL_STATE__C='Ile de France',
                                                      FSL_CITY__C='Paris',
                                                      FSL_COUNTRY__C='France',
                                                      FSL_HOMEPHONE__C = 0133333434,
                                                      FSL_MOBILEPHONE__C = 0633333434,
                                                      FSL_RESSOURCESOBLIGATOIRES__C ='99008471:9999008471:MARCEL BRUN',
                                                      FSL_RESSOURCESRECOMMANDEES__C = '99008507:9999008507:AMAPOSE',
                                                      FSL_RESSOURCESINTERDITES__C = '10010371:F4857070:FREDERIC MULLER');      
        events.add(insertEvent1);
        
        // Publier les events   
        List<Database.SaveResult> results = EventBus.publish(events);   
                 
        Test.stopTest();      
    }
    
    @isTest 
    static void testInsertWorkOrder2() {
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);

        Test.startTest();    

        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(listeSR,wo);
        List<DemandeRDV__e> events = new List<DemandeRDV__e>(); 
        DateTime now=System.now();
        String startDate=FieldServiceUtils.ConversionDateString(now.addDays(1));
        String endDate1=FieldServiceUtils.ConversionDateString(DateTime.newInstance(2018, 4, 1, 10, 0, 0));
        String endDate2=FieldServiceUtils.ConversionDateString(now.addDays(3));
        DemandeRDV__e insertEvent1 = new DemandeRDV__e(FSL_EXTERNALID__C='ChildWorkOrder',
                                                      FSL_ACCOUNTEXTERNAL__C=a.AccountNumber,
                                                      FSL_PARENTWORKORDEREXTERNAL__C='ParentWorkOrder',
                                                      FSL_SERVICETERRITORYEXTERNAL__C='DEP',
                                                      FSL_WORKTYPEEXTERNAL__C='METRAGE',
                                                      FSL_CHIFFREAFFAIRE__C=2090,
                                                      FSL_CONTRATKEXTERNAL__C='NEWCTR',
                                                      FSL_DURATIONTYPE__C='Minutes',
                                                      FSL_DURATION__C=40,
                                                      FSL_ENDDATE__C=endDate1,
                                                      FSL_MONTANTATTENDU__C=850,
                                                      FSL_MONTANTCONTRAT__C=1000,
                                                      FSL_SOLDECLIENT__C=2000,
                                                      FSL_NOMBREINTERVENANTS__C=1,
                                                      FSL_PRIORITY__C='FAIBLE',
                                                      FSL_STARTDATE__C=startDate,
                                                      FSL_SUBJECT__C='PE_test1',
                                                      FSL_DOCUMENTSATTENDUS__C='AVI;TVA',
                                                      FSL_SKILLEXTERNAL__C='ELECTRICITE:1',
                                                      FSL_STREET__C='34 rue de la faisanderie',
                                                      FSL_POSTALCODE__C='75016',
                                                      FSL_STATE__C='Ile de France',
                                                      FSL_CITY__C='Paris',
                                                      FSL_COUNTRY__C='France',
                                                      FSL_HOMEPHONE__C = 0133333434,
                                                      FSL_MOBILEPHONE__C = 0633333434,
                                                      FSL_RESSOURCESOBLIGATOIRES__C ='99008471:9999008471:MARCEL BRUN',
                                                      FSL_RESSOURCESRECOMMANDEES__C = '99008507:9999008507:AMAPOSE',
                                                      FSL_RESSOURCESINTERDITES__C = '10010371:F4857070:FREDERIC MULLER');      
        events.add(insertEvent1);
        
        // Publier les events   
        List<Database.SaveResult> results = EventBus.publish(events);  
                
        Test.stopTest();      
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
        Test.startTest();     
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(listeSR,wo);
        List<SuppressionRDV__e> events = new List<SuppressionRDV__e>();
        SuppressionRDV__e deleteEvent = new SuppressionRDV__e(FSL_EXTERNALID__C='ParentWorkOrder');
        events.add(deleteEvent);
        
        List<WorkOrder> oldListeWO=[select id from WorkOrder];
        //le nombre de WorkOrder existe
        System.assertEquals(1, oldListeWO.size(),'Problème delete Workorder'); 
        
        // Publier les events  
        List<Database.SaveResult> results = EventBus.publish(events);       
        
        // Vérifier le nombre de WorkOrder après l'exécution de Trigger
        List<WorkOrder> listeWO=[select id from WorkOrder];
        //System.assertEquals(0, listeWO.size(),'Problème delete Workorder');
        Test.stopTest();                 
    }
    
    @isTest 
    static void testNotificationWorkOrder() {          
        //User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        //SkillRequirement sr = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        Test.startTest();     

        //Vérifier la mise à jour de la Date de dernière synchronisation
        GlobalProperties__c synchronisation = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.sync.wo');     
        DateTime now=System.now();
        DateTime lastSynchro=synchronisation.dateTimeValue__c; 

        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);
        wo.fsl_techFlagSynchro__c = Datetime.newInstance(2018, 2, 7, 10, 0, 0);
        update wo;
        // Pour que le test passe, il faut modifier custom label fsl_nbMinuteSynchroPE à 0 
        System.debug('wo rt:'+wo.RecordTypeId+' fsl_techFlagSynchro__c:'+wo.fsl_techFlagSynchro__c);
        
        //WorkOrder woreq = [SELECT Id,fsl_techFlagSynchro__c FROM WorkOrder WHERE RecordType.DeveloperName != 'workOrderService' /*AND (fsl_techFlagSynchro__c = :System.now() OR (fsl_techFlagSynchro__c > :lastSynchro AND fsl_techFlagSynchro__c < :System.now()))*/ LIMIT 1];
        //System.debug('woreq'+woreq);

        BA_fsl_NotificationWO batch = new BA_fsl_NotificationWO();
        Id BatchWO = Database.ExecuteBatch(batch);   
        
        
        
        //System.assertEquals(now.date(),lastSynchro.date(),'Problème publication de notification Workorder');       
        Test.stopTest();
    }
    
    
    @isTest 
    static void testNotificationServiceAppointment() { 
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
        test.startTest();    
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
        ResourcePreference rp = TestData_fsl_Setup.createResourcePreference(listeSR,wo); 
        
        // Pour que le test passe, il faut modifier custom label fsl_nbMinuteSynchroPE à 0 
            
        //ServiceAppointment sa=[select id,fsl_techFlagSynchro__c,status,EarliestStartTime,Duration from ServiceAppointment where parentRecordId=: wo.Id];   
        ServiceAppointment sa = new ServiceAppointment ();
        sa.ParentRecordId = wo.Id;
        sa.Subject = 'Harry Potter';
        sa.EarliestStartTime = Date.today();
        sa.SchedStartTime = Date.today();
        sa.Duration = 180.0;
        sa.Status = 'Confirmé';
        sa.fsl_dateConfirmation__c = date.today();
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.fsl_chiffreAffaire__c = 1000;
        insert sa;
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId=sa.id;
        ar1.ServiceResourceId = listeSR[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId=sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c='Secondaire';
        listeAR.add(ar2);*/
        //Database.insert (listeAR,false);
        insert (listeAR); 
        System.debug('assigneResource '+listeAR); 
        
        BA_fsl_NotificationSA batch = new BA_fsl_NotificationSA();
        Id BatchSA = Database.ExecuteBatch(batch);   
        
        
        //Vérifier la mise à jour de la Date de dernière synchronisation
        GlobalProperties__c synchronisation = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.sync.sa');  
        DateTime now=System.now();
        DateTime lastSynchro=synchronisation.dateTimeValue__c; 
        System.debug('**synchro *** '+synchronisation);
        test.stopTest();
        //System.assertEquals(now.date(),lastSynchro.date(),'Problème publication de notification ServiceAppointment');    
    }   
}