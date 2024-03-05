//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_caseTemplt
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/09/2020
//-- Version     : 1.0
//-- * 
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_caseTemplt {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);   
    private static final Id RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);

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
    static void testCase() {
        
        Test.startTest();    

        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Chantier__c cha = [SELECT Id FROM Chantier__c LIMIT 1];  

        // Case
        Case caseTest = Utils_Test.createCase(RT_PNC_PROVIDERID, acc, cha.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
        insert caseTest;

        // Fichier
        Utils_Test.createFile('File.jpg', caseTest.Id, EncodingUtil.base64Decode('TEST'), true);

        // ProviderReinvoice    
        ProviderReInvoiceItem__c proRe = new ProviderReInvoiceItem__c(ProviderProductNonCompliance__c = caseTest.Id, demandedAmount__c=100);
        insert proRe;

        Ctrl_caseTemplt ctrl = new Ctrl_caseTemplt();
        ctrl.showTable = true;
        ctrl.showAttachmentTable = true;
        ctrl.caseId = caseTest.Id;

        ctrl.getncps();
        ctrl.getcases();
        ctrl.getattachments();

        Test.stopTest();
    }
}