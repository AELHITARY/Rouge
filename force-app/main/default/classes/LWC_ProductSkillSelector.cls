//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_ProductSkillSelector
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 16/12/2019
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_ProductSkillSelector {

    /**
    * @description Récupération de la liste des compétences du produit
    * @param productId Id du produit
    * @return Liste des lignes de compétences avec pré-sélection si le produit à la compétence
    */
    @AuraEnabled(Cacheable = true)
    public static List<SkillResult> getSkills(String productId){
        system.debug('### DEBUT LWC_ProductSkillSelector.getSkills'); 
        List<SkillResult> result = new List<SkillResult>();
        Map<String, ProductSkill__c> skillsProdList = new Map<String, ProductSkill__c>();
        system.debug('## productId: '+productId); 

        // Récupération des skills pour le produit
        for(ProductSkill__c prodSkill : [SELECT Id, skill__c, product__c, skillLevel__c FROM ProductSkill__c WHERE product__c = :productId]) {
            skillsProdList.put(prodSkill.skill__c, prodSkill);
        }         
        // Récupération des compétences
        for(SKill sk : [SELECT Id, MasterLabel FROM Skill ORDER BY MasterLabel]) {
            Decimal skillLevel = null;
            if(!skillsProdList.isEmpty() && skillsProdList.get(sk.Id) != null) {
                skillLevel = skillsProdList.get(sk.Id).skillLevel__c;
            }
            result.add(new SkillResult(sk.Id, sk.MasterLabel, skillLevel));
        }
        system.debug('## result: '+result); 
        system.debug('### FIN LWC_ProductSkillSelector.getSkills'); 
        return result;
    }

    /**
    * @description Fonction principal de création des compétences de produit
    * @param productId Id du produit
    * @param skills Liste des compétences définies par l'utilisateur
    * @return OK si création sinon null
    */
    @AuraEnabled
    public static String createProductSkillsRecord(String productId, List<Map<String, String>> skills){
        system.debug('### DEBUT LWC_ProductSkillSelector.createProductSkillsRecord'); 
        system.debug('## productId: '+productId); 
        system.debug('## skills: '+skills); 
        Map<String, ProductSkill__c> skillsProdList = new Map<String, ProductSkill__c>();
        List<ProductSkill__c> prodSkillToInsert = new List<ProductSkill__c>();
        Set<ProductSkill__c> prodSkillToDelete = new Set<ProductSkill__c>();

        // Sauvegarde transaction
        Savepoint sp = Database.setSavepoint();

        try {
            if(String.isNotBlank(productId) && !skills.isEmpty()) {
                // Récupération des skills pour le produit
                for(ProductSkill__c prodSkill : [SELECT Id, skill__c, product__c, skillLevel__c FROM ProductSkill__c WHERE product__c = :productId]) {
                    skillsProdList.put(prodSkill.skill__c, prodSkill);
                    prodSkillToDelete.add(prodSkill);
                }    

                // Boucle sur les skills pour création des records
                for(Map<String,String> skill : skills) {
                    String psId = (skillsProdList.containsKey(skill.get('id'))) ? skillsProdList.get(skill.get('id')).Id : null;
                    ProductSkill__c prodSkill = new ProductSkill__c(Id = psId,
                                                                    product__c = productId, 
                                                                    skill__c = skill.get('id'), 
                                                                    skillLevel__c = Decimal.valueOf(skill.get('value')));
                    prodSkillToInsert.add(prodSkill);
                }
                prodSkillToDelete.removeAll(prodSkillToInsert);

                // Création
                system.debug('## prodSkillToInsert: '+prodSkillToInsert); 
                if(!prodSkillToInsert.isEmpty()) {
                    upsert prodSkillToInsert;
                }
                // Delete
                system.debug('## prodSkillToDelete: '+prodSkillToDelete); 
                if(!prodSkillToDelete.isEmpty()) {
                    List<ProductSkill__c> tempList = new List<ProductSkill__c>();
                    tempList.addAll(prodSkillToDelete);
                    delete tempList;
                }
            }        
            system.debug('### FIN LWC_ProductSkillSelector.createProductSkillsRecord'); 
            return 'OK';
        } catch(Exception e) {
            Database.rollback( sp ); // Rollback des modifications
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class SkillResult {
        private String id;
        private String name;
        private Decimal value;

        public SkillResult(
            String id,
            String name,
            Decimal value
        ) {
            this.id = id;
            this.name = name;
            this.value = value;
        }

        @AuraEnabled
        public String getId() {
            return id;
        }

        @AuraEnabled
        public String getName() {
            return name;
        }

        @AuraEnabled
        public Decimal getValue() {
            return value;
        }
    }
}