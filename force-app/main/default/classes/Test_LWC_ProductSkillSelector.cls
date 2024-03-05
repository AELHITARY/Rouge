//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_ProductSkillSelector
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/08/2020
//-- Version     : 1.0
//-- Description : Classe de tests pour LWC_ProductSkillSelector
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_LWC_ProductSkillSelector {

    @testSetup 
    static void setup() {        
        // Creation produits
        Product2 prod = Utils_Test.createProduct('Produit Test','FFFETT','Fenetre','PVC',50,50,true);
        // Récupération d'un skill (impossible de les créér depuis APEX)
        SKill sk = [SELECT Id FROM Skill LIMIT 1];        
        // Création d'un skill pour un produit        
        ProductSkill__c pSkill = new ProductSkill__c(product__c = prod.Id, skill__c = sk.Id, skillLevel__c = 2);
        insert pSkill;
    }

    @isTest 
    static void test() {

        // Récupération produit et skill
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        SKill sk = [SELECT Id FROM Skill LIMIT 1];        

        Test.startTest();

        // Test récupération
        LWC_ProductSkillSelector.getSkills(prod.Id);
        // Préparation création
        Map<String, String> skillsMap = new Map<String, String>();
        skillsMap.put('id',sk.Id);
        skillsMap.put('value','1');
        List<Map<String, String>> skillList = new List<Map<String, String>>();
        skillList.add(skillsMap);
        // Test création
        LWC_ProductSkillSelector.createProductSkillsRecord(prod.Id, skillList);

        Test.stopTest();
    }
}