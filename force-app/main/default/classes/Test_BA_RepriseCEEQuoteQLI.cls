//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_RepriseCEEQuoteQLI
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/07/2018
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --

@isTest
private class Test_BA_RepriseCEEQuoteQLI {
    private static final Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    
    static testMethod void testSObjetcPurge() {
        // Récupération Record Type
        String accPersoRecordType = DAL.getRecordTypeIdByDevName(Constants.ACCOUNT_PERSO_RT);

        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',true);
        //Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        //insert chantier;
        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Opportunity projet = Utils_Test.createOpportunity(acc, null, chantier, true);
        Opportunity prj = [SELECT Id, Account.contactParDefaut__c FROM Opportunity];

        Event event = Utils_Test.createEvent('R1',rtRDV,projet.id,prj.Account.contactParDefaut__c,null,'Effectué', false);
        event.resultatDuRDV__c = null;
        insert event;
    
        Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);

        test.startTest();

        QuoteLineItem quoteLine = createQuoteLine(quote);
        quoteLine.eligibleCEE__c = TRUE;
        insert quoteLine; // A configurer

        BA_RepriseCEEQuoteQLI batch = new BA_RepriseCEEQuoteQLI();
        database.executebatch(batch);
        //system.assertEquals('Name0', lstChantier[0].Name);
        test.stopTest();
    }
    
    private static QuoteLineItem createQuoteLine(Quote quote) {        
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 1, 1.0, 1.0, prod, false);
        return line;
    }
    
}