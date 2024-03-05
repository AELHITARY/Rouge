//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Pages_Feuillederoute
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2020
//-- Version     : 1.0
//-- Description : Classe de tests des pages Feuillederoute et Feuillederoute_PDF
//-- * 1.0 : CRM-228, Fusion avec Test_Ctrl_Feuillederoute_PDF et Test_Ctrl002_Feuillederoute
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Pages_Feuillederoute{
    private static final Id rtPerson = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id rtActiviteProspe = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
    private static final UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
    
    @testSetup 
    static void setup() {
        // Récupération Role
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('usercontext.cache.enabled', false);
        // Création Sectorisation
        Utils_Test.createSectorisation(codeMagasin, codeMagasin, codeMagasin, codeMagasin,true);
        // Création de document LOGO
        Document doc = Utils_Test.createDocument('Logo', Constants.KparK_logo_NB, true);
    }

    @isTest
    static void testRDVService() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User user = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin, roleMag.Id); 
        user.ByPassValidationRule__c = true;
        update user;

        System.runAs(user) {           

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.rue__c='34 de la faisanderie';
            chantier.codePostal__c='75116';
            chantier.ville__c='Paris';
            chantier.departement__c='Ile de France';
            chantier.pays__c='France';
            insert chantier;
            
            // Mise à jour localisation
            chantier.codeMagasinTechnique__c = codeMagasin;
            update chantier;
            // Création Contrats SAV, Pose et Metrage
            List<KContrat__c> contratToUpdate = new List<KContrat__c>();
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

            // Création Worktypes
            List<WorkType> wtToInsert = new List<WorkType>();
            WorkType wtInstallation = new WorkType(Name = Constants.WORKTYPE_INSTALLATION, 
                                              EstimatedDuration=1.0,
                                              fsl_dateOuverture__c = Date.today().addDays(-10));
            wtToInsert.add(wtInstallation);
            WorkType wtMetrage = new WorkType(Name = Constants.WORKTYPE_METRAGE, 
                                              EstimatedDuration=1.0,
                                              fsl_dateOuverture__c = Date.today().addDays(-10));
            wtToInsert.add(wtMetrage);
            WorkType wtInterventionSAV = new WorkType(Name = Constants.WORKTYPE_INTERVENTION_SAV, 
                                              EstimatedDuration=1.0,
                                              fsl_dateOuverture__c = Date.today().addDays(-10));
            wtToInsert.add(wtInterventionSAV);
            insert wtToInsert;  

            //Création horaires
            OperatingHours oh = new OperatingHours(
                Name='Par défaut',
                TimeZone='Europe/Paris');
            insert oh;  

            //Création d'un territoire 
            ServiceTerritory st = new ServiceTerritory(
                //ParentTerritoryId=parentST.id,
                Name='Depot',
                OperatingHoursId=oh.Id,
                KparKReference__c = 'DEP',
                IsActive = true);    
            insert st;    
            
            Test.startTest();
        
            //Création d'un work order 
            DateTime now=System.now();
            WorkOrder woPose = new WorkOrder(
                FSL_EXTERNALID__C='ParentWorkOrder',
                AccountId=acc.Id, 
                ContratK__c=contratPose.Id, 
                WorkTypeId=wtInstallation.id,
                ServiceTerritoryId=st.Id,
                STARTDATE=now.addDays(1),
                ENDDATE=now.addDays(3),
                DURATIONTYPE='Minutes',
                DURATION=40,
                fsl_techFlagSynchro__c=Datetime.newInstance(2018, 2, 7, 10, 0, 0),
                FSL__VisitingHours__c = oh.id, 
                fsl_chiffreAffaire__c = 300);
            insert woPose;

            //Création RDV 
            WorkOrder WO = [SELECT Id FROM WorkOrder LIMIT 1][0];
            // Création RDV de service SAV, Pose et Metrage
            List<ServiceAppointment> rdvServiceToUpdate = new List<ServiceAppointment>();
            ServiceAppointment sa = new ServiceAppointment(SchedStartTime = System.Today(), 
                                                            Chantier__c = chantier.Id, 
                                                            ContratK__c = contratPose.Id,
                                                            ParentRecordId = WO.Id,
                                                            Subject = 'Harry Potter',
                                                            EarliestStartTime = Date.today(),
                                                            Duration = 180.0,
                                                            Status = Constants.RDV_FSL_CONFIRME,
                                                            fsl_chiffreAffaire__c = 1000);
            Integer duration= Integer.valueOf(sa.Duration);        
            sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
            rdvServiceToUpdate.add(sa);
            /*
            ServiceAppointment rdvServicePose = new ServiceAppointment(SchedStartTime = System.Today(), 
                                                                       Chantier__c = chantier.Id, 
                                                                       ContratK__c = contratPose.Id);
            rdvServiceToUpdate.add(rdvServicePose);

            ServiceAppointment rdvServiceIntSav = new ServiceAppointment(SchedStartTime = System.Today(), 
                                                                       Chantier__c = chantier.Id, 
                                                                       ContratK__c = contratIntSav.Id);
            rdvServiceToUpdate.add(rdvServiceIntSav);
            insert rdvServiceToUpdate;
            */

            // Test 
            Ctrl002_Feuillederoute ctrl = new Ctrl002_Feuillederoute();
            PageReference pageVF = Page.VF002_Feuillederoute;
            Test.setCurrentPage(pageVF);

            pageVF.getParameters().put('x_left'  , '-1000');
            pageVF.getParameters().put('x_right' , '1000');
            pageVF.getParameters().put('y_top'   , '1000');
            pageVF.getParameters().put('y_bottom', '-1000');
            pageVF.getParameters().put('sector'  , codeMagasin);

            ctrl.insertUserStats();

            System.debug(ctrl.getChantiersAvecContratsJSON());
            System.debug(ctrl.getChantiersSansContratsJSON());
            System.debug(ctrl.getPoseDuJourJSON());
            System.debug(ctrl.getPoseDuDemainJSON());
            System.debug(ctrl.getSAVJSON());
            System.debug(ctrl.getMetrageDuJourJSON());
            System.debug(ctrl.getMetrageDeDemainJSON());
            System.debug(ctrl.getInterventionSAVDuJourJSON());
            System.debug(ctrl.getInterventionSAVDeDemainJSON());
            Test.stopTest();
        }
    }
    
    @isTest
    static void testRDVCommerciaux() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User user = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin, roleMag.Id); 

        System.runAs(user) {
            List<Event> eventToUpdate = new List<Event>();
            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.sectorisation__c = sec.Id;
            insert chantier;
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

            // Mise à jour localisation
            chantier.codeMagasinTechnique__c = codeMagasin;
            update chantier;
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            Test.startTest();  

            // RDV Prospection
            Event eventProspection = Utils_Test.createEvent(null, rtActiviteProspe, projet1.Id, contact.Id, user.Id, true);
            eventProspection.ActivityDate = System.today();
            eventToUpdate.add(eventProspection);

            Event eventProspection2 = Utils_Test.createEvent(null, rtActiviteProspe, null, null, user.Id, true);
            eventProspection2.ActivityDate = System.today();
            Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord(1, 1);
            latlong.transform();
            eventProspection2.localisation__Latitude__s = latlong.Latitude;
            eventProspection2.localisation__Longitude__s = latlong.Longitude;
            eventToUpdate.add(eventProspection2);
            update eventToUpdate;
            
            // Test 
            Ctrl002_Feuillederoute ctrl = new Ctrl002_Feuillederoute();
            PageReference pageVF = Page.VF002_Feuillederoute;
            Test.setCurrentPage(pageVF);

            pageVF.getParameters().put('x_left'  , '-1000');
            pageVF.getParameters().put('x_right' , '1000');
            pageVF.getParameters().put('y_top'   , '1000');
            pageVF.getParameters().put('y_bottom', '-1000');
            pageVF.getParameters().put('sector'  , codeMagasin);

            ctrl.insertUserStats();      
            System.debug (ctrl.getR1DuJourJSON());
            System.debug (ctrl.getR2DuJourJSON());
            System.debug (ctrl.getRPlusDuJourJSON());
            System.debug (ctrl.getProspectionDuJourJSON());
            Test.stopTest();
        }
    }
    
    @isTest
    static void testRDVCommerciaux2() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User user = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin, roleMag.Id); 

        System.runAs(user) {
            List<Event> eventToUpdate = new List<Event>();
            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.sectorisation__c = sec.Id;
            insert chantier;
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

            // Mise à jour localisation
            chantier.codeMagasinTechnique__c = codeMagasin;
            update chantier;
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            // RDV R1,R2 et R+
            /*Event eventR1 = Utils_Test.createEvent('R1', rtActiviteCommerciale, projet1.Id, contact.Id, user.Id, false);
            eventR1.ActivityDate = System.today();
            eventToUpdate.add(eventR1);*/

            /*Event eventR2 = Utils_Test.createEvent('R2', rtActiviteCommerciale, projet1.Id, contact.Id, user.Id, false);
            eventR2.ActivityDate = System.today();
            eventToUpdate.add(eventR2);

            Event eventRPlus = Utils_Test.createEvent('R+', rtActiviteCommerciale, projet1.Id, contact.Id, user.Id, false);
            eventRPlus.ActivityDate = System.today();
            eventToUpdate.add(eventRPlus);
            insert eventToUpdate;*/

            Test.startTest();  
            
            // Test 
            Ctrl002_Feuillederoute ctrl = new Ctrl002_Feuillederoute();
            PageReference pageVF = Page.VF002_Feuillederoute;
            Test.setCurrentPage(pageVF);

            pageVF.getParameters().put('x_left'  , '-1000');
            pageVF.getParameters().put('x_right' , '1000');
            pageVF.getParameters().put('y_top'   , '1000');
            pageVF.getParameters().put('y_bottom', '-1000');
            pageVF.getParameters().put('sector'  , codeMagasin);

            ctrl.insertUserStats();      
            System.debug (ctrl.getR1DuJourJSON());
            System.debug (ctrl.getR2DuJourJSON());
            System.debug (ctrl.getRPlusDuJourJSON());
            System.debug (ctrl.getProspectionDuJourJSON());
            Test.stopTest();
        }
    }

    @isTest
    static void testPDFVendeur() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User user = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin, roleMag.Id); 

        System.runAs(user){
            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            // Mise à jour localisation
            chantier.codeMagasinTechnique__c = codeMagasin;
            chantier.Localisation__Latitude__s = 12;
            chantier.Localisation__Longitude__s = 12;
            update chantier;
            // Création Contrats SAV, Pose et Metrage
            List<KContrat__c> contratToUpdate = new List<KContrat__c>();
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

            Test.startTest();

            PageReference pageVF = Page.VF_Feuilldederoute_PDF;
            pageVF.getParameters().put('userId', user.Id);
            Test.setCurrentPageReference(pageVF);
            Ctrl_Feuillederoute_PDF ctrl = new Ctrl_Feuillederoute_PDF();
            ctrl.getLogoKparKId();

            Test.stopTest();
        }
    }

    @isTest
    static void testPDFRV() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User userTestRV = Utils_Test.createRVUser(codeMagasin, codeMagasin, codeMagasin,roleMag.Id);

        System.runAs(userTestRV){
            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            // Mise à jour localisation
            chantier.codeMagasinTechnique__c = codeMagasin;
            chantier.Localisation__Latitude__s = 12;
            chantier.Localisation__Longitude__s = 12;
            update chantier;

            Test.startTest();

            // Création Contrats SAV, Pose et Metrage
            List<KContrat__c> contratToUpdate = new List<KContrat__c>();
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

            PageReference pageVF = Page.VF_Feuilldederoute_PDF;
            pageVF.getParameters().put('userId', userTestRV.Id);
            Test.setCurrentPageReference(pageVF);
            Ctrl_Feuillederoute_PDF ctrl = new Ctrl_Feuillederoute_PDF();
            ctrl.getLogoKparKId();

            Test.stopTest();
        }
    }
    
    @isTest
    static void testPDFRDVCommerciaux() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin,roleMag.Id);

        System.runAs(userTestVendeur) {     
            List<Event> eventToUpdate = new List<Event>();
            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.sectorisation__c = sec.Id;
            insert chantier;
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            //Test
            Test.startTest();

            // RDV Prospection
            Event eventProspection = Utils_Test.createEvent(null, rtActiviteProspe, projet1.Id, contact.Id, userTestVendeur.Id, true);
            eventProspection.ActivityDate = System.today();
            eventToUpdate.add(eventProspection);

            Event eventProspection2 = Utils_Test.createEvent(null, rtActiviteProspe, null, null, userTestVendeur.Id, true);
            eventProspection2.ActivityDate = System.today();
            Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord(1, 1);
            latlong.transform();
            eventProspection2.localisation__Latitude__s = latlong.Latitude;
            eventProspection2.localisation__Longitude__s = latlong.Longitude;
            eventToUpdate.add(eventProspection2);
            update eventToUpdate;

            PageReference pageVF = Page.VF_Feuilldederoute_PDF;
            pageVF.getParameters().put('userId', userTestVendeur.Id);
            Test.setCurrentPageReference(pageVF);
            Ctrl_Feuillederoute_PDF ctrl = new Ctrl_Feuillederoute_PDF();
            ctrl.getLogoKparKId();

            Test.stopTest();
        }
    }

    @isTest
    static void testPDFRDVCommerciauxR1() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin,roleMag.Id, false);

        System.runAs(userTestVendeur) {
                 
            List<Event> eventToUpdate = new List<Event>();
            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.sectorisation__c = sec.Id;
            insert chantier;
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);
            Test.startTest();

            // RDV R1,R2 et R+
            Event eventR1 = Utils_Test.createEvent('R1', rtActiviteCommerciale, projet1.Id, contact.Id, userTestVendeur.Id, false);
            eventR1.ActivityDate = System.today();
            insert eventR1;
            
            PageReference pageVF = Page.VF_Feuilldederoute_PDF;
            pageVF.getParameters().put('userId', userTestVendeur.Id);
            Test.setCurrentPageReference(pageVF);
            Ctrl_Feuillederoute_PDF ctrl = new Ctrl_Feuillederoute_PDF();
            ctrl.getLogoKparKId();

            Test.stopTest();
        }
    }

    @isTest
    static void testPDFRDVCommerciauxR2() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin,roleMag.Id, false);

        System.runAs(userTestVendeur) {
            
            List<Event> eventToUpdate = new List<Event>();
            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.sectorisation__c = sec.Id;
            insert chantier;
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            Test.startTest();

            // RDV R1,R2 et R+
            Event eventR2 = Utils_Test.createEvent('R2', rtActiviteCommerciale, projet1.Id, contact.Id, userTestVendeur.Id, false);
            eventR2.ActivityDate = System.today();
            eventToUpdate.add(eventR2);
            insert eventToUpdate;

            PageReference pageVF = Page.VF_Feuilldederoute_PDF;
            pageVF.getParameters().put('userId', userTestVendeur.Id);
            Test.setCurrentPageReference(pageVF);
            Ctrl_Feuillederoute_PDF ctrl = new Ctrl_Feuillederoute_PDF();
            ctrl.getLogoKparKId();

            Test.stopTest();
        }
    }

    @isTest
    static void testPDFRDVCommerciauxRPlus() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin,roleMag.Id);

        System.runAs(userTestVendeur) {
            List<Event> eventToUpdate = new List<Event>();
            // Sectorisation
            Sectorisation__c sec = [SELECT Id, iris__c FROM Sectorisation__c LIMIT 1];

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.sectorisation__c = sec.Id;
            insert chantier;
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Opportunity projet1 = Utils_Test.createOpportunity(acc, chantier,true);

            //Test
            Test.startTest();     
            

            // RDV R+
            Event eventRPlus = Utils_Test.createEvent('R+', rtActiviteCommerciale, projet1.Id, contact.Id, userTestVendeur.Id, false);
            eventRPlus.ActivityDate = System.today();
            eventToUpdate.add(eventRPlus);
            insert eventToUpdate;

            PageReference pageVF = Page.VF_Feuilldederoute_PDF;
            pageVF.getParameters().put('userId', userTestVendeur.Id);
            Test.setCurrentPageReference(pageVF);
            Ctrl_Feuillederoute_PDF ctrl = new Ctrl_Feuillederoute_PDF();
            ctrl.getLogoKparKId();

            Test.stopTest();
        }
    }

    @isTest
    static void testPDFRDVService() {
        String codeMagasin = roleMag.Name.split('-')[0].trim();
        // Création utilisateurs Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser(codeMagasin, codeMagasin, codeMagasin, roleMag.Id); 
        userTestVendeur.ByPassValidationRule__c = true;
        update userTestVendeur;

        System.runAs(userTestVendeur) {     
            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', rtPerson, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.rue__c='34 de la faisanderie';
            chantier.codePostal__c='75116';
            chantier.ville__c='Paris';
            chantier.departement__c='Ile de France';
            chantier.pays__c='France';
            insert chantier;
            
            // Mise à jour localisation
            chantier.codeMagasinTechnique__c = codeMagasin;
            update chantier;
            
            // Création Contrats 
            List<KContrat__c> contratToUpdate = new List<KContrat__c>();
            KContrat__c contrat = Utils_Test.createContrat('Contrat Metrage', chantier.Id, acc.Id, '0002', false);
            contrat.cartoMetrageDuJour__c = Date.today();
            contratToUpdate.add(contrat);
            insert contratToUpdate;

            // Création Worktypes
            WorkType wkType = new WorkType(Name = Constants.WORKTYPE_METRAGE, 
                                              EstimatedDuration=1.0,
                                              fsl_dateOuverture__c = Date.today().addDays(-10));
            insert wkType;

            //Création horaires
            OperatingHours oh = new OperatingHours(
                Name='Par défaut',
                TimeZone='Europe/Paris');
            insert oh;  

            //Création d'un territoire 
            ServiceTerritory st = new ServiceTerritory(
                //ParentTerritoryId=parentST.id,
                Name='Depot',
                OperatingHoursId=oh.Id,
                IsActive=true,
                KparKReference__c = 'DEP');     
            insert st;    
            
            Test.startTest();
        
            //Création d'un work order 
            DateTime now=System.now();
            WorkOrder woPose = new WorkOrder(
                FSL_EXTERNALID__C='ParentWorkOrder',
                AccountId=acc.Id, 
                ContratK__c=contrat.Id, 
                WorkTypeId=wkType.id,
                ServiceTerritoryId=st.Id,
                STARTDATE=now.addDays(1),
                ENDDATE=now.addDays(3),
                DURATIONTYPE='Minutes',
                DURATION=40,
                fsl_techFlagSynchro__c=Datetime.newInstance(2018, 2, 7, 10, 0, 0),
                FSL__VisitingHours__c = oh.id, 
                fsl_chiffreAffaire__c = 300);
            insert woPose;

            //Création RDV 
            WorkOrder WO = [SELECT Id FROM WorkOrder LIMIT 1][0];
            // Création RDV 
            ServiceAppointment sa = new ServiceAppointment(SchedStartTime = System.Today(), 
                                                            Chantier__c = chantier.Id, 
                                                            ContratK__c = contrat.Id,
                                                            ParentRecordId = WO.Id,
                                                            Subject = 'Harry Potter',
                                                            EarliestStartTime = Date.today(),
                                                            Duration = 180.0,
                                                            Status = Constants.RDV_FSL_CONFIRME,
                                                            fsl_chiffreAffaire__c = 1000);
            Integer duration= Integer.valueOf(sa.Duration);        
            sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
            sa.fsl_dateConfirmation__c = date.today();
            insert sa;

            PageReference pageVF = Page.VF_Feuilldederoute_PDF;
            pageVF.getParameters().put('userId', userTestVendeur.Id);
            Test.setCurrentPageReference(pageVF);
            Ctrl_Feuillederoute_PDF ctrl = new Ctrl_Feuillederoute_PDF();
            ctrl.getLogoKparKId();

            Test.stopTest();
        }
    }
}