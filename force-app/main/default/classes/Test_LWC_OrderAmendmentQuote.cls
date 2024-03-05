//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_OrderAmendmentQuote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/06/2023
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_OrderAmendmentQuote
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_OrderAmendmentQuote {
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

    @testSetup 
    static void setup() {
        PropertiesUtils.setStringValue('cee.codesDVElligible','DV_0000');

        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, RT_REF_ENTITY, true, true, false, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, RT_REF_ENTITY, true, true, false, true, false);
        refList.add(refDep);
        refList.add(refMag);
        insert refList;

        // Création comptes
        List<Account> accToInsert = new List<Account>();
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
        Account accountTest = Utils_Test.createAccount('Dupont','Jean','test@test.fr', RT_ACC_PERSO, 'Email',false);
        accToInsert.add(accountTest);
        accToInsert.add(entiteDep);
        accToInsert.add(entiteMag);
        insert accToInsert;
        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.serviceEntity__c = entiteDep.id;
        chantier.salesEntity__c = entiteMag.id;
        chantier.rue__c = 'TEST';
        chantier.departement__c = 'TEST';
        chantier.heatingMode__c='Collectif';
        insert chantier;

        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
    }

    @isTest
    private static void testCreateQuoteAmendment(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.byPassTrigger__c = 'TR021_Account;TR021_Quote;TR022_QuoteLineItem;QA_KMDCEinstein;TR022_Quote';
        user.byPassValidationRule__c = true;
        update user;

        System.runAs(user){

            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Opportunity opp = [SELECT Id, AccountId, autreCompte__c, chantier__c FROM Opportunity LIMIT 1];

            Quote qt = Utils_Test.createQuote('Devis 1', null, opp, Constants.StatutDevisAConfigurer, Date.today(), 1000, 100, false);
            insert qt; 

            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }  

            QuoteLineItem qtli = Utils_Test.createQuoteLineItem(qt.Id, '1', 100, 100, 1, 10, 10, productTest1 ,false); 
            qtli.eligibleCEE__c=false;
            insert qtli;
            
            qt.dateAcceptationClient__c = date.today();
            qt.dateTransmissionClient__c = date.today();
            qt.moyenTransmissionClient__c = 'En main propre chez le client';
            update qt;
            
            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, false);
            customerOrder.QuoteId=qt.Id;
            insert customerOrder;
            
            OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, productTest1.Id, false);
            oi.QuoteLineItemId = qtli.Id;
            insert oi;
            
            Test.startTest();
            
            LWC_OrderAmendmentQuote.checkOrderItems(customerOrder.Id);
            LWC_OrderAmendmentQuote.createQuoteAmendment(customerOrder.Id,'test');

            Test.stopTest();
        }
    }
}