//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl017_OverrideEditQli
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/06/2017
//-- Version     : 1.1
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl017_OverrideEditQli {
    private static final Id rtB2C = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup 
	static void setup() {        
		// Création des objets
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setStringValue('cee.codesDVElligible', 'DV0018;DV0019;DV0020;DV0068');
		Account acc = Utils_Test.createAccount('Account UN', 'test', 'test@test.fr', rtB2C, 'Email',true);
		Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
        chantier.codeDVReference__c = '1234';
        insert chantier;
		Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);
		// Creation devis
		Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
		// Ligne de devis et produit
		Product2 product = Utils_Test.createProduct('test', '1234');
        QuoteLineItem line = Utils_Test.createQuoteLineItem(devis.id, '2', 90, 150, 1, 1.0, 1.0, product, true);
    }

    @isTest 
	static void test_OverrideEditQli() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
		
		System.runAs(user){
			QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];			

			Test.startTest();
	        Apexpages.Standardcontroller stdCtrl = new Apexpages.Standardcontroller(qli);
	        Ctrl017_OverrideEditQli controller = new Ctrl017_OverrideEditQli(stdCtrl);
			Test.stopTest();

			// Vérification
	        system.assertNotEquals(null,controller.redirectToEditAll());
		}
	}
}