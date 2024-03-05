//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_CaseAction
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 21/11/2020
//-- Version     : 1.1
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_CaseAction {    
    private static final String RT_RECLAMATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
    private static final String RT_RELATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RELATIONCLIENT_RT);
    private static final String RT_AUTREID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_AUTRE_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    // Récupération Role
    private static final UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
    private static final UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];

    // Méthode de configuration des enregistrements pour les tests 
    // Méthode standard exécutée avant les tests                   
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
        PropertiesUtils.setStringValue('case.emailtemplate.commentPublique', 'Requete_Creation_commentaire_public');

        // Création Sectorisation
        String magCode = roleMag.Name.substring(0,7);
        Sectorisation__c sect = Utils_Test.createSectorisation(magCode, 'Magasin Test', 'DEP123', 'Depot 123', false);
        //sect.emailResponsableDepot__c = 'testdepot@test.fr';
        //sect.emailDepot__c = 'testdepot@test.fr';
        sect.libelleDepot__c = 'TEST DEPOT';
        insert sect;

        // Création entite
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account magasinA = Utils_Test.createEntity('Depot 123', 'DEP123', Date.today(), '0123456789', refMag.Id, true);

        // Récupération Cartographie
        Cartographie__c carto = Utils_Test.createCartographie('Test Carto','KPK-Vente', true);
                
        // Récupération des types d'enregistrement
        Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        
        // Création des comptes
        Account account = Utils_Test.createAccount('Test', 'test', 'test@salesforce.com', rtB2C, 'FAX', true);
        Account accountDepot = Utils_Test.createAccount('TEST DEPOT', 'TEST DEPOT', 'testdepot@salesforce.com', rtB2C, Constants.ACCOUNT_TYPE_DEPOT, 'FAX', true);

        // Création d'un chantier        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, false);
        chantier.codeMagasinTechnique__c = magCode; // Mise à jour localisation
        chantier.sectorisation__c = sect.Id;
        insert chantier;    
    }

    @isTest 
    static void testAffectationProximiteVendeurChantier() {
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        system.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account WHERE email__c = 'test@salesforce.com' LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            Test.startTest();
            
            // Création requête Réclamation
            Utils_Test.createCase(RT_RECLAMATIONID, acc, cha.Id, Constants.REQUETE_RECLAMATION_COMMERCIALE , '', '', true);
            
            // TEST - Affectation des autorisations
            Case newCase = [SELECT Id, EntitlementId FROM Case LIMIT 1];
            
            ApexPages.StandardController stdController = new ApexPages.standardController(newCase);
            Ctrl_CaseActions ctrlCaseActions = new Ctrl_CaseActions(stdController);
            ctrlCaseActions.affectationProximiteVendeur();
            
            Test.stopTest();
        }
    }   

    @isTest 
    static void testAffectationProximiteVendeurAccount() {
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        system.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account WHERE email__c = 'test@salesforce.com' LIMIT 1];
                        
            Test.startTest();
            
            // Création requête Réclamation
            Utils_Test.createCase(RT_RECLAMATIONID, acc, null, Constants.REQUETE_RECLAMATION_COMMERCIALE , '', '', true);
            
            // TEST - Affectation des autorisations
            Case newCase = [SELECT Id, EntitlementId FROM Case LIMIT 1];
            
            ApexPages.StandardController stdController = new ApexPages.standardController(newCase);
            Ctrl_CaseActions ctrlCaseActions = new Ctrl_CaseActions(stdController);
            ctrlCaseActions.affectationProximiteVendeur();
            
            Test.stopTest();
        }
    }

    @isTest 
    static void testAffectationDernierVendeur() {
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        system.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId, AccountSource, accountCallSource__c FROM Account WHERE email__c = 'test@salesforce.com' LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            Opportunity opp = Utils_Test.createOpportunity(acc, cha,true);
                        
            Test.startTest();
            
            // Création requête Réclamation
            Utils_Test.createCase(RT_RECLAMATIONID, acc, cha.Id, Constants.REQUETE_RECLAMATION_COMMERCIALE , '', '', true);
            
            // TEST - Affectation des autorisations
            Case newCase = [SELECT Id, EntitlementId FROM Case LIMIT 1];
            
            ApexPages.StandardController stdController = new ApexPages.standardController(newCase);
            Ctrl_CaseActions ctrlCaseActions = new Ctrl_CaseActions(stdController);
            ctrlCaseActions.affectationDernierVendeur();
            
            Test.stopTest();
        }
    }

    @isTest 
    static void test_case() {
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        system.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account WHERE email__c = 'test@salesforce.com' LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            Test.startTest();
            
            // Création requête Réclamation
            Utils_Test.createCase(RT_RECLAMATIONID, acc, cha.Id, Constants.REQUETE_RECLAMATION_COMMERCIALE , '', '', true);
            
            // TEST - Affectation des autorisations
            Case newCase = [SELECT Id, EntitlementId FROM Case LIMIT 1];
            
            ApexPages.StandardController stdController = new ApexPages.standardController(newCase);
            Ctrl_CaseActions ctrlCaseActions = new Ctrl_CaseActions(stdController);
            
            ctrlCaseActions.associationDernierChantier();
            ctrlCaseActions.associationChantierDuCompte();
            ctrlCaseActions.affectationProximiteVendeur();
            ctrlCaseActions.affectationManager();
            ctrlCaseActions.renvoyerNotificationReseau();
            
            Test.stopTest();
        }
    }
}