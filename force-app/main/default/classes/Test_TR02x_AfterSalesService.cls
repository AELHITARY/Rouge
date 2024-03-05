//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_AfterSalesService
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 09/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_AfterSalesService {
    private static final String RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    private static final String RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final String RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);
    
    @testSetup 
    static void setup() {
        // Création compte
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', RT_ACC_PERSO, 'Email',true);
        // Création d'un chantier
        Chantier__c chant = Utils_Test.createChantier('test',a.Id,true);
    }

    @isTest
    private static void testUpdate(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];

            Test.startTest();

            // Create Piece
            AfterSalesService__c sav = new AfterSalesService__c(workSite__c = chantier.Id);
            insert sav;
            sav.description__c = 'TEST';
            sav.newStatusCaseCount__c  = 2;
            update sav;

            Test.stopTest();
        }
    }
}