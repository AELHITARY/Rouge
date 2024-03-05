//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_FSL_FDR_ServiceAppointmentAbsence 
//-- Auteur      : CGI
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/06/2022
//-- Version     : 1.2
//-- 1.2 - Correctif Ajout bypass WorkFlowRule sur testDisplayPage
//-- 1.1 - Mise à jour pour Kube3
//-- 1.0 - Class created.
//-- --------------------------------------------------------------------------------- --
@IsTest
public class Test_FSL_FDR_ServiceAppointmentAbsence {

    //Data Setup
    @testSetup 
    static void setup() {
        //préparer les données pour le test
        List<GlobalProperties__c> synchro= TestData_fsl_Setup.createGlobalProperties();  
        
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Demandé', 'Confirmé');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Planifié');
        FSL.GlobalAPIS.addStatusTransition('Confirmé', 'Demandé');  

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
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
    }
    
    //Test création de la liste des dates comprises entre la date de début et de fin + Vérification du message d'erreur si pas de RDV 
    @isTest 
    static void testGetListDateAndError() {
        Test.startTest(); 

        //Paramétrage de l'URL 
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1][0];
        Date today = Date.today();
        String dateDeb = String.valueOf(today);
        String dateFin = String.valueOf(today+3);
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_ServiceAppointmentAbsence;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('listResId', sr.id);
        ApexPages.currentPage().getParameters().put('start', dateDeb);
        ApexPages.currentPage().getParameters().put('end', dateFin);
        
        //Instanciation de la classe        
        CTRL_FSL_FDR_ServiceAppointmentAbsence  cffsaa = new CTRL_FSL_FDR_ServiceAppointmentAbsence();
        
        List<Date> lDate= new List<Date>(); 
        lDate = cffsaa.getListDate();
        
        Test.stopTest(); 
        
        System.assertEquals(4, lDate.size());
        System.assertEquals('AucunRDV', cffsaa.error);
        
    }
    
    //Test affichage page 
    @isTest 
    static void testDisplayPage() {
        
        //Paramétrage de l'URL 
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1][0];
        Date today = Date.today();
        String dateDeb = String.valueOf(today);
        String dateFin = String.valueOf(today+3);
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_ServiceAppointmentAbsence;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('listResId', sr.id);
        ApexPages.currentPage().getParameters().put('start', dateDeb);
        ApexPages.currentPage().getParameters().put('end', dateFin);
        
        
        //Création RDV 
        WorkOrder WO = [SELECT Id FROM WorkOrder LIMIT 1][0];
        //Instanciation de la classe        
        CTRL_FSL_FDR_ServiceAppointmentAbsence  cffsaa = new CTRL_FSL_FDR_ServiceAppointmentAbsence();

        String uniqueUserName = 'adminPlan' + DateTime.now().getTime() + '@testorg.com';
        
        User userToRun = new User(
            Alias = 'adminP', 
            Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', 
            LastName='Planificateur', 
            LanguageLocaleKey='fr',
            LocaleSidKey='fr_FR', 
            ProfileId = '00eD0000001iahAIAQ',
            TimeZoneSidKey='Europe/Paris',
            UserName= uniqueUserName,
            ByPassWorkflowRule__c = true);
        insert userToRun;

        System.runAs(userToRun){
            Test.startTest();

            
            ServiceAppointment sa = new ServiceAppointment();
            sa.ParentRecordId = wo.Id;
            sa.EarliestStartTime = Date.today()+2;
            sa.Duration = 180.0;
            Integer duration= Integer.valueOf(sa.Duration);        
            sa.SchedStartTime = Date.today()+2;
            sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
            sa.fsl_dateConfirmation__c = date.today();
            sa.Status = 'Confirmé';
            insert sa;

            System.debug('**Sa.id='+sa.id);

            //Création de la ressource attribuée
            List<AssignedResource> listeAR = new list<AssignedResource> ();
            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa.id;
            ar1.ServiceResourceId = sr.id;
            ar1.fsl_typeRessourceAttribuee__c='Principale';
            listeAR.add(ar1);
            insert listeAR; 

            //Création d'une absence 
            RecordType recordType = [select id from RecordType where name = 'Non Availability'];
            //Créer une absence pour la ressource secondaire
            ResourceAbsence abs = new ResourceAbsence ();        
            abs.Start = DateTime.newInstance(today.year(), today.month(), today.day(), 10, 0, 0);
            abs.End = DateTime.newInstance(today.year(), today.month(), today.day(), 19, 0, 0);
            abs.ResourceId = sr.id;
            abs.assignedResource__c = ar1.id;
            abs.RecordTypeId = recordType.id;
            abs.Type = 'Renfort';
            insert abs;
            
            cffsaa.createMapResourceSac();
            Test.stopTest();
        }
        System.assertEquals(1, cffsaa.getListServiceResource().size());         
        
    }
    
}