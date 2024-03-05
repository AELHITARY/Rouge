//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_RepriseDoublonCase
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 13/06/2019
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_BA_RepriseDoublonCase {

    @testSetup static void setup() {
        // Récupération des types d'enregistrement
        Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true); 
        // Création d'un compte
        Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', rtB2C, 'FAX', true);
        // Création chantiers
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, true);        
    }

    @isTest static void test_BA_RepriseChampsCase() {
        String RT_RECLAMATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Utils_Test.createCase(RT_RECLAMATIONID,acc,chantier.Id,true);
        Test.StartTest();
        Case cs = Utils_Test.createCase(RT_RECLAMATIONID,acc,chantier.Id,true);
        //Case csInfos = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        
        // Exécution du test
        
        Case cs2 = Utils_Test.createCase(RT_RECLAMATIONID,acc,chantier.Id,true);      
        cs2.Subject = 'Test pour la requete n°'+cs.CaseNumber+' créée';
        cs2.Description = 'Test à insérer en CaseComment';
        update cs2;

        BA_RepriseDoublonsCase ba= new BA_RepriseDoublonsCase();
        Database.executeBatch(ba);

        Test.stopTest();
    }
}