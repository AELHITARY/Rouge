//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_InsertCommercialCreditMemo
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 06/10/2021
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_InsertCommercialCreditMemo {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

    @testSetup 
    static void setup() {
        // Création entite 
        List<Referencial__c> refList = new List<Referencial__c>();       
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, false);
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, 
                                                            refEntityRT, true, true, true, true, false);
        refList.add(refMag);
        refList.add(refDep);
        insert refList;
        List<Account> accList = new List<Account>(); 
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', 
                                                 refMag.Id, false);
        Account entiteDep = Utils_Test.createEntity('DEPTESTTEST', 'DEPTESTTEST', Date.today(), '0123456789', 
                                                refDep.Id, false);
        // Création enregistrements utile
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRT, 'Email', false);
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(acc);
        insert accList;
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', acc.Id, false);
        chantier.salesEntity__c = entiteMag.Id;
        chantier.serviceEntity__c = entiteDep.Id;
        insert chantier;
        // Opportunity
        Opportunity opp = Utils_Test.createOpportunity('name', acc, null, chantier, true);
        
        Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.isConvertibleAsset__c=true;
        insert prod;
    }

    @isTest
    private static void testInsertCommercialCreditMemo_CPQ(){

        Test.startTest();
        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];

        // Vente devis pour création commande
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
        cpqQuote.SBQQ__Ordered__c = true;
        update cpqQuote;

        Order ord = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
        ord.SBQQ__Quote__c = cpqQuote.Id;
        ord.EffectiveDate = Date.today();
        insert ord;

        // Preparing Flow Action input list 
        System.debug('####ord.Id : ' + ord.Id);
        IV_InsertCommercialCreditMemo.FlowInputParameters[] inputList = new IV_InsertCommercialCreditMemo.FlowInputParameters[]{};
        IV_InsertCommercialCreditMemo.FlowInputParameters input1 = new IV_InsertCommercialCreditMemo.FlowInputParameters();
        input1.recordId = ord.Id;
        input1.amount = 2;
        input1.reason = 'Avoir commercial';
        inputList.add(input1);
        
        IV_InsertCommercialCreditMemo.insertCommercialCreditMemo(inputList);

        Test.stopTest();

    }

    @isTest
    private static void testInsertCommercialCreditMemo_Sales(){

        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :accPersoRT LIMIT 1];
        Account entiteMag = [SELECT Id FROM Account WHERE KparKReference__c = 'MAGTESTTEST' LIMIT 1];
        Account entiteDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEPTESTTEST' LIMIT 1];
    
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }

        Id rtRDV = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        Event event = Utils_Test.createEvent('R1',rtRDV,opp.id, opp.Account.PersonContactId,null,'Effectué', false);
        event.resultatDuRDV__c = null;
        insert event;

        Test.startTest();

        Quote quote = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, true);
        QuoteLineItem line = Utils_Test.createQuoteLineItem(quote.id, '2', 90, 150, 1, 1.0, 1.0, productTest1, true);

        Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
        customerOrder.QuoteId = quote.Id;
        customerOrder.salesEntity__c = entiteMag.Id;
        customerOrder.serviceEntity__c = entiteDep.Id;
        customerOrder.accountId = accountTest.Id;
        customerOrder.billingCity = 'Paris';
        customerOrder.billingName__c = accountTest.Id;
        customerOrder.billingPostalCode = '75000';
        customerOrder.shippingCity = 'Paris';
        customerOrder.ShippingPostalCode = '75000';
        customerOrder.shippingName__c = 'TEST';
        insert customerOrder;
        OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);        
        oi.QuoteLineItemId = line.Id;
        insert oi;

        // Preparing Flow Action input list 
        IV_InsertCommercialCreditMemo.FlowInputParameters[] inputList = new IV_InsertCommercialCreditMemo.FlowInputParameters[]{};
        IV_InsertCommercialCreditMemo.FlowInputParameters input1 = new IV_InsertCommercialCreditMemo.FlowInputParameters();
        input1.recordId = customerOrder.Id;
        input1.amount = 2;
        input1.reason = 'Avoir commercial';
        inputList.add(input1);
        
        //IV_InsertCommercialCreditMemo.insertCommercialCreditMemo(inputList);

        Test.stopTest();

    }
}