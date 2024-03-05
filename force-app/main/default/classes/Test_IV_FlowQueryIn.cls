//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_IV_FlowQueryIn 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 25/05/2022
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_IV_FlowQueryIn {
    
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

        IV_FlowQueryIn.Request[] requestList = new IV_FlowQueryIn.Request[]{};
        IV_FlowQueryIn.Results[] outputList = new IV_FlowQueryIn.Results[]{};            
            
        IV_FlowQueryIn.Request request1 = new IV_FlowQueryIn.Request();
        request1.fieldsToSelect = 'Name';
        request1.objectName = 'Account';
        request1.fieldToFilter = 'Name';
        request1.filterValuesString = 'A';
        //request1.filterValuesList = '';
        request1.field2ToFilter = 'Id';
        //request1.filter2ValuesList = '';
        request1.filter2ValuesString = 'A';
        requestList.add(request1);
        
        IV_FlowQueryIn.Request request2 = new IV_FlowQueryIn.Request();
        request2.fieldsToSelect = 'Id';
        request2.objectName = 'Case';
        request2.fieldToFilter = 'Id';
        request2.filterValuesString = 'A';
        //request2.filterValuesList = '';
        request2.field2ToFilter = '';
        //request2.filter2ValuesList = '';
        request2.filter2ValuesString = '';
        
        IV_FlowQueryIn.Request request3 = new IV_FlowQueryIn.Request();
        request3.fieldsToSelect = 'Id';
        request3.objectName = 'Opportunity';
        request3.fieldToFilter = 'Id';
        request3.filterValuesString = 'A';
        //request3.filterValuesList = '';
        request3.field2ToFilter = '';
        //request3.filter2ValuesList = '';
        request3.filter2ValuesString = '';
        requestList.add(request3);
        
        IV_FlowQueryIn.Request request4 = new IV_FlowQueryIn.Request();
        request4.fieldsToSelect = 'Id';
        request4.objectName = 'Contact';
        request4.fieldToFilter = 'Id';
        request4.filterValuesString = 'A';
        //request4.filterValuesList = '';
        request4.field2ToFilter = '';
        //request4.filter2ValuesList = '';
        request4.filter2ValuesString = '';
        requestList.add(request4);
        
        IV_FlowQueryIn.Request request5 = new IV_FlowQueryIn.Request();
        request5.fieldsToSelect = null;
        request5.objectName = 'Contact';
        request5.fieldToFilter = 'Id';
        request5.filterValuesString = 'A';
        //request5.filterValuesList = '';
        request5.field2ToFilter = '';
        //request5.filter2ValuesList = '';
        request5.filter2ValuesString = '';
        requestList.add(request5);
        
        IV_FlowQueryIn.Request request6 = new IV_FlowQueryIn.Request();
        request6.fieldsToSelect = 'Id';
        request6.objectName = null;
        request6.fieldToFilter = 'Id';
        request6.filterValuesString = 'A';
        //request6.filterValuesList = '';
        request6.field2ToFilter = '';
        //request6.filter2ValuesList = '';
        request6.filter2ValuesString = '';
        requestList.add(request6);
        
        IV_FlowQueryIn.Request request7 = new IV_FlowQueryIn.Request();
        request7.fieldsToSelect = 'Id';
        request7.objectName = 'Contact';
        request7.fieldToFilter = null;
        request7.filterValuesString = 'A';
        //request7.filterValuesList = '';
        request7.field2ToFilter = '';
        //request7.filter2ValuesList = '';
        request7.filter2ValuesString = '';
        requestList.add(request7);
        
        IV_FlowQueryIn.Request request8 = new IV_FlowQueryIn.Request();
        request8.fieldsToSelect = 'Id';
        request8.objectName = 'Contact';
        request8.fieldToFilter = 'Id';
        request8.filterValuesString = null;
        //request8.filterValuesList = '';
        request8.field2ToFilter = '';
        //request8.filter2ValuesList = '';
        request8.filter2ValuesString = '';
        requestList.add(request8);
        
        IV_FlowQueryIn.Request request9 = new IV_FlowQueryIn.Request();
        request9.fieldsToSelect = 'Id';
        request9.objectName = 'Referencial__c';
        request9.fieldToFilter = 'Id';
        request9.filterValuesString = 'A';
        //request9.filterValuesList = '';
        request9.field2ToFilter = '';
        //request9.filter2ValuesList = '';
        request9.filter2ValuesString = '';
        requestList.add(request9);
        
        IV_FlowQueryIn.Request request10 = new IV_FlowQueryIn.Request();
        request10.fieldsToSelect = 'Id';
        request10.objectName = 'ExpectedDocument__c';
        request10.fieldToFilter = 'Id';
        request10.filterValuesString = 'A';
        //request10.filterValuesList = '';
        request10.field2ToFilter = '';
        //request10.filter2ValuesList = '';
        request10.filter2ValuesString = '';
        requestList.add(request10);
        
        IV_FlowQueryIn.Request request11 = new IV_FlowQueryIn.Request();
        request11.fieldsToSelect = 'Id';
        request11.objectName = 'Product2';
        request11.fieldToFilter = 'Id';
        request11.filterValuesString = 'A';
        //request11.filterValuesList = '';
        request11.field2ToFilter = '';
        //request11.filter2ValuesList = '';
        request11.filter2ValuesString = '';
        requestList.add(request11);
        
        IV_FlowQueryIn.Request request12 = new IV_FlowQueryIn.Request();
        request12.fieldsToSelect = 'Id';
        request12.objectName = 'Option__c';
        request12.fieldToFilter = 'Id';
        request12.filterValuesString = 'A';
        //request12.filterValuesList = '';
        request12.field2ToFilter = '';
        //request12.filter2ValuesList = '';
        request12.filter2ValuesString = '';
        requestList.add(request12);
        
        IV_FlowQueryIn.Request request13 = new IV_FlowQueryIn.Request();
        request13.fieldsToSelect = 'Id';
        request13.objectName = 'RecordType';
        request13.fieldToFilter = 'Id';
        request13.filterValuesString = 'A';
        //request13.filterValuesList = '';
        request13.field2ToFilter = '';
        //request13.filter2ValuesList = '';
        request13.filter2ValuesString = '';
        requestList.add(request13);
        
        IV_FlowQueryIn.Request request14 = new IV_FlowQueryIn.Request();
        request14.fieldsToSelect = 'Id';
        request14.objectName = 'PricebookEntry';
        request14.fieldToFilter = 'Id';
        request14.filterValuesString = 'A';
        //request14.filterValuesList = '';
        request14.field2ToFilter = '';
        //request14.filter2ValuesList = '';
        request14.filter2ValuesString = '';
        requestList.add(request14);
        
        IV_FlowQueryIn.Request request15 = new IV_FlowQueryIn.Request();
        request15.fieldsToSelect = 'Id';
        request15.objectName = 'WorkOrderLineItem';
        request15.fieldToFilter = 'Id';
        request15.filterValuesString = 'A';
        //request15.filterValuesList = '';
        request15.field2ToFilter = '';
        //request15.filter2ValuesList = '';
        request15.filter2ValuesString = '';
        requestList.add(request15);
        
        IV_FlowQueryIn.Request request16 = new IV_FlowQueryIn.Request();
        request16.fieldsToSelect = 'Id';
        request16.objectName = 'Asset';
        request16.fieldToFilter = 'Id';
        request16.filterValuesString = 'A';
        //request16.filterValuesList = '';
        request16.field2ToFilter = '';
        //request16.filter2ValuesList = '';
        request16.filter2ValuesString = '';
        requestList.add(request16);
        
        Test.startTest();
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request2);
        try {
            outputList = IV_FlowQueryIn.queryFilter(requestList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            //System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        requestList.clear();
        requestList.add(request3);
        try {
            outputList = IV_FlowQueryIn.queryFilter(requestList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            //System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        requestList.clear();
        requestList.add(request4);
        try {
            outputList = IV_FlowQueryIn.queryFilter(requestList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            //System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        requestList.clear();
        requestList.add(request5);
        try {
            outputList = IV_FlowQueryIn.queryFilter(requestList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            //System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        requestList.clear();
        requestList.add(request6);
        try {
            outputList = IV_FlowQueryIn.queryFilter(requestList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            //System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        requestList.clear();
        requestList.add(request7);
        try {
            outputList = IV_FlowQueryIn.queryFilter(requestList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            //System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        requestList.clear();
        requestList.add(request8);
        try {
            outputList = IV_FlowQueryIn.queryFilter(requestList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            //System.assert(e.getMessage().contains('sObject type \'Acc\' is not supported'));
        }
        requestList.clear();
        requestList.add(request9);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request10);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request11);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request12);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request13);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request14);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request15);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        requestList.clear();
        requestList.add(request16);
        outputList = IV_FlowQueryIn.queryFilter(requestList);
        
        Test.stopTest();
    }
}