//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_RefundRequestWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/05/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_RefundRequestWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_RefundRequestWizard {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    private static final Id refRefundReasonyRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_REFUNDREASON_RT);  
    private static final Id accEntityRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

    @testSetup 
    static void setup() {
        // Création Referencial       
        List<Referencial__c> refToInsert = new List<Referencial__c>();
        refToInsert.add(Utils_Test.createPaymentMethod('VIREMENT','PAY-0012',Date.today(),null,false));
        refToInsert.add(Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,false));
        insert refToInsert;
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);   
        Referencial__c refReason = Utils_Test.createReferencial('Remb', 'REMB-01', Date.today(), null, refRefundReasonyRT, false, false, false, false, false);
        refReason.refundType__c = 'CheckRequest';
        insert refReason;
        // Création d'un compte
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);
        Chantier__c chant = Utils_Test.createChantier('test',entite.Id,true);
        // Création commande        
        Order newCustomerOrder = Utils_Test.createCustomerOrder(a.Id, false); 
        newCustomerOrder.chantier__c = chant.Id;
        newCustomerOrder.serviceEntity__c = entite.Id;
        insert newCustomerOrder;
        // Creation facture
        Invoice__c fac = Utils_Test.createInvoice('Facture', a.Id, entite.Id, Date.today(), entite.Id, chant.Id, true);
        CreditMemo__c cred = Utils_Test.createCreditMemo(a.Id, entite.Id, fac.Id, chant.Id, null, false);
        cred.headOfficeLegalForm__c = 'EI';
        cred.worksite__c = chant.Id;
        cred.customerOrder__c = newCustomerOrder.Id;
        cred.refundReason__c = refReason.Id;
        insert cred;
    }
    
    @isTest
    private static void testUpdatePieces(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
            Referencial__c refReason = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'REMB-01' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            CreditMemo__c credMemo = [SELECT Id FROM CreditMemo__c LIMIT 1];

            // Create Piece
            Referencial__c ref1 = LWC_RefundRequestWizard.getDefaultPaymentMethod();        
            LWC_RefundRequestWizard.createRefundRequestPiece(credMemo.Id, refReason.Id, ent.Id, ref1.Id, Date.today(), -100);

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUtils(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            Referencial__c ref1 = LWC_RefundRequestWizard.getDefaultPaymentMethod();
            LWC_RefundRequestWizard.getDefaultPaymentMethod();

            Test.stopTest();
        }
    }
}