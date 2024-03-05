//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_QA_QuoteProcessCommissions
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_QA_QuoteProcessCommissions {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void testSetup() {
        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        refList.add(refDep);
        refList.add(refMag);
        insert refList;
        // Création entite     
        List<Account> accList = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        //Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(accountTest);
        insert accList;
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c = secto.Id;
        chantier.heatingMode__c = 'Individuel Electrique';
        insert chantier;
        // Opportunity
        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
    }

    @isTest
    static void testCPQ() {

        Test.startTest();

        // Création enregistrements pour devis
        System.debug('Creation devis');
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        // Creation devis dont le user n'a pas de fiche collaborateur (pour sortir rapidement du traitement des commissions)
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp, Date.today(), 2, true);

        System.enqueueJob(new QA_QuoteProcessCommissions(new List<Id>{cpqQuote.Id}));

        Test.stopTest();
    }

    @isTest
    static void testSales() {

        Test.startTest();

        // Création enregistrements pour devis
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        
        System.enqueueJob(new QA_QuoteProcessCommissions(new List<Id>{quote.Id}));

        Test.stopTest();
    }
}