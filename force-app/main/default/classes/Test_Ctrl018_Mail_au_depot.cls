//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl018_Mail_au_depot
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2021
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-177 : Mise en place des nouveaux types d'enregistrement des comptes
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl018_Mail_au_depot {

    @isTest
    private static void test_ctrl018() {
        Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Id accEntityRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null, null);

        System.runAs(user) {
            Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            
            // Création Sectorisation
            Sectorisation__c secto = Utils_Test.createSectorisation('MAG001Test', 'MAG Test', 'DEP001Test', 'Test',true);
            system.debug('secto Id ' + secto.Id);

            // Création account client
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',false);
            acc.sectorisation__c = secto.Id;
            insert acc;
            system.debug('acc Id '+ acc.Id);

            // Création Account Dépot
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
            //Utils_Test.createEntity('DÉPÔT Test', 'DDD', Date.today(), '0123456789', refMag.Id, true); 


            Test.startTest();
            // Création requêtes
            Case myCase1 = Utils_Test.createCase(null,acc,null,true);

            PageReference p = Page.VF018_Mail_au_depot;
            p.getParameters().put('id',myCase1.Id);

            Ctrl018_Mail_au_depot ctrl = new Ctrl018_Mail_au_depot();
            ctrl.init();
            Test.setCurrentPage(p);

            Test.stopTest();
       }
    }
    
    @isTest
    private static void test_ctrl018_2() {
        Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
        Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        Id accEntityRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2',null, null);

        System.runAs(user) {
            Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
            
            // Création Sectorisation
            Sectorisation__c secto = Utils_Test.createSectorisation('MAG001Test', 'MAG Test', 'DEP001Test', 'Test',true);
            system.debug('secto Id ' + secto.Id);

            // Création account client
            Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email',false);
            acc.sectorisation__c = secto.Id;
            insert acc;
            system.debug('acc Id '+ acc.Id);

            // Création chantier client
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,false);
            chantier.sectorisation__c = secto.Id;
            insert chantier;
            system.debug('chantier Id '+ chantier.Id);

            // Création Account Dépot
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, true);
            Utils_Test.createEntity('DÉPÔT Test', 'DDD', Date.today(), '0123456789', refMag.Id, true); 


            Test.startTest();
            // Création requêtes
            
            Case myCase2 = Utils_Test.createCase(null,acc,chantier.Id,true);

            PageReference p = Page.VF018_Mail_au_depot;
            p.getParameters().put('id',myCase2.Id);

            Ctrl018_Mail_au_depot ctrl = new Ctrl018_Mail_au_depot();
            Test.setCurrentPage(p);
            ctrl.init();

            Test.stopTest();
       }
    }
}