//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_Fusion
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2020
//-- Version     : 1.2
//-- * 1.2 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.1 : Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_Fusion { 

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = New Sectorisation__c (codeRegion__c='R123',libelleRegion__c='Région 123',
                                                    codeMagasin__c='M123',libelleMagasin__c='Magasin 123');
        insert sect;
    }

    @isTest 
    static void test_Fusion_account() {
        // Récupération Record Type
        Id rtPerson = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        // Création enregistrements utile
        Account acc1 = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtPerson, 'Email',true);
        Account acc2 = Utils_Test.createAccount('Account Deux', 'test', 'test2@test.fr', rtPerson, 'Email',true);
        Account accMerged = new Account();

        accMerged = Utils_Dedoublonnage.selectAccountValuesToMerge(acc1, acc1, acc2, acc2, true, 'Premier créé');
        accMerged = Utils_Dedoublonnage.selectAccountValuesToMerge(acc1, acc1, acc2, acc2, true, 'Dernier créé');
        accMerged = Utils_Dedoublonnage.selectAccountValuesToMerge(acc1, acc1, acc2, acc2, true, 'Premier modifié');

        accMerged = Utils_Dedoublonnage.determineMasterAccount(acc1, acc1, acc2, acc2, true, 'Dernier créé');
        accMerged = Utils_Dedoublonnage.determineMasterAccount(acc1, acc1, acc2, acc2, true, 'Premier modifié');
        accMerged = Utils_Dedoublonnage.determineMasterAccount(acc1, acc1, acc2, acc2, true, 'Dernier modifié');
        accMerged = Utils_Dedoublonnage.determineMasterAccount(acc1, acc1, acc2, acc2, true, 'Premier créé');

        // Création tache de fusion account
        List<Account> accList = new List<Account>([SELECT Id FROM Account]);
        TacheFusion__c tacheFusion = new TacheFusion__c(objet__c='Compte', IDConserve__c=accList[0].Id,IDSupprime__c=accList[1].Id);
        insert tacheFusion;
        
        // Exécution du test
        Test.startTest();
        System.enqueueJob(new QA_Fusion());
        Test.stopTest();

        // Test
        /*List<Account> accTestList = new List<Account>([SELECT Id FROM Account]);
        System.assertEquals(2, accTestList.size());*/
    }
    
    @isTest 
    static void test_Fusion_chantier() {
        // Récupération Record Type
        Id rtPerson = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        // Création enregistrements utile
        Account acc1 = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtPerson, 'Email',true);  
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc1.Id, true);
        Chantier__c chantier2 = Utils_Test.createChantier('Chantier 2', acc1.Id, true);
        Chantier__c chaMerged = new Chantier__c();
        chaMerged = Utils_Dedoublonnage.selectChantierValuesToMerge(chantier, chantier, chantier2, chantier2, 'Premier créé');
        chaMerged = Utils_Dedoublonnage.selectChantierValuesToMerge(chantier, chantier, chantier2, chantier2, 'Dernier créé');
        chaMerged = Utils_Dedoublonnage.selectChantierValuesToMerge(chantier, chantier, chantier2, chantier2, 'Premier modifié');

        chaMerged = Utils_Dedoublonnage.determineMasterChantier(chantier, chantier, chantier2, chantier2, 'Dernier créé');
        chaMerged = Utils_Dedoublonnage.determineMasterChantier(chantier, chantier, chantier2, chantier2, 'Premier modifié');
        chaMerged = Utils_Dedoublonnage.determineMasterChantier(chantier, chantier, chantier2, chantier2, 'Premier créé');

        // Création tache de fusion chantier
        List<Chantier__c> chaList = new List<Chantier__c>([SELECT Id FROM Chantier__c]);
        TacheFusion__c tacheFusion = new TacheFusion__c(objet__c='Chantier', IDConserve__c=chaList[0].Id,IDSupprime__c=chaList[1].Id);
        insert tacheFusion;
        
        // Exécution du test
        Test.startTest();
        System.enqueueJob(new QA_Fusion());
        Test.stopTest();

        // Test
        /*List<Chantier__c> chaTestList = new List<Chantier__c>([SELECT Id FROM Chantier__c]);
        System.assertEquals(1, chaTestList.size());*/
    }

    
    @isTest 
    static void test_Fusion_exception() {
        // Récupération Record Type
        Id rtPerson = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        // Création enregistrements utile
        Account acc1 = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtPerson, 'Email',true);          
        // Création enregistrements utile
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc1.Id, true);
        Chantier__c chantier2 = Utils_Test.createChantier('Chantier 2', acc1.Id, true);

        // Création tache de fusion chantier avec mauvais ID pour erreur
        List<Chantier__c> chaList = new List<Chantier__c>([SELECT Id FROM Chantier__c]);
        TacheFusion__c tacheFusion = new TacheFusion__c(objet__c='Chantier', IDConserve__c=chaList[0].Id,IDSupprime__c='0000');
        insert tacheFusion;
        
        // Exécution du test
        Test.startTest();
        System.enqueueJob(new QA_Fusion());
        Test.stopTest();

        // Test
        /*List<Chantier__c> chaTestList = new List<Chantier__c>([SELECT Id FROM Chantier__c]);
        System.assertEquals(2, chaTestList.size());
        tacheFusion = [SELECT Id,erreur__c FROM TacheFusion__c WHERE Id=:tacheFusion.Id LIMIT 1];
        System.assertNotEquals(null, tacheFusion.erreur__c);*/
    }

    @isTest 
    static void test_Fusion_schedule() {
        // Récupération Record Type
        Id rtPerson = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        // Création enregistrements utile
        Account acc1 = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtPerson, 'Email',true);
        Account acc2 = Utils_Test.createAccount('Account Deux', 'test', 'test2@test.fr', rtPerson, 'Email',true);

        // Création tache de fusion account
        List<Account> accList = new List<Account>([SELECT Id FROM Account]);
        TacheFusion__c tacheFusion = new TacheFusion__c(objet__c='Compte', IDConserve__c=accList[0].Id,IDSupprime__c=accList[1].Id);
        insert tacheFusion;

        // Exécution du test
        Test.startTest();

        Schedule_Fusion schedule = new Schedule_Fusion();
        String jobId = System.schedule('Test Test_Schedule_Fusion', '0 0 23 * * ?', schedule);

        Test.stopTest();

        // Récupération des informations et vérification
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
    }
}