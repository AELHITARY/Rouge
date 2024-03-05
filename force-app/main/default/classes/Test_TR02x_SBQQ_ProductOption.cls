//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_SBQQ_ProductOption
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_TR02x_SBQQ_ProductOption {
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);

    @testSetup 
    static void testSetup() {   
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        PropertiesUtils.setBooleanValue('google.geocoder.enabled', true);
        PropertiesUtils.setStringValue('case.emailtemplate.commentPublique', 'Requete_Creation_commentaire_public');
        // Création Sectorisation
        UserRole roleMag = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name LIKE 'MAG%' AND Name LIKE '% - MAG - %' LIMIT 1];
        String magCode = roleMag.Name.substring(0,7);
        Sectorisation__c sect = Utils_Test.createSectorisation(magCode, 'Magasin Test', 'DEP123', 'Depot 123', false);
        //sect.emailResponsableDepot__c = 'testdepot@test.fr';
        //sect.emailDepot__c = 'testdepot@test.fr';
        sect.libelleDepot__c = 'TEST DEPOT';
        insert sect;

        // Création des comptes
        Account account = Utils_Test.createAccount('Test', 'test', 'test@salesforce.com', ACC_PERSO_RTID, 'FAX', true);

        // Création d'un chantier        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, false);
        chantier.codeMagasinTechnique__c = 'MAG001Test'; // Mise à jour localisation
        chantier.sectorisation__c = sect.Id;
        insert chantier;    
        
        // Création projet
        Opportunity opp = Utils_Test.createOpportunity('Test', account, null, chantier, true);
        
        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;

        // Creation produit Option
        SBQQ__ProductOption__c opt = new SBQQ__ProductOption__c();
        opt.SBQQ__ConfiguredSKU__c = prod.Id;
        opt.interventionDuration__c = 1;
        opt.SBQQ__Number__c = 1;
        opt.CPQID__c = 'TEST1';
        insert opt;
    }

    @isTest 
    static void testUpdateCaseItem() {         
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];
        SBQQ__ProductOption__c opt = [SELECT Id, interventionDuration__c FROM SBQQ__ProductOption__c LIMIT 1];

        Test.startTest();

        // Case
        Case caseTest = Utils_Test.createCase(RT_PNC_PROVIDERID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
        insert caseTest;

        // Case Item
        CaseItem__c caseItemTest = new CaseItem__c();
        caseItemTest.case__c = caseTest.Id;
        caseItemTest.productOption__c = opt.Id;
        caseItemTest.quantity__c = 1;
        caseItemTest.unit__c = 'UNIT';
        insert caseItemTest;

        // TEST
        opt.interventionDuration__c = 2;
        update opt;

        Test.stopTest();
    }
}