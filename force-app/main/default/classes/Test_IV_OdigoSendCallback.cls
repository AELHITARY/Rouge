//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_OdigoSendCallback 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 06/03/2018
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_OdigoSendCallback {
    private static final Id accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

        // Création Sectorisation
        // Code Magasin = MAG001Test
        // Libellé Magasin = MAG Test
        Utils_Test.createSectorisation('MAG001Test', 'MAG Test', 'DEP001Test', 'DEP TEST',true);

        // Création Compte, Chantier
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',false);
        acc.Phone = '0123456789';
        insert acc;
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

        // Création Contrats SAV, Pose et Metrage
        KContrat__c contratSAV = Utils_Test.createContrat('Contrat SAV', chantier.Id, acc.Id, '0001', true);
        
        // Création propriété global        
        PropertiesUtils.setBooleanValue('prosodie.odigo.enabled', true);
    }

    @isTest
    private static void test_SendSurvey() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);
    
        System.runAs(user) {

            Test.startTest();
            
            // Récupération contrats 
            List<KContrat__c> contratsList = [SELECT Id FROM KContrat__c];
            // Appel méthode d'envoi
            IV_OdigoSendCallback.sendSurveyCallBack(contratsList);

            Test.stopTest();
        }
    }

    @isTest
    private static void test_SendSurveyOpp() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);
    
        System.runAs(user) {

            Test.startTest();
            
            // Récupération contrats 
            List<Opportunity> oppList = [SELECT Id FROM Opportunity];
            // Appel méthode d'envoi
            IV_OdigoSendCallback_Opportunity.IV_OdigoSendCallback_Opportunity(oppList);

            Test.stopTest();
        }
    }
}