@isTest
private class Test_EmailUtils {

	@isTest 
	static void test() {      
		EmailUtils.mailToITSupport('Test d\'envoi d\'email au support', 'Test d\'envoi d\'email au support');  
		EmailUtils.mailToAdministrators('Test d\'envoi d\'email aux administrateurs', 'Test d\'envoi d\'email aux administrateurs');
     
		Profile administrator = [SELECT id FROM profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système' LIMIT 1];
		UserRole ITSupport = [SELECT id FROM userRole WHERE name = 'Support utilisateur' LIMIT 1];
		EmailUtils.mailTo('Test d\'envoi d\'email au profil admin et au rôle support', 'Test d\'envoi d\'email au profil admin et au rôle support', [SELECT id FROM user WHERE profileId = :administrator.id OR userRoleId = :ITSupport.id]);
		EmailUtils.mailTo('Test d\'envoi d\'email au profil admin (copie: rôle support)', 'Test d\'envoi d\'email au profil admin (copie : rôle support)', [SELECT id FROM user WHERE profileId = :administrator.id], [SELECT id FROM user WHERE userRoleId = :ITSupport.id]);
		EmailUtils.mailTo('Test d\'envoi d\'email au rôle support', 'Test d\'envoi d\'email au rôle support', [SELECT id FROM UserRole WHERE Id = :ITSupport.id]);
		EmailUtils.mailTo('Test d\'envoi d\'email au 1er profil admin', 'Test d\'envoi d\'email au 1er profil admin', new String[]{[SELECT email FROM user WHERE isActive = TRUE AND profileId = :administrator.id LIMIT 1].email});
		EmailUtils.mailTo('Test d\'envoi d\'email au 1er profil admin', 'Test d\'envoi d\'email au 1er profil admin', new String[]{});
   }
   
	@isTest static void test2() {
		try {
			Integer i = 1/ 0;
			system.debug(i);     
		} catch(Exception ex) {
       		EmailUtils.reportException('Division par zéro', ex);
     	}
	}
}