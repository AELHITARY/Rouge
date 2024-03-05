//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_UserContext
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 27/02/2023
//-- Version     : 1.3
//-- * 1.3 : Revue suite suppression de rôles
//-- * 1.2 : Correction pour les profils
//-- * 1.1 : RQM-113 : Ajout des constantes pour les nouveaux rôles/profils
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_UserContext {

	@isTest 
	static void test() {
		UserContext ctx1 = UserContext.getContext();
		UserContext ctx2 = UserContext.getContext(null);

		System.assertNotEquals(null, ctx1);
		System.assertNotEquals(null, ctx2);
		System.assertEquals(ctx1.getUser().id, ctx2.getUser().id);
		System.assertEquals(ctx1.getProfile().id, ctx2.getProfile().id);
		System.assertEquals(ctx1.getRole().id, ctx2.getRole().id);

		ctx1.setByPassTriggers(true);
		ctx1.setByPassValidationRules(true);
		ctx1.setByPassWorkflowRules(true);

		ctx1.canByPassValidationRules();
		ctx1.canByPassWorkflowRules();
		ctx1.canByPassTrigger('TEST');
   	}
   
	@isTest 
	static void test2() {
        // Récupération profil
        String prfId = [Select Id FROM Profile WHERE Name = 'K/K - Superviseur'].Id;
        // Création utilisateurs
        User user = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfId, 'DR123', 'DV123', 'M123',true);

        System.runAs(user){      
            Test.startTest();

			UserContext ctx1 = UserContext.getContext(user.id);
			ctx1.isSupportUser();
			ctx1.isChatterUser();
			System.assertEquals(true, ctx1.isCallUser());

            Test.stopTest();   
        }   
	}
   
	@isTest 
	static void test3() {
	 	// Récupération profil
		String prfId = [Select Id FROM Profile WHERE Name = 'K/K - Vendeur'].Id;
		// Création utilisateurs
		User user = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfId, 'DR123', 'DV123', 'M123',true);

		System.runAs(user){      
			Test.startTest();

			UserContext ctx1 = UserContext.getContext(user.id);
			ctx1.isSupportUser();
			ctx1.isChatterUser();
			System.assertEquals(true, ctx1.isSaleUser());

			Test.stopTest();   
		}   
   	}
   
	@isTest 
	static void test4() {
		// Récupération profil
		String prfId1 = [Select Id FROM Profile WHERE Name = :Constants.PROFIL_KPK_CONSULTATION].Id;
		String prfId2 = [Select Id FROM Profile WHERE Name = :Constants.PROFIL_Vendeur].Id;
		String prfId3 = [Select Id FROM Profile WHERE Name = 'K/K - Formateur'].Id;
		// Création utilisateurs
		User user = Utils_Test.createUser(true,'tes1', 'MyTestUserName1@test.sfd.test', 'MyTestLastName1','MyTestFirstName1', prfId1, 'DR123', 'DV123', 'M123',true);
		User user2 = Utils_Test.createUser(true,'tes2', 'MyTestUserName2@test.sfd.test', 'MyTestLastName2','MyTestFirstName2', prfId2, 'DR123', 'DV123', 'M123',true);
		User user3 = Utils_Test.createUser(true,'tes3', 'MyTestUserName3@test.sfd.test', 'MyTestLastName3','MyTestFirstName3', prfId3, 'DR123', 'DV123', 'M123',true);

		System.runAs(user){    
			Set<ID> users = new Set<ID>();
			users.add(user.Id);			
			users.add(user2.Id);		
			users.add(user3.Id);		
			
			Test.startTest();
			Map<ID, UserContext> ctx = UserContext.getContexts(users);
			System.assertEquals(users.size(), ctx.size());

			Test.stopTest();   
		}   
	}

    @isTest 
    static void testGetMagasin() {
        UserRole uRole = new UserRole (Name = 'MAG_0000 - MAG - CAEN');
        insert uRole;

        User userAdmin = Utils_Test.createAdminUser();
        System.RunAs(userAdmin) {
            Utils_Test.createSectorisation();
        }

        // Création d'un utilisateur
        User user = Utils_Test.createVendeurUser('DR_0000', 'DV_0000', 'MAG_0000', uRole.Id);
		
		System.runAs(user){      
			Test.startTest();

			UserContext ctx1 = UserContext.getContext(user.id);

			// Magasin
			ctx1.getMagasins();

			Test.stopTest();   
		} 
    }
}