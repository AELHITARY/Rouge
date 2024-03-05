//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_InsertInvoiceFromSA
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/09/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_InsertInvoiceFromSA {

    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static final Id assetEntityRT = DAL.getRecordTypeIdByDevName('Asset','Carpentry');  
    private static final Id wkRTId = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService'); 
    private static final Id SASARTId = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');

    @testSetup 
    static void setup() {
        
        
    }

    @isTest
    private static void test_IV_InsertInvoiceFromSA(){
        
        //Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        //PropertiesUtils.setStringValue('invoice.emailtemplate.name', 'Facture_Email_de_la_facture_au_client');
        // Création d'un contact et des comptes
        //Contact contact = Utils_Test.createContact('Test','Test',true);
        User [] u = TestData_fsl_Setup.createUser();
        Account a = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',true);
        // Création entite      
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, 
                                                             refEntityRT, true, true, true, true, true);
        
        Chantier__c chantier = Utils_Test.createChantier('', a.Id, null, null, null, a.Id, null, 4, true);
        Account entite = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag.Id, true);
        
        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,false);
        prod.isControllable__c=true;
        insert prod;
        
        // Price book
        Pricebook2 pBook = new Pricebook2(Name ='Test');
        insert pBook;
        PricebookEntry priceBookEntry = new PricebookEntry(UnitPrice = 125, Pricebook2Id = pBook.Id, Product2Id = prod.Id, IsActive = true);
        insert priceBookEntry;
        
        Order customerOrder = Utils_Test.createCustomerOrder(a.Id,false);
        //customerOrder.QuoteId = quote.Id;
        customerOrder.Pricebook2Id = pBook.Id;
        customerOrder.salesEntity__c = entite.Id;
        customerOrder.serviceEntity__c = entite.Id;
        customerOrder.chantier__c = chantier.Id;
        customerOrder.accountId = a.Id;
        customerOrder.billingCity = 'Paris';
        customerOrder.billingName__c = a.Id;
        customerOrder.billingPostalCode = '75000';
        customerOrder.shippingCity = 'Paris';
        customerOrder.ShippingPostalCode = '75000';
        customerOrder.shippingName__c = 'TEST';
        insert customerOrder;
        
        Asset asset1 = Utils_Test.createAsset(assetEntityRT, 'Test', customerOrder.Id, prod.Id, a.Id, true);
        OrderItem ordItem = Utils_Test.createOrderItem(customerOrder.Id, priceBookEntry.Id, asset1.Id, prod.Id, false);
        ordItem.name__c = 'TestOrderItem';
        insert ordItem;
        
        asset1.orderItem__c = ordItem.Id;
        update asset1;
        
        Test.startTest();
        // Creation Rendez-vous
        WorkType wt1 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_CONTROL, true);

        WorkType wt2 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_INTERVENTION, true);

        WorkType wt3 = Utils_Test.createWorkType(Constants.ACTIVITY_TYPE_DIAGNOSTIC, true);

        WorkOrder wo = Utils_Test.createWorkOrder(wkRTId, false);
        wo.customerOrder__c = customerOrder.Id;
        wo.WorkTypeId = wt1.Id;
        insert wo;
        
        ServiceAppointment sa1 = Utils_Test.createServiceAppointment(wo.Id, SASARTId, false);
        sa1.Status='Terminé';
        sa1.customerOrder__c = customerOrder.Id;
        sa1.ActualEndTime=Date.today();
        sa1.ActualStartTime=Date.today();
        sa1.fsl_dateConfirmation__c=Date.today();
        sa1.dateConfirmationClient__c=Date.today();
        sa1.SchedEndTime=Date.today();
        sa1.SchedStartTime=Date.today();
        insert sa1;
        
        WorkOrderLineItem woli =  Utils_Test.createWorkOrderLineItem(wo.Id, asset1.Id, false);
        insert woli;
        
        List<Skill> skillsList =  [SELECT Id, Description, DeveloperName, MasterLabel FROM Skill LIMIT 3];

        ProductSkill__c pk1 = Utils_Test.createProductSkill(skillsList[0].Id, 1, prod.Id, true);
        
        SkillRequirement reqSkill = Utils_Test.createSkillRequirement(skillsList[0].Id, 1, wt1.Id, true);
        
        FSL__Scheduling_Policy__c fslSp1 = Utils_Test.createSchedulingPolicy('test',true);

        IV_InsertInvoiceFromServiceAppointment.FlowInputParameters[] inputList = new IV_InsertInvoiceFromServiceAppointment.FlowInputParameters[]{};
            

        /* Preparing Flow Action input list */
        IV_InsertInvoiceFromServiceAppointment.FlowInputParameters input1 = new IV_InsertInvoiceFromServiceAppointment.FlowInputParameters();
        input1.serviceAppointmentId = sa1.Id;
        
        inputList.add(input1);
        
            IV_InsertInvoiceFromServiceAppointment.insertInvoiceFromServiceAppointment(inputList);
        Test.stopTest();

    }
}