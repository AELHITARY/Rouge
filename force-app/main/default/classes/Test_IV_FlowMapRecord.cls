//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_FlowMapRecord
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_FlowMapRecord {
    private static final Id accPersoRecordType = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);

    @testSetup 
    static void setup() {
        Account acc = Utils_Test.createAccount('Account 1', 'test', 'test@test.fr', accPersoRecordType, 'Email',true);
    }
    
    @isTest 
    static void test() {

        List<Account> accList = [SELECT Id FROM Account];

        // Create
        IV_CreateFlowMapRecord.CreateMapInputs input = new IV_CreateFlowMapRecord.CreateMapInputs();
        input.keyField = 'Id';
        input.records = accList;
        List<IV_CreateFlowMapRecord.CreateMapInputs> inputList = new List<IV_CreateFlowMapRecord.CreateMapInputs>();
        inputList.add(input);
        List<IV_CreateFlowMapRecord.CreateMapOutputs> output = IV_CreateFlowMapRecord.createMap(inputList);

        // Get
        IV_GetValueFromMapRecord.GetValueInputs inputGet = new IV_GetValueFromMapRecord.GetValueInputs();
        inputGet.key = accList[0].Id;
        inputGet.flowMap = output[0].flowMap;
        List<IV_GetValueFromMapRecord.GetValueInputs> inputGetList = new List<IV_GetValueFromMapRecord.GetValueInputs>();
        inputGetList.add(inputGet);
        IV_GetValueFromMapRecord.getValue(inputGetList);

        Utils_FlowMapRecordClass flowMapRec = new Utils_FlowMapRecordClass();
        flowMapRec.key = 'TEST';
        flowMapRec.record = accList[0];
    }
}