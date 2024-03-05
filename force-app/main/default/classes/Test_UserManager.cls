//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_UserManager
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/02/2023
//-- Version     : 1.4
//-- * 1.4 : Revue suite suppression de rôles
//-- * 1.3 : RQM-113 : Ajout des constantes pour les nouveaux rôles/profils
//-- * 1.2 : RQM-65 : Anonymisation des informations et ajout vérification des RDV de service
//-- * 1.1 : Ajout profil Espace Client
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_UserManager {

    @testSetup 
    static void setup() {
        PropertiesUtils.setBooleanValue('geoDQEEnabled', true);
    }

    @isTest 
    static void test() {
        UserManager usrManager = new userManager();

        Map<Id, User> activeUsers   = new Map<Id, User>([SELECT id FROM user WHERE isActive = true]);
        Map<Id, User> inactiveUsers = new Map<Id, User>([SELECT id FROM user WHERE isActive = false]);

        ID adminProfileId     = usrManager.getProfileId('Administrateur système');
        ID interfaceProfileId = usrManager.getProfileId('K/K - Interface');
        //ID DEProfileId        = usrManager.getProfileId('K/K - DE');
        //ID DAFProfileId       = usrManager.getProfileId('K/K - DAF');
        ID DCProfileId        = usrManager.getProfileId('K/K - DC');
        ID DVProfileId        = usrManager.getProfileId(Constants.PROFIL_DV);
        ID DRProfileId        = usrManager.getProfileId('K/K - DR');
        ID ConsultationProfileId = usrManager.getProfileId(Constants.PROFIL_KPK_CONSULTATION);
        ID chatterProfileId   = usrManager.getProfileId('Chatter Free User');
        ID chatterProfileModeratorId   = usrManager.getProfileId('Chatter Moderator User');
        ID qtsProfileId       = usrManager.getProfileId('Profil QTS');
        ID parrainageProfileId    = usrManager.getProfileId('Profil Parrainage');
        ID DddevisProfileId    = usrManager.getProfileId('Profil Demande de Devis');
        ID EspaceClientProfileId  = usrManager.getProfileId('Profil Espace clients K par K');
        ID TAEntrantProfileId        = usrManager.getProfileId('K/K - TA/Entrant');
        ID TASortantProfileId        = usrManager.getProfileId('K/K - TA/Sortant');
        ID superviseurProfileId        = usrManager.getProfileId('K/K - Superviseur');
        ID directeurCallProfileId        = usrManager.getProfileId('K/K - DC');

        Test.startTest();

        // Vérification de la liste des utilisateurs actifs
        List<User> usersT = usrManager.getUsers(true);

        // Vérification de la liste des utilisateurs intouchables
        List<User> usersF = usrManager.getUsers(false);
        Set<User> usersD = new Set<User>(usersT);
        usersD.removeAll(usersF);

        // Vérification des utilisateurs d'un profile/role donné
        List<User> users = usrManager.getUsers(adminProfileId, null);
        for (User user : users) {
            usrManager.isSupportUser(user);
            usrManager.isAdministrator(user);
        }
        Set<ID> roles = new Set<ID>();
        Set<ID> profiles = new Set<ID>();
        profiles.add(adminProfileId);
        profiles.add(interfaceProfileId);
        //profiles.add(DEProfileId);
        //profiles.add(DAFProfileId);
        profiles.add(DCProfileId);
        profiles.add(DVProfileId);
        profiles.add(DRProfileId);
        profiles.add(ConsultationProfileId);
        profiles.add(TAEntrantProfileId);
        profiles.add(TASortantProfileId);
        profiles.add(superviseurProfileId);
        profiles.add(directeurCallProfileId);

        users = usrManager.getUsers(profiles, null);
        users.addAll(usrManager.getUsers(null, roles));
        for (User user : users) {
            Boolean isCallSupervisor = usrManager.isCallSupervisor(user);
            Boolean isAdministrator = usrManager.isAdministrator(user);
            Boolean isCallUser = usrManager.isCallUser(user);
            Boolean isCallTA = usrManager.isCallTA(user);
            Boolean isDV = usrManager.isDV(user);
            Boolean isDR = usrManager.isDR(user);
            Boolean isDC = usrManager.isCallDirector(user);
            //Boolean isDAF = usrManager.isDAF(user);
            //Boolean isDE = usrManager.isDE(user);
            Boolean isKPKConsultation = usrManager.isKPKConsultation(user);
            Boolean isIntouchable = usrManager.isIntouchable(user);
            Boolean isInterface = usrManager.isInterface(user);
        }

        // Vérification des utilisateurs typés
        users = usrManager.getSupportUsers();
        for (User user : users) {
            System.assert(usrManager.isSupportUser(user));
        }
        List<String> emails = usrManager.getSupportEmails();
        System.assertEquals(users.size(), emails.size());

        users = usrManager.getSiegeUsers();
        for (User user : users) {
            System.assert(usrManager.isCallDirector(user));
        }
        emails = usrManager.getSiegeEmails();
        System.assertEquals(users.size(), emails.size());

        // Other TEST
        Id roleId = usrManager.getRoleId('MAG0050 - MAG - CAEN');
        usrManager.getUsersExcl(superviseurProfileId, roleId);

        Test.stopTest();
    }

    @isTest 
    static void userInactif() {  
        // Récupération profil
        String prfRVId = [Select Id FROM Profile WHERE Name = :Constants.PROFIL_RV].Id;
        // Création utilisateurs
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userTestRV = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfRVId, 'DR123', 'DV123', 'M123',true);

        System.runAs(user){      
            Test.startTest();

            // Désactivation
            PropertiesUtils.setBooleanValue('geoDQEEnabled', true);
            userTestRV.IsActive = false;
            update userTestRV;

            // Vérfication date de désactivation
            userTestRV = [SELECT Id, dateDesactivation__c FROM User WHERE Id = :userTestRV.Id LIMIT 1];
            System.assertNotEquals(null, userTestRV.dateDesactivation__c);

            Test.stopTest();   
        }   
    }

    @isTest 
    static void test_TR020_User() {  
        // Récupération profil et rôles
        String profileID    = [SELECT Id FROM Profile WHERE Name = :Constants.PROFIL_VENDEUR].Id;
        String roleID_AIX   = [SELECT Id FROM UserRole WHERE Name = 'MAG0025 - MAG - AIX EN PROVENCE'].Id;
        String roleID_PARIS = [SELECT Id FROM UserRole WHERE Name = 'MAG0057 - MAG - PARIS LA FAYETTE'].Id;

        // Création utilisateur
        User user = Utils_Test.createUser(false,'TR020Usr', 'TR020User@test.sfd.test', 'TR020LastName','TR020FirstName', null, null, true);                        

        Test.startTest();
        
        user.profileId = profileId;
        user.userRoleId = roleID_PARIS;
        user.rue__c = '148 RUE GALLIENI';
        user.codePostal__c = '92100';
        user.ville__c = 'BOULOGNE-BILLANCOURT';

        update user;


        // Forçage recalcul secto, manager, etc.
        user.codeDR__c         = 'AAA';
        user.codeDS__c         = 'AAA';
        user.codeDV__c         = 'AAA';
        user.codeDepot__c      = 'AAA';
        user.codeMagasin__c    = 'AAA';
        user.libelleDR__c      = 'AAA';
        user.libelleDS__c      = 'AAA';
        user.libelleDV__c      = 'AAA';
        user.libelleDepot__c   = 'AAA';
        user.libelleMagasin__c = 'AAA';

        update user;

        // Utilisateur inactif avec forçage secto
        user.isActive          = false;
        user.codeDR__c         = 'BBB';
        user.codeDS__c         = 'BBB';
        user.codeDV__c         = 'BBB';
        user.codeDepot__c      = 'BBB';
        user.codeMagasin__c    = 'BBB';
        user.libelleDR__c      = 'BBB';
        user.libelleDS__c      = 'BBB';
        user.libelleDV__c      = 'BBB';
        user.libelleDepot__c   = 'BBB';
        user.libelleMagasin__c = 'BBB';

        update user;

        // Utilisateur réactivé avec changement de rôle
        user.isActive          = true;
        user.userRoleId        = roleID_AIX;
        user.codeDR__c         = 'CCC';
        user.codeDS__c         = 'CCC';
        user.codeDV__c         = 'CCC';
        user.codeDepot__c      = 'CCC';
        user.codeMagasin__c    = 'CCC';
        user.libelleDR__c      = 'CCC';
        user.libelleDS__c      = 'CCC';
        user.libelleDV__c      = 'CCC';
        user.libelleDepot__c   = 'CCC';
        user.libelleMagasin__c = 'CCC';

        update user;



        Test.stopTest();   
    }

    @isTest 
    static void userAnonymisation() {  
        // Récupération profil
        String prfRVId = [Select Id FROM Profile WHERE Name = :Constants.PROFIL_RV].Id;
        // Création utilisateurs
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userTestRV = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfRVId, 'DR123', 'DV123', 'M123',true);

        System.runAs(user){     
            // Désactivation
            userTestRV.IsActive = false;
            update userTestRV;
 
            Test.startTest();

            // Anonymisation
            List<User> usrList = new List<User>();
            usrList.add(userTestRV);
            IV_ObfuscateUser.obfuscateUser(usrList);            
            System.enqueueJob(new QA_AsyncObfuscateUser(usrList, false, null, false));

            Test.stopTest();   
        }   
    }

    @isTest 
    static void userAnonymisationFSL() {  
        // Récupération profil
        String prfFSL = [Select Id from profile where Name LIKE '%Ressource%' LIMIT 1].Id;
        // Création utilisateurs
        User user = Utils_Test.createUser(false,'testmlg2', 'admin@test.sfd.test', 'ad','ad', null, null);
        User userTest1 = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfFSL, 'DR123', 'DV123', 'M123',true);
        User userTest2 = Utils_Test.createUser(true,'tes2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', prfFSL, 'DR123', 'DV123', 'M123',true);

        System.runAs(user){   
            List<User> usrList = new List<User>();
            usrList.add(userTest1);
            
            // Création données FSL pour User
            TestData_fsl_Setup.createServiceResource(new List<User>{userTest1, userTest2});
 
            Test.startTest();

            // Anonymisation            
            System.enqueueJob(new QA_AsyncObfuscateFSLDatas(usrList, null));

            Test.stopTest();   
        }   
    }

    @isTest 
    static void urlPublicationFacebook() {
        // récupération de l'Id d'un rôle
        //UserManager userManager = new userManager();
        //ID VendeurRoleId       = usrManager.getRoleId('MAG0050 - MAG - CAEN');
        UserRole uRole = new UserRole (Name = 'MAG_0000 - MAG - CAEN');
        insert uRole;
        //Map<Id, UserRole> roles = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole
                                                            //WHERE Name LIKE 'MAG%' OR Name LIKE 'DV%' OR Name LIKE 'RV%' OR Name = 'Marketing']);
        
        User userAdmin = Utils_Test.createAdminUser();
        System.RunAs(userAdmin) {
            Utils_Test.createSectorisation();
            PublicationFacebook__c PF = new PublicationFacebook__c();
            PF.codeDR__c = 'RV_0000';
            PF.codeDV__c = 'DV_0000';
            PF.codeMagasin__c = 'MAG_0000';
            PF.urls__c = 'www.test.com';
            insert PF;
        }

        Test.startTest();
        // Création d'un utilisateur
        User user = Utils_Test.createVendeurUser('DR_0000', 'DV_0000', 'MAG_0000', uRole.Id);
        Test.stopTest();
        
        User userVerif = new User();
        userVerif = [SELECT Id ,URLFacebook__c FROM User WHERE Id = :user.Id];
        System.assertEquals('www.test.com' , userVerif.URLFacebook__c);
    }

    @isTest 
    static void  urlPublicationFacebookDV() {
        // récupération de l'Id d'un rôle
        //UserManager userManager = new userManager();
        //ID VendeurRoleId       = usrManager.getRoleId('MAG0050 - MAG - CAEN');
        UserRole uRole = new UserRole (Name = 'DV_0000 - DV - OU');
        insert uRole;
        //Map<Id, UserRole> roles = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole
                                                            //WHERE Name LIKE 'MAG%' OR Name LIKE 'DV%' OR Name LIKE 'RV%' OR Name = 'Marketing']);
        
        User userAdmin = Utils_Test.createAdminUser();
        System.RunAs(userAdmin) {
            Utils_Test.createSectorisation();
            PublicationFacebook__c PF = new PublicationFacebook__c();
            PF.codeDR__c = 'RV_0000';
            PF.codeDV__c = 'DV_0000';
            PF.codeMagasin__c = 'MAG_0000';
            PF.urls__c = 'www.test.com';
            insert PF;
        }
        Test.startTest();
        // Création d'un utilisateur
        User user = Utils_Test.createVendeurUser('', '', 'MAG_0000', uRole.Id);
        Test.stopTest();
        
        User userVerif = new User();
        userVerif = [SELECT Id ,URLFacebook__c FROM User WHERE Id = :user.Id];
        System.assertEquals('www.test.com' , userVerif.URLFacebook__c);
    }

    @isTest 
    static void urlPublicationFacebookDR() {
        // récupération de l'Id d'un rôle
        //UserManager userManager = new userManager();
        //ID VendeurRoleId       = usrManager.getRoleId('MAG0050 - MAG - CAEN');
        UserRole uRole = new UserRole (Name = 'RV_0000 - RV - OU');
        insert uRole;
        //Map<Id, UserRole> roles = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole
                                                            //WHERE Name LIKE 'MAG%' OR Name LIKE 'DV%' OR Name LIKE 'RV%' OR Name = 'Marketing']);
        
        User userAdmin = Utils_Test.createAdminUser();
        System.RunAs(userAdmin) {
            Utils_Test.createSectorisation();
            PublicationFacebook__c PF = new PublicationFacebook__c();
            PF.codeDR__c = 'RV_0000';
            PF.codeDV__c = 'DV_0000';
            PF.codeMagasin__c = 'MAG_0000';
            PF.urls__c = 'www.test.com';
            insert PF;
        }
        Test.startTest();
        // Création d'un utilisateur
        User user = Utils_Test.createVendeurUser('', '', '', uRole.Id);
        Test.stopTest();
        
        User userVerif = new User();
        userVerif = [SELECT Id ,URLFacebook__c FROM User WHERE Id = :user.Id];
        System.assertEquals('www.test.com' , userVerif.URLFacebook__c);
    }
}