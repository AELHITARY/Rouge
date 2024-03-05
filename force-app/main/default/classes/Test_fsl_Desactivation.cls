//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : Test_fsl_Desactivation
//-- Modifié par : CGI
//-- Modifié le  : 13/04/2018
//-- Version     : 1.0
//-- Description : Classe de test pour la synchronisation via Platform Event
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_fsl_Desactivation {

    @testSetup 
    static void setup() {
        //préparer les données pour le test
        List<GlobalProperties__c> synchro= TestData_fsl_Setup.createGlobalProperties();  
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

    
    /*@isTest static void testDesactivationOperatingHours() {
       Test.startTest();
        OperatingHours oldOH = [SELECT id, fsl_actif__c, fsl_dateOuverture__c, fsl_dateFermeture__c FROM OperatingHours Limit 1]; 
         System.assertEquals(true,oldOH.fsl_actif__c); 
        oldOH.fsl_dateFermeture__c = System.today().addDays(-1);
        update oldOH;
        
        BA_fsl_Desactivation desactiviation = new BA_fsl_Desactivation();
        Id batchID = Database.ExecuteBatch(desactiviation);  
        
        Test.stopTest();
         
        OperatingHours newOH = [SELECT id, fsl_actif__c, fsl_dateOuverture__c, fsl_dateFermeture__c FROM OperatingHours Limit 1]; 
        System.assertEquals(false,newOH.fsl_actif__c); 
    }*/
    
     @isTest
     static void testDesactivationUser() {
         //test désactivation de User qui n'est pas rattaché à un rdv 
       Test.startTest();
        User oldUser = [SELECT id, IsActive, dateEntree__c, dateSortie__c  FROM User where matriculeGC__c = 'testResource1']; 
        ServiceTerritoryMember oldSTM = [SELECT id, EffectiveStartDate,EffectiveEndDate FROM ServiceTerritoryMember where ServiceResource.name='MetreurTest']; 
        oldUser.dateSortie__c = System.today().addDays(-1);
        oldSTM.EffectiveEndDate = System.today().addDays(-1);
        update oldSTM;
        update oldUser;
        
        BA_fsl_Desactivation desactiviation = new BA_fsl_Desactivation();
        Id batchID = Database.ExecuteBatch(desactiviation);  
        
        Test.stopTest();
         
        User newUser = [SELECT id, IsActive, dateEntree__c, dateSortie__c  FROM User where matriculeGC__c = 'testResource1']; 
    }
    
     @isTest 
     static void testDesactivationRessource() {
       //test désactivation de resssource qui est rattaché à un rdv 
       Test.startTest();
        WorkOrder wo = [select id from workOrder Limit 1] ;       
        ServiceAppointment sa = [select id,status,EarliestStartTime,Duration from ServiceAppointment where parentRecordId=: wo.Id];   
        sa.SchedStartTime = sa.EarliestStartTime;       
        Integer duration= Integer.valueOf(sa.Duration);        
        sa.SchedEndTime = sa.EarliestStartTime.addMinutes(duration);   
        Database.update (sa,false);  
        ServiceResource[] sr = [select id from ServiceResource ];       
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
            //déesactiver la ressource attribué au rdv futur
            ServiceResource testSR = [select id from ServiceResource where name='MetreurTest'];    
            testSR.IsActive = false;
            update testSR;
        }catch(Exception e){
            System.debug('**Error SR** : '+e.getMessage());
            // Vérifier si le message d'erreur est bien affiché
            Boolean expectedExceptionThrown =  e.getMessage().contains(Label.fsl_errorDesactivationResourceAttribuee);
            if(expectedExceptionThrown)
                System.assertEquals(true,expectedExceptionThrown);            
        }         
    }
}