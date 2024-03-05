//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_GeoUtils
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 12/05/2021
//-- Version     : 1.1
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_GeoUtils {
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('dqe.geocoder.enabled', true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);

        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('MAG123', 'Magasin 123', 'DEP123', 'Depot 123', true); 

        // Création entite
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, false);
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, false);
        List<Referencial__c> refList = new List<Referencial__c>();
        refList.add(refMag);
        refList.add(refDep);
        insert refList;
        Account accMag = Utils_Test.createEntity('Magasin 123', 'MAG123', Date.today(), '0123456789', refMag.Id, false);   
        Account accDep = Utils_Test.createEntity('Depot 123', 'DEP123', Date.today(), '0123456789', refDep.Id, false); 
        List<Account> accList = new List<Account>();
        accList.add(accMag);
        accList.add(accDep);
        insert accList;  
    }

    @isTest 
    static void testCalculAccount() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',false);
            acc.PersonMailingStreet = 'Test';
            acc.PersonMailingPostalCode = '13100';
            acc.PersonMailingCity = 'AIX';
            insert acc;
            
            // Exécution du test
            Test.startTest();

            GeoUtils.updateAccounts(new List<Account>{acc});

            Test.stopTest();
        }
    }

    @isTest 
    static void testCalculChantier() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, false);   
            chantier.rue__c = 'Test';
            chantier.codePostal__c = '13100';
            chantier.ville__c = 'AIX';
            insert chantier;
            
            // Exécution du test
            Test.startTest();

            GeoUtils.updateChantiers(new List<Chantier__c>{chantier});

            Test.stopTest();
        }
    }

    @isTest 
    static void testCalculEntityVersion() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            EntityVersion__c entV = [SELECT Id, street__c, postalCode__c, city__c, country__c, geolocalisation__Latitude__s, geolocalisation__Longitude__s 
										FROM EntityVersion__c LIMIT 1];
			entV.street__c = 'Test';
            entV.postalCode__c = '13100';
            entV.city__c = 'AIX';
            update entV;
            
            // Exécution du test
            Test.startTest();

            GeoUtils.updateEntityVersions(new List<EntityVersion__c>{entV});

            Test.stopTest();
        }
    }

    @isTest 
    static void testCalculUser() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.rue__c = 'Test';
        user.codePostal__c = '13100';
        user.ville__c = 'AIX';
        update user;

        System.runAs(user){
            
            // Exécution du test
            Test.startTest();

            GeoUtils.updateUsers(new List<User>{user});

            Test.stopTest();
        }
    }

    @isTest 
    static void testCalculEventDQE() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            PropertiesUtils.setBooleanValue('dqe.geocoder.enabled', true);
            PropertiesUtils.setBooleanValue('google.geocoder.enabled', false);

            Sectorisation__c sect = [SELECT Id FROM Sectorisation__c LIMIT 1];

            // Création enregistrement
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',false);
            acc.sectorisation__c = sect.Id;
            insert acc;
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, false);   
            chantier.sectorisation__c = sect.Id;
            insert chantier;
            
            // Exécution du test
            Test.startTest();

            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
            Event event0 = Utils_Test.createEvent(Constants.EVENT_TYPE_R0 ,rtRDV,projet.id,acc.PersonContactId, user.Id, Constants.StatutEventAReaffecter, false);
            event0.rue__c = 'Test';
            event0.codePostal__c = '13100';
            event0.ville__c = 'AIX';
            insert event0;

            GeoUtils.updateEvents(new List<Event>{event0});

            Test.stopTest();
        }
    }
    
    @isTest 
    static void testCalculEventGoogle() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            PropertiesUtils.setBooleanValue('dqe.geocoder.enabled', false);
            PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);

            Sectorisation__c sect = [SELECT Id FROM Sectorisation__c LIMIT 1];

            // Création enregistrement
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',false);
            acc.sectorisation__c = sect.Id;
            insert acc;
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, false);   
            chantier.sectorisation__c = sect.Id;
            insert chantier;
            
            // Exécution du test
            Test.startTest();

            Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
            Event event0 = Utils_Test.createEvent(Constants.EVENT_TYPE_R0 ,rtRDV,projet.id,acc.PersonContactId, user.Id, Constants.StatutEventAReaffecter, false);
            event0.rue__c = 'Test';
            event0.codePostal__c = '13100';
            event0.ville__c = 'AIX';
            insert event0;

            GeoUtils.updateEvents(new List<Event>{event0});

            Test.stopTest();
        }
    }
    
    @isTest 
    static void testGeolocationImportRecord() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        Utils_Test.createUser(true,'IU', 'INTERFACE@test.sfd.test', 'Interface API','', null, null);

        System.runAs(user){

            // Création enregistrement
            Id rtImport = DAL.getRecordTypeIdByDevName('Import__c', Constants.RT_IMPORT_EXTERNE);
            Import__c imp = Utils_Test.createImport(rtImport, 'Test', 'Test', 'Test', 'AIX', 'AIX', '0123456789', 'test@test.fr', '', Date.today(), false);
            
            // Exécution du test
            Test.startTest();

            GeoUtils.geolocationImportRecord(imp);    

            Test.stopTest();
        }
    }
}