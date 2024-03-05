//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Utils_Odigo 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 16/11/2021
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Utils_Odigo {
    private static final Id accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        // Création propriété global        
        PropertiesUtils.setBooleanValue('prosodie.odigo.enabled', true);
        PropertiesUtils.setStringValue('prosodie.odigo.api.userUID', 'TEST');
        PropertiesUtils.setStringValue('prosodie.odigo.api.appUID', 'TEST');
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

        // Création Sectorisation
        // Code Magasin = MAG001Test
        // Libellé Magasin = MAG Test
        Utils_Test.createSectorisation('MAG001Test', 'MAG Test', 'DEP001Test', 'DEP TEST',true);

        // Création Compte, Chantier
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',false);
        acc.Phone = '0123456789';
        acc.PersonHomePhone = '0123456789';
        acc.PersonMobilePhone = '0623456789';
        insert acc;
    }

    @isTest
    private static void testCallAPI() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);
    
        System.runAs(user) {
            Account acc = [SELECT Id, Phone, telephoneDomicile__c, telephoneMobile__c, autreTelephone__c FROM Account LIMIT 1];

            Test.startTest();
            
            // Appel API
            Utils_Odigo.getCampaignIdByLabel('TEST');

            List<Utils_Odigo.WebCallBackContactList> callbackList = new List<Utils_Odigo.WebCallBackContactList>();
            Utils_Odigo.WebCallBackContactList callBack = Utils_Odigo.configureCallback(acc); 
            callbackList.add(callBack);
            Utils_Odigo.uploadCallback(1, callbackList);

            Test.stopTest();
        }
    }

    @isTest
    private static void testOtherMethod() {
        // Création utilisateur
        User user = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null,null);
    
        System.runAs(user) {

            Test.startTest();
            
            Utils_Odigo.isCallBackAuthorized();
            /*
            Utils_Odigo.getUser();
            Utils_Odigo.checkCallback(1, 'TEST');
            Utils_Odigo.checkCallback(2, 'TEST');
            Utils_Odigo.checkCallback(3, 'TEST');
            Utils_Odigo.checkCallback(4, 'TEST');
            Utils_Odigo.checkCallback(5, 'TEST');
            Utils_Odigo.checkCallback(33, 'TEST');
            */

            Test.stopTest();
        }
    }
}