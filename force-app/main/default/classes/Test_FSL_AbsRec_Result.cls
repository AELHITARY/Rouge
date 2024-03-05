/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-17          Class created.

*/
@IsTest
public class Test_FSL_AbsRec_Result {
    //Data Setup
    @testSetup
    public static void testSetup(){
        //Création horaires
        OperatingHours oh = new OperatingHours(
            //fsl_dateOuverture__c = Date.newInstance(2017, 1, 1),
            Name='K/K Semaine type standard' ,
            TimeZone='Europe/Paris' );
        insert oh;  
        
        //Création du dépot
        ServiceTerritory parentST = new ServiceTerritory(
            Name='DS',
            KparKReference__c='DS',
            OperatingHoursId=oh.Id,
            IsActive=true);           
        insert parentST; 

        
        //Création d'un territoire 
        ServiceTerritory st = new ServiceTerritory(
            ParentTerritoryId=parentST.id,
            Name='Depot',
            KparKReference__c='DEP',
            OperatingHoursId=oh.Id,
            IsActive=true);     
        insert st;
        
         
        //Creation des utilisateurs 
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
        insert listeUser;
        
        List<User> u = [SELECT Id FROM User];
        
        //Creation des ressources
        List<ServiceResource> listeSR =new List<ServiceResource> ();
        ServiceResource sr1= new ServiceResource(
            fsl_matriculeGC__c='RES01',
            fsl_SGID__c='SGID01',
            name='MetreurTest',
            ResourceType='T',
            RelatedRecordId=u[0].id,
            IsActive=true,
            IsCapacityBased=true);           
        listeSR.add(sr1);
        insert listeSR;
        
        List<ServiceResource> sr = [SELECT Id FROM ServiceResource];
        
        //Creation de membre de territoires
        List<ServiceTerritoryMember> listeSTM=new List<ServiceTerritoryMember> ();
        ServiceTerritoryMember stm1= new ServiceTerritoryMember(
            EffectiveStartDate=Date.newInstance(2017, 1, 1),
            ServiceResourceId=sr[0].id,
            ServiceTerritoryId=st.id,
            TerritoryType='P',
            OperatingHoursId=oh.Id,
            EffectiveEndDate = null);           
        listeSTM.add(stm1);
        insert listeSTM;
    }
        
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPage()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String tabs = 'ta1';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Férié', tabsURL);
    } 
    
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam2()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Création d'une absence
        ResourceAbsence ra= new ResourceAbsence(
            ResourceId = stm.ServiceResourceId,
            Start = DateTime.newInstance(2019, 7, 2, 8, 0, 0),
            End = DateTime.newInstance(2019, 7, 2, 12, 0, 0),
            Type = 'Présence dépôt'
        );   
        insert ra;
        
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String tabs = 'ta2';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Présence dépôt', tabsURL);
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam3()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String tabs = 'ta3';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Rendez-vous société', tabsURL);
    }
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam4()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String tabs = 'ta4';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Indisponibilité poseur', tabsURL);
    }
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam5()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String tabs = 'ta5';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Réunion', tabsURL);
    }
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam6()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String tabs = 'ta6';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Formation', tabsURL);
    }
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam7()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));

        String tabs = 'ta7';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Enregistrement contrat', tabsURL);
    }
    
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam8()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String tabs = 'ta8';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));

        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('RTT', tabsURL);
    }
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam9()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));

        String tabs = 'ta9';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Autre', tabsURL);
    }
    
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayParam10()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('lres', stm.ServiceResourceId);
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 3);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));

        String tabs = 'ta10';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        Integer nb = 1;
        ApexPages.currentPage().getParameters().put('nb', String.valueOf(nb));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Result cfat = new CTRL_FSL_AbsRec_Result();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Saisie de commandes', tabsURL);
    }
}