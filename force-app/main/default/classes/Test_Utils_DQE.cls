//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Utils_DQE
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/11/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Utils_DQE {
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
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, true);
        Utils_Test.createEntity('Magasin 123', 'MAG123', Date.today(), '0123456789', refMag.Id, true);   
        Utils_Test.createEntity('Depot 123', 'DEP123', Date.today(), '0123456789', refDep.Id, true);   
    }

    @isTest 
    static void testIrisRNVP() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            // Exécution du test
            Test.startTest();

            Utils_DQE.DQEIrisRNVP('Complement', '13100', 'adresse', 'lieudit', 'AIX', 'FRA');

            Test.stopTest();
        }
    }

    @isTest 
    static void testPostalCode() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            // Exécution du test
            Test.startTest();

            Utils_DQE.DQEPostalCode('13100', 'FRA');

            Test.stopTest();
        }
    }

    @isTest 
    static void testLongLat() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            // Exécution du test
            Test.startTest();

            Utils_DQE.DQELongLat('13100', '1', 'FRA');

            Test.stopTest();
        }
    }

    @isTest 
    static void testExecuteDQEAddressRequest() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            
            // Exécution du test
            Test.startTest();
    
            Map<String, String> params = new Map<String, String>();
            params.put('Adresse', '1 cours mirabeau 13100 AIX EN PROVENCE');
            params.put('Pays', 'FRA');
            Utils_DQE.executeDQEAddressRequest('SINGLEV2', params);

            Test.stopTest();
        }
    }

    @isTest 
    static void testLookupAccount() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',true);
            
            // Exécution du test
            Test.startTest();
            
            Utils_DQE.DQELookupAccount('13100', 'Dupont', 'Jean', 'adresse', 'AIX', 'Dupont Jean', true, 
                                        'test@test.fr', '0123456789', '0611234567', '0123456789', '0123456789', acc.Id);

            Test.stopTest();
        }
    }

    @isTest 
    static void testLookupChantier() {
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, true);   
            
            // Exécution du test
            Test.startTest();
            
            Utils_DQE.DQELookupChantier('adresse', '13100', 'AIX', 'complement', 2, chantier.Id);

            Test.stopTest();
        }
    }


}