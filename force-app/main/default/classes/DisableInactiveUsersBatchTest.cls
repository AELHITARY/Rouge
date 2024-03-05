/**
 * @description       : 
 * @author            : MA
 * @last modified on  : 01-27-2024
 * @last modified by  : MA
 * @version           : 
**/
@isTest
private class DisableInactiveUsersBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users
        List<User> testUsers = new List<User>();
        for(Integer i = 0; i < 5; i++) {
            testUsers.add(new User(
                FirstName = 'Test' + i,
                LastName = 'User' + i,
                Email = 'test' + i + '@example.com',
                Username = 'testAAA' + i + '@example.com',
                Alias = 'T' + i,
                CommunityNickname = 'TestUser' + i,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id // Adjust the profile as needed
            ));
        }
        insert testUsers;
        
    }

    @isTest
    static void testBatchExecute() {

		User testUser = [SELECT Id FROM User WHERE FirstName = 'Test0'];

		System.runAs(testUser) {
			Test.startTest();

			// Start the batch job
			DisableInactiveUsersBatch batchJob = new DisableInactiveUsersBatch();
			Database.executeBatch(batchJob);
	
			Test.stopTest();
	
			// Query to check if users are frozen
			List<UserLogin> frozenUserLogins = [SELECT Id, UserId, IsFrozen FROM UserLogin WHERE IsFrozen = true];
			System.assertNotEquals(0, frozenUserLogins.size(), 'No user logins were frozen.');
		}
    }

}