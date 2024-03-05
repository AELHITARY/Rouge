//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_User
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/02/2023
//-- Version     : 1.11
//-- * 1.11 : Revue suite suppression de rôles
//-- * 1.10 : RQM-65 : Anonymisation des informations et ajout vérification des RDV de service
//-- * 1.9 : Correction alimentation sectorisation pour DV, DR
//-- * 1.7 : RQM-31 : Ajout informations facebook pour projet KAPTURE
//-- --------------------------------------------------------------------------------- --
public with sharing class TR020_User {  
    private static final Id RT_RDVCommercial = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final String URLFACEBOOK_SEPARATOR = ';';
    
    /**
    * @description Règles de validation pour l'objet User
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR020_User.applyValidationRules');
        List<User> newUsers = (List<User>)Trigger.new;
        Map<Id, User> oldUsers = (Map<Id, User>)Trigger.oldMap;
        
        if (Trigger.isUpdate) {
            // Récupération des RDV commerciaux
            AggregateResult[] results = [SELECT OwnerId, count(Id) eventCount
                                         FROM Event
                                         WHERE RecordTypeId = :RT_RDVCommercial
                                         AND OwnerId IN :newUsers
                                         AND ActivityDateTime >= TODAY
                                         GROUP BY OwnerId
                                         ORDER BY OwnerId];
            // Récupération des RDV de service
            List<ServiceAppointment> resultsSA = [SELECT Id, EarliestStartTime, SchedStartTime, 
                                                  (SELECT ServiceResource.RelatedRecordId FROM ServiceResources WHERE ServiceResource.RelatedRecordId IN :newUsers) 
                                                  FROM ServiceAppointment WHERE 
                                                  Id IN (SELECT ServiceAppointmentId FROM AssignedResource WHERE ServiceResource.RelatedRecordId IN :newUsers) 
                                                  AND SchedStartTime >= TODAY];
            
            for (User newUser : newUsers) {
                User oldUser = oldUsers.get(newUser.Id);
                // Si l'utilsateur est désactivé
                if (!newUser.isActive && oldUser != null && newUser.isActive != oldUser.isActive) {
                    Boolean hasRDV = false;
                    // Vérifie si un RDV commercial existe, si oui, erreur
                    for (AggregateResult result : results) {
                        ID ownerId = (ID) result.get('OwnerId');
                        Integer count = (Integer) result.get('eventCount');
                        
                        if (newUser.Id == ownerId) {
                            if (count > 0) {
                                hasRDV = true;
                                break;
                            }
                        }
                    }
                    // Vérifie si un RDV de service existe, si oui, erreur
                    if(hasRDV == false) {
                        for (ServiceAppointment sa : resultsSA) {
                            for (AssignedResource ar : sa.ServiceResources) {
                                if (newUser.Id == ar.ServiceResource.RelatedRecordId) {
                                    hasRDV = true;
                                    break;
                                }
                            }
                        }
                    }
                    if(hasRDV) {
                        newUser.addError(Label.user_error_desactivationImpossible);
                    }
                }
            }
        }
        System.debug('### FIN TR020_User.applyValidationRules');
    }
    
    /**
    * @description Règles de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR020_User.applyUpdateRules');
        List<User> newUsers = (List<User>)Trigger.new;
        Map<Id, User> oldUsers = (Map<Id, User>)Trigger.oldMap;
        
        List<String> sectorisationCodes = new List<String>();
        Map<String, AggregateResult> sectorisations = new Map<String, AggregateResult>();
        Map<String,List<PublicationFacebook__c>> publications = new Map<String,List<PublicationFacebook__c>>();
        String urlFBForMarketing = '';
        Set<Id> parentRoleIds = new Set<ID>();
        
        //** A - Initialisation des données intermédiaires 
        Map<Id, UserRole> roles = new Map<Id, UserRole>([SELECT Id, Name
                                                         FROM UserRole
                                                         WHERE PortalType = 'None' AND (Name LIKE 'MAG%'
                                                                OR Name LIKE 'DV%' 
                                                                OR Name LIKE 'RV%' 
                                                                OR Name = 'K par K')]);
        
        // A.1 - Construction du référentiel des sectorisations
        for (User newUser : newUsers) {
            User oldUser = Trigger.isInsert ? null : oldUsers.get(newUser.Id);
            
            // Matricule
            if(Trigger.isInsert || (oldUser != null && newUser.Matricule__c != oldUser.Matricule__c ))
                newUser.EmployeeNumber = newUser.Matricule__c;
            
            // Désactivation de l'utilisateur, suppression des données
            if(Trigger.isUpdate && newUser.IsActive != oldUser.IsActive && newUser.IsActive == false && newUser.dateDesactivation__c == null) {
                newUser.dateDesactivation__c = System.now();
                newUser.dateSortie__c = Date.today();   
                newUser.utilisateurAyantDesactive__c = UserInfo.getUserId();
            }
            
            // Réactivation de l'utilisateur
            if(Trigger.isUpdate && newUser.IsActive != oldUser.IsActive && newUser.IsActive) {
                newUser.dateAnonymisation__c = null;
                newUser.dateDesactivation__c = null;
                newUser.dateSortie__c = null;   
                newUser.utilisateurAyantDesactive__c = null;
            }
            
            // Gestion role et sectorisation
            if (newUser.UserRoleId != null /* && newUser.IsActive */ &&
                (Trigger.isInsert                                       ||
                 newUser.UserRoleId        != oldUser.UserRoleId        ||
                 newUser.IsActive          != oldUser.IsActive          ||
                 newUser.codeMagasin__c    != oldUser.codeMagasin__c    ||
                 newUser.libelleMagasin__c != oldUser.libelleMagasin__c ||
                 newUser.codeDV__c         != oldUser.codeDV__c         ||
                 newUser.libelleDV__c      != oldUser.libelleDV__c      ||
                 newUser.codeDepot__c      != oldUser.codeDepot__c      ||
                 newUser.libelleDepot__c   != oldUser.libelleDepot__c   ||
                 newUser.codeDS__c         != oldUser.codeDS__c         ||
                 newUser.libelleDS__c      != oldUser.libelleDS__c      ||
                 newUser.codeDR__c         != oldUser.codeDR__c         ||
                 newUser.libelleDR__c      != oldUser.libelleDR__c)) 
            {
                UserRole role = roles.get(newUser.UserRoleId);
                if (role != null && !'K par K'.equals(role.name)) {
                    String[] items = roles.get(newUser.UserRoleId).Name.split(' - ');
                    String newCode = items[0].trim().toUpperCase();
                    sectorisationCodes.add(newCode);
                }
            }
        }
        System.debug('sectorisationCodes : '+sectorisationCodes);

        if(!sectorisationCodes.isEmpty()) {
            for(AggregateResult ar : [SELECT codeMagasin__c, libelleMagasin__c, codeDV__c, libelleDV__c, codeRegion__c, libelleRegion__c, codeDepot__c, libelleDepot__c, codeDS__c, libelleDS__c
                                       FROM Sectorisation__c
                                       WHERE codeMagasin__c IN :sectorisationCodes
                                       OR codeDV__c IN :sectorisationCodes
                                       OR codeRegion__c  IN :sectorisationCodes
                                       GROUP BY libelleMagasin__c, codeMagasin__c, libelleDV__c, codeDV__c, libelleRegion__c, codeRegion__c, libelleDS__c, codeDS__c, libelleDepot__c, codeDepot__c
                                       ORDER BY libelleRegion__c, libelleDV__c, libelleRegion__c])
            {
                if (String.isNotBlank(String.valueOf(ar.get('codeMagasin__c')))) {
                    sectorisations.put(String.valueOf(ar.get('codeMagasin__c')), ar);
                }
                if (String.isNotBlank(String.valueOf(ar.get('codeDV__c')))) {
                    sectorisations.put(String.valueOf(ar.get('codeDV__c')), ar);
                }
                if (String.isNotBlank(String.valueOf(ar.get('codeRegion__c')))) {
                    sectorisations.put(String.valueOf(ar.get('codeRegion__c')), ar);
                }
            }
            /*for (Sectorisation__c sectorisation : [SELECT codeMagasin__c, libelleMagasin__c, codeDV__c, libelleDV__c, codeRegion__c, libelleRegion__c, codeDepot__c, libelleDepot__c, codeDS__c, libelleDS__c
                                                   FROM Sectorisation__c
                                                   WHERE codeMagasin__c IN :sectorisationCodes
                                                   OR codeDV__c IN :sectorisationCodes
                                                   OR codeRegion__c  IN :sectorisationCodes
                                                   GROUP BY codeMagasin__c]) {
                if (String.isNotBlank(sectorisation.codeMagasin__c))
                    sectorisations.put(sectorisation.codeMagasin__c, sectorisation);
                if (String.isNotBlank(sectorisation.codeDV__c))
                    sectorisations.put(sectorisation.codeDV__c, sectorisation);
                if (String.isNotBlank(sectorisation.codeRegion__c))
                    sectorisations.put(sectorisation.codeRegion__c, sectorisation);
            }*/
        }
        
        // A.2 - URLs Facebook
        if(!roles.isEmpty()) {
            for(PublicationFacebook__c publication : [SELECT codeMagasin__c, codeDV__c, codeDR__c, urls__c FROM PublicationFacebook__c]) {
                urlFBForMarketing += publication.urls__c + URLFACEBOOK_SEPARATOR;
                if (String.isNotBlank(publication.codeMagasin__c)) {
                    publications = constructURLFacebookMap(publication.codeMagasin__c, publications, publication);
                }
                if (String.isNotBlank(publication.codeDV__c)) {
                    publications = constructURLFacebookMap(publication.codeDV__c, publications, publication);
                }
                if (String.isNotBlank(publication.codeDR__c)) {
                    publications = constructURLFacebookMap(publication.codeDR__c, publications, publication);
                }
            }
            urlFBForMarketing = urlFBForMarketing.left(urlFBForMarketing.length() - 1);
        }
        
        //** B - Application des règles de mise à jour 
        for (User newUser : newUsers) {
            User oldUser = Trigger.isInsert ? null : oldUsers.get(newUser.id);
            
            // Mise à jour du magasin, depot etc....
            if (newUser.userRoleId != null /* && newUser.IsActive */ &&
                (Trigger.isInsert                                       ||
                 newUser.UserRoleId        != oldUser.UserRoleId        ||
                 newUser.IsActive          != oldUser.IsActive          ||
                 newUser.codeMagasin__c    != oldUser.codeMagasin__c    ||
                 newUser.libelleMagasin__c != oldUser.libelleMagasin__c ||
                 newUser.codeDV__c         != oldUser.codeDV__c         ||
                 newUser.libelleDV__c      != oldUser.libelleDV__c      ||
                 newUser.codeDepot__c      != oldUser.codeDepot__c      ||
                 newUser.libelleDepot__c   != oldUser.libelleDepot__c   ||
                 newUser.codeDS__c         != oldUser.codeDS__c         ||
                 newUser.libelleDS__c      != oldUser.libelleDS__c      ||
                 newUser.codeDR__c         != oldUser.codeDR__c         ||
                 newUser.libelleDR__c      != oldUser.libelleDR__c)) 
            {         
                newUser.codeMagasin__c    = null;
                newUser.libelleMagasin__c = null;
                newUser.codeDV__c         = null;
                newUser.libelleDV__c      = null;
                newUser.codeDR__c         = null;
                newUser.libelleDR__c      = null;
                newUser.codeDepot__c      = null;
                newUser.libelleDepot__c   = null;
                newUser.codeDS__c         = null;
                newUser.libelleDS__c      = null;
                newUser.managerId         = null;
                newUser.URLFacebook__c    = null;
                
                UserRole role = roles.get(newUser.UserRoleId);

                // B.1 - Reseau commercial ==> Affectation sectorisation et publication Facebook
                if (role != null && !'K par K'.equals(role.name)) {
                    String[] items = roles.get(newUser.UserRoleId).Name.split(' - ');
                    String newCode = items[0].trim().toUpperCase();
                    
                    items = oldUser == null || !roles.containsKey(oldUser.UserRoleId) ? null : roles.get(oldUser.UserRoleId).Name.split(' - ');
                    String oldCode = items == null || items.size() < 1 ? null : items[0].trim().toUpperCase();
                    
                    if (!String.isEmpty(newCode)) {
                        AggregateResult sectorisation = sectorisations.get(newCode);
                        
                        if (sectorisation != null) {
                            String urlFB = '';
                            if (newCode.startsWithIgnoreCase('MAG')) {
                                newUser.codeMagasin__c = String.valueOf(sectorisation.get('codeMagasin__c'));
                                newUser.libelleMagasin__c = String.valueOf(sectorisation.get('libelleMagasin__c'));
                                newUser.codeDV__c = String.valueOf(sectorisation.get('codeDV__c'));
                                newUser.libelleDV__c = String.valueOf(sectorisation.get('libelleDV__c'));
                                newUser.codeDR__c = String.valueOf(sectorisation.get('codeRegion__c'));
                                newUser.libelleDR__c = String.valueOf(sectorisation.get('libelleRegion__c'));
                                newUser.codeDepot__c = String.valueOf(sectorisation.get('codeDepot__c'));
                                newUser.libelleDepot__c = String.valueOf(sectorisation.get('libelleDepot__c'));
                                newUser.codeDS__c = String.valueOf(sectorisation.get('codeDS__c'));
                                newUser.libelleDS__c = String.valueOf(sectorisation.get('libelleDS__c'));
                                
                                if (publications != null && publications.containsKey(newUser.codeMagasin__c)) {
                                    newUser.URLFacebook__c = publications.get(newUser.codeMagasin__c)[0].urls__c;
                                }
                            } else if (newCode.startsWithIgnoreCase('DV')) {
                                newUser.codeDV__c = String.valueOf(sectorisation.get('codeDV__c'));
                                newUser.libelleDV__c = String.valueOf(sectorisation.get('libelleDV__c'));
                                newUser.codeDR__c = String.valueOf(sectorisation.get('codeRegion__c'));
                                newUser.libelleDR__c = String.valueOf(sectorisation.get('libelleRegion__c'));
                                
                                if (publications != null && publications.containsKey(newUser.codeDV__c)) {
                                    for(PublicationFacebook__c pfb : publications.get(newUser.codeDV__c)) {
                                        urlFB += pfb.urls__c + URLFACEBOOK_SEPARATOR;
                                    }
                                    newUser.URLFacebook__c = urlFB.left(urlFB.length()-1);
                                }
                            } else if (newCode.startsWithIgnoreCase('RV')) {
                                newUser.codeDR__c = String.valueOf(sectorisation.get('codeRegion__c'));
                                newUser.libelleDR__c = String.valueOf(sectorisation.get('libelleRegion__c'));
                                
                                if (publications != null && publications.containsKey(newUser.codeDR__c)) {
                                    for(PublicationFacebook__c pfb : publications.get(newUser.codeDR__c)) {
                                        urlFB += pfb.urls__c + URLFACEBOOK_SEPARATOR;
                                    }
                                    newUser.URLFacebook__c = urlFB.left(urlFB.length()-1);
                                }
                            }
                        }
                        
                        /***** Affectation manager du vendeur *****/
                        User manager = TerritoryUtils.getManager(newUser);
                        newUser.managerId = (manager == null || manager.id == newUser.id) ? null : manager.id; // Le manager d'un utilisateur ne peut pas être lui-même
                    }
                }
                // Reseau K par K ==> Affectation publication Facebook
                else if (role != null && 'K par K'.equals(role.name)) {
                    newUser.URLFacebook__c = urlFBForMarketing;
                }
                
                // B.2 - Mise à jour de l'autorisation de publication
                if(oldUser != null && !String.isNotBlank(oldUser.URLFacebook__c) && String.isNotBlank(newUser.URLFacebook__c)) {
                    newUser.publicationFacebook__c = true;
                } else if(String.isBlank(newUser.URLFacebook__c)) {
                    newUser.publicationFacebook__c = false;
                }
                
                // B.3 - Réaffectation du manager des subordonnés
                if (Trigger.isInsert || newUser.userRoleId != oldUser.userRoleId || newUser.isActive != oldUser.isActive) {
                    if (roles.containsKey(newUser.userRoleId)) {
                        parentRoleIds.add(newUser.userRoleId);
                    }
                    if (oldUser != null && roles.containsKey(oldUser.userRoleId)) {
                        parentRoleIds.add(oldUser.userRoleId);
                    }
                }
            }
        }
        
        // B.4 - Réaffectation du manager des subordonnés
        if (!parentRoleIds.isEmpty()) {
            Map<Id, UserRole> roleIds = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole WHERE ParentRoleId IN :parentRoleIds]);            
            if (!roleIds.isEmpty()) {
                // Fonction asynchrone si non batch
                if(System.isBatch() || System.isFuture() || Test.isRunningTest()) {
                    defineManagers(roleIds.keySet(), newUsers);
                } else {
                    defineManagersAsync(roleIds.keySet());
                }
            }
        }
        System.debug('### FIN TR020_User.applyUpdateRules');
    }
    
    /**
    * @description Règles asynchrone de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyAsyncUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR020_User.applyAsyncUpdateRules');
        // A - Initialisation des données intermédiaires 
        List<User> newUsers = (List<User>)Trigger.new;
        Map<Id, User> oldUsers = (Map<Id, User>)Trigger.oldMap;
        Boolean geoGoogleEnabled = PropertiesUtils.getBooleanValue('google.geocoder.enabled', false);
        Boolean geoDQEEnabled = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false);
        List<User> asyncUsers = new List<User>();
        
        /* UR001_K2_User__Geocodage */
        // Mise à jour des coordonnées de l'adresse de l'utilisateur
        if (geoGoogleEnabled || geoDQEEnabled || Test.isRunningTest()) {
            for (User newUser : newUsers) {
                if (!AlreadyUsed.isUsed('TR020_User.applyAsyncUpdateRules', newUser.id)) {
                    User oldUser = Trigger.isInsert ? null : oldUsers.get(newUser.id);
                    
                    Boolean adresseGeocodable = String.isNotBlank(newUser.rue__c) || String.isNotBlank(newUser.codePostal__c) || String.isNotBlank(newUser.ville__c);
                    Boolean adresseModifiee = Trigger.isInsert ? true
                        : (newUser.rue__c != oldUser.rue__c || newUser.codePostal__c != oldUser.codePostal__c || newUser.ville__c != oldUser.ville__c);
                            
                    System.debug('[DEBUG] User = ' + newUser.id + ' : ' + newUser.userName + ' (Geocodable = ' + adresseGeocodable + ', modifiée = ' + adresseModifiee + ')');
                    if (adresseGeocodable && adresseModifiee) {
                        asyncUsers.add(newUser);
                    }
                }
            }
        }
        
        // B - Application des règles de mise à jour 
        if ((geoGoogleEnabled || geoDQEEnabled) && !asyncUsers.isEmpty()) {
            GeoUtils.updateUsers(asyncUsers);
        }
        
        System.debug('### FIN TR020_User.applyAsyncUpdateRules');
    }
    
    /**
    * @description Fonction synchrone pour définir le responsable de l'utilisateur selon son rôle
    * @param ids Ids des utilisateurs à traiter
    */
    private static void defineManagers(Set<ID> ids, List<User> newUsers) {
        System.debug('### DEBUT TR020_User.defineManagers');

        // if(!Test.isRunningTest()){ >>> FGO, le 30/03/2023 
            List<User> users = [SELECT Id, ManagerId, UserRoleId
                                FROM User
                                WHERE IsActive = true
                                AND UserRoleId IN :ids AND Id NOT IN :newUsers];
            for (User user : users) {
                User manager = TerritoryUtils.getManager(user);
                user.ManagerId = (manager == null || manager.Id == user.Id) ? null : manager.Id;
            }
            
            update users;
        // } >>> FGO, le 30/03/2023 
        System.debug('### FIN TR020_User.defineManagers');
    }
    
    /**
    * @description Fonction asynchrone pour définir le responsable de l'utilisateur selon son rôle
    * @param ids Ids des utilisateurs à traiter
    */
    @future(callout=false)
    private static void defineManagersAsync(Set<ID> ids) {
        System.debug('### DEBUT TR020_User.defineManagersAsync');
        defineManagers(ids, new List<User>());
        System.debug('### FIN TR020_User.defineManagersAsync');
    }
    
    /**
    * @description Construit la MAP des URLs des pages Facebook selon le code magasin, code DV ou code DR
    * @param code Code du magasin, DV ou DR pour insertion dans la MAP
    * @param publiFacebookMap MAP contenant les différentes URLs
    * @param pfb Objet contenant les informations de publication facebook lié au code
    * @return Map<String,List<PublicationFacebook__c>> Map contenant la liste des URLS par code magasin, code DV et code DR
    */
    private static Map<String,List<PublicationFacebook__c>> constructURLFacebookMap(String code, Map<String,List<PublicationFacebook__c>> publiFacebookMap, PublicationFacebook__c pfb) {
        List<PublicationFacebook__c> publiFacebookTmp = new List<PublicationFacebook__c>();
        if(publiFacebookMap.get(code) == null) {
            publiFacebookTmp = new List<PublicationFacebook__c>();
        } else {
            publiFacebookTmp = publiFacebookMap.get(code);
        }
        publiFacebookTmp.add(pfb);
        publiFacebookMap.put(code,publiFacebookTmp);
        return publiFacebookMap;
    }
}