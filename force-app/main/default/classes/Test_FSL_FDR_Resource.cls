/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-13          Class created.

*/
@IsTest
public class Test_FSL_FDR_Resource {
    
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
        
        ServiceResource sr2= new ServiceResource(
            fsl_matriculeGC__c='RES02',
            fsl_SGID__c='SGID02',
            name='PoseurTest',
            ResourceType='T',
            RelatedRecordId=u[1].id,
            IsActive=true);           
        listeSR.add(sr2);
        insert listeSR;
        
        List<ServiceResource> sr = [SELECT Id FROM ServiceResource];
        
        //Creation de membre de territoires
        List<ServiceTerritoryMember> listeSTM=new List<ServiceTerritoryMember> ();
        ServiceTerritoryMember stm1= new ServiceTerritoryMember(
            EffectiveStartDate=Date.newInstance(2017, 1, 1),
            ServiceResourceId=sr[0].id,
            ServiceTerritoryId=st.id,
            TerritoryType='P',
            OperatingHoursId=oh.Id);           
        listeSTM.add(stm1);
        
        ServiceTerritoryMember stm2= new ServiceTerritoryMember(
            EffectiveStartDate=Date.newInstance(2017, 1, 1),
            ServiceResourceId=sr[1].id,
            ServiceTerritoryId=st.id,
            TerritoryType='P',
            OperatingHoursId=oh.Id);           
        listeSTM.add(stm2); 
        insert listeSTM;  
    }
    
    //Recup donnée + Affichage liste
    public static testmethod void testGetServiceResource()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        

        
        ServiceTerritoryMember stm = [SELECT Id,ServiceResourceId, ServiceTerritoryId, ServiceResource.IsActive FROM ServiceTerritoryMember LIMIT 1][0];
        
        ServiceResource srToUpdate = [SELECT Id, Name FROM ServiceResource WHERE Id = :stm.ServiceResourceId];
        srToUpdate.serviceTerritory__c = stm.ServiceTerritoryId;
        srToUpdate.IsActive = true;
        srToUpdate.job__c = 'METREUR';
        update srToUpdate;
        System.debug('SR TO UPDATE -----------' + srToUpdate);
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', stm.ServiceTerritoryId);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
        ApexPages.currentPage().getParameters().put('type', 'METREUR');
        
        //Instanciation de la classe        
        CTRL_FSL_FDR_Resource  cffr = new CTRL_FSL_FDR_Resource();

        Test.startTest();
     
        cffr.displayPage();
        
        Test.stopTest();
       
        System.assertNotEquals(null, cffr.displayPage());
    } 
    
    //Test récupération des données pour l'affichage de la liste des Service Resources
    public static testmethod void testDisplayPage()
    {
        //Paramétrage de l'URL 
        ServiceResource sr1 = [SELECT Id FROM ServiceResource LIMIT 1][0];
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        
        //Insertion de paramètre dans le lien
        PageReference pageRef = Page.VF_FSL_FDR_Resource;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
        ApexPages.currentPage().getParameters().put('type', 'METREUR');
        
        
        //Instanciation de la classe        
        CTRL_FSL_FDR_Resource  cffr = new CTRL_FSL_FDR_Resource();

        Test.startTest();
     
        cffr.displayPage();
        
        Test.stopTest();
       
        System.assertNotEquals(null, cffr.displayPage());
    } 
    
}