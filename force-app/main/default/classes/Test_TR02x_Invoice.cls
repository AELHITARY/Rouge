//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Invoice
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 08/02/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_TR02x_Invoice {
    private static final String RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final String RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final String RT_INV_INVOICE = DAL.getRecordTypeIdByDevName('Invoice__c',Constants.INVOICE_INVOICE_RT); 
    private static final String RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);

    @testSetup 
    static void setup() {
           
        // Création ref  
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        refList.add(refDep);
        refList.add(refMag);
        insert refList;

        // Création entite     
        List<Account> accList = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        //Compte
        Account a = Utils_Test.createAccount('name', 'name', 'test@test.fr', RT_ACC_PERSO, null, 'Email', false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(a);
        insert accList;

        // Chantier
        Chantier__c chant = Utils_Test.createChantier('test', a.Id, false);
        chant.serviceEntity__c = entiteDep.Id;
        chant.salesEntity__c = entiteMag.Id;
        chant.heatingMode__c = 'Individuel Electrique';
        insert chant;

        // Produit
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
    }

    @isTest
    private static void testValidationInvoice() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entiteDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1]; 
            Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];
            Chantier__c chant = [SELECT Id,serviceEntity__c,salesEntity__c FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            
            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entiteMag.Id, entiteDep.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            insert newCustomerOrder;

            newCustomerOrder.serviceEntity__c = entiteDep.Id;
            newCustomerOrder.salesEntity__c = entiteMag.Id;
            update newCustomerOrder;
            
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                        FROM PricebookEntry 
                                        WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            // Ligne Commande
            List<OrderItem> oiList = new List<OrderItem>();
            OrderItem newOrderItem = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, false);
            oiList.add(newOrderItem);
            OrderItem newOrderItem2 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, false);
            newOrderItem2.Quantity = 2;
            oiList.add(newOrderItem2);
            insert oiList;

            // Actif        
            List<Asset> astList = new List<Asset>();
            Asset newAsset = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset1', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, acc.Id, false);
            astList.add(newAsset);
            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset2', newCustomerOrder.Id, productTest1.Id, newOrderItem2.Id, null, acc.Id, false);
            astList.add(newAsset2);
            insert astList;

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entiteMag.Id, null, entiteDep.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            List<InvoiceLine__c> invLines = new List<InvoiceLine__c>(); 
            InvoiceLine__c invLine = Utils_Test.createInvoiceLine(inv.Id, null, newAsset.Id, newOrderItem.Id, 'TEST', 5,10, 1, false);
            InvoiceLine__c invLine2 = Utils_Test.createInvoiceLine(inv.Id, null, newAsset2.Id, newOrderItem2.Id, 'TEST2', 5,10, 1, false);
            invLines.add(invLine);
            invLines.add(invLine2);
            insert invLines;

            // MAJ
            inv.invoiceDate__c = Date.today();
            update inv;

            inv = [SELECT status__c,invoiceReference__c FROM Invoice__c LIMIT 1];

            //test passage au statut validée
            Assert.areEqual(inv.status__c, 'Validée');
            //Test référence renseignée
            Assert.areEqual(inv.invoiceReference__c,'FAC/0000001');

            Test.stopTest();
        }
    }

    @isTest
    private static void testDoubleInvoices() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            
            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entite.Id, entite.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            newCustomerOrder.serviceEntity__c = entite.Id;
            newCustomerOrder.salesEntity__c = entite.Id;
            insert newCustomerOrder;

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                        FROM PricebookEntry 
                                        WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            // Ligne Commande
            List<OrderItem> oiList = new List<OrderItem>();
            OrderItem newOrderItem = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, false);
            oiList.add(newOrderItem);
            OrderItem newOrderItem2 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, false);
            newOrderItem2.Quantity = 2;
            oiList.add(newOrderItem2);
            insert oiList;

            // Actif        
            List<Asset> astList = new List<Asset>();
            Asset newAsset = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset1', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, acc.Id, false);
            astList.add(newAsset);
            Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset2', newCustomerOrder.Id, productTest1.Id, newOrderItem2.Id, null, acc.Id, false);
            astList.add(newAsset2);
            insert astList;

            // Creation facture
            List<Invoice__c> invList = new List<Invoice__c>();
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, false);
            invList.add(inv);

            // Creation facture 2
            Invoice__c inv2  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, false);
            invList.add(inv2);
            insert invList;

            // Creation ligne facture
            List<InvoiceLine__c> invLinesToIns = new List<InvoiceLine__c>();
            invLinesToIns.add(Utils_Test.createInvoiceLine(inv.Id, null, newAsset.Id, newOrderItem.Id, 'TEST', 5,10, 1, false));
            invLinesToIns.add(Utils_Test.createInvoiceLine(inv.Id, null, newAsset2.Id, newOrderItem2.Id, 'TEST2', 5,10, 1, false));
            invLinesToIns.add( Utils_Test.createInvoiceLine(inv2.Id, null, newAsset.Id, newOrderItem.Id, 'TEST', 10, 20, 1, false));
            insert invLinesToIns;



            // MAJ
            List<Invoice__c> invoiceToUpdate = new List<Invoice__c>();
            inv.invoiceDate__c = Date.today();
            invoiceToUpdate.add(inv);
           
            // MAJ
            inv2.invoiceDate__c = Date.today();
            invoiceToUpdate.add(inv2);
            
            update invoiceToUpdate;

            invList = [SELECT status__c,dueDate__c FROM Invoice__c];

            //Vérification montant
            //Vérification Date d'échéance
            for(Invoice__c validatedInv : invList){            
                Assert.areEqual(validatedInv.status__c, 'Validée');
                Assert.areEqual(validatedInv.dueDate__c,Date.today().addDays(30));
            }
            Test.stopTest();
        }
    }

    @isTest
    private static void testAccountingPieceInvoice() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            
            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            Referencial__c paymentMethod = Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,true);

            Test.startTest();

            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entite.Id, entite.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            newCustomerOrder.serviceEntity__c = entite.Id;
            newCustomerOrder.salesEntity__c = entite.Id;
            insert newCustomerOrder;

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                        FROM PricebookEntry 
                                        WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            // Ligne Commande
            /*List<OrderItem> oiList = new List<OrderItem>();
            OrderItem newOrderItem = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, false);
            oiList.add(newOrderItem);*/
            /*OrderItem newOrderItem2 = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, false);
            newOrderItem2.Quantity = 2;
            oiList.add(newOrderItem2);*/
            //insert oiList;

            // Actif        
            /*List<Asset> astList = new List<Asset>();
            Asset newAsset = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset1', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, acc.Id, false);
            astList.add(newAsset);*/
            /*Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset2', newCustomerOrder.Id, productTest1.Id, newOrderItem2.Id, null, acc.Id, false);
            astList.add(newAsset2);*/
            //insert astList;

            // Création banque
            Referencial__c bank = Utils_Test.createBankAccount('BANK','BANK-FIN1',Date.today(),null,true);
            BankAccountVisibility__c bankV = new BankAccountVisibility__c(bankAccount__c=bank.Id, entity__c=entite.Id, startDate__c = Date.today());
            insert bankV;

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            /*List<InvoiceLine__c> invLinesToIns = new List<InvoiceLine__c>();
            invLinesToIns.add(Utils_Test.createInvoiceLine(inv.Id, null, newAsset.Id, newOrderItem.Id, 'TEST', 5,10, 1, false));
            //invLinesToIns.add(Utils_Test.createInvoiceLine(inv.Id, null, newAsset2.Id, newOrderItem2.Id, 'TEST2', 5,10, 1, false));
            insert invLinesToIns;*/

            // MAJ
            inv.invoiceDate__c = Date.today();
            update inv;
            // APP
            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, entite.Id, entite.Id, bank.Id, 
                                                                            paymentMethod.Id, null, null, 100, Date.today(), null, null, false);
                                                                            
            accPiece.accountingDate__c = Date.today();
            accPiece.invoice__c = inv.Id;
            //update accPiece;
            insert accPiece;

            inv = [SELECT paymentDate__c,perceivedAmount__c FROM Invoice__c LIMIT 1];

            //Vérif Montant des pièces et dernière date comptable 
            Assert.areEqual(inv.perceivedAmount__c,100);
            Assert.areEqual(inv.paymentDate__c,Date.today());

            Test.stopTest();
        }
    }

    @isTest
    private static void testCancelInvoice() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            
            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entite.Id, entite.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            newCustomerOrder.serviceEntity__c = entite.Id;
            newCustomerOrder.salesEntity__c = entite.Id;
            insert newCustomerOrder;

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                        FROM PricebookEntry 
                                        WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            // Ligne Commande
            OrderItem newOrderItem = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, true);
           
            Asset newAsset = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset1', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, acc.Id, true);

            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            Utils_Test.createInvoiceLine(inv.Id, null, newAsset.Id, newOrderItem.Id, 'TEST',5,10, 1, true);

            // MAJ
            //inv.cancellationDate__c = Date.today();
            inv.cancelledAmount__c = 0;
            update inv;

            inv = [SELECT status__c FROM Invoice__c LIMIT 1];

            //Vérif statut annulé
            Assert.areEqual(inv.status__c,'Annulée');

            Test.stopTest();
        }
    }

    @isTest
    private static void testDelete() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            
            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entite.Id, entite.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            newCustomerOrder.serviceEntity__c = entite.Id;
            newCustomerOrder.salesEntity__c = entite.Id;
            insert newCustomerOrder;
  
            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);

            inv.invoiceDate__c = Date.Today();
            update inv;

            try {
                delete inv;
            } catch(Exception ex) {                
            }

            //Vérif facture non supprimée
            List<Invoice__c> invList = [SELECT Id FROM invoice__c];
            Assert.areEqual(invList.size(), 1);

            Test.stopTest();
        }
    }

    @isTest
    private static void testDeleteInvoiceLine() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);

        System.runAs(user){
            Test.startTest();

            Account acc = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId != :RT_ACC_PERSO LIMIT 1];
            Chantier__c chant = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 LIMIT 1];
            
            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(acc.Id, chant.Id, entite.Id, entite.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            newCustomerOrder.serviceEntity__c = entite.Id;
            newCustomerOrder.salesEntity__c = entite.Id;
            insert newCustomerOrder;

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                        FROM PricebookEntry 
                                        WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            // Ligne Commande
            OrderItem newOrderItem = Utils_Test.createOrderItem(newCustomerOrder.Id, pbEntry.Id, null, null, true);

            Asset newAsset = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset1', newCustomerOrder.Id, productTest1.Id, newOrderItem.Id, null, acc.Id, true);
            
            // Creation facture
            Invoice__c inv  = Utils_Test.createInvoice('Facture', acc.Id, entite.Id, null, entite.Id, chant.Id, newCustomerOrder.Id, RT_INV_INVOICE, true);
            // Creation ligne facture
            InvoiceLine__c invLine = Utils_Test.createInvoiceLine(inv.Id, null, newAsset.Id, newOrderItem.Id, 'TEST', 5, 10, 1, true);
            
            invLine.description__c = 'TEST';
            update invLine;

            inv.invoiceDate__c = Date.Today();
            update inv;
            
            try {
                delete invLine;
            } catch(Exception ex) {}

            //Vérif ligne de facture non supprimée
            List<InvoiceLine__c> invLineList = [SELECT Id FROM InvoiceLine__c];
            Assert.areEqual(invLineList.size(), 1);

            Test.stopTest();
        }
    }
}