//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_KMDCEinstein
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 22/02/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
public without sharing class Test_IV_KMDCEinstein  {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void testSetup() {
        // Création ref
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
        accList.add(entiteMag);
        accList.add(entiteDep);
        accList.add(accountTest);
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
    static void testCalculate() {
        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }

        Test.startTest();

        Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,true);
        OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, null, true);

        IV_KMDCEinstein.FlowInputParameters[] inputList = new IV_KMDCEinstein.FlowInputParameters[]{};
        IV_KMDCEinstein.FlowInputParameters input = new IV_KMDCEinstein.FlowInputParameters();
        input.recordId = customerOrder.Id;
        inputList.add(input);
        IV_KMDCEinstein.generateKMDC(inputList);
        
        Test.stopTest();
    }

    @isTest 
    static void testInvalid() {
        Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
        Chantier__c chantier = [SELECT Id FROM Chantier__c LIMIT 1];
        Product2 productTest1 = [SELECT Id FROM Product2 WHERE reference__c = 'TEST1' LIMIT 1];

        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                    FROM PricebookEntry 
                                    WHERE Product2Id = :productTest1.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == productTest1.Id) pbEntry = pbeSelected;
        }

        Test.startTest();

        Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id,true);
        OrderItem oi = Utils_Test.createOrderItem(customerOrder.Id, pbEntry.Id, null, null, true);

        IV_KMDCEinstein.FlowInputParameters[] inputList = new IV_KMDCEinstein.FlowInputParameters[]{};
        IV_KMDCEinstein.FlowInputParameters input = new IV_KMDCEinstein.FlowInputParameters();
        input.recordId = '';
        inputList.add(input);

        try {
            IV_KMDCEinstein.generateKMDC(inputList);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Le paramètre recordId est vide'));
        }
        
        Test.stopTest();
    }
}