//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_ContentVersion
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 01/09/2021
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_ContentVersion {
    
    /**
    * @description Méthode exécutant les différentes règles de validation pour les documents
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les documents
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_ContentVersion.applyUpdateRules');    
        List<ContentVersion> newContentVersions = (List<ContentVersion>)Trigger.new;
        Map<Id, ContentVersion> oldContentVersions = (Map<Id, ContentVersion>)Trigger.oldMap;

        if (!Trigger.isExecuting) {
            return;
        }
         
        Set<ID> produitIDs = new Set<ID>();
        List<ContentVersion> updatedContentVersions = new List<ContentVersion>();
        if (Trigger.isInsert || Trigger.isUpdate) {   

            // On récupère seulement les fichiers liés à des lignes de devis
            String qLineKeyPrefix = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c').getDescribe().getKeyPrefix();
            System.debug('## QLI Key Prefix: '+qLineKeyPrefix);

            // Recherche des ContentVersion à mettre à jour car référencant un produit 
            for (ContentVersion newContentVersion : newContentVersions)  {
                System.debug('## Id: '+newContentVersion.Id); 
                System.debug('## Title: '+newContentVersion.Title); 

                // On vérifie le titre de l'image et si image liée à une ligne de devis CPQ, on modifie la catégorie
                if(String.isNotBlank(newContentVersion.Title) && String.isNotBlank(newContentVersion.FileType) 
                    && (newContentVersion.FileType.toLowerCase()=='jpg' || newContentVersion.FileType.toLowerCase()=='png')) 
                {
                    List<String> values = newContentVersion.Title.split('-');
                    if( values != null && values.size() > 1 &&  values[1] != null && newContentVersion.Title.startsWith('QL-') ){
                        System.debug('## Ajout catégorie KBMax');
                        newContentVersion.category__c = 'KBMax'; // Ajoute la catégorie KBMax
                    }
                }

                // Gestion des documents liés à la phototèque
                if (newContentVersion.produit__c != null) {
                    produitIDs.add(newContentVersion.produit__c);
                    updatedContentVersions.add(newContentVersion);
                }
            }
                
            // Recherche des caractéristiques des produits 
            System.debug('## produitIDs: '+produitIDs); 
            if(!produitIDs.isEmpty()) {
                Map<Id, Product2> produits = new Map<Id, Product2>([SELECT id, modele__c, Family, matiere__c, sousFamille__c, sousMatiere__c FROM Product2 WHERE id IN : produitIDs]);
                for (ContentVersion updatedContentVersion : updatedContentVersions) {
                    Product2 produit = produits.get(updatedContentVersion.produit__c);
                    if (produit != null) {
                        updatedContentVersion.title = produit.modele__c;
                        if (String.isNotBlank(updatedContentVersion.tagCsv)) {
                            updatedContentVersion.tagCsv += ', ';
                        }
                        updatedContentVersion.tagCsv += produit.Family + ', ' + produit.matiere__c + ', ' + produit.sousFamille__c + ', ' + produit.sousMatiere__c;
                    }
                }
            }
        } 

        System.debug('### FIN TR020_ContentVersion.applyUpdateRules');              
    }
}