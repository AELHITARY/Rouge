//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR001_Options
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/10/2022
//-- Version     : 1.01
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR001_Options {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @isTest 
    static void test_TR001_Options() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        
        System.runAs(user){

            Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            Account acc = Utils_Test.createAccount('Account UN', 'test', 'test@test.fr', rtB2C, 'Email',true);
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
            Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
            // Creation devis
            Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            quote.source__c = 'BAL VENDEUR';
            insert quote;
            // Ligne de devis et produit
            Product2 product = Utils_Test.createProduct('test', '1234');
            QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 1, 1.0, 1.0, product, false);

            Test.startTest();

            list <Option__c> optionList = new list<Option__c>();
            Option__c op = new Option__c();
            op.Option__c = TestUtils.getNewReferentielOptions(2).Id;
            op.ligneDevis__c = line.Id;
            op.Valorisation__c = 100;
            optionList.add(op);
            System.debug('\n\n\n optionList'+optionList+'\n\n\n\n');
            TR001_Options.calculatePrice(optionList);
            op.Option__c = TestUtils.getNewReferentielOptions(3).Id;
            TR001_Options.calculatePrice(optionList);
            op.Option__c = TestUtils.getNewReferentielOptions(4).Id;
            TR001_Options.calculatePrice(optionList);
            op.Option__c = TestUtils.getNewReferentielOptions(5).Id;
            TR001_Options.calculatePrice(optionList);
            op.Option__c = TestUtils.getNewReferentielOptions(6).Id;
            TR001_Options.calculatePrice(optionList);
            op.Option__c = TestUtils.getNewReferentielOptions(7).Id;
            TR001_Options.calculatePrice(optionList);
            op.Option__c = TestUtils.getNewReferentielOptions(8).Id;
            TR001_Options.calculatePrice(optionList);

            Test.stopTest();

        }
    }
}