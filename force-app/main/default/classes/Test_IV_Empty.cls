//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_Empty
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 01/09/2019
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_Empty {
    private static final Id accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String RT_RECLAMATIONID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);

    @testSetup static void setup() {

        // Création Compte, Chantier
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',true);
        Chantier__c cha = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Case caseTest1 = Utils_Test.createCase(RT_RECLAMATIONID,acc,cha.Id,true);

    }

    @isTest
    private static void test_IVEmpty() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);
    
        System.runAs(user) {

            Test.startTest();
            
            // Récupération contrats 
            List<Case> caseList = [SELECT Id FROM Case];
            // Appel méthode d'envoi
            IV_Empty.noActionsMethod(caseList);

            Test.stopTest();
        }
    }
}