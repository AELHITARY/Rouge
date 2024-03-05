//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CreditMemoGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/09/2020
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CreditMemoGeneratePDF
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CreditMemoGeneratePDF {
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
                                                 refMag.Id, false);
        
        
        Account ent = Utils_Test.createEntity('MAGTESTTESTD', 'MAGTESTTESTD', Date.today(), '0123456789', null, false);
        List<Account> accList = new List<Account>();
        accList.add(entite);
        accList.add(ent);
        insert accList;
        Chantier__c chant = Utils_Test.createChantier('test',ent.Id,true);
        // Creation facture
        Invoice__c fac = Utils_Test.createInvoice('Facture', a.Id, entite.Id, Date.today(), ent.Id, chant.Id, true); 
        // Creation avoir
        Utils_Test.createCreditMemo(a.Id, entite.Id, fac.Id, chant.Id, null, true);
    }

    @isTest
    private static void testGenerate() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            CreditMemo__c cred = [SELECT Id FROM CreditMemo__c LIMIT 1];

            Test.startTest();
            try{
                LWC_CreditMemoGeneratePDF.renderDocumentPDF(cred.Id, 'Test FAC');
            }
            catch(Exception e){

            }

            try{
                LWC_CreditMemoGeneratePDF.renderDocumentPDF(null, null);
            }
            catch(Exception e){

            }

            Test.stopTest();
        }
    }

    @isTest
    private static void testLinkDocumentToRecordError(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        Test.startTest();
        System.runAs(user){
            try{
                LWC_CreditMemoGeneratePDF.linkDocumentToRecord(null, null,null);
            }
            catch(Exception e){

            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testGetInvoiceInformationError(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        Test.startTest();
        System.runAs(user){
            try{
                LWC_CreditMemoGeneratePDF.getCreditMemoInformation(null);
            }
            catch(Exception e){

            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testChangeStatusOfCreditMemo(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            CreditMemo__c cred = [SELECT Id FROM CreditMemo__c LIMIT 1];
            Test.startTest();
            try{
                LWC_CreditMemoGeneratePDF.changeStatusOfcreditMemo(cred.Id);
            }
            catch(Exception e){

            }
            Test.stopTest();
        }
    }

    @isTest
    private static void testChangeStatusOfCreditMemoError(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            try{
                LWC_CreditMemoGeneratePDF.changeStatusOfcreditMemo(null);
            }
            catch(Exception e){

            }
            Test.stopTest();
        }
    }

    @isTest
    private static void testSearchExistingDocumentPDF(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            CreditMemo__c cred = [SELECT Id FROM CreditMemo__c LIMIT 1];
            Test.startTest();
            try{
                LWC_CreditMemoGeneratePDF.searchExistingDocumentPDF(cred.Id);
            }
            catch(Exception e){

            }
            Test.stopTest();
        }
    }

    @isTest
    private static void testSearchExistingDocumentPDFError(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            try{
                LWC_CreditMemoGeneratePDF.searchExistingDocumentPDF(null);
            }
            catch(Exception e){

            }
            Test.stopTest();
        }
    }
}