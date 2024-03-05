//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_AdwordsGenerateCSV 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 04/03/2019
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_AdwordsGenerateCSV {

    @testSetup static void setup() {
        Double longitude = 2.3354245000000446;
        Double latitude = 48.8807489;
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
                
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);
        
        // Création de comptes
        Account acc1 = Utils_Test.createAccount('Dupont', 'Jean', 'test@test.fr', accPersoRT, 'Piste', 'Email',false);
        acc1.Phone = '0123456789';
        acc1.Localisation__Latitude__s = latitude;
        acc1.Localisation__Longitude__s = longitude;
        insert acc1;

        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc1.Id,false);
        chantier.Localisation__Latitude__s = latitude;
        chantier.Localisation__Longitude__s = longitude;
        insert chantier;
        
        // Ajout projet avec GCLID
        Opportunity opp = Utils_Test.createOpportunity(acc1, chantier, false);
        opp.GCLID__c = 'Test';
        opp.dateEnvoiAdwords__c = Date.today();
        insert opp;        
    }

    @isTest 
    public static void test_GenerateCSV() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.RunAs(userTest) {
            // TEST
            Test.startTest();

            PageReference pageRef = Page.VF_AdwordsGenerateCSV ;
            Test.setCurrentPage(pageRef);
            Ctrl_AdwordsGenerateCSV ctrl = new Ctrl_AdwordsGenerateCSV();

            // Init CSV
            ctrl.init();

            Test.stopTest();
            
            // Vérification
            system.assertNotEquals(0, ctrl.csvRowValues1.size()); 
            system.assertEquals(0, ctrl.csvRowValues2.size()); 
            system.assertEquals(0, ctrl.csvRowValues3.size()); 
        }
    }
}