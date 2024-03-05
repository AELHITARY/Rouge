//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_AccountingClosureWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/07/2023
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_AccountingClosureWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_AccountingClosureWizard {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_ORD_PROVIDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  
    private static final Id customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final Id accEntityRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);
    private static final Id RT_AE_BANKREMITTANCE = DAL.getRecordTypeIdByDevName('AccountingEntry__c',Constants.ACCOUNTINGENTRY_BANKREMITTANCE_RT);
    private static final Id RT_WO = DAL.getRecordTypeIdByDevName('WorkOrder','workOrderService');
    private static final Id RT_SA = DAL.getRecordTypeIdByDevName('ServiceAppointment','ServiceAppointment');

    @testSetup 
    static void setup() {
        User user = Utils_Test.createUser(false,'stpUser', 'SetupUserName@test.sfd.test', 'SetupUserName','SetupUserName', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassWorkflowRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR020_Account;TR020_Order;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            // Création Ref
            List<Account> accToInsert = new List<Account>();
            accToInsert.add(new Account(Name = 'ORG',RecordTypeId = DAL.getRecordTypeIdByDevName('Account', 'FundingOrganization'), KparKReference__c = 'ORG-FIN1', startDate__c = Date.today()));
            // Création Referencial        
            List<Referencial__c> refToInsert = new List<Referencial__c>();
            refToInsert.add(Utils_Test.createPaymentMethod('VIREMENT','PAY-0012',Date.today(),null,false));
            Referencial__c paymentMethod = Utils_Test.createPaymentMethod('CHEQUE','PAY-0004',Date.today(),null,false);
            refToInsert.add(paymentMethod);
            insert refToInsert;
            Referencial__c refDep = Utils_Test.createReferencial('Dépôt', 'DEP', Date.today(), null, 
                                                                refEntityRT, true, true, true, true, true);
            Referencial__c bank = Utils_Test.createBankAccount('BANK','BANK-FIN1',Date.today(),null,true);
            // Création d'un compte, d'un fournisseur et d'une entité
            Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false);
            accToInsert.add(a);
            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
            accToInsert.add(provider1);
            Account ent = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refDep.Id, false);
            ent.stageName__c = 'En cours';
            accToInsert.add(ent);
            insert accToInsert;
            // Création chantier
            Chantier__c chant = Utils_Test.createChantier('test',ent.Id,true);
            // Création commande client, fournisseur, produit et lignes de commandes      
            Order newCustomerOrder = Utils_Test.createCustomerOrder(a.Id, false);
            newCustomerOrder.billingCity = 'test';
            newCustomerOrder.billingPostalCode = '12345';
            newCustomerOrder.chantier__c = chant.Id;
            newCustomerOrder.shippingName__c = 'test';
            newCustomerOrder.shippingPostalCode = '12345';
            newCustomerOrder.shippingCity = 'test';
            insert newCustomerOrder;        
            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            Order newProviderOrder1 = Utils_Test.createProviderOrder(ent.Id, newCustomerOrder.Id, provider1.Id ,true);

            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, null, productTest1.Id, false);
            newOrderItem1.billingDate__c = Date.today();
            newOrderItem1.pretaxAmount__c = 200;
            insert newOrderItem1;

            // Creation facture
            Invoice__c inv = Utils_Test.createInvoice('Facture', a.Id, ent.Id, Date.today(), ent.Id, chant.Id, false); 
            inv.amount__c = 220;
            inv.pretaxAmount__c = 200;
            inv.autoComputedAmount__c = false;
            inv.perceivedAmount__c = 100;
            inv.billingAccount__c = a.Id;
            inv.invoiceDate__c = Date.today();
            inv.customerOrder__c = newCustomerOrder.Id;
            inv.headOfficeLegalForm__c = 'Autre';
            inv.invoiceReference__c = '1';
            inv.status__c = 'Validée';
            insert inv;

            // Creation avoir
            CreditMemo__c cm = Utils_Test.createCreditMemo(a.Id, ent.Id, inv.Id, chant.Id, null, false);
            cm.creditMemoDate__c = Date.today();
            cm.pretaxAmount__c = 100;
            insert cm;

            // Création pièce comptable
            AccountingPiece__c accPiece = Utils_Test.createAccountingPiece(RT_AP_RECEIPT, newCustomerOrder.Id, ent.Id, ent.Id, bank.Id, 
            paymentMethod.Id, null, null, 100, Date.today(), null, null, true);
            accPiece.accountingDate__c = Date.today();
            accPiece.invoice__c = inv.Id;
            update accPiece;

            // Create new AccountingEntry
            AccountingEntry__c accEnt = new AccountingEntry__c(
                entryDate__c = Date.today(),
                entityBankAccount__c = bank.Id,
                amount__c = 100,
                RecordTypeId = RT_AE_BANKREMITTANCE,
                label__c = 'Encaissements',
                inputEntity__c = ent.Id
            );
            insert accEnt;

            //Création RDV
            OperatingHours oh = new OperatingHours(Name='K/K Semaine type standard' ,TimeZone='Europe/Paris' );
            insert oh;
            ServiceTerritory st = new ServiceTerritory(Name='DS',KparKReference__c='DS',OperatingHoursId=oh.Id,IsActive=true);
            insert st;
            ent.serviceTerritory__c = st.Id;
            update ent;
            WorkOrder wo = Utils_Test.createWorkOrder(RT_WO, newCustomerOrder.Id, true);
            ServiceAppointment sa = Utils_Test.createServiceAppointment(wo.Id, RT_SA, false);
            sa.SchedStartTime = DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0));
            sa.SchedEndTime = DateTime.newInstance(Date.today(), Time.newInstance(1,0,0,0));
            sa.Status = 'Confirmé';
            sa.fsl_dateConfirmation__c = date.today();
            sa.serviceTerritoryId = st.Id;
            insert sa;
            ServiceResource sr1= new ServiceResource(fsl_matriculeGC__c='RES01',fsl_SGID__c='SGID01',name='MetreurTest',ResourceType='T',RelatedRecordId=user.id,IsActive=true,IsCapacityBased=true);
            insert sr1;
            ServiceTerritoryMember stm= new ServiceTerritoryMember(EffectiveStartDate=Date.newInstance(2017, 1, 1),ServiceResourceId=sr1.id,ServiceTerritoryId=st.id,TerritoryType='P',OperatingHoursId=oh.Id); 
            insert stm;
            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa.id;
            ar1.ServiceResourceId = sr1.id;
            ar1.fsl_typeRessourceAttribuee__c='Principale';
            ar1.standardCost__c = 1000;
            ar1.billingDate__c = Date.today();
            insert ar1;
        }
    }
    
    @isTest
    private static void testCloture(){
        
        Test.startTest();     
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){       
            List<Account> depotList = new List<Account>();
            List<Account> providerList = new List<Account>();
            List<String> accIdList = new List<String>();
            List<String> specificRecordTypes = new List<String>{ 'Invoice', 'CreditMemo', 'AccountingEntry', 'AccountingPiece', 'AssignedResource', 'OrderItem'};
            List<String> accountsProviderId =  new List<String>();
            depotList = LWC_AccountingClosureWizard.getDepotsAccounts();
            if(!depotList.isEmpty()){
                for(Account acc : depotList){
                    accIdList.add(acc.Id);
                }
            }
            providerList = LWC_AccountingClosureWizard.getProviderAccounts();
            if(!providerList.isEmpty()){
                for(Account acc : providerList){
                    accountsProviderId.add(acc.Id);
                }
            }      
            LWC_AccountingClosureWizard.RecapRecordsToUpdateObject result = LWC_AccountingClosureWizard.retrieveRecordsToClose(accIdList[0], Date.today(), specificRecordTypes, accountsProviderId);
            LWC_AccountingClosureWizard.closeRecords(Date.today(), result.invoiceIdList, result.creditMemoIdList, result.accPieceIdList, result.accEntryIdList, result.orderItemIdList, result.assignedResourceIdList, result.recordNameByIdMap);

            //vérif clôture des enregistrements
            Invoice__c inv = [SELECT closingDate__c FROM Invoice__c WHERE closingDate__c != null LIMIT 1];
            Assert.areEqual(Date.today(), inv.closingDate__c);
            CreditMemo__c cm = [SELECT closingDate__c FROM CreditMemo__c WHERE closingDate__c != null LIMIT 1];
            Assert.areEqual(Date.today(), cm.closingDate__c);
            AccountingPiece__c accPiece = [SELECT closingDate__c FROM AccountingPiece__c WHERE closingDate__c != null LIMIT 1];
            Assert.areEqual(Date.today(), accPiece.closingDate__c);
            List<AccountingEntry__c> accEntList = [SELECT closingDate__c FROM AccountingEntry__c WHERE closingDate__c != null];
            for(AccountingEntry__c accEnt : accEntList){
                Assert.areEqual(Date.today(), accEnt.closingDate__c);
            }
            OrderItem oi = [SELECT closingDate__c FROM OrderItem WHERE closingDate__c != null LIMIT 1];
            Assert.areEqual(Date.today(), oi.closingDate__c);
            AssignedResource ar = [SELECT closingDate__c FROM AssignedResource WHERE closingDate__c != null LIMIT 1];
            Assert.areEqual(Date.today(), ar.closingDate__c);
        }
        Test.stopTest();
    }

    @isTest
    private static void testClotureWithError(){
        Test.startTest();     
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        User userWithBypass = Utils_Test.createUser(true,'testmlg3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', null, null);

        //Mise à jour des enregistrement avec un user avec bypass pour générer des erreurs
        System.runAs(userWithBypass){
            //Mise à jour Setting rollup Helper à true pour permettre le déclenchement des VR custom
            rh2__PS_Settings__c rollupValRule = new rh2__PS_Settings__c(rh2__Run_Validation_Rule__c = true);
            insert rollupValRule;

            Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];
            CreditMemo__c cm = [SELECT Id FROM CreditMemo__c LIMIT 1];
            AccountingPiece__c accPiece = [SELECT Id FROM AccountingPiece__c LIMIT 1];
            AccountingEntry__c accEntry = [SELECT Id FROM AccountingEntry__c LIMIT 1];
            AssignedResource ar = [SELECT Id FROM AssignedResource LIMIT 1];
            OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];

            inv.amount__c = null;
            update inv;

            cm.headOfficeShareCapital__c = null;
            update cm;

            accPiece.account__c = null;
            accPiece.order__c = null;
            accPiece.invoice__c = null;
            update accPiece;

            accEntry.label__c = '';
            update accEntry;

            ar.additionalCost__c  = -1;
            update ar;

            oi.estimatedProductCost__c = -1;
            update oi;
        }

        System.runAs(user){
            Account ent = [SELECT Id FROM Account WHERE Name = 'MAGTESTTEST' LIMIT 1];
            List<String> specificRecordTypes = new List<String>{ 'Invoice', 'CreditMemo', 'AccountingPiece','AccountingEntry', 'AssignedResource', 'OrderItem'};
            Account provider1 = [SELECT Id FROM Account WHERE Name = 'PROVIDERONE' LIMIT 1];
            List<String> accountsProviderId =  new List<String>();
            accountsProviderId.Add(provider1.Id);

            Invoice__c inv = [SELECT Name FROM Invoice__c LIMIT 1];
            CreditMemo__c cm = [SELECT Name FROM CreditMemo__c LIMIT 1];
            AccountingPiece__c accPiece = [SELECT Name FROM AccountingPiece__c LIMIT 1];
            AccountingEntry__c accEntry = [SELECT Name FROM AccountingEntry__c LIMIT 1];
            AssignedResource ar = [SELECT AssignedResourceNumber FROM AssignedResource LIMIT 1];
            OrderItem oi = [SELECT OrderItemNumber FROM OrderItem LIMIT 1];
            
            LWC_AccountingClosureWizard.RecapRecordsToUpdateObject result = LWC_AccountingClosureWizard.retrieveRecordsToClose(ent.Id, Date.today(), specificRecordTypes, accountsProviderId);
            LWC_AccountingClosureWizard.RecapRecordsUpdated recapUpdate = LWC_AccountingClosureWizard.closeRecords(Date.today(), result.invoiceIdList, result.creditMemoIdList, result.accPieceIdList, result.accEntryIdList, result.orderItemIdList, result.assignedResourceIdList, result.recordNameByIdMap);
            
            //Vérif nombres d'enregistrements en erreur correct pour chaque type
            Assert.areEqual('1',recapUpdate.numberOfFailedInvoices);
            Assert.areEqual('1',recapUpdate.numberOfFailedCreditMemos);
            Assert.areEqual('1',recapUpdate.numberOfFailedAccountingPieces);
            Assert.areEqual('1',recapUpdate.numberOfFailedAccountingEntries);
            Assert.areEqual('1',recapUpdate.numberOfFailedAssignedResources);
            Assert.areEqual('1',recapUpdate.numberOfFailedOrderItems);

            Set<String> recordNameList = new Set<String>();
            for(LWC_AccountingClosureWizard.RecordUpdateError errorLine : recapUpdate.errorList){
                if(!recordNameList.Contains(errorLine.recordName)){
                    recordNameList.add(errorLine.recordName);
                }
            }

            //Vérif si Nom des enregistrements en erreur présent dans les messages en retour de cloture
            Assert.areEqual(true,recordNameList.contains(inv.Name));
            Assert.areEqual(true,recordNameList.contains(cm.Name));
            Assert.areEqual(true,recordNameList.contains(accPiece.Name));
            Assert.areEqual(true,recordNameList.contains(accEntry.Name));
            Assert.areEqual(true,recordNameList.contains(ar.AssignedResourceNumber));
            Assert.areEqual(true,recordNameList.contains(oi.OrderItemNumber));
        }
        Test.stopTest();
    }

    @isTest
    private static void testGetPreviousBusinessDayDate(){
        Test.startTest();     
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
            Date previousBusinessDAY = Date.today().addDays(-1);
            while(!BusinessHours.isWithin(bh.Id, previousBusinessDAY)){
                previousBusinessDAY = previousBusinessDAY.addDays(-1);
            }

            Date result = LWC_AccountingClosureWizard.getPreviousBusinessDayDate();
            Assert.areEqual(previousBusinessDAY, result);
        }
        Test.stopTest();
    }

    @isTest
    private static void testUtils() {
        Test.startTest();
        AuraHandledException error = LWC_AccountingClosureWizard.generateAuraException('TEST');
        Assert.areEqual('TEST',error.getMessage());
        Test.stopTest();
    }
}