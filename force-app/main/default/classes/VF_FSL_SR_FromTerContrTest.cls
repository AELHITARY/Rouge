/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-04-15          Class created.
2.0     DPHA            2019-04-30          Modification after the update of parent class

*/
@isTest
public class VF_FSL_SR_FromTerContrTest {
    //Data setup. 
    @testSetup 
    public static void testSetup() {
        List<GlobalProperties__c> listeGP =TestData_fsl_Setup.createGlobalProperties();
        List<mapping__c> listeGP1 =TestData_fsl_Setup.createGlobalProperties1();
    }
    
    @isTest 
    public static void testVerificationSetup() {
        
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
        List<ServiceResource> newSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(newSR,st,oh); 
         /*List<User> lstUser= [select id, matriculeGC__c from user where matriculeGC__c LIKE '%testResource%'];
         System.assertEquals(2,lstUser.size());
         List<Account> listAccount = [select id,name from Account where Name='TestAccount'];
         System.assertEquals(1,listAccount.size());
         List<WorkType> listWorkType = [select id,name from WorkType where Name='METRAGE'];
         System.assertEquals(1,listWorkType.size());
         List<Skill> lstSkill = [select id from Skill where MasterLabel = 'Métrage'];
         System.assertEquals(1,lstSkill.size());
         List<SkillRequirement> listSkillRequirement = [select id from SkillRequirement where skillId IN : lstSkill];
         //System.assertEquals(2,listSkillRequirement.size());
         List<OperatingHours> listOperatingHours = [select id,name from OperatingHours where Name='K/K Semaine type standard'];
         //System.assertEquals(1,listOperatingHours.size());
         List<ServiceTerritory> listDS = [select id,name from ServiceTerritory where Name='DS'];
         //System.assertEquals(1,listDS.size());
         List<ServiceTerritory> listDepot = [select id,name from ServiceTerritory where Name='Depot'];
         //System.assertEquals(1,listDepot.size());
         List<Chantier__c> listChantier = [select id,name from Chantier__c where Name='testChantier'];
         //System.assertEquals(1,listChantier.size());
         List<KContrat__c> listContrat = [select id,name from KContrat__c where Name='TestContrat'];
         //System.assertEquals(1,listContrat.size());
         List<WorkOrder> listWorkOrder = [select id from WorkOrder where FSL_EXTERNALID__C='ParentWorkOrder'];
         //System.assertEquals(1,listWorkOrder.size());
         List<ServiceResource> listServiceResource = [select id from ServiceResource where fsl_matriculeGC__c like '%RES0%'];
         //System.assertEquals(2,listServiceResource.size());
         List<ServiceTerritoryMember> listServiceTerritoryMember = [select id from ServiceTerritoryMember where ServiceResourceId in :listServiceResource];
         //System.assertEquals(2,listServiceTerritoryMember.size());*/
        Test.stopTest();
    }    
    
    //Test récupération des données pour l'affichage de la liste des Service Resources
    public static testmethod void testDisplayPage()
    {
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
        List<ServiceResource> newSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(newSR,st,oh); 
        
        //Préparation des données à injecter dans l'URL
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];

        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        update srToUpdate;
        System.debug('SR TO UPDATE -----------' + srToUpdate);
        
        ServiceTerritoryMember stm2 = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        update stm2;
        
        System.debug('STM 2 -----------' + stm2);
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_FeuilleRoute;
        Test.setCurrentPage(pageRef);
        //ApexPages.currentPage().getParameters().put('idRes', stm2.ServiceResourceId);
        ApexPages.currentPage().getParameters().put('listTer', stm2.ServiceTerritoryId);
        
        //Instanciation de la classe        
        VF_FSL_SR_FromTerritoryController  sftc = new VF_FSL_SR_FromTerritoryController();

     
        sftc.createResource();
        sftc.displayPage();
        
        Test.stopTest();
       
        System.assertNotEquals(null, sftc.displayPage());
    }     
}