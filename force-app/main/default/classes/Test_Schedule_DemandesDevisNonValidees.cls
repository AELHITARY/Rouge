//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_DemandesDevisNonValidees
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 09/12/2015
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_DemandesDevisNonValidees {

    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup static void setup() {
        PropertiesUtils.setIntegerValue('demandededevis.delai.validation', 120);

        // Récupération des Record Type
        List<Import__c> importsToInsert = new List<Import__c>();

        RecordType rtImport = [SELECT id FROM RecordType WHERE developerName = 'importExterne' LIMIT 1];

        Import__c nouveau_compte1 = new Import__c(recordTypeId = rtImport.id, nomCompte__c = 'NOM1', prenomCompte__c = 'PRENOM1', civiliteCompte__c = 'M', rueCompte__c = '2 avenue des Champs Elysées',
                codePostalCompte__c = '75008', codePostalChantier__c = '75008', villeCompte__c = 'Paris', departementCompte__c = 'Île-de-France', departementChantier__c = 'Île-de-France',
                paysCompte__c = 'France', paysChantier__c = 'France', emailCompte__c = 'puser'+system.now().format('hhmmss')+'@testemail.com', telephoneDomicileCompte__c = '0100000001');

        Import__c nouveau_compte2 = new Import__c(recordTypeId = rtImport.id, nomCompte__c = 'NOM2', prenomCompte__c = 'PRENOM2', civiliteCompte__c = 'M', rueCompte__c = '4 avenue des Champs Elysées',
                codePostalCompte__c = '75008', codePostalChantier__c = '75008', villeCompte__c = 'Paris', departementCompte__c = 'Île-de-France', departementChantier__c = 'Île-de-France',
                paysCompte__c = 'France', paysChantier__c = 'France', emailCompte__c = 'puser'+system.now().format('hhmmss')+'@testemail.com', telephoneDomicileCompte__c = '0100000002');

        Import__c nouveau_compte3 = new Import__c(recordTypeId = rtImport.id, nomCompte__c = 'NOM3', prenomCompte__c = 'PRENOM3', civiliteCompte__c = 'M', rueCompte__c = '6 avenue des Champs Elysées',
                codePostalCompte__c = '75008', codePostalChantier__c = '75008', villeCompte__c = 'Paris', departementCompte__c = 'Île-de-France', departementChantier__c = 'Île-de-France',
                paysCompte__c = 'France', paysChantier__c = 'France', emailCompte__c = 'puser'+system.now().format('hhmmss')+'@testemail.com', telephoneDomicileCompte__c = '0100000003');

        Import__c nouveau_compte4 = new Import__c(recordTypeId = rtImport.id, nomCompte__c = 'NOM4', prenomCompte__c = 'PRENOM4', civiliteCompte__c = 'M', rueCompte__c = '8 avenue des Champs Elysées',
                codePostalCompte__c = '75008', codePostalChantier__c = '75008', villeCompte__c = 'Paris', departementCompte__c = 'Île-de-France', departementChantier__c = 'Île-de-France',
                paysCompte__c = 'France', paysChantier__c = 'France', emailCompte__c = 'puser'+system.now().format('hhmmss')+'@testemail.com', telephoneDomicileCompte__c = '0100000004');

        importsToInsert.add(nouveau_compte1);
        importsToInsert.add(nouveau_compte2);
        importsToInsert.add(nouveau_compte3);
        importsToInsert.add(nouveau_compte4);
        insert importsToInsert;
    }

    @isTest static void test_Schedule_DemandesDevisNonValidees() {
        // Exécution du test
        Test.StartTest();

        String jobId = system.schedule('Demandes de devis non validées TEST', '0 0 * * * ?', new Schedule_DemandesDevisNonValidees() );

        Test.stopTest();
    }
}