//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_GDPR_AdminExportDeDonnees
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/05/2021
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_GDPR_AdminExportDeDonnees {

    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
    }

    @isTest
    static void test_Utility() {
        Ctrl_GDPR_AdminExportDeDonnees.populatePickListObject();
        Ctrl_GDPR_AdminExportDeDonnees.populatePickListObjectField('Account');
        Ctrl_GDPR_AdminExportDeDonnees.getObjectDepedencies('Account');
        Ctrl_GDPR_AdminExportDeDonnees.getObjectJointField('Account', 'Contact');
        Ctrl_GDPR_AdminExportDeDonnees.getObjectStructure('Account');
    }

    @isTest
    static void test_CreateMetadata() {
        // Création
        Ctrl_GDPR_AdminExportDeDonnees.createCustomMetadata('Account', 'Contact', 1, true, 'Id', 'AccountId');
        // Récupération
        List<referentielExportDonnesGDPR__c> refList = Ctrl_GDPR_AdminExportDeDonnees.getReglesExportationDeDonnees();
        Ctrl_GDPR_AdminExportDeDonnees.getMetadataById(refList[0].Id);
    }

    @isTest
    static void test_ModifyDeleteMetadata() {
        // Création
        Ctrl_GDPR_AdminExportDeDonnees.createCustomMetadata('Account', 'Contact', 1, true, 'Id', 'AccountId');
        // Récupération
        List<referentielExportDonnesGDPR__c> refList = Ctrl_GDPR_AdminExportDeDonnees.getReglesExportationDeDonnees();
        Ctrl_GDPR_AdminExportDeDonnees.modifyMetadataById(refList[0].Id, 'Account', 'Chantier__c', 1, true, 'Id', 'compte__c');
        Ctrl_GDPR_AdminExportDeDonnees.deleteMetadataById(refList[0].Id);
    }
}