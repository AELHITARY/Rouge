//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_RepriseProviderOrderItemKube3
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/04/2023
//-- Version     : 1.0
//-- Description : Classe de tests de BA_RepriseProviderOrderItemKube3
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_BA_RepriseProviderOrderItemKube3 {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 

    @testSetup 
    static void setup() {
            // Création ref
            List<Referencial__c> refList = new List<Referencial__c>();
            Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, RT_REF_ENTITY, true, true, false, true, false);
            Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, RT_REF_ENTITY, true, true, false, true, false);
            refList.add(refDep);
            refList.add(refMag);
            insert refList;

            // Compte
            List<Account> accToInsert = new List<Account>();
            Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
            entiteDep.migratedToK3__c = true;
            Account entiteMag = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, false);
            Account accountTest = Utils_Test.createAccount('Dupont','Jean','test@test.fr', RT_ACC_PERSO, 'Email',false);
            Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RT_ACC_PROVIDER, null , null, false);
            accToInsert.add(accountTest);
            accToInsert.add(entiteDep);
            accToInsert.add(entiteMag);
            accToInsert.add(provider1);
            insert accToInsert;
            
            Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
            chantier.serviceEntity__c = entiteDep.id;
            chantier.salesEntity__c = entiteMag.id;
            chantier.rue__c = 'TEST';
            chantier.departement__c = 'TEST';
            insert chantier;
            
            List<Product2> prodList = new List<Product2>();
            Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
            productTest1.isControllable__c=true;
            prodList.add(productTest1);
            insert prodList;

            // Price book
            PricebookEntry priceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :productTest1.Id LIMIT 1];
            
            List<Order> orderList = new List<Order>();
            Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, entiteMag.id, entiteDep.id, false);
            newCustomerOrder.legacyReference__c = '0615157089';
            orderList.add(newCustomerOrder);
            insert orderList;
            
            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;

            OrderItem ordItem = Utils_Test.createOrderItem(newCustomerOrder.Id, priceBookEntry.Id, newAsset1.Id, productTest1.Id, false);
            ordItem.name__c = 'TestOrderItem';
            insert ordItem;
    }

    @isTest
    private static void testOneEntity(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account entDep = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PROVIDER LIMIT 1];
            Order customerOrder = [SELECT Id FROM Order LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset LIMIT 1];
            PricebookEntry priceBookEntry = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];
            
            Test.startTest();

            Order providerOrder = Utils_Test.createProviderOrder(entDep.Id, customerOrder.Id, provider1.Id ,false);
            providerOrder.isLegacy__c = true;
            insert providerOrder;
            OrderItem ordItem = Utils_Test.createOrderItem(providerOrder.Id, priceBookEntry.Id, newAsset1.Id, priceBookEntry.Product2Id, false);
            ordItem.name__c = 'TestOrderItem';
            ordItem.isLegacy__c = true;
            ordItem.status__c = 'Enregistré';
            insert ordItem;

            // Batch
            BA_RepriseProviderOrderItemKube3 ba= new BA_RepriseProviderOrderItemKube3(entDep.Id);
            Database.executeBatch(ba);

            Test.stopTest();
        }
    }

    @isTest
    private static void testMultiEntity(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassWorkflowRule__c = true;
        user.byPassValidationRule__c = true;
        update user;
                
        System.runAs(user){
            Account entDep = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PROVIDER LIMIT 1];
            Order customerOrder = [SELECT Id FROM Order LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset LIMIT 1];
            PricebookEntry priceBookEntry = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];
            
            Test.startTest();

            Order providerOrder = Utils_Test.createProviderOrder(entDep.Id, customerOrder.Id, provider1.Id ,false);
            providerOrder.isLegacy__c = true;
            insert providerOrder;
            OrderItem ordItem = Utils_Test.createOrderItem(providerOrder.Id, priceBookEntry.Id, newAsset1.Id, priceBookEntry.Product2Id, false);
            ordItem.name__c = 'TestOrderItem';
            ordItem.isLegacy__c = true;
            ordItem.status__c = 'Enregistré';
            insert ordItem;

            // Batch
            BA_RepriseProviderOrderItemKube3 ba= new BA_RepriseProviderOrderItemKube3(null);
            Database.executeBatch(ba);

            Test.stopTest();
        }
    }
}