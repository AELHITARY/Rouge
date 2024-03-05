//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Utils_HistoriqueBatchs
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/10/2022
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Utils_HistoriqueBatchs {
    private static final Id ACC_PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @isTest 
    static void test() {
        
        Test.startTest();

        BatchHistory__c batchHistoryStored;
        batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('TEST');
        batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, 2);
        batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
        batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
        
        Test.stopTest();
    }

    @isTest 
    static void testError() {
        
        Test.startTest();

        BatchHistory__c batchHistoryStored;
        batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('TEST');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, 2);
        batchHistoryStored = Utils_HistoriqueBatchs.updateTraceError(batchHistoryStored, 'ERROR');
        batchHistoryStored = Utils_HistoriqueBatchs.updateIdsError(batchHistoryStored, new List<String>{'ID1'});
        batchHistoryStored = Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERROR');
        batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);
        
        Test.stopTest();
    }

    @isTest 
    static void testErrorResult() {
        List<Account> accList = new List<Account>();
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', ACC_PERSO_RTID, null, 'Email', false);
        accList.add(accountTest);
        insert accList;

        Database.SaveResult[] saveResList = Database.update(accList, false);
        Database.DeleteResult[] deleteResList = Database.delete(accList, false);
        
        Test.startTest();

        BatchHistory__c batchHistoryStored;
        batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('TEST');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, 2);
        Utils_HistoriqueBatchs.changeDeleteResult(deleteResList, accList);
        Utils_HistoriqueBatchs.changeSaveResult(saveResList, accList);
        
        Test.stopTest();
    }
}