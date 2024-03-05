/**
 * Created by 4C on 07/10/2020.
 */

@IsTest
public with sharing class Test_Schedulable_SalesCommissionInstant {

    @IsTest
    static void testNotTheGoodDay() {
        NRV10Calendar__c cal3 = new NRV10Calendar__c(commDate__c = Date.today().addDays(2));
        insert cal3;
        String cron = '0 0 0 * * ?';

        Test.startTest();

        Schedulable_SalesCommissionInstant schedul = new Schedulable_SalesCommissionInstant();
        String schId = System.schedule('snapshotSched', cron, schedul);

        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE JobType = 'ScheduledApex'];
        System.assertEquals(1, jobs.size(), 'Schedulable not in asyncApex list');
        System.assertEquals('Schedulable_SalesCommissionInstant', jobs.get(0).ApexClass.Name, 'Expected Schedulable_SalesCommissionInstant but got something else');

        List<AsyncApexJob> batchs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(batchs.isEmpty(), 'Batchs should not be queued');
    }

    @IsTest
    static void testTheGoodDay(){
        NRV10Calendar__c cal3 = new NRV10Calendar__c(commDate__c = Date.today());
        insert cal3;

        String cron = '0 0 0 * * ?';

        Test.startTest();

        Schedulable_SalesCommissionInstant schedul = new Schedulable_SalesCommissionInstant();
        String schId = System.schedule('snapshotSched', cron, schedul);

        Test.stopTest();

        List<AsyncApexJob> scheds = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE JobType = 'ScheduledApex'];
        System.assertEquals(1, scheds.size(), 'Schedulable not in asyncApex list');
        System.assertEquals('Schedulable_SalesCommissionInstant', scheds.get(0).ApexClass.Name, 'Expected Schedulable_SalesCommissionInstant but got something else');

        List<AsyncApexJob> batchs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assertEquals(1, batchs.size(), 'Wrong number of batch in queue');
        System.assertEquals('BA_SalesCommissionInstant', batchs.get(0).ApexClass.Name, 'Not the expected batch');
    }

}