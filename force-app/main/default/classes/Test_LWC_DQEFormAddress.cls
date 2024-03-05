//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_DQEFormAddress
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/08/2020
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_DQEFormAddress
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_DQEFormAddress {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id accProRT = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_PRO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

        // Création Sectorisation
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        Sectorisation__c sect2 = Utils_Test.createSectorisation(magCode, 'Magasin Test', 'D123', 'Depot 123', true);

        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        List<Account> accList = new List<Account>();
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
        accList.add(a);
        Account c = Utils_Test.createAccountPro('Dupont Jeanne','0123456789', accProRT, contact.Id,false);
        accList.add(c);
        insert accList;   
    }

    @isTest
    private static void testAccountPerso() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE IsPersonAccount = true];

            Test.startTest();
            
            LWC_DQEFormAddress.modifyRecordInformation('Account', acc.Id, 'Test rue', 'Test ville', 'Test region',
                                                    'Test code', 'FRANCE', 10, 10, '', 1);

            Test.stopTest();
        }
    }

    @isTest
    private static void testAccountPro() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE IsPersonAccount = false];
            
            Test.startTest();
            
            LWC_DQEFormAddress.modifyRecordInformation('Account', acc.Id, 'Test rue', 'Test ville', 'Test region',
                                                    'Test code', 'FRANCE', 10, 10, '', 1);

            Test.stopTest();
        }
    }

    @isTest
    private static void testChantier() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE IsPersonAccount = true];
        
            // Création d'un chantier        
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);
            
            Test.startTest();
            
            LWC_DQEFormAddress.modifyRecordInformation('Chantier__c', chantier.Id, 'Test rue', 'Test ville', 'Test region',
                                                    'Test code', 'FRANCE', 10, 10, '', 1);

            Test.stopTest();
        }
    }

    @isTest
    private static void testEntityVersion() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = [SELECT Id FROM Account WHERE IsPersonAccount = true];
        
            // Création entite
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
            Account ent = Utils_Test.createEntity('Magasin 123', 'MAG123', Date.today(), '0123456789', refMag.Id, true);   
            EntityVersion__c entVer = [SELECT Id FROM EntityVersion__c LIMIT 1];
            
            Test.startTest();
            
            LWC_DQEFormAddress.modifyRecordInformation('EntityVersion__c', entVer.Id, 'Test rue', 'Test ville', 'Test region',
                                                    'Test code', 'FRANCE', 10, 10, '', 1);

            Test.stopTest();
        }
    }

    @isTest
    private static void testCollaborator() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Collaborator__c collab = new Collaborator__c();
            collab.startDate__c = Date.today();
            collab.firstname__c = 'first';
            collab.Name = 'collaborator';
            collab.lastName__c = 'collaborator';
            collab.reference__c = 'sgid1';
            insert collab;
            
            Test.startTest();
            
            LWC_DQEFormAddress.modifyRecordInformation('Collaborator__c', collab.Id, 'Test rue', 'Test ville', 'Test region',
                                                    'Test code', 'FRANCE', 10, 10, '', 1);

            Test.stopTest();
        }
    }    

    @isTest
    private static void testExecuteDQERequest() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){

            Test.startTest(); 
            
            Map<String, String> params = new Map<String, String>();
            params.put('Adresse', '1 cours mirabeau 13100 AIX EN PROVENCE');
            params.put('Pays', 'FRA');
            LWC_DQEFormAddress.executeDQERequest(params, 'SINGLEV2');

            Test.stopTest();
        }
    }
}