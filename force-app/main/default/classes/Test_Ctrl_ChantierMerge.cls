//-- *
//-- Fichier     : Test_Ctrl_ChantierMerge
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 11/04/2017
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_ChantierMerge { 

	@testSetup 
    static void setup() {
		Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        Sectorisation__c defaultSectorisation = Utils_Test.createSectorisation();
	}

	@isTest 
    static void test_ManualFusion() {
        // Création d'un utilisateur
        User user = Utils_Test.createUser(true,'Test', 'puser'+system.now().format('hhmmss')+'@testemail.com', 'Test LastName','Test FirstName', null, null);

        // Test compte personnel sans géolocalisation avec association de conjoint
        System.RunAs(user) {
            Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
			RecordType accountRecordType = [Select id, Name from RecordType where sobjectType = 'Account' and isPersonType = true limit 1];
			RecordType chantierRecordType = [Select id, Name from RecordType where sobjectType = 'Chantier__c' and isActive = true limit 1];
			Account compte = Utils_Test.createAccount('Test', 'test', 'test@test.com', accountRecordType.Id, 'Email', true);
			Chantier__c chantier = Utils_Test.createChantier('a', compte.Id, true);
			Chantier__c chantier2 = Utils_Test.createChantier('b', compte.Id, true);
            List<Chantier__c> chaList = [SELECT Id FROM Chantier__c LIMIT 2];
			String doublonId=chaList[0].Id;
			String maitreId=chaList[1].Id;

            GlobalProperties__c dqe = new GlobalProperties__c(name='dqe.dedup.compte.enabled',booleanValue__c = true, stringValue__c='MAG');
            insert dqe;

            // TEST
            Test.startTest();

            PageReference pageRef = Page.VF_ChantierMerge;
			// Parametre doublon
			pageRef.getParameters().put('doublonKeyId', maitreId);
			pageRef.getParameters().put('detail', 'edit');
			pageRef.getParameters().put('doublonsId', doublonId);
			pageRef.getParameters().put('chantierObject', JSON.serialize(chantier2));
			pageRef.getParameters().put('cha1', maitreId);

			List<String> fieldList = new List<String>{ 'Name','rue__c','complementAdresse__c','codePostal__c','ville__c','departement__c','pays__c','etage__c','codeAcces__c','interphone__c','proprietaire__c',
                            'autreProprietaire__c','anneeAchat__c','locataire__c','autreLocataire__c','occupant__c','autreOccupant__c','anneeConstruction__c','caracteristiquesUrbanisme__c',
                            'typeHabitation__c','typeResidence__c','chauffages__c','montantDepensesChauffage__c','bilanEnergetique__c','isolationHabitation__c','nbPortesEtFenetres__c',
                            'presenceGarage__c','presencePortail__c','presenceTerrasse__c','description__c' };

            // Fusion manuel
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController stdController = new ApexPages.standardController(chantier);
            Ctrl_ChantierMerge ctrl = new Ctrl_ChantierMerge(stdController);

            List<SelectOption> optionListTest = new List<SelectOption>();
            optionListTest = ctrl.getcaracteristiquesUrbanisme();
            optionListTest = ctrl.getmodesDeChauffe();
            optionListTest = ctrl.gettypeHabitationList();
            optionListTest = ctrl.gettypeResidenceList();
            Ctrl_ChantierMerge.manualMerge(new Map<String,String>{'Name'=>'test'}, JSON.serialize(chantier2), doublonId, maitreId, fieldList);

			// Cancel
			ctrl.typeURL='edit';
			ctrl.doublonsId=doublonId;
            ctrl.cancelMerge();
			
            Test.stopTest();
        }
    }	
}