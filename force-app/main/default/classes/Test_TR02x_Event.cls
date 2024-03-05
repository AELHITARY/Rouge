//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Event
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/01/2019
//-- Version     : 1.2
//-- *  Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_Event {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id rtProspection = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

    private static Sectorisation__c defaultSectorisation;

    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup 
    static void setup() {
        
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);

        PropertiesUtils.setBooleanValue('function.enabled.changeOwner', true);
       
        // Création ref  
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, false);
        refList.add(refMag);
        insert refList;
        // Création entite    
        List<Account> accList = new List<Account>();
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        entiteMag.KparKReference__c = 'TestMag2';
        accList.add(entiteMag);
        insert accList;

    }

    @isTest 
    static void test_eventRDV() {        
       
        defaultSectorisation = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
        Account B2C1 = createAccountB2C();
        Account B2C2 = createAccountB2C();

        List<Account> accounts = new List<Account>();
        accounts.add(B2C1);
        accounts.add(B2C2);
        insert accounts;

        Map<Id, Account> accountMap = new Map<Id, Account>((List<Account>) SchemaUtils.executeQuery('Account', IDUtils.getIDs(accounts)));
        B2C1 = accountMap.get(B2C1.id);
        B2C2 = accountMap.get(B2C2.id);

        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
        Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);
        
        Test.startTest();

        Event event0 = Utils_Test.createEvent(Constants.EVENT_TYPE_R0 ,rtRDV,projet.id,B2C1.PersonContactId,null, Constants.StatutEventAReaffecter, false);      
        Event event = Utils_Test.createEvent(Constants.EVENT_TYPE_R1 ,rtRDV,projet.id,B2C1.PersonContactId,null, Constants.StatutEventPris, false);
        Event event2 = Utils_Test.createEvent(Constants.EVENT_TYPE_R2 ,rtRDV,projet.id,B2C1.PersonContactId,null,'Non effectué', false);
        Event event3 = Utils_Test.createEvent(Constants.EVENT_TYPE_RP ,rtRDV,projet.id,B2C1.PersonContactId,null,'Non effectué (avec déplacement)', false);
        Event event4 = Utils_Test.createEvent('',rtRDV,projet.id,B2C1.PersonContactId,null,'Non effectué (avec déplacement)', false);
        
        
        insert new Event[]{event0, event, event2, event3, event4};

        event2.statutRDV__c = 'Effectué';
        event2.resultatDuRDV__c = 'Devisable';
        event2.activityDate = event.activityDate.addDays(-1);
        event2.startDateTime = event.startDateTime.addDays(-1);
        event2.endDateTime = event.endDateTime.addDays(-1);
        update event2;

        try {
            delete event3;
        } catch(Exception ex) {} // Catch 'vous n'avez pas les droits de suppression

        Test.stopTest();  
    }

    @isTest 
    static void test_eventDifferentOwner(){    
        // Création utilisateurs RV et Vendeur
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', 'M123', roleMag.Id);
        //User userTestRV = Utils_Test.createUser(false,'testRV', 'MyTestUserNameRV@test.sfd.test', 'MyTestUserNameRV','MyTestUserNameRV', profilRV.Id, role.Id);

        // récupération du groupe spécifique
        List<Group> userGroupList = [SELECT Id, Type, DeveloperName, RelatedId FROM Group WHERE DeveloperName = 'Utilisateurs_pilote'];

        //Ajout de l'utilisateur RV en tant que membre du groupe
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = userTestVendeur.Id;
        grpMem1.GroupId = userGroupList[0].Id;
        Insert grpMem1;
        //System.debug('user profile:'+user.ProfileId);

        Id currentUser = UserInfo.getUserId();
        
        System.runAs(userTestVendeur){
            defaultSectorisation = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
            Account B2C1 = createAccountB2C();
            Account B2C2 = createAccountB2C();

            List<Account> accounts = new List<Account>();
            accounts.add(B2C1);
            accounts.add(B2C2);
            insert accounts;

            Map<Id, Account> accountMap = new Map<Id, Account>((List<Account>) SchemaUtils.executeQuery('Account', IDUtils.getIDs(accounts)));
            B2C1 = accountMap.get(B2C1.id);
            B2C2 = accountMap.get(B2C2.id);

            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
            Opportunity projet = Utils_Test.createOpportunity(B2C1, B2C2, chantier, true);

            
        
            Test.startTest();
            
            try{
                Event event0 = Utils_Test.createEvent(Constants.EVENT_TYPE_R0 ,rtRDV,projet.id,B2C1.PersonContactId, currentUser, Constants.StatutEventAReaffecter, false);
                event0.magasin__c = 'Magasin Test';
                insert event0;

                event0.OwnerId = currentUser;
                update event0;
            }
            catch (Exception ex){} // Catch Erreur de droits
            Test.stopTest();
        }
    }

    @isTest 
    static void test_notificationCreationRDV() {
         // Création utilisateurs RV et Vendeur
        UserRole roleMag = [SELECT Id, Name FROM UserRole WHERE Name LIKE 'MAG%' LIMIT 1];
        User userTestVendeur = Utils_Test.createVendeurUser('DR123', 'DV123', 'M123', roleMag.Id);
        //User userTestRV = Utils_Test.createUser(false,'testRV', 'MyTestUserNameRV@test.sfd.test', 'MyTestUserNameRV','MyTestUserNameRV', profilRV.Id, role.Id);

        // récupération du groupe spécifique
        List<Group> userGroupList = [SELECT Id, Type, DeveloperName, RelatedId FROM Group WHERE DeveloperName = 'Utilisateurs_pilote'];

        //Ajout de l'utilisateur RV en tant que membre du groupe
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = userTestVendeur.Id;
        grpMem1.GroupId = userGroupList[0].Id;
        Insert grpMem1;

        System.runAs(userTestVendeur){
            // Création enregistrement
            defaultSectorisation = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
            Account B2C1 = createAccountB2C();
            List<Account> accounts = new List<Account>();
            accounts.add(B2C1);
            insert accounts;
            Map<Id, Account> accountMap = new Map<Id, Account>((List<Account>) SchemaUtils.executeQuery('Account', IDUtils.getIDs(accounts)));
            B2C1 = accountMap.get(B2C1.id);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
            Opportunity projet = Utils_Test.createOpportunity(B2C1, null, chantier, true);

            Test.startTest();

            // Création
            Event event = Utils_Test.createEvent(Constants.EVENT_TYPE_R1 ,rtRDV,projet.id,B2C1.PersonContactId,null, Constants.StatutEventPris, true);

            Test.stopTest();
        }
    }

    @isTest 
    static void test_eventProspection() {
        defaultSectorisation = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
        Account B2C1 = createAccountB2C();
        List<Account> accounts = new List<Account>();
        accounts.add(B2C1);
        insert accounts;

        Map<Id, Account> accountMap = new Map<Id, Account>((List<Account>) SchemaUtils.executeQuery('Account', IDUtils.getIDs(accounts)));
        B2C1 = accountMap.get(B2C1.id);

        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
        Opportunity projet = Utils_Test.createOpportunity(B2C1, chantier, true);

        Test.startTest();

        Event event = createProspectionEvent('Cours Mirabeau', '13100', 'Aix en Provence', projet, B2C1);
        Event event2 = createProspectionEvent(null, null, null, projet, B2C1);
        Event event3 = createProspectionEvent(null, null, null, null, B2C1);
        event3.nbBAL50__c = 10;
        event3.nbTAP51__c = 15;

        insert new Event[]{event, event2, event3};

        event.rue__c = '8 Cours Mirabeau';
        update event;

        try {
            delete event3;
        } catch(Exception ex) {} // Catch 'vous n'avez pas les droits de suppression

        Test.stopTest();
    }

    @isTest 
    static void test_ChangerOwnerTA() {
        User userTA = Utils_Test.createCallUser();
        User uRVCaen = Utils_Test.createRVUser('DR123', 'DV123', 'M123',null);
        UserRole CaenRole = [Select Id from UserRole where Name Like '%- REF - %' LIMIT 1];
        uRVCaen.UserRoleId = CaenRole.Id;
        update uRVCaen;

        System.runAs(userTA) {
            // Création enregistrement utile
            Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
            Account acc = Utils_Test.createAccount('Account UN', 'test', 'test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
            update chantier;

            acc = [Select PersonContactId From Account Where Id =:acc.Id];
            Event event = Utils_Test.createEvent(Constants.EVENT_TYPE_R1,rtRDV,opp.id,acc.PersonContactId,null,'Effectué', false);

            Test.startTest();
            insert event;
            Test.stopTest();
        }
    }

    @isTest 
    static void test_ChangerOwnerTAUsingRole() {
        // Création du call user
        User userTA = Utils_Test.createAdminUser();

        
        UserRole CaenRole = [SELECT Id FROM UserRole WHERE Name LIKE '%- REF - %' LIMIT 1];
        User uRVCaen = Utils_Test.createRVUser('DR123', 'DV123', 'M123',CaenRole.Id);
        
        // création des roles Magasin et de l'utilisateur associé
        UserRole magRefRole = new UserRole(DeveloperName = 'Role_Ref_magasin', Name = 'TestMag2 - REF - Test');
        insert magRefRole;
        UserRole magRole = new UserRole(DeveloperName = 'Role_magasin', Name = 'TestMag2 - MAG - Test', parentRoleId = magRefRole.Id);
        insert magRole;

        Utils_Test.createVendeurUser('DR1234', 'DV1234', 'TestMag2', magRefRole.Id, true);
        
        Id entId = [SELECT Id FROM ACCOUNT WHERE KparKReference__c = 'TestMag2' LIMIT 1].Id;

        System.runAs(userTA) {
            PassiveContactRecipient__c passiveContact = Utils_Test.createPassiveContactRecipient(entId, 'REF', Date.today(), true);
            // Création enregistrement utile
            Sectorisation__c secto = Utils_Test.createSectorisation('TestMag2', 'Test_Magasin', 'D123', 'Depot 123', true);
            Account acc = Utils_Test.createAccount('Account UN', 'test', 'test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.salesEntity__c = entId;
            chantier.sectorisation__c = secto.Id;
            insert chantier;
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

            acc = [Select PersonContactId From Account Where Id =:acc.Id];
            Event event = Utils_Test.createEvent(Constants.EVENT_TYPE_R1,rtRDV,opp.id,acc.PersonContactId,uRVCaen.Id,'Effectué', false);

            Test.startTest();
            insert event;
            Test.stopTest();
        }
    }

    private static Account createAccountB2C() {
        Account account = Utils_Test.createAccount('Nom', 'Prénom', 'test@kpark.fr', rtB2C,'Email',false);
        account.personHomePhone = '010203ADGJ';
        account.personMobilePhone = '060203ADGJ';
        account.personOtherPhone = '010204TEST';
        account.phone = '010204MPTW';
        account.fax = '010204MPTW';
        account.Localisation__Latitude__s = 0;
        account.Localisation__Longitude__s = 0;
        account.iris__c = defaultSectorisation.iris__c;

        System.assertNotEquals(null, account.iris__c);

        return account;
    }

    private static Event createProspectionEvent(String rue, String codePostal, String ville, Opportunity opportunity, Account demandeur) {
        Event event = Utils_Test.createEvent('Prospection physique', rtProspection, opportunity == null ? null : opportunity.Id, demandeur.PersonContactId, null, 'Effectué', false);
        event.rue__c = rue;
        event.codePostal__c = codePostal;
        event.ville__c = ville;
        return event;
    }
}