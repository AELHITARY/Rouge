//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_Order
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 15/06/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
public without sharing class Test_TR02x_Order {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id REF_MARGIN_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_CATALOGMARGIN_RT);
    private static final Id REF_PROVDELAY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);
    private static final Id REF_CANCELREASON_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', 'CustomerCancellationReason');
    private static final Id ACC_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final String NCC_IMPOSSIBILITY_RTID = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Impossibility');
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
 
    

    @testSetup 
    static void testSetup() {
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        // Création réf délai 
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refMarg = Utils_Test.createReferencial('Margin', 'Margin', Date.today(), null, REF_MARGIN_RTID, false, false, false, false, false);
        refMarg.productSubFamily__c = 'PVC';
        refMarg.productSubMaterial__c  = 'Ekilibre';
        refMarg.providerDelayType__c   = 'Standard';
        refMarg.margin__c = 2;
        refList.add(refMarg);

        // Création réf délai 
        Referencial__c refDelay = Utils_Test.createReferencial('Delay', 'Delay', Date.today(), null, REF_PROVDELAY_RTID, false, false, false, false, false);
        refDelay.productSubFamily__c = 'PVC';
        refDelay.productSubMaterial__c  = 'Ekilibre';
        refDelay.providerDelayType__c   = 'Standard';
        refDelay.concertedDelay__c = 4; 
        refDelay.contractualDelay__c = 4; 
        refDelay.minCommercialDelay__c = 5;
        refDelay.maxCommercialDelay__c = 10;
        refList.add(refDelay);

        // Création réf Cancellation reason
        Referencial__c refcancel = Utils_Test.createReferencial('RESILIATION AUTOMATIQUE', 'RESILIATION AUTOMATIQUE', Date.today(), null, REF_CANCELREASON_RTID, false, false, false, false, false);
        refList.add(refcancel);

        // Création ref
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refCgv = Utils_Test.createReferencial('CGV', 'CGV1', Date.today(), null, REF_TERMSANDCONT_RTID, false, false, false, false, false);
        refList.add(refDep);
        refList.add(refMag);
        refList.add(refCgv);
        insert refList;
        // Création entite     
        List<Account> accList = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        //Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', ACC_PROVIDER_RTID, null , null, false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(accountTest);
        accList.add(provider1);
        insert accList;
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c = secto.Id;
        chantier.serviceEntity__c = entiteDep.Id;
        chantier.salesEntity__c = entiteMag.Id;
        chantier.heatingMode__c = 'Individuel Electrique';
        insert chantier;
        // Opportunity
        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
        // Produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.isConvertibleAsset__c=true;
        insert prod;

        EntityProviderParameters__c enPt = new EntityProviderParameters__c();
        enPt.provider__c = provider1.Id;
        enPt.entity__c = entiteDep.Id;
        enPt.KparKReference__c = 'Tue';
        enPt.deliveryDays__c = 'Tue';
        enPt.startDate__c = Date.today();
        enPt.stageName__c = 'En cours';
        insert enPt;
    }

    @isTest 
    static void testCreateCPQCustomerOrder() {
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
    
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }

        Test.startTest();

        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, false);
        cpqQuote.SBQQ__Account__c = opp.AccountId;
        cpqQuote.chantier__c = chantier.Id;
        insert cpqQuote;
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, productTest1, true);

        // Garantie
        Entitlement enti = new Entitlement();
        enti.Name = 'Test';
        enti.AccountId = accountTest.Id;
        enti.quoteLineCPQ__c = cpqQuoteLine.Id;
        insert enti;

        // passage en non transmis
        cpqQuote.quoteIsValid__c = true;
        cpqQuote.dateTransmissionClient__c = Date.today();
        cpqQuote.dateAcceptationClient__c = Date.today();
        cpqQuote.MoyenTransmissionClient__c = 'Par email';
        cpqQuote.SBQQ__Ordered__c = true;
        update cpqQuote;
        
        Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
        customerOrder.SBQQ__Quote__c = cpqQuote.Id;
        customerOrder.EffectiveDate = Date.today();
        insert customerOrder;
        OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);        
        oi.SBQQ__QuoteLine__c = cpqQuoteLine.Id;
        insert oi;
        
        Test.stopTest();
    }

    @isTest 
    static void testProviderOrder() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.byPassTrigger__c = 'QA_KMDCEinstein';
        user.byPassValidationRule__c = true;
        update user;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PROVIDER_RTID LIMIT 1];
            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            List<Order> ordList = new List<Order>();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            insert customerOrder;
            Order providerOrder = Utils_Test.createProviderOrder(entDep.Id, customerOrder.Id, provider1.Id ,false);
            insert providerOrder;
            /*ordList.add(customerOrder);
            ordList.add(providerOrder);
            insert ordList;*/

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', customerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;

            OrderItem oi2 = Utils_Test.createOrderItem(providerOrder.Id, pbEntry.Id, newAsset1.Id, productTest1.Id,true);

            //Provider order status change
            
            providerOrder.ActivatedDate=Date.today();
            update providerOrder;

            providerOrder.transmissionDate__c=Date.today();
            update providerOrder;

            oi2.confirmationDate__c=Date.today();
            update oi2;

            providerOrder.Name='test3';
            update providerOrder;

            oi2.manufacturingStart__c=Date.today();
            update oi2;

            providerOrder.Name='test';
            update providerOrder;

            oi2.manufacturingEnd__c=Date.today();
            update oi2;

            providerOrder.Name='test2';
            update providerOrder;

            oi2.shippingDate__c=Date.today();
            update oi2;

            providerOrder.Name='test';
            update providerOrder;

            oi2.deliveryDate__c=Date.today();
            update oi2;

            providerOrder.Name='test2';
            update providerOrder;

            oi2.billingDate__c=Date.today();
            update oi2;
            
            providerOrder.Name='test';
            update providerOrder;
            /*
            oi2.receivedDate__c=Date.today();
            update oi2;

            providerOrder.Name='test2';
            update providerOrder;
            
            providerOrder.amendingInProgress__c=true;
            update providerOrder;
           
            providerOrder.Name='test';
            update providerOrder;
            update customerOrder;
            
            oi2.manufacturingStart__c=Date.today();
            oi2.manufacturingEnd__c=Date.today();
            oi2.confirmationDate__c=Date.today();
            oi2.shippingDate__c=Date.today();
            oi2.deliveryDate__c=Date.today();
            oi2.billingDate__c=Date.today();
            oi2.receivedDate__c=Date.today();
            update oi2;

            providerOrder.Name='test2';
            providerOrder.amendingInProgress__c=true;
            update providerOrder;

            oi2.cancellationDate__c=Date.today();
            update oi2;

            providerOrder.Name='test3';
            update providerOrder;*/

            Test.stopTest();
        }  
    }

    @isTest 
    static void testProviderOrder2() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.byPassTrigger__c = 'QA_KMDCEinstein';
        user.byPassValidationRule__c = true;
        update user;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PROVIDER_RTID LIMIT 1];
            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            insert customerOrder;
            Order providerOrder = Utils_Test.createProviderOrder(entDep.Id, customerOrder.Id, provider1.Id ,false);
            insert providerOrder;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', customerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;

            OrderItem oi2 = Utils_Test.createOrderItem(providerOrder.Id, pbEntry.Id, newAsset1.Id, productTest1.Id,true);

            providerOrder.transmissionDate__c = Date.Today();
            update providerOrder;

            providerOrder.transmissionDate__c = null;
            update providerOrder;

            customerOrder.cancellingDate__c = Date.today();
            update customerOrder;

            Test.stopTest();
        }  
    }

    @isTest 
    static void testCustomerOrder() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,true);

            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, null, true);
            oi.confirmationDate__c = date.today().addDays(1);
            update oi;

            //Customer order status change
            customerOrder.isValid__c=true;
            update customerOrder;

            customerOrder.controllableAssetCount__c=1;
            customerOrder.controlledAssetCount__c=1;
            update customerOrder;

            customerOrder.providerOrderCount__c=1;
            customerOrder.providerOrderOrderedCount__c=1;
            update customerOrder;

            customerOrder.providerOrderCount__c=1;
            customerOrder.deliveredProviderOrderCount__c=1;
            update customerOrder;

            //customerOrder.paymentsTotalAmount__c=1;
            customerOrder.assetCount__c =1;
            customerOrder.installedOrCancelledAssetCount__c=1;
            update customerOrder;

            customerOrder.amendingInProgress__c=true;
            update customerOrder;

            String RTDevNameProductFeature = DAL.getRecordTypeIdByDevName('Referencial__c', 'CustomerCancellationReason');
            
            //customerOrder.paymentsTotalAmount__c=0;
            //update customerOrder;
            /*
            customerOrder.suspendDate__c=Date.today();
            update customerOrder;

            Referencial__c referencial = Utils_Test.createReferencial('Test', 'Test', Date.today(), Date.today(), RTDevNameProductFeature, false, false, false, false, true);
            customerOrder.cancellingDate__c=Date.today();
            customerOrder.cancellingReason__c=referencial.Id;
            update customerOrder;
            */

            //Avenant
            Order customerOrderAvenant = Utils_Test.createCustomerOrder(accountTest.Id,false);
            customerOrderAvenant.Type=Constants.ORDER_TYPE_AVENANT;
            customerOrderAvenant.isRefused__c=false;
            customerOrderAvenant.isValid__c=false;
            insert customerOrderAvenant;

            PropertiesUtils.setStringValue('ref.motifAvenantValide.code', 'R-30');
            PropertiesUtils.setStringValue('ref.motifAvenantRefuse.code', 'R-31');

            String refMotifAvenantValidCode = PropertiesUtils.getStringValue('ref.motifAvenantValide.code', 'R-30');
            String refMotifAvenantRefuseCode = PropertiesUtils.getStringValue('ref.motifAvenantRefuse.code', 'R-31');    

            Referencial__c referencial2 = Utils_Test.createReferencial('R-31', refMotifAvenantRefuseCode, Date.today(), Date.today(), RTDevNameProductFeature, false, false, false, false, true);
            Referencial__c referencial3 = Utils_Test.createReferencial('R-30', refMotifAvenantValidCode, Date.today(), Date.today(), RTDevNameProductFeature, false, false, false, false, true);
            
            customerOrderAvenant.isRefused__c=true;
            update customerOrderAvenant;

            customerOrderAvenant.isValid__c=true;
            update customerOrderAvenant;
            Test.stopTest();
        }
    }

    @isTest 
    static void testCancelCustomerOrder() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            entDep.enabledCustomerOrderApprovalProcess__c = false;
            update entDep;

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.serviceEntity__c = entDep.Id;
            insert customerOrder;

            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, null, true);

            //Customer order status change
            customerOrder.cancellingDate__c =Date.today();
            update customerOrder;

            Test.stopTest();
        }
    }

    @isTest 
    static void testCancelApprovalCustomerOrder() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            Referencial__c refCancel = [SELECT Id From Referencial__C WHERE RecordTypeId = :REF_CANCELREASON_RTID LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            entDep.enabledCustomerOrderApprovalProcess__c = false;
            update entDep;

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.serviceEntity__c = entDep.Id;
            insert customerOrder;
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, null, true);

            // Approval
            customerOrder.isValid__c = false;
            customerOrder.isInApprovalProcess__c = true;
            update customerOrder;

            //Customer order status change
            customerOrder.cancellingDate__c =Date.today();
            customerOrder.cancellingReason__c = refCancel.Id;
            update customerOrder;

            Test.stopTest();
        }
    }

    @isTest 
    static void testLegacyCustomerOrder() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.legacyReference__c = 'TEST';
            customerOrder.isLegacy__c = true;
            insert customerOrder;

            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, null, null, productTest1.Id, false);
            oi.legacyReference__c = 'TEST';
            oi.isLegacy__c = true;
            insert oi;

            Test.stopTest();
        }
    }

    @isTest 
    static void testExecuteManagementFlow() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        String customerOrder5Id;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }            
            
            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            entDep.enabledCustomerOrderApprovalProcess__c = true;
            update entDep;

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, entDep.Id, false);
            insert customerOrder;

            OrderItem oi2 = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);
            oi2.confirmationDate__c = Date.today();
            insert oi2;

            Test.startTest();

            Order customerOrder5 = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder5.Status=Constants.ORDER_STATUS_REGISTERED;
            //customerOrder5.isValid__c=true;
            insert customerOrder5;
            customerOrder5Id=customerOrder5.Id;
            //ActivatedDate

            OrderItem oi3 = Utils_Test.createOrderItem(customerOrder5.Id, pbEntry.Id, null, productTest1.Id, false);
            oi3.confirmationDate__c = Date.today();
            insert oi3;
        }

        User user2 = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user2){
            Order customerOrder = [SELECT Id, Status, Name, cancellingDate__c, isInApprovalProcess__c, isRefused__c,  orderItemCount__c FROM Order LIMIT 1];
            customerOrder.Name='testChange';
            customerOrder.isInApprovalProcess__c=false;
            customerOrder.isRefused__c=false;
            update customerOrder;
            
            Order[] customerOrder5 = [SELECT Id, Name FROM Order WHERE Id=:customerOrder5Id];
            customerOrder5[0].isValid__c=true;
            try{
            update customerOrder5[0];
            }
            catch(Exception e){}
        }
        Test.stopTest();
    }

    @isTest 
    static void testExecuteManagementFlow2() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        String customerOrder5Id;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }      

            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            entDep.enabledCustomerOrderApprovalProcess__c = true;
            update entDep;

            Test.startTest();

            Order customerOrder2 = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, entDep.Id, true);
            OrderItem oi = Utils_Test.createOrderItem(customerOrder2.Id, pbEntry.Id, null, null, true);

            customerOrder2.isInApprovalProcess__c=false;
            customerOrder2.isValid__c=true;
            update customerOrder2;
            customerOrder2.cancellingDate__c=Date.today();
            update customerOrder2;
        }

        User user2 = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user2){
            Order[] customerOrder2 = [SELECT Id, cancellingDate__c FROM Order WHERE cancellingDate__c=:Date.today()];
            customerOrder2[0].cancellingDate__c=null;
            update customerOrder2[0];
        }
        Test.stopTest();
    }

    @isTest 
    static void testExecuteManagementFlow3() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        String customerOrder5Id;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }            

            Test.startTest();

            Order customerOrder3 = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder3.assetCount__c=1;
            customerOrder3.Status=Constants.ORDER_STATUS_REGISTERED;
            insert customerOrder3;

            OrderItem oi = Utils_Test.createOrderItem(customerOrder3.Id,pbEntry.Id, /*Id assetId*/null, productTest1.Id,false);
            oi.billingDate__c=Date.today();
            insert oi;

            customerOrder3.Status=CONSTANTS.ORDER_STATUS_BILLED;
            update customerOrder3;
        }

        User user2 = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user2){

            Order[] customerOrder3 = [SELECT Id, assetCount__c, installedAssetCount__c FROM Order WHERE assetCount__c=1];
            customerOrder3[0].installedAssetCount__c=1;
            try{
                update customerOrder3[0];
            }
            catch(Exception e){}
        }
        Test.stopTest();
    }

    @isTest 
    static void testExecuteManagementFlow4() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        String customerOrder5Id;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }           

            Test.startTest();

            Order customerOrder4 = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder4.nccFinished__c=1;
            customerOrder4.inescapableCount__c=1;
            customerOrder4.isRefused__c=true;
            customerOrder4.Status=Constants.ORDER_STATUS_REGISTERED;
            insert customerOrder4;
        }

        User user2 = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user2){

            Order[] customerOrder4 = [SELECT Id, nccFinished__c, Name FROM Order WHERE nccFinished__c=1];
            customerOrder4[0].Name='test2524';
            update customerOrder4[0];
        }
        Test.stopTest();
    }

    @isTest 
    static void testApproval() {
        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }            

        Test.startTest();
        
        Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
        entDep.enabledCustomerOrderApprovalProcess__c = true;
        update entDep;

        Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, entDep.Id, false);
        insert customerOrder;

        OrderItem oi2 = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);
        insert oi2;

        TR022_Order.executeApprovalProcessCustomerOrder(customerOrder.Id, UserInfo.getUserId(), 'PA_Order_Approbation3');

        Test.stopTest();
    }

    @isTest 
    static void testUpdateRelatedOrderItems() {
        User user = Utils_Test.createUser(false,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', ACC_PROVIDER_RTID, null , null, true);

            Order providerOrder = Utils_Test.createProviderOrder(accountTest.Id, null, provider1.Id ,false);
            insert providerOrder;
            OrderItem oi = Utils_Test.createOrderItem(providerOrder.Id, pbEntry.Id, null, null, false);
            insert oi;
            providerOrder.transmissionDate__c = Date.today();
            update providerOrder;

            Order providerOrder2 = Utils_Test.createProviderOrder(accountTest.Id, null, provider1.Id ,false);
            insert providerOrder2;
            OrderItem oi2 = Utils_Test.createOrderItem(providerOrder2.Id, pbEntry.Id, null, null, false);
            insert oi2;
            oi.confirmationDate__c = Date.today();
            update oi2;
            providerOrder.transmissionDate__c = Date.today();
            update providerOrder;
            providerOrder.transmissionDate__c = null;
            update providerOrder;

            Order providerOrder3 = Utils_Test.createProviderOrder(accountTest.Id, null, provider1.Id ,false);
            insert providerOrder3;
            OrderItem oi3 = Utils_Test.createOrderItem(providerOrder3.Id, pbEntry.Id, null, null, false);
            insert oi3;
            providerOrder3.isRefused__c=true;
            providerOrder.cancellingDate__c = Date.today();
            update providerOrder3;
        }
    }

    @isTest 
    static void testUpdateAmendmentOrder(){
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null, false);
        user.ByPassTrigger__c = 'TR022_Order';
        insert user;
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            
            Order customerOrder2 = Utils_Test.createCustomerOrder(accountTest.Id,false);
            customerOrder2.Status=Constants.ORDER_STATUS_REGISTERED;
            customerOrder2.isValid__c=false;
            //customerOrder.serviceEntity__c=ent.Id;
            insert customerOrder2;

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,false);
            customerOrder.Status=Constants.ORDER_STATUS_REGISTERED;
            customerOrder.Type = Constants.ORDER_TYPE_AVENANT;
            customerOrder.isValid__c=false;
            customerOrder.parentOrder__c=customerOrder2.Id;
            //customerOrder.serviceEntity__c=ent.Id;
            insert customerOrder;

            Test.startTest();

            String RTFinancingMethod = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod');
            String RTExpectedDoc = DAL.getRecordTypeIdByDevName('Referencial__c', 'ExpectedDocument');
            //FinancingMethod to add
            String oncRT = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Instance');
            Utils_Test.createOrderNonCompliance('Test', customerOrder.Id, oncRT, true);
            
            Referencial__c ref1 = Utils_Test.createReferencial('Test', 'Test', Date.today(), Date.today().addDays(5), RTExpectedDoc/*RTFinancingMethod*/, false, false, false, false, false);
            Referencial__c ref2 = Utils_Test.createReferencial('Test2', 'Test2', Date.today(), Date.today().addDays(5), RTFinancingMethod, false, false, false, false, false);
            List<Referencial__c> refToInsert = new List<Referencial__c>();
            refToInsert.add(ref1);
            refToInsert.add(ref2);
            insert refToInsert;
            Referencial__c[] testref = [SELECT Id, RecordType.DeveloperName FROM Referencial__c WHERE RecordTypeId=:RTFinancingMethod];
            System.debug('ref2.RecordType.DeveloperName : '+testref[0].RecordType.DeveloperName);
            //ExpectedDocument

            ExpectedDocument__c expDoc = new ExpectedDocument__c(document__c=ref1.Id, expectedBy__c=ref2.Id);
            insert expDoc;
            
            AssignedExpectedDocument__c doc = new AssignedExpectedDocument__c(customerOrder__c=customerOrder.Id, expectedDocument__c=ref1.Id);

            AssignedExpectedDocument__c doc2 = new AssignedExpectedDocument__c(customerOrder__c=customerOrder2.Id, expectedDocument__c=ref1.Id);
            
            List<AssignedExpectedDocument__c> docsToInsert = new List<AssignedExpectedDocument__c>();
            docsToInsert.add(doc);
            docsToInsert.add(doc2);

            insert docsToInsert;

            Test.stopTest();
        }
        User user2 = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user2){
            Order[] customerOrder = [SELECT Id, isValid__c, Type FROM Order WHERE Type=:Constants.ORDER_TYPE_AVENANT LIMIT 1];
            customerOrder[0].isValid__c=true;
            update customerOrder[0];
        }
    } 

    @isTest 
    static void testCreateAssets(){
        User user = Utils_Test.createUser(false,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        user.byPassTrigger__c = 'TR022_Order';
        update user;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id, isConvertibleAsset__c FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            productTest1.isConvertibleAsset__c=true;
            update productTest1;
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();
            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,false);
            customerOrder.Status=Constants.ORDER_STATUS_REGISTERED;
            insert customerOrder;

            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, true);
            OrderItem oiChild = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);
            oiChild.parentOrderItem__c = oi.Id;
            oiChild.productType__c = 'Component';
            insert oiChild;

            
            List<Order> orderList = new List<Order>([SELECT Id FROM Order]);
            TR022_Order.createAssets(orderList);
            Test.stopTest();
        }
    }

    @isTest 
    static void testDeleteChildrenOrderItems(){
        User user = Utils_Test.createUser(false,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id, isConvertibleAsset__c FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            productTest1.isConvertibleAsset__c=true;
            update productTest1;

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                        FROM PricebookEntry 
                                        WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,false);
            insert customerOrder;

            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, null, false);
            insert oi;

            OrderItem oi2 = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, null, false);
            oi2.parentOrderItem__c = oi.Id;
            insert oi2;

            delete oi;

            Test.stopTest();
        }
    }
    
    @isTest 
    static void testCreateAssetsIsAmending(){
        User user = Utils_Test.createUser(false,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        
        System.runAs(user){
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id, isConvertibleAsset__c FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            productTest1.isConvertibleAsset__c=true;
            update productTest1;
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,false);
            customerOrder.Status=Constants.ORDER_STATUS_REGISTERED;
            insert customerOrder;

            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);
            oi.confirmationDate__c = Date.today();
            insert oi;

            OrderItem oiChild = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);
            oiChild.parentOrderItem__c = oi.Id;
            oiChild.productType__c = 'Component';
            insert oiChild;
        }

        User user2 = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user2){
            List<OrderItem> orderItemList = new List<OrderItem>([SELECT Id, parentOrderItem__c, productConvertibleAsset__c, OrderId, productType__c, reference__c, assetQuantity__c, height__c, width__c,
            name__c, locationPrecision__c, Quantity, orderAccountId__c, assetAmendableCount__c, leaf__c, location__c, productCode__c, assetComponent__c,
            orderContactId__c, orderChantierId__c, orderServiceEntityId__c, orderEffectiveDate__c, UnitPrice, Product2Id, unit__c, locationFormula__c, thermalCoefficients__c
            FROM OrderItem]);
            TR022_Order.createAssets(orderItemList,true);
            Test.stopTest();
        }
    }

    @isTest 
    static void testGetDocumentsFromQuote(){
        User user = Utils_Test.createUser(false,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Opportunity projet = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id, isConvertibleAsset__c FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            Test.startTest();
            Quote quote = Utils_Test.createQuote('Devis 1', null, projet, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            QuoteLineItem qli = Utils_Test.createQuoteLineItem(quote.Id, '1', 30, 100, 2, 56.0, 56.0, productTest1, true);
            quote.dateTransmissionClient__c = date.today();
            quote.moyenTransmissionClient__c = 'Par email';
            quote.dateAcceptationClient__c = date.today();
            update quote;
            
            /*
            SBQQ__Quote__c devis = Utils_Test.createCPQQuote(projet,Date.today(),0, false);
            devis.SBQQ__Primary__c=true;
            insert devis;
            */

            //[SELECT Id, ParentId, Name, body FROM Attachment WHERE ParentId IN :salesQuotesId.keySet()])
            //parentId = QuoteId
            
            Test.stopTest();

            Attachment att = Utils_Test.createAttachment('name', quote.Id, Blob.valueOf('test'));

            //Account ent = Utils_Test.createEntity('test', null, Date.today(), null, null, true);

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,false);
            customerOrder.QuoteId=quote.Id;
            //customerOrder.SBQQ__Quote__c=devis.Id;
            customerOrder.Status=Constants.ORDER_STATUS_REGISTERED;
            insert customerOrder;
        }
    }

    @isTest 
    static void testAmendmentOrderItem(){
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
        
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
    
            Test.startTest();
            
            // Commande
            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            insert customerOrder;

            // Asset
                Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', customerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
                Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', customerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
                newAsset2.Status = Constants.ASSET_STATUS_VALIDE;
                List<Asset> astList = new List<Asset>();
                astList.add(newAsset1);
                astList.add(newAsset2);
                insert astList;

            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, true);
            OrderItem oi2 = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, newAsset2.Id, productTest1.Id, true);        

            // Avenant
            oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
            oi.Quantity = 2;
            oi.assetAmendableCount__c = 0;
            update oi;
            oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
            oi.Quantity = 2;
            oi.assetAmendableCount__c = 1;
            update oi;
            
            oi2.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
            oi2.Quantity = 0;
            oi2.assetAmendableCount__c = 1;
            update oi2;
            
            Test.stopTest();
        } 
    }

    @isTest 
    static void testAdministrativeApproval(){
        User user = Utils_Test.createUser(false,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            insert customerOrder;

            
            OrderNonCompliance__c newOrderNonCompliance = Utils_Test.createOrderNonCompliance('Test', customerOrder.Id, NCC_IMPOSSIBILITY_RTID, false);
            newOrderNonCompliance.status__c = 'En cours';
            //newOrderNonCompliance.orderNonComplianceType__c = 'Impossibility';
            insert newOrderNonCompliance;

            newOrderNonCompliance = [SELECT status__c,orderNonComplianceType__c FROM OrderNonCompliance__c LIMIT 1];
            System.debug('## newOrderNonCompliance'+newOrderNonCompliance.status__c+ ' '+newOrderNonCompliance.orderNonComplianceType__c);

            // Creation Rendez-vous
            WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, true);
            

            WorkOrder wo = Utils_Test.createWorkOrder(wkRTId, false);
            wo.customerOrder__c = customerOrder.Id;
            wo.WorkTypeId = wt1.Id;
            insert wo;
            
            ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, SASARTId, false);
            sa1.Status='En cours';
            sa1.customerOrder__c = customerOrder.Id;
            sa1.ActualStartTime=Date.today();
            sa1.fsl_dateConfirmation__c=Date.today();
            sa1.dateConfirmationClient__c=Date.today();
            sa1.SchedEndTime=Date.today();
            sa1.SchedStartTime=Date.today();
            insert sa1;

            customerOrder.administrativeValidation__c = true;
            update customerOrder;
            
            //WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, asset1.Id, false);
            //insert woli;

            Test.stopTest();
        }
    }

    @isTest 
    static void testUtils(){
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];   
            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
            Product2 productTest1 = [SELECT Id, isConvertibleAsset__c FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
    
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }

            Test.startTest();
    
            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, entDep.Id, false);
            insert customerOrder;
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);
            insert oi;

            TR023_Order.defineOrderItemSalesLocation('entrée');
            TR023_Order.defineOrderItemSalesLocation('salon');
            TR023_Order.defineOrderItemSalesLocation('cuisine');
            TR023_Order.defineOrderItemSalesLocation('chambre');

            TR023_Order.defineOrderItemSalesPrecisionLocation('entrée 2');
            TR023_Order.defineOrderItemSalesPrecisionLocation('salon 2');
            TR023_Order.defineOrderItemSalesPrecisionLocation('cuisine 2');
            TR023_Order.defineOrderItemSalesPrecisionLocation('chambre 2');

            TR022_Order.executeApprovalProcessCustomerOrder(customerOrder.Id, UserInfo.getUserId(), 'PA_Order_Approbation3');
            TR022_Order.executeApprovalProcessCustomerOrderAsync(customerOrder.Id, UserInfo.getUserId(), 'PA_Order_Approbation3');

            TR022_OrderItem.amendmentUpdateOrderItem(new Set<String>{oi.Id}, new Set<String>{oi.Id});
            
            Test.stopTest();
        } 
    }
}