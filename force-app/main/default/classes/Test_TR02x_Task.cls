//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Task
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 12/02/2019
//-- Version     : 1.2
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_Task {

    private static final Id rtTaskSortant = DAL.getRecordTypeIdByDevName('Task', Constants.TASK_APPEL_SORTANT_RT);
    private static final String PATTERN_APPEL_SORTANT = 'Appel sortant';
    private static final String PATTERN_TAG_APPEL = 'Tag Appel';
    private static final String PATTERN_EMAIL = 'E-mail';

    @testSetup static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        // Création Sectorisation
        Sectorisation__c sect = Utils_Test.createSectorisation('M123', 'Magasin 123', 'D123', 'Depot 123', true);       
        // Récupération Record Type
        Id rtPerson = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);        
        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Account Un', 'test', 'test@test.fr', rtPerson, 'Email', true);
        Chantier__c cha = Utils_Test.createChantier('Chantier 1', acc.Id, true);
        Utils_Test.createOpportunity(acc,cha,true);
    }

    @isTest static void test_AppelSortant() {   
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {     
            Test.startTest();
    
            Task task = Utils_Test.createTask(rtTaskSortant,null,null,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);        
            task.Subject = 'Test';
            update task;
            
            task.Subject = PATTERN_APPEL_SORTANT;
            update task;
            
            task.Status = Constants.StatutTaskTermine;
            update task;
    
            Test.stopTest();      
        }
    }
    
    @isTest static void test_TagAppel() { 
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            Test.startTest();
    
            Task task = Utils_Test.createTask(rtTaskSortant,null,null,PATTERN_TAG_APPEL,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);        
            task.Subject = 'Test';
            update task;
            
            task.Subject = PATTERN_TAG_APPEL;
            update task;
            
            task.Status = Constants.StatutTaskTermine;
            update task;
    
            Test.stopTest();       
        }
    }
    
    @isTest static void test_Email() {
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            Test.startTest();
    
            Task task = Utils_Test.createTask(rtTaskSortant,null,null,PATTERN_EMAIL,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);        
            task.Subject = 'Test';
            update task;
            
            task.Subject = PATTERN_EMAIL;
            update task;
            
            task.Status = 'Completed';
            update task;
    
            Test.stopTest();      
        }
    }
    
    @isTest static void testPhoning() {
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            Id rtTaskPhoning = DAL.getRecordTypeIdByDevName('Task', Constants.TASK_PHONING_RT); 
    
            Test.startTest();
    
            Task task = Utils_Test.createTask(rtTaskPhoning,null,null,'Phoning',Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);        
            task.Subject = 'Test';
            update task;
                    
            task.Status = Constants.StatutTaskTermine;
            update task;
            Test.stopTest();      
        }
    }   

    @isTest static void test_Odigo() { 
        User userTest = Utils_Test.createUser(true,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {     
            /** Setup **/
            Id rtTaskAFaire = DAL.getRecordTypeIdByDevName('Task',Constants.TASK_A_FAIRE_RT);   
            Account acc = [SELECT Id FROM Account LIMIT 1];
    
            Test.startTest();
    
            Task task = Utils_Test.createTask(rtTaskAFaire,null,null,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),false);     
            task.OdigoCti__Phone_number__c='0101010101';
            insert task;
            
            task.OdigoCti__Call_Folder_ID__c = acc.Id;
            update task;
    
            Test.stopTest();      
        }
    }
    
    /**************************************************************************/
    /******** Test du Remplissage automatique du champ Compte sur Task ********/
    /**************************************************************************/

    @isTest static void test_populateFieldCompte_WithCompte() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id FROM Account LIMIT 1];
    
            /** Test **/
            Test.startTest();        
     
            Task task = Utils_Test.createTask(rtTaskSortant,null,acc.Id,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);  
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu (task.WhatId = ' + task.WhatId + ').');
        }
    }
    
    @isTest static void test_populateFieldCompte_WithContact() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
                    
            /** Test **/
            Test.startTest();
            
            Task task = Utils_Test.createTask(rtTaskSortant,contact.Id,null,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);  
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu (task.WhoId = ' + task.WhoId + ').');
        }
    }
    
    @isTest static void test_populateFieldCompte_WithProjet() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            
            /** Test **/
            Test.startTest();
             
            Task task = Utils_Test.createTask(rtTaskSortant,null,opp.Id,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);  
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu.');
        }
    }
    
    @isTest static void test_populateFieldCompte_WithChantier() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            
            /** Test **/
            Test.startTest();
            
            Task task = Utils_Test.createTask(rtTaskSortant,null,chantier.Id,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu.');
        }
    }
    
    @isTest static void test_populateFieldCompte_WithCaseAccount() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
            Case testCase = Utils_Test.createCase(null, acc, null,true);
            
            /** Test **/
            Test.startTest();
            
            Task task = Utils_Test.createTask(rtTaskSortant,null,testCase.Id,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            //System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu.');
        }
    }
    
    @isTest static void test_populateFieldCompte_WithCaseContact() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
            Case testCase = Utils_Test.createCase(null, acc, contact.Id, null, true);
            
            /** Test **/
            Test.startTest();
            
            Task task = Utils_Test.createTask(rtTaskSortant,null,testCase.Id,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            //System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu.');
        }
    }

    @isTest static void test_populateFieldCompte_WithKContrat() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id FROM Account LIMIT 1];
            KContrat__c contrat = Utils_Test.createContrat('Contrat Test', null, acc.Id, 'IDuniquewesh99', true);
            
            /** Test **/
            Test.startTest();
            
            Task task = Utils_Test.createTask(rtTaskSortant,null,contrat.Id,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu.');
        }
    }

    @isTest static void test_populateFieldCompte_WithQuote() {
        User userTest = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        system.runAs(userTest) {
            /** Setup **/
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            
            /** Test **/
            Test.startTest();
            
            Task task = Utils_Test.createTask(rtTaskSortant,null,devis.Id,PATTERN_APPEL_SORTANT,Constants.StatutTaskAFaire,UserInfo.getUserId(),System.today(),true);
            
            Test.stopTest();
            
            /** Vérifs **/
            List<Task> taskList = [SELECT Compte__c FROM Task WHERE Id = :task.Id];
            System.assert(!taskList.isEmpty(), 'Tâche non insérée (Id recherché = ' + task.Id + ').');
            
            Task insertedTask = taskList[0];
            System.assertEquals(acc.Id, insertedTask.compte__c, 'Le champ Compte inséré ne correspond pas au compte attendu.');
        }
    }
}