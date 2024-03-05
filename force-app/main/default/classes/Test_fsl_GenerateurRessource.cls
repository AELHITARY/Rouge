//-- --------------------------------------------------------------------------------- --
//-- * 
//-- Fichier     : Test_fsl_GenerateurRessource
//-- Modifié par : CGI
//-- Modifié le  : 26/03/2018
//-- Version     : 1.0
//-- Description : Classe de test pour calcul les chiffres d'affaires des ressources
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_fsl_GenerateurRessource {
    
    @testSetup public static void setup() {
        //préparer les données pour le test
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
        WorkOrder wo= TestData_fsl_Setup.createTestCAWorkOrder(a,wt,st,c,oh);      
        List<ServiceResource> listeSR= TestData_fsl_Setup.createServiceResource(u);       
        List<ServiceTerritoryMember> listeSTM = TestData_fsl_Setup.createServiceTerritoryMember(listeSR,st,oh);
        
    }
    
    @istest public static void testGenerationUser() {
        test.startTest();
        TR002_fsl_GenerateurRessource.doChainJob = false;
        List<fsl_tech_generateurRessource__c> userRessourceList  = new List<fsl_tech_generateurRessource__c>();
        fsl_tech_generateurRessource__c generateur = new fsl_tech_generateurRessource__c();
        generateur.fsl_defaultGroupNotificationFrequency__c= 'N';  
        generateur.fsl_alias__c= 'kwu';
        generateur.fsl_communityNickname__c= 'kemanwu';
        generateur.fsl_contentEmailAsAndWhen__c= 'TRUE';
        generateur.fsl_contentNoEmail__c= 'TRUE';
        generateur.fsl_dateEntree__c= '01/10/2017';
        generateur.fsl_dateEntreeDepot__c= '01/10/2017'; 
        generateur.fsl_depotCodeGC__c= 'DEP';
        generateur.fsl_digestFrequency__c= 'D';
        generateur.fsl_email__c= 'keman.wu@reprisekpark.fr';
        generateur.fsl_emailEncodingKey__c= 'iso-8859-1';
        generateur.fsl_firstName__c= 'KEMAN';    
        generateur.fsl_metier__c= 'SVC0010';    
        generateur.fsl_matriculeGC__c= '123456';
        generateur.fsl_localeSidKey__c= 'fr_FR_EURO';
        generateur.fsl_lastName__c= 'WU';
        generateur.fsl_languageLocaleKey__c= 'fr';   
        generateur.fsl_name__c= 'WU KEMAN';  
        generateur.fsl_SGID__c= 'T1234567';
        generateur.fsl_timeZoneSidKey__c= 'Europe/Paris';
        generateur.fsl_typePlanification__c= 'Ressource planifiable interne';   
        generateur.fsl_username__c= 'keman.wu@reprisekpark.fr.generateur.fslreprise'; 
        
        
        insert generateur;
        userRessourceList.add(generateur);
        TR001_fsl_GenerateurRessource.createUser(userRessourceList);
        
        /*User u =[select id,Email from User where matriculeGC__c = '123456'];        
        system.assertEquals('keman.wu@reprisekpark.fr',u.Email,'Problème de génération de user');
        
        
        Integer nbPermissionSet = [select count() from PermissionSetAssignment where AssigneeId =:u.id ]; 
        system.assertEquals(4,nbPermissionSet,'Problème de génération de PermissionSet');
        
        Integer nbPermissionSetLicense = [select count() from PermissionSetLicenseAssign where AssigneeId =:u.id ]; 
        system.assertEquals(2,nbPermissionSetLicense,'Problème de génération de PermissionSetLicense');*/
        test.stopTest();
        
    }
    
    
    @istest public static void testGenerationRessource() {  
        test.startTest();             
        TR002_fsl_GenerateurRessource.doChainJob = false;
        TR003_fsl_GenerateurRessource.doChainJob = false;
        
        Map<String, fsl_tech_generateurRessource__c> generatorMap = new  Map<String, fsl_tech_generateurRessource__c>();
        List<fsl_tech_generateurRessource__c> userRessourceList  = new List<fsl_tech_generateurRessource__c>();
        fsl_tech_generateurRessource__c generateur = new fsl_tech_generateurRessource__c();
        generateur.fsl_defaultGroupNotificationFrequency__c= 'N';  
        generateur.fsl_alias__c= 'kwu';
        generateur.fsl_communityNickname__c= 'kemanwu';
        generateur.fsl_contentEmailAsAndWhen__c= 'TRUE';
        generateur.fsl_contentNoEmail__c= 'TRUE';
        generateur.fsl_dateEntree__c= '01/10/2017';
        generateur.fsl_dateEntreeDepot__c= '01/10/2017'; 
        generateur.fsl_depotCodeGC__c= 'DEP';
        generateur.fsl_digestFrequency__c= 'D';
        generateur.fsl_email__c= 'keman.wu@reprisekpark.fr';
        generateur.fsl_emailEncodingKey__c= 'iso-8859-1';
        generateur.fsl_firstName__c= 'KEMAN';    
        generateur.fsl_metier__c= 'SVC0010';    
        generateur.fsl_matriculeGC__c= '123456';
        generateur.fsl_localeSidKey__c= 'fr_FR_EURO';
        generateur.fsl_lastName__c= 'WU';
        generateur.fsl_languageLocaleKey__c= 'fr';   
        generateur.fsl_name__c= 'WU KEMAN';  
        generateur.fsl_SGID__c= 'T1234567';
        generateur.fsl_timeZoneSidKey__c= 'Europe/Paris';
        generateur.fsl_typePlanification__c= 'Ressource planifiable interne';   
        generateur.fsl_username__c= 'keman.wu@reprisekpark.fr.generateur.fslreprise'; 
        generatorMap.put(generateur.fsl_matriculeGC__c, generateur);
        
        insert generateur;  
        userRessourceList.add(generateur);
        TR001_fsl_GenerateurRessource.createUser(userRessourceList);
        
        List<User> u =[select id,codeDepot__c,matriculeGC__c,typePlanification__c,FirstName,LastName,metier__c,sgid__c,isActive from User /*where matriculeGC__c = '123456'*/];        
        List<PermissionSetLicenseAssign>  permission = [select PermissionSetLicense.MasterLabel from PermissionSetLicenseAssign where AssigneeId =:u[0].id ];      
        
        TR003_fsl_GenerateurRessource third = new TR003_fsl_GenerateurRessource(u, generatorMap, new FieldServiceError());
        third.execute(null);
        
        
        //ServiceResource sr = [select fsl_SGID__c from ServiceResource where fsl_matriculeGC__c = '123456'];
        //system.assertEquals('T1234567',sr.fsl_SGID__c,'Problème de génération de ressource');
        test.stopTest();
        
    }
    
    @istest public static void testGenerationGroupMember() {
        test.startTest();       
        
        TR002_fsl_GenerateurRessource.doChainJob = false;
        TR003_fsl_GenerateurRessource.doChainJob = false;
        TR004_fsl_GenerateurRessource.doChainJob = false;
        
        Map<String, fsl_tech_generateurRessource__c> generatorMap = new  Map<String, fsl_tech_generateurRessource__c>(); 
        List<fsl_tech_generateurRessource__c> userRessourceList  = new List<fsl_tech_generateurRessource__c>();
        fsl_tech_generateurRessource__c generateur = new fsl_tech_generateurRessource__c();
        generateur.fsl_defaultGroupNotificationFrequency__c= 'N';  
        generateur.fsl_alias__c= 'kwu';
        generateur.fsl_communityNickname__c= 'kemanwu';
        generateur.fsl_contentEmailAsAndWhen__c= 'TRUE';
        generateur.fsl_contentNoEmail__c= 'TRUE';
        generateur.fsl_dateEntree__c= '01/10/2017';
        generateur.fsl_dateEntreeDepot__c= '01/10/2017'; 
        generateur.fsl_depotCodeGC__c= 'DEP';
        generateur.fsl_digestFrequency__c= 'D';
        generateur.fsl_email__c= 'keman.wu@reprisekpark.fr';
        generateur.fsl_emailEncodingKey__c= 'iso-8859-1';
        generateur.fsl_firstName__c= 'KEMAN';    
        generateur.fsl_metier__c= 'SVC0010';    
        generateur.fsl_matriculeGC__c= '123456';
        generateur.fsl_localeSidKey__c= 'fr_FR_EURO';
        generateur.fsl_lastName__c= 'WU';
        generateur.fsl_languageLocaleKey__c= 'fr';   
        generateur.fsl_name__c= 'WU KEMAN';  
        generateur.fsl_SGID__c= 'T1234567';
        generateur.fsl_timeZoneSidKey__c= 'Europe/Paris';
        generateur.fsl_typePlanification__c= 'Ressource planifiable interne';   
        generateur.fsl_username__c= 'keman.wu@reprisekpark.fr.generateur.fslreprise'; 
        generatorMap.put(generateur.fsl_matriculeGC__c, generateur);
        
        Map<String, ServiceTerritory> territoryMap = new Map <String,ServiceTerritory>();
        for (ServiceTerritory str : [select id, KparKReference__c from serviceTerritory Limit 1000]) {
            territoryMap.put(str.KparKReference__c, str );            
        }
        Map<String, ID> territoryGroupIdMap = new Map <String,ID>();
        for (ServiceTerritoryShare strSh : [select UserOrGroupId, Parent.KparKReference__c from ServiceTerritoryShare where RowCause = 'Manual' and Parent.KparKReference__c IN :territoryMap.keySet()  Limit 1000]) {
            territoryGroupIdMap.put(strSh.Parent.KparKReference__c, strSh.UserOrGroupId );            
        }
        
        insert generateur; 
        userRessourceList.add(generateur);
        TR001_fsl_GenerateurRessource.createUser(userRessourceList);
        
        List<User> u =[select id,codeDepot__c,matriculeGC__c,typePlanification__c,FirstName,LastName,metier__c,sgid__c,isActive from User/* where matriculeGC__c = '123456'*/];        
        List<GroupMember > grpMemberToCreateList = new  List<GroupMember >(); 
        
        if(territoryGroupIdMap.containsKey(u[0].codeDepot__c)){
            GroupMember grpMemberToCreate = new  GroupMember();
            grpMemberToCreate.groupId = territoryGroupIdMap.get(u[0].codeDepot__c);
            grpMemberToCreate.UserOrGroupId = u[0].id;
            grpMemberToCreateList.add(grpMemberToCreate);
        }
        
        List<FSL__User_Territory__c> userTerritoryToCreateList = new  List<FSL__User_Territory__c>(); 
        FSL__User_Territory__c  userTerritoryToCreate = new FSL__User_Territory__c ();  
        if (territoryMap.containsKey(u[0].codeDepot__c)){
            userTerritoryToCreate = new FSL__User_Territory__c();
            userTerritoryToCreate.FSL__ServiceTerritory__c = territoryMap.get(u[0].codeDepot__c).id;
            userTerritoryToCreate.FSL__User__c = u[0].ID;
            userTerritoryToCreateList.add(userTerritoryToCreate);
        }
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            TR004_fsl_GenerateurRessource fourth =  new TR004_fsl_GenerateurRessource(u, generatorMap,grpMemberToCreateList,new FieldServiceError(),userTerritoryToCreateList );
            fourth.execute(null);
        }  
        
        
        /*GroupMember gm = [select groupId from GroupMember where UserOrGroupId = :u[0].id];
        system.assertEquals(territoryGroupIdMap.get(u[0].codeDepot__c),gm.groupId,'Problème de génération de grope member');*/
        
        test.stopTest();
    }
    
    @istest public static void testGenerationUserTerritory() {
        test.startTest();       
        
        TR002_fsl_GenerateurRessource.doChainJob = false;
        TR003_fsl_GenerateurRessource.doChainJob = false;
        TR004_fsl_GenerateurRessource.doChainJob = false;
        
        Map<String, fsl_tech_generateurRessource__c> generatorMap = new  Map<String, fsl_tech_generateurRessource__c>(); 
        List<fsl_tech_generateurRessource__c> userRessourceList  = new List<fsl_tech_generateurRessource__c>();
        fsl_tech_generateurRessource__c generateur = new fsl_tech_generateurRessource__c();
        generateur.fsl_defaultGroupNotificationFrequency__c= 'N';  
        generateur.fsl_alias__c= 'kwu';
        generateur.fsl_communityNickname__c= 'kemanwu';
        generateur.fsl_contentEmailAsAndWhen__c= 'TRUE';
        generateur.fsl_contentNoEmail__c= 'TRUE';
        generateur.fsl_dateEntree__c= '01/10/2017';
        generateur.fsl_dateEntreeDepot__c= '01/10/2017'; 
        generateur.fsl_depotCodeGC__c= 'DEP';
        generateur.fsl_digestFrequency__c= 'D';
        generateur.fsl_email__c= 'keman.wu@reprisekpark.fr';
        generateur.fsl_emailEncodingKey__c= 'iso-8859-1';
        generateur.fsl_firstName__c= 'KEMAN';    
        generateur.fsl_metier__c= 'SVC0010';    
        generateur.fsl_matriculeGC__c= '123456';
        generateur.fsl_localeSidKey__c= 'fr_FR_EURO';
        generateur.fsl_lastName__c= 'WU';
        generateur.fsl_languageLocaleKey__c= 'fr';   
        generateur.fsl_name__c= 'WU KEMAN';  
        generateur.fsl_SGID__c= 'T1234567';
        generateur.fsl_timeZoneSidKey__c= 'Europe/Paris';
        generateur.fsl_typePlanification__c= 'Ressource planifiable interne';   
        generateur.fsl_username__c= 'keman.wu@reprisekpark.fr.generateur.fslreprise'; 
        generatorMap.put(generateur.fsl_matriculeGC__c, generateur);
        
        Map<String, ServiceTerritory> territoryMap = new Map <String,ServiceTerritory>();
        for (ServiceTerritory str : [select id, KparKReference__c  from serviceTerritory Limit 1000]) {
            territoryMap.put(str.KparKReference__c, str );            
        }
        Map<String, ID> territoryGroupIdMap = new Map <String,ID>();
        for (ServiceTerritoryShare strSh : [select UserOrGroupId, Parent.KparKReference__c from ServiceTerritoryShare where RowCause = 'Manual' and Parent.KparKReference__c IN :territoryMap.keySet()  Limit 1000]) {
            territoryGroupIdMap.put(strSh.Parent.KparKReference__c, strSh.UserOrGroupId );            
        }
        
        insert generateur; 
        userRessourceList.add(generateur);
        TR001_fsl_GenerateurRessource.createUser(userRessourceList);
        
        List<User> u =[select id,codeDepot__c,matriculeGC__c,typePlanification__c,FirstName,LastName,metier__c,sgid__c,isActive from User/* where matriculeGC__c = '123456'*/];        
        
        List<FSL__User_Territory__c> userTerritoryToCreateList = new  List<FSL__User_Territory__c>(); 
        FSL__User_Territory__c  userTerritoryToCreate = new FSL__User_Territory__c ();  
        if (territoryMap.containsKey(u[0].codeDepot__c)){
            userTerritoryToCreate = new FSL__User_Territory__c();
            userTerritoryToCreate.FSL__ServiceTerritory__c = territoryMap.get(u[0].codeDepot__c).id;
            userTerritoryToCreate.FSL__User__c = u[0].ID;
            userTerritoryToCreateList.add(userTerritoryToCreate);
        }
        
        TR005_fsl_GenerateurRessource fifth = new TR005_fsl_GenerateurRessource(u, generatorMap, new FieldServiceError(),userTerritoryToCreateList);
        fifth.execute(null);
        
        /*FSL__User_Territory__c ut = [select FSL__ServiceTerritory__c from FSL__User_Territory__c where FSL__User__c = :u[0].id];
        system.assertEquals(territoryMap.get(u[0].codeDepot__c).id,ut.FSL__ServiceTerritory__c,'Problème de génération user territory');
        
        fsl_tech_generateurRessource__c gr = [select fsl_insertUserTerritoryID__c,fsl_insertGroupMemberID__c,fsl_upsertServiceResourceID__c from fsl_tech_generateurRessource__c where fsl_matriculeGC__c= '123456'];
        system.assertNotEquals(null,gr.fsl_insertUserTerritoryID__c,'Problème de mise à jour générateur');  */ 
        test.stopTest();    
        
    }
}