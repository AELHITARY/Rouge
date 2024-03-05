//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_GDPRChantierExpDate
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 01/11/2018
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_GDPRChantierExpDate {

    @testSetup static void setup() {
        // Récupération des types d'enregistrement
        Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true); 
        // Création d'un compte
        Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', rtB2C, 'FAX', true);
        // Création chantiers
        Utils_Test.createChantier('Chantier 1', account.Id, true);
        Utils_Test.createChantier('Chantier 2', account.Id, true);
    }

    @isTest static void test_Schedule_GDPRChantierExpDate() {
        // Exécution du test
        Test.StartTest();

        String jobId = system.schedule('BA Chantier TEST', '0 0 * * * ?', new Schedule_GDPRChantierExpDate() );
        BA_GDPRChantierExpDate ba = new BA_GDPRChantierExpDate();
        Database.executeBatch(ba);

        Test.stopTest();
    }
}