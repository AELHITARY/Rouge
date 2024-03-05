//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_InvoiceSendToCustomer
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/09/2020
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_InvoiceSendToCustomer
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_InvoiceSendToCustomer {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

    @testSetup 
    static void setup() {
        // Création d'un contact et des comptes
        Contact contact = Utils_Test.createContact('Test','Test',true);
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        
        // Création entite        
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', 
                                                 refMag.Id, true);
        
        
        //Account ent = Utils_Test.createEntity('MAGTESTTESTD', 'MAGTESTTESTD', Date.today(), '0123456789', null, true);
        Chantier__c chant = Utils_Test.createChantier('test',entite.Id,true);
        // Creation facture
        Invoice__c inv  = Utils_Test.createInvoice('Facture', a.Id, entite.Id, null, entite.Id, chant.Id, false);
        inv.headOfficeLegalForm__c = 'EI';
        insert inv;
    }

    @isTest
    private static void testRenderAndSend() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Invoice__c fac = [SELECT Id FROM Invoice__c LIMIT 1];
            Test.startTest();
            
            LWC_InvoiceGeneratePDF.renderDocumentPDF(fac.Id, 'Test FAC', 'Facture');
            LWC_InvoiceSendToCustomer.sendInvoiceToCustomer(fac.Id, 'Facture');

            Test.stopTest();
        }
    }

    @isTest
    private static void testSend() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Invoice__c fac = [SELECT Id FROM Invoice__c LIMIT 1];
            Test.startTest();
            
            LWC_InvoiceSendToCustomer.sendInvoiceToCustomer(fac.Id, 'Facture');

            Test.stopTest();
        }
    }

    @isTest
    private static void testSendPaid() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Invoice__c fac = [SELECT Id FROM Invoice__c LIMIT 1];
            Test.startTest();
            
            LWC_InvoiceSendToCustomer.sendInvoiceToCustomer(fac.Id, 'Facture acquittée');

            Test.stopTest();
        }
    }

    @isTest
    private static void testUtils() {
        Test.startTest();
        
        LWC_InvoiceSendToCustomer.generateAuraException('TEST');

        Test.stopTest();
    }
}