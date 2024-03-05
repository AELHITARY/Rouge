//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_FieldServiceUtils
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/10/2022
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_FieldServiceUtils {

    @testSetup 
    static void setup() {
        //préparer les données pour le test
        List<GlobalProperties__c> listeGP =TestData_fsl_Setup.createGlobalProperties();
        
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Demandé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Annulé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Terminé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Transmis');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'En cours');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'Débriefé');
        FSL.GlobalAPIS.addStatusTransition('Planifié', 'En route');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Demandé');        
    }

    @isTest 
    static void test() {
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);
        
        Test.startTest();

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = Date.today()+2;
        sa.SchedStartTime = Date.today()+2;
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        insert sa;
        
        //Création de la ressource attribuée
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        insert (listeAR);  

        FieldServiceUtils.crlCoherenceDate(Date.today(), Date.today()+1, Date.today(), Date.today()+1);        
        FieldServiceUtils.crlCoherenceDateTime(System.now(), System.now()+1, System.now(), System.now()+1);
        FieldServiceUtils.construireMapServiceAppointment(listeAR);
        FieldServiceUtils.construireMapServiceResource(listeAR);
        FieldServiceUtils.construireMapRessourceIdToListSA(listeAR);
        FieldServiceUtils.crlDesactivation(Date.today(), Date.today()+1, true);

        FieldServiceUtils.createMapExternalIdByWorkOrder(new Set<string>{wo.Id});
        FieldServiceUtils.createMapRessource(new Set<string>{wo.Id});
        FieldServiceUtils.createMapParentWorkOrder(new Set<string>{wo.Id});
        FieldServiceUtils.createMapAccount(new Set<string>{a.Id});
        FieldServiceUtils.createMapContrat(new Set<string>{c.Id});
        Map<String, Account> accMap = new Map<String, Account>();
        accMap.put(a.Id, a);
        FieldServiceUtils.createMapChantier(accMap);
        FieldServiceUtils.createMapWorkType(new Set<string>{wt.Id});
        FieldServiceUtils.createMapServiceTerritory(new Set<string>{parentST.Id});
        FieldServiceUtils.createMapWorkOrderIDbyExternalId(new List<WorkOrder>{wo});

        FieldServiceUtils.createMapSkillIdByName(new List<DemandeRDV__e>());
        FieldServiceUtils.createMapResourceIdByMatricule(new List<DemandeRDV__e>());

        GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.exception.email'); 
        FieldServiceUtils.conversionStringDate(Date.today().format(), new DemandeRDV__e(), emailException);
        FieldServiceUtils.ConversionDateString(System.now());
        FieldServiceUtils.serviceEmailAlert(new KubeException(), null, 'TEST',new DemandeRDV__e(), null, emailException);
        
        FieldServiceUtils.replaceIfNull(null, System.now());
        FieldServiceUtils.getIdList(new List<WorkOrder>{wo});
        FieldServiceUtils.getObjectMap(new List<WorkOrder>{wo});

        Test.stopTest();
    }
    
    @isTest 
    static void test2() {
        User [] u = TestData_fsl_Setup.createUser();
        Account a = TestData_fsl_Setup.createAccount();
        WorkType wt = TestData_fsl_Setup.createWorkType();
        SkillRequirement sk = TestData_fsl_Setup.createSkillRequirement(wt);
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);
        Chantier__c chantier= TestData_fsl_Setup.createChantier(a);
        KContrat__c c = TestData_fsl_Setup.createContrat(a,chantier);
        WorkOrder wo= TestData_fsl_Setup.createWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> sr= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(sr,st,oh);

        Test.startTest();
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = Date.today()+2;
        sa.SchedStartTime = Date.today()+2;
        sa.Duration = 180.0;
        sa.fsl_dateConfirmation__c = date.today();
        sa.Status = 'Confirmé';
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        insert sa;
        
        //Création de la ressource attribuée
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = sr[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        insert (listeAR);  

        FieldServiceUtils.getMapUserId(u);
        FieldServiceUtils.getProfondeurMap();
        FieldServiceUtils.getFslAutorisationMap();
        FieldServiceUtils.loadFslAutorisationMap('TEST');
        FieldServiceUtils.getFslProfileMap();
        FieldServiceUtils.loadFslProfileMap();

        FieldServiceUtils.ifInPeriodeCalendarService(Date.today(), Date.today()+1, Date.today()-1);
        FieldServiceUtils.ifInPeriodeCalendarService(Date.today(), Date.today(), Date.today());

        FieldServiceUtils.definirFinPeriodeSelonProfondeur(1, Date.today(), Date.today());
        FieldServiceUtils.definirFinPeriodeSelonProfondeur(2, Date.today(), Date.today());
        FieldServiceUtils.definirFinPeriodeSelonProfondeur(3, Date.today(), Date.today());

        Test.stopTest();
    }
    
    @isTest 
    static void testDatabaseAction() {
        User [] u = TestData_fsl_Setup.createUser();
        u[0].LastName = '';

        Test.startTest();

        try {
            GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.exception.email'); 
            FieldServiceUtils.databaseAction('insert', 'TEST', null);
            FieldServiceUtils.databaseAction('update', 'TEST', u);
            FieldServiceUtils.databaseAction('delete', 'TEST', u);
            FieldServiceError err = FieldServiceUtils.databaseAction('upsert', 'TEST', u);
            FieldServiceUtils.serviceEmailAlertGenRess('TEST', err, emailException);
        } catch(Exception ex) {}

        Test.stopTest();
    }
}