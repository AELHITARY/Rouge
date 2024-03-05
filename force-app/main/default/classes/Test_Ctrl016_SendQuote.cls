//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl016_SendQuote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 11/02/2019
//-- Version     : 1.1
//-- *
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl016_SendQuote {

    @testSetup static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);

        // Récupération record type
        String accPersonRTId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

        // Création enregistrement utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersonRTId, 'Email',true);
        Account acc2 = Utils_Test.createAccount('Account 2', 'test deux', 'test2@test.fr', accPersonRTId, 'Email',true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id,true);
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier,true);

        // Creation devis
        Quote devis = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
        devis.autreCompte__c = acc2.Id;
        insert devis;
    }
    
    @isTest
    private static void TestVF016_OK() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Récupération enregistrement du devis 
            Quote devis = [SELECT Id, forcageEtat__c, Status FROM Quote WHERE Name='Devis 1' LIMIT 1];
            devis.forcageEtat__c = Constants.StatutDevisNonTransmis;
            devis.Status = Constants.StatutDevisNonTransmis;
            devis.delaiInstallationMin__c = 3;
            devis.delaiInstallationMax__c = 4;
            update devis;

            PageReference newPRpage  = Page.VF016_SendQuote;
            newPRpage.getParameters().put('qId',devis.Id);
            Test.setCurrentPage (newPRpage);

            Ctrl016_SendQuote ctrl = new Ctrl016_SendQuote();
            // Envoi car statut OK
            ctrl.sendEmail();
        }
    }
    
    @isTest
    private static void TestVF016_KO() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Récupération enregistrement du devis 
            Quote devis = [SELECT Id FROM Quote WHERE Name='Devis 1' LIMIT 1];

            PageReference newPRpage  = Page.VF016_SendQuote;
            newPRpage.getParameters().put('qId',devis.Id);
            Test.setCurrentPage (newPRpage);

            Ctrl016_SendQuote ctrl = new Ctrl016_SendQuote();
            // Pas d'envoi car a configuré
            ctrl.sendEmail();
            // Erreur car plus de devis
            delete devis;
            ctrl.sendEmail();
        }
    }
    
    @isTest
    private static void TestVF016_KO2() {
        // Création utilisateur
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            // Récupération enregistrement du devis 
            Quote devis = [SELECT Id FROM Quote WHERE Name='Devis 1' LIMIT 1];
            devis.delaiInstallationMin__c = 3;
            devis.delaiInstallationMax__c = 4;
            update devis;

            PageReference newPRpage  = Page.VF016_SendQuote;
            newPRpage.getParameters().put('qId',devis.Id);
            Test.setCurrentPage (newPRpage);

            Ctrl016_SendQuote ctrl = new Ctrl016_SendQuote();
            // Pas d'envoi car a configuré
            ctrl.sendEmail();
            // Erreur car plus de devis
            delete devis;
            ctrl.sendEmail();
        }
    }
}