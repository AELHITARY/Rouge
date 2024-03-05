//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : DAL_Feuillederoute
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/07/2022
//-- Version     : 1.8
//-- * 1.8 : Ajout du statut FSL En cours
//-- * 1.7 : Gestion des recouvrements d'iris pour les K-Store
//-- * 1.6 : KPKCRM_RQM-40 : Cohérence entre les données affichées par Cartographie et Feuille de route
//-- --------------------------------------------------------------------------------- --
public with sharing class DAL_Feuillederoute {
    public static final Integer fdrDotLimits = Constants.FDR_CHANTIER_LIMITS;

    /**
    * @description FEUILLE DE ROUTE PDF - Récupération des contrats avec chantiers par vendeur d'un magasin
    * @param userList Liste des vendeurs du secteur du PDF
    * @param codeMagasin Code du secteur (magasin)
    * @return List<ServiceAppointment> Liste des contrats
    */
    public static List<ServiceAppointment> getContratsByUserId(List<User> userList, String codeMagasin) {
        try {
            // Récupération des contrats
            List<String> codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
            List<ServiceAppointment> contrats = [SELECT Id, ContratK__c, ContratK__r.datesignature__c, ContratK__r.LastModifiedById, ContratK__r.LastModifiedBy.Name, 
                                                 customerOrder__c, customerOrder__r.EffectiveDate, customerOrder__r.LastModifiedById, customerOrder__r.LastModifiedBy.Name,
                                                 Chantier__c, chantier__r.OwnerId, WorkTypeId, WorkType.Name, SchedStartTime,
                                                 Chantier__r.Localisation__Latitude__s, chantier__r.Localisation__Longitude__s,
                                                 Chantier__r.interditProspection__c, Chantier__r.Id, Chantier__r.Name, 
                                                 Chantier__r.nomProprietaires__c, Chantier__r.nomLocataires__c, Chantier__r.nomOccupants__c,
                                                 Chantier__r.prenomProprietaires__c, Chantier__r.prenomLocataires__c, Chantier__r.prenomOccupants__c,
                                                 Chantier__r.locataire__c, Chantier__r.telephoneDomicileLocataires__c, Chantier__r.telephoneMobileLocataires__c, Chantier__r.locataire__r.name,
                                                 Chantier__r.proprietaire__c, Chantier__r.proprietaire__r.name, Chantier__r.telephoneDomicileProprietaires__c, Chantier__r.telephoneMobileProprietaires__c,
                                                 Chantier__r.occupant__c, Chantier__r.telephoneDomicileOccupants__c, Chantier__r.telephoneMobileOccupants__c, Chantier__r.occupant__r.name,
                                                 Chantier__r.autreProprietaire__c, Chantier__r.autreProprietaire__r.name,
                                                 Chantier__r.autreLocataire__c, Chantier__r.autreOccupant__c, Chantier__r.autreOccupant__r.name, Chantier__r.autreLocataire__r.name,
                                                 Chantier__r.codePostal__c , Chantier__r.ville__c, Chantier__r.rue__c,
                                                 Chantier__r.autreTelephoneLocataires__c, Chantier__r.autreTelephoneOccupants__c, Chantier__r.autreTelephoneProprietaires__c,
                                                 ContratK__r.produits__c, ContratK__r.derniereInterventionSAV__c, ContratK__r.nbSAVTotal__c, ContratK__r.nombreInterventionsSAV__c,
                                                 ContratK__r.cartoMetrageDuJour__c, ContratK__r.cartoInstallationDuJour__c, ContratK__r.cartoInterventionSAVDuJour__c
                                          FROM ServiceAppointment 
                                          WHERE chantier__c IN (SELECT Id FROM Chantier__c WHERE codeMagasinTechnique__c IN :codeMagasins AND OwnerId IN :userList)
                                          ORDER BY LastModifiedDate DESC];

            return contrats;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description FEUILLE DE ROUTE PDF - Récupération des contrats en pose, métrage ou intervention du jour pour des vendeurs
    * @param userList Liste des vendeurs du secteur du PDF
    * @param codeMagasin Code du secteur (magasin)
    * @param pDate Date pour rechercher les RDV 
    * @return List<ServiceAppointment> Liste des contrats
    */
    public static List<ServiceAppointment> getContratRDVUsers(List<User> userList, String codeMagasin, Date pDate) {
        Map<Id, ServiceAppointment> contratWithChantiers = new Map<Id, ServiceAppointment> (getContratsByUserId(userList, codeMagasin));

        List<ServiceAppointment> rdvs = [SELECT Id, WorkType.Name, SchedStartTime
                                  FROM ServiceAppointment 
                                  WHERE Id IN :contratWithChantiers.keySet() 
                                    AND SchedStartTime = :pDate
                                    AND (WorkType.Name = :Constants.WORKTYPE_METRAGE OR WorkType.Name = :Constants.WORKTYPE_INSTALLATION OR WorkType.Name = :Constants.WORKTYPE_INTERVENTION_SAV
                                        OR WorkType.Name = :Constants.ACTIVITY_TYPE_CONTROL OR WorkType.Name = :Constants.ACTIVITY_TYPE_INTERVENTION OR WorkType.Name = :Constants.ACTIVITY_TYPE_DIAGNOSTIC) 
                                    AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                                  LIMIT :fdrDotLimits];
                                  
      System.debug('rdvs '+rdvs );

        List<ServiceAppointment> res = new List<ServiceAppointment>{};
        for (ServiceAppointment rdv : rdvs) {
            if (contratWithChantiers.containsKey(rdv.Id))
                res.add (contratWithChantiers.get(rdv.Id));
        }
        return res;
    }

    /**
    * @description FEUILLE DE ROUTE PDF - Récupération du nombre de RDV de service en pose, métrage, intervention et événements du jour pour des vendeurs
    * @param userList Liste des vendeurs du secteur du PDF
    * @param codeMagasin Code du secteur (magasin)
    * @param pDate Date pour rechercher les RDV 
    * @return Integer Nombre de RDV de service et de RDV
    */
    public static Integer getContratsRDVSizeUsers(List<User> userList, String codeMagasin, Date pDate) {
        List<ServiceAppointment> contratsList = new List<ServiceAppointment>();
        List<Event> eventsList = new List<Event>();
        List<Chantier__c> chantierList = new List<Chantier__c>();
        
        // Récupération des contrats
        String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
        contratsList = [SELECT Id 
                        FROM ServiceAppointment 
                        WHERE Chantier__c IN (SELECT Id FROM Chantier__c WHERE codeMagasinTechnique__c IN :codeMagasins AND OwnerId IN :userList)
                          AND SchedStartTime = :pDate
                          AND (WorkType.Name = :Constants.WORKTYPE_METRAGE OR WorkType.Name = :Constants.WORKTYPE_INSTALLATION OR WorkType.Name = :Constants.WORKTYPE_INTERVENTION_SAV
                                OR WorkType.Name = :Constants.ACTIVITY_TYPE_CONTROL OR WorkType.Name = :Constants.ACTIVITY_TYPE_INTERVENTION OR WorkType.Name = :Constants.ACTIVITY_TYPE_DIAGNOSTIC) 
                          AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                        LIMIT :fdrDotLimits];
                        
        // Récupération des RDV
        eventsList = [SELECT Id FROM Event  WHERE ((RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT) AND Localisation__Longitude__s!=null)
                        OR (RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT))) 
                        AND OwnerId IN :userList AND ActivityDate = :pDate AND isDeleted = false AND isArchived = false];
        
        Integer nbContrats = contratsList.size() + eventsList.size();
        return nbContrats;
    }

    /**
    * @description Récupération des contrats avec chantiers par secteur
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return List<ServiceAppointment> Liste des contrats avec chantiers dans le secteur
    */
    public static List<ServiceAppointment> getContratsBySector(String codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        try {
            // Récupération des chantiers
            String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
            /*// Transfer du géocodage de Lambert 2 en WGS84
            Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
            latlong.transform();
            Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
            latlong2.transform();*/
            List<Chantier__c> chantiers = [SELECT Id 
                                           FROM Chantier__c
                                           WHERE codeMagasinTechnique__c IN :codeMagasins
                                            AND ((((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))];

            // Récupération des contrats
            List<ServiceAppointment> contrats = [SELECT Id, ContratK__c, ContratK__r.datesignature__c, ContratK__r.LastModifiedById, ContratK__r.LastModifiedBy.Name, 
                                                customerOrder__c, customerOrder__r.EffectiveDate, customerOrder__r.LastModifiedById, customerOrder__r.LastModifiedBy.Name,
                                                Chantier__c, Chantier__r.OwnerId, WorkType.Name, SchedStartTime,
                                                Chantier__r.Localisation__Latitude__s, chantier__r.Localisation__Longitude__s,
                                                Chantier__r.interditProspection__c, Chantier__r.Id, Chantier__r.Name,
                                                Chantier__r.nomProprietaires__c, Chantier__r.nomLocataires__c, Chantier__r.nomOccupants__c,
                                                Chantier__r.prenomProprietaires__c, Chantier__r.prenomLocataires__c, Chantier__r.prenomOccupants__c,
                                                Chantier__r.locataire__c, Chantier__r.telephoneDomicileLocataires__c, Chantier__r.telephoneMobileLocataires__c, Chantier__r.locataire__r.name,
                                                Chantier__r.proprietaire__c, Chantier__r.proprietaire__r.name, Chantier__r.telephoneDomicileProprietaires__c, Chantier__r.telephoneMobileProprietaires__c,
                                                Chantier__r.occupant__c, Chantier__r.telephoneDomicileOccupants__c, Chantier__r.telephoneMobileOccupants__c, Chantier__r.occupant__r.name,
                                                Chantier__r.autreProprietaire__c, Chantier__r.autreProprietaire__r.name,
                                                Chantier__r.autreLocataire__c, Chantier__r.autreOccupant__c, Chantier__r.autreOccupant__r.name, Chantier__r.autreLocataire__r.name,
                                                Chantier__r.codePostal__c , Chantier__r.ville__c, Chantier__r.rue__c,
                                                Chantier__r.autreTelephoneLocataires__c, Chantier__r.autreTelephoneOccupants__c, Chantier__r.autreTelephoneProprietaires__c,
                                                ContratK__r.produits__c, ContratK__r.derniereInterventionSAV__c, ContratK__r.nbSAVTotal__c, ContratK__r.nombreInterventionsSAV__c
                                            FROM ServiceAppointment 
                                            WHERE Chantier__c IN :chantiers
                                            ORDER BY LastModifiedDate DESC];

            return contrats;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Récupération des contrats avec chantiers par secteur
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return List<KContrat__c> Liste des contrats avec chantiers dans le secteur
    */
    public static List<KContrat__c> getKContratsBySector(String codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        try {
            // Récupération des chantiers
            String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
            /*// Transfer du géocodage de Lambert 2 en WGS84
            Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
            latlong.transform();
            Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
            latlong2.transform();*/
            List<Chantier__c> chantiers = [SELECT Id 
                                           FROM Chantier__c
                                           WHERE codeMagasinTechnique__c IN :codeMagasins
                                            AND ((((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))];

            

            // Récupération des contrats
            List<KContrat__c> contrats = [SELECT Id, datesignature__c, LastModifiedById, LastModifiedBy.Name, chantier__c, chantier__r.OwnerId, 
                                                chantier__r.Localisation__Latitude__s, chantier__r.Localisation__Longitude__s,
                                                chantier__r.interditProspection__c, Chantier__r.Id, Chantier__r.Name,
                                                Chantier__r.nomProprietaires__c, Chantier__r.nomLocataires__c, Chantier__r.nomOccupants__c,
                                                Chantier__r.prenomProprietaires__c, Chantier__r.prenomLocataires__c, Chantier__r.prenomOccupants__c,
                                                Chantier__r.locataire__c, Chantier__r.telephoneDomicileLocataires__c, Chantier__r.telephoneMobileLocataires__c, Chantier__r.locataire__r.name,
                                                Chantier__r.proprietaire__c, Chantier__r.proprietaire__r.name, Chantier__r.telephoneDomicileProprietaires__c, Chantier__r.telephoneMobileProprietaires__c,
                                                Chantier__r.occupant__c, Chantier__r.telephoneDomicileOccupants__c, Chantier__r.telephoneMobileOccupants__c, Chantier__r.occupant__r.name,
                                                Chantier__r.autreProprietaire__c, Chantier__r.autreProprietaire__r.name,
                                                Chantier__r.autreLocataire__c, Chantier__r.autreOccupant__c, Chantier__r.autreOccupant__r.name, Chantier__r.autreLocataire__r.name,
                                                Chantier__r.codePostal__c , Chantier__r.ville__c, Chantier__r.rue__c,
                                                Chantier__r.autreTelephoneLocataires__c, Chantier__r.autreTelephoneOccupants__c, Chantier__r.autreTelephoneProprietaires__c,
                                                produits__c, derniereInterventionSAV__c, nbSAVTotal__c, nombreInterventionsSAV__c
                                            FROM KContrat__c 
                                            WHERE chantier__c IN :chantiers
                                            ORDER BY  LastModifiedDate DESC];
            return contrats;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Récupération des chantiers sans contrats
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param withContrat Recherche avec ou sans chantiers
    * @return List<KContrat__c> Liste des contrats sans chantiers dans le secteur
    */
    public static List<KContrat__c> getContratChantierFDRList(string codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min, Boolean withContrat) {
        List<KContrat__c> contratsToReturn = new List<KContrat__c>();
        List<KContrat__c> contratsWithout = new List<KContrat__c>();

        // Récupération des contrat avec chantier
        List<KContrat__c> contratsWith = getKContratsBySector(codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min);
        List<Id> chantierIdsWithContrats = new List<Id>();
        for (KContrat__c c : contratsWith) {
            chantierIdsWithContrats.add (c.Chantier__r.Id);
        }

        // Récupération des chantiers n'ayant pas de contrat
        if(!withContrat) {
            String[] codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);  
            /*// Transfer du géocodage de Lambert 2 en WGS84
            Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
            latlong.transform();
            Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
            latlong2.transform();       */
            List<Chantier__c> chantiersWithOutContrats = [ SELECT Id, Name, Localisation__Latitude__s, Localisation__Longitude__s,
                                                            nomProprietaires__c, nomLocataires__c, nomOccupants__c, interditProspection__c,
                                                            prenomProprietaires__c, prenomLocataires__c, prenomOccupants__c,
                                                            locataire__c, telephoneDomicileLocataires__c, telephoneMobileLocataires__c, locataire__r.name,
                                                            proprietaire__c, proprietaire__r.name, telephoneDomicileProprietaires__c, telephoneMobileProprietaires__c,
                                                            occupant__c, telephoneDomicileOccupants__c, telephoneMobileOccupants__c, occupant__r.name,
                                                            autreProprietaire__c, autreProprietaire__r.name,
                                                            autreLocataire__c, autreOccupant__c, autreOccupant__r.name, autreLocataire__r.name,
                                                            autreTelephoneLocataires__c, autreTelephoneOccupants__c, autreTelephoneProprietaires__c,
                                                            rue__c, codePostal__c, ville__c
                                                        FROM Chantier__c
                                                        WHERE Id NOT IN :chantierIdsWithContrats
                                                          AND codeMagasinTechnique__c IN :codeMagasins
                                                          AND ((((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                                        ORDER BY  LastModifiedDate DESC // tri par date de la derniere modification
                                                        LIMIT :fdrDotLimits];

            for (Chantier__c c : chantiersWithOutContrats)
                contratsWithout.add (new KContrat__c(Chantier__r = c));
        }

        // Retour des chantiers avec ou sans contrats
        if(withContrat)
            contratsToReturn = contratsWith;
        else
            contratsToReturn = contratsWithout;

        return contratsToReturn;
    }

    /**
    * @description Récupération des contrats en pose, métrage ou intervention pour un secteur
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param ptype Type du contrat à récupérer (pose, métrage, intervention)
    * @param pDate Date de réalisation du RDV du contrat
    * @return List<ServiceAppointment> Liste des contrats dans le secteur
    */
    public static List<ServiceAppointment> getContratRDVbyTypeFDRList (string codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min, string ptype, Date pDate) {
        Map<Id, ServiceAppointment> contratWithChantiers = new Map<Id, ServiceAppointment> (getContratsBySector(codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min));

        List<ServiceAppointment> rdvs = new List<ServiceAppointment>();
        Datetime dtToday = DateTime.newInstance(pDate.year(), pDate.month(), pDate.day(), 0, 0, 0);
        Datetime dtTommorrow = DateTime.newInstance(pDate.year(), pDate.month(), pDate.day(), 23, 59, 59);

        if(ptype.equalsIgnoreCase('Métrage')){
            rdvs = [SELECT Id, chantier__c FROM ServiceAppointment 
                        WHERE (WorkType.Name = :Constants.WORKTYPE_METRAGE OR WorkType.Name = :Constants.ACTIVITY_TYPE_CONTROL)
                        AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                        AND SchedStartTime > :dtToday AND SchedStartTime < :dtTommorrow LIMIT :fdrDotLimits];
        }
        if(ptype.equalsIgnoreCase('Installation')){
            rdvs = [SELECT Id, chantier__c FROM ServiceAppointment 
                        WHERE (WorkType.Name = :Constants.WORKTYPE_INSTALLATION OR WorkType.Name = :Constants.ACTIVITY_TYPE_INTERVENTION)
                        AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                        AND SchedStartTime > :dtToday AND SchedStartTime < :dtTommorrow LIMIT :fdrDotLimits];
        }
        if(ptype.equalsIgnoreCase('Intervention SAV')){
            rdvs = [SELECT Id, chantier__c FROM ServiceAppointment 
                        WHERE (WorkType.Name = :Constants.WORKTYPE_INTERVENTION_SAV OR WorkType.Name = :Constants.ACTIVITY_TYPE_DIAGNOSTIC)
                        AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENROUTE OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                        AND SchedStartTime > :dtToday AND SchedStartTime < :dtTommorrow LIMIT :fdrDotLimits];
        }

        List<ServiceAppointment> res = new List<ServiceAppointment>{};
        for (ServiceAppointment rdv : rdvs) {
            if (contratWithChantiers.containsKey(rdv.Id))
                res.add (contratWithChantiers.get(rdv.Id));
        }
        
        return res;
    }

    /**
    * @description Récupération des contrats en SAV
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @return List<ServiceAppointment> Liste des contrats dans le secteur
    */
    public static List<ServiceAppointment> getContratSAVFDRList (String codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min) {
        Map<Id, ServiceAppointment> contratWithChantiers = new Map<Id, ServiceAppointment> (getContratsBySector(codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min));

        List<ServiceAppointment> savs = [SELECT Id FROM ServiceAppointment
                                    WHERE Id IN :contratWithChantiers.keySet() AND ContratK__r.libelleStatutContrat__c = 'Contrats en SAV'
                                    LIMIT :fdrDotLimits];

        List<ServiceAppointment> res = new List<ServiceAppointment>{};
        for (ServiceAppointment sav : savs) {
            if (contratWithChantiers.containsKey(sav.Id))
                res.add (contratWithChantiers.get(sav.Id));
        }
        return res;
    }

    /**
    * @description Récupération des chantiers ayant un RDV R1, R2 ou R+ sur les projets du chantiers selon leur type et selon le secteur choisi
    * @param codeMagasin Code du secteur (magasin)
    * @param latitude_min Coordonnée latitude minimale
    * @param longitude_max Coordonnée longitude maximale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param rdvType Type de RDV à chercher
    * @return Map<Event, Chantier__c> Objet de mappage entre les RDV et leur chantier
    */
    public static Map<Event, Chantier__c> getRDVTodayList(String codeMagasin, Decimal latitude_min, Decimal longitude_max, Decimal latitude_max, Decimal longitude_min, String rdvType) {
        Map<Event, Chantier__c> chantierToReturn = new Map<Event, Chantier__c>();       
        Set<String> projetsId = new Set<String>();
        
        // Récupération des RDV
        Date eventStartDate = System.today();
        List<Event> eventsList = [SELECT Id, WhatId, ActivityDate, OwnerId FROM Event WHERE Type = :rdvType                                
                                    AND ActivityDate >= :eventStartDate AND ActivityDate <= :System.today()
                                    AND isDeleted = false AND isArchived = false
                                    AND (RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT)
                                        OR RecordTypeId = :DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT))];
        // Récupération des projets
        for(Event event : eventsList) {
            if(event.WhatId != null)
                projetsId.add(event.WhatId);
        }
        // Récupération des chantiers et projets
        List<String> codeMagasins = TerritoryUtils.getMagasinsKStore(codeMagasin);
        // Transfer du géocodage de Lambert 2 en WGS84
        /*Utils_Cartographie.LatLongCoord latlong = new Utils_Cartographie.LatLongCoord((Double) latitude_min, (Double) longitude_max);
        latlong.transform();
        Utils_Cartographie.LatLongCoord latlong2 = new Utils_Cartographie.LatLongCoord((Double) latitude_max, (Double) longitude_min);
        latlong2.transform();  */
        Map<String, Chantier__c> chantiersMap = new Map<String, Chantier__c>([SELECT Id, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, codePostal__c,
                                                                                    interditProspection__c,  nomProprietaires__c, nomLocataires__c, nomOccupants__c,
                                                                                    prenomProprietaires__c, prenomLocataires__c, prenomOccupants__c, OwnerId,
                                                                                    locataire__c, telephoneDomicileLocataires__c, telephoneMobileLocataires__c, locataire__r.name,
                                                                                    proprietaire__c, proprietaire__r.name, telephoneDomicileProprietaires__c, telephoneMobileProprietaires__c,
                                                                                    occupant__c, telephoneDomicileOccupants__c, telephoneMobileOccupants__c, occupant__r.name,
                                                                                    autreProprietaire__c, autreProprietaire__r.name,
                                                                                    autreLocataire__c, autreOccupant__c, autreOccupant__r.name, autreLocataire__r.name,
                                                                                    autreTelephoneLocataires__c, autreTelephoneOccupants__c, autreTelephoneProprietaires__c,
                                                                            (SELECT Id, chantier__c FROM Projets__r) FROM Chantier__c
                                                                            WHERE codeMagasinTechnique__c IN :codeMagasins AND Id IN (SELECT chantier__c FROM Opportunity WHERE Id IN :projetsId)
                                                                                AND (Localisation__Longitude__s = NULL
                                                                                    OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                                                        AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                                                            LIMIT :fdrDotLimits]);
        
        String a = '';
        String b = '';
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        b = a;
        a = b;
        
        // Récupération des chantiers et ajout dans la liste de retour      
        for(Event event : eventsList) {
            for(Chantier__c chantier : chantiersMap.values()) {
                for(Opportunity projet : chantier.Projets__r) {
                    if(projet.Id == event.WhatId) 
                        chantierToReturn.put(event, chantiersMap.get(projet.chantier__c));
                }
            }
        }
        return chantierToReturn;
    }
}