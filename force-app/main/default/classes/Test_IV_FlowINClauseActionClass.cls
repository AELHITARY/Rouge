//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_FlowINClauseActionClass 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 07/09/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_FlowINClauseActionClass {
    
    @testSetup
    static void createData(){
        insert new Account[]{
            new Account(Name = 'A', Rating = 'A'),
            new Account(Name = 'B', Rating = 'B'),
            new Account(Name = 'C', Rating = 'C'),
            new Account(Name = 'D', Rating = 'D'),
            new Account(Name = 'E', Rating = 'E')
        };
    }

    @isTest
    private static void testCloneRecordMethod(){

        IV_FlowINClauseActionClass.FlowInputParameters[] inputList = new IV_FlowINClauseActionClass.FlowInputParameters[]{};
        IV_FlowINClauseActionClass.FlowOutputParameters[] outputList = new IV_FlowINClauseActionClass.FlowOutputParameters[]{};
        
        /* Testing Exception */
        IV_FlowINClauseActionClass.FlowInputParameters invalidInput = new IV_FlowINClauseActionClass.FlowInputParameters();
        invalidInput.objectApiName = 'Acc';
        invalidInput.fieldsToQuery = 'Id,Name,Rating';
        invalidInput.filterField = 'Rating';
        invalidInput.filteringValuesCollection = new String[]{'A','B'};
        inputList.add(invalidInput);

        try {
            outputList = IV_FlowINClauseActionClass.filterRecords(inputList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        
        inputList.clear();

        /* Preparing Flow Action input list */
        IV_FlowINClauseActionClass.FlowInputParameters input1 = new IV_FlowINClauseActionClass.FlowInputParameters();
        input1.objectApiName = 'Account';
        input1.fieldsToQuery = 'Id,Name,Rating';
        input1.filterField = 'Rating';
        input1.filteringValuesCollection = new String[]{'A','B'};
        
        IV_FlowINClauseActionClass.FlowInputParameters input2 = new IV_FlowINClauseActionClass.FlowInputParameters();
        input2.objectApiName = 'Account';
        input2.fieldsToQuery = 'Id,Name,Rating';
        input2.filterField = 'Rating';
        input2.filteringValuesCollection = new String[]{'C'};
        
        IV_FlowINClauseActionClass.FlowInputParameters input3 = new IV_FlowINClauseActionClass.FlowInputParameters();
        input3.objectApiName = 'Account';
        input3.fieldsToQuery = 'Id,Name,Rating';
        input3.filterField = 'Rating';
        input3.filteringValuesCollection = new String[]{'D','E'};
        
        inputList.add(input1);
        inputList.add(input2);
        inputList.add(input3);
        
        Test.startTest();
            outputList = IV_FlowINClauseActionClass.filterRecords(inputList);
        Test.stopTest();

        System.assert(outputList[0].records.size() == 2);
        System.assert(outputList[1].records.size() == 1);
        System.assert(outputList[2].records.size() == 2);
    }
}