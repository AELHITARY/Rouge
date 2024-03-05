//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_EntityVersion 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 06/03/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_EntityVersion {

    /**
    * @description Méthode exécutant les règles de validation pour les versions d'entité
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        List<EntityVersion__c> checkDates = new List<EntityVersion__c>();

        for (EntityVersion__c newEntityVersion : (List<EntityVersion__c>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR020_EntityVersion.applyValidationRules', newEntityVersion.id)) {
            
                if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore) {
                    checkDates.add(newEntityVersion);
                }
            }
        }

        // Vérification 
        if (!checkDates.isEmpty()) {
            checkValidationDate(checkDates);
        }
    }
    
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les versions d'entités
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
            
        Map<Id, EntityVersion__c>  oldEntityVersions = (Map<Id, EntityVersion__c>)Trigger.oldMap;
        Map<EntityVersion__c, String> entitiesVerMap = new Map<EntityVersion__c, String>();
        List<EntityVersion__c> entityVersionsToUp = new List<EntityVersion__c>();       
        
        for (EntityVersion__c newEntityVersion : (List<EntityVersion__c>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR020_EntityVersion.applyUpdateRules', newEntityVersion.id)) {
                EntityVersion__c oldEntityVersion = oldEntityVersions == null ? null : oldEntityVersions.get(newEntityVersion.id);
            
                // Vérifie pour mettre à jour les anciennes versions si endate = null
                if (Trigger.IsAfter && (Trigger.isInsert && newEntityVersion.startDate__c != null) 
                                        || (Trigger.isUpdate && oldEntityVersion.startDate__c != newEntityVersion.startDate__c && newEntityVersion.startDate__c != null )) {        
                    entitiesVerMap.put(newEntityVersion, newEntityVersion.entity__c);
                }
            }
        }
        
        // Récupération des ancienne versions
        if(!entitiesVerMap.isEmpty()) {
            for (EntityVersion__c oldEntityVersion : [SELECT Id, endDate__c, startDate__c, entity__c FROM EntityVersion__c WHERE entity__c IN :entitiesVerMap.values() 
                                                        AND endDate__c = null AND Id NOT IN :entitiesVerMap.keySet()])  {
                // Vérification de la date et mise à jour
                for (EntityVersion__c key : entitiesVerMap.keySet())  {
                    if(key.endDate__c == null && oldEntityVersion.entity__c == key.entity__c) {
                        System.debug('## key.startDate__c : ' + key.startDate__c);
                        System.debug('## key.endDate__c : ' + key.endDate__c);
                        System.debug('## oldEntityVersion.startDate__c : ' + oldEntityVersion.startDate__c);
                        System.debug('## oldEntityVersion.endDate__c : ' + oldEntityVersion.endDate__c);
                        oldEntityVersion.endDate__c = key.startDate__c.addDays(-1);
                        System.debug('## NEW oldEntityVersion.endDate__c : ' + oldEntityVersion.endDate__c);
                        entityVersionsToUp.add(oldEntityVersion);
                    }            
                }          
            }
            
            // Commit en base
            if(!entityVersionsToUp.isEmpty()) {
                update entityVersionsToUp;
            }
        }
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ asynchrone pour les versions d'entités
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyAsyncUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        // A - Initialisation des données intermédiaires 
        List<EntityVersion__c> newEntitiesVers = (List<EntityVersion__c>)Trigger.new;
        Map<Id, EntityVersion__c>  oldEntitiesVers = (Map<Id, EntityVersion__c>)Trigger.oldMap;
        Boolean geoEnabled = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false);
        List<EntityVersion__c> geoEntitiesVers = new List<EntityVersion__c>();

        if (Test.isRunningTest() || geoEnabled) {
            for (EntityVersion__c newEntityVers : newEntitiesVers) {
                if (!AlreadyUsed.isUsed('TR020_EntityVersion.applyAsyncUpdateRules', newEntityVers.id)) {
                    EntityVersion__c oldEntityVers = oldEntitiesVers == null ? null : oldEntitiesVers.get(newEntityVers.id); 

                    // Géocodage
                    Boolean adresseModifiee = Trigger.isInsert ? true : (newEntityVers.street__c != oldEntityVers.street__c 
                                                                        || newEntityVers.postalCode__c != oldEntityVers.postalCode__c 
                                                                        || newEntityVers.city__c != oldEntityVers.city__c 
                                                                        || newEntityVers.country__c != oldEntityVers.country__c
                                                                        || newEntityVers.geolocalisation__Latitude__s == null
                                                                        || newEntityVers.geolocalisation__Longitude__s == null);

                    if (adresseModifiee) {
                        geoEntitiesVers.add(newEntityVers);
                    }
                }
            }
        }

        // B - Application des règles de mise à jour asynchrone 
        if (geoEnabled && !geoEntitiesVers.isEmpty()) {
            GeoUtils.updateEntityVersions(geoEntitiesVers);
        }
    }    
    
    /**
    * @description Méthode vérifiant les dates des versions pour vérifier les conflits
    * @param entitiesVersion Liste des versions d'entité
    */
    private static void checkValidationDate(List<EntityVersion__c> entitiesVersion) {
        System.debug('### DEBUT TR020_EntityVersion.checkValidationDate');
        List<EntityVersion__c> listEntitiesVersion = new List<EntityVersion__c>();
        List<EntityVersion__c> entitiesVersionToUpdate = new List<EntityVersion__c>();
        Map<Id, List<EntityVersion__c>> mapEntitiesVerison = new Map<Id, List<EntityVersion__c>>();
        
        // Récupération des Ids des entités
        for(EntityVersion__c entityVersion : entitiesVersion) {
            if(mapEntitiesVerison.containsKey(entityVersion.entity__c) && mapEntitiesVerison.get(entityVersion.entity__c) != null) {
                List<EntityVersion__c> listEntitiesVersionToMap = mapEntitiesVerison.get(entityVersion.entity__c);
                listEntitiesVersionToMap.add(entityVersion);
                mapEntitiesVerison.put(entityVersion.entity__c, listEntitiesVersionToMap);
            } else {
                mapEntitiesVerison.put(entityVersion.entity__c, new List<EntityVersion__c> {entityVersion});
            }
        }        
        
        // Récupération des entités
        if (!mapEntitiesVerison.isEmpty()) {
            listEntitiesVersion = [SELECT Name, Id, isNotAvailable__c, entity__c, startDate__c, endDate__c FROM 
                                                      EntityVersion__c WHERE entity__c IN :mapEntitiesVerison.keySet() ORDER BY startDate__c];
        }
        
        // Vérification des dates
        for (EntityVersion__c newEntityVersion : entitiesVersion) {
            newEntityVersion.isNotAvailable__c = false;
            for(EntityVersion__c allEntityVersion : listEntitiesVersion) {
                if(newEntityVersion.entity__c == allEntityVersion.entity__c && newEntityVersion.Id != allEntityVersion.Id) {
                    System.debug('## --------------------------------------');
                    System.debug('## newEntityVersion.startDate__c : ' + newEntityVersion.startDate__c);
                    System.debug('## newEntityVersion.endDate__c : ' + newEntityVersion.endDate__c);
                    System.debug('## allEntityVersion.startDate__c : ' + allEntityVersion.startDate__c);
                    System.debug('## allEntityVersion.endDate__c : ' + allEntityVersion.endDate__c);
                    
                    if((newEntityVersion.startDate__c < allEntityVersion.startDate__c && (newEntityVersion.endDate__c < allEntityVersion.startDate__c ) ) 
                       || (newEntityVersion.startDate__c > allEntityVersion.endDate__c && (newEntityVersion.endDate__c >= allEntityVersion.endDate__c || newEntityVersion.endDate__c == null))
                       || (newEntityVersion.startDate__c > allEntityVersion.startDate__c && newEntityVersion.endDate__c == null && allEntityVersion.endDate__c == null)) {
                        //entityVersion.isNotAvailable__c = false;
                    } else {
                        System.debug('## isNotAvailable');
                        newEntityVersion.isNotAvailable__c = true;
                        //entitiesVersionToUpdate.add(entityVersion);
                   }
                }
            }
        }
        
        //update entitiesVersionToUpdate;
        System.debug('### FIN TR020_EntityVersion.checkValidationDate');
    }
}