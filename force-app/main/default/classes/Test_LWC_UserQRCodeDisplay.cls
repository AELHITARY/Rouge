//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_UserQRCodeDisplay
//-- Modifie par : SOPRA STERIA 
//-- Modifie le  : 05/05/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_UserQRCodeDisplay {

    @isTest
    private static void testGetUserData() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            // Récupération enregistrement du devis 
            Test.startTest();
            
            try{
                LWC_UserQRCodeDisplay.getUserData(user.Id);
            }
            catch(Exception e){}

            Test.stopTest();
        }
    }
    @isTest
    private static void testGetMagasinsName() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.codeMagasin__c='MAG';
        update user;
        
        System.runAs(user){
            // Création magasin
            PropertiesUtils.setStringValue('fsl.operatingHours.defaultName', 'Par Défaut');
            Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
            Account magasinA = Utils_Test.createEntity('MAG', 'MAG', Date.today(), '0123456789', refMag.Id, true);
            Test.startTest();
            
            try{
                LWC_UserQRCodeDisplay.getMagasinsName(user.Id);
            }
            catch(Exception e){}

            Test.stopTest();
        }
    }
    @isTest
    private static void testGetMagasinData() {
        // Création utilisateur
        Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.codeMagasin__c='MAG';
        update user;
        
        System.runAs(user){
            // Création magasin
            PropertiesUtils.setStringValue('fsl.operatingHours.defaultName', 'Par Défaut');
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
            Account magasinA = Utils_Test.createEntity('MAG', 'MAG', Date.today(), '0123456789', refMag.Id, true);
            Test.startTest();
            
            try{
                LWC_UserQRCodeDisplay.getMagasinData('MAG');
                LWC_UserQRCodeDisplay.getMagasinData('NULL');
            }
            catch(Exception e){}

            Test.stopTest();
        }
    }
}