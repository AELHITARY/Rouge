//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_OrderNonCompliance
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 16/06/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_OrderNonCompliance {

    @isTest 
    static void test_TR020_OrderNonCompliance_applyUpdateRules() {
        User uCurrentForecastUser = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null);
        uCurrentForecastUser.ByPassWorkflowRule__c = false;
        update uCurrentForecastUser;
        RecordType RTDevName = [SELECT Id, Name, DeveloperName FROM RecordType WHERE DeveloperName ='PersonalAccount'];
        
        System.runAs(uCurrentForecastUser){
            Account accountTest = new Account(Salutation = 'M.',
                                              FirstName = 'name',
                                              LastName = 'name',
                                              RecordTypeId = RTDevName.Id,
                                              Canalprefere__c = 'Email',
                                              PersonMailingPostalCode='12345',
                                              PersonMailingCity='City123',
                                              PersonMailingCountry='Country123',
                                              PersonEmail = 'test@test.fr',
                                              AccountSource = 'CCM');
            insert accountTest;
            PriceBook2 pBook = new PriceBook2(Name ='Test');
            insert pBook;
            Product2 product = new Product2(Name = 'Test');
            insert product;
            PriceBookEntry pbEntry = new PriceBookEntry(UnitPrice = 0, PriceBook2Id = pBook.Id, Product2Id = product.Id);
            insert pbEntry;
            Order newOrder = new Order(Name = 'Par Défaut', Status = 'Registered', AccountId = accountTest.Id, EffectiveDate = Date.today(), PriceBook2Id = pBook.Id);
            insert newOrder;
            String oncRT = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Instance');
            OrderNonCompliance__c newOrderNonCompliance = Utils_Test.createOrderNonCompliance('Test', newOrder.Id, oncRT, true);
            newOrderNonCompliance.closeDate__c = Date.today();
            update newOrderNonCompliance;
                
            Test.startTest();
            system.debug('####### status : '+newOrderNonCompliance.Status__c);
            Test.stopTest();
        }
        
    }
}