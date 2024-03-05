@isTest
private with sharing class Test_LWC_QuoteCPQClone{
    @testSetup 
    static void setup() {
        String RTDevNamePersonnalAcc = DAL.getRecordTypeIdByDevName('Account', 'PersonalAccount');
        String RTDevNameReferencial = DAL.getRecordTypeIdByDevName('Referencial__c', 'CustomerCancellationReason');
       
        Account accountTest = Utils_Test.createAccount('name', 'name', 'test@test.fr', RTDevNamePersonnalAcc, null, 'Email', true);
        
        Sectorisation__c secto = Utils_Test.createSectorisation('123456', '12345', 'nomMag', '12345', 'nomDepot', '12345', 'nomCom', true);

        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', accountTest.Id,false);
        chantier.sectorisation__c=secto.Id;
        chantier.heatingMode__c='Collectif';
        insert chantier;

        Opportunity opp = Utils_Test.createOpportunity('name', accountTest, null, chantier, true);
        
        PropertiesUtils.setStringValue('ref.motifAnnulationKparK.code','RSL-0016');

        Referencial__c ref = Utils_Test.createReferencial('ref','ref', Date.today(), Date.today(), RTDevNameReferencial, false, false, false, false, false);
        ref.KparKReference__c= PropertiesUtils.getStringValue('ref.motifAnnulationKparK.code', 'RSL-0016');
        insert ref;

        SBQQ__Quote__c cpqQuote = Utils_Test.createCPQQuote(opp,Date.today(),1, true);

        SBQQ__QuoteLine__c cpqQuoteLine = Utils_Test.createCPQQuoteLineItem(cpqQuote.Id ,100, 100, 1,true);
    }

    /* TEMPLATE TEST
    @isTest
    private static void TestXxxXxxxxx(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
            
            Test.stopTest();
        }
    }*/

    @isTest
    private static void TestCloneQuote(){
        User user = Utils_Test.createUser(false,'testmlg2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', null, null);
        System.runAs(user){
            Test.startTest();
                SBQQ__Quote__c[] cpqQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
                try{
                    LWC_QuoteCPQClone.cloneQuote(cpqQuote[0].Id);     
                }
                catch(Exception e){}
            Test.stopTest();
        }
    }
}