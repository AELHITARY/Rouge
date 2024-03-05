//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : DAL_Cartographie
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/07/2022
//-- Version     : 1.12
//-- * 1.12 : Ajout du statut FSL En cours
//-- * 1.11 : RQM-175 : RDV FSL affichés aux vendeurs
//-- * 1.10 - RQM-113 : Ajout des constantes pour les nouveaux rôles/profils
//-- * 1.9 - Mise à jour pour WGS84
//-- * 1.8 : CRM-988 : Evolution de la cartographie pour secteur sans polygones
//-- --------------------------------------------------------------------------------- --
public with sharing class DAL_Cartographie {
    public static final integer mapDotLimits = Constants.MAP_DOT_LIMITS;

    /**
    * @description Récupération des noms des fichiers contenant les points géographique pour les magasins
    * @param codeMag Liste des codes magasins
    * @return Set<String> Liste des noms des fichiers (Attachment)
    */
    public static Set<String> attsParentIds (Set<String> codeMag) {
        Set<String> ret = new Set<String> ();
        try {
            for (Attachment a : [SELECT Id, Body, Name FROM Attachment WHERE ParentId IN (SELECT Id FROM Cartographie__c WHERE idTiers__c  = 'KPK-Vente') 
                                    AND Name IN :codeMag ORDER BY CreatedDate DESC])
                ret.add(a.Name);
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
        return ret;
    }
    
    /**
    * @description Récupération du fichier contenant les coordonées en X et Y du secteur (magasin)
    * @param codeMagasin Code du secteur (magasin)
    * @return Attachment Objet contenant les points cartographique (WGS84) du secteur
    */
    public static Attachment getAttachmentByMag (String codeMagasin) {
        Attachment pj = null;
        try {
            List<Attachment> cartographie = [SELECT Id, Body, Name FROM Attachment WHERE ParentId IN (SELECT Id FROM Cartographie__c WHERE idTiers__c  = 'KPK-Vente') 
                                                AND name = :codeMagasin ORDER BY CreatedDate DESC];
            pj = (cartographie.isEmpty()) ? null : cartographie.get(0);
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
        return pj;
    }

    /**
    * @description Récupération de l'enregistrement Sectorisation selon le nom du magasin
    * @param sectorName Nom du secteur (magasin)
    * @return Sectorisation__c Enregistrement contenant les informations du magasins
    */
    public static Sectorisation__c getSectorByName(String sectorName) {
        List<Sectorisation__c> sectorisations = SchemaUtils.executeQuery('Sectorisation__c', 'LibelleMagasin__c', sectorName);
        if(!sectorisations.isEmpty())
            return sectorisations.get(0); //retourne les details sur le secteur selectionne (magasin)
        else
            return null;
    }

    /**
    * @description Récupération des chantiers avec contrats du secteur choisi
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getChantierAvecContratsList(string codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();
        // Récupération des chantiers présent dans le secteur avec contrats
        String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
        // Transfer du géocodage de Lambert 2 en WGS84
        /*Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
        latlong.transform();
        Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
        latlong2.transform();  */
        for(Chantier__c chantier : [SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c, OwnerId, Owner.Name FROM Chantier__c
                                        WHERE codeMagasinTechnique__c IN :codeMagasins AND interditProspection__c = false
                                        AND (Localisation__Longitude__s = NULL
                                            OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                            AND (nbContratsResilies__c>0 OR nbContratsVendus__c>0)
                                        LIMIT :mapDotLimits]) {
            objectToReturn.add(new Utils_Cartographie.DotMap(chantier));
        }
        return objectToReturn;
    }

    /**
    * @description Récupération des chantiers sans contrats du secteur choisi
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getChantierSansContratsList(string codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();
        // Récupération des chantiers présent dans le secteur sans contrats
        String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
        // Transfer du géocodage de Lambert 2 en WGS84
        /*Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
        latlong.transform();
        Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
        latlong2.transform(); */ 
        for(Chantier__c chantier : [SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c, OwnerId, Owner.Name FROM Chantier__c
                                        WHERE codeMagasinTechnique__c IN :codeMagasins AND interditProspection__c = false
                                            AND (Localisation__Longitude__s = NULL
                                                OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                    AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                            AND (nbContratsResilies__c=0 OR nbContratsResilies__c = NULL)
                                            AND (nbContratsVendus__c=0 OR nbContratsVendus__c = NULL)
                                        LIMIT :mapDotLimits]) {
            objectToReturn.add(new Utils_Cartographie.DotMap(chantier));
        }
        return objectToReturn;
    }

    /**
    * @description Récupération générique des chantiers
    * @param chantierList Liste des Ids des chantiers
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getChantierRDV(Set<String> chantierList, string codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();
        if(!chantierList.isEmpty()) {
            // Récupération des chantiers possédant un contrat et présent dans le secteur
            String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
            // Transfer du géocodage de Lambert 2 en WGS84
           /* Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
            latlong.transform();
            Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
            latlong2.transform();*/  
            for(Chantier__c chantier : [SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c, OwnerId, Owner.Name FROM Chantier__c
                                            WHERE codeMagasinTechnique__c IN :codeMagasins AND Id IN :chantierList AND interditProspection__c = false
                                            AND (Localisation__Longitude__s = NULL
                                                OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                    AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                        LIMIT :mapDotLimits]) {
                objectToReturn.add(new Utils_Cartographie.DotMap(chantier));
            }
        }
        return objectToReturn;
    }

    /**
    * @description Récupération des chantiers ayant un contrat en SAV dans le secteur choisi
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getSAVList(string codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        Set<String> chantierWithContratSAV = new Set<String>();
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();

        // Récupération des chantiers des contrats
        for(KContrat__c contrat : [SELECT Id, chantier__c FROM KContrat__c WHERE libelleStatutContrat__c = 'Contrats en SAV' ])
            chantierWithContratSAV.add(contrat.chantier__c);

        objectToReturn = getChantierRDV(chantierWithContratSAV, codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min);
        return objectToReturn;
    }

    /**
    * @description Récupération des chantiers ayant un contrat selon leur type, le jour et selon le secteur choisi
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getContratRDVbyTypeList(string codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min, string ptype, Date pDate) {
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();
        List<ServiceAppointment> contrats = new List<ServiceAppointment>();
        Set<String> chantierWithContrat = new Set<String>();
        Datetime dtToday = DateTime.newInstance(pDate.year(), pDate.month(), pDate.day(), 0, 0, 0);
        Datetime dtTommorrow = DateTime.newInstance(pDate.year(), pDate.month(), pDate.day(), 23, 59, 59);

        // Récupération des contrat selon les types et la date
        if(ptype.equalsIgnoreCase('Metrage')){
            contrats =  [SELECT Id, chantier__c FROM ServiceAppointment WHERE ((SchedStartTime > :dtToday AND SchedStartTime < :dtTommorrow)
                                OR (SchedEndTime > :dtToday AND SchedEndTime < :dtTommorrow)
                                OR (SchedStartTime < :dtToday AND SchedEndTime > :dtTommorrow))
                            AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                            AND (WorkType.Name = :Constants.WORKTYPE_METRAGE OR WorkType.Name = :Constants.ACTIVITY_TYPE_CONTROL)];
        } else if(ptype.equalsIgnoreCase('Installation')){
            contrats =  [SELECT Id, chantier__c FROM ServiceAppointment WHERE ((SchedStartTime > :dtToday AND SchedStartTime < :dtTommorrow)
                                OR (SchedEndTime > :dtToday AND SchedEndTime < :dtTommorrow)
                                OR (SchedStartTime < :dtToday AND SchedEndTime > :dtTommorrow))
                            AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                            AND (WorkType.Name = :Constants.WORKTYPE_INSTALLATION OR WorkType.Name = :Constants.WORKTYPE_INSTALLATION_ECI OR WorkType.Name = :Constants.ACTIVITY_TYPE_INTERVENTION)];
        } else if(ptype.equalsIgnoreCase('Intervention SAV')){
            contrats =  [SELECT Id, chantier__c FROM ServiceAppointment WHERE ((SchedStartTime > :dtToday AND SchedStartTime < :dtTommorrow)
                                OR (SchedEndTime > :dtToday AND SchedEndTime < :dtTommorrow)
                                OR (SchedStartTime < :dtToday AND SchedEndTime > :dtTommorrow))
                            AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                            AND (WorkType.Name = :Constants.WORKTYPE_INTERVENTION_SAV OR WorkType.Name = :Constants.WORKTYPE_INTERVENTION_SAV_ECI OR WorkType.Name = :Constants.ACTIVITY_TYPE_DIAGNOSTIC)];
        }

        // Récupération des chantiers des contrats
        for(ServiceAppointment contrat : contrats) chantierWithContrat.add(contrat.chantier__c);
        objectToReturn = getChantierRDV(chantierWithContrat, codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min);
        return objectToReturn;
    }

    /**
    * @description Récupération des chantiers ayant un RDV R1, R2 ou R+ sur les projets du chantiers selon leur type, le jour et selon le secteur choisi
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getChantiersWithRDVList(String codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min, String rdvType, Date eventDate, String user, String userProfile) {
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();
        Set<String> projetsId = new Set<String>();

        // Transfer du géocodage de Lambert 2 en WGS84
        /*Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
        latlong.transform();
        Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
        latlong2.transform();  */

        // Récupération des RDV
        Date eventStartDate = (eventDate == system.today()) ? system.today() : system.today().addDays(1);
        List<Event> eventsList = new List<Event>();
        if(userProfile.startsWith(Constants.PROFIL_Vendeur)) {
            eventsList = [SELECT Id, WhatId, ActivityDate, Owner.Name, Type 
                                  FROM Event 
                                  WHERE Type = :rdvType    
                                    AND (RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT)
                                        OR RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT))                                 
                                    AND ActivityDate >= :eventStartDate AND ActivityDate <= :eventDate
                                    AND isDeleted = false AND isArchived = false
                                    AND ownerId = :user];
        } else {
            eventsList = [SELECT Id, WhatId, ActivityDate, Owner.Name, Type 
                                  FROM Event 
                                  WHERE Type = :rdvType    
                                    AND (RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT)
                                        OR RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT))                                 
                                    AND ActivityDate >= :eventStartDate AND ActivityDate <= :eventDate
                                    AND isDeleted = false AND isArchived = false
                                    AND ownerId IN (SELECT id FROM User WHERE isActive = TRUE AND codeMagasin__c = :codeMagasin)];
        }
        // Récupération des projets et activités
        for(Event event : eventsList) {
            if(event.WhatId != null) {
                projetsId.add(event.WhatId);
            }
        }
        // Récupération des projets
        Map<String, Opportunity> projetsMap = new Map<String, Opportunity>([SELECT Id, chantier__c, LeadSource, account.Name FROM Opportunity WHERE Id IN :projetsId]);
        // Récupération des chantiers et ajout dans la liste de retour
        Map<String, Chantier__c> chantiersMap = new Map<String, Chantier__c>([SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c, OwnerId, Owner.Name
                                                                              FROM Chantier__c 
                                                                              WHERE Id IN (SELECT chantier__c FROM Opportunity WHERE Id IN :projetsMap.keySet())
                                                                                AND (Localisation__Longitude__s = NULL
                                                                                    OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                                                        AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                                                                LIMIT :mapDotLimits]);
        
        // Construction liste de retour
        if(!chantiersMap.values().isEmpty()) {
            for(Event event : eventsList) {
                if(event.WhatId != null) {
                    Opportunity projet = projetsMap.get(event.WhatId);
                    Chantier__c chantier = (projet != null) ? chantiersMap.get(projet.chantier__c) : null;
                    if(chantier != null && projet != null) objectToReturn.add(new Utils_Cartographie.DotMap(event, projet, chantier));
                }
            }
        }

        return objectToReturn;
    }

    /**
    * @description Récupération des chantiers ayant un RDV prospection sur les projets du chantiers selon leur type, le jour et selon le secteur choisi
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param eventDate Date pour la recherche des RDV de prospection
    * @param feuilleRoute True si la recherche s'effectue pour la feuille de route sinon false
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getRDVProspectionList(String codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min, Date eventDate, Boolean feuilleRoute, String user, String userProfile) {
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();
        List<Event> eventsList = new List<Event>();
        Set<String> objectId = new Set<String>();
        Map<String, String> eventOwnerMap = new Map<String, String>();
        Date eventStartDate = null;

        // Transfer du géocodage de Lambert 2 en WGS84
        /*Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
        latlong.transform();
        Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
        latlong2.transform();*/

        // Date de début selon type
        if(feuilleRoute)
            eventStartDate = system.today();
        else
            eventStartDate = (eventDate == system.today()) ? system.today() : system.today().addDays(1);

        // Récupération des prospections et traitement
        if(userProfile == Constants.PROFIL_Vendeur){
            eventsList = [SELECT Id, Type, rue__c, ville__c, codePostal__c, Localisation__Longitude__s, Localisation__Latitude__s, OwnerId, ActivityDate, WhatId , Owner.Name
                          FROM Event 
                          WHERE RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT) 
                            AND isDeleted = false AND isArchived = false
                            AND ActivityDate >= :eventStartDate AND ActivityDate <= :eventDate
                            AND ownerId = :user];
        } else {
            eventsList = [SELECT Id, Type, rue__c, ville__c, codePostal__c, Localisation__Longitude__s, Localisation__Latitude__s, OwnerId, ActivityDate, WhatId , Owner.Name
                          FROM Event 
                          WHERE RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT) 
                            AND isDeleted = false AND isArchived = false
                            AND ActivityDate >= :eventStartDate AND ActivityDate <= :eventDate
                            AND ownerId IN (SELECT id FROM User WHERE isActive = TRUE AND codeMagasin__c = :codeMagasin)];
        }
        /* <<< F.G., le 05/04/2016 - Certains RDV commerciaux apparaissent sur plusieurs magasins au lieu du seul magasin du vendeur -> Filtrage au niveau des utilisateurs des événements plutôt que des chantiers */
        for(Event event : eventsList) {
            // Vérification si dans le secteur
            if(event.Localisation__Latitude__s >= latitude_min && event.Localisation__Latitude__s <= latitude_max
                 && ((event.Localisation__Longitude__s >= longitude_min && event.Localisation__Longitude__s <= longitude_max) || (event.Localisation__Longitude__s >= longitude_max && event.Localisation__Longitude__s <= longitude_min))) {
                    if(feuilleRoute)
                        eventOwnerMap.put(event.Id, event.OwnerId);
                    else
                        objectToReturn.add(new Utils_Cartographie.DotMap(event));
            } else {
                if(event.WhatId != null)
                    objectId.add(event.WhatId);
            }
        }
        // Récupération des utilisateurs (Seulement pour la feuille de route)
        if(feuilleRoute) {
            Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, CodeMagasin__c FROM User WHERE Id IN :eventOwnerMap.values()]);
            for(Event event : eventsList) {
                String ownerId = eventOwnerMap.get(event.Id);
                if(ownerId != null) {
                    if(usersMap.get(ownerId).CodeMagasin__c == codeMagasin)
                        objectToReturn.add(new Utils_Cartographie.DotMap(event));
                }
            }
        }
        // Récupération des projets
        Map<String, Opportunity> projetsMap = new Map<String, Opportunity>([SELECT Id, chantier__c, LeadSource, account.Name FROM Opportunity WHERE Id IN :objectId]);
        // Récupération des comptes et chantiers et ajout dans la liste de retour
        Map<String, Account> accountsMap = new Map<String, Account>([SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c, OwnerId, Owner.Name
                                                                     FROM Account 
                                                                     WHERE Id IN :objectId
                                                                        AND (Localisation__Longitude__s = NULL
                                                                            OR (Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max
                                                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                                                        LIMIT :mapDotLimits]);
        Map<String, Chantier__c> chantiersMap = new Map<String, Chantier__c>([SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c, OwnerId, Owner.Name
                                                                              FROM Chantier__c 
                                                                              WHERE Id IN (SELECT chantier__c FROM Opportunity WHERE Id IN :objectId)
                                                                                AND (Localisation__Longitude__s = NULL
                                                                                    OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                                                        AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                                                                LIMIT :mapDotLimits]);

        // Construction liste de retour
        if(!accountsMap.values().isEmpty() || !chantiersMap.values().isEmpty()) {
            for(Event event : eventsList) {
                if(event.WhatId != null) {
                    // Projet
                    if(String.valueOf(event.WhatId).startsWith('006')) {
                        Opportunity projet = projetsMap.get(event.WhatId);
                        Chantier__c chantier = (projet != null) ? chantiersMap.get(projet.chantier__c) : null;
                        if(chantier != null && projet != null) objectToReturn.add(new Utils_Cartographie.DotMap(event, projet, chantier));
                    }
                    // Chantier
                    if(String.valueOf(event.WhatId).startsWith('a08')) {
                        Chantier__c chantier = chantiersMap.get(event.WhatId);
                        if(chantier != null) objectToReturn.add(new Utils_Cartographie.DotMap(event, chantier));
                    }
                    // Compte
                    if(String.valueOf(event.WhatId).startsWith('001')) {
                        Account compte = accountsMap.get(event.WhatId);
                        if(compte != null) objectToReturn.add(new Utils_Cartographie.DotMap(event, compte));
                    }
                }
            }
        }

        return objectToReturn;
    }

    /**
    * @description Récupération des chantiers en interdit de prospection du secteur choisi
    * @param veName Nom du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return Set<Utils_Cartographie.DotMap> Liste de l'objet DotMap contenant les informations des chantiers à afficher sur la carte
    */
    public static Set<Utils_Cartographie.DotMap> getInterditDeProspectionList_Chantier(string veName, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        Set<Utils_Cartographie.DotMap> objectToReturn = new Set<Utils_Cartographie.DotMap>();
        String[] codeMagasins = TerritoryUtils.getMagasinsKStore(veName);
        // Transfer du géocodage de Lambert 2 en WGS84
        /*Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
        latlong.transform();
        Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
        latlong2.transform();  */
        for(Chantier__c chantier : [SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c, OwnerId, Owner.Name FROM Chantier__c
                                        WHERE codeMagasinTechnique__c IN :codeMagasins AND interditProspection__c = true
                                        AND (Localisation__Longitude__s = NULL
                                            OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                        LIMIT :mapDotLimits]) {
            objectToReturn.add(new Utils_Cartographie.DotMap(chantier));
        }
        return objectToReturn;
    }

    /**
    * @description Récupération des vendeurs du secteur choisi. Retourne les vendeurs selon type d'utilisateur courant
    * @param codeMagasin Code du secteur (magasin)
    * @param userId Id de l'utilisateur courant
    * @return List<User> Liste des vendeurs du secteur (Administrateur) ou du vendeur sélectionné (Vendeur)
    */
    public static List<User> getVendeursList(String codeMagasin, String userId) {
        List<User> userToReturn = new List<User>();
        // Si Code Magasin est null, on récupère celui de l'utilisateur
        if(codeMagasin == null) {
            List<User> users = [SELECT CodeMagasin__c  FROM User WHERE Id = :userId LIMIT 1];
            codeMagasin = users[0].CodeMagasin__c;
        }
        // Récupère les informations de l'utilisateur courant
        UserContext context = UserContext.getContext(userId);
        if(context.isSaleUser()) {
            // Si c'est un Vendeur, récupère seulement l'utilisateur
            if(context.getProfile().name == Constants.PROFIL_Vendeur) {
                // Affiche seulement si adresse et magasin
                if(context.getUser().CodeMagasin__c == codeMagasin)
                    userToReturn.add(context.getUser());
            }
            // Si c'est un RVJ, on récupère les vendeurs du magasin et le RVJ
            /*else if (context.getProfile().name.containsIgnoreCase('K/K - RVJ')) {
                userToReturn.add(context.getUser());
                List<User> allVendeursList = [SELECT Id, Name, CodeMagasin__c, FirstName, LastName, rue__c, ville__c, codePostal__c,
                                                localisationLatitude__c, localisationLongitude__c FROM User
                                                WHERE CodeMagasin__c = :codeMagasin
                                                AND IsActive = true AND Profile.Name = :Constants.PROFIL_Vendeur ORDER BY Profile.Name, LastName, FirstName ASC];
                userToReturn.addAll(allVendeursList);
                // Si c'est un RV, récupère les vendeurs du magasin
            } else {*/
                List<User> users = [SELECT Id, Name, CodeMagasin__c, FirstName, LastName, rue__c, ville__c, codePostal__c,
                                    localisationLatitude__c, localisationLongitude__c
                                    FROM User WHERE CodeMagasin__c = :codeMagasin AND IsActive = true ORDER BY Profile.Name, LastName, FirstName ASC];
                for(User vendeur : users){
                    userToReturn.add(vendeur);
                }
            //}
        } else if(context.getProfile().name.containsIgnoreCase('Administrateur')) {
            // Si c'est un Administrateur, récupère les vendeurs du magasin
            List<User> users = [SELECT Id, Name, CodeMagasin__c, FirstName, LastName, rue__c, ville__c, codePostal__c,
                                localisationLatitude__c, localisationLongitude__c
                                FROM User WHERE CodeMagasin__c = :codeMagasin AND IsActive = true ORDER BY Profile.Name, LastName, FirstName ASC];
            for(User vendeur : users){
                userToReturn.add(vendeur);
            }
        }
        return userToReturn;
    }
}