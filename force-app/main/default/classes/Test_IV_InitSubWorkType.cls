@isTest
private class Test_IV_InitSubWorkType {
    private static final Id RT_REF_ENTITY = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT); 
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    private static final Id RT_CASE_INTPNC = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final Id RT_ACC_PERSO = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id RT_ACC_PROVIDER = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_WO_SERVICE = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final Id RT_ORD_PROVIDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final Id RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final String RDV_DEBRIEFE = Constants.RDV_FSL_DEBRIEFE;
    private static final String RDV_ENCOURS = Constants.RDV_FSL_ENCOURS;
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');

    @testSetup
    static void setup(){
        // FSL
        User [] u = TestData_fsl_Setup.createUser();
        OperatingHours oh = TestData_fsl_Setup.createOperatingHours();
        ServiceTerritory parentST = TestData_fsl_Setup.createDS(oh);
        ServiceTerritory st = TestData_fsl_Setup.createDepot(parentST,oh);

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
        entiteDep.serviceTerritory__c = st.Id;
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
        insert chantier;
        
        List<Product2> prodList = new List<Product2>();
        Product2 productTest1 = Utils_Test.createProduct('Test1', 'TEST1' , false);
        productTest1.isControllable__c=true;
        prodList.add(productTest1);
        insert prodList;
        
        List<Order> orderList = new List<Order>();
        Order newCustomerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, entiteMag.id, entiteDep.id, false);
        orderList.add(newCustomerOrder);
        
        Order newProviderOrder1 = Utils_Test.createProviderOrder(accountTest.Id, newCustomerOrder.Id, provider1.Id ,false);
        orderList.add(newProviderOrder1);
        insert orderList;
        
        Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
        Asset newAsset2 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test2', newCustomerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
        List<Asset> astList = new List<Asset>();
        astList.add(newAsset1);
        astList.add(newAsset2);
        insert astList;
    }

    @isTest
    private static void testCalculSubWorkType(){

        Test.startTest();
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.ByPassValidationRule__c = true;
        user.ByPassTrigger__c = 'TR020_User;TR001_fsl_ServiceAppointment;TR001_fsl_ServiceTerritory;TR001_fsl_User';
        update user;
        
        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :RT_ACC_PERSO LIMIT 1];
            Asset newAsset1 = [SELECT Id FROM Asset WHERE Name = 'Test1' LIMIT 1];
            Asset newAsset2 = [SELECT Id FROM Asset WHERE Name = 'Test2' LIMIT 1];
            Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
            Order newProviderOrder1 = [SELECT Id FROM Order WHERE RecordTypeId = :RT_ORD_PROVIDER LIMIT 1];
            Order newCustomerOrder = [SELECT Id FROM Order WHERE RecordTypeId != :RT_ORD_PROVIDER LIMIT 1];
            Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

            PricebookEntry pbEntry;
            List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                            FROM PricebookEntry 
                                            WHERE Product2Id = :productTest1.Id];
            for(PricebookEntry pbeSelected : pbeList) {
                if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
            }
            
            Case case1 = Utils_Test.createCase(RT_CASE_INTPNC, accountTest, null, chantier.Id, false);
            case1.AssetId=newAsset1.Id;
            insert case1;
            
            OrderItem newOrderItem1 = Utils_Test.createOrderItem(newProviderOrder1.Id, pbEntry.Id, newAsset1.Id, productTest1.Id, false);
            newOrderItem1.case__c=case1.Id;
            insert newOrderItem1;
            
            List<String> assetsId = new List<String>();
            assetsId.add(newAsset1.Id);
            assetsId.add(newAsset2.Id);
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_CONTROL, newCustomerOrder.Id, false, true,'');
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_INTERVENTION, newCustomerOrder.Id, false, true,'');
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_INTERVENTION, null, false, true,'');
            LWC_CustomWorkOrderWizard.getProductsNonCompliance(assetsId, null, Constants.ACTIVITY_TYPE_DIAGNOSTIC, newProviderOrder1.Id, true, true,'');
            
            List<String> assetsIdList = new List<String>();
            List<String> casesIdList = new List<String>(); 
            
            assetsIdList.add(case1.AssetId);
            casesIdList.add(case1.Id);

            List<IV_InitSubWorkType.FlowInputParameters> inputList = new List<IV_InitSubWorkType.FlowInputParameters>();

            IV_InitSubWorkType.FlowInputParameters input = new IV_InitSubWorkType.FlowInputParameters();
            input.workTypeName = Constants.ACTIVITY_TYPE_CONTROL;
            input.casesIdList = casesIdList;
            input.commandeId = newCustomerOrder.Id;

            inputList.add(input);
            
           IV_InitSubWorkType.initSubWorkType(inputList);
            Test.stopTest();
        }
    }
}