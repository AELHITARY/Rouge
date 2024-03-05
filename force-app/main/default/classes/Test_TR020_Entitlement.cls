//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR020_Entitlement
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 27/10/2021
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR020_Entitlement {
    
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup static void setup() {
        
        RecordType RTDevName = [SELECT Id, Name, DeveloperName FROM RecordType WHERE DeveloperName ='PersonalAccount'];
        // Creation Record
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
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        Order newOrder = new Order(Name = 'Par Défaut', Status = 'Registered', AccountId = accountTest.Id, EffectiveDate = Date.today(), PriceBook2Id = pBook.Id);
        newOrder.salesEntity__c = entite.Id;
        newOrder.serviceEntity__c = entite.Id;
        insert newOrder;
        OrderItem newOrderItem = new OrderItem(OrderId = newOrder.Id, UnitPrice = 0, Quantity = 1, status__c = 'Enregistré', productType__c = 'Carpentry',
                                               stageName__c = 'Enregistrement', PriceBookEntryId=pbEntry.Id, confirmationDate__c = date.today());
        insert newOrderItem;
        Asset newAsset = new Asset(Name = 'Asset Test', customerOrder__c = newOrder.Id, orderItem__c = newOrderItem.Id, AccountId = accountTest.Id);
        insert newAsset;
        Entitlement newEntitlement = new Entitlement(Name = 'Entitlement Test', AccountId = accountTest.Id, AssetId = newAsset.Id);
        insert newEntitlement;
        
        
    }

    @isTest static void test_deleteAutorisation() {
        User userTest = TestCommon.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null);

        system.runAs(userTest) {
            // Récupération données
            Order newOrder = [SELECT Id, suspendDate__c FROM Order LIMIT 1];
            Asset newAsset = [SELECT Id, isLocked__c FROM Asset LIMIT 1];
            Entitlement newEntitlement = [SELECT Id FROM Entitlement LIMIT 1];

            newOrder.suspendDate__c = date.today();
            update newOrder;
            Test.startTest();
            
            delete newEntitlement;
            
            Test.stopTest();

        }
    }
}