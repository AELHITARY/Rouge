//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_RepriseIndicateursOrder
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 07/09/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
public without sharing class Test_BA_RepriseIndicateursOrder {
    private static final Id REF_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_ENTITY_RT);
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id REF_TERMSANDCONT_RTID = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_TERMSANDCONTITIONS_RT); 
    private static final Id ACC_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final Id RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT); 
    

    @testSetup 
    static void testSetup() {
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        // Création ref
        List<Referencial__c> refList = new List<Referencial__c>();
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refMag = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null, REF_ENTITY_RTID, true, true, true, true, false);
        Referencial__c refCgv = Utils_Test.createReferencial('CGV', 'CGV1', Date.today(), null, REF_TERMSANDCONT_RTID, false, false, false, false, false);
        refList.add(refDep);
        refList.add(refMag);
        refList.add(refCgv);
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

        EntityProviderParameters__c enPt = new EntityProviderParameters__c();
        enPt.provider__c = provider1.Id;
        enPt.entity__c = entiteDep.Id;
        enPt.KparKReference__c = 'Tue';
        enPt.deliveryDays__c = 'Tue';
        enPt.startDate__c = Date.today();
        enPt.stageName__c = 'En cours';
        insert enPt;
    }

    @isTest 
    static void testProviderOrder() {
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        user.byPassTrigger__c = 'QA_KMDCEinstein';
        user.byPassValidationRule__c = true;
        update user;

        System.runAs(user){
            Account accountTest = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PERSO_RTID LIMIT 1];
            Account provider1 = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_PROVIDER_RTID LIMIT 1];
            Account entDep = [SELECT Id FROM Account WHERE KparKReference__c = 'DEP00X0' LIMIT 1];
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

            List<Order> ordList = new List<Order>();

            Order customerOrder = Utils_Test.createCustomerOrder(accountTest.Id, chantier.Id, null, null, false);
            insert customerOrder;
            Order providerOrder = Utils_Test.createProviderOrder(entDep.Id, customerOrder.Id, provider1.Id ,false);
            insert providerOrder;

            Asset newAsset1 = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', customerOrder.Id, productTest1.Id, null, chantier.Id, accountTest.Id,false);
            List<Asset> astList = new List<Asset>();
            astList.add(newAsset1);
            insert astList;

            OrderItem oi2 = Utils_Test.createOrderItem(providerOrder.Id, pbEntry.Id, newAsset1.Id, productTest1.Id,true);

            BA_RepriseIndicateursOrder ba= new BA_RepriseIndicateursOrder(Date.today().addMonths(-4), Date.today());
            Database.executeBatch(ba);

            Test.stopTest();
        }  
    }
}