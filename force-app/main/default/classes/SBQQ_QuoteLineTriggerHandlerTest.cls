/**
* Created by MCA on 15/11/2020.
 */

@IsTest
private class SBQQ_QuoteLineTriggerHandlerTest {
    @IsTest
    static void testBehavior() {

        Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        String customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', 'CustomerOrder');
        String providerOrderRTId = DAL.getRecordTypeIdByDevName('Order', 'ProviderOrder');
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            list <Option__c> optionList = new list<Option__c>();

            PriceBook2 pBook = new PriceBook2(Name ='Test');
            insert pBook;
            Product2 product = new Product2(Name = 'Test');
            insert product;
            PriceBookEntry pbEntry = new PriceBookEntry(UnitPrice = 0, PriceBook2Id = pBook.Id, Product2Id = product.Id);
            insert pbEntry;

            Product2 product2 = new Product2(Name = 'Test2');
            insert product2;
            PriceBookEntry pbEntry2 = new PriceBookEntry(UnitPrice = 0, PriceBook2Id = pBook.Id, Product2Id = product2.Id);
            insert pbEntry2;

            // Création enregistrement utile
            Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            Account acc = Utils_Test.createAccount('Account UN', 'test', 'test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

            // Creation devis
            SBQQ__Quote__c devis = Utils_TesT.createCPQQuote ('Test Quote', null, opp, null, Date.today(), 1000, 10, 'FOIRE', null, true);

            // Ligne de devis et produit
            SBQQ__QuoteLine__c qli = Utils_Test.createCPQQuoteLineItem(devis.Id, 50, 50, 1, product, true);


            Order newOrder = new Order(Name = 'Par Défaut', Status = 'Registered', AccountId = acc.Id, EffectiveDate = Date.today(), PriceBook2Id = pBook.Id, RecordTypeId = customerOrderRTId);
            insert newOrder;

            OrderItem newOrderItem = Utils_Test.createOrderItem(newOrder.Id, pbEntry.Id, null, null, true);
            Asset newAsset = new Asset(customerOrder__c = newOrder.Id, Name = 'Test', AccountId = acc.Id, orderItem__c = newOrderItem.Id);
            insert newAsset;

            qli.AmendedOrderProduct__c = newOrderItem.Id;
            update qli;

            Test.startTest();

            delete qli;

            Test.stopTest();

        }

    }
}