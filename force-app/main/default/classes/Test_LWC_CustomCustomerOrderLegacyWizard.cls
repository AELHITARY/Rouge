//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomCustomerOrderLegacyWizard
//-- Modifié par : SOPRA STERIA 
//-- Modifie le  : 07/11/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
public without sharing class Test_LWC_CustomCustomerOrderLegacyWizard {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);

    @testSetup 
    static void testSetup() {
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        // Création réf
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
    }

    @isTest 
    static void testQLILegacy(){
        User user = Utils_Test.createUser(true,'Test', 'MyTestUserName@test.sfd.test', 'MyTestLastName','MyTestFirstName', null, null);
        user.byPassTrigger__c = 'TR020_Account;TR021_Account;TR022_Account;TR021_Quote;TR022_QuoteLineItem;QA_KMDCEinstein;TR022_Quote';
        user.byPassValidationRule__c = true;
        user.byPassWorkflowRule__c = true;
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
            Test.startTest();
            Utils_Test.createOption(line.Id,'1','Libellé Option 1',refOpt.Id,1,true);

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            customerOrder.QuoteId = quote.Id;
            insert customerOrder;
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, true);    
            OrderItem oiOpt = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);    
            oiOpt.parentOrderItem__c = oi.Id;
            oiOpt.productType__c = 'Component';
            insert oiOpt;
                
            

            List<LWC_CustomCustomerOrderLegacyWizard.OrderItemQLI> ordObj = LWC_CustomCustomerOrderLegacyWizard.getOrderItems(customerOrder.Id);
            LWC_CustomCustomerOrderLegacyWizard.getAllQuoteLines(customerOrder.Id);

            // Update
            Map<String,String> orderItemsRec = new Map<String,String>();
            orderItemsRec.put(oi.Id, line.Id);
            LWC_CustomCustomerOrderLegacyWizard.updateOrderItems(customerOrder.Id, orderItemsRec);

            // Autre
            ordObj[0].getId();
            ordObj[0].getProductCode();
            ordObj[0].getQty();
            ordObj[0].getDimensions();
            ordObj[0].getLocation();
            ordObj[0].getQLIId();
            ordObj[0].getQLIName();
            
            Test.stopTest();
        } 
    }
    
    @isTest
    private static void testUtils() {
        Test.startTest();
        LWC_CustomCustomerOrderLegacyWizard.generateAuraException('TEST');
        Test.stopTest();
    }
}