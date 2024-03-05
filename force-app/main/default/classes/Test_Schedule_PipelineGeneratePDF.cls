//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Schedule_PipelineGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/01/2023
//-- Version     : 1.0
//-- Description : Classe de tests pour Schedule_PipelineGeneratePDF et BA_GeneratePipeline
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Schedule_PipelineGeneratePDF {
    private static final String ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final String RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 

    @testSetup 
    static void setup() {
        String accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
        String providerRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
        String refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);  

        // Compte
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', accPersoRT, null, 'Email', true);
        // Fournisseur
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', providerRT, null , null, true);
        // Création entite     
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, true);
        Account entite = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        entite.migratedToK3__c = true;
        insert entite;
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
        Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Asset', newCustomerOrder.Id, productTest1.Id, null, null, accountTest.Id, true);
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
    }

    @isTest 
    static void testBatchAll() {
        // Exécution du test
        Test.startTest();

        BA_GeneratePipeline ba = new BA_GeneratePipeline(null, Date.today(), 'pdf', false);
        Database.executeBatch(ba, 1);

        Test.stopTest();

    }
    @isTest 
    static void testBatchOne() {
        // Exécution du test
        Test.startTest();

        Account accEnt = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_ENTITY_RTID LIMIT 1];
        BA_GeneratePipeline ba = new BA_GeneratePipeline(accEnt.Id, Date.today(), 'pdf', true);
        Database.executeBatch(ba, 1);

        Test.stopTest();

    }

    @isTest 
    static void testSchedule() {
        // Exécution du test
        Test.startTest();

        String jobId = System.schedule('Schedule_PipelineGeneratePDF', '0 0 * * * ?', new Schedule_PipelineGeneratePDF() );
        Schedule_PipelineGeneratePDF schedule = new Schedule_PipelineGeneratePDF();
        schedule.execute(null);

        Test.stopTest();

    }
}