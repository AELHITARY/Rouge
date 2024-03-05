//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_GDPR_AdminExportDeDonnees
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/12/2018
//-- Version     : 1.0
//-- * 1.0 : RQM-73 : Initialisation
//-- --------------------------------------------------------------------------------- --
public with sharing class Ctrl_GDPR_AdminExportDeDonnees {  
    
    /**
    * @description Méthode retournant la liste des règles d'export défini par l'utilisateur
    * @return List<String> Liste des règles
    */
    @AuraEnabled
    public static List<referentielExportDonnesGDPR__c> getReglesExportationDeDonnees() {
        System.debug('### DEBUT getReglesExportationDeDonnees');
        List<referentielExportDonnesGDPR__c> metadatas = [SELECT Id, nomObjet__c, actif__c, champDeJointure__c, champsExclus__c, 
                                                          objetDeJointure__c, priorite__c
                                                          FROM referentielExportDonnesGDPR__c ORDER BY priorite__c ASC];
        System.debug('### FIN getReglesExportationDeDonnees');
        return metadatas;
    }
    
    /**
    * @description Méthode retournant la liste des noms API des objets Salesforce pouvant être exportés
    * @return List<String> Liste du nom API des objets
    */
    @AuraEnabled
    public static List<String> populatePickListObject() {
        System.debug('### DEBUT populatePickListObject');
        List<String> sObjectsName = new List<String>();
   		Set<String> objetAlreadyUsed = new Set<String>();
        
        // Récupère la liste des objets déjà utilisés dans les options
        /*for(referentielExportDonnesGDPR__c regle : getReglesExportationDeDonnees()) {
            if(String.isNotBlank(regle.nomObjet__c)) objetAlreadyUsed.add(regle.nomObjet__c);
        }*/
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().values()){
            Schema.DescribeSObjectResult objMetadata = objTyp.getDescribe(); // Récupère les infos de l'objet
            // Ajoute seulement les objets pouvant être récupérés par SOQL
            if(isObjectExportable(objMetadata) && !objetAlreadyUsed.contains(objMetadata.getName())) {
                sObjectsName.add(objMetadata.getName());
            }
        }   
        sObjectsName.sort(); // Trie
        System.debug('## sObjectsName: ' + sObjectsName);
        System.debug('## Taille: ' + sObjectsName.size());
        System.debug('### FIN populatePickListObject');
        return sObjectsName;
    }
    
    /**
    * @description Méthode retournant la liste des nom API des champs pour un objet
    * @param sObjectName Nom API de l'objet pour récupérer les champs
    * @return List<String> Liste du nom API des champs
    */
    @AuraEnabled
    public static List<String> populatePickListObjectField(String sObjectName) {
        System.debug('### DEBUT populatePickListObjectField');
        List<String> sObjectsFields = new List<String> ();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField> ();
        fieldMap = schemaMap.get(sObjectName).getDescribe().fields.getMap();
        for(String fieldName : fieldMap.keyset()) {
            sObjectsFields.add(fieldName); 
        }
        sObjectsFields.sort(); // Trie
        System.debug('## sObjectsFields: ' + sObjectsFields);
        System.debug('## Taille: ' + sObjectsFields.size());
        System.debug('### FIN populatePickListObjectField');
        return sObjectsFields;
    }
    
    /**
    * @description Méthode retournant la liste des noms API des objets de jointure d'un objet principal
    * @param sObjectName Nom API de l'objet pour récupérer les objets enfants
    * @return List<String> Liste du nom API des objets enfants
    */
    @AuraEnabled
    public static List<String> getObjectDepedencies(String sObjectName) {
        System.debug('### DEBUT getObjectDepedencies');
        System.debug('## sObjectName: ' + sObjectName);
        Set<String> sObjectsDepedencies = new Set<String> ();
        List<String> results = new List<String> ();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        for(Schema.SobjectField strFld: schemaMap.get(sObjectName).getDescribe().fields.getMap().Values()){
            if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE){
                for(Schema.sObjectType objType : strFld.getDescribe().getReferenceTo()) {
                	DescribeSObjectResult objMetadata = objType.getDescribe(); // Récupère les infos de l'objet
                    // Ajoute seulement les objets pouvant être récupérés par SOQL
                    if(isObjectExportable(objMetadata)) {
                        sObjectsDepedencies.add(objMetadata.getName());
                    }
                }
            }
        }
        results.addAll(sObjectsDepedencies);
        results.sort(); // Trie
        System.debug('### FIN getObjectDepedencies');
        return results;
    }
    
    /**
    * @description Méthode retournant la liste des noms API des champs de jointure pour une relation
    * @param objectParentName Nom API de l'objet pour récupérer les champs
    * @param objectChildName Nom API de l'objet pour récupérer les champs
    * @return List<String> Liste du nom API des champs de jointure
    */
    @AuraEnabled
    public static List<String> getObjectJointField(String objectParentName, String objectChildName) {
        System.debug('### DEBUT getObjectJointField');
        System.debug('## objectParentName: ' + objectParentName);
        System.debug('## objectChildName: ' + objectChildName);
        List<String> sObjectsChildField = new List<String>();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult objParent = schemaMap.get(objectParentName).getDescribe();
        // Parcours la liste des objets enfants
        for (Schema.ChildRelationship cr: objParent.getChildRelationships()) {
            if(String.valueOf(cr.getChildSObject()) == objectChildName) { 
                // Ajoute les champs de jointure seulement si filtrable
                System.debug('====child object==='+cr.getChildSObject());
                System.debug('====child field==='+cr.getField());
                Schema.DescribeFieldResult field = cr.getField().getDescribe();
                if(!field.isDeprecatedAndHidden() && field.isFilterable()) {
                    sObjectsChildField.add(String.valueOf(cr.getField()));
                }
            }
        }
        sObjectsChildField.sort(); // Trie
        System.debug('## sObjectsChildField: ' + sObjectsChildField);
        System.debug('## Taille: ' + sObjectsChildField.size());
        System.debug('### FIN getObjectJointField');
        return sObjectsChildField;
    }    
    
    /**
    * @description Méthode permettant de créer une règle d'exportation
	* @param objetDeJointure Nom API de l'objet de jointure
	* @param nomObjet Nom API de l'objet
	* @param priorite Priorité de l'export
	* @param actif Règle active ou non
	* @param champsExclus Nom API des champs à exclure
	* @param champDeJointure Nom API des champs de jointure
    * @return referentielExportDonnesGDPR__c Objet contenant les informations de la règle
    */
    @AuraEnabled
    public static void createCustomMetadata(String objetDeJointure, String nomObjet, Decimal priorite, 
                                            Boolean actif, String champsExclus, String champDeJointure) 
    {
        System.debug('### DEBUT createCustomMetadata');
        System.debug('## Objet: '+nomObjet);
        System.debug('## Objet de jointure: '+objetDeJointure);
        System.debug('## Champ de jointure: '+champDeJointure);
        try{ 
            // Vérification si règle existante pour le même objet ou relation parent/enfant
            List<referentielExportDonnesGDPR__c> regleList = Ctrl_GDPR_AdminExportDeDonnees.getReglesExportationDeDonnees();
            if(!regleList.isEmpty()) {
                for(referentielExportDonnesGDPR__c regle : regleList) {
                    if(nomObjet == regle.nomObjet__c && 
                        (String.isBlank(objetDeJointure) || (objetDeJointure == regle.objetDeJointure__c && regle.champDeJointure__c.containsIgnoreCase(champDeJointure)))) {
                        System.debug('## Doublon existant');
                        throw new KubeException('Doublon existant. Une règle d\'export existe déjà pour cet objet et/ou cette relation');
                    }
                }
            }
            // Priorité toujours supérieur au nombre de lignes
            if(priorite <= regleList.size() || priorite > regleList.size())
                priorite = regleList.size() + 1;
            // Création de la règle d'export
            referentielExportDonnesGDPR__c meta = new referentielExportDonnesGDPR__c();
            meta.nomObjet__c = nomObjet;
            meta.champsExclus__c = champsExclus;
            meta.objetDeJointure__c = objetDeJointure;
            meta.champDeJointure__c = champDeJointure;
            meta.actif__c = actif;
            meta.priorite__c = priorite;
            System.debug('### FIN createCustomMetadata');
            insert meta;
        }catch(exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description Méthode permettant de récuperer les infos d'une règle d'exportation    
    * @param metadataId Id de la règle
    * @return referentielExportDonnesGDPR__c Objet contenant les informations de la règle
    */
    @AuraEnabled
    public static referentielExportDonnesGDPR__c getMetadataById(Id metadataId) {        
        referentielExportDonnesGDPR__c customMetadata = [SELECT Id, nomObjet__c, actif__c, champDeJointure__c, champsExclus__c, 
                                                         objetDeJointure__c, priorite__c
                                                         FROM referentielExportDonnesGDPR__c WHERE Id = :metadataId LIMIT 1];
        return customMetadata;
    }
    
    /**
    * @description Méthode permettant de suppimer une règle d'exportation    
    * @param metadataId Id de la règle
    * @return Boolean True si la règle est supprimée
    */
    @AuraEnabled
    public static Boolean deleteMetadataById(String metadataId) {
        System.debug('### DEBUT deleteMetadataById');
        System.debug('## Rule Id: '+metadataId);
        delete [SELECT Id FROM referentielExportDonnesGDPR__c WHERE id=:metadataId];
        System.debug('### FIN deleteMetadataById');
        return true;
    }
    
    /**
    * @description Méthode permettant de modifier une règle d'exportation
    * @param metadataId Id de la règle
	* @param objetDeJointure Nom API de l'objet de jointure
	* @param nomObjet Nom API de l'objet
	* @param priorite Priorité de l'export
	* @param actif Règle active ou non
	* @param champsExclus Nom API des champs à exclure
	* @param champDeJointure Nom API des champs de jointure
    * @return referentielExportDonnesGDPR__c Objet contenant les informations de la règle
    */
    @AuraEnabled
    public static referentielExportDonnesGDPR__c modifyMetadataById(Id metadataId, String objetDeJointure, String nomObjet, Decimal priorite, 
                                                                    Boolean actif, String champsExclus, String champDeJointure) 
    {        
        System.debug('### DEBUT modifyMetadataById');
        System.debug('## Rule Id: '+metadataId);
        referentielExportDonnesGDPR__c customMetadata = new referentielExportDonnesGDPR__c();

        try{ 
            // Vérification si règle existante pour le même objet ou relation parent/enfant
            List<referentielExportDonnesGDPR__c> regleList = Ctrl_GDPR_AdminExportDeDonnees.getReglesExportationDeDonnees();
            if(!regleList.isEmpty()) {
                for(referentielExportDonnesGDPR__c regle : regleList) {
                    if(metadataId != regle.Id && nomObjet == regle.nomObjet__c && 
                        (String.isBlank(objetDeJointure) || (objetDeJointure == regle.objetDeJointure__c && regle.champDeJointure__c.containsIgnoreCase(champDeJointure)))) {
                        System.debug('## Doublon existant');
                        throw new KubeException('Doublon existant. Une règle d\'export existe déjà pour cet objet et/ou cette relation');
                    }
                }
            }
            // Priorité toujours supérieur au nombre de lignes
            if(priorite > regleList.size())
                priorite = regleList.size() + 1;
            // Modification de la règle d'export
    		customMetadata.Id = metadataId;
    		customMetadata.nomObjet__c = nomObjet;
            customMetadata.champsExclus__c = champsExclus;
            customMetadata.objetDeJointure__c = objetDeJointure;
            customMetadata.champDeJointure__c = champDeJointure;
            customMetadata.actif__c = actif;
            customMetadata.priorite__c = priorite;
            upsert customMetadata;
            System.debug('### FIN modifyMetadataById');
        }catch(exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return customMetadata;
    }
    
    @AuraEnabled
    public static List<Map<String, List<String>>> getObjectStructure(String sObjectName) {
        System.debug('sObjectName : '+sObjectName);
        Map<String,Map<String,String>> sObjectRelationsMap = new Map<String,Map<String,String>>(); // Liste de tous les objets avec leur relations
        Boolean loopToAccount = true;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        List<String> sObjectAlreadyFoundList = new List<String>(); // Liste d'objets déjà répertoriés par les itérations précédentes
        List<String> sObjectToCheckList = new List<String>(); // Liste d'objets à répertorier sur cette itération
        sObjectToCheckList.add('Account');
        Integer nbIterations = 0;
        
        // A - Récupération des objets de référence de l'objet de départ. Récupération des références des objets référence par itération jusqu'à atteindre l'objet "Account" 
        while(loopToAccount) { // Boucler sur les objets de référence jusqu'à trouver "Account"
            nbIterations++;
            System.debug('ITERATION '+nbIterations);
            List<String> sObjectList = new List<String>(); // Nouvelle itération d'objets à remplir
            for(String objectToCheck :  sObjectToCheckList){ // Boucler sur la dernière itération d'objets référence
                Boolean isAlreadyFoundObject = false;
                for(String obj :  sObjectAlreadyFoundList){ // Si l'objet a déjà été analysé, on passe au suivant
                    if(objectToCheck == obj) isAlreadyFoundObject = true;
                }
                if(!isAlreadyFoundObject){ // Sinon, on récupère toutes ces relations enfants et on le rajoute dans la liste des objets analysés
                    Map<String, String> sObjectRelations = new Map<String, String>();
                    sObjectAlreadyFoundList.add(objectToCheck);
                    Schema.DescribeSObjectResult fieldMap = schemaMap.get(objectToCheck).getDescribe();
                    sObjectRelations.put('sObjectName',objectToCheck);
                    sObjectRelations.put('nbIterations',String.valueOf(nbIterations));
                    for (Schema.ChildRelationship cr: fieldMap.getChildRelationships()) { // Boucle sur les champs relationnels
                        sObjectRelations.put(String.valueOf(cr.getChildSObject()) + '-' + String.valueOf(cr.getField()),String.valueOf(cr.getChildSObject())); // Les relations de cet objet sont sauvegardées
                        if(String.valueOf(cr.getChildSObject()) != 'User') sObjectList.add(String.valueOf(cr.getChildSObject())); // La prochaine itération est alimentée avec les nouveaux objets relationnels
                        if(String.valueOf(cr.getChildSObject()) == sObjectName) loopToAccount = false; // Si "Account" est atteint on ne réitère plus
                        if(String.valueOf(cr.getChildSObject()) == sObjectName) {
                            System.debug('END 1');
                            System.debug('====child object==='+String.valueOf(cr.getChildSObject()));
                            System.debug('====child field==='+String.valueOf(cr.getField()));
                            System.debug('objectToCheck : '+objectToCheck);
                        }
                    }
                    sObjectRelationsMap.put(objectToCheck, sObjectRelations);
                }
            }
            sObjectToCheckList = sObjectList; // La nouvelle liste d'objet est pleine, les valeurs sont transférées pour que les relations enfants puissent être analysées
            System.debug('sObjectToCheckList : '+sObjectToCheckList);
        }
        
        Integer totalIteration = nbIterations;
        System.debug('******** sObjectRelationsMap : '+sObjectRelationsMap);
        
        // B - Tri des relations pour trouver le chemin le plus rapide de l'objet de départ jusqu'à "Account"
        List<Map<String, List<String>>> finalStructure = new List<Map<String, List<String>>>();
        String objectToLink = sObjectName;
        List<String> sObjectListToLink = new List<String>();
        Boolean loopToEnd = true;
        nbIterations = 0;
        while(loopToEnd) {
            nbIterations++;
            System.debug('ITERATION '+nbIterations);
            System.debug('objectToLink : '+objectToLink);
            List<String> objectsLinked = new List<String>();
            for(String objectMapKey : sObjectRelationsMap.keySet()){
                Map<String,String> objectMap = new Map<String,String>();
                List<String> linkedFields = new List<String>();
                objectMap = sObjectRelationsMap.get(objectMapKey);
                String parentObject = null;
                if(objectMap.get('nbIterations') == String.valueOf(totalIteration+1-nbIterations)){
                    for(String objectField : objectMap.keySet()){
                        System.debug('objectField : '+objectField);
                        if(objectMap.get(objectField) == objectToLink){
                            List<String> fieldName = objectField.split('-');
                            System.debug('fieldName : '+fieldName);
                            if(fieldName.size() > 1) {
                                linkedFields.add(fieldName[1]);
                                parentObject = objectMap.get('sObjectName');
                                objectsLinked.add(parentObject);
                                if(parentObject == 'Account') loopToEnd = false;
                            }
                        }
                    }
                    List<String> parentObjectList = new List<String>();
                    List<String> childObjectList = new List<String>();
                    parentObjectList.add(parentObject);
                    childObjectList.add(objectToLink);
                    if(!linkedFields.isEmpty()){
                        Map<String, List<String>> objectStructure = new Map<String, List<String>>();
                        objectStructure.put('sObjectName', childObjectList);
                        objectStructure.put('parentName', parentObjectList);
                        objectStructure.put('sObjectRelationFields', linkedFields);
                        System.debug('## OBJECT : '+objectToLink);
                        System.debug('## OBJECT RELATIONS : '+linkedFields+ ' -> ' +parentObjectList);
                        finalStructure.add(objectStructure);
                    }
                }
            }
            if(!objectsLinked.isEmpty())
                objectToLink = objectsLinked[0];
            if(nbIterations == 5)
                loopToEnd = false;
        }
        System.debug('finalStructure : '+finalStructure);
        return finalStructure;
    }
    
    /**
    * @description Méthode retournant true si l'objet peut être exporté et si une règle peut être créée
    * @param objMetadata Objet metadata de l'objet à vérifier
    * @return Boolean True si l'objet est exportable
    */
    private static Boolean isObjectExportable(Schema.DescribeSObjectResult objMetadata) {
        return (objMetadata.isQueryable() && !objMetadata.isCustomSetting() 
                && !objMetadata.getName().containsIgnoreCase('__Tag') && !objMetadata.getName().containsIgnoreCase('__Share'));
    }
}