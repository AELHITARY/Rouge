/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-18          Class created.

*/
@IsTest
public class Test_FSL_FigerRDV_DateType {
    
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
    }
    

    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void testDisplayPage()
    {
        
        Date today = Date.today();
        String dateDebFin = String.valueOf(today);
        
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_FDR_DateType;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        ApexPages.currentPage().getParameters().put('start', dateDebFin);
        ApexPages.currentPage().getParameters().put('end', dateDebFin);
        
        //Instanciation de la classe        
        CTRL_FSL_FigerRDV_DateType  cffd = new CTRL_FSL_FigerRDV_DateType();

        Test.startTest();       
     
        cffd.createTypeResourceCustom();
        cffd.displayPage();
        
        Test.stopTest();
       
        System.assertNotEquals(null, cffd.displayPage());
    }    
}