/*
History 
-------
Ver.    Author          Date                Detail
1.0     DPHA            2019-06-18          Class created.

*/
@IsTest
public class Test_FSL_AbsRec_TerritoryDate {
    
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
    
    
    //Méthode pour vérifier la création de ServiceTerritory 
    //+ Affichage de la page se déroule bien    
    public static testmethod void testDisplayTerritoryAdmin()
    { 
        //Création d'un user admin
        
        String uniqueUserName = 'adminPlan' + DateTime.now().getTime() + '@testorg.com';
        
        User userToRun = new User(
            Alias = 'adminP', 
            Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', 
            LastName='Planificateur', 
            LanguageLocaleKey='fr',
            LocaleSidKey='fr_FR', 
            ProfileId = '00eD0000001iahAIAQ',
            TimeZoneSidKey='Europe/Paris',
            UserName= uniqueUserName );
        insert userToRun;
        
        //Création du groupe
        Group g = new Group(
            Name = 'Depot'
        );
        insert g;
        
        //Création du membre du groupe
        GroupMember gm = new GroupMember(
            UserorGroupId= userToRun.id,
            GroupId = g.id
        );
        insert gm;
        
        //Instanciation de la classe
        CTRL_FSL_AbsRec_TerritoryDate cfft = new CTRL_FSL_AbsRec_TerritoryDate();
        //Instanciation des territoires custom pour simuler le comportement à l'ouverture de la page
        CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom stc1 = new CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom('DS');
        CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom stc2 = new CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom('Depot');
        
        //Lancement du test en tant qu'utilisateur crée
        System.runAs(userToRun){
            Test.startTest();
            cfft.createListTerritory();
            cfft.displayParam();
            Test.stopTest(); 
        }
        
        System.assertEquals(1, cfft.getTerritory().size());
        System.assertNotEquals(null, cfft.getTerritory().size());
        System.assertNotEquals(null, cfft.displayParam());
        System.assertEquals(false, stc2.isSelectedTerritory);
        
    }
    
    //Méthode pour vérifier la création de ServiceTerritory 
    //+ Affichage de la page se déroule bien    
    public static testmethod void testDisplayTerritory()
    { 
        //Création d'un user admin
        
        String uniqueUserName = 'adminPlan' + DateTime.now().getTime() + '@testorg.com';
        
        
        
        User userToRun = new User(
            Alias = 'adminP', 
            Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', 
            LastName='Planificateur', 
            LanguageLocaleKey='fr',
            LocaleSidKey='fr_FR', 
            ProfileId = '00e57000001oSqO',
            TimeZoneSidKey='Europe/Paris',
            UserName= uniqueUserName );
        insert userToRun;
        
        //Création du groupe
        Group g = new Group(
            Name = 'Depot'
        );
        insert g;
        
        //Création du membre du groupe
        GroupMember gm = new GroupMember(
            UserorGroupId= userToRun.id,
            GroupId = g.id
        );
        insert gm;
        
        //Instanciation de la classe
        CTRL_FSL_AbsRec_TerritoryDate cfft = new CTRL_FSL_AbsRec_TerritoryDate();
        //Instanciation des territoires custom pour simuler le comportement à l'ouverture de la page
        CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom stc1 = new CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom('DS');
        CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom stc2 = new CTRL_FSL_AbsRec_TerritoryDate.ServiceTerritoryCustom('Depot');
        
        //Lancement du test en tant qu'utilisateur crée
        System.runAs(userToRun){
            Test.startTest();
            cfft.createListTerritory();
            cfft.displayParam();
            Test.stopTest(); 
        }
        
        System.assertEquals(1, cfft.getTerritory().size());
        System.assertNotEquals(null, cfft.getTerritory().size());
        System.assertNotEquals(null, cfft.displayParam());
        System.assertEquals(false, stc2.isSelectedTerritory);
        
    }
}