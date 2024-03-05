//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_CTILightningSearchController 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 16/11/2020
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_CTILightningSearchController {
    
    @isTest 
    static void test_CTILightningSearchPage_oneContact() {
        // Creation user de test
        User testUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);
        
        System.runAs(testUser) {  
            Id accountRecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            Account accountTest = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accountRecordTypeId, 'Email',false);
            accountTest.Phone = '0123456789';
            insert accountTest;
            
            // Rends les comptes visible dans la requête SOSL
            Test.setFixedSearchResults(new List<STring>{accountTest.Id});
            
            Test.startTest();
            
            // Numéro avec un seul contact    
            CTILightningSearchController ctrl = new CTILightningSearchController();
            system.assertNotEquals(null, ctrl.SearchRecords('', '', '0123456789', '0000000000','', '', '', ''));
            
            Test.stopTest();
        }
    }
    
    @isTest static void test_CTILightningSearchPage_multipleContact() {
        // Creation user de test
        User testUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);
        
        System.runAs(testUser) {  
            Id accountRecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            Account accountTest = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accountRecordTypeId, 'Email',false);
            accountTest.Phone = '0123456789';
            insert accountTest;
            Account accountTest1 = Utils_Test.createAccount('Account DD', 'testDD', 'test2@test.fr', accountRecordTypeId, 'Email',false);
            accountTest1.Phone = '0123456789';
            insert accountTest1;
            
            // Rends les comptes visible dans la requête SOSL
            Test.setFixedSearchResults(new List<STring>{accountTest.Id, accountTest1.Id});
            
            Test.startTest();
            
            // Numéro avec un plusieurs contacts
            CTILightningSearchController ctrl = new CTILightningSearchController();
            system.assertNotEquals(null, ctrl.SearchRecords('', '', '0123456789', '0000000000','', '', '', ''));
            
            Test.stopTest();
        }
    }
    
    @isTest static void test_CTILightningSearchPage_noContact() {
        // Creation user de test
        User testUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);
        
        System.runAs(testUser) {  
            
            Test.startTest();
            
            // Pas de numéro
            CTILightningSearchController ctrl = new CTILightningSearchController();
            system.assertNotEquals(null, ctrl.SearchRecords('', '', '0123456789', '0000000000','', '', '', ''));
            
            Test.stopTest();
        }
    }
    
    @isTest static void test_CTILightningSearchPage_devis() {
        // Creation user de test
        User testUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);
        
        System.runAs(testUser) {  
            // Création Account 
            Id accountRecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            Account accountTest = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accountRecordTypeId, 'Email',true);
            
            // Rends les comptes visible dans la requête SOSL
            Test.setFixedSearchResults(new List<STring>{accountTest.Id});
            
            // Creation devis
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,true);
            Opportunity projet = Utils_Test.createOpportunity(accountTest, null, chantier, true);
            Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            
            Test.startTest();
            
            // Recherche devis
            CTILightningSearchController ctrl = new CTILightningSearchController();
            system.assertNotEquals(null, ctrl.SearchRecords('', '', '0123456789', quote.Id,'', '', '', ''));
            
            Test.stopTest();
        }
    }
}