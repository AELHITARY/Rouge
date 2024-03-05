//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl002_GoogleMaps
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/03/2019
//-- Version     : 1.6
//-- *  Ajout des tests sur les RDV commerciaux
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl002_GoogleMaps {
    static Double longitude = 2.3354245000000446;
    static Double latitude = 48.8807489;
    private static final Id accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id rtActiviteProspe = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

        // Création Sectorisation
        // Code Magasin = MAG001Test
        // Libellé Magasin = MAG Test
        Sectorisation__c secto = Utils_Test.createSectorisation('MAG001Test', 'MAG Test', 'DEP001Test', 'DEP TEST',true);

        // Récupération Cartographie
        Cartographie__c carto = Utils_Test.createCartographie('Test Carto','KPK-Vente', true);

        // Création Attachement pour secteur
        Utils_Test.createAttachment('MAG001Test', carto.Id, Blob.valueOf('547031 2523701,547066 2523729,547331 2523900,547450 2523956,547080 2524237'));

        // Création Compte, Chantier
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        chantier.telephoneDomicileProprietaires__c = '0123456789';
        chantier.telephoneMobileProprietaires__c = '0123456789';
        chantier.autreTelephoneProprietaires__c = '0123456789';
        chantier.sectorisation__c = secto.Id;
        // Mise à jour localisation
        chantier.codeMagasinTechnique__c = 'MAG001Test';
        update chantier;

        // Création Contrats SAV, Pose et Metrage
        List<KContrat__c> contratToUpdate = new List<KContrat__c>();
        KContrat__c contratSAV = Utils_Test.createContrat('Contrat SAV', chantier.Id, acc.Id, '0001', false);
        contratSAV.libelleStatutContrat__c = 'Contrats en SAV';
        contratToUpdate.add(contratSAV);
        KContrat__c contratMetrage = Utils_Test.createContrat('Contrat Metrage', chantier.Id, acc.Id, '0002', false);
        contratMetrage.cartoMetrageDuJour__c = Date.today();
        contratToUpdate.add(contratMetrage);
        KContrat__c contratPose = Utils_Test.createContrat('Contrat Pose', chantier.Id, acc.Id, '0003', false);
        contratPose.cartoInstallationDuJour__c = Date.today();
        contratToUpdate.add(contratPose);
        KContrat__c contratIntSav = Utils_Test.createContrat('Contrat Int SAV', chantier.Id, acc.Id, '0004', false);
        contratIntSav.cartoInterventionSAVDuJour__c = Date.today();
        contratToUpdate.add(contratIntSav);
        insert contratToUpdate;
    }

    @isTest 
    static void test_GoogleMaps_User_Magasin_Set() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        // Création utilisateur
        User user = Utils_Test.createVendeurUser('MAG001Test', 'MAG001Test', 'MAG001Test', roleMag.Id); 
        user.localisationLatitude__c = latitude;
        user.localisationLongitude__c = longitude;
        update user;

        System.runAs(user) {
            system.debug('user.CodeMagasin__c : ' + user.CodeMagasin__c);

            // Exécution de la cartographie
            Test.startTest();
            PageReference vf002 = Page.VF002_GoogleMaps;
            Test.setCurrentPageReference (vf002);
            Ctrl002_GoogleMaps ctrl = new Ctrl002_GoogleMaps();
            String codeMag = ctrl.sectorcodeMagasin;
            Utils_Cartographie.Sector sec = ctrl.retSector;
            Ctrl002_GoogleMaps.getSectorCoord('MAG Test');
            Ctrl002_GoogleMaps.getChantierAvecContratsList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getChantierSansContratsList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getPoseDuJourList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getPoseDeDemainList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getSAVList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getMetrageDuJourList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getMetrageDeDemainList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getInterventionDuJourList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getInterventionDeDemainList('MAG001Test', 547031,547450,2524237,2523701);
            try {
                Ctrl002_GoogleMaps.getInterditDeProspectionList('MAG001Test', 547031,547450,2524237,2523701);
            } catch(Exception e) {}
            Ctrl002_GoogleMaps.getVendeursList('MAG001Test');
            ctrl.insertUserStats();
            ctrl.getTest();
            Test.stopTest();
        }
    }

    @isTest 
    static void test_GoogleMaps_User_Magasin_NotSet() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        // Création utilisateur
        Profile profil = [SELECT Id FROM Profile WHERE Name LIKE '%RV%' LIMIT 1];
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', profil.Id, roleMag.Id);       
        user.localisationLatitude__c = latitude;
        user.localisationLongitude__c = longitude;
        update user;
        
        System.runAs(user) {
            system.debug('user.CodeMagasin__c : ' + user.CodeMagasin__c);

            // Exécution de la cartographie
            Test.startTest();

            PageReference vf002 = Page.VF002_GoogleMaps;
            Test.setCurrentPageReference (vf002);
            Ctrl002_GoogleMaps ctrl = new Ctrl002_GoogleMaps();
            String codeMag = ctrl.sectorcodeMagasin;
            Utils_Cartographie.Sector sec = ctrl.retSector;
            Ctrl002_GoogleMaps.getSectorCoord('MAG Test');
            Ctrl002_GoogleMaps.getChantierAvecContratsList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getChantierSansContratsList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getPoseDuJourList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getPoseDeDemainList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getSAVList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getMetrageDuJourList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getMetrageDeDemainList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getInterventionDuJourList('MAG001Test', 547031,547450,2524237,2523701);
            Ctrl002_GoogleMaps.getInterventionDeDemainList('MAG001Test', 547031,547450,2524237,2523701);
            try {
                Ctrl002_GoogleMaps.getInterditDeProspectionList('MAG001Test', 547031,547450,2524237,2523701);
            } catch(Exception e) {}
            Ctrl002_GoogleMaps.getVendeursList('MAG001Test');
            ctrl.insertUserStats();

            Test.stopTest();
        }
    }

    @isTest 
    static void test_GoogleMaps_RDV1() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        // Création utilisateur
        User user = Utils_Test.createVendeurUser('MAG001Test', 'MAG001Test', 'MAG001Test', roleMag.Id);
        User usr = [SELECT Id, Profile.Name FROM User WHERE Id=:user.Id LIMIT 1];

        System.runAs(user) {
            system.debug('user.CodeMagasin__c : ' + user.CodeMagasin__c);

            // Enregistrements utile
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account LIMIT 1];
            Chantier__c chantier = [SELECT Id, Name FROM Chantier__c LIMIT 1];
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            // RDV R1
            Test.startTest();
            Event eventR1 = Utils_Test.createEvent('R1', rtActiviteCommerciale, projet1.Id, contact.Id, user.Id,null,true);
            
            // Exécution de la cartographie
            PageReference vf002 = Page.VF002_GoogleMaps;
            Test.setCurrentPageReference (vf002);
            Ctrl002_GoogleMaps ctrl = new Ctrl002_GoogleMaps();
            String codeMag = ctrl.sectorcodeMagasin;
            Utils_Cartographie.Sector sec = ctrl.retSector;
            Ctrl002_GoogleMaps.getSectorCoord('MAG Test');
            Ctrl002_GoogleMaps.getRDVDuJourList('MAG001Test', 547031,547450,2524237,2523701, 'R1', usr.Id, usr.Profile.Name);
            Ctrl002_GoogleMaps.getRDVProchainList('MAG001Test', 547031,547450,2524237,2523701, 'R1', usr.Id, usr.Profile.Name);

            Test.stopTest();
        }
    }

    @isTest 
    static void test_GoogleMaps_RDV2() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        // Création utilisateur
        User user = Utils_Test.createVendeurUser('MAG001Test', 'MAG001Test', 'MAG001Test', roleMag.Id);
        User usr = [SELECT Id, Profile.Name FROM User WHERE Id=:user.Id LIMIT 1];

        System.runAs(user) {
            system.debug('user.CodeMagasin__c : ' + user.CodeMagasin__c);

            // Enregistrements utile
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account LIMIT 1];
            Chantier__c chantier = [SELECT Id, Name FROM Chantier__c LIMIT 1];
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            // RDV R2
            Test.startTest();
            Event eventR2 = Utils_Test.createEvent('R2', rtActiviteCommerciale, projet1.Id, contact.Id, user.Id,null,true);
            
            // Exécution de la cartographie
            PageReference vf002 = Page.VF002_GoogleMaps;
            Test.setCurrentPageReference (vf002);
            Ctrl002_GoogleMaps ctrl = new Ctrl002_GoogleMaps();
            String codeMag = ctrl.sectorcodeMagasin;
            Utils_Cartographie.Sector sec = ctrl.retSector;
            Ctrl002_GoogleMaps.getSectorCoord('MAG Test');
            Ctrl002_GoogleMaps.getRDVDuJourList('MAG001Test', 547031,547450,2524237,2523701, 'R2', usr.Id, usr.Profile.Name);
            Ctrl002_GoogleMaps.getRDVProchainList('MAG001Test', 547031,547450,2524237,2523701, 'R2', usr.Id, usr.Profile.Name);

            Test.stopTest();
        }
    }

    @isTest 
    static void test_GoogleMaps_RDVPlus() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        // Création utilisateur
        User user = Utils_Test.createVendeurUser('MAG001Test', 'MAG001Test', 'MAG001Test', roleMag.Id);
        User usr = [SELECT Id, Profile.Name FROM User WHERE Id=:user.Id LIMIT 1];

        System.runAs(user) {
            system.debug('user.CodeMagasin__c : ' + user.CodeMagasin__c);

            // Enregistrements utile
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account LIMIT 1];
            Chantier__c chantier = [SELECT Id, Name FROM Chantier__c LIMIT 1];
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            // RDV R1,R2 et R+
            Event eventRPlus = Utils_Test.createEvent('R+', rtActiviteCommerciale, projet1.Id, contact.Id, user.Id,null,true);
            
            // Exécution de la cartographie
            Test.startTest();
            PageReference vf002 = Page.VF002_GoogleMaps;
            Test.setCurrentPageReference (vf002);
            Ctrl002_GoogleMaps ctrl = new Ctrl002_GoogleMaps();
            String codeMag = ctrl.sectorcodeMagasin;
            Utils_Cartographie.Sector sec = ctrl.retSector;
            Ctrl002_GoogleMaps.getSectorCoord('MAG Test');
            Ctrl002_GoogleMaps.getRDVDuJourList('MAG001Test', 547031,547450,2524237,2523701, 'R+', usr.Id, usr.Profile.Name);
            Ctrl002_GoogleMaps.getRDVProchainList('MAG001Test', 547031,547450,2524237,2523701, 'R+', usr.Id, usr.Profile.Name);

            Test.stopTest();
        }
    }

    @isTest 
    static void test_GoogleMaps_Prospection() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        // Création utilisateur
        User user = Utils_Test.createVendeurUser('MAG001Test', 'MAG001Test', 'MAG001Test', roleMag.Id);
        User usr = [SELECT Id, Profile.Name FROM User WHERE Id=:user.Id LIMIT 1];

        System.runAs(user) {
            system.debug('user.CodeMagasin__c : ' + user.CodeMagasin__c);

            // Enregistrements utile
            Account acc = [SELECT Id, AccountSource, accountCallSource__c FROM Account LIMIT 1];
            Chantier__c chantier = [SELECT Id, Name FROM Chantier__c LIMIT 1];
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            // RDV Prospection
            Event eventProspection = Utils_Test.createEvent(null, rtActiviteProspe, projet1.Id, contact.Id, user.Id,null,true);

            Event eventProspection2 = Utils_Test.createEvent(null, rtActiviteProspe, null, null, user.Id, false);
            Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord(1, 1);
            latlong.transform();
            eventProspection2.localisation__Latitude__s = latlong.Latitude;
            eventProspection2.localisation__Longitude__s = latlong.Longitude;
            insert eventProspection2;

            // Exécution de la cartographie
            Test.startTest();
            PageReference vf002 = Page.VF002_GoogleMaps;
            Test.setCurrentPageReference (vf002);
            Ctrl002_GoogleMaps ctrl = new Ctrl002_GoogleMaps();
            String codeMag = ctrl.sectorcodeMagasin;
            Utils_Cartographie.Sector sec = ctrl.retSector;
            Ctrl002_GoogleMaps.getSectorCoord('MAG Test');
            try {
                Ctrl002_GoogleMaps.getProspectionsProchaineList('MAG001Test', 547031,547450,2524237,2523701, usr.Id, usr.Profile.Name);
            } catch(Exception e) {}
            try {
                Ctrl002_GoogleMaps.getProspectionsDuJourList('MAG001Test', 547031,547450,2524237,2523701, usr.Id, usr.Profile.Name);
            } catch(Exception e) {}

            Test.stopTest();
        }
    }

    @isTest 
    static void test_GoogleMaps_TestUtils() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);

        System.runAs(user) {
            system.debug('user.CodeMagasin__c : ' + user.CodeMagasin__c);
            Sectorisation__c secto = [SELECT Id, codeDepot__c, codeMagasin__c FROM Sectorisation__c WHERE CodeMagasin__c = 'MAG001Test' LIMIT 1];
            Attachment att = [SELECT Id, Name, Body FROM Attachment WHERE Name = 'MAG001Test' LIMIT 1];
            
            Test.startTest();

            // API Google Maps Geocoder
            Utils_Cartographie.getGeoGoogleMaps('RUE DE TOLBIAC', '75013', 'Paris', false);
            Utils_Cartographie.getGeoGoogleMaps('RUE DE TOLBIAC', '7501', 'Paris'); // Test si code postal non correct

            // Transformation LAMBER2 en WGS84
            Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord(601184, 2425284);
            latlong.transform();
            system.assertNotEquals(null, latlong.Longitude);
            system.assertNotEquals(null, latlong.Latitude);

            // Sector
            Utils_Cartographie.Sector sector = new Utils_Cartographie.Sector();
            sector = new Utils_Cartographie.Sector(secto);
            sector = new Utils_Cartographie.Sector(secto, att);
            sector.Id = sector.Id; sector.Name = sector.Name; sector.WKT = sector.WKT;
            
            Test.stopTest();
        }
    }
        
    @isTest 
    static void test_GoogleMaps_TestUtils2() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);

        System.runAs(user) {
            
            Test.startTest();
            
            // Création Compte, Chantier            
            Account acc = Utils_Test.createAccount('Account TESTTEST', 'test', 'test@test.fr', accPersoRecordType, 'Email',true);
            Chantier__c chantier2 = Utils_Test.createChantier('Chantier 2', null, null, acc.Id, null, null, null, false);
            chantier2.telephoneMobileLocataires__c = '0123456789';
            chantier2.autreTelephoneLocataires__c = '0123456789';
            insert chantier2;
            Chantier__c chantier3 = Utils_Test.createChantier('Chantier 3', null, null, null, null, acc.Id, null, false);
            chantier3.telephoneDomicileOccupants__c = '0123456789';
            chantier3.telephoneMobileOccupants__c = '0123456789';
            insert chantier3;
            
            KContrat__c contrat2 = Utils_Test.createContrat('Contrat2', chantier2.Id, acc.Id, '0014', true);
            KContrat__c contrat3 = Utils_Test.createContrat('Contrat3', chantier3.Id, acc.Id, '0015', true);
            
            List<Chantier__c> chaList = [SELECT Id, Name, rue__c, codePostal__c, ville__c, interditProspection__c, nbContratsResilies__c, nbContratsVendus__c, nomProprietaires__c, nomLocataires__c, nomOccupants__c, 
                                         prenomProprietaires__c, prenomLocataires__c, prenomOccupants__c, locataire__c, telephoneDomicileLocataires__c, telephoneMobileLocataires__c, locataire__r.name, 
                                         proprietaire__c, proprietaire__r.name, telephoneDomicileProprietaires__c, telephoneMobileProprietaires__c, occupant__c, telephoneDomicileOccupants__c, 
                                         telephoneMobileOccupants__c, occupant__r.name, autreProprietaire__c, autreProprietaire__r.name, autreLocataire__c, autreOccupant__c, autreOccupant__r.name, autreLocataire__r.name,
                                         autreTelephoneLocataires__c, autreTelephoneOccupants__c, autreTelephoneProprietaires__c, OwnerId, Localisation__Latitude__s, Localisation__Longitude__s ,
                                         (SELECT Id, datesignature__c, nombreInterventionsSAV__c, derniereInterventionSAV__c, nbSAVTotal__c, produits__c FROM ChantierContrats__r ORDER BY LastModifiedDate DESC LIMIT 1) 
                                         FROM Chantier__c];
            Utils_Cartographie.newChantierWithContratFDRList(chaList); 
            
            Test.stopTest();
        }
    }
}