//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_GlobalPipelineGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/08/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_GlobalPipelineGeneratePDF
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
public without sharing class Test_LWC_GlobalPipelineGeneratePDF {
    private static final Id ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id ACC_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 

    @testSetup 
    static void setup() {
        String refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

        // Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', true);
        // Fournisseur
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', ACC_PROVIDER_RTID, null , null, true);
        // Création entite     
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, true);
    }
    
    @isTest
    private static void generatePDFToday() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassTrigger__c = 'QA_KMDCEinstein';
        update user;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_ENTITY_RTID LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PROVIDER_RTID LIMIT 1];

            // Produit
            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, null, entite.Id, entite.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            insert newCustomerOrder;
            // NCC
            String oncImposRT = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Impossibility');
            Utils_Test.createOrderNonCompliance('Test', newCustomerOrder.Id, oncImposRT, true);
            // Actif
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test', newCustomerOrder.Id, productTest1.Id, accountTest.Id, true);
            // Commande fournisseur
            Order newProviderOrder1 = Utils_Test.createProviderOrder(accountTest.Id, newCustomerOrder.Id, provider1.Id ,true);
            // Ligne commande fournisseur
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, true);
            newProviderOrder1.transmissionDate__c=Date.today();
            update newProviderOrder1;
            
            Test.startTest();
            LWC_GlobalPipelineGeneratePDF.renderDocumentPDF(entite.Id, Date.today(), null, 'pdf'); // Premiere génération
            LWC_GlobalPipelineGeneratePDF.renderDocumentPDF(entite.Id, Date.today(), null, 'pdf'); // Pour regénérer un document
            Test.stopTest();
        }
    }
    
    @isTest
    private static void generatePDFYesterday() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassTrigger__c = 'QA_KMDCEinstein';
        update user;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Account entite = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_ENTITY_RTID LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PROVIDER_RTID LIMIT 1];

            // Produit
            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , true);
            // Commande client
            Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, null, entite.Id, entite.Id, false);
            newCustomerOrder.oldCompositeStatus__c = 'Non métrable';
            newCustomerOrder.amount__c = 1000;
            insert newCustomerOrder;
            // NCC
            String oncImposRT = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Impossibility');
            Utils_Test.createOrderNonCompliance('Test', newCustomerOrder.Id, oncImposRT, true);
            // Actif
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test', newCustomerOrder.Id, productTest1.Id, accountTest.Id, true);
            // Commande fournisseur
            Order newProviderOrder1 = Utils_Test.createProviderOrder(accountTest.Id, newCustomerOrder.Id, provider1.Id ,true);
            // Ligne commande fournisseur
            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, true);
            newProviderOrder1.transmissionDate__c=Date.today();
            update newProviderOrder1;

            Test.startTest();
      
            OrderStatusHistory__c old = new OrderStatusHistory__c(
                customerOrder__c = newCustomerOrder.Id,
                oldCompositeStatus__c = newCustomerOrder.oldCompositeStatus__c,
                status__c = newCustomerOrder.oldCompositeStatus__c,
                applicationDate__c = Date.today()-1);
            insert old;

            LWC_GlobalPipelineGeneratePDF.renderDocumentPDF(entite.Id, Date.today()-1, null, 'xlsx');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testUtils() {
        Test.startTest();
        LWC_GlobalPipelineGeneratePDF.generateAuraException('TEST');
        Test.stopTest();
    }
}