/**
 * @author 4C
 * @date 2020-07-20
 * @description Test class for the before insert trigger
 */
@IsTest
public with sharing class Test_NRV10ManagerAssignment_InsertUpdate {

    private static final Id refEntityRT = DAL.getRecordTypeIdByDevName('Referencial__c',Constants.REFERENCIAL_ENTITY_RT);
    private static Date todayDate = Date.today();
    private static Date startDate = todayDate.addDays(-30);
    private static Collaborator__c collaborator1;
    private static Collaborator__c collaborator2;
    private static Referencial__c refMag1;
    private static Referencial__c refMag2;
    private static Account store1;
    private static Account store2;

    static void initContext() {

        User userSales = Utils_Test.createUser(false,'Sales1', 'sales1@test.remvrp.com', 'sal','es', null, null);
        userSales.ByPassValidationRule__c = true;
        userSales.ByPassWorkflowRule__c = true;
        userSales.ByPassTrigger__c = 'TR020_WorkOrder;TR022_WorkOrderLineItem;TR022_User;TR020_Phones;TR023_ChangeOwner;BA_QuoteProcessCommissions;TR023_SBQQ__Quote;TR022_Order;TR022_ContentVersion';
        update userSales;

        System.runAs(userSales) {
            collaborator1 = new Collaborator__c();
            collaborator1.firstname__c = 'first';
            collaborator1.Name = 'collaborator';
            collaborator1.lastName__c = 'collaborator';
            collaborator1.reference__c = 'sgid1';
            insert collaborator1;

            collaborator2 = new Collaborator__c();
            collaborator2.firstname__c = 'second';
            collaborator2.Name = 'collaborator';
            collaborator2.lastName__c = 'collaborator';
            collaborator2.reference__c = 'sgid2';
            insert collaborator2;

            refMag1 = Utils_Test.createReferencial('Magasin', 'MAG', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            store1 = Utils_Test.createEntity('MAGTESTTEST', 'MAGTESTTEST', Date.today(), '0123456789', refMag1.Id, true);

            //second magasin
            refMag2 = Utils_Test.createReferencial('Magasin2', 'MAG2', Date.today(), null,
                    refEntityRT, true, true, true, true, true);
            store2 = Utils_Test.createEntity('MAGTESTTEST2', 'MAGTESTTEST2', Date.today(), '01234567892', refMag2.Id, true);
        }
    }

    /**
     * @author 4C
     * @date 2020-07-20
     * @description Test trigger without other assignments ok
     */
    @IsTest
    static void testNoRecords() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.endDate__c = startDate.addDays(15);
            assignment.store__c = store1.Id;
            assignment.salesManager__c = collaborator1.Id;
            assignment.role__c = 'RV';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.assert(result[0].isSuccess(), 'Record has not been inserted');
        }
    }

    /**
     * @author 4C
     * @date 2020-07-20
     * @description Test trigger validation ok
     */
    @IsTest
    static void testNoConcurrentRecords() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            initContext();

            Test.startTest();

            NRV10ManagerAssignment__c assignmentOlder = new NRV10ManagerAssignment__c();
            assignmentOlder.startDate__c = startDate.addMonths(-1);
            assignmentOlder.endDate__c = startDate.addDays(-5);
            assignmentOlder.store__c = store1.Id;
            assignmentOlder.salesManager__c = collaborator1.Id;
            assignmentOlder.role__c = 'RV';
            insert assignmentOlder;

            NRV10ManagerAssignment__c assignmentAfter = new NRV10ManagerAssignment__c();
            assignmentAfter.startDate__c = startDate.addMonths(2);
            assignmentAfter.endDate__c = startDate.addMonths(3);
            assignmentAfter.store__c = store2.Id;
            assignmentAfter.salesManager__c = collaborator1.Id;
            assignmentAfter.role__c = 'RV';
            insert assignmentAfter;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.endDate__c = startDate.addDays(15);
            assignment.store__c = store1.Id;
            assignment.salesManager__c = collaborator1.Id;
            assignment.role__c = 'RV';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.assert(result[0].isSuccess(), 'Record has not been inserted');
        }
    }

    /**
     * @author 4C
     * @date 2020-07-17
     * @description Test trigger validation fail
     */
    @IsTest
    static void testConcurrentRecordBeforeEndBypassTrigger() {
        User testUser = Utils_Test.createUser(true, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);
        testUser.ByPassTrigger__c = 'TR020_AffectationManager';
        update testUser;

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentAfter = new NRV10ManagerAssignment__c();
            assignmentAfter.startDate__c = startDate.addMonths(2);
            assignmentAfter.store__c = store2.Id;
            assignmentAfter.salesManager__c = collaborator1.Id;
            assignmentAfter.role__c = 'RV';
            insert assignmentAfter;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store1.Id;
            assignment.salesManager__c = collaborator1.Id;
            assignment.role__c = 'RV';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.assert(result[0].isSuccess(), 'Record has not been inserted');
        }
    }

