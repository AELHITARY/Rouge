//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_EXP
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/07/2020
//-- Version     : 1.2
//-- * 1.2 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.1 : Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_EXP {

   @isTest static void testSchedule_corrigerRDV() {

      // Récupération Record Type
      Id rtPerson = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

      // Création enregistrements utile
      Account acc = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtPerson, 'Email', true);
      Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);

      // Création Contrat 
      KContrat__c contrat = Utils_Test.createContrat('Contrat', chantier.Id, acc.Id, '0002', false);
      contrat.cartoMetrageDuJour__c = Date.today().addDays(1);
      contrat.cartoInstallationDuJour__c = Date.today().addDays(1);
      contrat.cartoInterventionSAVDuJour__c = Date.today().addDays(1);
      contrat.cartoMetrageDeDemain__c = Date.today();
      contrat.cartoInstallationDeDemain__c = Date.today();
      contrat.cartoInterventionSAVDeDemain__c = Date.today();
      contrat.prochainMetrage__c = Date.today().addDays(1);
      contrat.prochaineInstallation__c = Date.today().addDays(1);
      contrat.prochainSAV__c = Date.today().addDays(1);
      insert contrat;

      
      KContrat__c contrat2 = Utils_Test.createContrat('Contrat2', chantier.Id, acc.Id, '0003', false);
      contrat2.cartoMetrageDuJour__c = Date.today().addDays(1);
      contrat2.cartoInstallationDuJour__c = Date.today().addDays(1);
      contrat2.cartoInterventionSAVDuJour__c = Date.today().addDays(1);
      contrat2.cartoMetrageDeDemain__c = Date.today().addDays(4);
      contrat2.cartoInstallationDeDemain__c = Date.today().addDays(4);
      contrat2.cartoInterventionSAVDeDemain__c = Date.today().addDays(4);
      contrat2.prochainMetrage__c = Date.today().addDays(1);
      contrat2.prochaineInstallation__c = Date.today().addDays(1);
      contrat2.prochainSAV__c = Date.today().addDays(1);
      insert contrat2;

      Test.startTest();

      Schedule_EXP_CorrigerRDV schedule = new Schedule_EXP_CorrigerRDV();
      schedule.execute(null);
      BA_EXP_CorrigerRDV ba = new BA_EXP_CorrigerRDV();
      Database.executeBatch(ba);

      Test.stopTest();
   }

   @isTest static void testSchedule_supprimeICTInactifs() {

      User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

      System.runAs(user){
         // Récupération des Record Type
         Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
         // Création enregistrements utile
         Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',true);
         Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
         Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

         // Creation devis
         Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today()-30, 1000, 100, true);

         KIncontournable__c incontournable = Utils_Test.createIncontournable(devis, false);
         incontournable.actif__c = false;
         insert incontournable;
         KIncontournable__c incontournable2 = Utils_Test.createIncontournable(devis, false);
         incontournable2.actif__c = false;         
         incontournable2.nIncontournable__c = 'ICT/0102030405/02';
         insert incontournable2;

         Test.startTest();

         BA_EXP_SupprimeICTInactifs ba = new BA_EXP_SupprimeICTInactifs();
         Database.executeBatch(ba);
         Schedule_EXP_SupprimeICTInactifs schedule = new Schedule_EXP_SupprimeICTInactifs();
         schedule.execute(null);

         Test.stopTest();
      }
   }

   @isTest static void testSchedule_supprimeIECInactives() {

      User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

      System.runAs(user){
         // Récupération des Record Type
         Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
         // Création enregistrements utile
         Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',true);
         Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
         Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

         // Creation devis
         Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today()-30, 1000, 100, true);

         // Création Contrat 
         KContrat__c contrat = Utils_Test.createContrat('Contrat', chantier.Id, acc.Id, '0002', true);

         // Création instance en cours
         KInstance__c instance = new KInstance__c();
         instance.contrat__c = contrat.id;
         instance.actif__c = false;
         instance.dateEcheance__c = System.today() + 10;
         instance.dateEntree__c = System.today();
         instance.dateSortie__c = System.today()+1;
         instance.nInstance__c = 'IEC/0102030405/01';
         instance.statut__c = 'EN COURS';
         insert instance;

         // Création instance en cours
         KInstance__c instance2 = new KInstance__c();
         instance2.contrat__c = contrat.id;
         instance2.actif__c = false;
         instance2.dateEcheance__c = System.today() + 10;
         instance2.dateEntree__c = System.today();
         instance2.dateSortie__c = System.today()+1;
         instance2.nInstance__c = 'IEC/0102030405/02';
         instance2.statut__c = 'EN COURS';
         insert instance2;

         Test.startTest();

         Schedule_EXP_SupprimeIECInactives schedule = new Schedule_EXP_SupprimeIECInactives();
         schedule.execute(null);
         BA_EXP_SupprimeIECInactives ba = new BA_EXP_SupprimeIECInactives();
         Database.executeBatch(ba);

         Test.stopTest();
      }
   }

    @isTest static void testSchedule_supprimeRDVPasses() {

        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user) {         
            Id rtActiviteAnnexeTA = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_TA_RT);
            Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

            // RDV R1,R2 et R+
            Event eventR1 = Utils_Test.createEvent('Congés', rtActiviteAnnexeTA, opp.Id, contact.Id, user.Id, false);
            eventR1.ActivityDate = Date.today().addDays(-7);
            eventR1.StartDateTime = Date.today().addDays(-7);
            eventR1.EndDateTime = Date.today().addDays(-7);
            insert eventR1;

            Test.startTest();

            Schedule_EXP_SupprimeRDVPasses schedule = new Schedule_EXP_SupprimeRDVPasses();
            schedule.execute(null);
            BA_EXP_SupprimeRDVPasses ba = new BA_EXP_SupprimeRDVPasses();
            Database.executeBatch(ba);

            Test.stopTest();
        }
   }

   @isTest static void testSchedule_listeDesactivationUsers() {
    
      // Récupération profil
        List<UserRole> ur = new List<UserRole>();
        ur = [SELECT Id, Name FROM UserRole WHERE UserRole.Name LIKE '%- REF -%'];
        String prfRVId = [Select Id FROM Profile WHERE Name = 'K/K - RV'].Id;
        User userTestRV = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfRVId, ur[0].Id, 'DR123', 'DV123', 'M123',false);
        User userTestRV2 = Utils_Test.createUser(true,'tes2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', prfRVId, ur[1].Id ,'DR123', 'DV123', 'M123',false);
        User userTestRV3 = Utils_Test.createUser(true,'tes3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', prfRVId, 'DR123', 'DV123', 'M123',true);
        User userTestAdmin = Utils_Test.createAdminUser();
        User userTestCall = Utils_Test.createCallUser();
        userTestRV2.ManagerId = userTestRV.Id;
        userTestRV.isActive = false;
        userTestRV2.isActive = false;
        insert userTestRV;
        insert userTestRV2;
        System.runAs(userTestAdmin){
            Test.startTest();
      
            Schedule_EXP_ListeDesactivationUsers schedule = new Schedule_EXP_ListeDesactivationUsers();
            String jobId = System.schedule('Test Schedule_EXP_ListeDesactivationUsers', '0 0 23 * * ?', schedule);
            BA_EXP_ListeDesactivationUsers ba = new BA_EXP_ListeDesactivationUsers();
            Database.executeBatch(ba);
          Test.stopTest();
      }
   }

   @isTest static void testSchedule_listeInactiviteUsers() {

      List<UserRole> ur = new List<UserRole>();
        ur = [SELECT Id, Name FROM UserRole WHERE UserRole.Name LIKE '%- REF -%'];
        String prfRVId = [Select Id FROM Profile WHERE Name = 'K/K - RV'].Id;
        User userTestRV = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfRVId, ur[0].Id, 'DR123', 'DV123', 'M123',false);
        User userTestRV2 = Utils_Test.createUser(true,'tes2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', prfRVId, ur[1].Id ,'DR123', 'DV123', 'M123',false);
        User userTestRV3 = Utils_Test.createUser(true,'tes3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', prfRVId, 'DR123', 'DV123', 'M123',true);
        User userTestAdmin = Utils_Test.createAdminUser();
        User userTestCall = Utils_Test.createCallUser();
        userTestRV2.ManagerId = userTestRV.Id;
        userTestRV.isActive = false;
        userTestRV2.isActive = false;
        insert userTestRV;
        insert userTestRV2;
        System.runAs(userTestAdmin){
            Test.startTest();

      Schedule_EXP_ListeInactiviteUsers schedule = new Schedule_EXP_ListeInactiviteUsers();
      String jobId = System.schedule('Test Schedule_EXP_ListeInactiviteUsers', '0 0 23 * * ?', schedule);
      BA_EXP_ListeInactiviteUsers ba = new BA_EXP_ListeInactiviteUsers();
      Database.executeBatch(ba);

      Test.stopTest();
        }
   }

   @isTest static void testSchedule_desactiveUsers() {

      List<UserRole> ur = new List<UserRole>();
      ur = [SELECT Id, Name FROM UserRole WHERE UserRole.Name LIKE '%- REF -%'];
        String prfRVId = [Select Id FROM Profile WHERE Name = 'K/K - RV'].Id;
        User userTestRV = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfRVId, ur[0].Id, 'DR123', 'DV123', 'M123',true);
        User userTestRV2 = Utils_Test.createUser(true,'tes2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', prfRVId, ur[1].Id ,'DR123', 'DV123', 'M123',false);
        User userTestRV3 = Utils_Test.createUser(true,'tes3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', prfRVId, 'DR123', 'DV123', 'M123',true);
        User userTestAdmin = Utils_Test.createAdminUser();
        User userTestCall = Utils_Test.createCallUser();
        userTestRV2.ManagerId = userTestRV.Id;
        insert userTestRV2;
        System.runAs(userTestAdmin){
            Test.startTest();

      Schedule_EXP_DesactiveUsers schedule = new Schedule_EXP_DesactiveUsers();
      String jobId = System.schedule('Test Schedule_EXP_DesactiveUsers', '0 0 23 * * ?', schedule);
      BA_EXP_desactiveUsers ba = new BA_EXP_desactiveUsers();
      Database.executeBatch(ba);

      Test.stopTest();
        }
   }

    @isTest static void testSchedule_supprimeImportMkt() {

        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Valeur du paramètre personnalisé de maintenance
            PropertiesUtils.setBooleanValue('maintenance.ImportMktASupprimer', true);

            // Récupération Record Type
            Id rtImport = DAL.getRecordTypeIdByDevName('Import__c', Constants.RT_IMPORT_EXTERNE);
            Id rtFicheContact = DAL.getRecordTypeIdByDevName('Import__c', Constants.RT_IMPORT_CONTACT);
            Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
            Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

            // Création enregistrements utile
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Event eventR1 = Utils_Test.createEvent('R1', rtActiviteCommerciale, opp.Id, contact.Id, user.Id, false);
            eventR1.StartDateTime = Date.today().addDays(7);
            eventR1.EndDateTime = Date.today().addDays(8);
            insert eventR1;

            // Création Import
            Import__c imp1 = Utils_Test.createImport(rtImport,'NOMUN','PRENOMUN','2 avenue des Champs Elysées','Paris','75008','0100000001',
                                                        'puser'+System.now().format('hhmmss')+'@testemail.com','', null,false);
            imp1.dateIntegration__c = Date.today().addDays(-20);
            insert imp1;

            // Création Import 2
            Import__c imp2 = Utils_Test.createImport(rtFicheContact,'NOMDEUX','PRENOMDEUX','4 avenue des Champs Elysées','Paris','75008','0100000002',
                                                        'puser'+System.now().format('hhmmss')+'@testemail.com','', null,false);
            imp2.dateIntegration__c = Date.today().addDays(-20);
            acc = [SELECT Id, LastModifiedDate FROM Account WHERE Id = :acc.Id LIMIT 1];
            imp2.versioningCompte__c = acc.LastModifiedDate.getTime();
            imp2.idRDV__c = eventR1.Id;
            imp2.dateRDV__c = Date.today().addDays(7);
            insert imp2;

            Test.startTest();

            Schedule_EXP_supprimeImportMkt schedule = new Schedule_EXP_supprimeImportMkt();
            schedule.execute(null);
            BA_EXP_supprimeImportMkt ba = new BA_EXP_supprimeImportMkt();
            Database.executeBatch(ba);

            Test.stopTest();
        }
    }

   @isTest static void testSchedule_expireDevis() {

      User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

      System.runAs(user){
         // Valeur du paramètre personnalisé de maintenance
         PropertiesUtils.setBooleanValue('maintenance.devisAExpirer', true);
         // Récupération des Record Type
         Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
         // Création enregistrements utile
         Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',true);
         Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
         Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

         // Creation devis
         Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today().addDays(-50), 1000, 100, true);
         devis.ExpirationDate = Date.today().addDays(-40);
         update devis;
         Quote devis2 = Utils_Test.createQuote('Devis 2', null, opp, Constants.StatutDevisAConfigurer, Date.today().addDays(-50), 1000, 100, true);
         devis2.ExpirationDate = Date.today().addDays(-40);
         update devis2;

         Test.startTest();

         Schedule_EXP_expireDevis schedule = new Schedule_EXP_expireDevis();
         schedule.execute(null);
         BA_EXP_expireDevis ba = new BA_EXP_expireDevis();
         Database.executeBatch(ba);

         Test.stopTest();
      }
   }
}