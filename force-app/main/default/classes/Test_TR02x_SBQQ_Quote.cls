//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_TR02x_SBQQ_Quote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_TR02x_SBQQ_Quote {    
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id REF_MARGIN_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_CATALOGMARGIN_RT);
    private static final Id REF_PROVDELAY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);
    private static final Id REF_CUSTCANCEREAS_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', 'CustomerCancellationReason');

    @testSetup 
    static void testSetup() {
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refCgv = Utils_Test.createReferencial('CGV', 'CGV1', Date.today(), null, REF_TERMSANDCONT_RTID, false, false, false, false, false);
        Referencial__c ref = Utils_Test.createReferencial('ref', PropertiesUtils.getStringValue('ref.motifAnnulationKparK.code', 'RSL-0016'), Date.today(), 
                                                                Date.today(), REF_CUSTCANCEREAS_RTID, false, false, false, false, false);
        // Mode de financement
        Referencial__c financialRef = new Referencial__c(Name = 'Comptant',
                RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod'),
                startDate__c = Date.today().addMonths(-12), financingType__c = 'Cash',
                KparKReference__c = 'CASH', advancePayment1__c = 10);
        refList.add(financialRef);
        refList.add(refDep);
        refList.add(refMag);
        refList.add(refCgv);
        refList.add(ref);
        insert refList;
        // Création entite     
        List<Account> accList = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        //Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(accountTest);
        insert accList;
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c = secto.Id;
        chantier.heatingMode__c = 'Individuel Electrique';
        insert chantier;
        // Opportunity
        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
    }

    @isTest 
    static void testCreateCPQQuote() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            Test.startTest();

            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Referencial__c fin = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'CASH' LIMIT 1];

            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);
            
            cpqQuote.financingMethod__c = fin.Id;
            update cpqQuote;

            Test.stopTest();
        }
    }

    @isTest 
    static void testChild() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            // Creation produit
            Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
            prod.SousMatiere__c = 'Ekilibre';
            insert prod;

            Test.startTest();

            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Referencial__c fin = [SELECT Id FROM Referencial__c WHERE KparKReference__c = 'CASH' LIMIT 1];

            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);
            SBQQ__QuoteLine__c cpqQuoteLine2 = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, false);
            cpqQuoteLine2.SBQQ__RequiredBy__c = cpqQuoteLine.Id;
            insert cpqQuoteLine2;

            Test.stopTest();
        }
    }

    @isTest 
    static void testUpdateAcousticCoefficients() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            // Creation produit
            List<Product2> prodList = new List<Product2>(); 
            Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
            Product2 productOption1 = Utils_Test.createProduct('Produit Option 1', 'OPTION1',false);
            prodList.Add(prod);
            prodList.Add(productOption1);
            insert prodList;

            Test.startTest();

            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            Referencial__c acousticCoefficientRef = new Referencial__c(Name = 'Coeff Acoustique Test', KparKReference__c = 'COEFFACTEST',
                                                        RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'ProductAcousticCoefficient'),
                                                        startDate__c = Date.today(), product__c = prod.Id, option__c = productOption1.Id, 
                                                        valueRW__c = 1, valueRATR__c = 2, valueRA__c = 3);
            insert acousticCoefficientRef;

            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);
            SBQQ__QuoteLine__c cpqQuoteLineOption = Utils_Test.createCPQOption(cpqQuoteLine.Id, cpqQuote.Id, 100, 100, 1, productOption1, true);

            Test.stopTest();
        }
    }

    @isTest 
    static void testDeleteLines() {
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);

        System.runAs(user){
            Test.startTest();

            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
            SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
            SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);
            delete cpqQuoteLine;

            Test.stopTest();
        }
    }

    @isTest 
    static void testCPQQuoteCEE() {

        // Creation Incentive CEE
        ESCIncentive__c esc = new ESCIncentive__c(type__c = 'Menuiserie',
                                                startDate__c = Date.today(),
                                                minIncomes__c = 0,
                                                maxIncomes__c = 3000,
                                                personNumber__c = 2,
                                                geography__c = 'H1_IDF',
                                                KparKReference__c = 'ESC',
                                                officialAmount__c = 100,
                                                heatingModes__c = 'Individuel Electrique',
                                                customerAmount__c = 1000);
        insert esc;

        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;
        
        // Creation TVA
        Utils_Test.createTVAProduit(prod.Id, Date.today(), 5, '11', true);
        
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        // Devis CEE
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, false);
        cpqQuote.RevenusFiscaux__c = 1000;
        cpqQuote.NombrePersonnes__c = 2;
        cpqQuote.Zone__c = 'H1_IDF';
        cpqQuote.SBQQ__ShippingPostalCode__c = '13100';
        insert cpqQuote;
        // Ligne devis CEE
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, false);
        cpqQuoteLine.eligibleCEE__c = true;
        insert cpqQuoteLine;

        // MAJ montant CEE
        cpqQuote.RevenusFiscaux__c = 1005;
        update cpqQuote;

        Test.stopTest();
    }

    @isTest 
    static void testUpdateStatusCPQQuote() {
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);

        // passage en non transmis
        cpqQuote.quoteIsValid__c = true;
        update cpqQuote;

        // puis passage en transmis
        cpqQuote.dateTransmissionClient__c = Date.today();
        cpqQuote.moyenTransmissionClient__c = 'Par email';
        update cpqQuote;

        // puis passage en vendu
        cpqQuote.dateAcceptationClient__c = Date.today();
        update cpqQuote;
        
        Test.stopTest();
    }

    @isTest 
    static void testProviderDelay() {

        // Création réf délai 
        Referencial__c refDelay = Utils_Test.createReferencial('Delay', 'Delay', Date.today(), null, REF_PROVDELAY_RTID, false, false, false, false, false);
        refDelay.productSubFamily__c = 'PVC';
        refDelay.productSubMaterial__c  = 'Ekilibre';
        refDelay.providerDelayType__c   = 'Standard';
        refDelay.minCommercialDelay__c = 5;
        refDelay.maxCommercialDelay__c = 10;
        insert refDelay;

        // Creation produits
        List<Product2> prodList = new List<Product2>();
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        Product2 prod2 = Utils_Test.createProduct('Produit Test2', 'FFFETT2', 'Fenetre', 'PVC', 50, 50, false);
        prod2.SousMatiere__c = '';
        Product2 prod3 = Utils_Test.createProduct('Produit Test3', 'FFFETT3', 'Fenetre', '', 50, 50, false);
        prod3.SousMatiere__c = 'Ekilibre';
        prodList.add(prod);
        prodList.add(prod2);
        prodList.add(prod3);
        insert prodList;

        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);
        Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod2, true);
        Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod3, true);

        Test.stopTest();
    }

    @isTest 
    static void testMargin() {

        // Création réf délai 
        Referencial__c refDelay = Utils_Test.createReferencial('Delay', 'Delay', Date.today(), null, REF_MARGIN_RTID, false, false, false, false, false);
        refDelay.productSubFamily__c = 'PVC';
        refDelay.productSubMaterial__c  = 'Ekilibre';
        refDelay.providerDelayType__c   = 'Standard';
        refDelay.margin__c = 2;
        insert refDelay;

        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;

        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);

        Test.stopTest();
    }

    @isTest 
    static void testGetKBMaxImage() {

        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.KBMAXSB__Id__c = 1;
        insert prod;
        
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        // Devis 
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        // Ligne devis 
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);
        // Simulation fichier de KBMAX
        Utils_Test.createFile('File.jpg', cpqQuoteLine.Id, Blob.valueof('TEST'), true);
        // Copie fichier de la ligne original si création d'une ligne clonée
        SBQQ__QuoteLine__c cpqQuoteLineCloned = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, false);
        cpqQuoteLineCloned.lineCloned__c = true;
        cpqQuoteLineCloned.KBMAXSB__Id__c = 1;
        cpqQuoteLineCloned.SBQQ__Source__c = cpqQuoteLine.Id;
        insert cpqQuoteLineCloned;

        Test.stopTest();
    }

    @isTest 
    static void testGenerateDocuments() {

        // Fichier CGV
        Referencial__c cgv = [SELECT Id FROM Referencial__c WHERE RecordTypeId = :REF_TERMSANDCONT_RTID LIMIT 1];
        Utils_Test.createFile('CGV', cgv.Id, Blob.valueof('TEST'), true);
        
        Test.startTest();

        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        // Devis 
        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, false);
        cpqQuote.termsAndConditions__c = cgv.Id;
        insert cpqQuote;
        // Ligne devis 
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, true);

        // passage en non transmis
        cpqQuote.quoteIsValid__c = true;
        update cpqQuote;

        // puis passage en transmis
        cpqQuote.dateTransmissionClient__c = Date.today();
        cpqQuote.moyenTransmissionClient__c = 'Par email';
        update cpqQuote;

        Test.stopTest();
    }

    @isTest 
    static void testAmendmentCPQ(){
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        // Creation produit
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        insert prod;

        Test.startTest();

        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);
        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1, prod, true);

        // Avenant
        SBQQ__Quote__c cpqQuoteAv = Utils_Test.createCPQQuote(opp, Date.today(),1, false);
        cpqQuoteAv.amendInitialQuote__c = cpqQuote.Id;
        cpqQuoteAv.AmendmentQuote__c = true;
        insert cpqQuoteAv;
        SBQQ__QuoteLine__c cpqQuoteLine2 = Utils_Test.createCPQQuoteLineItem(cpqQuoteAv.Id ,100, 100, 2, prod, true);
        
        Test.stopTest();
    }

    /**
     * Test qu'une commande avenant validée avec commandes client/founisseur validé est bien commissionnable,
     * que les commissions précédentes sont bien prises en compte et que la régularisation se fait bien.
     */
    /*
    @IsTest
    public static void testAmendmentQuote() {
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];

        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test', 'FFFETT', 'Fenetre', 'PVC', 50, 50, true);
        // Price book
        Pricebook2 pBook = new Pricebook2(Name = 'Test');
        insert pBook;
        PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
        insert priceBookEntry;

        // Mode de financement
        Referencial__c financialRef = new Referencial__c(Name = Constants.QUOTE_PAIEMENT_COMPTANT,
                RecordTypeId = DAL.getRecordTypeIdByDevName('Referencial__c', 'FinancingMethod'),
                startDate__c = Date.today().addMonths(-12), financingType__c = 'Cash',
                KparKReference__c = 'CASH', advancePayment1__c = 0);
        insert financialRef;

        // Création entite
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null,
            REF_ENTITY_RTID, true, true, true, true, true);
        Account magasinA = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);

        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];


        List<Order> orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                InitialQuote__c, amendmentQuote__c FROM Order WHERE SBQQ__Quote__c = :quote.Id];
        System.debug('Found ' + orders.size() + ' orders');
        System.assert(!orders.isEmpty(), 'No order found');

        Order ord = orders.get(0);

        Test.startTest();

        //create amendment quote
        SBQQ__Quote__c amendment = Utils_Test.createSBQQQuote(opp, null, pBook.Id, priceBookEntry.Id, prod, false, ord, true);

        orders = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                InitialQuote__c, amendmentQuote__c FROM Order WHERE amendmentQuote__c = :amendment.Id];
        System.debug('Found ' + orders.size() + ' orders');
        System.assert(!orders.isEmpty(), 'No order found');

        ord = orders.get(0);
        ord.SBQQ__Quote__c = quote.Id;
        update ord;
        System.debug('Updated order? ' + ord);

        // Passage en non transmis
        amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_NOT_TRANSMITTED;
        amendment.amendInitialQuote__c = quote.Id;
        amendment.previousQuote__c = quote.Id;
        update amendment;

        System.debug('  -> passage en transmis');
        // puis passage en transmie
        amendment.dateTransmissionClient__c = Date.today();
        amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
        amendment.financingMethod__c = financialRef.Id;
        update amendment;

        amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
        amendment.amendmentOrderApproved__c = true;
        amendment.techPB__c = false;
        update amendment;

        Test.stopTest();
    }
    */

    /*
    @isTest 
    static void testModifyAfterAmendment() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userManager = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c,
                ByPassTrigger__c FROM User WHERE Alias = 'manager1'];

        SBQQ.TriggerControl.disable();

        System.runAs(userManager) {
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
            Pricebook2 pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test' LIMIT 1];
            PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
            Order order = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                    InitialQuote__c, amendmentQuote__c, amending__c FROM Order LIMIT 1];
            OrderItem orderItem = [SELECT Id, OrderId, assetAmendableCount__c, locationPrecision__c,
                    height__c, width__c, leaf__c, UnitPrice, PricebookEntryId, SBQQ__QuotedQuantity__c,
                    Product2Id, SBQQ__QuoteLine__c, SBQQ__QuotedListPrice__c, SBQQ__RequiredBy__c
            FROM OrderItem WHERE OrderId = :order.Id];
            SBQQ__Quote__c oldQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            SBQQ__QuoteLine__c oldQuoteLine = [SELECT Id, CoefficientThermique__c, DateValiditeTarif__c,
                    ExcluBonusProjet__c, ExclusionPromo__c,  
                    IdPromotionRetenue__c, IndexParent__c,
                    SBQQ__Quantity__c, PrixUnitaireHTManuel__c, KBMAXSB__Id__c,
                    MethodePrixOption__c, NbTauxReduits__c, quoteLineLabelManual__c,
                    SBQQ__AdditionalDiscount__c, SBQQ__AdditionalQuantity__c, SBQQ__Bundle__c,
                    SBQQ__ComponentListTotal__c, SBQQ__SubscriptionScope__c, SBQQ__ComponentSubscriptionScope__c,
                    SBQQ__ComponentTotal__c, SBQQ__Discount__c, SBQQ__DistributorDiscount__c,
                    SBQQ__NonDiscountable__c, SBQQ__Number__c, SBQQ__OptionType__c, SBQQ__OriginalPrice__c,
                    SBQQ__PackageProductCode__c, SBQQ__PartnerDiscount__c, SBQQ__PartnerPrice__c,
                    SBQQ__PriceEditable__c, SBQQ__PricingMethod__c, SBQQ__ProductOption__c,
                    SBQQ__ProratedListPrice__c, SBQQ__ProratedPrice__c, SBQQ__RegularPrice__c,
                    SBQQ__SubscriptionBase__c, SBQQ__SubscriptionCategory__c, SBQQ__SubscriptionPercent__c,
                    SBQQ__AdditionalDiscountAmount__c,
                    SBQQ__ListPrice__c, SBQQ__PricingMethodEditable__c, SBQQ__RequiredBy__c, SBQQ__Bundled__c,
                    AssetAmendableCount__c
            FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :oldQuote.Id LIMIT 1];
            Referencial__c financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];

            Test.startTest();

            //create amendment quote
            SBQQ__Quote__c amendment = Utils_Test.createSBQQQuote(opp, userManager.Id, pBook.Id, priceBookEntry.Id, prod, false, order, true);

            // création de la nouvelle quoteline d'avenant
            SBQQ__QuoteLine__c ql = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :amendment.Id LIMIT 1];
            ql.AmendedQLValidated__c = true;
            ql.AmendedOrderProduct__c = orderItem.Id;
            ql.AssetAmendableCount__c = orderItem.assetAmendableCount__c;
            ql.CoefficientThermique__c = oldQuoteLine.CoefficientThermique__c;
            ql.DateValiditeTarif__c = oldQuoteLine.DateValiditeTarif__c;
            ql.ExcluBonusProjet__c = oldQuoteLine.ExcluBonusProjet__c;
            ql.ExclusionPromo__c = oldQuoteLine.ExclusionPromo__c;
            ql.Hauteur__c = orderItem.height__c;
            ql.IdPromotionRetenue__c = oldQuoteLine.IdPromotionRetenue__c;
            ql.IndexParent__c = oldQuoteLine.IndexParent__c;
            ql.SBQQ__Quantity__c = oldQuoteLine.SBQQ__Quantity__c;
            ql.KBMAXSB__Id__c = oldQuoteLine.KBMAXSB__Id__c;
            ql.Largeur__c = orderItem.width__c;
            ql.MethodePrixOption__c = oldQuoteLine.MethodePrixOption__c;
            ql.NbTauxReduits__c = oldQuoteLine.NbTauxReduits__c;
            ql.NombreVantaux__c = orderItem.leaf__c;
            ql.quoteLineLabelManual__c = oldQuoteLine.quoteLineLabelManual__c;
            ql.PrixUnitaireHTManuel__c = oldQuoteLine.PrixUnitaireHTManuel__c;
            ql.SBQQ__Bundle__c = oldQuoteLine.SBQQ__Bundle__c;
            ql.SBQQ__ComponentListTotal__c = oldQuoteLine.SBQQ__ComponentListTotal__c;
            ql.SBQQ__ComponentSubscriptionScope__c = oldQuoteLine.SBQQ__ComponentSubscriptionScope__c;
            ql.SBQQ__ComponentTotal__c = oldQuoteLine.SBQQ__ComponentTotal__c;
            ql.SBQQ__NetPrice__c = orderItem.UnitPrice;
            ql.SBQQ__AdditionalDiscountAmount__c = oldQuoteLine.SBQQ__AdditionalDiscountAmount__c;
            ql.SBQQ__AdditionalQuantity__c = oldQuoteLine.SBQQ__AdditionalQuantity__c;
            ql.SBQQ__Discount__c = oldQuoteLine.SBQQ__Discount__c;
            ql.SBQQ__DistributorDiscount__c = oldQuoteLine.SBQQ__DistributorDiscount__c;
            ql.SBQQ__ListPrice__c = oldQuoteLine.SBQQ__ListPrice__c;
            ql.SBQQ__CustomerPrice__c = orderItem.UnitPrice;
            ql.SBQQ__NonDiscountable__c = oldQuoteLine.SBQQ__NonDiscountable__c;
            ql.SBQQ__Number__c = oldQuoteLine.SBQQ__Number__c;
            ql.SBQQ__OptionType__c = oldQuoteLine.SBQQ__OptionType__c;
            ql.SBQQ__OriginalPrice__c = oldQuoteLine.SBQQ__OriginalPrice__c;
            ql.SBQQ__PackageProductCode__c = oldQuoteLine.SBQQ__PackageProductCode__c;
            ql.SBQQ__PartnerPrice__c = oldQuoteLine.SBQQ__PartnerPrice__c;
            ql.SBQQ__PriceEditable__c = oldQuoteLine.SBQQ__PriceEditable__c;
            ql.SBQQ__PricebookEntryId__c = orderItem.PricebookEntryId;
            ql.SBQQ__PricingMethodEditable__c = oldQuoteLine.SBQQ__PricingMethodEditable__c;
            ql.SBQQ__PricingMethod__c = oldQuoteLine.SBQQ__PricingMethod__c;
            ql.SBQQ__ProductOption__c = oldQuoteLine.SBQQ__ProductOption__c;
            ql.SBQQ__Product__c = orderItem.Product2Id;
            ql.SBQQ__ProratedListPrice__c = oldQuoteLine.SBQQ__ProratedListPrice__c;
            ql.SBQQ__ProratedPrice__c = oldQuoteLine.SBQQ__ProratedPrice__c;
            ql.SBQQ__Quantity__c = oldQuoteLine.SBQQ__Quantity__c;
            ql.SBQQ__RegularPrice__c = oldQuoteLine.SBQQ__RegularPrice__c;
            ql.SBQQ__SubscriptionBase__c = oldQuoteLine.SBQQ__SubscriptionBase__c;
            ql.SBQQ__SubscriptionCategory__c = oldQuoteLine.SBQQ__SubscriptionCategory__c;
            ql.SBQQ__SubscriptionPercent__c = oldQuoteLine.SBQQ__SubscriptionPercent__c;
            ql.SBQQ__SubscriptionScope__c = oldQuoteLine.SBQQ__SubscriptionScope__c;
            if (orderItem.SBQQ__RequiredBy__c != null) ql.SBQQ__Bundled__c = true;

            update ql;

            // mise à jour order product pour prise en compte par le process
            orderItem.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
            orderItem.SBQQ__QuoteLine__c = ql.Id;
            update orderItem;

            System.debug('  -> passage en transmis');
            // puis passage en transmie
            amendment.DateTransmissionClient__c = Date.today();
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            amendment.quoteIsValid__c = true;
            amendment.customerOrder__c = order.Id;
            update amendment;

            System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            amendment.DateAcceptationClient__c = Date.today();
            amendment.MoyenTransmissionClient__c = 'Par email';
            amendment.financingMethod__c = financialRef.Id;
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            amendment.techQLValidated__c = true;
            
            //update amendment;

            //trigger runs here and launch the process

            Test.stopTest();

            //OrderItem oItem = [SELECT Id, StatutDeRevision__c, SBQQ__QuoteLine__c FROM OrderItem WHERE SBQQ__QuoteLine__c = :ql.Id];//
            //System.assert(oItem != null);
            //System.assertEquals(Constants.ORDERITEM_STATUTREVISION_UPDATED, oItem.StatutDeRevision__c);
        }
    }
    */

    /*
    @isTest 
    static void testNewOrderProductAfterAmendment() {
        User curUser = [SELECT Id, ByPassWorkflowRule__c, ByPassTrigger__c, ByPassValidationRule__c FROM User WHERE Id = :UserInfo.getUserId()];
        curUser.ByPassWorkflowRule__c = true;
        curUser.ByPassValidationRule__c = true;
        curUser.ByPassTrigger__c = BYPASS_TRIGGER;
        update curUser;
        User userManager = [SELECT Id, ByPassWorkflowRule__c, ByPassValidationRule__c,
                ByPassTrigger__c FROM User WHERE Alias = 'manager1'];
        Opportunity opp = [SELECT Id, AccountId, autreCompte__c FROM Opportunity LIMIT 1];
        Pricebook2 pBook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Produit Test'];
        Product2 prod2 = [SELECT Id FROM Product2 WHERE Name = 'Produit Test2'];
        PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id AND Product2Id = :prod.Id];
        PricebookEntry priceBookEntry2 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pBook.Id AND Product2Id = :prod2.Id];
        Order order = [SELECT Id, Name, isInApprovalProcess__c, isRefused__c, Status, SBQQ__Quote__c,
                InitialQuote__c, amendmentQuote__c, amending__c FROM Order LIMIT 1];
        OrderItem orderItem = [SELECT Id, OrderId, assetAmendableCount__c, locationPrecision__c,
                height__c, width__c, leaf__c, UnitPrice, PricebookEntryId, SBQQ__QuotedQuantity__c,
                Product2Id, SBQQ__QuoteLine__c, SBQQ__QuotedListPrice__c, SBQQ__RequiredBy__c
        FROM OrderItem WHERE OrderId = :order.Id];
        SBQQ__Quote__c oldQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Referencial__c financialRef = [SELECT Id FROM Referencial__c WHERE Name = :Constants.QUOTE_PAIEMENT_COMPTANT];

        SBQQ.TriggerControl.disable();

        System.runAs(userManager) {

            Test.startTest();

            //create amendment quote
            SBQQ__Quote__c amendment = Utils_Test.createSBQQQuote(opp, userManager.Id, pBook.Id, priceBookEntry.Id, prod, false, order, false);
            order.amendingInProgress__c = true;
            order.Status = 'AmendmentInProgress';
            update order;

            // mise à jour order product pour prise en compte par le process
            orderItem.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
            update orderItem;

            // création de la nouvelle quoteline d'avenant
            SBQQ__QuoteLine__c ql = Utils_Test.createCPQQuoteLineItem(amendment.Id, 80, 110, 1, prod2, false);
            ql.SBQQ__PricebookEntryId__c = priceBookEntry2.Id;
            ql.AmendedQLValidated__c = true;
            ql.OrderProductCreated__c = false;
            ql.SBQQ__Quantity__c = 1;
            ql.SBQQ__CustomerPrice__c = 125.0;
            ql.SBQQ__ProratedListPrice__c = 125.0;
            ql.SBQQ__CarryoverLine__c = false;
            ql.SBQQ__Existing__c = false;
            ql.SBQQ__NetPrice__c = 125.0;

            insert ql;

            System.debug('  -> passage en transmis');
            // puis passage en transmie
            amendment.DateTransmissionClient__c = Date.today();
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_TRANSMITTED;
            amendment.quoteIsValid__c = true;
            update amendment;

            System.debug('  -> passage en vendu attente avec mode de financement cash');
            // puis passage en vendu attente
            amendment.DateAcceptationClient__c = Date.today();
            amendment.MoyenTransmissionClient__c = 'Par email';
            amendment.financingMethod__c = financialRef.Id;
            amendment.SBQQ__Status__c = Constants.QUOTE_STATUS_SOLD;
            amendment.techQLValidated__c = true;
            //update amendment;

            //trigger runs here and launch the process

            Test.stopTest();

            //rderItem oItem = [SELECT Id, StatutDeRevision__c, SBQQ__QuoteLine__c FROM OrderItem WHERE SBQQ__QuoteLine__c = :ql.Id LIMIT 1];
            //System.assert(oItem != null);
            //System.assertEquals('Révisé', oItem.StatutDeRevision__c);
            //System.assertEquals(ql.Id, oItem.SBQQ__QuoteLine__c);

            //ql = [SELECT Id, OrderProductCreated__c FROM SBQQ__QuoteLine__c WHERE Id = :ql.Id];
            //System.assert(ql.OrderProductCreated__c);

            //amendment = [SELECT Id, techPB__c FROM SBQQ__Quote__c WHERE Id = :amendment.Id];
            //System.assert(amendment.techPB__c);
        }
    }
    */
}