/**
     * @author 4C
     * @date 2020-07-17
     * @description Test trigger validation fail
     */
    @IsTest
    static void testConcurrentRecordBeforeEnd() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentAfter = new NRV10ManagerAssignment__c();
            assignmentAfter.startDate__c = startDate.addMonths(2);
            assignmentAfter.store__c = store2.Id;
            assignmentAfter.salesManager__c = collaborator1.Id;
            assignmentAfter.role__c = 'RV';
            insert assignmentAfter;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store1.Id;
            assignment.salesManager__c = collaborator1.Id;
            assignment.role__c = 'RV';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.assert(!result[0].isSuccess(), 'Insert has been successful');
            System.assert(result[0].getErrors().size() > 0, 'No error message found');
            System.assertEquals(System.Label.NRV10ManagerAssignmentValidationFailManager, result[0].getErrors()[0].getMessage(), 'Wrong error message');
        }
    }

    /**
     * Test qu'une affectation de RVJ sur même période qu'un RV est ok (1 seul rv+rvj)
     * @author 4C
     * @date 2020-07-17
     * @description Test trigger validation fail
     */
    @IsTest
    static void testConcurrentRecordBeforeEndOtherManagerOK() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentAfter = new NRV10ManagerAssignment__c();
            assignmentAfter.startDate__c = startDate.addMonths(2);
            assignmentAfter.store__c = store2.Id;
            assignmentAfter.salesManager__c = collaborator1.Id;
            assignmentAfter.role__c = 'RV';
            insert assignmentAfter;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.assert(result[0].isSuccess(), 'Insert has been successful');
            System.assert(result[0].getErrors().isEmpty(), 'Error message found');
        }
    }


    /**
     * Test qu'une affectation de RV sur même période qu'un autre RV est rejetée
     * @author 4C
     * @date 2020-07-17
     * @description Test trigger validation fail
     */
    @IsTest
    static void testConcurrentRecordBeforeEndOtherManagerRV() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentAfter = new NRV10ManagerAssignment__c();
            assignmentAfter.startDate__c = startDate.addMonths(2);
            assignmentAfter.store__c = store2.Id;
            assignmentAfter.salesManager__c = collaborator1.Id;
            assignmentAfter.role__c = 'RV';
            insert assignmentAfter;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.role__c = 'RV';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.assert(!result[0].isSuccess(), 'Insert has been successful');
            System.assert(result[0].getErrors().size() > 0, 'Error message found');
            System.assertEquals(System.Label.NRV10ManagerAssignmentValidationFailRole, result[0].getErrors()[0].getMessage(), 'Wrong error message');
        }
    }

    /**
     * @author 4C
     * @date 2020-08-11
     * @description Test trigger validation ok
     */
    @IsTest
    static void testConcurrentRecordReplacedBeforeEndOtherManager() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentOld = new NRV10ManagerAssignment__c();
            assignmentOld.startDate__c = startDate.addMonths(2);
            assignmentOld.store__c = store2.Id;
            assignmentOld.salesManager__c = collaborator1.Id;
            assignmentOld.role__c = 'RV';
            insert assignmentOld;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.replaced__c = collaborator1.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.debug('Save result: ' + result);

            System.assert(result[0].isSuccess(), 'Insert has not been successful');
            System.assert(result[0].getErrors().isEmpty(), 'Error message found');

            List<NRV10ManagerAssignment__c> assigns = [SELECT Id, startDate__c, endDate__c, salesManager__c, replaced__c FROM NRV10ManagerAssignment__c];

            System.assertEquals(1, assigns.size(), 'Replaced manager end date not deleted');
        }
    }

    /**
     * @author 4C
     * @date 2020-08-11
     * @description Test trigger validation ok
     */
    @IsTest
    static void testConcurrentRecordReplacedAfterStartOtherManager() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentOld = new NRV10ManagerAssignment__c();
            assignmentOld.startDate__c = startDate.addDays(-20);
            assignmentOld.store__c = store2.Id;
            assignmentOld.salesManager__c = collaborator1.Id;
            assignmentOld.role__c = 'RV';
            insert assignmentOld;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.replaced__c = collaborator1.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.debug('Save result: ' + result);

            System.assert(result[0].isSuccess(), 'Insert has not been successful');
            System.assert(result[0].getErrors().isEmpty(), 'Error message found');

            Boolean updatedDate = false;
            for(NRV10ManagerAssignment__c assign : [SELECT Id, startDate__c, endDate__c, salesManager__c, replaced__c FROM NRV10ManagerAssignment__c]) {
                System.debug('assignment ' + assign);
                System.debug('  check ' + assign.salesManager__c + ' VS ' + collaborator1.Id);
                System.debug('  check ' + assignmentOld.endDate__c + ' VS ' + assignment.startDate__c.addDays(-1));
                if (assign.salesManager__c == collaborator1.Id) {
                    if (assign.endDate__c == assignment.startDate__c.addDays(-1)) updatedDate = true;
                }
            }
            System.assert(updatedDate, 'Replaced manager end date not set');
        }
    }

    /**
     * @author 4C
     * @date 2020-08-11
     * @description Test trigger validation ok
     */
    @IsTest
    static void testConcurrentRecordReplacedEndAfterStartOtherManager() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentOld = new NRV10ManagerAssignment__c();
            assignmentOld.startDate__c = startDate.addDays(5);
            assignmentOld.store__c = store2.Id;
            assignmentOld.salesManager__c = collaborator1.Id;
            assignmentOld.role__c = 'RV';
            insert assignmentOld;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.endDate__c = startDate.addDays(15);
            assignment.replaced__c = collaborator1.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.debug('Save result: ' + result);

            System.assert(result[0].isSuccess(), 'Insert has not been successful');
            System.assert(result[0].getErrors().isEmpty(), 'Error message found');

            //This part tests the after trigger
            Boolean updatedDate = false;
            for(NRV10ManagerAssignment__c assign : [SELECT Id, startDate__c, endDate__c, salesManager__c, replaced__c FROM NRV10ManagerAssignment__c]) {
                System.debug('assignment ' + assign);
                System.debug('  check ' + assign.salesManager__c + ' VS ' + collaborator1.Id);
                System.debug('  check ' + assignmentOld.startDate__c + ' VS ' + assignment.endDate__c.addDays(1));
                if (assign.salesManager__c == collaborator1.Id) {
                    if (assign.startDate__c == assignment.endDate__c.addDays(1)) updatedDate = true;
                }
            }
            System.assert(updatedDate, 'Replaced manager start date not set');
        }
    }

    /**
     * @author 4C
     * @date 2020-08-11
     * @description Test trigger validation ok
     */
    @IsTest
    static void testDelete() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentOld = new NRV10ManagerAssignment__c();
            assignmentOld.startDate__c = startDate.addDays(5);
            assignmentOld.store__c = store2.Id;
            assignmentOld.salesManager__c = collaborator1.Id;
            assignmentOld.role__c = 'RV';
            insert assignmentOld;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.endDate__c = startDate.addDays(15);
            assignment.replaced__c = collaborator1.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);

            delete assignmentOld;
            delete assignment;
            Test.stopTest();
        }
    }

    /**
     * Test qu'une affectation de manager à cheval sur une affectattion de son remplacant est ok et supprime/modifie
     * le remplaçant.
     * @author 4C
     * @date 2020-08-11
     * @description Test trigger validation ok
     */
    @IsTest
    static void testManagerBackBeforeReplacementEnd() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentOld = new NRV10ManagerAssignment__c();
            assignmentOld.startDate__c = startDate.addDays(5);
            assignmentOld.store__c = store2.Id;
            assignmentOld.salesManager__c = collaborator1.Id;
            assignmentOld.replaced__c = collaborator2.Id;
            assignmentOld.role__c = 'RV';
            insert assignmentOld;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate.addDays(15);
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.debug('Save result: ' + result);

            System.assert(result[0].isSuccess(), 'Insert has not been successful');
            System.assert(result[0].getErrors().isEmpty(), 'Error message found');

            //This part tests the after trigger
            Boolean updatedDate = false;
            for(NRV10ManagerAssignment__c assign : [SELECT Id, startDate__c, endDate__c, salesManager__c, replaced__c FROM NRV10ManagerAssignment__c]) {
                System.debug('assignment ' + assign);
                System.debug('  check ' + assign.salesManager__c + ' VS ' + collaborator1.Id);
                System.debug('  check ' + assignmentOld.endDate__c + ' VS ' + assignment.startDate__c.addDays(-1));
                if (assign.salesManager__c == collaborator1.Id) {
                    if (assign.endDate__c == assignment.startDate__c.addDays(-1)) updatedDate = true;
                }
            }
            System.assert(updatedDate, 'Replaced manager start date not set');
        }
    }

    /**
     * Test qu'une affectation de manager à cheval sur une affectattion de son remplacant est ok et supprime/modifie
     * le remplaçant.
     * @author 4C
     * @date 2020-08-11
     * @description Test trigger validation ok
     */
    @IsTest
    static void testManagerBackBeforeReplacementEndAndStartAfterReturnStart() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentOld = new NRV10ManagerAssignment__c();
            assignmentOld.startDate__c = startDate.addDays(5);
            assignmentOld.endDate__c = startDate.addDays(45);
            assignmentOld.store__c = store2.Id;
            assignmentOld.salesManager__c = collaborator1.Id;
            assignmentOld.replaced__c = collaborator2.Id;
            assignmentOld.role__c = 'RV';
            insert assignmentOld;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.endDate__c = startDate.addDays(25);
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.debug('Save result: ' + result);

            System.assert(result[0].isSuccess(), 'Insert has not been successful');
            System.assert(result[0].getErrors().isEmpty(), 'Error message found');

            //This part tests the after trigger
            Boolean updatedDate = false;
            for(NRV10ManagerAssignment__c assign : [SELECT Id, startDate__c, endDate__c, salesManager__c, replaced__c FROM NRV10ManagerAssignment__c]) {
                System.debug('assignment ' + assign);
                System.debug('  check ' + assign.salesManager__c + ' VS ' + collaborator1.Id);
                System.debug('  check ' + assignmentOld.startDate__c + ' VS ' + assignment.endDate__c.addDays(1));
                if (assign.salesManager__c == collaborator1.Id) {
                    if (assign.startDate__c == assignment.endDate__c.addDays(1)) updatedDate = true;
                }
            }
            System.assert(updatedDate, 'Replaced manager start date not set');
        }
    }

    /**
     * Test qu'une affectation de manager avant une affectattion de son remplacant sans date de fin supprime
     * le remplaçant.
     * @author 4C
     * @date 2020-08-11
     * @description Test trigger validation ok
     */
    @IsTest
    static void testManagerBackBeforeReplacementStartNoEnd() {
        User testUser = Utils_Test.createUser(false, 'Admin1', 'admin@onecompany.com', 'First', 'Adm', null, null);

        System.runAs(testUser) {
            Test.startTest();
            initContext();

            NRV10ManagerAssignment__c assignmentOld = new NRV10ManagerAssignment__c();
            assignmentOld.startDate__c = startDate.addDays(5);
            assignmentOld.endDate__c = startDate.addDays(45);
            assignmentOld.store__c = store2.Id;
            assignmentOld.salesManager__c = collaborator1.Id;
            assignmentOld.replaced__c = collaborator2.Id;
            assignmentOld.role__c = 'RV';
            insert assignmentOld;

            NRV10ManagerAssignment__c assignment = new NRV10ManagerAssignment__c();
            assignment.startDate__c = startDate;
            assignment.store__c = store2.Id;
            assignment.salesManager__c = collaborator2.Id;
            assignment.role__c = 'RVJ';

            List<SObject> toSave = new List<SObject>{assignment};
            Database.SaveResult[] result = Database.insert(toSave, false);
            Test.stopTest();

            System.debug('Save result: ' + result);

            System.assert(result[0].isSuccess(), 'Insert has not been successful');
            System.assert(result[0].getErrors().isEmpty(), 'Error message found');

            //This part tests the after trigger
            Boolean updatedDate = false;
            List<NRV10ManagerAssignment__c> assigns = [SELECT Id, startDate__c, endDate__c,
                    salesManager__c, replaced__c FROM NRV10ManagerAssignment__c];

            System.assertEquals(1, assigns.size(), 'Replacement manager still in base');
        }
    }
}