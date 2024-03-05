//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_AdvancePaymentWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 01/03/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_AdvancePaymentWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_AdvancePaymentWizard {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id invoiceRT = DAL.getRecordTypeIdByDevName('Invoice__c', Constants.INVOICE_INVOICE_RT);
    private static final Id refBank = DAL.getRecordTypeIdByDevName('Referencial__c', 'BankAccount');
    private static final Id customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final Id accEntityRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

    @testSetup 
    static void setup() {
        // Création Ref
        List<Account> accToInsert = new List<Account>();
        accToInsert.add(new Account(Name = 'ORG',RecordTypeId = DAL.getRecordTypeIdByDevName('Account', 'FundingOrganization'), KparKReference__c = 'ORG-FIN1', startDate__c = Date.today()));
        //insert accToInsert;
        // Création Referencial        
        List<Referencial__c> refToInsert = new List<Referencial__c>();
        refToInsert.add(Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,false));
        Referencial__c ref = Utils_Test.createPaymentMethod('VIREMENT','PAY-0012',Date.today(),null,false);
        ref.minPayableAmount__c = 0;
        ref.maxPayableAmount__c = 10000;
        refToInsert.Add(ref);       
        //refToInsert.add(Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,false));
        refToInsert.add(Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, refEntityRT, true, true, true, true, false));
        insert refToInsert;
        // Création d'un compte
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
        accToInsert.add(a);
        //Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);
        Account ent = Utils_Test.createEntity('MAGTESTTESTD', 'MAGTESTTESTD', Date.today(), '0123456789', null, false);
        accToInsert.add(ent);
        insert accToInsert;
        Chantier__c chant = Utils_Test.createChantier('test',ent.Id,true);
        // Création banque
        Referencial__c bank = Utils_Test.createBankAccount('BANK','BANK-FIN1',Date.today(),null,true);
        BankAccountVisibility__c bankV = new BankAccountVisibility__c(bankAccount__c=bank.Id, entity__c=ent.Id, startDate__c = Date.today());
        bankV.startDate__c = Date.newInstance(2022, 06, 09);
        insert bankV;
        // Création commande        
        Order newCustomerOrder = Utils_Test.createCustomerOrder(a.Id, false);
        newCustomerOrder.billingCity = 'test';
        newCustomerOrder.billingPostalCode = '12345';
        newCustomerOrder.chantier__c = chant.Id;
        newCustomerOrder.shippingName__c = 'test';
        newCustomerOrder.shippingPostalCode = '12345';
        newCustomerOrder.shippingCity = 'test';
        newCustomerOrder.serviceEntity__c = ent.Id;
        insert newCustomerOrder;
		system.debug('newCustomerOrder.serviceEntity__c '+newCustomerOrder.serviceEntity__c);        
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }
        OrderItem newOrderItem1 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, productTest1.Id, true);
        // Creation facture
        Invoice__c inv = Utils_Test.createInvoice('Facture', a.Id, ent.Id, Date.today(), ent.Id, chant.Id, false); 
        inv.amount__c = 200;
        inv.autoComputedAmount__c = false;
        inv.perceivedAmount__c = 100;
        inv.billingAccount__c = a.Id;
        //inv.invoiceDate__c = Date.today();
        inv.customerOrder__c = newCustomerOrder.Id;        
        inv.headOfficeLegalForm__c = 'Autre';
        inv.invoiceReference__c = '1';
        inv.toPerceiveAmount__c = 50;
        insert inv;
        system.debug('customerOrder__r.serviceEntity__c'+inv.customerOrder__r.serviceEntity__c);
        System.debug('inv amount:'+inv.amount__c + ', autocalc:'+inv.autoComputedAmount__c);
    }
    
    @isTest
    private static void testAccountB2C(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            

            // Update order
            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            Referencial__c banck = [SELECT Id FROM Referencial__c WHERE RecordTypeId = :refBank LIMIT 1];
            Order newCustomerOrder = [SELECT Id,Order.AccountId FROM Order LIMIT 1];
            newCustomerOrder.advancePaymentAmount1__c = 100;
            newCustomerOrder.advancePaymentAmount2__c = 100;
            newCustomerOrder.amount__c = 200;
            newCustomerOrder.isValid__c = true;
            newCustomerOrder.serviceEntity__c = ent.Id;
            update newCustomerOrder;

            Referencial__c ref1 = LWC_AdvancePaymentWizard.getDefaultPaymentMethod(false);
            List<Invoice__c> newInvoiceList = LWC_AdvancePaymentWizard.getInvoices(acc.Id, false, banck.Id, Date.today());
            Assert.areEqual(1,newInvoiceList.size());
            List<Order> newOrderList = LWC_AdvancePaymentWizard.getCustomerOrders(acc.Id, false, banck.Id, Date.today());
            Assert.areEqual(1,newOrderList.size());

            String result = LWC_AdvancePaymentWizard.createAccountingPieces(acc.Id, ent.Id, false, null, Date.today(), null, 400, ref1.Id, 
                                                            'TEST', 'Test', newOrderList, newInvoiceList);
            Assert.areEqual('OK', result);
            List<AccountingPiece__c> accPieceList = [SELECT Id FROM AccountingPiece__c];
            //3 nouvelles pièce crées (1 composite , 1 pour commande, 1 pour facture)
            Assert.areEqual(3,accPieceList.size());
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testDatatableInvoice(){
        
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        
        System.runAs(user){       
            Account acc = [SELECT Id,FirstName,LastName,PersonEmail FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
			Referencial__c banck = [SELECT Id FROM Referencial__c WHERE RecordTypeId = :refBank LIMIT 1];
            List<Invoice__c> invo = [SELECT Id FROM Invoice__c WHERE RecordTypeId = :invoiceRT];
            system.debug('banck '+banck);
            system.debug('invo '+invo);           
            
            

            List<Map<String,String>> newValues = new List<Map<String,String>>();
            Map<String, String> mapParameters = new Map<String, String>();
            mapParameters.put('Id', invo[0].Id);
            mapParameters.put('perceivedAmount__c', '4500');
            mapParameters.put('priceReduction__c','1000');
            newValues.add(mapParameters);
            
            List<Invoice__c> invToUpdateList = LWC_AdvancePaymentWizard.updateDatatableInvoices(newValues, invo);
            update invToUpdateList;

            Invoice__c invUpdated = [SELECT priceReduction__c FROM Invoice__c LIMIT 1]; 
            Assert.areEqual(1000,invUpdated.priceReduction__c);
        }

        Test.stopTest();
    }
    
    @isTest
    private static void testDatatableOrder(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            Referencial__c banck = [SELECT Id FROM Referencial__c WHERE RecordTypeId = :refBank LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order LIMIT 1];
            newCustomerOrder.advancePaymentAmount1__c = 100;
            newCustomerOrder.advancePaymentAmount2__c = 100;
            newCustomerOrder.amount__c = 200;
            newCustomerOrder.isValid__c = true;
            newCustomerOrder.serviceEntity__c = ent.Id;
            update newCustomerOrder;
            List<Order> newOrderList = LWC_AdvancePaymentWizard.getCustomerOrders(acc.Id, false, banck.Id, Date.today());
            //repasser la valeur du staut en nom api pour évter l'erreur à l'update
            newOrderList[0].Status = 'Validated';

            List<Map<String,String>> newValues = new List<Map<String,String>>();
            Map<String, String> mapParameters = new Map<String, String>();
            mapParameters.put('Id', newOrderList[0].Id);
            mapParameters.put('advPaymentAmountSum__c', '4500');
            mapParameters.put('shippingCost__c','1000');
            newValues.add(mapParameters);
            
            List<Order> orderToUpdate = LWC_AdvancePaymentWizard.updateDatatableOrders(newValues, newOrderList);
            update orderToUpdate;
            Order orderUpdated = [SELECT shippingCost__c FROM Order LIMIT 1];
            Assert.areEqual(1000,orderUpdated.shippingCost__c);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testUtils(){
        Test.startTest();

        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user)
        {
            Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            Referencial__c bank = [SELECT Id,Name FROM Referencial__c WHERE Name = 'BANK' LIMIT 1];

            Referencial__c ref1 = LWC_AdvancePaymentWizard.getDefaultPaymentMethod(false);
            Referencial__c ref2 = LWC_AdvancePaymentWizard.getDefaultPaymentMethod(true);
            Assert.areEqual('CHEQUE',ref1.Name);
            Assert.areEqual('VIREMENT',ref2.Name);
            ref2 = LWC_AdvancePaymentWizard.getPaymentMethodInfos(ref2.Id);
            Assert.areEqual(true,ref2.requiredExternalBankAccount__c);
            Assert.areEqual(0,ref2.minPayableAmount__c);
            Assert.areEqual(10000,ref2.maxPayableAmount__c);
            AuraHandledException ex = LWC_AdvancePaymentWizard.generateAuraException('TEST');
            Assert.areEqual('TEST', ex.getMessage());
            String bkId = LWC_AdvancePaymentWizard.getBankAccount(ent.Id, Date.today());
            Assert.areEqual(bank.Id,bkId);
            String bankAccountName = LWC_AdvancePaymentWizard.getBankAccountName(bkId);
            Assert.areEqual(bank.Name,bankAccountName);
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testgetVisibilityVerification(){
        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
       		Account ent = [SELECT Id FROM Account WHERE RecordTypeId = :accEntityRT LIMIT 1];
            Referencial__c banck = [SELECT Id FROM Referencial__c WHERE RecordTypeId = :refBank LIMIT 1];
            Boolean result = LWC_AdvancePaymentWizard.getVisibilityVerification(ent.Id, banck.Id, Date.today());
            System.assertEquals(true, result, 'Le résultat de la vérification de visibilité devrait être vrai.');
            }
        Test.stopTest();
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}