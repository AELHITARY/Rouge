/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-07-16          Class created.

*/
@IsTest
public class Test_FSL_AbsRec_TypeRes {

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
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 2);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'M';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='ts';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta3';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();       
        cfat.displayPage();
        String freqURL = cfat.frequenceSelected;
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Toutes les semaines', freqURL);
        System.assertEquals('Rendez-vous société', tabsURL);
        System.assertNotEquals(null, cfat.displayPage());
    } 
    
    //Horaires  
    public  static testmethod void getHoraires()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 2);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = '(L';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tss';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta1';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();       
        Date debut = cfat.debutPlanning;
        Date fin = cfat.finPlanning;
        String heureDeb = cfat.heureDebut;
        String heureFin = cfat.heureFin;
        
        String freqURL = cfat.frequenceSelected;
        String tabsURL = cfat.typeAbsSelected;
        String sameDate = cfat.sameDate;
        Test.stopTest();
       
        System.assertEquals(Date.newInstance(2019, 7, 1), debut);
        System.assertEquals(Date.newInstance(2019, 7, 2), fin);
        System.assertEquals('08h00', heureDeb);
        System.assertEquals('12h00', heureFin);
        
        System.assertEquals('Toutes les deux semaines', freqURL);
        System.assertEquals('Férié', tabsURL);
        System.assertEquals('', sameDate);
    }
    
    //Same Date  
    public  static testmethod void sameDate()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'Me';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='none';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta2';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();       
        String freqURL = cfat.frequenceSelected;
        String tabsURL = cfat.typeAbsSelected;
        String sameDate = cfat.sameDate;
        Test.stopTest();
       
        
        System.assertEquals('Aucune', freqURL);
        System.assertEquals('Présence dépôt', tabsURL);
        System.assertEquals('hidden', sameDate);
    }
    
    //Paramétrage selon différentes option  
    public  static testmethod void param1()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'J';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tsss';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta4';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();       
        String freqURL = cfat.frequenceSelected;
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        
        System.assertEquals('Toutes les trois semaines', freqURL);
        System.assertEquals('Indisponibilité poseur', tabsURL);
    }
    
    //Paramétrage selon différentes option  
    public  static testmethod void param2()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'V';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta5';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();       
        String freqURL = cfat.frequenceSelected;
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        
        System.assertEquals('Toutes les quatre semaines', freqURL);
        System.assertEquals('Réunion', tabsURL);
    }
    
    //Paramétrage selon différentes option  
    public  static testmethod void param3()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'S)';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta6';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();       
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Formation', tabsURL);
    }
    
    //Paramétrage selon différentes option  
    public  static testmethod void param4()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'V';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta7';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Enregistrement contrat', tabsURL);
    }
    
    //Paramétrage selon différentes option  
    public  static testmethod void param5()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'V';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta8';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('RTT', tabsURL);
    }
    
    //Paramétrage selon différentes option  
    public  static testmethod void param6()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'V';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta9';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Autre', tabsURL);
    }
    
    //Paramétrage selon différentes option  
    public  static testmethod void param7()
    {
        //Paramétrage de l'URL 
        PageReference pageRef = Page.VF_FSL_AbsRec_TypeRes;
        Test.setCurrentPage(pageRef);
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1][0];
        ApexPages.currentPage().getParameters().put('listTer', st.id);
        
        Date startDate = Date.newInstance(2019, 7, 1);
        Date endDate = Date.newInstance(2019, 7, 1);
        Time hDeb = Time.newInstance(8, 0, 0, 0);
        Time hFin = Time.newInstance(12, 0, 0, 0);
        
        ApexPages.currentPage().getParameters().put('start', String.valueOf(startDate));
        ApexPages.currentPage().getParameters().put('end', String.valueOf(endDate));
        ApexPages.currentPage().getParameters().put('hdeb', String.valueOf(hDeb));
        ApexPages.currentPage().getParameters().put('hfin', String.valueOf(hfin));
        
        String comm = 'Réunion';
        ApexPages.currentPage().getParameters().put('comm', String.valueOf(comm));
        
        String days = 'V';
        ApexPages.currentPage().getParameters().put('days', String.valueOf(days));
        
        String freq ='tm';
        ApexPages.currentPage().getParameters().put('freq', String.valueOf(freq));
        
        String tabs = 'ta10';
        ApexPages.currentPage().getParameters().put('tabs', String.valueOf(tabs));
        
        //Instanciation de la classe        
        CTRL_FSL_AbsRec_TypeRes cfat = new CTRL_FSL_AbsRec_TypeRes();

        Test.startTest();
        String tabsURL = cfat.typeAbsSelected;
        Test.stopTest();
       
        System.assertEquals('Saisie de commandes', tabsURL);
    }
}