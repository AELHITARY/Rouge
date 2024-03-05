//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CreditMemoSendToCustomer
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/09/2020
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CreditMemoSendToCustomer
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CreditMemoSendToCustomer {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

    @testSetup 
    static void setup() {
        
    }

    @isTest
    private static void testSend() { 
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        
        
       
        System.runAs(user){
            Contact contact = Utils_Test.createContact('Test','Test',true);
            Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
            
            // Création entite        
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                                 refEntityRT, true, true, true, true, true);
            Referencial__c refMag2 = Utils_Test.createReferencial('Magasin2', 'MAG2', Date.today(), null, 
                                                                 refEntityRT, true, true, true, true, true);
            Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', 
                                                     refMag.Id, true);
            //Account ent = Utils_Test.createEntity('MAGTESTTESTD', 'MAGTESTTESTD', Date.today(), '0123456789', refMag2.Id, true);
            //CreditMemo__c cred = [SELECT Id FROM CreditMemo__c LIMIT 1];
            Test.startTest();
            Chantier__c chant = Utils_Test.createChantier('test',entite.Id,true);
            // Creation facture
            Invoice__c fac = Utils_Test.createInvoice('Facture', a.Id, entite.Id, Date.today(), entite.Id, chant.Id, true);
            CreditMemo__c cred = Utils_Test.createCreditMemo(a.Id, entite.Id, fac.Id, chant.Id, null, false);
            cred.headOfficeLegalForm__c = 'EI';
            insert cred;
            
            LWC_CreditMemoGeneratePDF.renderDocumentPDF(cred.Id, 'Test FAC');
            LWC_CreditMemoSendToCustomer.sendCreditMemoToCustomer(cred.Id);

            Test.stopTest();
        }
    }
}