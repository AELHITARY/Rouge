//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_AcountingPiece
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 09/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_AcountingPiece {
    private static final String RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    private static final String RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

    private static final String RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);
    private static final String RT_AP_COMPOSITERECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_COMPOSITERECEIPT_RT);
    private static final String RT_AP_CHECKREQUEST = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_CHECKREQUEST_RT);
    private static final String RT_AP_REFUND = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_REFUND_RT);
    private static final String RT_AP_RECEIPTCANCELLATION = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPTCANCELLATION_RT);
    private static final String RT_AP_UNDELIVEREDRECEIPTCANCELLATION = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_UNDELIVERED_RECEIPTCANCELLATION_RT);
    private static final String RT_AP_UNPAID = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_UNPAID_RT);

    private static final String RT_REF_REFUNDREASON = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_REFUNDREASON_RT);

    @testSetup 
    static void setup() {
        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, RT_REF_ENTITY, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, RT_REF_ENTITY, true, true, true, true, false);
        refList.add(Utils_Test.createPaymentMethod('VIREMENT','PAY-0012',Date.today(),null,false));
        refList.add(Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,false));
        refList.add(refDep);
        refList.add(refMag);
        insert refList;
        // Compte
        List<Account> accToInsert = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', RT_ACC_PERSO, 'Email',false);
        accToInsert.add(new Account(Name = 'ORG',RecordTypeId = DAL.getRecordTypeIdByDevName('Account', 'FundingOrganization'), 
                                    KparKReference__c = 'ORG-FIN1', startDate__c = Date.today()));
        accToInsert.add(a);
        accToInsert.add(entiteDep);
        accToInsert.add(entiteMag);
        insert accToInsert;
        // Création d'un chantier
        Chantier__c chant = Utils_Test.createChantier('test',a.Id,true);
        // Création banque
        Referencial__c bank = Utils_Test.createBankAccount('BANK','BANK-FIN1',Date.today(),null,true);
        BankAccountVisibility__c bankV = new BankAccountVisibility__c(bankAccount__c=bank.Id, entity__c=entiteDep.Id, startDate__c = Date.today());
        insert bankV;
        // Création commande        
        /*Order newCustomerOrder = Utils_Test.createCustomerOrder(a.Id, false);        
        newCustomerOrder.serviceEntity__c = entiteDep.Id;
        newCustomerOrder.salesEntity__c = entiteMag.Id;
        insert newCustomerOrder;
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }
        OrderItem newOrderItem1 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, productTest1.Id, true);*/
    }

    @isTest
    private static void testUpdatePieces(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];
            Chantier__c chantier = [SELECT Id,serviceEntity__c FROM Chantier__c  LIMIT 1];

            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, false);
            newCustomerOrder.serviceEntity__c = ent.Id;
            newCustomerOrder.salesEntity__c = entiteMag.Id;
            newCustomerOrder.Chantier__c = chantier.Id;
            insert newCustomerOrder;

            List<AccountingEntry__c> accountEntryList = new List<AccountingEntry__c>();
            AccountingEntry__c accEntry1 = new AccountingEntry__c(entityBankAccount__c = bankAccount.Id);
            AccountingEntry__c accEntry2 = new AccountingEntry__c(entityBankAccount__c = bankAccount.Id);
            accountEntryList.add(accEntry1);
            accountEntryList.add(accEntry2);
            insert accountEntryList;

            List<AccountingPiece__c> apList = new List<AccountingPiece__c>();
            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, ent.Id, ent.id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, 100, Date.today(), null, null, false);
            accPiece.accountingEntry__c = accEntry1.Id; 
            AccountingPiece__c accPiece2 = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, ent.Id, ent.id, null, 
                                                                            paymentMethod.Id, null, null, 100, Date.today(), null, null, false);
            accPiece2.accountingEntry__c = accEntry1.Id;  
            apList.add(accPiece);
            apList.add(accPiece2);
            insert apList;
            
            accPiece.accountingEntry__c = accEntry2.Id;
            accPiece.accountingDate__c = Date.today();
            update accPiece;

            accPiece = [SELECT status__c FROM AccountingPiece__c WHERE accountingDate__c != null LIMIT 1];

            //vérif statut
            Assert.areEqual('Comptabilisé', accPiece.status__c); 

            //vérif montant AccEntry
            accountEntryList = [SELECT Id,amount__c FROM AccountingEntry__c];
            for(AccountingEntry__c accEntry : accountEntryList){
                Assert.areEqual(100, accEntry.amount__c);
            }
            Test.stopTest();
        }
    }

    @isTest
    private static void testDeletePieces(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];

            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, false);
            newCustomerOrder.serviceEntity__c = ent.Id;
            newCustomerOrder.salesEntity__c = entiteMag.Id;
            insert newCustomerOrder;

            // Create Piece
            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, null, Date.today(), Date.today()+30, Date.today(), true);

            try {
                delete accPiece;
            } catch(Exception ex) {

            }

            //Vérif pièce non supprimée
            List<AccountingPiece__c> accPieceList = [SELECT Id FROM AccountingPiece__c];
            Assert.areEqual(1, accPieceList.size());

            Test.stopTest();
        }
    }

    @isTest
    private static void testCompositePiece(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];

            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, false);
            newCustomerOrder.serviceEntity__c = ent.Id;
            newCustomerOrder.salesEntity__c = entiteMag.Id;
            insert newCustomerOrder;

            newCustomerOrder.amount__c = 100;
            update newCustomerOrder;

            // Piece composite
            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_COMPOSITERECEIPT, newCustomerOrder.Id, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, 100, Date.today(), Date.today()+30, null, false);
            accPiece.account__c = acc.Id;
            insert accPiece;

            // Piece enfant
            AccountingPiece__c accPiece2 = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, null, null, null, 
                                                                            null, null, accPiece.Id, 100, null, null, null, true);
            
            //Vérif lineAmount et lineQuantity mis à jour sur pièce parent
            accPiece = [SELECT lineAmount__c, lineQuantity__c FROM AccountingPiece__c WHERE parent__c = null LIMIT 1]; 
            Assert.areEqual(100, accPiece.lineAmount__c);
            Assert.areEqual(1, accPiece.lineQuantity__c);

            delete accPiece2;
            //Vérif lineAmount et lineQuantity vidé sur pièce parent quand supression
            accPiece = [SELECT lineAmount__c, lineQuantity__c FROM AccountingPiece__c WHERE parent__c = null LIMIT 1];
            Assert.areEqual(null, accPiece.lineAmount__c);
            Assert.areEqual(null, accPiece.lineQuantity__c);

            Test.stopTest();
        }
    }

    @isTest
    private static void testCancelPiece(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];

            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, false);
            newCustomerOrder.serviceEntity__c = ent.Id;
            newCustomerOrder.salesEntity__c = entiteMag.Id;
            insert newCustomerOrder;

            // Create Piece
            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, 100, Date.today(), Date.today()+30, null, true);

            // Annulation piece
            AccountingPiece__c accPiece2 = Utils_Test.createAccountingPiece(RT_AP_UNDELIVEREDRECEIPTCANCELLATION, newCustomerOrder.Id, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, accPiece.Id, null, null, null, null, null, true);
            

            //Vérif statut et Montant pièce annulée
            accPiece = [SELECT cancelledAmount__c, cancelledQuantity__c, status__c FROM AccountingPiece__c WHERE RecordTypeId =:RT_AP_RECEIPT LIMIT 1];
            Assert.areEqual('Annulé', accPiece.status__c); 
            Assert.areEqual(-100,accPiece.cancelledAmount__c);
            Assert.areEqual(1,accPiece.cancelledQuantity__c); 

            delete accPiece2;

            //Vérif dé-annulation pièce 
            accPiece = [SELECT cancelledAmount__c, cancelledQuantity__c, status__c FROM AccountingPiece__c WHERE RecordTypeId =:RT_AP_RECEIPT LIMIT 1];
            Assert.areEqual('En cours', accPiece.status__c); 
            Assert.areEqual(null,accPiece.cancelledAmount__c);
            Assert.areEqual(null,accPiece.cancelledQuantity__c); 

            Test.stopTest();
        }
    }

    @isTest
    private static void testReceiptCancelPieces(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];

            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, false);
            newCustomerOrder.serviceEntity__c = ent.Id;
            newCustomerOrder.salesEntity__c = entiteMag.Id;
            insert newCustomerOrder;

            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, 100, Date.today(), null, null, true);
                                                              
            accPiece.accountingDate__c = Date.today();
            update accPiece;

            AccountingPiece__c accPieceCancel = Utils_Test.createAccountingPiece(RT_AP_RECEIPTCANCELLATION, newCustomerOrder.Id, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, accPiece.Id, null, -100, Date.today(), null, Date.today(), true);

            accPiece = [SELECT cancelledAmount__c, netAmount__c, status__c FROM AccountingPiece__c WHERE recordTypeId =:RT_AP_RECEIPT LIMIT 1];

            Assert.areEqual('Annulé', accPiece.status__c);
            Assert.areEqual(-100, accPiece.cancelledAmount__c);
            Assert.areEqual(0, accPiece.netAmount__c);

            Test.stopTest();
        }
    }

    @isTest
    private static void testUnpaidPieces(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];

            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, false);
            newCustomerOrder.serviceEntity__c = ent.Id;
            newCustomerOrder.salesEntity__c = entiteMag.Id;
            insert newCustomerOrder;

            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, 100, Date.today(), null, null, true);
            accPiece.accountingDate__c = Date.today();
            update accPiece;

            AccountingPiece__c accPiece2 = Utils_Test.createAccountingPiece(RT_AP_UNPAID, null, ent.Id, ent.Id, bankAccount.Id, 
                                                                            paymentMethod.Id, accPiece.Id, null, null, Date.today(), null, Date.today(), true);
            
            //Vérif status et maj montant
            accPiece = [SELECT cancelledAmount__c, status__c FROM AccountingPiece__c WHERE recordTypeId =: RT_AP_RECEIPT];
            Assert.areEqual('Annulé', accPiece.status__c);
            Assert.areEqual(-100, accPiece.cancelledAmount__c);

            Test.stopTest();
        }
    }

    @isTest
    private static void testInvoicePieces(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];

            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];

            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entiteMag.Id, ent.Id, true);
           
            // Creation facture
            Invoice__c inv = Utils_Test.createInvoice('Facture', acc.Id, ent.Id, Date.today(), ent.Id, chant.Id, false);
            inv.amount__c = 100;
            inv.customerOrder__c = newCustomerOrder.Id;
            inv.autoComputedAmount__c = false;
            insert inv;

            inv = [SELECT amount__c FROM Invoice__c LIMIT 1];

            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, null, ent.Id, ent.id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, null, Date.today(), null, null, false);
            accPiece.invoice__c = inv.Id;
            insert accPiece;

            accPiece.accountingDate__c = Date.today();
            update accPiece;

            //vérif commande + montant récup depuis facture
            accPiece = [SELECT amount__c, order__c FROM AccountingPiece__c LIMIT 1];
            Assert.areEqual(100, accPiece.amount__c);
            Assert.areEqual(newCustomerOrder.Id, accPiece.order__c);

            //Vérif maj montant percu facture
            inv = [SELECT perceivedAmount__c, paymentDate__c FROM Invoice__c LIMIT 1];
            Assert.areEqual(100, inv.perceivedAmount__c);
            Assert.areEqual(Date.today(),inv.paymentDate__c);

            Test.stopTest();
        }
    }

    @isTest
    private static void testApproveCheckRequest(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Referencial__c bankAccount = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'BANK-FIN1' LIMIT 1];
            Referencial__c paymentMethod = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'PAY-0004' LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY And KparKReference__c = 'DEP00X0' LIMIT 1];
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            

            // Création commande        
            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entiteMag.Id, ent.Id, true);        
            
            Referencial__c refundReason = Utils_Test.createReferencial('Test motif', 'MREMB_TESTXXX', Date.today(), null, RT_REF_REFUNDREASON, true, true, true, true, false);
            refundReason.refundType__c = 'CheckRequest';
            insert refundReason;

            // Creation facture
            Invoice__c inv = Utils_Test.createInvoice('Facture', acc.Id, ent.Id, Date.today(), ent.Id, chant.Id, true);
            
            // Creation avoir
            CreditMemo__c cred = Utils_Test.createCreditMemo(acc.Id, ent.Id, inv.Id, chant.Id, Date.today(), false);
            cred.customerOrder__c = newCustomerOrder.Id;
            insert cred;

            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_CHECKREQUEST, null, ent.Id, ent.id, bankAccount.Id, 
                                                                            paymentMethod.Id, null, null, -100, Date.today(), null, null, false);
            accPiece.creditMemo__c = cred.Id;
            accPiece.refundReason__c = refundReason.Id;
            insert accPiece;

            accPiece.isValid__c = true;
            update accPiece;

            //vérif commande récup depuis avoir
            accPiece = [SELECT order__c FROM AccountingPiece__c WHERE amount__c = -100 LIMIT 1];
            Assert.areEqual(newCustomerOrder.Id, accPiece.order__c);

            //vérif pièce avec montant inversé créée
            accPiece = [SELECT amount__c FROM AccountingPiece__c WHERE isPositiveCheckRequest__c = true LIMIT 1];
            Assert.areEqual(100, accPiece.amount__c);

            Test.stopTest();
        }
    }
}