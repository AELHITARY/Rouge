//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_SObjectPurge
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/07/2018
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --

@isTest
private class Test_BA_SObjectPurge {
    
    static testMethod void test_BA_SObjetcPurge() {
        // Récupération Record Type
        String accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',true);
        //Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        //insert chantier;
        
        List<Chantier__c> lstChantier= new List<Chantier__c>();
        for(Integer i=0 ;i <5;i++)
        {
            Chantier__c chantier = new Chantier__c();
            chantier.Name ='Name'+i;
            chantier.GDPR_dateExpiration__c = date.today().addDays(-i);
            chantier.proprietaire__c = acc.Id;
            lstChantier.add(chantier);
        }
        insert lstChantier;
        
        Test.startTest();
        BA_SObjectPurge batch = new BA_SObjectPurge('Chantier__c');
        database.executebatch(batch);
        system.assertEquals('Name0', lstChantier[0].Name);
        Test.stopTest();
    }
    
    static testMethod void test_Schedule_SObjetcPurge() {
        // Récupération Record Type
        String accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',true);
        //Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        //insert chantier;
        
        List<Chantier__c> lstChantier= new List<Chantier__c>();
        for(Integer i=0 ;i <5;i++)
        {
            Chantier__c chantier = new Chantier__c();
            chantier.Name ='Name'+i;
            chantier.GDPR_dateExpiration__c = date.today().addDays(-i);
            chantier.proprietaire__c = acc.Id;
            lstChantier.add(chantier);
        }
        insert lstChantier;
        
        Test.startTest();
        Schedule_SObjectPurge.scheduleIt();
        Test.stopTest();
    }
    
}