//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_GenerateQuoteCommissions
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/09/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_GenerateQuoteCommissions {
    private static final Id accPersoRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);

    @testSetup 
    static void setup() {
        User curUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String idUser = curUser.Id;
        GlobalProperties__c properties = new GlobalProperties__c(name = 'signea.package.ownerId', actif__c = true, stringValue__c = idUser);
        insert properties;

        List<Referencial__c> refList = new List<Referencial__c>();  
        Referencial__c refDep = Utils_Test.createReferencial('Depot', 'DEP', Date.today(), null, refEntityRT, true, true, true, true, false);
        refList.add(refDep);
        insert refList;
        
        // Comptes
        List<Account> accList = new List<Account>();       
        Account acc = Utils_Test.createAccount('Dupont','Jean','test@test.fr', accPersoRT, 'Email',false); 
        Account entDep = Utils_Test.createEntity('DEPOT', 'DEP', Date.today(), '0123456789', refDep.Id, false);
        accList.add(entDep);
        accList.add(acc);
        insert accList;
        
        // Chantier
        Chantier__c chantier = Utils_Test.createChantier('TEST', acc.Id, null, null, null, acc.Id, null, 4, false);
        chantier.serviceEntity__c = entDep.Id;
        insert chantier;

        // Projets
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = Utils_Test.createOpportunity(acc, chantier,false);
        oppList.add(opp);
        insert oppList;
        
        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        
        // Price book
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntry;
        List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice 
                                  FROM PricebookEntry 
                                  WHERE Product2Id = :prod.Id];
        for(PricebookEntry pbeSelected : pbeList) {
            if(pbeSelected.Product2Id == prod.Id) pbEntry = pbeSelected;
        }
        
        // Creation devis
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c devis = Utils_TesT.createCPQQuote ('Test Quote', null, opp, null, Date.today(), 1000, 10, 'FOIRE', null, false);
        devis.SBQQ__PricebookId__c = pricebookId;
        devis.SBQQ__Pricebook__c = pricebookId;
        quoteList.add(devis);
        insert quoteList;
    }

    @isTest
    private static void testGenerateQuoteCPQ(){
        List<IV_GenerateQuoteCommissions.FlowInputParameters> inputList = new List<IV_GenerateQuoteCommissions.FlowInputParameters>();

        /* Preparing Flow Action input list */
        SBQQ__Quote__c devis = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        List<String> quoteIdsList = new List<String>();
        quoteIdsList.add(devis.Id);
        
        IV_GenerateQuoteCommissions.FlowInputParameters input1 = new IV_GenerateQuoteCommissions.FlowInputParameters();
        input1.quoteIds = quoteIdsList;        
        inputList.add(input1);
        
        Test.startTest();
        IV_GenerateQuoteCommissions.calculateRemVRP(inputList);
        Test.stopTest();

    }

    @isTest
    private static void testError(){
        List<IV_GenerateQuoteCommissions.FlowInputParameters> inputList = new List<IV_GenerateQuoteCommissions.FlowInputParameters>();
        IV_GenerateQuoteCommissions.FlowInputParameters input1 = new IV_GenerateQuoteCommissions.FlowInputParameters();
        input1.quoteIds = null;        
        inputList.add(input1);

        Test.startTest();

        try {
            IV_GenerateQuoteCommissions.calculateRemVRP(inputList);
        } catch(Exception ex) {}

        Test.stopTest();

    }
}