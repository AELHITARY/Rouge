/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-17          Class created.

*/
@IsTest
public class Test_FSL_AbsRec_Recap {
    
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
        
        String days = '(L';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='none';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta1';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Férié', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam2()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 7, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'M';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='null';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta2';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Présence dépôt', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam3()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 8, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'Me';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='ts';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta3';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Rendez-vous société', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam4()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 8, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'J';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tss';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta4';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Indisponibilité poseur', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam5()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 8, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'V';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tsss';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta5';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Réunion', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam6()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 8, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'S)';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta6';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Formation', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam7()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 8, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'S)';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta7';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Enregistrement contrat', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam8()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 8, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'S)';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta8';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('RTT', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam9()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 7, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = '';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta9';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Autre', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPageParam10()
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
        Date startDate = Date.newInstance(2019, 7, 2);
        Date endDate = Date.newInstance(2019, 7, 2);
        Time hdeb = Time.newInstance(8, 0, 0, 0);
        Time hfin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hdeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = '';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta10';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        String tres = 'METREUR';
        ApexPages.currentPage().getParameters().put('tres', String.valueOf(tres));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_Recap cfat = new CTRL_FSL_AbsRec_Recap();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        cfat.confirmerCreate();
        Test.stopTest();
       
        System.assertEquals('Saisie de commandes', tabsURL);
        System.assertNotEquals(null, cfat.confirmerCreate());
    } 

}