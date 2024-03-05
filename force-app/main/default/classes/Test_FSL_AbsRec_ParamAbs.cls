/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-16          Class created.

*/
@IsTest
public class Test_FSL_AbsRec_ParamAbs {
    
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
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_ParamAbs;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 2);
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_ParamAbs  cfap = new CTRL_FSL_AbsRec_ParamAbs();

        Test.startTest();       
        Integer diff = cfap.diffDebFin;
        cfap.displayPage();
        
        Test.stopTest();
       
        System.assertNotEquals(null, cfap.displayPage());
        System.assertEquals(1, diff);
    } 
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void sameDate()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_ParamAbs;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_ParamAbs  cfap = new CTRL_FSL_AbsRec_ParamAbs();

        Test.startTest();       
        Integer diff = cfap.diffDebFin;
        cfap.displayPage();
        
        Test.stopTest();
       
        System.assertEquals(0, diff);
    }  
    
    //Test récupération des données pour l'affichage de la page
    public static testmethod void getDate()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_ParamAbs;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_ParamAbs  cfap = new CTRL_FSL_AbsRec_ParamAbs();

        Test.startTest();       
        cfap.getDays();
        cfap.getlDays();
        cfap.setlDays(cfap.getlDays());
        Test.stopTest();
       
        System.assertEquals(6, cfap.getDays().size());
    } 

}