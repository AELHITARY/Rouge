//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : GeoUtils
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 12/05/2021
//-- Version     : 1.10
//-- * 1.10 - Optimisation calcul de la geolocalisation
//-- * 1.9 - RQM-52 : Correctif sur la précision des adresses retournées par DQE
//-- * 1.8 - Correctif sur vérification secteur pour les imports
//-- * 1.7 - Correctif sur récupération meilleur résultat DQE
//-- --------------------------------------------------------------------------------- --
public without sharing class GeoUtils {
    private static final Boolean COPYADDRESS       = PropertiesUtils.getBooleanValue('dqe.adresse.copyAddress', true);
    private static final Boolean GEOENABLED        = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false);
    private static final Boolean GOOGLEGEOENABLED  = PropertiesUtils.getBooleanValue('google.geocoder.enabled', false);

    /**
    * @description Récupération Latitude/Longitude pour les comptes
    * @param accounts Liste des comptes
    */
    public static void updateAccounts(List<Account> accounts) {
        updateAccounts((new Map<Id, Account>(accounts)).keySet());
    }

    /**
    * @description Récupération Latitude/Longitude pour les comptes
    * @param accountIds Set des ID des comptes
    */
    public static void updateAccounts(Set<Id> accountIds) {
        Integer availableCallCount = Math.min(Limits.getLimitCallouts(), Limits.getLimitFutureCalls()) // Nombre max possible d'appels (out et/ou future)
                                - Math.max(Limits.getCallouts(), Limits.getFutureCalls()); // Nombre actuel d'appels (out et/ou future)

        if (availableCallCount <= 0) {
            return;
        }

        Set<Id> smallList = getRecordsToProcess(accountIds, availableCallCount);        
        if(!smallList.isEmpty() && !System.isFuture()) {
            calcAccountCoordinates(smallList);
        }
    }

    /**
    * @description Récupération Latitude/Longitude pour les chantiers
    * @param chantiers Liste des chantiers
    */
    public static void updateChantiers(List<Chantier__c> chantiers) {
        updateChantiers((new Map<Id, Chantier__c>(chantiers)).keySet());
    }

    /**
    * @description Récupération Latitude/Longitude pour les chantiers
    * @param chantierIds Set des ID des chantiers
    */
    public static void updateChantiers(Set<Id> chantierIds) {
        Integer availableCallCount = Math.min(Limits.getLimitCallouts(), Limits.getLimitFutureCalls()) // Nombre max possible d'appels (out et/ou future)
                                - Math.max(Limits.getCallouts(), Limits.getFutureCalls()); // Nombre actuel d'appels (out et/ou future)

        if (availableCallCount <= 0) {
            return;
        }

        Set<Id> smallList = getRecordsToProcess(chantierIds, availableCallCount);    
        if(!smallList.isEmpty() && !System.isFuture()) {
            calcChantierCoordinates(smallList);
        }
    }

    /**
    * @description Récupération Latitude/Longitude pour les utilisateurs
    * @param users Liste des utilisateurs
    */
    public static void updateUsers(List<User> users) {
        updateUsers((new Map<Id, User>(users)).keySet());
    }

    /**
    * @description Récupération Latitude/Longitude pour les utilisateurs
    * @param userIds Set des ID des utilisateurs
    */
    public static void updateUsers(Set<Id> userIds) {
        Integer availableCallCount = Math.min(Limits.getLimitCallouts(), Limits.getLimitFutureCalls()) // Nombre max possible d'appels (out et/ou future)
                                - Math.max(Limits.getCallouts(), Limits.getFutureCalls()); // Nombre actuel d'appels (out et/ou future)

        if (availableCallCount <= 0) {
            return;
        }

        Set<Id> smallList = getRecordsToProcess(userIds, availableCallCount); 
        if(!smallList.isEmpty() && !System.isFuture()) {
            calcUserCoordinates(smallList);
        }
    }

    /**
    * @description Récupération Latitude/Longitude pour les événements
    * @param events Liste des événements
    */
    public static void updateEvents(List<Event> events) {
        updateEvents((new Map<Id, Event>(events)).keySet());
    }

    /**
    * @description Récupération Latitude/Longitude pour les événements
    * @param eventIds Set des ID des événements
    */
    public static void updateEvents(Set<Id> eventIds) {
        Integer availableCallCount = Math.min(Limits.getLimitCallouts(), Limits.getLimitFutureCalls()) // Nombre max possible d'appels (out et/ou future)
                                - Math.max(Limits.getCallouts(), Limits.getFutureCalls()); // Nombre actuel d'appels (out et/ou future)

        if (availableCallCount <= 0) {
            return;
        }

        Set<Id> smallList = getRecordsToProcess(eventIds, availableCallCount); 
        if(!smallList.isEmpty() && !System.isFuture()) {
            calcEventCoordinates(smallList);
        }
    }

    /**
    * @description Récupération Latitude/Longitude pour les versions d'entités
    * @param entityVersion Liste des versions d'entités
    */
    public static void updateEntityVersions(List<EntityVersion__c> entityVersion) {
        updateEntityVersions((new Map<Id, EntityVersion__c>(entityVersion)).keySet());
    }

    /**
    * @description Récupération Latitude/Longitude pour les versions d'entités
    * @param entityVersionIds Set des ID des versions d'entités
    */
    public static void updateEntityVersions(Set<Id> entityVersionIds) {
        Integer availableCallCount = Math.min(Limits.getLimitCallouts(), Limits.getLimitFutureCalls()) // Nombre max possible d'appels (out et/ou future)
                                - Math.max(Limits.getCallouts(), Limits.getFutureCalls()); // Nombre actuel d'appels (out et/ou future)

        if (availableCallCount <= 0) {
            return;
        }

        Set<Id> smallList = getRecordsToProcess(entityVersionIds, availableCallCount); 
        if(!smallList.isEmpty() && !System.isFuture()) {
            calcEntityVersionCoordinates(smallList);
        }
    }

    /**
    * @description Récupération Latitude/Longitude pour les collaborateurs
    * @param collaborators Liste des collaborateurs
    */
    public static void updateCollaborators(List<Collaborator__c> collaborators) {
        updateCollaborators((new Map<Id, Collaborator__c>(collaborators)).keySet());
    }

    /**
    * @description Récupération Latitude/Longitude pour les collaborateurs
    * @param collaboratorIds Set des ID des collaborateurs
    */
    public static void updateCollaborators(Set<Id> collaboratorIds) {
        Integer availableCallCount = Math.min(Limits.getLimitCallouts(), Limits.getLimitFutureCalls()) // Nombre max possible d'appels (out et/ou future)
                                - Math.max(Limits.getCallouts(), Limits.getFutureCalls()); // Nombre actuel d'appels (out et/ou future)

        if (availableCallCount <= 0) {
            return;
        }

        Set<Id> smallList = getRecordsToProcess(collaboratorIds, availableCallCount); 
        if(!smallList.isEmpty() && !System.isFuture()) {
            calcCollaboratorCoordinates(smallList);
        }
    }

    /**
    * @description Retourn les enregistrement à traiter en fonction des limites Salesforce et et en évitant de les traiter plusieurs fois
    * @param records Liste des Ids des enregistrements
    * @param availableCallCount Limit disponible
    */
    private static Set<Id> getRecordsToProcess(Set<Id> records, Integer availableCallCount) {        
        Set<Id> result = new Set<Id>();

        for (Id recordId : records){
            if (!AlreadyUsed.isUsed('GeoUtils', recordId)) {
                result.add(recordId);
                if (result.size() >= availableCallCount) {
                    break;
                }
            }
        }
        return result;
    }

    /**
    * @description Geocodage adresse pour les comptes avec récupération code IRIS / Méthode asynchrone
    * @param accountIds Liste des ID des comptes
    */
    @future(callout=true)
    private static void calcAccountCoordinates(Set<Id> accountIds) {        
        System.debug('### DEBUT GeoUtils.calcAccountCoordinates');
        System.debug('## DQE enabled: '+GEOENABLED);
        System.debug('## accountIds: '+accountIds);

        List<Account> accountToUpdate = new List<Account>();
        Set<String> valuesList = new Set<String>();
        List<Sectorisation__c> sectList = new List<Sectorisation__c>();
        
        List<Account> accounts = [SELECT id, AccountNumber, isPersonAccount, rue__c, codePostal__c, ville__c,
                                        personMailingStreet, personMailingPostalCode, personMailingCity, personMailingCountry,
                                        billingStreet, billingPostalCode, billingCity, billingCountry, methodeGeocodage__c, iris__c, codeCommune__c,
                                        Localisation__Latitude__s, Localisation__Longitude__s
                                    FROM Account
                                    WHERE id IN :accountIds];
        // Récupération sectorisations par code postal, code commune et iris des enregistrements
        for (Account account : accounts) {
            if(String.isNotBlank(account.iris__c)) {
                valuesList.add(account.iris__c);
            }
            if(String.isNotBlank(account.codeCommune__c)) {
                valuesList.add(account.codeCommune__c);
            }
            if(String.isNotBlank(account.codePostal__c)) {
                valuesList.add(account.codePostal__c);
            }
        }
        if(!valuesList.isEmpty()) {
            sectList = [SELECT Id, iris__c, codeCommuneAdm__c, codePostalAdm__c FROM Sectorisation__c 
                            WHERE iris__c IN :valuesList OR codePostalAdm__c IN :valuesList OR codeCommuneAdm__c IN :valuesList];
        }
        System.debug('## Sectorisation: '+sectList);

        for (Account account : accounts) {
            //DQE 
            if(GEOENABLED){
                account.methodeGeocodage__c = 'Batch';
                Utils_DQE.GeocodeResultType checkAdress = new Utils_DQE.GeocodeResultType();
                checkAdress = geolocationAccountDQE(account, account.isPersonAccount, sectList);
                if(checkAdress != null) {
                    accountToUpdate.add(account);
                } else {
                    account.Localisation__Latitude__s = null;
                    account.Localisation__Longitude__s = null;
                    accountToUpdate.add(account);
                }
            }
        }

        System.debug('## Account To Update: '+accountToUpdate);
        if (!accountToUpdate.isEmpty()) {
            Database.update(accountToUpdate, false);
        }     
        System.debug('### FIN GeoUtils.calcAccountCoordinates');
    }

    /**
    * @description Geocodage adresse pour les chantiers avec récupération code IRIS / Méthode asynchrone
    * @param chantierIds Liste des ID des chantiers
    */
    @future(callout=true)
    private static void calcChantierCoordinates(Set<Id> chantierIds) {  
        System.debug('### DEBUT GeoUtils.calcChantierCoordinates');
        System.debug('## DQE enabled: '+GEOENABLED);
        System.debug('## chantierIds: '+chantierIds);

        List<Chantier__c> chantierToUpdate = new List<Chantier__c>();
        Set<String> valuesList = new Set<String>();
        List<Sectorisation__c> sectList = new List<Sectorisation__c>();

        List<Chantier__c> chantiers = [SELECT id, numeroChantier__c, rue__c, codePostal__c, ville__c, pays__c, methodeGeocodage__c,
                                        complementAdresse__c, codeCommune__c, iris__c, Localisation__Latitude__s, Localisation__Longitude__s
                                        FROM Chantier__c
                                        WHERE id IN :chantierIds];
        // Récupération sectorisations par code postal, code commune et iris des enregistrements
        for (Chantier__c chantier : chantiers) {
            if(String.isNotBlank(chantier.iris__c)) {
                valuesList.add(chantier.iris__c);
            }
            if(String.isNotBlank(chantier.codeCommune__c)) {
                valuesList.add(chantier.codeCommune__c);
            }
            if(String.isNotBlank(chantier.codePostal__c)) {
                valuesList.add(chantier.codePostal__c);
            }
        }
        if(!valuesList.isEmpty()) {
            sectList = [SELECT Id, iris__c, codeCommuneAdm__c, codePostalAdm__c FROM Sectorisation__c 
                            WHERE iris__c IN :valuesList OR codePostalAdm__c IN :valuesList OR codeCommuneAdm__c IN :valuesList];
        }
        System.debug('## Sectorisation: '+sectList);

        for (Chantier__c chantier : chantiers) {
            //DQE 
            if(GEOENABLED){
                chantier.methodeGeocodage__c = 'Batch';
                Utils_DQE.GeocodeResultType checkAdress = new Utils_DQE.GeocodeResultType();
                checkAdress = geolocationChantierDQE(chantier, sectList);
                if(checkAdress != null) {
                    chantierToUpdate.add(chantier);
                } else {
                    chantier.Localisation__Latitude__s = null;
                    chantier.Localisation__Longitude__s = null;
                    chantierToUpdate.add(chantier);
                }
            }
        }

        System.debug('## Chantier To Update: '+chantierToUpdate);
        if (!chantierToUpdate.isEmpty()) {
            Database.update(chantierToUpdate, false);
        }
        System.debug('### FIN GeoUtils.calcChantierCoordinates');
    }

    /**
    * @description Récupération Latitude/Longitude pour les utilisateurs / Méthode asynchrone
    * @param userIds Liste des ID des utilisateurs
    */
    @future(callout=true)
    private static void calcUserCoordinates(Set<Id> userIds) {
        System.debug('### DEBUT GeoUtils.calcUserCoordinates');
        System.debug('## Google enabled: '+GOOGLEGEOENABLED);
        System.debug('## userIds: '+userIds);
        // Traitement
        List<User> users = [SELECT id, rue__c, codePostal__c, ville__c, localisationLatitude__c, localisationLongitude__c FROM User WHERE Id IN :userIds];
        List<User> updatedUsers = new List<User>();
        // Appel au WebService de Google Maps
        if(GOOGLEGEOENABLED) {
            for (User user : users) {
                Utils_Cartographie.GoogleMapsJSONLatLng latlong = Utils_Cartographie.getGeoGoogleMaps(user.rue__c == null ? '' : user.rue__c, user.codePostal__c, user.ville__c);
                if (latlong != null) {
                    user.localisationLatitude__c = latlong.lat;
                    user.localisationLongitude__c = latlong.lng;
                    updatedUsers.add(user);
                }
            }
            // Mise à jour
            System.debug('## User To Update: '+updatedUsers);
            if (!updatedUsers.isEmpty()) {
                Database.update(updatedUsers, false);
            }
        }
        System.debug('### FIN GeoUtils.calcUserCoordinates');
    }

    /**
    * @description Récupération Latitude/Longitude pour les événements / Méthode asynchrone
    * @param eventIds Liste des ID des événements
    */
    @future(callout=true)
    private static void calcEventCoordinates(Set<Id> eventIds) {
        System.debug('### DEBUT GeoUtils.calcEventCoordinates');
        System.debug('## DQE enabled: '+GEOENABLED);
        System.debug('## Google enabled: '+GOOGLEGEOENABLED);
        System.debug('## eventIds: '+eventIds);

        // Traitement
        List<Event> events = [SELECT id, rue__c, codePostal__c, ville__c, Localisation__Latitude__s, Localisation__Longitude__s FROM Event WHERE Id IN :eventIds];
        List<Event> updateEvents = new List<Event>();

        // Appel au WebService de DQE
        if(GEOENABLED){
            for (Event rdv : events) {
                if(String.isNotBlank(rdv.codePostal__c)) {
                    Utils_DQE.GeocodeResultType bestResult=null;
                    List<Utils_DQE.GeocodeResultType> geoResults = Utils_DQE.DQEIrisRNVP('', rdv.codePostal__c, rdv.rue__c == null ? '' : rdv.rue__c, '', rdv.ville__c, 'FRA');
                    if(geoResults != null && !geoResults.isEmpty()){
                        // Récupération du résultat sans erreur, sinon récupération du premier
                        bestResult = defineBestLocalisation(geoResults, rdv.codePostal__c, rdv.ville__c);

                        // Récupération latitude/longitude
                        if (bestResult != null) {
                            Map<String, String> recordLoc = processRecordLocalisation(bestResult, rdv.rue__c, rdv.ville__c , rdv.codePostal__c);
                            if(recordLoc != null && String.isNotBlank(recordLoc.get('latitude')) && String.isNotBlank(recordLoc.get('longitude')) && recordLoc.get('longitude') != '0.00'){
                                rdv.Localisation__Latitude__s = Decimal.valueOf(recordLoc.get('latitude'));
                                rdv.Localisation__Longitude__s = Decimal.valueOf(recordLoc.get('longitude'));
                            } else {                    
                                rdv.Localisation__Latitude__s = null;
                                rdv.Localisation__Longitude__s = null;
                            }                        
                            updateEvents.add(rdv);
                        }
                    } else {
                        rdv.Localisation__Latitude__s = null;
                        rdv.Localisation__Longitude__s = null;  
                        updateEvents.add(rdv);
                    }
                } else {
                    rdv.Localisation__Latitude__s = null;
                    rdv.Localisation__Longitude__s = null;  
                    updateEvents.add(rdv);
                }
            }   
        }
        // Appel au WebService de Google Maps
        else if(GOOGLEGEOENABLED) {
            for (Event rdv : events) {
                Utils_Cartographie.GoogleMapsJSONLatLng latlong = Utils_Cartographie.getGeoGoogleMaps(rdv.rue__c == null ? '' : rdv.rue__c, rdv.codePostal__c, rdv.ville__c);
                if (latlong != null) {
                    rdv.Localisation__Latitude__s = latlong.lat;
                    rdv.Localisation__Longitude__s= latlong.lng;
                    System.debug('## Latitude: '+ rdv.Localisation__Latitude__s);
                    System.debug('## Longitude: '+ rdv.Localisation__Longitude__s);
                    updateEvents.add(rdv);
                }
            }
        }

        // Mise à jour
        System.debug('## Event To Update: '+updateEvents);
        if (!updateEvents.isEmpty()) {
            Database.update(updateEvents, false);
        }
        System.debug('### FIN GeoUtils.calcEventCoordinates');
    }

    /**
    * @description Geocodage adresse pour les versions d'entités / Méthode asynchrone
    * @param entityVersionIds Set des ID des versions d'entités
    */
    @future(callout=true)
    private static void calcEntityVersionCoordinates(Set<Id> entityVersionIds) {
        System.debug('### DEBUT GeoUtils.calcEntityVersionCoordinates');
        System.debug('## DQE enabled: '+GEOENABLED);
        System.debug('## entityVersionIds: '+entityVersionIds);
        List<EntityVersion__c> updateEntitiesVersion = new List<EntityVersion__c>();

        // Traitement
        if(GEOENABLED) {
            List<EntityVersion__c> entitiesVersion = [SELECT Id, street__c, postalCode__c, city__c, country__c, geolocalisation__Latitude__s, geolocalisation__Longitude__s 
                                    FROM EntityVersion__c WHERE Id IN :entityVersionIds];

            // Appel au WebService de DQE
            for (EntityVersion__c entityVer : entitiesVersion) {
                if(String.isNotBlank(entityVer.postalCode__c)) {
                    System.debug('## Entité: '+entityVer.Id);
                    System.debug('## Adresse: '+entityVer.street__c+' '+entityVer.postalCode__c+' '+entityVer.city__c+' '+entityVer.country__c);  

                    Utils_DQE.GeocodeResultType bestResult=null;    
                    String countryCode = '';     
                    // Init
                    if(String.isNotBlank(entityVer.country__c)) {
                        countryCode = GeoUtils.PAYS_VALEUR_MAP.get(entityVer.country__c);
                    } else {                    
                        countryCode = 'FRA';
                    }  
                    List<Utils_DQE.GeocodeResultType> geoResults = Utils_DQE.DQEIrisRNVP('', entityVer.postalCode__c, entityVer.street__c, '', entityVer.city__c, countryCode);
                    if(geoResults != null && !geoResults.isEmpty()) {
                        // Récupération du résultat sans erreur, sinon récupération du premier
                        bestResult = defineBestLocalisation(geoResults, entityVer.postalCode__c, entityVer.city__c);
                        System.debug('## Best Result: '+bestResult);

                        // Récupération adresse
                        if(COPYADDRESS) {
                            entityVer.street__c=bestResult.Adresse;
                            entityVer.postalCode__c=bestResult.CodePostal;
                            entityVer.city__c=bestResult.Localite;
                        }
                        entityVer.country__c=PAYS_CODE_MAP.get(bestResult.Pays);

                        // Récupération latitude/longitude
                        if (bestResult != null ) {
                            Map<String, String> recordLoc = processRecordLocalisation(bestResult, entityVer.street__c, entityVer.city__c , entityVer.postalCode__c);
                            if(recordLoc != null && String.isNotBlank(recordLoc.get('latitude')) && String.isNotBlank(recordLoc.get('longitude')) && recordLoc.get('longitude') != '0.00'){
                                entityVer.geolocalisation__Latitude__s = Decimal.valueOf(recordLoc.get('latitude'));
                                entityVer.geolocalisation__Longitude__s = Decimal.valueOf(recordLoc.get('longitude'));
                            } else {                    
                                entityVer.geolocalisation__Latitude__s = null;
                                entityVer.geolocalisation__Longitude__s = null;
                            }                        
                        }  
                        updateEntitiesVersion.add(entityVer);
                    } else {
                        entityVer.geolocalisation__Latitude__s = null;
                        entityVer.geolocalisation__Longitude__s = null;
                        updateEntitiesVersion.add(entityVer);
                    }
                } else {
                    entityVer.geolocalisation__Latitude__s = null;
                    entityVer.geolocalisation__Longitude__s = null;
                    updateEntitiesVersion.add(entityVer);
                }
            }   
        }

        // Mise à jour
        System.debug('## updateEntitiesVersion: '+ updateEntitiesVersion);
        if (!updateEntitiesVersion.isEmpty()) {
            Database.update(updateEntitiesVersion, false);
        }
        System.debug('### FIN GeoUtils.calcEntityVersionCoordinates');
    }

    /**
    * @description Geocodage adresse pour les collaborateurs / Méthode asynchrone
    * @param collaboratorIds Set des ID des collaborateurs
    */
    @future(callout=true)
    private static void calcCollaboratorCoordinates(Set<Id> collaboratorIds) {
        System.debug('### DEBUT GeoUtils.calcCollaboratorCoordinates');
        System.debug('## DQE enabled: '+GEOENABLED);
        System.debug('## collaboratorIds: '+collaboratorIds);
        List<Collaborator__c> updateCollaborator = new List<Collaborator__c>();

        // Traitement
        if(GEOENABLED) {
            List<Collaborator__c> collaborator = [SELECT Id, street__c, postalCode__c, city__c, country__c, localisation__Latitude__s, localisation__Longitude__s 
                                    FROM Collaborator__c WHERE Id IN :collaboratorIds];

            // Appel au WebService de DQE
            for (Collaborator__c collab : collaborator) {
                if(String.isNotBlank(collab.postalCode__c)) {
                    System.debug('## Entité: '+collab.Id);
                    System.debug('## Adresse: '+collab.street__c+' '+collab.postalCode__c+' '+collab.city__c+' '+collab.country__c);  

                    Utils_DQE.GeocodeResultType bestResult=null;    
                    String countryCode = '';     
                    // Init
                    if(String.isNotBlank(collab.country__c)) {
                        countryCode = GeoUtils.PAYS_VALEUR_MAP.get(collab.country__c);
                    } else {                    
                        countryCode = 'FRA';
                    }  
                    List<Utils_DQE.GeocodeResultType> geoResults = Utils_DQE.DQEIrisRNVP('', collab.postalCode__c, collab.street__c, '', collab.city__c, countryCode);
                    if(geoResults != null && !geoResults.isEmpty()) {
                        // Récupération du résultat sans erreur, sinon récupération du premier
                        bestResult = defineBestLocalisation(geoResults, collab.postalCode__c, collab.city__c);
                        System.debug('## Best Result: '+bestResult);

                        // Récupération adresse
                        if(COPYADDRESS) {
                            collab.street__c=bestResult.Adresse;
                            collab.postalCode__c=bestResult.CodePostal;
                            collab.city__c=bestResult.Localite;
                        }
                        collab.country__c=PAYS_CODE_MAP.get(bestResult.Pays);

                        // Récupération latitude/longitude
                        if (bestResult != null ) {
                            Map<String, String> recordLoc = processRecordLocalisation(bestResult, collab.street__c, collab.city__c , collab.postalCode__c);
                            if(recordLoc != null && String.isNotBlank(recordLoc.get('latitude')) && String.isNotBlank(recordLoc.get('longitude')) && recordLoc.get('longitude') != '0.00'){
                                collab.localisation__Latitude__s = Decimal.valueOf(recordLoc.get('latitude'));
                                collab.localisation__Longitude__s = Decimal.valueOf(recordLoc.get('longitude'));
                            } else {                    
                                collab.localisation__Latitude__s = null;
                                collab.localisation__Longitude__s = null;
                            }                        
                        }  
                        updateCollaborator.add(collab);
                    } else {
                        collab.localisation__Latitude__s = null;
                        collab.localisation__Longitude__s = null;
                        updateCollaborator.add(collab);
                    }
                } else {
                    collab.localisation__Latitude__s = null;
                    collab.localisation__Longitude__s = null;
                    updateCollaborator.add(collab);
                }
            }   
        }

        // Mise à jour
        System.debug('## updateCollaborator: '+ updateCollaborator);
        if (!updateCollaborator.isEmpty()) {
            Database.update(updateCollaborator, false);
        }
        System.debug('### FIN GeoUtils.calcCollaboratorCoordinates');
    }

    /**
    * @description Geocodage adresse DQE pour les enregistrements importés / Récupération code IRIS
    * @param importRecord Enregistrement importé
    */
    public static void geolocationImportRecord(Import__c importRecord) {
        System.debug('### DEBUT GeoUtils.geolocationImportRecord');
        Boolean horsZone = false;
        Utils_DQE.GeocodeResultType bestResult=null;

        if (GEOENABLED) {
            // Appel du géocodeur
            try{
                List<Utils_DQE.GeocodeResultType> geoResults = Utils_DQE.DQEIrisRNVP('', StringUtils.defaultIfEmpty(importRecord.codePostalCompte__c, importRecord.codePostalChantier__c),
                                                                                    StringUtils.defaultIfEmpty(importRecord.rueCompte__c, importRecord.rueChantier__c), '',
                                                                                    StringUtils.defaultIfEmpty(importRecord.villeCompte__c, importRecord.villeChantier__c),
                                                                                    'FRA');

                // Traitement du résultat
                if (geoResults != null && !geoResults.isEmpty()) {
                    // Récupération du résultat sans erreur, sinon récupération du premier
                    for(Utils_DQE.GeocodeResultType geo : geoResults) {
                        if(geo.DQECodeErreur=='0') {
                            bestResult = geo;
                        }
                    }    
                    if(bestResult==null) {
                        bestResult = geoResults[0];
                    }
                    if (importRecord.rueChantier__c == null) {
                        importRecord.rueChantier__c = bestResult.Adresse;
                    }
                    if (importRecord.codePostalChantier__c == null) {
                        importRecord.codePostalChantier__c = bestResult.CodePostal;
                    }
                    if (importRecord.villeChantier__c == null) {
                        importRecord.villeChantier__c = bestResult.Localite;
                    }
                    if (importRecord.rueCompte__c == null) {
                        importRecord.rueCompte__c = bestResult.Adresse;
                    }
                    if (importRecord.codePostalCompte__c == null) {
                        importRecord.codePostalCompte__c = bestResult.CodePostal;
                    }
                    if (importRecord.villeCompte__c == null) {
                        importRecord.villeCompte__c = bestResult.Localite;
                    }
                    if (importRecord.codeCommune__c == null) {
                        importRecord.codeCommune__c = bestResult.IDLocalite;
                    }
                    importRecord.adresseGeolocalisation__c = bestResult.Adresse+'\n'+bestResult.CodePostal+' '+bestResult.Localite+'\n'+PAYS_CODE_MAP.get(bestResult.Pays);
                    importRecord.methodeGeocodage__c = 'Manuel';

                    // Vérification IRIS retourné par DQE   
                    String codePostal=importRecord.codePostalCompte__c;
                    String insee=importRecord.codeCommune__c;              
                    importRecord.iris__c = calcultateIRIS(codePostal, insee, bestResult.iris, null);
                    // Vérification hors secteur
                    horsZone = checkHorsSecteur(importRecord);
                    if(horsZone) {
                        importRecord.integrable__c = false;
                        importRecord.messageException__c = Label.import_erreur_horssecteur_messageexception;
                        importRecord.classeException__c  = Label.import_erreur_horssecteur_classeexception;
                    }
                }
                System.debug('### FIN GeoUtils.geolocationImportRecord');
            } catch(Exception e){
                // JMU - 29/06/2017 : Hotfix dans le cas ou la geoloc time out (qd le reseau KpK est down par exemple)
                // A la place, il faut affecter le 1er iris associé au code postal et de l'adresse et appartenant à un magasin.
                // Pas de recherche par code commune car ce dernier est récupéré par DQE qui est indisponible
                if(e.getMessage()==Label.dqe_msg_errorsWSDQEAddress){
                    // Vérification du secteur de l'adresse
                    System.debug('## CP: '+importRecord.codePostalCompte__c);
                    List<Sectorisation__c> sectorisations = [SELECT Id, iris__c, libelleMagasin__c, libelleDepot__c
                                                                FROM Sectorisation__c 
                                                                WHERE codePostalAdm__c = :importRecord.codePostalCompte__c AND codeMagasin__c != '' LIMIT 1];
                    // Si pas de secteur ou hors zone, erreur
                    if(!sectorisations.isEmpty()) {
                        for(Sectorisation__c sector : sectorisations) {
                            if('HORS ZONE'.equalsIgnoreCase(sector.libelleMagasin__c) || 'ZONE BLANCHE'.equalsIgnoreCase(sector.libelleMagasin__c)) {
                                horsZone = true;
                            } else {
                                importRecord.iris__c=sector.iris__c;
                            }
                        }
                    } else {
                        horsZone = true;
                    }

                    if(horsZone) {
                        importRecord.integrable__c = false;
                        importRecord.messageException__c = System.label.import_erreur_horssecteur_messageexception;
                        importRecord.classeException__c  = System.label.import_erreur_horssecteur_classeexception;
                    }
                }
                else {
                    throw e;
                }
            }
        }
    }

    /**
    * @description Geocodage adresse DQE pour compte / Récupération code IRIS
    * @param account Compte à géocoder
    * @param isPersonAccount Vrai si c'est un compte personnel
    * @param sectorisations Liste des sectorisations à utiliser (null si optionnel)
    * @return Boolean Flag de validation
    */
    public static Utils_DQE.GeocodeResultType geolocationAccountDQE(Account account, Boolean isPersonAccount, List<Sectorisation__c> sectorisations){
        System.debug('### DEBUT GeoUtils.geolocationAccountDQE');
        Account dataAccount = account;
        Utils_DQE.GeocodeResultType bestResult=null;
        String accCodePostal = null;
        String accRue = null;
        String accVille = null;
        String accPays = null;
        if(isPersonAccount){
            accCodePostal = account.PersonMailingPostalCode;
            accRue = account.PersonMailingStreet;
            accVille = account.PersonMailingCity;
            accPays = PAYS_VALEUR_MAP.get(account.PersonMailingCountry);
        } else {
            accCodePostal = account.BillingPostalCode;
            accRue = account.BillingStreet;
            accVille = account.BillingCity;
            accPays = PAYS_VALEUR_MAP.get(account.BillingCountry);
        }
        Integer niveauErreurDQE = 999999;
        try {
            if(String.isNotBlank(accCodePostal)) {
                List<Utils_DQE.GeocodeResultType> geoResults = Utils_DQE.DQEIrisRNVP('', accCodePostal, accRue, '', accVille, accPays);
                if(geoResults != null && !geoResults.isEmpty()){
                    // 20/03/2018 - RQM-52 lot-1 - JMU
                    // Récupération du résultat avec le niveau d'incertitude le plus bas, sinon récupération du premier. 
                    // Si incertitude égale, comparaison de l'erreur code DQE la plus basse
                    /*for(Utils_DQE.GeocodeResultType geo : geoResults) {
                        if((niveauIncertitude > 1 || (niveauIncertitude == 1 && niveauErreurDQE > Integer.valueOf(geo.DQECodeErreur))) && 
                                    accCodePostal == geo.CodePostal && accVille == geo.Localite){
                            bestResult = geo;
                            niveauIncertitude = 1;
                            niveauErreurDQE = Integer.valueOf(geo.DQECodeErreur);
                        } else if((niveauIncertitude > 2 || (niveauIncertitude == 2 && niveauErreurDQE > Integer.valueOf(geo.DQECodeErreur))) && 
                                    accCodePostal == geo.CodePostal){
                            bestResult = geo;
                            niveauIncertitude = 2;
                            niveauErreurDQE = Integer.valueOf(geo.DQECodeErreur);
                        } else if((niveauIncertitude > 3 || (niveauIncertitude == 3 && niveauErreurDQE > Integer.valueOf(geo.DQECodeErreur))) && 
                                    accCodePostal.substring(0,2) == geo.CodePostal.substring(0,2)){
                            bestResult = geo;
                            niveauIncertitude = 3;
                            niveauErreurDQE = Integer.valueOf(geo.DQECodeErreur);
                        } else if(niveauIncertitude > 4 || (niveauIncertitude == 4 && niveauErreurDQE > Integer.valueOf(geo.DQECodeErreur))){
                            bestResult = geo;
                            niveauIncertitude = 4;
                            niveauErreurDQE = Integer.valueOf(geo.DQECodeErreur);
                        }
                    }*/    
                    // Récupération du résultat sans erreur, sinon récupération du premier
                    bestResult = defineBestLocalisation(geoResults, accCodePostal, accVille);
                    System.debug('## Best Result: '+bestResult);
                    // Récupération code IRIS
                    String rue = String.isBlank(bestResult.Adresse) ? accRue : bestResult.Adresse;
                    String codePostal = String.isBlank(bestResult.CodePostal) ? accCodePostal : bestResult.CodePostal;
                    String ville = String.isBlank(bestResult.Localite) ? accVille : bestResult.Localite;
                    String pays = String.isBlank(bestResult.Pays) ? PAYS_CODE_MAP.get(accPays) : PAYS_CODE_MAP.get(bestResult.Pays);
                    String insee = bestResult.IDLocalite;
                    account.iris__c = calcultateIRIS(codePostal, insee, bestResult.iris, sectorisations);

                    // Récupération latitude/longitude
                    Map<String, String> recordLoc = processRecordLocalisation(bestResult, accRue, accVille , accCodePostal);
                    if(recordLoc != null && String.isNotBlank(recordLoc.get('latitude')) && String.isNotBlank(recordLoc.get('longitude')) && recordLoc.get('longitude') != '0.00'){
                        account.Localisation__Latitude__s = Decimal.valueOf(recordLoc.get('latitude'));
                        account.Localisation__Longitude__s = Decimal.valueOf(recordLoc.get('longitude'));
                        ville = recordLoc.get('ville');
                    } else {                    
                        account.Localisation__Latitude__s = null;
                        account.Localisation__Longitude__s = null;
                    }

                    // Récupération adresse
                    if (COPYADDRESS) {
                        if (account.isPersonAccount) {
                            account.PersonMailingStreet=rue;
                            account.PersonMailingPostalCode=codePostal;
                            account.PersonMailingCity=ville;
                            account.PersonMailingCountry=pays;
                        }
                        else {
                            account.BillingStreet=rue;
                            account.BillingPostalCode=codePostal;
                            account.BillingCity=ville;
                            account.BillingCountry=pays;
                        }
                    }
                    account.codeCommune__c=insee;
                    account.adresseGeolocalisation__c = rue+'\n'+codePostal+' '+ville+'\n'+pays;
                    System.debug('## Adresse de geolocalisation: ' + account.adresseGeolocalisation__c);
                    account.methodeGeocodage__c='Batch';
                } else {
                    return null;
                }
            } 
            System.debug('### FIN GeoUtils.geolocationAccountDQE');
            return bestResult;
        } catch(Exception e){
            // JMU - 29/06/2017 : Hotfix dans le cas ou la geoloc time out (qd le reseau KpK est down par exemple)
            // A la place, il faut affecter le 1er iris associé au code postal et de l'adresse et appartenant à un magasin.
            // Pas de recherche par code commune car ce dernier est récupéré par DQE qui est indisponible
            if(e.getMessage()==Label.dqe_msg_errorsWSDQEAddress){
                // Vérification du secteur de l'adresse selon code postal
                String newCodePostal = '';
                if (isPersonAccount) {
                    newCodePostal = dataAccount.PersonMailingPostalCode;
                } else {
                    newCodePostal = dataAccount.BillingPostalCode;
                }
                System.debug('## CP: '+newCodePostal);
                sectorisations = [SELECT Id, iris__c
                                    FROM Sectorisation__c 
                                    WHERE codePostalAdm__c = :newCodePostal AND codeMagasin__c != '' LIMIT 1];
                // Si pas de secteur ou hors zone, erreur
                if(!sectorisations.isEmpty()) {
                    for(Sectorisation__c sector : sectorisations) {
                        account.iris__c=sector.iris__c;
                    }
                } else {
                    return null;
                }
                return bestResult;
            } else {
                throw e;
            }
        }
    }

    /**
    * @description Geocodage adresse DQE pour chantier / Récupération code IRIS
    * @param chantier Chantier à géocoder
    * @param sectorisations Liste des sectorisations à utiliser (null si optionnel)
    * @return Utils_DQE.GeocodeResultType Flag de validation
    */
    public static Utils_DQE.GeocodeResultType geolocationChantierDQE(Chantier__c chantier, List<Sectorisation__c> sectorisations){
        System.debug('### DEBUT GeoUtils.geolocationChantierDQE');
        Utils_DQE.GeocodeResultType bestResult=null;

        try {
            if(String.isNotBlank(chantier.codePostal__c)) {
                List<Utils_DQE.GeocodeResultType> geoResults = Utils_DQE.DQEIrisRNVP(chantier.complementAdresse__c, chantier.codePostal__c, chantier.rue__c, '', 
                                                                                        chantier.ville__c, PAYS_VALEUR_MAP.get(chantier.pays__c));
                if(geoResults != null && !geoResults.isEmpty()){
                    // Récupération du résultat sans erreur, sinon récupération du premier
                    bestResult = defineBestLocalisation(geoResults, chantier.codePostal__c, chantier.ville__c);
                    System.debug('## Best Result: '+bestResult);

                    // Récupération code IRIS
                    String rue = String.isBlank(bestResult.Adresse) ? chantier.rue__c : bestResult.Adresse;
                    String codePostal = String.isBlank(bestResult.CodePostal) ? chantier.codePostal__c : bestResult.CodePostal;
                    String ville = String.isBlank(bestResult.Localite) ? chantier.ville__c : bestResult.Localite;
                    String pays = String.isBlank(bestResult.Pays) ? PAYS_CODE_MAP.get(chantier.pays__c) : PAYS_CODE_MAP.get(bestResult.Pays);
                    String insee = bestResult.IDLocalite;
                    chantier.iris__c = calcultateIRIS(codePostal, insee, bestResult.iris, sectorisations);

                    // Récupération latitude/longitude
                    Map<String, String> recordLoc = processRecordLocalisation(bestResult, chantier.rue__c, chantier.ville__c , chantier.codePostal__c);
                    if(recordLoc != null && String.isNotBlank(recordLoc.get('latitude')) && String.isNotBlank(recordLoc.get('longitude')) && recordLoc.get('longitude') != '0.00'){
                        chantier.Localisation__Latitude__s = Decimal.valueOf(recordLoc.get('latitude'));
                        chantier.Localisation__Longitude__s = Decimal.valueOf(recordLoc.get('longitude'));
                        ville = recordLoc.get('ville');
                    } else {                    
                        chantier.Localisation__Latitude__s = null;
                        chantier.Localisation__Longitude__s = null;
                    }

                    // Récupération adresse
                    if (COPYADDRESS) {
                        chantier.rue__c=rue;
                        chantier.codePostal__c=codePostal;
                        chantier.ville__c=ville;
                        chantier.pays__c=pays;
                    }
                    chantier.codeCommune__c=insee;
                    chantier.adresseGeolocalisation__c = rue+'\n'+codePostal+' '+ville+'\n'+pays;
                    System.debug('## Adresse de geolocalisation: ' + chantier.adresseGeolocalisation__c);   
                    chantier.methodeGeocodage__c='Batch';
                } else {
                    return null;
                } 
            } 
            System.debug('### FIN GeoUtils.GeolocationAccountDQE');
            return bestResult;
        } catch(Exception e){
            // JMU - 29/06/2017 : Hotfix dans le cas ou la geoloc time out (qd le reseau KpK est down par exemple)
            // A la place, il faut affecter le 1er iris associé au code postal et de l'adresse et appartenant à un magasin.
            // Pas de recherche par code commune car ce dernier est récupéré par DQE qui est indisponible
            if(e.getMessage()==Label.dqe_msg_errorsWSDQEAddress){
                // Vérification du secteur de l'adresse selon code postal
                System.debug('## CP: '+chantier.codePostal__c);
                sectorisations = [SELECT Id, iris__c
                                    FROM Sectorisation__c 
                                    WHERE codePostalAdm__c = :chantier.codePostal__c AND codeMagasin__c != '' LIMIT 1];
                // Si pas de secteur ou hors zone, erreur
                if(!sectorisations.isEmpty()) {
                    for(Sectorisation__c sector : sectorisations) {
                        chantier.iris__c=sector.iris__c;
                    }
                } else {
                    return null;
                }
                return bestResult;
            } else {
                throw e;
            }
        }
    }
    
    /**
    * @description Détermine le code IRIS de l'enregistrement selon la valeur retournée par DQE ou le code commune/code postal si ce dernier n'existe pas
    * @param codePostal Code postal de l'enregistrement
    * @param codeInsee Code commune de l'enregistrement
    * @param irisDQE Valeur IRIS retournée par DQE
    * @param sectorisations Liste des sectorisations à utiliser
    * @return String Code IRIS calculé selon la présence d'une sectorisation dans Salesforce
    */
    public static String calcultateIRIS(String codePostal, String codeInsee, String irisDQE, List<Sectorisation__c> sectorisations) {
        System.debug('### DEBUT GeoUtils.calcultateIRIS');
        String retVal;
        Boolean errorIris=false;

        // Construction code IRIS (Code commune + code IRIS)
        String codeIris = codeInsee+''+irisDQE;
        // Vérification de la présence du secteur selon IRIS retourné par DQE ou code commune, ou code postal
        if(sectorisations==null || sectorisations.isEmpty()) {
            sectorisations = [SELECT Id, iris__c, codeCommuneAdm__c, codePostalAdm__c FROM Sectorisation__c 
                                WHERE iris__c=:codeIris OR codePostalAdm__c=:codePostal OR codeCommuneAdm__c=:codeInsee];
        }
        System.debug('## INSEE: '+codeInsee+' / CP: '+codePostal);
        if(String.isBlank(irisDQE)) { // 3 Si iris renvoyé par DQE = '' alors erreur = VRAI      
            System.debug('## Iris non renseigné par DQE');
            errorIris=true;
        } else if(irisDQE=='0000'){ // 4 Si iris renvoyé par DQE = '0000' 
            System.debug('## Iris 0000');
            // 4.a Recherche de l'enregistrement de sectorisation correspondant à l'iris renvoyé par DQE
            for(Sectorisation__c  sector : sectorisations) {
                if(sector.iris__c == codeIris) {
                    retVal=sector.iris__c;
                }
            }
            // 4.b Si enregistrement de sectorisation__c inexistant alors erreur = VRAI
            if(String.isBlank(retVal)) {
                errorIris=true;
            }
        } else{ // 4 Si iris renvoyé par DQE != '0000' et != '' vérification présence sectorisation
            System.debug('## Iris renseigné par DQE');
            for(Sectorisation__c  sector : sectorisations) {
                if(sector.iris__c == codeIris) {
                    retVal=sector.iris__c;
                }
            }
            if(String.isBlank(retVal)) {
                errorIris=true;
            }
        }
        // 5 Si erreur = VRAI
        if(errorIris) {
            System.debug('## ErrorIris');
            // Reexécution de la requête SOQL pour récupérer correctement tous les secteurs
            sectorisations = [SELECT Id, iris__c, codeCommuneAdm__c, codePostalAdm__c FROM Sectorisation__c 
                                WHERE iris__c=:codeIris OR codePostalAdm__c=:codePostal OR codeCommuneAdm__c=:codeInsee];
            // 5.A - Recherche du 1er enregistrement de sectorisation__c dont le code commune correspond à celui recherché
            if(String.isNotBlank(codeInsee)) {
                for(Sectorisation__c  sector : sectorisations) {
                    if(sector.codeCommuneAdm__c == codeInsee) {
                        System.debug('## Recherche par code commune: '+sector.iris__c);
                        // 5.B - Si enregistrement trouvé, alors affectation de l'iris et de l'id de sectorisation
                        retVal=sector.iris__c;
                        break;
                    }
                }
            }
            // 5.C - Sinon
            if(String.isBlank(retVal)) {
                // 5.C.1 - Recherche du 1er enregistrement de sectorisation__c dont le code postal correspond à celui recherché
                if(String.isNotBlank(codePostal)) {
                    for(Sectorisation__c  sector : sectorisations) {
                        if(sector.codePostalAdm__c == codePostal) {
                            System.debug('## Recherche par code postal: '+sector.iris__c);
                            // 5.C.2 - Si enregistrement trouvé, alors affectation de l'iris et de l'id de sectorisation 
                            retVal=sector.iris__c;
                            break; 
                        }
                    }
                }
            }
        } 
        System.debug('## Iris: '+retVal);
        System.debug('### FIN GeoUtils.calcultateIRIS');
        return retVal;
    }

    /**
    * @escription Fonction permettant de récupérer l'adresse proposés par DQE la plus pertinente. 
    * @param geoResult Resultat de la première localisation
    * @param codePostal Code postal de l'enregistrement
    * @param ville Ville de l'enregistrement
    * @return Utils_DQE.GeocodeResultType Objet contenant l'adresse la plus pertinente
    */
    private static Utils_DQE.GeocodeResultType defineBestLocalisation(List<Utils_DQE.GeocodeResultType> geoResults, String codePostal, String ville) {
        Utils_DQE.GeocodeResultType bestResult = null; 
        Integer niveauIncertitude = 5;
        // Récupération du résultat sans erreur, sinon récupération du premier
        for(Utils_DQE.GeocodeResultType geo : geoResults) {
            system.debug('geo : '+geo);
            system.debug('codePostal : '+codePostal);
            if(geo != null && codePostal != null){
                if((niveauIncertitude > 1 || niveauIncertitude == 1) && codePostal == geo.CodePostal && ville == geo.Localite){
                    bestResult = geo;
                    niveauIncertitude = 1;
                } else if((niveauIncertitude > 2 || niveauIncertitude == 2) && codePostal == geo.CodePostal){
                    bestResult = geo;
                    niveauIncertitude = 2;
                } else if(geo.CodePostal != null && (niveauIncertitude > 3 || niveauIncertitude == 3) && codePostal.substring(0,2) == geo.CodePostal.substring(0,2)){
                    system.debug('geo.CodePostal : '+geo.CodePostal);
                    bestResult = geo;
                    niveauIncertitude = 3;
                } else if(niveauIncertitude > 4 || niveauIncertitude == 4){
                    bestResult = geo;
                    niveauIncertitude = 4;
                }
            }
        }    
        if(bestResult==null) {
            bestResult = geoResults[0];        
        }
        return bestResult;
    }

    /**
    * @escription Fonction permettant de récupérer la localisation en fonction de la rue/ville/code postal ou ville/code postal. 
    * Dans le deuxième cas, un calcul de distance entre les villes est effectués pour définir la bonne ville selon le code postal
    * @param geoResult Resultat de la première localisation
    * @param rue Rue de l'enregistrement
    * @param ville Ville de l'enregistrement
    * @param codePostal Code postal de l'enregistrement
    * @return Map<String, String> Objet contenant les valeurs de localisation (latitude/longitude) et la nouvelle valeur de la ville
    */
    private static Map<String, String> processRecordLocalisation(Utils_DQE.GeocodeResultType geoResult, String rue, String ville ,String codePostal) {
        System.debug('### DEBUT GeoUtils.processRecordLocalisation');
        Map<String, String> resultMap = new Map<String, String>();
        String latitude = null;
        String longitude = null;
        String newVille = ville;
        // Récupération latitude/longitude
        if(String.isNotBlank(geoResult.Latitude) && Decimal.valueOf(geoResult.Latitude) != 0) {
            System.debug('## Localisation grâce a DQE');
            latitude = geoResult.Latitude;
            longitude = geoResult.Longitude;
        } else if (String.isNotBlank(geoResult.IDVoie)) {
            Utils_DQE.GeocodeResultType geoLatLongResult = Utils_DQE.DQELongLat(geoResult.IDVoie, geoResult.Numero, geoResult.Pays); 
            if(geoLatLongResult != null && Decimal.valueOf(geoLatLongResult.Latitude) != 0){
                // Récupération par latitude/longitude par IDVoie
                System.debug('## Localisation grâce a IDVoie');
                latitude = geoLatLongResult.Latitude;
                longitude = geoLatLongResult.Longitude;
            }
        } 
        // Recherche par code postal
        if (String.isBlank(longitude) && String.isNotBlank(codePostal) && String.isNotBlank(ville)) {
            System.debug('## Localisation grâce au code postal');
            // Récupération par code postal
            List<Utils_DQE.GeocodeResultType> postalCodeResults = Utils_DQE.DQEPostalCode(codePostal, geoResult.Pays);
            if(postalCodeResults != null){
                // Parcours de toutes les liste des villes et calcule distance pour récupérer l'adresse
                Double percentageMax = 0;
                for(Utils_DQE.GeocodeResultType geo : postalCodeResults) {
                    System.debug('## GeocodeResultType: '+geo);
                    // Calcul de la distance du nom de la ville
                    if(String.IsNotBlank(geo.Localite)) {
                        System.debug('## Check localite: '+geo.Localite);
                        /*Integer distance = ville.getLevenshteinDistance(geo.Localite);
                        System.debug('## distance: '+distance);
                        System.debug('## distanceMax: '+distanceMax);
                        if(distance <= distanceMax) {
                            latitude = geo.Latitude;
                            longitude = geo.Longitude;
                            newVille = geo.Localite;
                            distanceMax = distance;
                        }*/
                        Double percentage = calculateLevenshteinDistance(ville, geo.Localite);
                        // Si le nom saisi par l'utilisateur est dans la valeur de DQE, on augmente le pourcentage (traitement nom composé)
                        if(geo.Localite.containsIgnoreCase(ville)) {
                            percentage = percentage + 20;
                        }
                        // Vérifie la distance et récupération si localisation présente
                        System.debug('## percentage: '+percentage);
                        System.debug('## percentageMax: '+percentageMax);
                        if(percentage > percentageMax & String.isNotBlank(geo.Longitude)) {
                            System.debug('## Localisation: '+geo.Latitude + ' / '+geo.Longitude);
                            latitude = geo.Latitude;
                            longitude = geo.Longitude;
                            newVille = geo.Localite;
                            percentageMax = percentage;
                        }
                    }
                }    
            }
        }
        System.debug('## latitude: '+latitude);
        System.debug('## longitude: '+longitude);
        System.debug('## newVille: '+newVille);
        resultMap.put('latitude', latitude);
        resultMap.put('longitude', longitude);
        resultMap.put('ville', newVille);
        System.debug('### FIN GeoUtils.processRecordLocalisation');
        return resultMap;
    }
    
    /**
    * @escription Fonction calculant la distance (similarité) entre deux textes en utilisant l'algorithme de Levenshtein. 
    * @param s Texte 1 
    * @param t Texte 2
    * @return Double Pourcentage de similarité entre les deux textes
    */
    private static Double calculateLevenshteinDistance(String s, String t) {
        Integer len0 = s.length() + 1;
        integer len1 = t.length() + 1;
        list<integer> cost = new list<integer>();
        List<Integer> newcost = new list<Integer>();
        for(Integer i = 0; i < len0; i++) {
            cost.add(i);
        }
        for(integer j = 1; j< len1; j++) {
            newcost.add(j);
            for(Integer i = 1; i< len0; i++) {
                integer match = (s.charAt(i-1) == t.charat(j-1)) ? 0 : 1;
                Integer cost_replace = cost[i-1] + match;
                Integer cost_insert = cost[i] + 1;
                Integer cost_delete = newcost[i - 1] + 1;
                if(newcost.size() > i ) {
                    newcost[i] = Math.min(Math.min(cost_replace,cost_delete),cost_replace);
                }
                else {
                    newcost.add(Math.min(Math.min(cost_replace,cost_delete),cost_replace));
                }
            }
            list<integer> swap = new list<Integer>();
            swap.addAll(cost);
            cost = new List<Integer>();
            cost.addAll(newcost);
            newcost = new list<integer>();
            newcost.addall(swap);
        }
        integer bigger = Math.max(s.length(),t.length());
        Double percentage = (double.valueOf(bigger)-double.valueOf(cost[len0 - 1])) * 100 /double.valueOf(bigger);
        return percentage;
    }

    /**
    * @description Permet de vérifier si l'adresse est en secteur
    * @param importRecord Objet de l'import à vérifier
    * @return Boolean True si l'adresse est en hors secteur
    */
    private static Boolean checkHorsSecteur(Import__c importRecord) {
        System.debug('### DEBUT GeoUtils.checkHorsSecteur');
        Boolean horsZone = false;
        // Vérification de la présence du secteur selon IRIS retourné par DQE
        List<Sectorisation__c> sectorisations = [SELECT Id, iris__c, libelleMagasin__c, libelleDepot__c 
                                                    FROM Sectorisation__c WHERE iris__c = :importRecord.iris__c];
        if(!sectorisations.isEmpty()) {  
            for(Sectorisation__c sector : sectorisations) {        
                // Vérification si pas Hors zone ou zone blanche
                if('HORS ZONE'.equalsIgnoreCase(sector.libelleMagasin__c) || 'ZONE BLANCHE'.equalsIgnoreCase(sector.libelleMagasin__c)) {
                    horsZone = true;
                }
            }
        } else {
            horsZone = true;
        }
        /* else {
            // Vérification selon secteur par défaut                    
            for(Liste_Iris__c  codeIris : listIris) {
                if(codeIris.codePostal__c == importRecord.codePostalCompte__c && codeIris.codeINSEE__c == importRecord.codeCommune__c)
                    importRecord.iris__c=codeIris.iris__c;
            }
            sectorisations = [SELECT Id, iris__c, libelleMagasin__c, libelleDepot__c FROM Sectorisation__c WHERE iris__c = :importRecord.iris__c];
            if(!sectorisations.isEmpty()) {
                System.debug('## Vérification secteur par défaut');     
                for(Sectorisation__c sector : sectorisations) {  
                    // Vérification si pas Hors zone ou zone blanche
                    if('HORS ZONE'.equalsIgnoreCase(sector.libelleMagasin__c) || 'ZONE BLANCHE'.equalsIgnoreCase(sector.libelleMagasin__c))
                        hors_zone = true;
                }
            } else
                hors_zone = true;
        } */
        
        System.debug('## Hors zone: '+horsZone); 
        System.debug('### FIN GeoUtils.checkHorsSecteur');
        return horsZone;
    }

    // Map pour la liste des valeur pays
    public static final Map<String, String> PAYS_VALEUR_MAP =  new Map<String, String>
        {'AFGHANISTAN' => 'AFG',
        'AFRIQUE DU SUD' => 'ZAF',
        'ALBANIE' => 'ALB',
        'ALGÉRIE' => 'DZA',
        'ALLEMAGNE' => 'DEU',
        'ANDORRE' => 'AND',
        'ANGOLA' => 'AGO',
        'ANGUILLA' => 'AIA',
        'ANTIGUA-ET-BARBUDA' => 'ATG',
        'ARGENTINE' => 'ARG',
        'ARMÉNIE' => 'ARM',
        'ARUBA' => 'ABW',
        'AUSTRALIE' => 'AUS',
        'AUTRICHE' => 'AUT',
        'AZERBAÏDJAN' => 'AZE',
        'BAHAMAS' => 'BHS',
        'BAHREÏN' => 'BHR',
        'BANGLADESH' => 'BGD',
        'BARBADE' => 'BRB',
        'BIÉLORUSSIE' => 'BLR',
        'BELGIQUE' => 'BEL',
        'BELIZE' => 'BLZ',
        'BÉNIN' => 'BEN',
        'BERMUDES' => 'BMU',
        'BHOUTAN' => 'BTN',
        'BOLIVIE' => 'BOL',
        'BOSNIE-HERZÉGOVINE' => 'BIH',
        'BOTSWANA' => 'BWA',
        'BRÉSIL' => 'BRA',
        'BRUNEI' => 'BRN',
        'BULGARIE' => 'BGR',
        'BURKINA FASO' => 'BFA',
        'BURUNDI' => 'BDI',
        'ÎLES CAÏMANS' => 'CYM',
        'CAMBODGE' => 'KHM',
        'CAMEROUN' => 'CMR',
        'CANADA' => 'CAN',
        'CAP-VERT' => 'CPV',
        'RÉPUBLIQUE CENTRAFRICAINE' => 'CAF',
        'CHILI' => 'CHL',
        'CHINE' => 'CHN',
        'CHYPRE' => 'CYP',
        'COLOMBIE' => 'COL',
        'COMORES' => 'COM',
        'RÉPUBLIQUE DU CONGO' => 'COG',
        'RÉPUBLIQUE DÉMOCRATIQUE DU CONGO' => 'COD',
        'CORÉE DU SUD' => 'KOR',
        'CORÉE DU NORD' => 'PRK',
        'COSTA RICA' => 'CRI',
        'CÔTE D\'IVOIRE' => 'CIV',
        'CROATIE' => 'HRV',
        'CUBA' => 'CUB',
        'CURAÇAO' => 'CUW',
        'DANEMARK' => 'DNK',
        'DJIBOUTI' => 'DJI',
        'RÉPUBLIQUE DOMINICAINE' => 'DOM',
        'DOMINIQUE' => 'DMA',
        'ÉGYPTE' => 'EGY',
        'SALVADOR' => 'SLV',
        'ÉMIRATS ARABES UNIS' => 'ARE',
        'ÉQUATEUR' => 'ECU',
        'ÉRYTHRÉE' => 'ERI',
        'ESPAGNE' => 'ESP',
        'ESTONIE' => 'EST',
        'ÉTATS-UNIS' => 'USA',
        'ÉTHIOPIE' => 'ETH',
        'ÎLES MALOUINES' => 'FLK',
        'ÎLES FÉROÉ' => 'FRO',
        'FIDJI' => 'FJI',
        'FINLANDE' => 'FIN',
        'FRANCE' => 'FRA',
        'GABON' => 'GAB',
        'GAMBIE' => 'GMB',
        'GÉORGIE' => 'GEO',
        'GHANA' => 'GHA',
        'GRÈCE' => 'GRC',
        'GRENADE' => 'GRD',
        'GUATEMALA' => 'GTM',
        'GUINÉE' => 'GIN',
        'GUINÉE-BISSAU' => 'GNB',
        'GUYANA' => 'GUY',
        'GUYANE' => 'GUF',
        'HAÏTI' => 'HTI',
        'HONDURAS' => 'HND',
        'HONG KONG' => 'HKG',
        'HONGRIE' => 'HUN',
        'INDE' => 'IND',
        'INDONÉSIE' => 'IDN',
        'IRAN' => 'IRN',
        'IRAK' => 'IRQ',
        'IRLANDE' => 'IRL',
        'ISLANDE' => 'ISL',
        'ISRAËL' => 'ISR',
        'ITALIE' => 'ITA',
        'JAMAÏQUE' => 'JAM',
        'JAPON' => 'JPN',
        'JORDANIE' => 'JOR',
        'KAZAKHSTAN' => 'KAZ',
        'KENYA' => 'KEN',
        'KIRIBATI' => 'KIR',
        'KOWEÏT' => 'KWT',
        'LAOS' => 'LAO',
        'LESOTHO' => 'LSO',
        'LETTONIE' => 'LVA',
        'LIBAN' => 'LBN',
        'LIBÉRIA' => 'LBR',
        'LIBYE' => 'LBY',
        'LIECHTENSTEIN' => 'LIE',
        'LITUANIE' => 'LTU',
        'LUXEMBOURG' => 'LUX',
        'MACÉDOINE' => 'MKD',
        'MADAGASCAR' => 'MDG',
        'MALAISIE' => 'MYS',
        'MALAWI' => 'MWI',
        'MALDIVES' => 'MDV',
        'MALI' => 'MLI',
        'MALTE' => 'MLT',
        'MAROC' => 'MAR',
        'MAURICE' => 'MUS',
        'MAURITANIE' => 'MRT',
        'MEXIQUE' => 'MEX',
        'MOLDAVIE' => 'MDA',
        'MONACO' => 'MCO',
        'MONGOLIE' => 'MNG',
        'MONTÉNÉGRO' => 'MNE',
        'MOZAMBIQUE' => 'MOZ',
        'BIRMANIE' => 'MMR',
        'NAMIBIE' => 'NAM',
        'NAURU' => 'NRU',
        'NÉPAL' => 'NPL',
        'NICARAGUA' => 'NIC',
        'NIGER' => 'NER',
        'NIGERIA' => 'NGA',
        'NORVÈGE' => 'NOR',
        'NOUVELLE-CALÉDONIE' => 'NCL',
        'NOUVELLE-ZÉLANDE' => 'NZL',
        'OMAN' => 'OMN',
        'OUZBÉKISTAN' => 'UZB',
        'PAKISTAN' => 'PAK',
        'PANAMA' => 'PAN',
        'PAPOUASIE-NOUVELLE-GUINÉE' => 'PNG',
        'PARAGUAY' => 'PRY',
        'PAYS-BAS' => 'NLD',
        'PÉROU' => 'PER',
        'PHILIPPINES' => 'PHL',
        'POLOGNE' => 'POL',
        'PORTUGAL' => 'PRT',
        'QATAR' => 'QAT',
        'ROUMANIE' => 'ROU',
        'ROYAUME-UNI' => 'GBR',
        'RUSSIE' => 'RUS',
        'RWANDA' => 'RWA',
        'SAINT-CHRISTOPHE-ET-NIÉVÈS' => 'KNA',
        'SAINT-MARIN' => 'SMR',
        'SAINT-PIERRE-ET-MIQUELON' => 'SPM',
        'VATICAN' => 'VAT',
        'SAINT-VINCENT-ET-LES-GRENADINES' => 'VCT',
        'SAINTE-LUCIE' => 'LCA',
        'SALOMON' => 'SLB',
        'SAMOA' => 'WSM',
        'SAO TOMÉ-ET-PRINCIPE' => 'STP',
        'SÉNÉGAL' => 'SEN',
        'SERBIE' => 'SRB',
        'SEYCHELLES' => 'SYC',
        'SIERRA LEONE' => 'SLE',
        'SINGAPOUR' => 'SGP',
        'SLOVAQUIE' => 'SVK',
        'SLOVÉNIE' => 'SVN',
        'SOMALIE' => 'SOM',
        'SOUDAN' => 'SDN',
        'SRI LANKA' => 'LKA',
        'SUÈDE' => 'SWE',
        'SUISSE' => 'CHE',
        'SURINAME' => 'SUR',
        'SWAZILAND' => 'SWZ',
        'SYRIE' => 'SYR',
        'TADJIKISTAN' => 'TJK',
        'TANZANIE' => 'TZA',
        'RÉPUBLIQUE TCHÈQUE' => 'CZE',
        'THAÏLANDE' => 'THA',
        'TIMOR ORIENTAL' => 'TLS',
        'TOGO' => 'TGO',
        'TONGA' => 'TON',
        'TRINITÉ-ET-TOBAGO' => 'TTO',
        'TUNISIE' => 'TUN',
        'TURKMÉNISTAN' => 'TKM',
        'TURQUIE' => 'TUR',
        'TUVALU' => 'TUV',
        'UKRAINE' => 'UKR',
        'URUGUAY' => 'URY',
        'VANUATU' => 'VUT',
        'VENEZUELA' => 'VEN',
        'VIÊT NAM' => 'VNM',
        'WALLIS-ET-FUTUNA' => 'WLF',
        'YÉMEN' => 'YEM',
        'ZAMBIE' => 'ZMB',
        'ZIMBABWE' => 'ZWE'};

    // Map pour la liste des code pays
    public static final Map<String, String> PAYS_CODE_MAP =  new Map<String, String>
        {'AFG' => 'AFGHANISTAN',
        'ZAF' => 'AFRIQUE DU SUD',
        'ALB' => 'ALBANIE',
        'DZA' => 'ALGÉRIE',
        'DEU' => 'ALLEMAGNE',
        'AND' => 'ANDORRE',
        'AGO' => 'ANGOLA',
        'AIA' => 'ANGUILLA',
        'ATG' => 'ANTIGUA-ET-BARBUDA',
        'ARG' => 'ARGENTINE',
        'ARM' => 'ARMÉNIE',
        'ABW' => 'ARUBA',
        'AUS' => 'AUSTRALIE',
        'AUT' => 'AUTRICHE',
        'AZE' => 'AZERBAÏDJAN',
        'BHS' => 'BAHAMAS',
        'BHR' => 'BAHREÏN',
        'BGD' => 'BANGLADESH',
        'BRB' => 'BARBADE',
        'BLR' => 'BIÉLORUSSIE',
        'BEL' => 'BELGIQUE',
        'BLZ' => 'BELIZE',
        'BEN' => 'BÉNIN',
        'BMU' => 'BERMUDES',
        'BTN' => 'BHOUTAN',
        'BOL' => 'BOLIVIE',
        'BIH' => 'BOSNIE-HERZÉGOVINE',
        'BWA' => 'BOTSWANA',
        'BRA' => 'BRÉSIL',
        'BRN' => 'BRUNEI',
        'BGR' => 'BULGARIE',
        'BFA' => 'BURKINA FASO',
        'BDI' => 'BURUNDI',
        'CYM' => 'ÎLES CAÏMANS',
        'KHM' => 'CAMBODGE',
        'CMR' => 'CAMEROUN',
        'CAN' => 'CANADA',
        'CPV' => 'CAP-VERT',
        'CAF' => 'RÉPUBLIQUE CENTRAFRICAINE',
        'CHL' => 'CHILI',
        'CHN' => 'CHINE',
        'CYP' => 'CHYPRE',
        'COL' => 'COLOMBIE',
        'COM' => 'COMORES',
        'COG' => 'RÉPUBLIQUE DU CONGO',
        'COD' => 'RÉPUBLIQUE DÉMOCRATIQUE DU CONGO',
        'KOR' => 'CORÉE DU SUD',
        'PRK' => 'CORÉE DU NORD',
        'CRI' => 'COSTA RICA',
        'CIV' => 'CÔTE D\'IVOIRE',
        'HRV' => 'CROATIE',
        'CUB' => 'CUBA',
        'CUW' => 'CURAÇAO',
        'DNK' => 'DANEMARK',
        'DJI' => 'DJIBOUTI',
        'DOM' => 'RÉPUBLIQUE DOMINICAINE',
        'DMA' => 'DOMINIQUE',
        'EGY' => 'ÉGYPTE',
        'SLV' => 'SALVADOR',
        'ARE' => 'ÉMIRATS ARABES UNIS',
        'ECU' => 'ÉQUATEUR',
        'ERI' => 'ÉRYTHRÉE',
        'ESP' => 'ESPAGNE',
        'EST' => 'ESTONIE',
        'USA' => 'ÉTATS-UNIS',
        'ETH' => 'ÉTHIOPIE',
        'FLK' => 'ÎLES MALOUINES',
        'FRO' => 'ÎLES FÉROÉ',
        'FJI' => 'FIDJI',
        'FIN' => 'FINLANDE',
        'FRA' => 'FRANCE',
        'GAB' => 'GABON',
        'GMB' => 'GAMBIE',
        'GEO' => 'GÉORGIE',
        'GHA' => 'GHANA',
        'GRC' => 'GRÈCE',
        'GRD' => 'GRENADE',
        'GTM' => 'GUATEMALA',
        'GIN' => 'GUINÉE',
        'GNB' => 'GUINÉE-BISSAU',
        'GUY' => 'GUYANA',
        'GUF' => 'GUYANE',
        'HTI' => 'HAÏTI',
        'HND' => 'HONDURAS',
        'HKG' => 'HONG KONG',
        'HUN' => 'HONGRIE',
        'IND' => 'INDE',
        'IDN' => 'INDONÉSIE',
        'IRN' => 'IRAN',
        'IRQ' => 'IRAK',
        'IRL' => 'IRLANDE',
        'ISL' => 'ISLANDE',
        'ISR' => 'ISRAËL',
        'ITA' => 'ITALIE',
        'JAM' => 'JAMAÏQUE',
        'JPN' => 'JAPON',
        'JOR' => 'JORDANIE',
        'KAZ' => 'KAZAKHSTAN',
        'KEN' => 'KENYA',
        'KIR' => 'KIRIBATI',
        'KWT' => 'KOWEÏT',
        'LAO' => 'LAOS',
        'LSO' => 'LESOTHO',
        'LVA' => 'LETTONIE',
        'LBN' => 'LIBAN',
        'LBR' => 'LIBÉRIA',
        'LBY' => 'LIBYE',
        'LIE' => 'LIECHTENSTEIN',
        'LTU' => 'LITUANIE',
        'LUX' => 'LUXEMBOURG',
        'MKD' => 'MACÉDOINE',
        'MDG' => 'MADAGASCAR',
        'MYS' => 'MALAISIE',
        'MWI' => 'MALAWI',
        'MDV' => 'MALDIVES',
        'MLI' => 'MALI',
        'MLT' => 'MALTE',
        'MAR' => 'MAROC',
        'MUS' => 'MAURICE',
        'MRT' => 'MAURITANIE',
        'MEX' => 'MEXIQUE',
        'MDA' => 'MOLDAVIE',
        'MCO' => 'MONACO',
        'MNG' => 'MONGOLIE',
        'MNE' => 'MONTÉNÉGRO',
        'MOZ' => 'MOZAMBIQUE',
        'MMR' => 'BIRMANIE',
        'NAM' => 'NAMIBIE',
        'NRU' => 'NAURU',
        'NPL' => 'NÉPAL',
        'NIC' => 'NICARAGUA',
        'NER' => 'NIGER',
        'NGA' => 'NIGERIA',
        'NOR' => 'NORVÈGE',
        'NCL' => 'NOUVELLE-CALÉDONIE',
        'NZL' => 'NOUVELLE-ZÉLANDE',
        'OMN' => 'OMAN',
        'UZB' => 'OUZBÉKISTAN',
        'PAK' => 'PAKISTAN',
        'PAN' => 'PANAMA',
        'PNG' => 'PAPOUASIE-NOUVELLE-GUINÉE',
        'PRY' => 'PARAGUAY',
        'NLD' => 'PAYS-BAS',
        'PER' => 'PÉROU',
        'PHL' => 'PHILIPPINES',
        'POL' => 'POLOGNE',
        'PRT' => 'PORTUGAL',
        'QAT' => 'QATAR',
        'ROU' => 'ROUMANIE',
        'GBR' => 'ROYAUME-UNI',
        'RUS' => 'RUSSIE',
        'RWA' => 'RWANDA',
        'KNA' => 'SAINT-CHRISTOPHE-ET-NIÉVÈS',
        'SMR' => 'SAINT-MARIN',
        'SPM' => 'SAINT-PIERRE-ET-MIQUELON',
        'VAT' => 'VATICAN',
        'VCT' => 'SAINT-VINCENT-ET-LES-GRENADINES',
        'LCA' => 'SAINTE-LUCIE',
        'SLB' => 'SALOMON',
        'WSM' => 'SAMOA',
        'STP' => 'SAO TOMÉ-ET-PRINCIPE',
        'SEN' => 'SÉNÉGAL',
        'SRB' => 'SERBIE',
        'SYC' => 'SEYCHELLES',
        'SLE' => 'SIERRA LEONE',
        'SGP' => 'SINGAPOUR',
        'SVK' => 'SLOVAQUIE',
        'SVN' => 'SLOVÉNIE',
        'SOM' => 'SOMALIE',
        'SDN' => 'SOUDAN',
        'LKA' => 'SRI LANKA',
        'SWE' => 'SUÈDE',
        'CHE' => 'SUISSE',
        'SUR' => 'SURINAME',
        'SWZ' => 'SWAZILAND',
        'SYR' => 'SYRIE',
        'TJK' => 'TADJIKISTAN',
        'TZA' => 'TANZANIE',
        'CZE' => 'RÉPUBLIQUE TCHÈQUE',
        'THA' => 'THAÏLANDE',
        'TLS' => 'TIMOR ORIENTAL',
        'TGO' => 'TOGO',
        'TON' => 'TONGA',
        'TTO' => 'TRINITÉ-ET-TOBAGO',
        'TUN' => 'TUNISIE',
        'TKM' => 'TURKMÉNISTAN',
        'TUR' => 'TURQUIE',
        'TUV' => 'TUVALU',
        'UKR' => 'UKRAINE',
        'URY' => 'URUGUAY',
        'VUT' => 'VANUATU',
        'VEN' => 'VENEZUELA',
        'VNM' => 'VIÊT NAM',
        'WLF' => 'WALLIS-ET-FUTUNA',
        'YEM' => 'YÉMEN',
        'ZMB' => 'ZAMBIE',
        'ZWE' => 'ZIMBABWE'};
}