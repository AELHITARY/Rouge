//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomProviderOrderWizard
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/04/2022
//-- Version     : 1.0
//-- Description : Classe de tests de LWC_CustomProviderOrderWizard
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_CustomProviderOrderWizard {    
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RTDevNamePersonnalAcc = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RTDevNameProvider = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);

    @testSetup 
    static void setup() { 
        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        refList.add(refDep);
        insert refList;

        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', RTDevNamePersonnalAcc, null, 'Email', false);
        Account entiteDep = Utils_Test.createEntity('TEST', 'DEP00X0', Date.today(), '0123456789', refDep.Id, false);
        Account provider1 = Utils_Test.createAccountPro('PROVIDERONE','0123456789', RTDevNameProvider, null , null, false);
        Account provider2 = Utils_Test.createAccountPro('PROVIDERTWO','0123456789', RTDevNameProvider, null , null, false);
        List<Account> accList = new List<Account>();
        accList.add(accountTest);
        accList.add(entiteDep);
        accList.add(provider1);
        accList.add(provider2);
        insert accList;

        //Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        //chantier.sectorisation__c = secto.Id;
        chantier.heatingMode__c = 'Individuel Electrique';
        chantier.serviceEntity__c =entiteDep.Id;
        insert chantier;

        Id pBook = Test.getStandardPricebookId();

        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
        Product2 productTest2 = Utils_Test.createProduct('Test2', 'TEST2' , false);
        Product2 productTest3 = Utils_Test.createProduct('Test2', 'INCONNU' , false);
        
        productTest1.isOrderable__c = true;
        productTest2.isOrderable__c = true;
        productTest3.isOrderable__c = true;
        
        List<Product2> prodList = new List<Product2>();
        prodList.add(productTest1);
        prodList.add(productTest2);
        prodList.add(productTest3);
        insert prodList;

        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }

        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, entiteDep.Id, false);
        newCustomerOrder.provider__c=provider1.Id;
        newCustomerOrder.serviceEntity__c=entiteDep.Id;
        newCustomerOrder.AccountId = accountTest.Id;
        newCustomerOrder.chantier__c = chantier.Id;
        insert newCustomerOrder;

        Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, accountTest.Id,false);
        Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test2', newCustomerOrder.Id, productTest2.Id, accountTest.Id,false);
        List<Asset> assetList = new List<Asset>();
        assetList.add(newAsset1);
        assetList.add(newAsset2);
        insert assetList;     
        
        Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
        case1.AssetId=newAsset1.Id;
        case1.responsability__c = 'Client';
        case1.chantier__c = chantier.Id;
        case1.Status = 'Nouveau';
        case1.Subject = 'test';
        case1.Description = 'test_NCPCASE';        
        insert case1;

        Product_Provider__c pp1 = Utils_Test.createProductProvider(provider1.Id, productTest1.Id, false);
        Product_Provider__c pp2 = Utils_Test.createProductProvider(provider2.Id, productTest2.Id, false);
        List<Product_Provider__c> ppList = new List<Product_Provider__c>();
        ppList.add(pp1);
        ppList.add(pp2);
        insert ppList;
    }

    @isTest
    private static void testGetProducts(){
        //LWC_CustomOrderLockerWizard.getOrdersFromRecordId
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        Test.startTest();
        System.runAs(user){
            
            List<Order> customerOrder = [SELECT Id, RecordType.DeveloperName, Name, Type FROM Order WHERE RecordType.DeveloperName='CustomerOrder'];
            System.assert(LWC_CustomProviderOrderWizard.getProducts(customerOrder[0].Id).size()==2,'Problème test TestGetProducts');
            LWC_CustomProviderOrderWizard.getUnknownProduct();
            LWC_CustomProviderOrderWizard.getProviderOrderRecordType();
            Test.stopTest();
        }
    }

    @isTest
    private static void testGetAllProviders(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<String> assetIdList = new List<String>();
            for (asset a : [SELECT Id FROM Asset]){
                assetIdList.add(a.Id);                
            }
            LWC_CustomProviderOrderWizard.getAllProvidersUnknown();
            System.assert(LWC_CustomProviderOrderWizard.getAllProviders(assetIdList,'Order').size()==2, 'Problème test TestGetAllProviders');
            Test.stopTest();
        }
    }

    @isTest
    private static void testGetProviders(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            List<String> assetIdList = new List<String>();
            for (asset a : [SELECT Id FROM Asset]){
                assetIdList.add(a.Id);                
            }
            LWC_CustomProviderOrderWizard.getProviders(assetIdList, true);
            System.assert(LWC_CustomProviderOrderWizard.getProviders(assetIdList, false).size()==2, 'Problème test TestGetProviders');
            /*String test = LWC_CustomProviderOrderWizard.ProductProvider.getAssetId();
            String test2 = LWC_CustomProviderOrderWizard.ProductProvider.getDimensions();
            String test3 = LWC_CustomProviderOrderWizard.ProductProvider.getAssetName();
            String test4 = LWC_CustomProviderOrderWizard.ProductProvider.getProductCode();
            String test5 = LWC_CustomProviderOrderWizard.ProductProvider.getSupName();
            String test6 = LWC_CustomProviderOrderWizard.ProductProvider.getSupId();
            Decimal test7 = LWC_CustomProviderOrderWizard.ProductProvider.getProductCostPrev();
            Date test8 = LWC_CustomProviderOrderWizard.ProductProvider.getDeliveryDatePrev();
            String test9 = LWC_CustomProviderOrderWizard.ProductProvider.getLineNumber();
            String test10 = LWC_CustomProviderOrderWizard.ProductProvider.getProvId();
            String test11 = LWC_CustomProviderOrderWizard.ProductProvider.getProviderReferenceOrder();*/
            Test.stopTest();
        }
    }

    @isTest
    private static void testGetSelectedProductProviders(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();

            List<Map<String,String>> selectedSupList = new List<Map<String,String>>();
            List<String> productProviderId = new List<String>();
            for (Product_Provider__c pp  : [SELECT Id, product__c FROM Product_Provider__c]){
                System.debug('#pp:'+pp);
                Map<String,String> newMap = new Map<String,String>();
                for (Asset a : [SELECT Id, Product2Id FROM Asset]){
                    if(a.Product2Id == pp.product__c){
                        newMap.put('id', a.Id);
                        newMap.put('value', pp.Id);
                        break;
                    }              
                }
                System.debug('#newMap:'+newMap);
                selectedSupList.add(newMap);
            }
            LWC_CustomProviderOrderWizard.getSelectedProductProviders(selectedSupList, false);
            LWC_CustomProviderOrderWizard.getSelectedProductProviders(selectedSupList, true);
            Test.stopTest();
        }

    }
    
    @isTest
    private static void testCreateOrders(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();

            List<Map<String,String>> selectedSupList = new List<Map<String,String>>();
            List<Map<String,String>> selectedSupList2 = new List<Map<String,String>>();
            List<String> productProviderId = new List<String>();
            for (Product_Provider__c pp  : [SELECT Id, product__c FROM Product_Provider__c]){
                Map<String,String> newMap = new Map<String,String>();
                for (Asset a : [SELECT Id, Product2Id FROM Asset]){
                    if(a.Product2Id == pp.product__c){
                        newMap.put('id', a.Id);
                        newMap.put('value', pp.Id);
                        break;
                    }              
                }
                selectedSupList.add(newMap);
            }
            List<Order> customerOrder = [SELECT Id, RecordType.DeveloperName, Name, Type, AccountId, serviceEntity__c, QuoteId FROM Order WHERE RecordType.DeveloperName='CustomerOrder'];
            List<Account> entite = [SELECT Id FROM Account WHERE Name = 'DEP00X0' OR Name = 'TEST'];
            customerOrder[0].serviceEntity__c = entite[0].Id;
            update customerOrder[0];
            system.debug('## customerOrder : '+customerOrder);
            LWC_CustomProviderOrderWizard.createOrders(selectedSupList, String.valueOf(customerOrder[0].Id), Date.today(), 'Extranet', 
                                                        String.valueOf(customerOrder[0].Type), Date.today(), selectedSupList2, false, 'Order','Client');
            /*LWC_CustomProviderOrderWizard.createOrders(selectedSupList, String.valueOf(customerOrder[1].Id), Date.today(), 'Extranet', 
                                                        String.valueOf(customerOrder[0].Type), Date.today(), selectedSupList2, true, 'Order', 'Client');*/

            Test.stopTest();
        }
    }

     @isTest
     private static void testCreateOrderNPCAndUnknown(){
         Test.startTest();
         User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
         System.runAs(user){
            

            List<Map<String,String>> selectedSupList = new List<Map<String,String>>();
             List<Map<String,String>> selectedSupList2 = new List<Map<String,String>>();
             List<String> productProviderId = new List<String>();
             for (Product_Provider__c pp  : [SELECT Id, product__c FROM Product_Provider__c]){
                 Map<String,String> newMap = new Map<String,String>();
                 system.debug('## Product_Provider__c : '+pp);
                 for (Asset a : [SELECT Id, Product2Id FROM Asset]){
                     if(a.Product2Id == pp.product__c){
                         system.debug('## asset : '+a);
                         newMap.put('id', a.Id);
                         newMap.put('value', pp.Id);
                         break;
                     }              
                 }
                 selectedSupList.add(newMap);
            }

           List<Case> npc = [SELECT Id, Chantier__c, serviceConcerne__c, customerOrder__c,entity__c FROM Case WHERE responsability__c = 'Client'];
            LWC_CustomProviderOrderWizard.createOrders(selectedSupList, String.valueOf(npc[0].Id), Date.today(), 'Extranet', 
                                                         'Commande marchandise', Date.today(), selectedSupList2, true, 'Case','Client');
             
            LWC_CustomProviderOrderWizard.getNcpResponsability(String.valueOf(npc[0].Id), 'Case');
            

             Test.stopTest();
         }
     }
    
    @isTest
    private static void testUtils(){
        Test.startTest();

        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user) {
            LWC_CustomProviderOrderWizard.generateAuraException('TEST');
        }
        Test.stopTest();
    } 
}