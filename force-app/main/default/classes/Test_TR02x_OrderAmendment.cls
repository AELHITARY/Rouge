//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_OrderAmendment
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 24/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
public without sharing class Test_TR02x_OrderAmendment {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id REF_MARGIN_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_CATALOGMARGIN_RT);
    private static final Id REF_PROVDELAY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);
    private static final Id ACC_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT);
    private final static String BYPASS_TRIGGER = 'TR021_Chantier;TR022_Chantier;TR023_ChantierTR020_User;TR020_WorkOrder;' +
            'TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;TR023_SBQQ__Quote;TR022_Order;' +
            'TR022_OrderItem;TR022_Account;TR024_Account;TR001_Dedoublonnage;TR021_Opportunity;TR022_Opportunity;' +
            'TR023_Opportunity;TR020_SharingRulesProcess;TR022_R040;TR023_ChangeOwner;'; 

    @testSetup 
    static void testSetup() {
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;

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
    static void testAmendmentSalesAdd(){
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        //user.byPassTrigger__c = 'TR021_Account;TR021_Quote;TR022_QuoteLineItem;QA_KMDCEinstein;TR022_Quote';
        user.byPassTrigger__c = BYPASS_TRIGGER;
        user.byPassValidationRule__c = true;
        user.ByPassWorkflowRule__c = true;
        update user;

        System.runAs(user){
            Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
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

            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',2,true);

            Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
            Event event = Utils_Test.createEvent('R1',rtRDV,opp.id, opp.Account.PersonContactId,null,'Effectué', false);
            event.resultatDuRDV__c = null;
            insert event;
    
            Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 1, 1.0, 1.0, productTest1, true);
            //Utils_Test.createOption(line.Id,'1','Libellé Option 1',refOpt.Id,1,true);

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.QuoteId = quote.Id;
            insert customerOrder;
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);        
            oi.QuoteLineItemId = line.Id;
            oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
            oi.assetAmendableCount__c = 1;
            insert oi;
            customerOrder.isValid__c = true;
            customerOrder.isInApprovalProcess__c = false;
            update customerOrder;
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', customerOrder.Id, productTest1.Id, oi.Id, chantier.Id, accountTest.Id,true);
                
            Test.startTest();

            // Avenant
            Quote quoteAv = Utils_Test.createQuote('Devis 2', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            quoteAv.amendInitialQuote__c = quote.Id;
            insert quoteAv;
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            QuoteLineItem lineAv = Utils_Test.createQuoteLineItem(quoteAv.id, '2', 90, 150, 2, 1.0, 1.0, productTest1, false);
            lineAv.amendedOrderProduct__c = oi.Id;
            lineAv.amendInitialQuoteline__c = line.Id;
            qliList.add(lineAv);
            QuoteLineItem lineAv2 = Utils_Test.createQuoteLineItem(quoteAv.id, '2', 90, 150, 1, 1.0, 1.0, productTest1, false);
            qliList.add(lineAv2);
            insert qliList;
            Option__c opt = Utils_Test.createOption(lineAv.Id,'1','Libellé Option 1',refOpt.Id,1, false);
            insert opt;

            Order customerOrderAv = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrderAv.QuoteId = quoteAv.Id;
            customerOrderAv.Type = Constants.ORDER_TYPE_AVENANT;
            customerOrderAv.parentOrder__c = customerOrder.Id;
            insert customerOrderAv;
            OrderItem oiAv = Utils_Test.createOrderItem(customerOrderAv.Id, pbEntry.Id, null, productTest1.Id, false);        
            oiAv.QuoteLineItemId = lineAv.Id;
            insert oiAv;

            System.debug('## TEST Amendment');
            customerOrderAv.isValid__c = true;
            customerOrderAv.isInApprovalProcess__c = false;
            update customerOrderAv;
            
            Test.stopTest();
        } 
    }

    @isTest 
    static void testAmendmentSalesDown(){
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        //user.byPassTrigger__c = 'TR021_Account;TR021_Quote;TR022_QuoteLineItem;QA_KMDCEinstein;TR022_Quote';
        user.byPassTrigger__c = BYPASS_TRIGGER;
        user.byPassValidationRule__c = true;
        user.ByPassWorkflowRule__c = true;
        update user;

        System.runAs(user){
            Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
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

            // Options référence
            ReferentielOptions__c refOpt = Utils_Test.createRefOption('RefOption','RefOption','RefOption2',2,true);

            Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
            Event event = Utils_Test.createEvent('R1',rtRDV,opp.id, opp.Account.PersonContactId,null,'Effectué', false);
            event.resultatDuRDV__c = null;
            insert event;
    
            Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
            QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 2, 1.0, 1.0, productTest1, true);
            //Utils_Test.createOption(line.Id,'1','Libellé Option 1',refOpt.Id,1,true);

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.QuoteId = quote.Id;
            insert customerOrder;
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);        
            oi.QuoteLineItemId = line.Id;
            oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
            oi.assetAmendableCount__c = 2;
            insert oi;
            customerOrder.isValid__c = true;
            customerOrder.isInApprovalProcess__c = false;
            update customerOrder;
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', customerOrder.Id, productTest1.Id, oi.Id, chantier.Id, accountTest.Id,true);
                
            Test.startTest();

            // Avenant
            Quote quoteAv = Utils_Test.createQuote('Devis 2', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            quoteAv.amendInitialQuote__c = quote.Id;
            insert quoteAv;
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            QuoteLineItem lineAv = Utils_Test.createQuoteLineItem(quoteAv.id, '2', 90, 150, 1, 1.0, 1.0, productTest1, false);
            lineAv.amendedOrderProduct__c = oi.Id;
            lineAv.amendInitialQuoteline__c = line.Id;
            qliList.add(lineAv);
            QuoteLineItem lineAv2 = Utils_Test.createQuoteLineItem(quoteAv.id, '2', 90, 150, 1, 1.0, 1.0, productTest1, false);
            qliList.add(lineAv2);
            insert qliList;
            Option__c opt = Utils_Test.createOption(lineAv.Id,'1','Libellé Option 1',refOpt.Id,1, false);
            insert opt;

            Order customerOrderAv = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrderAv.QuoteId = quoteAv.Id;
            customerOrderAv.Type = Constants.ORDER_TYPE_AVENANT;
            customerOrderAv.parentOrder__c = customerOrder.Id;
            insert customerOrderAv;
            OrderItem oiAv = Utils_Test.createOrderItem(customerOrderAv.Id, pbEntry.Id, null, productTest1.Id, false);        
            oiAv.QuoteLineItemId = lineAv.Id;
            insert oiAv;

            System.debug('## TEST Amendment');
            customerOrderAv.isValid__c = true;
            customerOrderAv.isInApprovalProcess__c = false;
            update customerOrderAv;
            
            Test.stopTest();
        } 
    }

    /*@isTest 
    static void testAmendmentCPQ(){
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
    
            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, productTest1, true);
            
            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.SBQQ__Quote__c = cpqQuote.Id;
            insert customerOrder;
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);        
            oi.SBQQ__QuoteLine__c = cpqQuoteLine.Id;
            insert oi;

            // Avenant
            SBQQ__Quote__c cpqQuoteAv = Utils_Test.createCPQQuote(opp, Date.today(),1, false);
            cpqQuoteAv.amendInitialQuote__c = cpqQuote.Id;
            cpqQuoteAv.AmendmentQuote__c = true;
            insert cpqQuoteAv;
            SBQQ__QuoteLine__c cpqQuoteLine2 = Utils_Test.createCPQQuoteLineItem(cpqQuoteAv.Id ,100, 100, 2, productTest1, true);

            //MAJ
            customerOrder.amendmentQuote__c = cpqQuoteAv.Id;
            customerOrder.amending__c = true;
            update customerOrder;
            
            Test.stopTest();
        }*
    }*/
}