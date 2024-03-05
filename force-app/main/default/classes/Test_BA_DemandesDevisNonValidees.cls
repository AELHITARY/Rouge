//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_BA_DemandesDevisNonValidees
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 19/07/2018
//-- Version     : 1.2
//-- * 1.2 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.1 : Optimisation
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_BA_DemandesDevisNonValidees {

  	@testSetup static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
    	PropertiesUtils.setIntegerValue('demandededevis.delai.validation', 0); // Exécution du code immédiatement
        PropertiesUtils.setIntegerValue('demandededevis.delai.reprise', 0); // Exécution du code immédiatement
        PropertiesUtils.setBooleanValue('import.deversement.enabled', true);

    	List<Import__c> importsToInsert = new List<Import__c>();

        // Récupération Record Type
        Id rtImport = DAL.getRecordTypeIdByDevName(Constants.RT_IMPORT_EXTERNE);

        // Création
        Import__c imp1 = Utils_Test.createImport(rtImport,'NOMUN','PRENOMUN','2 avenue des Champs Elysées','Paris','75008','0100000001',
                                                    'puser'+system.now().format('hhmmss')+'@testemail.com','', null,false);
        imp1.nomFichierSource__c='formulaire_site_kpark.fr';
        imp1.dateIntegration__c = null;
        imp1.integrable__c = false;
        imp1.messageException__c = '';
        Import__c imp2 = Utils_Test.createImport(rtImport,'NOMDEUX','PRENOMDEUX','4 avenue des Champs Elysées','Paris','75008','0100000002',
                                                    'puser'+system.now().format('hhmmss')+'@testemail.com','', null,false);
        imp2.nomFichierSource__c='formulaire_site_kpark.fr';
        imp2.dateIntegration__c = null;
        imp2.integrable__c = false;
        imp2.messageException__c = '';
        Import__c imp3 = Utils_Test.createImport(rtImport,'NOMTROIS','PRENOMTROIS','6 avenue des Champs Elysées','Paris','75008','0100000003',
                                                    'puser'+system.now().format('hhmmss')+'@testemail.com','', null,false);
        imp3.nomFichierSource__c='formulaire_site_kpark.fr';
        imp3.dateIntegration__c = null;
        imp3.integrable__c = false;
        imp3.messageException__c = '';
        Import__c imp4 = Utils_Test.createImport(rtImport,'NOMQUA','PRENOMQUA','8 avenue des Champs Elysées','Paris','75008','0100000004',
                                                    'puser'+system.now().format('hhmmss')+'@testemail.com','', null,false);
        imp4.nomFichierSource__c='formulaire_site_kpark.fr';
		imp4.dateIntegration__c = null;
        imp4.integrable__c = false;
        imp4.messageException__c = '';

        importsToInsert.add(imp1);
		importsToInsert.add(imp2);
		importsToInsert.add(imp3);
		importsToInsert.add(imp4);
		insert importsToInsert;
	}

  	@isTest static void test_batch_DemandesDevisNonValidees() {
    	// Exécution du test
    	Test.startTest();

        /*Schedule_DemandesDevisNonValidees schedule = new Schedule_DemandesDevisNonValidees();
        schedule.execute(null);*/

        BA_DemandesDevisNonValidees ba = new BA_DemandesDevisNonValidees();
        Database.executeBatch(ba);

    	Test.stopTest();
  	}
}