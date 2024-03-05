@isTest
public class Test_fsl_Schedule_ArUpdateRenfort {
    @isTest
    static void test(){
        Test.startTest();
        Schedule_fsl_ArUpdateRenfort b = new Schedule_fsl_ArUpdateRenfort();
        
        String sch = '0 5 * * * ?'; 
        String jobId = System.schedule('Catch job', sch, b);
        
        Test.stopTest();
    }
}