//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_CalculateSAVStatusGC
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/10/2024
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
public class Test_IV_CalculateSAVStatusGC {
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String RT_AST_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset',Constants.ASSET_CARPENTRY_RT);
    private static final String RT_PNC_INTERNALID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);

    @testSetup 
    static void testSetup() {
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', true);
        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,true);

        Product2 prod = Utils_Test.createProduct('Produit Test', 'TEST1', 'Fenetre', 'PVC', 50, 50, false);
        prod.SousMatiere__c = 'Ekilibre';
        prod.isConvertibleAsset__c=true;
        insert prod;

        //PricebookEntry pbe = Utils_Test.createPricebookEntry(prod.Id,true);

        Asset newAsset = Utils_Test.createAsset(RT_AST_CARPENTRY, 'Test1', null, prod.Id, null, chantier.Id, accountTest.Id,false);
        newAsset.controlDate__c = System.today() - 60;
        newAsset.installDate = System.today() - 10;

        insert newAsset;

        AfterSalesService__c dossierSav = new AfterSalesService__c(workSite__c = chantier.Id, description__c = 'TEST');
        insert dossierSav;

        Case caseTest = Utils_Test.createCase(RT_PNC_INTERNALID, accountTest, chantier.Id, Constants.REQUETE_RECLAMATION_METRAGE, '', '', false);
        caseTest.chantier__c = chantier.Id;
        caseTest.AssetId = newAsset.Id;
        caseTest.afterSalesService__c = dossierSav.Id;
        insert caseTest;
    }

    @isTest 
    static void testCalculate() {
        AfterSalesService__c dossierSav = [SELECT Id FROM AfterSalesService__c LIMIT 1];

        Test.startTest();
        

        IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters[] inputList = new IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters[]{};
        IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters input = new IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters();
        input.recordId = dossierSav.Id;
        inputList.add(input);
        IV_CalculateAfterSalesServiceStatusGC.calculateAfterSalesServiceStatusGC(inputList);
        
        Test.stopTest();
    }

    @isTest 
    static void testInvalid() {
        AfterSalesService__c dossierSav = [SELECT Id FROM AfterSalesService__c LIMIT 1];

        Test.startTest();

        IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters[] inputList = new IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters[]{};
        IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters input = new IV_CalculateAfterSalesServiceStatusGC.FlowInputParameters();
        input.recordId = '';
        inputList.add(input);

        try {
            IV_CalculateAfterSalesServiceStatusGC.calculateAfterSalesServiceStatusGC(inputList);
        } catch (Exception e) {
            Assert.areEqual(true, e.getMessage().contains('Le paramètre recordId est vide'));
        }
        
        Test.stopTest();
    }
}