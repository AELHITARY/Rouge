@isTest
public class Test_fsl_ArUpdateRenfort {
    @testSetup static void setup() {
        //Préparation d'un jeu de données
        
    }
    
     @isTest static void testVerificationSetup() {

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
    
    @isTest static void testScopeOk() {
        


         List<GlobalProperties__c> listeGP =TestData_fsl_Setup.createGlobalProperties();
        List<mapping__c> listeGP1 =TestData_fsl_Setup.createGlobalProperties1();
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
        //Création du RDV
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
        //Sélecton de la ressource  
        
        //Création de la ressource attribuée
        List<AssignedResource> listeAR = new list<AssignedResource> ();
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = sa.id;
        ar1.ServiceResourceId = newSR[0].id;
        ar1.fsl_typeRessourceAttribuee__c='Principale';
        listeAR.add(ar1);
        /*AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = sa.id;
        ar2.ServiceResourceId = sr[1].id;
        ar2.fsl_typeRessourceAttribuee__c='Secondaire';
        listeAR.add(ar2);*/
        //Database.insert (listeAR,false);
        insert (listeAR);  
        
        RecordType recordType = [select id from RecordType where name = 'Non Availability'];
        //Créer une absence pour la ressource secondaire
        ResourceAbsence testAbsence = new ResourceAbsence (); 
        testAbsence.Start = Date.today()+2;
        testAbsence.End = testAbsence.Start + 2;
        testAbsence.ResourceId = newSR[0].id;
        testAbsence.assignedResource__c = ar1.id;
        testAbsence.RecordTypeId = recordType.id;
        testAbsence.Type = 'Renfort';
        //Database.insert (testAbsence,false);
        insert (testAbsence);
        
        //List<AssignedResource> lAssignedResource =[select id, fsl_typeRessourceAttribuee__c from AssignedResource WHERE fsl_typeRessourceAttribuee__c='Secondaire'];
        //System.assertEquals(1 , lAssignedResource.size(), 'Problème nombre ressource');         
        
        
        
        BA_fsl_ArUpdateRenfort baur = new BA_fsl_ArUpdateRenfort();
        Id batchId = Database.executeBatch(baur);

        Test.stopTest(); 
        
        //Vérifier si l'absence du ressource secondaire est supprimée lorsque AssignedRessource secondaire est supprimer
        //List<AssignedResource> listetestAR=[select id, fsl_typeRessourceAttribuee__c, LastModifiedDate from AssignedResource WHERE fsl_typeRessourceAttribuee__c='Secondaire'];        
        //System.assertEquals(1, listetestAR.size(),'Absence inconnue');  
        
        //Vérification de l'update 
        /*DateTime dTar = listetestAR[0].LastModifiedDate;
        Date myDateAr = date.newInstance(dTar.year(), dTar.month(), dTar.day());
        
        DateTime now = DateTime.now();
        Date dateNow = Date.newInstance(now.year(), now.month(), now.day());
        
        System.assertEquals(dateNow, myDateAr, 'Date non correspondante');*/
    }
}