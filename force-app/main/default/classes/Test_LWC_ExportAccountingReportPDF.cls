//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_ExportAccountingReportPDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 04/08/2023
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_ExportAccountingReportPDF
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
public without sharing class Test_LWC_ExportAccountingReportPDF {
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String ACCOUNTINGPIECE_DOUBTFULDEBT_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_DOUBTFULDEBT_RT);
    private static final String ACCOUNTINGENTRY_BANKREMITTANCE_RTID = DAL.getRecordTypeIdByDevName('AccountingEntry__c', Constants.ACCOUNTINGENTRY_BANKREMITTANCE_RT);
    private static final String ACCOUNTINGENTRY_UNPAID_RTID = DAL.getRecordTypeIdByDevName('AccountingEntry__c', Constants.ACCOUNTINGENTRY_UNPAID_RT);
    private static final String ACCOUNTINGENTRY_BANKFEES_RTID = DAL.getRecordTypeIdByDevName('AccountingEntry__c', Constants.ACCOUNTINGENTRY_BANKFEES_RT);
    private static final Id REFERENCIAL_BANKACCOUNT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', 'BankAccount');
    private static final Id REFERENCIAL_PAYMENTMETHOD_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', 'PaymentMethod');
    private static final String ACCOUNTINGPIECE_UNPAID_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_UNPAID_RT);
    private static final String ACCOUNTINGPIECE_RECEIPT_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_RECEIPT_RT);
    private static final String ACCOUNTINGPIECE_RECEIPTCANCELLATION_RTID = DAL.getRecordTypeIdByDevName('AccountingPiece__c', Constants.ACCOUNTINGPIECE_RECEIPTCANCELLATION_RT);
    


    @testSetup 
    static void setup() {
        PropertiesUtils.setDateValue('export.nonCollecte.dateProfondeur', Date.newInstance(2007,01,01));
        PropertiesUtils.setBooleanValue('merkure.api.debug', true);
        String refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
        
        Account account = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', true);

        // Création dépôt     
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account entity = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        entity.migratedToK3__c = true;
        insert entity;

        //Création chantier
        Chantier__c chantier = Utils_Test.createChantier('test',entity.Id,true);
    }
    
    @isTest
    private static void notCollectedReport() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            String exportType = 'Non collecté';

            Date startDate = Date.today();

            Account account = [SELECT Id,Name FROM Account WHERE Name = 'Name name' LIMIT 1];
            Account entity = [SELECT Id,Name FROM Account WHERE Name = 'TEST' LIMIT 1];
            Chantier__c chantier = [SELECT Id,Name FROM Chantier__c LIMIT 1];

            Test.startTest();

            //Création Commande
            Order customerOrder = Utils_Test.createCustomerOrder(account.Id, chantier.Id, null, entity.Id, false);
            customerOrder.effectiveDate = Date.today();
            customerOrder.Type = 'Commande client';
            customerOrder.oldCompositeStatus__c = 'Non confirmé';
            
            insert customerOrder;
            customerOrder.pretaxAmount__c = 1000;
            customerOrder.legacyReference__c = customerOrder.Id;
            customerOrder.serviceEntity__c = entity.Id;
            customerOrder.firstInvoiceDate__c = Date.Today();
            update customerOrder;
            
            //Création factures
            List<Invoice__c> invoices = new List<Invoice__c>();
            Invoice__c invoice = Utils_Test.createInvoice('Facture Test', account.Id, entity.Id, Date.today(), entity.Id, chantier.Id, false);
            Invoice__c invoice2 = Utils_Test.createInvoice('Facture Test2', account.Id, entity.Id, Date.today().addDays(-31), entity.Id, chantier.Id, false);
            invoice.customerOrder__c = customerOrder.Id;
            invoice.amount__c = 100;
            invoice.autoComputedAmount__c = false;
            invoices.Add(invoice);
            invoice2.customerOrder__c = customerOrder.Id;
            invoice2.amount__c = 100;
            invoice2.autoComputedAmount__c = false;
            invoices.Add(invoice2);
            insert invoices;

            //Création avoirs
            List<CreditMemo__c> creditMemos = new List<CreditMemo__c>();
            CreditMemo__c creditMemo = Utils_Test.createCreditMemo(account.Id, entity.Id, invoice.Id, chantier.Id, Date.today(), false);
            CreditMemo__c creditMemo2 = Utils_Test.createCreditMemo(account.Id, entity.Id, invoice.Id, chantier.Id, Date.today(), false);
            creditMemo.customerOrder__c = customerOrder.Id;
            creditMemo.amount__c = 100;
            creditMemos.Add(creditMemo);
            creditMemo2.customerOrder__c = customerOrder.Id;
            creditMemo2.amount__c = 100;
            creditMemos.Add(creditMemo2);

            insert creditMemos;

            //Création pièces comptables
            List<AccountingPiece__c> accountingPieces = new List<AccountingPiece__c>();
            AccountingPiece__c accountingPiece = Utils_Test.createAccountingPiece(ACCOUNTINGPIECE_DOUBTFULDEBT_RTID, customerOrder.Id, entity.Id, entity.Id, null, null, 
            null, null, 100, Date.today(), Date.today(), Date.today(), true);

            Map<String, String> availableEntities = LWC_ExportAccountingReportPDF.getEntityAccounts();
            Assert.areEqual(1,availableEntities.size());

            String entityid = availableEntities.get('TEST').split('/')[0];
            String entityName = availableEntities.get('TEST').split('/')[1];
            Assert.areEqual('TEST',entityName);

            String[] bankAccounts = new String[]{};

            String jsonString = LWC_ExportAccountingReportPDF.generateJsonObject(exportType, entityid, entityName, startDate, null, bankAccounts);

            //Vérif Json généré (Montant total factures : avoir / pièces comtpables)
            LWC_ExportAccountingReportPDF.NotCollectedReportObject jsonObject = new LWC_ExportAccountingReportPDF.NotCollectedReportObject();
            jsonObject = (LWC_ExportAccountingReportPDF.NotCollectedReportObject)JSON.deserialize(jsonString, LWC_ExportAccountingReportPDF.NotCollectedReportObject.class);
            Assert.areEqual(200,jsonObject.Orders[0].invoicesAmount);
            Assert.areEqual(200,jsonObject.Orders[0].creditMemosAmount);
            Assert.areEqual(100,jsonObject.Orders[0].doubtfulAccountingPieceAmount);

            String result = LWC_ExportAccountingReportPDF.renderDocumentPDF(exportType, entityid, entityName, startDate, null, jsonString);

            //vérif création lien vers document sur entité
            List<ContentDocumentLink> ctLinkList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :entityid];
            Assert.areEqual(1,ctLinkList.size());

            Test.stopTest();
        }
    }

    @isTest
    private static void bankReport(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account account = [SELECT Id,Name FROM Account WHERE Name = 'Name name' LIMIT 1];
            Account entity = [SELECT Id,Name FROM Account WHERE Name = 'TEST' LIMIT 1];
            Chantier__c chantier = [SELECT Id,Name FROM Chantier__c LIMIT 1];

            Test.startTest();

            //Création comtpes bancaires visibles depuis le dépôt

            List<Referencial__c> refList = new List<Referencial__c>();
            Referencial__c refBank = Utils_Test.createReferencial('BANK TEST', 'refBank', Date.today(), null, REFERENCIAL_BANKACCOUNT_RTID, true, true, true, true, false);
            refBank.bank__c = 'BANQUE DE TEST';
            refBank.bic__c = 'INGBFRPP';
            refBank.iban__c = 'FR1420041010050500013M02606';
            refList.Add(refBank);
            Referencial__c refBank2 = Utils_Test.createReferencial('BANK TEST2', 'refBank2', Date.today(), null, REFERENCIAL_BANKACCOUNT_RTID, true, true, true, true, false);
            refBank2.bank__c = 'BANQUE DE TEST 2';
            refBank2.bic__c = 'INGBFRPP';
            refBank2.iban__c = 'FR1420041010050500013M02606';
            refList.Add(refBank2);

            Referencial__c refPaymentMethod = Utils_Test.createReferencial('PAYMENT METHOD TEST', 'refPaymentMethod', Date.today(), null, REFERENCIAL_PAYMENTMETHOD_RTID, true, true, true, true, false);
            refList.Add(refPaymentMethod);
            
            insert refList;

            List<BankAccountVisibility__c> bankAccountVisibilityList = new List<BankAccountVisibility__c>();
            BankAccountVisibility__c bankAccountVisibility = new BankAccountVisibility__c(bankAccount__c = refBank.Id, entity__c = entity.Id, startDate__c = Date.today());
            BankAccountVisibility__c bankAccountVisibility2 = new BankAccountVisibility__c(bankAccount__c = refBank2.Id, entity__c = entity.Id, startDate__c = Date.today());
            bankAccountVisibilityList.Add(bankAccountVisibility);
            bankAccountVisibilityList.Add(bankAccountVisibility2);
            insert bankAccountVisibilityList;


            //Type de journal et date de début et de fin d'observation de l'export
            String exportType = 'Journal des banques';
            Date startDate = Date.today();
            Date endDate = Date.today();

            //Création Commande
            Order customerOrder = Utils_Test.createCustomerOrder(account.Id, chantier.Id, null, entity.Id, false);
            customerOrder.effectiveDate = Date.today();
            customerOrder.Type = 'Commande client';
            customerOrder.oldCompositeStatus__c = 'Non confirmé';
            insert customerOrder;
            customerOrder.pretaxAmount__c = 1000;
            customerOrder.serviceEntity__c = entity.Id;
            update customerOrder;

            //Création pièces comptable
            AccountingPiece__c accountingPiece = Utils_Test.createAccountingPiece(ACCOUNTINGPIECE_RECEIPT_RTID, customerOrder.Id, entity.Id, entity.Id, refBank.Id, refPaymentMethod.Id, 
            null, null, 100, Date.today(), Date.today(), Date.today(), true);
           
            //Création écriture comptable
            List<AccountingEntry__c> accountingEntries = new List<AccountingEntry__c>();
            AccountingEntry__c accountingEntry = new AccountingEntry__c(RecordTypeId = ACCOUNTINGENTRY_BANKFEES_RTID, 
                                                                            amount__c = 1000,
                                                                            KparKReference__c = 'REF-TEST',
                                                                            label__c = 'Frais bancaire',
                                                                            entryDate__c = Date.today(),
                                                                            entityBankAccount__c = refBank.Id,
                                                                            inputEntity__c = entity.Id);
            AccountingEntry__c accountingEntry2 = new AccountingEntry__c(RecordTypeId = ACCOUNTINGENTRY_UNPAID_RTID, 
                                                                            amount__c = -200,
                                                                            KparKReference__c = 'REF-TEST2',
                                                                            label__c = 'Impayés',
                                                                            entryDate__c = Date.today(),
                                                                            entityBankAccount__c = refBank2.Id,
                                                                            inputEntity__c = entity.Id);
            accountingEntries.Add(accountingEntry);
            accountingEntries.Add(accountingEntry2);
            insert accountingEntries;

            //Sélection des comtpes bancaires à récupérer dans l'export
            Map<String, String> bankAccounts = LWC_ExportAccountingReportPDF.getBankAccounts(entity.Id, startDate, endDate);
            //Vérif Comptes bancaires disponibles 
            Assert.areEqual(2,bankAccounts.size());

            String[] bankAccountsSelected = new String[]{ bankAccounts.get('BANK TEST'), bankAccounts.get('BANK TEST2')};

            String jsonString = LWC_ExportAccountingReportPDF.generateJsonObject(exportType, entity.Id, entity.Name, startDate, endDate, bankAccountsSelected);
            //Vérif Json généré
            LWC_ExportAccountingReportPDF.BankReportObject jsonObject = new LWC_ExportAccountingReportPDF.BankReportObject();
            jsonObject = (LWC_ExportAccountingReportPDF.BankReportObject)JSON.deserialize(jsonString, LWC_ExportAccountingReportPDF.BankReportObject.class);
            //Filtré sur banques sélectionnées
            Assert.areEqual(2,jsonObject.bankAccountLines.size());
            //2 écritures associé à la 1ère banque
            Assert.areEqual(2,jsonObject.bankAccountLines[0].details.size());
            //pièce comptable ajoutée dans distribution
            Assert.areEqual(100,jsonObject.bankAccountLines[0].distribution[0].amount);

            String result = LWC_ExportAccountingReportPDF.renderDocumentPDF(exportType, entity.Id, entity.Name, startDate, endDate, jsonString);

            //vérif création lien vers document sur entité
            List<ContentDocumentLink> ctLinkList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :entity.Id];
            Assert.areEqual(1,ctLinkList.size());

            Test.stopTest();
        }
    }

    @isTest
    private static void accountingPiecesReport(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account account = [SELECT Id,Name FROM Account WHERE Name = 'Name name' LIMIT 1];
            Account entity = [SELECT Id,Name FROM Account WHERE Name = 'TEST' LIMIT 1];
            Chantier__c chantier = [SELECT Id,Name FROM Chantier__c LIMIT 1];


            Test.startTest();
            Referencial__c refBank = Utils_Test.createReferencial('BANK TEST', 'REFERENCIAL_BANKACCOUNT_RTID', Date.today(), null, REFERENCIAL_BANKACCOUNT_RTID, true, true, true, true, false);
            refBank.bank__c = 'BANQUE DE TEST';
            refBank.bic__c = 'INGBFRPP';
            refBank.iban__c = 'FR1420041010050500013M02606';
            insert refBank;

            //Création Commande
            Order customerOrder = Utils_Test.createCustomerOrder(account.Id, chantier.Id, null, entity.Id, false);
            customerOrder.effectiveDate = Date.today();
            customerOrder.Type = 'Commande client';
            customerOrder.oldCompositeStatus__c = 'Non confirmé';
            
            insert customerOrder;
            customerOrder.pretaxAmount__c = 1000;
            //ustomerOrder.legacyReference__c = customerOrder.Id;
            customerOrder.serviceEntity__c = entity.Id;
            update customerOrder;

            String exportType = 'Journal des OD';
            Date startDate = Date.today().addDays(-30);
            Date endDate = Date.today();
            String[] bankAccounts = new String[]{};

            //Création piece comptable
            AccountingPiece__c accountingPiece = Utils_Test.createAccountingPiece(ACCOUNTINGPIECE_DOUBTFULDEBT_RTID, customerOrder.Id, entity.Id, entity.Id, refBank.Id, null, 
            null, null, 100, Date.today(), Date.today(), Date.today().addDays(-20), true);

            String jsonString = LWC_ExportAccountingReportPDF.generateJsonObject(exportType, entity.Id, entity.Name, startDate, endDate, bankAccounts);

            //Vérif Json généré
            LWC_ExportAccountingReportPDF.OtherTypeReportObject jsonObject = new LWC_ExportAccountingReportPDF.OtherTypeReportObject();
            jsonObject = (LWC_ExportAccountingReportPDF.OtherTypeReportObject)JSON.deserialize(jsonString, LWC_ExportAccountingReportPDF.OtherTypeReportObject.class);
            //1 pièce récupérée
            Assert.areEqual(1,jsonObject.accountingObjects.size());
            //Montant de la pièce récupéré
            Assert.areEqual(100,jsonObject.accountingObjects[0].amount);
            
            String result = LWC_ExportAccountingReportPDF.renderDocumentPDF(exportType, entity.Id, entity.Name, startDate, endDate, jsonString);

            //vérif création lien vers document sur entité
            List<ContentDocumentLink> ctLinkList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :entity.Id];
            Assert.areEqual(1,ctLinkList.size());

            Test.stopTest();
        }
    }

    @isTest
    private static void sellReport(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Account account = [SELECT Id,Name FROM Account WHERE Name = 'Name name' LIMIT 1];
            Account entity = [SELECT Id,Name FROM Account WHERE Name = 'TEST' LIMIT 1];
            Chantier__c chantier = [SELECT Id,Name FROM Chantier__c LIMIT 1];


            Test.startTest();
            Referencial__c refBank = Utils_Test.createReferencial('BANK TEST', 'REFERENCIAL_BANKACCOUNT_RTID', Date.today(), null, REFERENCIAL_BANKACCOUNT_RTID, true, true, true, true, false);
            refBank.bank__c = 'BANQUE DE TEST';
            refBank.bic__c = 'INGBFRPP';
            refBank.iban__c = 'FR1420041010050500013M02606';
            insert refBank;

            //Création Commande
            Order customerOrder = Utils_Test.createCustomerOrder(account.Id, chantier.Id, null, entity.Id, false);
            customerOrder.effectiveDate = Date.today();
            customerOrder.Type = 'Commande client';
            customerOrder.oldCompositeStatus__c = 'Non confirmé';
            
            insert customerOrder;
            customerOrder.pretaxAmount__c = 1000;
            //ustomerOrder.legacyReference__c = customerOrder.Id;
            customerOrder.serviceEntity__c = entity.Id;
            update customerOrder;

            String exportType = 'Journal des ventes';
            Date startDate = Date.today().addDays(-30);
            Date endDate = Date.today();
            String[] bankAccounts = new String[]{};

            //Création factures
            List<Invoice__c> invoices = new List<Invoice__c>();
            Invoice__c invoice = Utils_Test.createInvoice('Facture Test', account.Id, entity.Id, Date.today().addDays(-5), entity.Id, chantier.Id, false);
            Invoice__c invoice2 = Utils_Test.createInvoice('Facture Test2', account.Id, entity.Id, Date.today().addDays(-20), entity.Id, chantier.Id, false);
            invoice.customerOrder__c = customerOrder.Id;
            invoice.amount__c = 100;
            invoice.invoiceReference__c = 'TEST';
            invoices.Add(invoice);
            invoice2.customerOrder__c = customerOrder.Id;
            invoice2.amount__c = 100;
            invoice2.invoiceReference__c = 'TEST2';
            invoices.Add(invoice2);
            insert invoices;

            //Création avoirs
            List<CreditMemo__c> creditMemos = new List<CreditMemo__c>();
            CreditMemo__c creditMemo = Utils_Test.createCreditMemo(account.Id, entity.Id, invoice.Id, chantier.Id, Date.today().addDays(-5), false);
            CreditMemo__c creditMemo2 = Utils_Test.createCreditMemo(account.Id, entity.Id, invoice.Id, chantier.Id, Date.today().addDays(-20), false);
            creditMemo.customerOrder__c = customerOrder.Id;
            creditMemo.amount__c = 100;
            creditMemo.creditMemoReference__c = 'TEST';
            creditMemos.Add(creditMemo);
            creditMemo2.customerOrder__c = customerOrder.Id;
            creditMemo2.amount__c = 100;
            creditMemo2.creditMemoReference__c = 'TEST2';
            creditMemos.Add(creditMemo2);

            insert creditMemos;
            
            String jsonString = LWC_ExportAccountingReportPDF.generateJsonObject(exportType, entity.Id, entity.Name, startDate, endDate, bankAccounts);

            //Vérif Json généré
            LWC_ExportAccountingReportPDF.OtherTypeReportObject jsonObject = new LWC_ExportAccountingReportPDF.OtherTypeReportObject();
            jsonObject = (LWC_ExportAccountingReportPDF.OtherTypeReportObject)JSON.deserialize(jsonString, LWC_ExportAccountingReportPDF.OtherTypeReportObject.class);
            //2 factures + 2 avoirs récupérés
            Assert.areEqual(4,jsonObject.accountingObjects.size());

            String result = LWC_ExportAccountingReportPDF.renderDocumentPDF(exportType, entity.Id, entity.Name, startDate, endDate, jsonString);

            //vérif création lien vers document sur entité
            List<ContentDocumentLink> ctLinkList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :entity.Id];
            Assert.areEqual(1,ctLinkList.size());

            Test.stopTest();
        }
    }

    @isTest
    private static void testUtils() {
        Test.startTest();
        AuraHandledException error = LWC_ExportAccountingReportPDF.generateAuraException('TEST');
        Assert.areEqual('TEST',error.getMessage());
        Test.stopTest();
    }
}