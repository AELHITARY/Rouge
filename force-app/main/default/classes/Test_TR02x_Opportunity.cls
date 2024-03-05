//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Opportunity
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/11/2022
//-- Version     : 1.3
//-- * RQM-74 : Ajout test pour GCLID
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_Opportunity {
    private static final Id rtB2B = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);            
        // Création enregistrements utile
        Account B2C1 = Utils_Test.createAccount('Nom', 'Prénom', 'test@kpark.fr', rtB2C,'Email',false);
        B2C1.personHomePhone = '010203ADGJ';
        B2C1.personMobilePhone = '060203ADGJ';
        B2C1.personOtherPhone = '010204TEST';
        B2C1.phone = '010204MPTW';
        B2C1.fax = '010204MPTW';
        B2C1.Localisation__Latitude__s = 0;
        B2C1.Localisation__Longitude__s = 0;
        B2C1.iris__c = sect.iris__c;
        System.assertNotEquals(null, B2C1.iris__c);

        Account B2C2 = Utils_Test.createAccount('Nom Deux', 'Prénom Deux', 'test2@kpark.fr', rtB2C,'Email',false);
        B2C2.personHomePhone = '010203ADGJ';
        B2C2.personMobilePhone = '060203ADGJ';
        B2C2.personOtherPhone = '010204TEST';
        B2C2.phone = '010204MPTW';
        B2C2.fax = '010204MPTW';
        B2C2.Localisation__Latitude__s = 0;
        B2C2.Localisation__Longitude__s = 0;
        B2C2.iris__c = sect.iris__c;
        System.assertNotEquals(null, B2C2.iris__c);

        List<Account> accounts = new List<Account>();
        accounts.add(B2C1);
        accounts.add(B2C2);
        insert accounts;
    }

    @isTest 
    static void test_Opportunity() {
        User user = Utils_Test.createUser(false, 'testmlg3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', null, null);

        System.runAs(user) {
            // Récupération des comptes
            Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
            Account B2C2 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test2@kpark.fr'))[0];
            // Création chantier
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);

            Test.startTest();

            Opportunity projet = Utils_Test.createOpportunity(B2C1, null, chantier, false);
            projet.couplePresent__c = 'Oui';
            projet.rappelProduitsQuantites__c = 'test';
            projet.objectionPrincipale__c = 'Autre';
            projet.mntPremiereProposition__c = 1;
            projet.mntDernierPrixLaisse__c = 10;
            projet.pctRemise__c = 10;
            insert projet;

            Opportunity projet2 = Utils_Test.createOpportunity(B2C1,B2C2,chantier,true);
            projet2.forcageEtape__c = 'Vendu';

            System.debug('#projet:'+projet.Id);

            
            //projet.tarif__c = 10;
            //projet.dateDernierRDV__c = System.now();

            update projet;

            delete projet;

            Test.stopTest();
        }
    }

    @isTest 
    static void test_OpportunityotherAccountType(){
        // Récupération des comptes
        Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
        Account B2C2 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test2@kpark.fr'))[0];
        
        Test.startTest();

        Account B2C3 = Utils_Test.createAccount('Nom trois', 'Prénom trois', 'test3@kpark.fr', rtB2C,'Email',false);
        Account B2C4 = Utils_Test.createAccount('Nom quatre', 'Prénom quatre', 'test4@kpark.fr', rtB2C,'Email',false);
        Account B2C5 = Utils_Test.createAccount('Nom cinq', 'Prénom cinq', 'test5@kpark.fr', rtB2C,'Email',false);
        Account B2C6 = Utils_Test.createAccount('Nom six', 'Prénom six', 'test6@kpark.fr', rtB2C,'Email',false);

        List<Account> accounts = new List<Account>();
        accounts.add(B2C3);
        accounts.add(B2C4);
        accounts.add(B2C5);
        accounts.add(B2C6);

        insert accounts;

        // Création chantier
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,B2C2.Id, B2C3.Id, B2C4.Id, B2C5.Id, B2C6.Id,true);

        //Test opportunity avec Account Autre propriétaire
        Opportunity projet = Utils_Test.createOpportunity('PRJ - TEST',B2C2, null, chantier, false);
        //Test opportunity avec Account locataire
        Opportunity projet2 = Utils_Test.createOpportunity('PRJ - TEST2', B2C3, null, chantier, false);
        //Test opportunity avec Account Autre locataire
        Opportunity projet3 = Utils_Test.createOpportunity('PRJ - TEST3', B2C4, null, chantier, false);
        //Test opportunity avec Account occupant
        Opportunity projet4 = Utils_Test.createOpportunity('PRJ - TEST4', B2C5, null, chantier, false);
        //Test opportunity avec Account Autre occupant
        Opportunity projet5 = Utils_Test.createOpportunity('PRJ - TEST5', B2C6, null, chantier, false);
        
        List<Opportunity> projets = new List<Opportunity>();
        projets.add(projet);
        projets.add(projet2);
        projets.add(projet3);
        projets.add(projet4);
        projets.add(projet5);

        insert projets;


        Test.stopTest();
    }

    @isTest 
    static void test_OpportunityChangeOwner() {
        User user = Utils_Test.createUser(false, 'testmlg3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', null, null);
        //User user = Utils_Test.createCallUser();
        User uRVCaen = Utils_Test.createRVUser('DR123', 'DV123', 'M123',null);
        UserRole CaenRole = [Select Id from UserRole where Name Like '%- REF %' LIMIT 1];
        uRVCaen.UserRoleId = CaenRole.Id;
        update uRVCaen;

        System.runAs(user) {
            // Récupération des comptes
            Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
            // Création chantier
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);
            // Création projet
            Opportunity projet = Utils_Test.createOpportunity(B2C1, null, chantier, true);

            Test.startTest();
            
            projet.OwnerId = uRVCaen.Id;
            update projet;

            Test.stopTest();
        }
    }

    @isTest 
    static void test_OpportunityWithGCLID() {
        User user = Utils_Test.createUser(false, 'testmlg3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', null, null);

        System.runAs(user) {
            // Récupération des comptes
            Account B2C1 = (Account)((List<SObject>)SchemaUtils.executeQuery('Account', 'PersonEmail', 'test@kpark.fr'))[0];
            // Création chantier
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', B2C1.Id,true);

            Test.startTest();

            system.debug('TEST');
            Opportunity projet = Utils_Test.createOpportunity(B2C1, null, chantier, false);
            projet.GCLID__c = 'TEST';
            insert projet;            
            // Mise à jour de l'étape à RDV
            projet.StageName = 'RDV';
            projet.forcageEtape__c = 'RDV';
            update projet;

            Test.stopTest();
            
            // TEST
            //projet = [SELECT Id, dateEnvoiAdwords__c FROM Opportunity WHERE Id = :projet.Id LIMIT 1];
            //system.assertNotEquals(null, projet.dateEnvoiAdwords__c);
        }
    }
}