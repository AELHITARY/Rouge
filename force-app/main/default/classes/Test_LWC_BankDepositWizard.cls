//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_BankDepositWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/04/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_BankDepositWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_BankDepositWizard {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    private static final Id customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final Id accEntityRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

    @testSetup 
    static void setup() {
        // Création Ref
        List<Account> accToInsert = new List<Account>();
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
        //Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);
        Account ent = Utils_Test.createEntity('MAGTESTTESTD', 'MAGTESTTESTD', Date.today(), '0123456789', null, false);
        accToInsert.add(new Account(Name = 'ORG',RecordTypeId = DAL.getRecordTypeIdByDevName('Account', 'FundingOrganization'), KparKReference__c = 'ORG-FIN1', startDate__c = Date.today()));
        accToInsert.add(a);
        accToInsert.add(ent);
        insert accToInsert;
        // Création Referencial        
        List<Referencial__c> refToInsert = new List<Referencial__c>();
        refToInsert.add(Utils_Test.createPaymentMethod('VIREMENT','PAY-0012',Date.today(),null,false));
        refToInsert.add(Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,false));
        refToInsert.add(Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, false));
        insert refToInsert;
        // Création d'un compte
        Chantier__c chant = Utils_Test.createChantier('test',ent.Id,true);
        // Création banque
        Referencial__c bank = Utils_Test.createBankAccount('BANK','BANK-FIN1',Date.today(),null,true);
        BankAccountVisibility__c bankV = new BankAccountVisibility__c(bankAccount__c=bank.Id, entity__c=ent.Id, startDate__c = Date.today());
        insert bankV;
        // Création commande        
        Order newCustomerOrder = Utils_Test.createCustomerOrder(a.Id, true);        
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }
        OrderItem newOrderItem1 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, productTest1.Id, true);
    }
    
    @isTest
    private static void testUpdatePieces(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];

            // Create Piece
            Referencial__c ref1 = LWC_AdvancePaymentWizard.getDefaultPaymentMethod(false);            
            List<AccountingPiece__c> piecesToIns = new List<AccountingPiece__c>();
            String RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);
            AccountingPiece__c accPiece = new AccountingPiece__c();
            accPiece.RecordTypeId = RT_AP_RECEIPT;
            accPiece.order__c = newCustomerOrder.Id;
            accPiece.orderEntity__c = ent.Id;
            accPiece.inputEntity__c = ent.Id;
            accPiece.entityBankAccount__c = bankAccount.Id;
            accPiece.pieceDate__c = Date.today();
            accPiece.dueDate__c = Date.today()+30;
            accPiece.paymentMethod__c = ref1.Id;
            accPiece.amount__c = 100;
            accPiece.externalBank__c = 'TEST';
            accPiece.externalReference__c = 'TEST';
            piecesToIns.add(accPiece);
            insert piecesToIns;

            // Get Pieces
            List<AccountingPiece__c> accPieceList = LWC_BankDepositWizard.getAccountingPieces(ent.Id, bankAccount.Id, Date.today(), true, true);
            // Update
            List<String> selectedPieceRecordsId = new List<String>();
            for(AccountingPiece__c accP : accPieceList) {
                selectedPieceRecordsId.add(accP.Id);
            }
            LWC_BankDepositWizard.updateAccountingPieces(selectedPieceRecordsId, bankAccount.Id, ent.Id, Date.today(), '0000001');
            LWC_BankDepositWizard.createDocumentPDF(selectedPieceRecordsId, bankAccount.Id, ent.Id, Date.today(), '0000001');

            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUtils(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();
            
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            String bankAccId = LWC_BankDepositWizard.getBankAccount(ent.Id);
            LWC_BankDepositWizard.getBankAccountName(bankAccId);
            
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            
            BankAccountVisibility__c bankV = new BankAccountVisibility__c(bankAccount__c=bankAccount.Id, entity__c=ent.Id, startDate__c = Date.today());
            insert bankV;
            String bankAccId2 = LWC_BankDepositWizard.getBankAccount(ent.Id);
            LWC_BankDepositWizard.generateAuraException('TEST');

            Test.stopTest();
        }
    }
}