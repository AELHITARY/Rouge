//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Prospection
//-- Modifié par : SOPRA - Julien MORINEAU
//-- Modifié le  : 24/04/2014
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
@isTest(seeAllData=false)
private class Test_Ctrl_Prospection {

	public static testMethod void test_Ctrl_Prospection(){
		List<Import__c> prospects = new List<Import__c>();

		String testmail = 'Ally@testemail.com';
		Date testdate = Date.newInstance(2014, 04, 22 );

		String testdatestring = '2014-04-22';

		Import__c p1 = new Import__c(villeCompte__c='Le Pecq',nomCompte__c='Rousseau',telephoneDomicileCompte__c='0980980980',
										emailCompte__c=testmail ,observationsComplementaires__c='Reliure',codePostalCompte__c ='78430',
										dateDeProspection__c=testdate);
		prospects.add(p1);

		PageReference pageRef = Page.VF_Prospection;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.standardController(prospects[0]);
		Ctrl_Prospection pro1 = new Ctrl_Prospection(stdController);
		pro1.DateProspection = Date.newInstance(2014, 04, 22 );

		pro1.Ville = 'Le Port-Marly';
		pro1.Cp = '78560';
		pro1.Rue = '2 allée Sisley';
		pro1.Nom = 'Pinto';
		pro1.Telephone = '0987654321';
		pro1.Email = 'Obladi@Oblada.com';
		pro1.Observation = 'La sonnette est cassée !';
		pro1.PId = '2';
		pro1.DateProspection = testdate;

		//Map<String,pro1> MapId = new Map<String,pro1>();
		Map<String,String> argument1 = new Map<String,String>();
		argument1.put('nom' , 'Pinto');
		argument1.put('rue' , '2 allée Sisley');
		argument1.put('ville' , 'Le Port-Marly');
		argument1.put('cp' , '78560');
		argument1.put('telephone' , '0987654321');
		argument1.put('email' , 'Obladi@Oblada.com');
		argument1.put('observation' , 'La sonnette est cassée !');
		argument1.put('pid' , '2');
		argument1.put('dateProspection' , '2014-04-22');

		//Ctrl_Prospection.insertProspection(argument1);

		Map<String,String> argument2 = new Map<String,String>();
		argument2.put('nom' , 'Gaulois');
		argument2.put('rue' , '2 rue de Versailles');
		argument2.put('ville' , 'Saint Germain En Laye');
		argument2.put('cp' , '78100');
		argument2.put('telephone' , '0909090909');
		argument2.put('email' , 'Zazi@Zazou.com');
		argument2.put('observation' , 'La sonnette marche !');
		argument2.put('pid' , '3');
		argument2.put('dateProspection' , '2014-04-22');

		//Ctrl_Prospection.insertProspection(argument2);

		Map<String,String> argument3 = new Map<String,String>();
		argument3.put('nom' , 'Morineau');
		argument3.put('rue' , '2 allée Sisley');
		argument3.put('ville' , 'Le Port-Marly');
		argument3.put('cp' , '78560');
		argument3.put('telephone' , '0139393939');
		argument3.put('email' , 'Zaza@61.com');
		argument3.put('observation' , 'La sonnette est cassée !');
		argument3.put('pid' , '2');
		argument3.put('dateProspection' , '2014-04-22');

		//Ctrl_Prospection.updateProspection(argument3);

		Map<String,String> argument4 = new Map<String,String>();
		argument4.put('nom' , 'Morineau');
		argument4.put('rue' , '2 allée Sisley');
		argument4.put('ville' , 'Le Port-Marly');
		argument4.put('cp' , '78560');
		argument4.put('telephone' , '0139393939');
		argument4.put('email' , 'Zaza@61.com');
		argument4.put('observation' , 'La sonnette est cassée !');
		argument4.put('pid' , '2');
		argument4.put('dateProspection' , '2014-04-22');

		//Ctrl_Prospection.deleteProspection(argument4);
		Ctrl_Prospection.getProspection(testdatestring);
	}
}