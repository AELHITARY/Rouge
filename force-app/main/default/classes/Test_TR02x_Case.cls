//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Case
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 08/02/2023
//-- Version     : 1.4
//-- * 1.4 : Réclamation siège, envoi email avec PJ
//-- * 1.3 - Test pour les NCP
//-- * 1.2 - KPKCRM_RQM-177 : Mise en place des nouveaux types d'enregistrement des comptes
//-- * 1.1 - Correction des tests
//-- * 1.0 - Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_Case {
    private static final String RT_RECLAMATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
    private static final String RT_RELATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RELATIONCLIENT_RT);
    private static final String RT_AUTREID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_AUTRE_RT);
    private static final String RT_PNC_INTERNALID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final String RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);
    private static final String RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final String RT_REQ_A_QUALIFIER = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_AQUALIFIER_RT);
    private static final Id ACC_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    
    
    // Méthode de configuration des enregistrements pour les tests 
    // Méthode standard exécutée avant les tests                   
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
        PropertiesUtils.setStringValue('case.emailtemplate.commentPublique', 'Requete_Creation_commentaire_public');
        // Création Sectorisation
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        Sectorisation__c sect = Utils_Test.createSectorisation(magCode, 'Magasin Test', 'DEP123', 'Depot 123', false);
        //sect.emailResponsableDepot__c = 'testdepot@test.fr';
        //sect.emailDepot__c = 'testdepot@test.fr';
        sect.libelleDepot__c = 'TEST DEPOT';
        insert sect;

        // Ref        
        Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, true);

        // Récupération Cartographie
        Cartographie__c carto = Utils_Test.createCartographie('Test Carto','KPK-Vente', true);
                
        // Récupération des types d'enregistrement
        Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        Id rtEntity = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        
        // Création des comptes et entite
        List<Account> accList = new List<Account>();
        Account account = Utils_Test.createAccount('Test', 'test', 'test@salesforce.com', rtB2C, 'FAX', false);
        Account ent = Utils_Test.createEntity('Depot 123', 'DEP123', Date.today(), '0123456789', refDep.Id, false);
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', ACC_PROVIDER_RTID, null , null, false);
        accList.add(account);
        accList.add(ent);
        accList.add(provider1);
        insert accList; 

        // Création d'un chantier        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, false);
        chantier.codeMagasinTechnique__c = 'MAG001Test'; // Mise à jour localisation
        chantier.sectorisation__c = sect.Id;
        insert chantier;    
        
        // Création projet
        Opportunity opp = Utils_Test.createOpportunity('Test', account, null, chantier, true);
        SBQQ__Quote__c CPQquote = Utils_Test.createCPQQuote(opp,Date.today(),1000,true);

        
        //SOQL LIMIT 101
        /*
        // Création d'un événement sur chantier
        account = [SELECT Id, PersonContactId FROM Account WHERE Id=:account.Id];
        Event evt = Utils_Test.createEvent(Constants.EVENT_TYPE_R1, rtRDV, opp.id, account.PersonContactId, null, Constants.StatutEventPris, 
                                            Date.today().addDays(1), System.now().addDays(1), System.now().addDays(1), '', true);           
        // Création des autorisations 
        List<Entitlement> newEntList = new List<Entitlement>();
        Entitlement ent = new Entitlement(Name='Auto1', AccountId=account.Id, Type='Réclamation', StartDate=Date.today());
        newEntList.add(ent);
        Entitlement ent1 = new Entitlement(Name='Auto2', AccountId=account.Id, Type='Relation client', StartDate=Date.today());
        newEntList.add(ent1);
        insert newEntList;
        */
    }

    @isTest 
    static void autorisationReclamation() {
        // Récupération Role
        Test.startTest();
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            //Test.startTest();
            
            // Création requête Réclamation
            Utils_Test.createCase(RT_RECLAMATIONID, acc, cha.Id, Constants.REQUETE_RECLAMATION_COMMERCIALE , '', '', true);
            
            Test.stopTest();
        }
    }

    @isTest 
    static void autorisationRelationClient() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {                      
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            //Test.startTest();
            
            // Création requête Relation client
            Case caseTest = Utils_Test.createCase(RT_RELATIONID, acc, cha.Id, Constants.REQUETE_DEMANDE_INFO , Constants.REQUETE_RDV_COMMERCIAL, '', true);   

            Test.stopTest();
        }
    }

    @isTest 
    static void autorisationAutre() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {              
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            //Test.startTest();
            
            // Création requête Autre demande
            Utils_Test.createCase(RT_AUTREID,acc,cha.Id,true);
            
            Test.stopTest();
        }
    }

    @isTest 
    static void alimentationCompteChantier() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        userTestRV.ByPassTrigger__c = 'TR020_User;TR020_Account;TR020_Asset;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        userTestRV.ByPassValidationRule__c = true;
        update userTestRV;
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            
            // Test sans compte pour mise à jour du compte selon chantier
            Case caseTest1 = Utils_Test.createCase(RT_RECLAMATIONID,acc,cha.Id,false);
            caseTest1.AccountId = null;
            caseTest1.ContactId = null;
            insert caseTest1;

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            /*Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;
            
            Case caseTest4 = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest4.chantier__c = null;
            caseTest4.AssetId = newAsset1.Id;
            insert caseTest4;*/
            
            Test.stopTest();
        }
    }

    @isTest 
    static void alimentationCompteChantier2() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        userTestRV.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update userTestRV;
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = Utils_Test.createChantier('String name',null, null, null, null, null, acc.Id,0,true);
            
            Case caseTest3 = Utils_Test.createCase(RT_RECLAMATIONID,acc,cha.Id,false);
            caseTest3.AccountId = null;
            caseTest3.ContactId = null;
            insert caseTest3;
            Test.stopTest();
        }
    }

    @isTest 
    static void delete_case() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        userTestRV.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update userTestRV;
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            //Chantier__c cha = Utils_Test.createChantier('String name',null, null, null, null, null, acc.Id,0,true);      
            Case caseTest3 = Utils_Test.createCase(RT_RECLAMATIONID,acc,null,true);
            try{
                delete caseTest3;
            }
            catch(Exception e){

            }
            Test.stopTest();
        }
    }

    @isTest 
    static void caseComment() {
        Test.startTest();
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);
        User user2 = Utils_Test.createUser(true,'Test2', 'puse2r'+System.now().format('hhmmss')+'@testemail2.com', 'Test LastName2','Test FirstName2', null, null);
        
        System.RunAs(user) {                
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            //Test.startTest();
            
            // Création requête Relation client
            Case case1 = Utils_Test.createCase(RT_RELATIONID, acc, cha.Id, Constants.REQUETE_NOUVEAU_RDV, Constants.REQUETE_RDV_INSTALLATION, '', true);
            
            // Test création commentaire publique si date prévi
            case1.datePrevisionnelleResolution__c = Date.today().addDays(1);
            case1.typeResolution__c = 'Autre';
            update case1;

            // Passage du commentaire en publique
            List<CaseComment> caseComList = [SELECT Id, IsPublished FROM CaseComment];
            CaseComment caseComment = caseComList[0];
            caseComment.IsPublished = true;
            update caseComment;
            
            Test.stopTest();

            
        }
    }

    @isTest 
    static void defineManager() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {              
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            //Test.startTest();
            
            // Création requête Relation client
            Case case1 = Utils_Test.createCase(RT_RELATIONID, acc, cha.Id, Constants.REQUETE_NOUVEAU_RDV, Constants.REQUETE_RDV_INSTALLATION, '', true);

            // Test changement de propriétaire
            case1.OwnerId = userTestVendeur.Id;
            update case1;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void autreProcessus() {
        Test.startTest();
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);
        User user2 = Utils_Test.createUser(true,'Test2', 'puse2r'+System.now().format('hhmmss')+'@testemail2.com', 'Test LastName2','Test FirstName2', null, null);
        
        System.RunAs(user) {            
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
                        
            //Test.startTest();
            
            // Création requête Relation client
            Case case1 = Utils_Test.createCase(RT_PNC_PROVIDERID, acc, cha.Id, Constants.REQUETE_NOUVEAU_RDV, Constants.REQUETE_RDV_INSTALLATION, '', true);

            // Test changement statut 
            case1.datePremiereReponse__c = Date.today();
            update case1;

            // Test A cloturer avec erreur (pas de date 1er réponse)
            try{
                case1.datePremiereReponse__c = null;
                case1.aCloturer__c = true;
                update case1;
            } catch(Exception e) {}
            
            Test.stopTest();
        }
    }

    @isTest 
    static void email2CaseWithAccount() {
        Test.startTest();
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);
        
        System.RunAs(user) {            
            Account acc = [SELECT Id, PersonContactId, email__c FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            Case case1 = Utils_Test.createCase(RT_AUTREID,acc,cha.Id, '', '', '', 'E-mail', 'Test Email2Case', false);
            case1.chantier__c = null;
            insert case1;
                        
            //Test.startTest();
            
            // Création Email Message
            Utils_Test.createEmailMessage(true,
                acc.email__c,
                'cnil@kpark.fr',
                'Object',
                'Test',
                case1.Id);
            
            Test.stopTest();
        }
    }

    @isTest 
    static void email2CaseWithoutAccount() {
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);
        
        System.RunAs(user) {            
            Account acc = [SELECT Id, PersonContactId, email__c FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            Case case1 = Utils_Test.createCase(RT_AUTREID,acc,cha.Id, '', '', '', 'E-mail', 'Test Email2Case', false);
            case1.Origin = 'E-mail';
            case1.chantier__c = null;
            insert case1;
                        
            Test.startTest();
            
            // Création Email Message
            Utils_Test.createEmailMessage(true,
                'test@test.fr',
                'devis@kpark.fr',
                'Object',
                'Test',
                case1.Id);
            
            Test.stopTest();
        }
    }

    @isTest 
    static void statusUpdateRules() {
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);
        user.ByPassTrigger__c = 'TR020_User;TR020_Account;TR020_Asset;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        user.ByPassValidationRule__c = true;
        update user;
        
        System.RunAs(user) {            
            Account acc = [SELECT Id, PersonContactId, email__c FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            Case case1 = Utils_Test.createCase(RT_AUTREID,acc,cha.Id, '', '', '', 'E-mail', 'Test Email2Case', false);
            case1.Origin = 'E-mail';
            case1.chantier__c = null;
            insert case1;
                        
            Test.startTest();
            
            //Gestion des status : RT_AUTREID
            case1.datePremiereReponse__c=Date.today();
            update case1;

            case1.aCloturer__c=true;
            update case1;

            // Création Email Message
            Utils_Test.createEmailMessage(true,
            'test@test.fr',
            'devis@kpark.fr',
            'Object',
            'Test',
            case1.Id);

            //Gestion des status : RT_PNC_PROVIDERID
            case1.recordTypeId=RT_PNC_PROVIDERID;
            update case1;

            case1.provider__c=acc.Id;
            update case1;

            case1.transmissionDate__c=Date.today();
            update case1;

            case1.conciliationDate__c=Date.today();
            update case1;

            case1.invoicedDate__c=Date.today();
            //case1.invoicedAmount__c=1;
            update case1;

            case1.processingEndDate__c=Date.today();
            update case1;

            //Case case1 = Utils_Test.createCase(RT_AUTREID,acc,cha.Id, '', '', '', 'E-mail', 'Test Email2Case', false);
            
            
            Test.stopTest();
        }
    }
    
     @isTest 
    static void statusUpdateRules_PNCProvider() {
        
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        //User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        userTestRV.ByPassValidationRule__c = true;
        userTestRV.ByPassTrigger__c = 'TR020_User;TR020_Account;TR020_Asset;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update userTestRV;

        Test.startTest();
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            
            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;

            // Gestion des status
            Case caseTest5 = Utils_Test.createCase(RT_PNC_PROVIDERID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest5.chantier__c = null;
            caseTest5.AssetId = newAsset1.Id;
            insert caseTest5;
           
            // Création Email Message
            Utils_Test.createEmailMessage(true,
            'test@test.fr',
            'devis@kpark.fr',
            'Object',
            'Test',
            caseTest5.Id);
            
            caseTest5.provider__c=acc.Id;
            update caseTest5;

            caseTest5.transmissionDate__c=Date.today();
            update caseTest5;
            
            /*caseTest5.conciliationDate__c=Date.today();
            update caseTest5;
            
            caseTest5.invoicedDate__c=Date.today();
            //case1.invoicedAmount__c=1;
            update caseTest5;

            caseTest5.processingEndDate__c=Date.today();
            update caseTest5;*/
            
            Test.stopTest();
        }
    }
    
    @isTest 
    static void statusUpdateRules_PNCProvider2() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        //User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id); 
        userTestRV.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update userTestRV; 
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            
            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;

            // Gestion des status
            Case caseTest5 = Utils_Test.createCase(RT_PNC_PROVIDERID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest5.chantier__c = null;
            caseTest5.AssetId = newAsset1.Id;
            insert caseTest5;

            caseTest5.processingEndDate__c=Date.today();
            update caseTest5;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void statusUpdateRules_Reclamation() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        
        // Création utilisateurs RV et Vendeur
        //User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        userTestRV.ByPassTrigger__c = 'TR020_User;TR020_Account;TR020_Asset;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        userTestRV.ByPassValidationRule__c = true;
        update userTestRV;
        Test.startTest();
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Case caseTest3 = Utils_Test.createCase(RT_RECLAMATIONID,acc,cha.Id,false);
            caseTest3.AccountId = null;
            insert caseTest3;
           
            /*caseTest3.datePremiereReponse__c=Date.today();
            update caseTest3;*/

            caseTest3.Status=Constants.REQUETE_STATUS_CLOSED;
            update caseTest3;

            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal1() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        SBQQ__Quote__c CPQquote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset1.controlDate__c = System.today() - 60;
            newAsset1.installDate = System.today() - 10;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;
            
            Case caseTest1 = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest1.chantier__c = null;
            caseTest1.AssetId = newAsset1.Id;
            insert caseTest1;

            //Test changement Statut
            caseTest1.diagnosticDate__c = Date.today();

            update caseTest1;

            caseTest1.afterSalesServiceQuote__c = CPQquote.Id;
            update caseTest1;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal2() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset1.controlDate__c = System.today() - 60;
            newAsset1.installDate = System.today() - 10;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;
            
            Case caseTest2 = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest2.AssetId = newAsset1.Id;
            insert caseTest2;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal3() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset1.controlDate__c = System.today() - 60;
            newAsset1.installDate = System.today() - 10;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;
            
            Case caseTest3 = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest3.AssetId = newAsset1.Id;
            caseTest3.responsability__c = 'Client';            
            insert caseTest3;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal4() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset1.controlDate__c = System.today() - 60;
            newAsset1.installDate = System.today() - 10;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;
            
            Case caseTest4 = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest4.AssetId = newAsset1.Id;
            caseTest4.detectedWarranty__c = 'Garantie';
            insert caseTest4;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal5() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset1.controlDate__c = System.today() - 60;
            newAsset1.installDate = System.today() - 10;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;                        

            Case caseTest5 = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest5.AssetId = newAsset1.Id;
            caseTest5.detectedWarranty__c = 'Hors garantie';
            insert caseTest5;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal6() {
        
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        Test.startTest();
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PROVIDER_RTID LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP123' LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset1.controlDate__c = System.today() - 60;
            newAsset1.installDate = System.today() - 10;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;
            
            Case caseTest6 = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest6.AssetId = newAsset1.Id;
            caseTest6.responsability__c = 'Client';            
            insert caseTest6;

            Order customerOrder = Utils_Test.createCustomerOrder(acc.Id, cha.Id, null, null, false);
            insert customerOrder;
            Order providerOrder = Utils_Test.createProviderOrder(entDep.Id, customerOrder.Id, provider1.Id ,false);
            providerOrder.productNonCompliance__c = caseTest6.Id;
            providerOrder.responsability__c = 'Client';
            insert providerOrder;
            
            update caseTest6;

            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal2b() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset2.controlDate__c = System.today() - 60;
            newAsset2.installDate = System.today() - 45;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset2);
            insert astList;
                        
            Case caseTest2b = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest2b.AssetId = newAsset2.Id;
            insert caseTest2b;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal3b() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset2.controlDate__c = System.today() - 60;
            newAsset2.installDate = System.today() - 45;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset2);
            insert astList;
                        
            Case caseTest3b = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest3b.AssetId = newAsset2.Id;
            caseTest3b.responsability__c = 'Client';            
            insert caseTest3b;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal4b() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset2.controlDate__c = System.today() - 60;
            newAsset2.installDate = System.today() - 45;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset2);
            insert astList;

            Case caseTest4b = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest4b.AssetId = newAsset2.Id;
            caseTest4b.detectedWarranty__c = 'Garantie';
            insert caseTest4b;
            
            Test.stopTest();
        }
    }

    @isTest 
    static void assetPNCInternal5b() {
        Test.startTest();
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);  
        
        System.RunAs(userTestRV) {          
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];

            Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            prod.isConvertibleAsset__c=true;
            insert prod;

            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, cha.Id, acc.Id,false);
            newAsset2.controlDate__c = System.today() - 60;
            newAsset2.installDate = System.today() - 45;
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset2);
            insert astList;            

            Case caseTest5b = Utils_Test.createCase(RT_PNC_INTERNALID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
            caseTest5b.AssetId = newAsset2.Id;
            caseTest5b.detectedWarranty__c = 'Hors garantie';
            insert caseTest5b;
            
            Test.stopTest();
        }
    }
    
    @isTest 
    static void testSendEmailRecla() {
        Test.startTest();
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+System.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);
        
        System.RunAs(user) {   
            // création d'un fichier 
            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.VersionData = EncodingUtil.base64Decode('Ceci est un test');
            cv.Title = 'TestFile.pdf';
            cv.PathOnClient = 'testFile';
            insert cv;

            // Création du Case de test
            Account acc = [SELECT Id, PersonContactId, email__c FROM Account LIMIT 1];
            Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
            Case caseTest5 = Utils_Test.createCase(RT_REQ_A_QUALIFIER,acc,cha.Id, '', '', '', 'Courrier', 'Test sendEmailRecla', false);
            insert caseTest5;

            // Ajout du fichier
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
            cdl.LinkedEntityId = caseTest5.Id;
            cdl.ShareType = 'V';
            insert cdl;
                        
            // Enregistrement de la valeur par default pour faire marcher la fonction
            PropertiesUtils.setStringValue('case.emailtemplate.reclaSiege', 'Reclamationservice_siege_copie');

            //Modification du Case
            caseTest5.recordTypeId = RT_RECLAMATIONID;
            caseTest5.OwnerId = user.Id;
            update caseTest5;
            
            Test.stopTest();
        }
    }
}