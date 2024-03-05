//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Pages_Calendrier
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/07/2023
//-- Version     : 1.2
//-- Description : Classe de tests des pages Calendrier, CalendrierDashboard et CalendrierMobile
//-- * 1.2 : MAJ Kube3
//-- * 1.1 : GDPR : Suppression référence semaine type
//-- * 1.0 : CRM-228, Fusion avec Test_Ctrl_Calendrier, Test_Ctrl_CalendrierDashboard et Test_Ctrl_CalendrierMobile
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Pages_Calendrier {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id accProRT = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_PRO_RT);
    private static final Id rtRDV = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id rtRDVProspection = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_PROSPECTION_RT);
    private static final Id rtRDVAnnexeTA = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_ANNEXE_TA_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        //Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);

        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        Sectorisation__c sect2 = Utils_Test.createSectorisation(magCode, 'Magasin Test', 'D123', 'Depot 123', true);
    }

    @isTest
    static void test_Calendrier_Affichage() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        system.debug('roleMag : '+roleMag);
        system.debug('roleMag.Name : '+roleMag.Name);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id);        

        System.RunAs(userTestRV) {
            // Récupération de l'année / mois
            String month = String.valueOf(Date.today().month());
            String year = String.valueOf(Date.today().year());
            system.debug('month ' + month);
            system.debug('year ' + year);

            // Création d'un contact et des comptes
            Contact contact = Utils_Test.createContact('Test','Test',true);
            List<Account> accList = new List<Account>();
            Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
            accList.add(a);
            Account b = Utils_Test.createAccount('Dupont','Jeanne','test2@test2.fr', accPersoRT, 'Email',false);
            accList.add(b);
            Account c = Utils_Test.createAccountPro('Dupont Jeanne','0123456789', accProRT, contact.Id,false);
            accList.add(c);
            Account d = Utils_Test.createAccountPro('Dupont Jeanne 2','0123456789', accProRT, null,false);
            accList.add(d);
            insert accList;

            Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, AccountSource, accountCallSource__c, PersonContactId FROM Account]);
            Account B2C1 = accountMap.get(a.id);
            Account B2C2 = accountMap.get(b.id);
            Account B2C3 = accountMap.get(c.id);
            Account B2C4 = accountMap.get(d.id);

            // Création des chantiers
            List<Chantier__c> chantierList = new List<Chantier__c>();
            Chantier__c chantierCompte1 = Utils_Test.createChantier('MyChantier1',B2C1.Id,B2C1.Id,false);
            Chantier__c chantierCompte1bis = Utils_Test.createChantier('MyChantier2',B2C1.Id,B2C2.Id,false);
            Chantier__c chantierCompte1bis2 = Utils_Test.createChantier('MyChantier3',B2C1.Id,false);
            chantierList.add(chantierCompte1);
            chantierList.add(chantierCompte1bis);
            chantierList.add(chantierCompte1bis2);
            insert chantierList;

            // Création des projets
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity oppChantierCompte1 = Utils_Test.createOpportunity('MyOpp1',B2C1,null,chantierCompte1,false);
            Opportunity oppChantierCompte1bis = Utils_Test.createOpportunity('MyOpp1bis',B2C2,null,chantierCompte1bis,false);
            oppList.add(oppChantierCompte1);
            oppList.add(oppChantierCompte1bis);
            insert oppList;

            // Création opération 
            Referencial__c source = new Referencial__c(Name = 'Test',
                                                        RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'Source'),
                                                        KparKReference__c = 'ref',
                                                        startDate__c = date.today(),
                                                        endDate__c = null);
            source.category__c = 'AUTRE';
            source.subCategory__c = 'PARRAINAGES & AUTRES';
            source.usableForSales__c = true;
            insert source;
            ReferentielOperation__c op1 = Utils_Test.createOperation('A operation1', Date.today().addMonths(-1), Date.today().addMonths(1), 'marseille', 10, 45, 89, '**', B2C1.AccountSource, false);
            op1.source__c = source.Id;
            insert op1;
            
            // Création d'une tache
            Task tOppChantierCompte1 = Utils_Test.createTask(null, oppChantierCompte1.Id, Constants.StatutTaskAFaire, userTestRV.Id,Date.today(),true);
            Utils_Test.createTask(null, chantierCompte1.Id, Constants.StatutTaskAFaire, userTestRV.Id,Date.today(),true);

            Test.startTest();

            // Création des events
            Event eventOppChantierCompte1 =  Utils_Test.createEvent(B2C1.Id, rtRDV, oppChantierCompte1.Id, null, userTestRV.Id, null, true);
            Event eventR1 = Utils_Test.createEvent('R1', rtRDV, oppChantierCompte1.Id, B2C1.PersonContactId, userTestRV.Id, Constants.StatutEventPris, 
                                    System.today(), System.now(),  System.now().addHours(2), 'location', true);
            List<Event> evtList = new List<Event>();
            String geoloc = '48.8534, 2.3488';
            evtList.add(Utils_Test.createEvent(oppChantierCompte1.Id, B2C1, Constants.EVENT_TYPE_R2, Constants.StatutEventNoneffectue, rtRDV, '', false));
            evtList.add(Utils_Test.createEvent(oppChantierCompte1.Id, B2C1, Constants.EVENT_TYPE_RP, Constants.StatutEventNonConfirme, rtRDV, '', false));
            evtList.add(Utils_Test.createEvent(oppChantierCompte1.Id, B2C1, Constants.EVENT_TYPE_R1, Constants.StatutEventDeplace, rtRDV, '', false));          
            evtList.add(Utils_Test.createEvent(oppChantierCompte1.Id, B2C1, Constants.EVENT_TYPE_R2, Constants.StatutEventEffectue, rtRDV, '', false));
            evtList.add(Utils_Test.createEvent(oppChantierCompte1.Id, B2C1, Constants.EVENT_TYPE_RP, Constants.StatutEventAReaffecter, rtRDV, '', false));
            evtList.add(Utils_Test.createEvent(oppChantierCompte1.Id, B2C1, Constants.EVENT_TYPE_R1, Constants.StatutEventAnnuleCall, rtRDV, '', false));
            /*evtList.add(Utils_Test.createEvent(oppChantierCompte1bis.Id, B2C1, 'Phone', '', rtRDVProspection, '', false));
            evtList.add(Utils_Test.createEvent(oppChantierCompte1bis.Id, B2C1, 'Prospection Physique', '', rtRDVProspection, '', false));
            evtList.add(Utils_Test.createEvent(oppChantierCompte1bis.Id, B2C1, 'Stand/Marché', '', rtRDVProspection, '', false));
            evtList.add(Utils_Test.createEvent(op1.Id, B2C3, 'Stand/Galerie Marchande', '', rtRDVProspection, geoloc, false));
            evtList.add(Utils_Test.createEvent(op1.Id, B2C3, 'Foire', '', rtRDVProspection, geoloc, false));            
            evtList.add(Utils_Test.createEvent(oppChantierCompte1.Id, B2C1, '', '', rtRDVAnnexeTA, '', false));*/
            insert evtList;

            List<String> userIds = new List<String>();
            userIds.add(userTestRV.Id);
            userIds.add(userTestVendeur.Id);

            PageReference pa = Page.VF_Calendrier;
            Test.setCurrentPage (pa);

            Ctrl_Calendrier ctrl = new Ctrl_Calendrier();
            ctrl.pageLoad();

            // Modifie les évènements/taches
            Ctrl_Calendrier.changeEventDateTime(eventR1.Id, false, Datetime.now().format('YYYY-MM-dd HH:mm:ss'), Datetime.now().addhours(2).format('YYYY-MM-dd HH:mm:ss'));
            Ctrl_Calendrier.changeEventDateTime(tOppChantierCompte1.Id, true, Datetime.now().format('YYYY-MM-dd HH:mm:ss'), Datetime.now().addhours(2).format('YYYY-MM-dd HH:mm:ss'));

            // Récupère la liste des vendeurs d'un magasin
            Ctrl_Calendrier.getVendeursByMagasin(magCode);

            // Récupère les évènements et les taches
            Ctrl_Calendrier.getActivitiesForUser(userIds[0], Datetime.now(), Datetime.now().addDays(1), true , true, true , true , true , true , true , true , true , true , true , true, true, true, true, true, magCode, true);
            
            Ctrl_Calendrier.closeTask(tOppChantierCompte1.Id);

            Ctrl_Calendrier.getVendeursByDistanceRemote(magCode, 'Account', B2C1.Id);
            Ctrl_Calendrier.getVendeursByDistanceRemote(magCode, 'Chantier', chantierCompte1.Id);
            Ctrl_Calendrier.getVendeursByDistanceRemote(magCode, 'Opportunity', oppChantierCompte1.Id);

            Test.stopTest();

        }
    }
    @isTest
    static void test_Calendrier_MagSubtistion() {
        // Récupération Role
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        UserRole roleManager = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :roleMag.ParentRoleId LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        system.debug('roleMag : '+roleMag);
        system.debug('roleMag.Name : '+roleMag.Name);
        // Création utilisateurs RV et Vendeur
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', magCode, roleMag.Id);
        User userTestRV = Utils_Test.createRVUser('DR123', 'DV123', magCode, roleManager.Id); 

        userTestRV.localisationLatitude__c = 48.8534;
        userTestRV.localisationLongitude__c = 2.3488;
        update userTestRV;     

        System.RunAs(userTestRV) {
            // Récupération de l'année / mois
            String month = String.valueOf(Date.today().month());
            String year = String.valueOf(Date.today().year());
            system.debug('month ' + month);
            system.debug('year ' + year);

            // Création d'un contact et des comptes
            Contact contact = Utils_Test.createContact('Test','Test',true);
            List<Account> accList = new List<Account>();
            Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
            accList.add(a);
            Account b = Utils_Test.createAccount('Dupont','Jeanne','test2@test2.fr', accPersoRT, 'Email',false);
            accList.add(b);
            Account c = Utils_Test.createAccountPro('Dupont Jeanne','0123456789', accProRT, contact.Id,false);
            accList.add(c);
            Account d = Utils_Test.createAccountPro('Dupont Jeanne 2','0123456789', accProRT, null,false);
            accList.add(d);
            insert accList;

            Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, AccountSource, accountCallSource__c, PersonContactId FROM Account]);
            Account B2C1 = accountMap.get(a.id);
            Account B2C2 = accountMap.get(b.id);
            Account B2C3 = accountMap.get(c.id);
            Account B2C4 = accountMap.get(d.id);

            // Création des chantiers
            Chantier__c chantierCompte1 = Utils_Test.createChantier('MyChantier1',B2C1.Id,B2C1.Id,true);
            Chantier__c chantierCompte1bis = Utils_Test.createChantier('MyChantier2',B2C1.Id,B2C2.Id,true);
            Chantier__c chantierCompte1bis2 = Utils_Test.createChantier('MyChantier3',B2C1.Id,true);
            
            // Création des projets
            Opportunity oppChantierCompte1 = Utils_Test.createOpportunity('MyOpp1',B2C1,null,chantierCompte1,true);
            Opportunity oppChantierCompte1bis = Utils_Test.createOpportunity('MyOpp1bis',B2C2,null,chantierCompte1bis,true);

            // Création d'une tache
            Task tOppChantierCompte1 = Utils_Test.createTask(null, oppChantierCompte1.Id, Constants.StatutTaskAFaire, userTestRV.Id,Date.today(),true);
            Utils_Test.createTask(null, chantierCompte1.Id, Constants.StatutTaskAFaire, userTestRV.Id,Date.today(),true);

            Test.startTest();

            PageReference pa = Page.VF_Calendrier;
            Test.setCurrentPage (pa);

            Ctrl_Calendrier ctrl = new Ctrl_Calendrier();
            ctrl.pageLoad();

            // Planning avec un chantier
            ctrl.objectName = 'Chantier';
            ctrl.objectId = chantierCompte1.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(chantierCompte1.Id, userTestVendeur.Id);
            ctrl.objectName = 'Chantier';
            ctrl.objectId = chantierCompte1bis.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(chantierCompte1bis.Id, userTestVendeur.Id);
            ctrl.objectName = 'Chantier';
            ctrl.objectId = chantierCompte1bis2.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(chantierCompte1bis2.Id, userTestVendeur.Id);

            // Planning avec un projet
            ctrl.objectName = 'Opportunity';
            ctrl.objectId = oppChantierCompte1.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(oppChantierCompte1.Id, userTestVendeur.Id);

            // Planning avec un compte
            ctrl.objectName = 'Account';
            ctrl.objectId = B2C2.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(B2C2.Id, userTestVendeur.Id);
            ctrl.objectName = 'Account';
            ctrl.objectId = B2C3.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(B2C3.Id, userTestVendeur.Id);
            ctrl.objectName = 'Account';
            ctrl.objectId = B2C4.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(B2C4.Id, userTestVendeur.Id);

            // Planning avec un contact
            ctrl.objectName = '';
            ctrl.objectId = contact.Id;
            ctrl.magCode = magCode;
            ctrl.pageLoad();
            Ctrl_Calendrier.objectCreate(contact.Id, userTestVendeur.Id);

            ctrl.magSubstitution();
            Ctrl_Calendrier.closeTask(tOppChantierCompte1.Id);

            Test.stopTest();

        }
    }

    @isTest 
    static void test_CalendrierDashboard() {
        //creation utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);

        // Initilialisation des objets pour la création des taches/évènements
        System.RunAs(user) {
            Account compte = Utils_Test.createAccount('Dupont', 'Jean', 'test@test.fr', accPersoRT, 'Email',true);
            // Création des chantiers
            Chantier__c chantierCompte1 = Utils_Test.createChantier('MyChantier1',compte.Id,true);
            Chantier__c chantierCompte1bis = Utils_Test.createChantier('MyChantier2',compte.Id,true);
            // Création projet
            Opportunity oppChantierCompte1 = Utils_Test.createOpportunity('MyOpp1',compte,null,chantierCompte1,true);
            // Création des tâches
            Task tCompte1 = Utils_Test.createTask(null, compte.Id, Constants.StatutTaskAFaire, user.Id,Date.today(),true);
            Task tChantierCompte1 = Utils_Test.createTask(null, chantierCompte1.Id, Constants.StatutTaskAFaire, user.Id,Date.today(),true);
            Task tChantierCompte1bis = Utils_Test.createTask(null, chantierCompte1bis.Id, Constants.StatutTaskTermine, user.Id,Date.today(),true);
            Task tOppChantierCompte1 = Utils_Test.createTask(null, oppChantierCompte1.Id, Constants.StatutTaskTermine, user.Id,Date.today(),true);
            // Création des event
            Event eventOppChantierCompte1 =  Utils_Test.createEvent(null, rtRDV, oppChantierCompte1.Id, null, user.Id,true);
            Event eventOppChantierCompte2 =  Utils_Test.createEvent(null, rtRDV, oppChantierCompte1.Id, null, user.Id,true);

            Test.startTest();

            PageReference pa = Page.VF_CalendrierDashboard;
            Test.setCurrentPage (pa);
            Ctrl_CalendrierDashboard ctrl = new Ctrl_CalendrierDashboard();

            // Initialisation des variables
            ctrl.getrtEventCommercial();
            ctrl.getrtEventProspection();
            ctrl.getrtEventAnnexe();
            ctrl.getrtTaskVendeur();
            ctrl.getBaseURL();

            // Chargement des events et test des fonctionnalités
            Ctrl_CalendrierDashboard.getSelectedEvents(date.today().day(), date.today().month(), date.today().year());
            Ctrl_CalendrierDashboard.getSelectedTasks(date.today().day(), date.today().month(), date.today().year());
            Ctrl_CalendrierDashboard.updateEventCommercial(eventOppChantierCompte1.Id, eventOppChantierCompte1.StatutRDV__c, 'Oui', eventOppChantierCompte1.ResultatduRDV__c, 'Malade');
            Ctrl_CalendrierDashboard.updateEventProspection(eventOppChantierCompte2.Id, 55, 0, 'Phone');
            Ctrl_CalendrierDashboard.updateEventProspection(eventOppChantierCompte2.Id, 55, 40, 'BAL');
            Ctrl_CalendrierDashboard.updateTask(tCompte1.Id, tCompte1.Priority, 'Terminé', 'Test');
            ctrl.refreshDate();

            Test.stopTest();
        }
    }

    @isTest 
    static void test_CalendrierMobile() {
        //creation utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);
        User user2 = Utils_Test.createUser(false,'testmlg3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3',null,null);

        System.RunAs(user) {
            List<String> vendeursList = new List<String>();
            vendeursList.add(user.Id);
            vendeursList.add(user2.Id);

            Account compte = Utils_Test.createAccount('Dupont', 'Jean', 'test@test.fr', accPersoRT, 'Email',true);
            // Création des chantiers
            Chantier__c chantierCompte1 = Utils_Test.createChantier('MyChantier1',compte.Id,true);
            Chantier__c chantierCompte1bis = Utils_Test.createChantier('MyChantier2',compte.Id,true);
            // Création projet
            Opportunity oppChantierCompte1 = Utils_Test.createOpportunity('MyOpp1',compte,null,chantierCompte1,true);
            // Création des tâches
            Task tCompte1 = Utils_Test.createTask(null, compte.Id, Constants.StatutTaskAFaire, user.Id,Date.today(),true);
            Task tChantierCompte1 = Utils_Test.createTask(null, chantierCompte1.Id, Constants.StatutTaskAFaire, user.Id,Date.today(),true);
            Task tChantierCompte1bis = Utils_Test.createTask(null, chantierCompte1bis.Id, Constants.StatutTaskTermine, user.Id,Date.today(),true);
            Task tOppChantierCompte1 = Utils_Test.createTask(null, oppChantierCompte1.Id, Constants.StatutTaskTermine, user.Id,Date.today(),true);
            // Création des event
            Event eventOppChantierCompte1 =  Utils_Test.createEvent(chantierCompte1.Id, rtRDV, oppChantierCompte1.Id, null, user.Id,true);
            Event eventOppChantierCompte2 =  Utils_Test.createEvent(null, rtRDVProspection, oppChantierCompte1.Id, null, user.Id,true);

            Test.startTest();

            PageReference pa = Page.VF_CalendrierMobile;
            Test.setCurrentPage (pa);
            Ctrl_CalendrierMobile ctrl = new Ctrl_CalendrierMobile();

            // Initialisation des variables
            ctrl.getrtEventCommercial();
            ctrl.getrtEventProspection();
            ctrl.getrtEventAnnexe();
            ctrl.getrtTaskVendeur();
            ctrl.insertUserStats();

            // Chargement des events et test des fonctionnalités
            Ctrl_CalendrierMobile.getSelectedEvents(date.today().day(), date.today().month(), date.today().year(), 'type', vendeursList);
            Ctrl_CalendrierMobile.getSelectedEvents(date.today().day(), date.today().month(), date.today().year(), 'vendeur', vendeursList);
            Ctrl_CalendrierMobile.getSelectedTasks(date.today().day(), date.today().month(), date.today().year(), vendeursList);
            Ctrl_CalendrierMobile.getSelectedTasks(date.today().day(), date.today().month(), date.today().year(), vendeursList);
            Ctrl_CalendrierMobile.updateEvent(eventOppChantierCompte1.Id, user2.Id);
            Ctrl_CalendrierMobile.updateEvent(eventOppChantierCompte2.Id, user2.Id);
            Ctrl_CalendrierMobile.getVendeursByDistance(vendeursList, oppChantierCompte1.Id, 42, 18);
            Ctrl_CalendrierMobile.getVendeursByMagasin('M123');
            ctrl.refreshDate();

            Test.stopTest();
        }
    }
}