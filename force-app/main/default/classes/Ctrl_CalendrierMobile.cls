//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_CalendrierMobile
//-- Modifié par : SOPRA - Julien MORINEAU
//-- Modifié le  : 09/06/2016
//-- Version     : 1.3
//-- * 1.3 : CRM-783 - Modification d'affichage des managers et des RDV à réaffecter
//-- * 1.2 : CRM-757 - Ajout des nouveaux rôles pour la picklist des magasins
//-- --------------------------------------------------------------------------------- --
public with sharing class Ctrl_CalendrierMobile {
    public String codeMagasinActuel { get; set; }
    public String libelleMagasinActuel { get; set; }
    public List<SelectOption> magasinOptionList { get; set; }
    public Boolean unlockMagasin { get; set; }

    // Stockage des valeurs des différentes picklists
    public String resultatRDVListDepl { get; set; }
    public String resultatRDVListEff { get; set; }
    public String resultatRDVListNonConf { get; set; }
    public String resultatRDVListNonEff { get; set; }
    public String resultatRDVListNonEffDepl { get; set; }
    public String resultatRDVListPris { get; set; }

    // Stockage des RecordTypes d'évènements
    public Id getrtEventCommercial(){
        return DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
    }
    public Id getrtEventProspection(){
        return DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_PROSPECTION_RT);
    }
    public Id getrtEventAnnexe(){
        return DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_ANNEXE_Vendeur_RT);
    }
    public Id getrtTaskVendeur(){
        return DAL.getRecordTypeIdByDevName('Task',Constants.TASK_VENDEUR_RT);
    }

    public String selectedDate { get; set; }{
        Datetime ajd = Date.today();
        String ajdFormate = ajd.format('dd/MM/yyyy');
        system.debug('ajdFormate : ' + ajdFormate);
        selectedDate = ajdFormate;
    }

    /**
    * @description Fonction appelée lors l'ouverture de la page pour incrémentation le champ compteurCalendrierMobile__c de UserStats
    */
    public void insertUserStats() {
        Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurCalendrierMobile__c');
    }

    /**
    * @description Constructeur
    * @return Ctrl_CalendrierMobile 
    */
    public Ctrl_CalendrierMobile() {
        Map<String,String> magasinsMap = new Map<String,String>();
        List<String> codeMagasinsMapTemp = new List<String>();
        unlockMagasin = false;

        if(Apexpages.currentPage().getParameters().get('changeDate') != null && Apexpages.currentPage().getParameters().get('changeDate') != '')
        selectedDate = Apexpages.currentPage().getParameters().get('changeDate');
        system.debug('selectedDate : ' + selectedDate);

        // Construction de la liste dépendante StatutRDV/RésultatDuRDV
        Map<String,List<String>> statutResultatRDV = PicklistUtils.GetDependentOptions('Event', 'StatutRDV__c', 'ResultatduRDV__c');
        system.debug('statutResultatRDV : ' + statutResultatRDV);

        List<String> resultatRDVdepl = statutResultatRDV.get(Constants.StatutEventAReaffecter);
        List<String> resultatRDVeff = statutResultatRDV.get(Constants.StatutEventEffectue);
        List<String> resultatRDVnonconf = statutResultatRDV.get(Constants.StatutEventNonConfirme);
        List<String> resultatRDVnoneff = statutResultatRDV.get(Constants.StatutEventNoneffectue);
        List<String> resultatRDVnoneffdepl = statutResultatRDV.get(Constants.StatutEventNoneffectueAvDep);
        List<String> resultatRDVpris = statutResultatRDV.get(Constants.StatutEventPris);

        resultatRDVListDepl = JSON.serialize(resultatRDVdepl);
        resultatRDVListEff = JSON.serialize(resultatRDVeff);
        resultatRDVListNonConf = JSON.serialize(resultatRDVnonconf);
        resultatRDVListNonEff = JSON.serialize(resultatRDVnoneff);
        resultatRDVListNonEffDepl = JSON.serialize(resultatRDVnoneffdepl);
        resultatRDVListPris = JSON.serialize(resultatRDVpris);

        // Récupération des informations de l'utilisateur pour magasin
        User actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, LastLoginDate, UserRoleId, UserRole.Name, ProfileId, profile.Name, IsActive
                        FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = true];

        // Construction de la liste des magasins
        /*if ((actualUser.CodeDR__c == null || actualUser.CodeDR__c == '*') && (actualUser.CodeDV__c == null || actualUser.CodeDV__c == '*') && (actualUser.CodeMagasin__c == null || actualUser.CodeMagasin__c == '*'))
            magasinsMap = DAL_Cartographie.getAllMagasins();
        else if(actualUser.UserRole.Name.containsIgnoreCase(' - REF - ') ){
            // Cas d'un référent  (JMU / CRM-757 / 14-03-2016)
            magasinsMap = DAL_Cartographie.getAllMagasinsByRole(actualUser.UserRole);
            if(magasinsMap.size() > 1) unlockMagasin = true;
        } else
            magasinsMap = DAL_Cartographie.getAllMagasinsByUser(actualUser);*/

        UserContext context = UserContext.getContext(UserInfo.getUserId());
        magasinsMap = context.getMagasins();
        if(magasinsMap.size() > 1) unlockMagasin = true;

        // Trie
        List<String> libelleMagasinList = new List<String>(magasinsMap.Values());
        libelleMagasinList.sort();

        // Initialisation de la picklist de sélection de magasin
        magasinOptionList = new List<SelectOption>();
        for(String libelleMag : libelleMagasinList) {
            for (String code : magasinsMap.keySet()) {
                if(magasinsMap.get(code) == libelleMag) {
                    codeMagasinsMapTemp.add(code);
                    magasinOptionList.add(new SelectOption(code, magasinsMap.get(code)));
                    break;
                }
            }
        }

        // Initialisation sur le premier magasin de la liste si disponible
        if(codeMagasinActuel == null && actualUser.CodeMagasin__c != null && actualUser.CodeMagasin__c != '*') {
            codeMagasinActuel = actualUser.CodeMagasin__c;
            libelleMagasinActuel = actualUser.libelleMagasin__c;
        } else if (codeMagasinActuel == null && !magasinsMap.isEmpty() && magasinsMap != null) {
            codeMagasinActuel = magasinOptionList.get(0).getValue();
            libelleMagasinActuel = magasinOptionList.get(0).getLabel();
        }
        if(magasinOptionList.isEmpty()) magasinOptionList.add(new SelectOption('Aucun', 'Aucun'));
        system.debug('magasinOptionList ' + magasinOptionList.get(0).getValue());
    }

    /**
    *
    *   REMOTEACTION
    *   Recherche vendeur par magasin
    *
    **/
    @RemoteAction
    public static List<Utils_InnerClasses.VendeurInfos> getVendeursByMagasin(String codeMagasinActuel) {
        List<User> users = new List<User>();
        List<Utils_InnerClasses.VendeurInfos> vendeursList = new List<Utils_InnerClasses.VendeurInfos>();
        User responsable =  new User();
        String responsableMagId;

        system.debug('### DEBUT getVendeursByMagasin');
        try {
            if(codeMagasinActuel != null && codeMagasinActuel != '') {
                /*
                responsable = TerritoryUtils.getManagersByMag(codeMagasinActuel);
                */
                
                responsable = TerritoryUtils.getManager(codeMagasinActuel);
                users = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, FirstName, LastName, UserRoleId, UserRole.Name, SmallPhotoUrl,
                                libelleMagasin__c, localisationLongitude__c, localisationLatitude__c FROM User
                            WHERE CodeMagasin__c = :codeMagasinActuel AND IsActive = true ORDER BY Name ASC];
            }
            if(responsable != null){
                responsableMagId = responsable.Id;

                Utils_InnerClasses.VendeurInfos resultat = new Utils_InnerClasses.VendeurInfos();
                resultat.RoleName = responsable.UserRole.Name;
                resultat.Vendeur = responsable;
                resultat.UserId = responsable.Id;
                resultat.UserName = String.escapeSingleQuotes(responsable.Name);
                resultat.isResponsable = true;
                resultat.Latitude = responsable.localisationLatitude__c;
                resultat.Longitude = responsable.localisationLongitude__c;
                vendeursList.add(resultat);
            }

            system.debug('users in mag : ' + users);

            for(User vendeur : users){
                Utils_InnerClasses.VendeurInfos resultat = new Utils_InnerClasses.VendeurInfos();
                resultat.RoleName = vendeur.UserRole.Name;
                resultat.Vendeur = vendeur;
                resultat.UserId = vendeur.Id;
                resultat.UserName = String.escapeSingleQuotes(vendeur.Name);
                resultat.isResponsable = false;
                resultat.Latitude = vendeur.localisationLatitude__c;
                resultat.Longitude = vendeur.localisationLongitude__c;
                if(responsableMagId == null || (responsableMagId != null && responsableMagId != resultat.UserId))
                    vendeursList.add(resultat);
            }
            system.debug('vendeursList : ' + vendeursList);

            system.debug('### FIN getVendeursByMagasin');
            return vendeursList;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Récupération des évènements du jour pour affichage selon liste de vendeurs
    *
    **/
    @RemoteAction
    public static List<Event> getSelectedEvents(Integer jour, Integer mois, Integer annee, String sortType, List<String> vendeursId) {
        List<Event> eventToReturn = new List<Event>();
        DateTime startDate = DateTime.newInstance(annee, mois+1, jour,0,0,0);
        DateTime endDate = DateTime.newInstance(annee, mois+1, jour,23,59,59);

        system.debug('### DEBUT getSelectedEvents');
        try {
            system.debug('### Sort Type : ' + sortType);
            system.debug('### IDs vendeur : ' + vendeursId);
            system.debug('### StartDateTime : ' + startDate);
            system.debug('### EndDateTime : ' + endDate);
            if(sortType == 'vendeur') {
                eventToReturn = [SELECT Id, Type, Subject, OwnerId, Owner.Name, StatutRDV__c, ResultatduRDV__c, localisation__longitude__s, localisation__latitude__s,
                                            StartDateTime, EndDateTime, ActivityDate, WhoId, WhatId, What.Name, Who.Name, Decisionnaire__c,
                                            NbBAL50__c , NbFoire43__c, NbPhone55__c, NbStandGM42__c, NbStandMarch54__c, NbTAP51__c,
                                            Motifsannulationclient__c, MotifsAnnulationnondevisable__c, Motifsannulationvendeur__c, debriefe__c
                                    FROM Event WHERE OwnerId IN :vendeursId
                                        AND((StartDateTime >= :startDate AND StartDateTime <= :endDate) OR (EndDateTime >= :startDate AND EndDateTime <= :endDate))
                                    ORDER BY Owner.Name ASC, StartDateTime ASC, Type ASC];
            } else if(sortType == 'type') {
                eventToReturn = [SELECT Id, Type, Subject, OwnerId, Owner.Name, StatutRDV__c, ResultatduRDV__c, localisation__longitude__s, localisation__latitude__s,
                                            StartDateTime, EndDateTime, ActivityDate, WhoId, WhatId, What.Name, Who.Name, Decisionnaire__c,
                                            NbBAL50__c , NbFoire43__c, NbPhone55__c, NbStandGM42__c, NbStandMarch54__c, NbTAP51__c,
                                            Motifsannulationclient__c, MotifsAnnulationnondevisable__c, Motifsannulationvendeur__c, debriefe__c
                                    FROM Event WHERE OwnerId IN :vendeursId
                                        AND((StartDateTime >= :startDate AND StartDateTime <= :endDate) OR (EndDateTime >= :startDate AND EndDateTime <= :endDate))
                                    ORDER BY Type ASC, StartDateTime ASC, Owner.Name ASC];
            } else if(sortType == 'heure') {
                eventToReturn = [SELECT Id, Type, Subject, OwnerId, Owner.Name, StatutRDV__c, ResultatduRDV__c, localisation__longitude__s, localisation__latitude__s,
                                            StartDateTime, EndDateTime, ActivityDate, WhoId, WhatId, What.Name, Who.Name, Decisionnaire__c,
                                            NbBAL50__c , NbFoire43__c, NbPhone55__c, NbStandGM42__c, NbStandMarch54__c, NbTAP51__c,
                                            Motifsannulationclient__c, MotifsAnnulationnondevisable__c, Motifsannulationvendeur__c, debriefe__c
                                    FROM Event WHERE OwnerId IN :vendeursId
                                        AND((StartDateTime >= :startDate AND StartDateTime <= :endDate) OR (EndDateTime >= :startDate AND EndDateTime <= :endDate))
                                    ORDER BY StartDateTime ASC, Owner.Name ASC, Type ASC];
            }

            system.debug('### Number of events : ' + eventToReturn.size());
            system.debug('### FIN getSelectedEvents');
            return eventToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Récupération des taches du jour pour affichage selon liste de vendeurs
    *
    **/
    @RemoteAction
    public static List<Task> getSelectedTasks(Integer jour, Integer mois, Integer annee, List<String> vendeursId){
        List<Task> taskToReturn = new List<Task>();
        Date actualDate = Date.newInstance(annee, mois+1, jour);

        system.debug('### DEBUT getSelectedTasks');
        try {
            system.debug('### IDs vendeur : ' + vendeursId);
            system.debug('### ActivityDate : ' + actualDate);

            taskToReturn = [SELECT Id, Type, Subject, OwnerId, Priority, ActivityDate, StatutRDV__c, ResultatduRDV__c, WhatId, WhoId, Status, Owner.Name, Description
                                FROM Task WHERE OwnerId IN :vendeursId AND ActivityDate = :actualDate
                            ORDER BY Status ASC, Owner.Name ASC];

            system.debug('### Number of tasks : ' + taskToReturn.size());
            system.debug('### FIN getSelectedTasks');
            return taskToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Mise à jour d'un évènement pour modification du propriétaire
    *
    **/
    @RemoteAction
    public static Boolean updateEvent(String eventId, String ownerId) {
        Boolean saveOK = false;

        system.debug('### DEBUT updateEvent');
        try {
            if(ownerId != '') {
                List<Event> updatedEvent = [SELECT Id, OwnerId FROM Event WHERE Id = :eventId LIMIT 1];
                if(!updatedEvent.isEmpty()) {
                    Event eventToUpdate = updatedEvent[0];
                    eventToUpdate.OwnerId = ownerId;
                    update eventToUpdate;
                    saveOK = true;
                }
            }
            system.debug('### Flag Save : ' + saveOK);
            system.debug('### FIN updateEvent');
            return saveOK;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Récupère la liste des vendeurs par ordre de distance pour un événement
    *
    **/
    @RemoteAction
    public static Set<Utils_InnerClasses.VendeurInfos> getVendeursByDistance(List<String> vendeursId, String projetId, Decimal latitude, Decimal longitude) {
        Map<User, Decimal> vendeursDistanceMap = new Map<User, Decimal>();
        Set<Utils_InnerClasses.VendeurInfos> vendeursToReturn = new Set<Utils_InnerClasses.VendeurInfos>();

        system.debug('### DEBUT getVendeursByDistance');

        // Si pas de géolocalisation sur le RDV, on récupère la géolocalisation du chantier du projet du RDV
        if ((latitude == null || longitude == null) && projetId != null) {
            List<Chantier__c> objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s FROM Chantier__c
                                                WHERE Id IN (SELECT chantier__c FROM Opportunity WHERE Id = :projetId) LIMIT 1];
            if(!objectResult.isEmpty()) {
                latitude = objectResult[0].localisation__latitude__s;
                longitude = objectResult[0].localisation__longitude__s;
            }
        }

        List<User> vendeursList = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, FirstName, LastName, UserRoleId, UserRole.Name, SmallPhotoUrl,
                                        localisationLongitude__c, localisationLatitude__c FROM User
                                    WHERE Id IN :vendeursId AND IsActive = true ORDER BY Name];

        // Pour tous les vendeurs , on calcul la distance
        for(User vendeur : vendeursList) {
            Decimal distanceUser = 0;
            // Si l'adresse du vendeur est spécifiée, calcul
            if(vendeur.localisationLatitude__c != null && vendeur.localisationLongitude__c != null && latitude != null && longitude != null){
                distanceUser = ObjectDetailUtils.CalculationByDistance(latitude, longitude, vendeur.localisationLatitude__c, vendeur.localisationLongitude__c);
            } else {
                distanceUser = null;
            }
            vendeursDistanceMap.put(vendeur, distanceUser);
        }

        // Trie de la liste des vendeurs selon la distance
        List<Decimal> distanceList = vendeursDistanceMap.values();
        distanceList.sort();
        for(Decimal distance : distanceList) {
            system.debug('### Distance calcultated : ' + distance);
            for(User vendeur : vendeursDistanceMap.keySet()) {
                system.debug('### -----------------------');
                system.debug('### User : ' + vendeur.Name);
                Decimal distanceUser = vendeursDistanceMap.get(vendeur);
                system.debug('### Distance User : ' + distanceUser);
                if(distanceUser == distance) {
                    Utils_InnerClasses.VendeurInfos resultat = new Utils_InnerClasses.VendeurInfos();
                    resultat.UserId = vendeur.Id;
                    resultat.UserName = String.escapeSingleQuotes(vendeur.Name);
                    resultat.Distance = distanceUser;
                    system.debug('### Add User in list : ' + vendeur.Name);
                    vendeursToReturn.add(resultat);
                    vendeursDistanceMap.remove(vendeur);
                    break;
                }
                system.debug('### -----------------------');
            }
        }
        system.debug('### FIN getVendeursByDistance');
        return vendeursToReturn;
    }

    // Refresh de la page lors d'un changement de date
    public PageReference refreshDate() {
        system.debug('selectedDate : ' + selectedDate);
        PageReference pageVF = Page.VF_CalendrierMobile;
        pageVF.getParameters().put('changeDate', selectedDate);
        pageVF.setRedirect(true);
        return pageVF;
    }
}