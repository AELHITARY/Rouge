//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_CTISearchPageController
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 17/10/2019
//-- Version     : 1.0
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_CTISearchPageController {

    @isTest static void test_CTISearchPage_oneContact() {
        // Creation user de test
        User testUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);

        System.runAs(testUser) {    
            Id accountRecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            Account accountTest = Utils_Test.createAccount('APEX1', 'Account TEST', 'test1@apex.salesforce.com', accountRecordTypeId, 'Email',true);
            accountTest.Phone = '0123456789';
            update accountTest;

            Test.startTest();
            // Numéro avec un seul contact
            PageReference pageRef = Page.CTISearchPage;
            Test.setCurrentPage(pageRef);  
            ApexPages.currentPage().getParameters().put('Call_Folder_ID', '0000000000');   
            ApexPages.currentPage().getParameters().put('Phone_number', '0123456789');       
            CTISearchPageController ctrl = new CTISearchPageController();
            Pagereference nextPage = ctrl.CTIScreenPop(); 
            Test.stopTest();

            // Unit Test
            system.AssertNotEquals(null, nextPage);
        }
    }

    @isTest static void test_CTISearchPage_multipleContact() {
        // Creation user de test
        User testUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);

        System.runAs(testUser) {    
            Id accountRecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
            Account accountTest = Utils_Test.createAccount('APEX1', 'Account TEST', 'test1@apex.salesforce.com', accountRecordTypeId, 'Email',true);
            accountTest.Phone = '0123456789';
            update accountTest;
            Account accountTest1 = Utils_Test.createAccount('APEX2', 'Account TEST', 'test2@apex.salesforce.com', accountRecordTypeId, 'Email',true);
            accountTest1.Phone = '0123456789';
            update accountTest1;

            Test.startTest();
            // Numéro avec un seul contact
            PageReference pageRef = Page.CTISearchPage;
            Test.setCurrentPage(pageRef);  
            ApexPages.currentPage().getParameters().put('Call_Folder_ID', '0000000000');   
            ApexPages.currentPage().getParameters().put('Phone_number', '0123456789');       
            CTISearchPageController ctrl = new CTISearchPageController();
            Pagereference nextPage = ctrl.CTIScreenPop(); 
            Test.stopTest();

            // Unit Test
            system.AssertNotEquals(null, nextPage);
        }
    }

    @isTest static void test_CTISearchPage_noContact() {
        // Creation user de test
        User testUser = Utils_Test.createUser(true, 'TAPEX', 'TestAPEXUserName@test.sfd.test', 'TestAPEXLastName', 'TestAPEXFirstName', null, null);

        System.runAs(testUser) {    
    
            Test.startTest();
            // Pas de numéro
            PageReference pageRef = Page.CTISearchPage;
            Test.setCurrentPage(pageRef);  
            ApexPages.currentPage().getParameters().put('callerId', '0000000000');   
            ApexPages.currentPage().getParameters().put('Phone_number', '0123456789');       
            CTISearchPageController ctrl = new CTISearchPageController();
            Pagereference nextPage = ctrl.CTIScreenPop(); 
            Test.stopTest();

            // Unit Test
            system.AssertNotEquals(null, nextPage);
        }
    }

}