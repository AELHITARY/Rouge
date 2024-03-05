/**
 * Created by Gregory Quinet on 13/10/2020.
 */

@IsTest
public with sharing class Test_Process_DoNothing {

    @IsTest
    public static void testDoNothing() {
        Process_DoNothing.doNothing();
    }
}