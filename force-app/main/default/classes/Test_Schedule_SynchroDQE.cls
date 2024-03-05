//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_SynchroDQE
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/06/2017
//-- Version     : 1.1
//-- * 
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_SynchroDQE {
    
    /* Méthode de configuration des enregistrements pour les tests */
    /* Méthode standard exécutée avant les tests                   */
    /***************************************************************/
    @testSetup static void setup() {
        TestCommon.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = New Sectorisation__c (codeRegion__c='R123',libelleRegion__c='Région 123',
                                                    codeMagasin__c='M123',libelleMagasin__c='Magasin 123');
        insert sect;
        
        // Récupération des Record Type
        RecordType accountRecordType = [Select id, Name from RecordType where sobjectType = 'Account' and isPersonType = true limit 1];
        
        // Création de 2 comptes de tests
        Account acc1 = new Account(Type='Piste',
            RecordTypeId = accountRecordType.Id,
            LastName='MyAccount1',
            FirstName='MyAccount1',
            PersonMailingPostalCode='12345',
            PersonMailingCity='City123',
            PersonMailingCountry='Country123',
            erreurSynchronisationDQE__c = 'erreur',
            aSynchroniserDQE__c = 3
        );
        insert acc1;

        Account acc2 = new Account(Type='Piste',
            RecordTypeId = accountRecordType.Id,
            LastName='MyAccount2',
            FirstName='Œuf',
            PersonMailingPostalCode='12345',
            PersonMailingCity='City123',
            PersonMailingCountry='Country123',
            erreurSynchronisationDQE__c = 'erreur',
            aSynchroniserDQE__c = 3
        );
        insert acc2;

        

        // Création de 2 chantiers de tests
        chantier__c cha1 = Utils_Test.createChantier('Chantier 1', acc1.Id, false);
        cha1.aSynchroniserDQE__c = 3;
        cha1.erreurSynchronisationDQE__c = 'erreur';
        insert cha1;
        /*Chantier__c cha1 = new Chantier__c(
            Name='MyAccount1',
            account__c = acc1.Id,
            codePostal__c='12345',
            ville__c='Test',
            pays__c='Country123',
            erreurSynchronisationDQE__c = 'erreur',
            aSynchroniserDQE__c = 3
        );
        insert cha1;*/

        chantier__c cha2 = Utils_Test.createChantier('Chantier 2', acc2.Id, false);
        cha2.aSynchroniserDQE__c = 3;
        cha2.erreurSynchronisationDQE__c = 'erreur';
        insert cha2;

    }

    @isTest static void test_schedule() {

        // Vérification des 2 enregistrements non-synchronisés
        List<Account> accList = new List<Account>([SELECT Id FROM Account WHERE aSynchroniserDQE__c > 0]);
        
        system.assertEquals(2, accList.size());

        // Exécution du test
        Test.startTest();
       
        // Execution du batch
        Schedule_SynchroDQE schedule = new Schedule_SynchroDQE();
        String jobId = system.schedule('Test Test_Schedule_SynchroDQE', '0 0 23 * * ?', schedule);

        Test.stopTest();

        // Récupération des informations et vérification
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        system.assertEquals(0, ct.TimesTriggered);
    }

    @isTest static void test_batchCompte() {
        // Vérification des 2 enregistrements non-synchronisés
        List<Account> accList = new List<Account>([SELECT Id FROM Account WHERE aSynchroniserDQE__c > 0]);
        system.assertEquals(2, accList.size());

        // Exécution du test
        Test.startTest();

        BA_SynchroAccountDQE batch = new BA_SynchroAccountDQE();
        Id batchId = Database.executeBatch(batch);

        Test.stopTest();
    }

    @isTest static void test_batchChantier() {
        // Vérification des 2 enregistrements non-synchronisés
        List<Chantier__c> chaList = new List<Chantier__c>([SELECT Id FROM Chantier__c WHERE aSynchroniserDQE__c > 0]);
        system.assertEquals(2, chaList.size());

        // Exécution du test
        Test.startTest();

        BA_SynchroChantierDQE batch = new BA_SynchroChantierDQE();
        Id batchId = Database.executeBatch(batch);

        Test.stopTest();
    }
    
}