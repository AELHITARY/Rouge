//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_MappingUtils
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/09/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest 
private class Test_MappingUtils {

    @testSetup
    static void setup() {
        Mapping__c origine = new Mapping__c(Name='origine-42', ConvertedValue__c='42', PickValue__c='STAND GM', Repository__c='origine');
        insert origine;
        Mapping__c call = new Mapping__c(Name='SOURCE', ConvertedValue__c='42', PickValue__c='SOURCE', Repository__c='call');
        insert call;
        Mapping__c credit = new Mapping__c(Name='credit-004', ConvertedValue__c='49', PickValue__c='PROMO - 24M JPO', Repository__c='credit');
        insert credit;
        Mapping__c acompte = new Mapping__c(Name='acompt', ConvertedValue__c='0', PickValue__c='CLASSIQUE (SANS ACOMPTE)', Repository__c='acompte');
        insert acompte;
        Mapping__c case_typeMapping = new Mapping__c(Name='autreDemande', ConvertedValue__c='autreDemande', PickValue__c='Autre', Repository__c='case_typeMapping');
        insert case_typeMapping;
    }

    @isTest 
    static void test() {
        Test.startTest();

        MappingUtils.getCodeOrigine('STAND GM');
        MappingUtils.getOrigineVenteFromCall('SOURCE');
        MappingUtils.getCodeCredit('PROMO - 24M JPO');
        MappingUtils.getAcompteString('CLASSIQUE (SANS ACOMPTE)');
        MappingUtils.getCaseRecordTypeFromType('Autre');

        Test.stopTest();
    }
}