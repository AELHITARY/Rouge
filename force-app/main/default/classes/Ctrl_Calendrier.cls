//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Calendrier
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/07/2023
//-- Version     : 1.10
//-- * 1.10 : Ajout permission réaffectation contact passif
//-- * 1.9 : Ajout infos pour les RDV Kube3
//-- * 1.8 : RQM-175 : RDV FSL affichés aux vendeurs
//-- * 1.7 : GDPR : Suppression référence semaine type
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Calendrier {
    public User actualUser { get; set; }
    public String userName {get;set;}
    public String userId {get;set;}
    public String objectName {get;set;}
    public String objectId {get;set;}
    public String magCode {get;set;}
    public String objectRealName {get;set;}
    public String userProfile {get;set;}
    public List<String> userIds {get;set;}
    public List<User> userIdsList {get;set;}
    public Boolean viewOtherUser {get;set;}
    public List<CalEvent> events {get;set;}
    public string codeMagasinActuel { get; set; }
    public string codeMagasinSubstitution { get; set; }
    public string libelleMagasinActuel { get; set; }
    public string libelleMagasinSubstitution { get; set; }
    public List<SelectOption> magasinOptionList { get; set; }
    public Map<String,String> magasinsMap { get; set; }
    public String codeMagasinsMap { get; set; }
    public String origineCodesSerialized { get; set; }
    public String heureDebut { get; set; }
    public String heureFin { get; set; }
    public Boolean activeDrapNDrop { get; set; }
    public Boolean proximityMode { get; set; }
    public Boolean isCall { get; set; }
    public String vendeursMagasin { get; set; }
    public String adresseLigne1 { get; set; }
    public String adresseLigne2 { get; set; }
    public String adresseLigne3 { get; set; }
    public Boolean unlockMagasin { get; set; }
    public String walkMeURL { get; set; }
    public String commercialRecordType { get; set; }
    public Boolean hasReaffectationPermission { get; set; }

    public List<SelectOption> heuresDebut { get; set; }{
        Integer i = 0;
        heuresDebut = new List<SelectOption>();
        for(i=0;i<=8;i++){
            heuresDebut.add(new SelectOption('' + i + '', '' + i + 'h00'));
            System.debug('i : ' + i);
        }
    }

    public List<SelectOption> heuresFin { get; set; }{
        Integer i = 0;
        heuresFin = new List<SelectOption>();
        for(i=22;i<=24;i++){
            heuresFin.add(new SelectOption('' + i + '', '' + i + 'h00'));
        }
    }

    //The calendar plugin is expecting dates is a certain format. We can use this string to get it formated correctly
    public static String dtFormat = 'yyyy-MM-dd';
    public static String hourFormat = 'HH:mm:ssZ';

    /**
    * @description Fonction appelée lors l'ouverture de la page pour incrémentation le champ compteurAffectationProximitePlanning__c ou compteurCalendrierKparK__c de UserStats
    */
    public static void insertUserStatsCalendar(Id userId, Boolean affectationMode) {
        if(affectationMode)
            Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurAffectationProximitePlanning__c');
        else
            Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurCalendrierKparK__c');
    }

    /**
    * @description Constructeur
    * @return Ctrl_Calendrier 
    */
    public Ctrl_Calendrier() {
        viewOtherUser = true;
        activeDrapNDrop = false;
        walkMeURL = PropertiesUtils.getStringValue('walkme.snippet.url', '');

        // Récupération des paramètres
        userId = ApexPages.currentPage().getParameters().get('cal_lkid');
        userName = ApexPages.currentPage().getParameters().get('cal');

        objectName = ApexPages.currentPage().getParameters().get('objectName');
        objectId = ApexPages.currentPage().getParameters().get('objectId');
        magCode = ApexPages.currentPage().getParameters().get('codeMagasin');

        actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, LastLoginDate, UserRoleId, UserRole.Name, ProfileId, profile.Name, IsActive
                        FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = true];

        //recupere le role de l utilisateur courant
        UserContext context = UserContext.getContext();
        //recupere le role associé
        isCall = context.isCallUser();

        if(userId == null) { userId = UserInfo.getUserId(); viewOtherUser = false; }
        if(userName == null) userName = UserInfo.getName();
        System.debug('### objectName ' + objectName);
        System.debug('### objectId ' + objectId);
        System.debug('### magCode ' + magCode);
        // Récupération paramètre personnalisé (DragAndDrop)
        activeDrapNDrop = PropertiesUtils.isUserAllowed('calendrier_draganddrop__c');
        System.debug('### Drag & Drop : ' + activeDrapNDrop);
        // Type d'enregistrement Event commercial
        commercialRecordType = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
        // Vérification permission
        hasReaffectationPermission = FeatureManagement.checkPermission('KPK_Reaffectation_Contact_Passif');
        System.debug('## hasReaffectationPermission: '+hasReaffectationPermission);
    }

    /**
    * @description Fonction exécutée lors du chargement de la page. Charge la liste des vendeurs
    * @return PageReference Page Visualforce VF_Calendrier 
    */
    public PageReference pageLoad() {
        System.debug('### DEBUT pageLoad');
        events = new List<CalEvent>();
        List<String> codeMagasinsMapTemp = new List<String>();
        List<mapping__c> magSubList = mapping__c.getall().values();
        List<mapping__c> origineCodes = new List<mapping__c>();
        unlockMagasin = false;

        Integer i;
        for(i=0;i<magSubList.size();i++){
            if(magSubList[i].Repository__c == 'origine'){
                origineCodes.add(magSubList[i]);
            }
        }
        origineCodesSerialized = JSON.serialize(origineCodes);
        if(objectName == '' || objectId == '' || magCode == '' || objectName == null || objectId == null || magCode == null) {
            proximityMode = false;
            /* if ((actualUser.CodeDR__c == null || actualUser.CodeDR__c == '*') && (actualUser.CodeDV__c == null || actualUser.CodeDV__c == '*') && (actualUser.CodeMagasin__c == null || actualUser.CodeMagasin__c == '*'))
                magasinsMap = DAL_Cartographie.getAllMagasins();
            else if(actualUser.UserRole.Name.containsIgnoreCase(' - REF - ') ){
                // Cas d'un référent  (JMU / CRM-757 / 14-03-2016)
                magasinsMap = DAL_Cartographie.getAllMagasinsByRole(actualUser.UserRole);
                if(magasinsMap.size() > 1) unlockMagasin = true;
            } else
                magasinsMap = DAL_Cartographie.getAllMagasinsByUser(actualUser); */
            // Récupération liste des magasins de l'utilisateur
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
            codeMagasinsMap = JSON.serialize(codeMagasinsMapTemp);

            // Initialisation sur le premier magasin de la liste si disponible
            if(codeMagasinActuel == null && actualUser.CodeMagasin__c != null && actualUser.CodeMagasin__c != '*') {
                codeMagasinActuel = actualUser.CodeMagasin__c;
                libelleMagasinActuel = actualUser.libelleMagasin__c;
            } else if (codeMagasinActuel == null && !magasinsMap.isEmpty() && magasinsMap != null) {
                codeMagasinActuel = magasinOptionList.get(0).getValue();
                libelleMagasinActuel = magasinOptionList.get(0).getLabel();
            }
            if(magasinOptionList.isEmpty()) magasinOptionList.add(new SelectOption('Aucun', 'Aucun'));
        } else {
            proximityMode = true;

/** F.G., le 01/04/2016 - K-Store
            List<Sectorisation__c> mag = new List<Sectorisation__c>();
            List<Sectorisation__c> mag2 = new List<Sectorisation__c>();

            String[] codeMagsins = SectorisationUtisl.getMagasinsKStore(magCode);
            mag = [SELECT libelleMagasin__c, codeMagasin__c FROM Sectorisation__c WHERE codeMagasin__c = :magCode LIMIT 1];

            for(i=0;i<magSubList.size();i++){
                if(magSubList[i].Repository__c == 'substitution-magasin' && magSubList[i].PickValue__c == magCode){
                    codeMagasinSubstitution = magSubList[i].ConvertedValue__c;
                }
            }
            codeMagasinsMap = JSON.serialize(codeMagasinsMapTemp);

            mag2 = [SELECT libelleMagasin__c, codeMagasin__c FROM Sectorisation__c WHERE codeMagasin__c = :codeMagasinSubstitution LIMIT 1];
            for(Sectorisation__c se : mag2){
                libelleMagasinSubstitution = se.libelleMagasin__c;
            }

            magasinOptionList = new List<SelectOption>();

            for(Sectorisation__c s : mag){
                magasinOptionList.add(new SelectOption(s.codeMagasin__c, s.libelleMagasin__c));
            }

            codeMagasinActuel = magasinOptionList.get(0).getValue();
            libelleMagasinActuel = magasinOptionList.get(0).getLabel();
 -- F.G., le 01/04/2016 - K-Store **/

            magasinOptionList = new List<SelectOption>();

            String[] codeMagasins = CalendrierUtils.getMagasinsKStore(magCode);
            for (AggregateResult ar : [SELECT codeMagasin__c, libelleMagasin__c, COUNT(id) FROM Sectorisation__c WHERE codeMagasin__c IN :codeMagasins GROUP BY codeMagasin__c, libelleMagasin__c ORDER BY libelleMagasin__c]) {
                String codeMagasin =  String.valueOf(ar.get('codeMagasin__c'));
                String libelleMagasin =  String.valueOf(ar.get('libelleMagasin__c'));

                magasinOptionList.add(new SelectOption(codeMagasin, libelleMagasin));
                if (magCode.equalsIgnoreCase(codeMagasin)) {
                    codeMagasinActuel = codeMagasin;
                    libelleMagasinActuel =libelleMagasin;
                }
            }
/** F.G., le 01/04/2016 - K-Store **/



            // Récupération information de l'objet
            if(objectName == 'Account' || objectName == 'Contact') {
                Account objectResult = [SELECT Id, Name, rue__c, codePostal__c, ville__c, pays__c FROM Account WHERE Id = :objectId];
                adresseLigne1 = (objectResult.rue__c == null) ? '' : objectResult.rue__c + ',';
                adresseLigne2 = objectResult.codePostal__c + ' ' + objectResult.ville__c;
                if(objectResult.pays__c != 'FRANCE') adresseLigne3 = objectResult.pays__c;
                objectRealName = objectResult.Name;
            } else if (objectName == 'Chantier') {
                Chantier__c objectResult = [SELECT Id, Name, rue__c, codePostal__c, ville__c, pays__c FROM Chantier__c WHERE Id = :objectId];
                adresseLigne1 = (objectResult.rue__c == null) ? '' : objectResult.rue__c + ',';
                adresseLigne2 = objectResult.codePostal__c + ' ' + objectResult.ville__c;
                if(objectResult.pays__c != 'FRANCE') adresseLigne3 = objectResult.pays__c;
                objectRealName = objectResult.Name;
            } else if (objectName == 'Opportunity') {
                Opportunity objectResult = [SELECT Id, Name, chantier__c FROM Opportunity WHERE Id = :objectId];
                Chantier__c objectAdresse = [SELECT Id, Name, rue__c, codePostal__c, ville__c, pays__c FROM Chantier__c WHERE Id = :objectResult.chantier__c];
                adresseLigne1 = (objectAdresse.rue__c == null) ? '' : objectAdresse.rue__c + ',';
                adresseLigne2 = objectAdresse.codePostal__c + ' ' + objectAdresse.ville__c;
                if(objectAdresse.pays__c != 'FRANCE') adresseLigne3 = objectAdresse.pays__c;
                objectRealName = objectResult.Name;
            }

            // Récupération des vendeurs pour assignation
            List<Utils_InnerClasses.vendeurinfos> vendeursMagasinTemp = getVendeursByDistance(magCode, objectName, objectId);
            vendeursMagasin = JSON.serialize(vendeursMagasinTemp);
            System.debug('vendeursMagasin : ' + vendeursMagasin);
        }

        // Mise à jour compteur statistique utilisateur
        insertUserStatsCalendar(Userinfo.getUserId(), proximityMode);

        heureDebut = '8';
        heureFin = '22';
        userProfile = actualUser.profile.Name;

        System.debug('### FIN pageLoad');
        return null;
    }

    /**
    * @description Fonction de récupération des vendeurs du magasin pour affectation
    * @param magCode Code du magasin
    * @param objectName Nom API de l'objet
    * @param objectId Id de l'objet
    * @return String Liste des vendeurs avec leur distance
    */
    public static List<Utils_InnerClasses.vendeurinfos> getVendeursByDistance(String magCode, String objectName, String objectId) {
        List<Utils_InnerClasses.vendeurinfos> vendeurDistanceList = new List<Utils_InnerClasses.vendeurinfos>();
        List<Utils_InnerClasses.vendeurinfos> finalVendeurList = new List<Utils_InnerClasses.vendeurinfos>();
        Set<Decimal> vendeurDistanceSet = new Set<Decimal>();
        List<Decimal> distanceList = new List<Decimal>();
        User responsable =  new User();
        List<User> vendeursList = new List<User>();
        Sectorisation__c sectoMag = new Sectorisation__c();
        String lastCodeMagasinProject = null;
        String lastOwnerProject = null;
        Decimal latitude = null;
        Decimal longitude = null;
        String responsableMagId;

        System.debug('### DEBUT Récupération vendeurs pour affectation');
        try {
            // Récupération information de l'objet
            if(objectName == 'Account' || objectName == 'Contact') {
                Account objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s, codeMagasinActuel__c,
                                        (SELECT Id, OwnerId, Owner.codeMagasin__c FROM Opportunities ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id = :objectId];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                // Recherche du dernier vendeur du dernier projet du compte
                if(objectResult.Opportunities != null && !objectResult.Opportunities.isEmpty())  {
                    lastOwnerProject = objectResult.Opportunities[0].OwnerId;
                    lastCodeMagasinProject = objectResult.Opportunities[0].Owner.codeMagasin__c;
                }
            } else if (objectName == 'Chantier') {
                Chantier__c objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s, codeMagasinTechnique__c, codeMagasinActuel__c,
                                                (SELECT Id, OwnerId, Owner.codeMagasin__c FROM Projets__r ORDER BY CreatedDate DESC LIMIT 1) FROM Chantier__c WHERE Id = :objectId];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                // Recherche du dernier vendeur du dernier projet
                if(objectResult.Projets__r != null && !objectResult.Projets__r.isEmpty())  {
                    lastOwnerProject = objectResult.Projets__r[0].OwnerId;
                    lastCodeMagasinProject = objectResult.Projets__r[0].Owner.codeMagasin__c;
                }
            } else if (objectName == 'Opportunity') {
                Opportunity objectOpportunity = [SELECT Id, Name, chantier__c FROM Opportunity WHERE Id = :objectId];
                Chantier__c objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s,
                                                (SELECT Id, OwnerId, Owner.codeMagasin__c FROM Projets__r WHERE Id != :objectId ORDER BY CreatedDate DESC LIMIT 1)
                                            FROM Chantier__c WHERE Id = :objectOpportunity.chantier__c];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                // Recherche du dernier vendeur du dernier projet
                if(objectResult.Projets__r != null && !objectResult.Projets__r.isEmpty())  {
                    lastOwnerProject = objectResult.Projets__r[0].OwnerId;
                    lastCodeMagasinProject = objectResult.Projets__r[0].Owner.codeMagasin__c;
                }
            }

            // Affectation aux vendeurs du magasin de la sectorisation actuelle
            if(magCode != null) {
                responsable = TerritoryUtils.getManager(magCode);
                if(responsable != null){
                    responsableMagId = responsable.Id;

                    Utils_InnerClasses.vendeurinfos resultat = new Utils_InnerClasses.vendeurinfos();
                    if(responsable.localisationLatitude__c != null && responsable.localisationLongitude__c != null && latitude != null && longitude != null){
                        Decimal distanceUser = ObjectDetailUtils.CalculationByDistance(latitude, longitude, responsable.localisationLatitude__c, responsable.localisationLongitude__c);
                        resultat.Distance = distanceUser;
                    } else {
                        resultat.Distance = null;
                    }
                    resultat.Position = (responsable.Id == lastOwnerProject) ? 1 : 2;
                    resultat.RoleName = responsable.UserRole.Name;
                    resultat.Vendeur = responsable;
                    resultat.UserId = responsable.Id;
                    resultat.UserName = String.escapeSingleQuotes(responsable.Name);
                    resultat.isResponsable = true;
                    vendeurDistanceList.add(resultat);
                    distanceList.add(resultat.distance);
                }
                vendeursList = [SELECT Id, Name, localisationLongitude__c, localisationLatitude__c, libelleMagasin__c, IsActive, UserRoleId, UserRole.Name,
                                    CodeDR__c, CodeDV__c, CodeMagasin__c, FirstName, LastName, SmallPhotoUrl, effectueVentes__c FROM User Where codeMagasin__c = :magCode AND IsActive = true];
            }

            // Pour tous les vendeurs , on calcul le distance
            for(User vendeur : vendeursList) {
                Utils_InnerClasses.vendeurinfos resultat = new Utils_InnerClasses.vendeurinfos();
                // Si le adresse du vendeur spécifié, calcul
                if(vendeur.localisationLatitude__c != null && vendeur.localisationLongitude__c != null && latitude != null && longitude != null){
                    Decimal distanceUser = ObjectDetailUtils.CalculationByDistance(latitude, longitude, vendeur.localisationLatitude__c, vendeur.localisationLongitude__c);
                    resultat.Distance = distanceUser;
                } else {
                    resultat.Distance = null;
                }
                resultat.Position = (vendeur.Id == lastOwnerProject) ? 1 : 2;
                resultat.RoleName = vendeur.UserRole.Name;
                resultat.Vendeur = vendeur;
                resultat.UserId = vendeur.Id;
                resultat.UserName = String.escapeSingleQuotes(vendeur.Name);
                resultat.isResponsable = false;
                if(responsableMagId == null || (responsableMagId != null && responsableMagId != resultat.UserId)) {
                    vendeurDistanceList.add(resultat);
                    distanceList.add(resultat.distance);
                }
            }

            System.debug('vendeurDistanceList : '+ vendeurDistanceList);
            System.debug('distanceList : '+ distanceList);

            distanceList.sort();
            for(Decimal d : distanceList){
                if (d != null) vendeurDistanceSet.add(d);
            }
            vendeurDistanceSet.add(null);

            for(Decimal de : vendeurDistanceSet){
                for(Utils_InnerClasses.vendeurinfos vi : vendeurDistanceList){
                    if(vi.Distance == de){
                        finalVendeurList.add(vi);
                    }
                }
            }

            System.debug('finalVendeurList : '+ finalVendeurList);

            System.debug('### FIN Récupération vendeurs pour affectation');
            return finalVendeurList;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Fonction de récupération des vendeurs du magasin pour affectation (Remote Action)
    * @param magCode Code du magasin
    * @param objectName Nom API de l'objet
    * @param objectId Id de l'objet
    * @return String Liste des vendeurs avec leur distance
    */
    @RemoteAction
    public static String getVendeursByDistanceRemote(String magCode, String objectName, String objectId) {
        List<Utils_InnerClasses.vendeurinfos> vendeurDistanceList = new List<Utils_InnerClasses.vendeurinfos>();
        List<Utils_InnerClasses.vendeurinfos> finalVendeurList = new List<Utils_InnerClasses.vendeurinfos>();
        Set<Decimal> vendeurDistanceSet = new Set<Decimal>();
        List<Decimal> distanceList = new List<Decimal>();
        Sectorisation__c sectoMag = new Sectorisation__c();
        User responsable =  new User();
        List<User> vendeursList = new List<User>();
        String lastOwnerProject = null;
        String lastCodeMagasinProject = null;
        String responsableMagId;
        Decimal latitude = null;
        Decimal longitude = null;


        System.debug('### DEBUT Récupération vendeurs pour affectation');
        try {
            // Récupération information de l'objet
            if(objectName == 'Account' || objectName == 'Contact') {
                Account objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s, codeMagasinActuel__c,
                                        (SELECT Id, OwnerId, Owner.codeMagasin__c FROM Opportunities ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id = :objectId];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                // Recherche du dernier vendeur du dernier projet du compte
                if(objectResult.Opportunities != null && !objectResult.Opportunities.isEmpty())  {
                    lastOwnerProject = objectResult.Opportunities[0].OwnerId;
                    lastCodeMagasinProject = objectResult.Opportunities[0].Owner.codeMagasin__c;
                }
            } else if (objectName == 'Chantier') {
                Chantier__c objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s, codeMagasinTechnique__c, codeMagasinActuel__c,
                                                (SELECT Id, OwnerId, Owner.codeMagasin__c FROM Projets__r ORDER BY CreatedDate DESC LIMIT 1) FROM Chantier__c WHERE Id = :objectId];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                // Recherche du dernier vendeur du dernier projet
                if(objectResult.Projets__r != null && !objectResult.Projets__r.isEmpty())  {
                    lastOwnerProject = objectResult.Projets__r[0].OwnerId;
                    lastCodeMagasinProject = objectResult.Projets__r[0].Owner.codeMagasin__c;
                }
            } else if (objectName == 'Opportunity') {
                Opportunity objectOpportunity = [SELECT Id, Name, chantier__c FROM Opportunity WHERE Id = :objectId];
                Chantier__c objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s,
                                                (SELECT Id, OwnerId, Owner.codeMagasin__c FROM Projets__r WHERE Id != :objectId ORDER BY CreatedDate DESC LIMIT 1)
                                            FROM Chantier__c WHERE Id = :objectOpportunity.chantier__c];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                // Recherche du dernier vendeur du dernier projet
                if(objectResult.Projets__r != null && !objectResult.Projets__r.isEmpty())  {
                    lastOwnerProject = objectResult.Projets__r[0].OwnerId;
                    lastCodeMagasinProject = objectResult.Projets__r[0].Owner.codeMagasin__c;
                }
            }

            // Affectation aux vendeurs du magasin de la sectorisation actuelle
            if(magCode != null) {
                responsable = TerritoryUtils.getManager(magCode);
                if(responsable != null){
                    responsableMagId = responsable.Id;

                    Utils_InnerClasses.vendeurinfos resultat = new Utils_InnerClasses.vendeurinfos();
                    if(responsable.localisationLatitude__c != null && responsable.localisationLongitude__c != null && latitude != null && longitude != null){
                        Decimal distanceUser = ObjectDetailUtils.CalculationByDistance(latitude, longitude, responsable.localisationLatitude__c, responsable.localisationLongitude__c);
                        resultat.Distance = distanceUser;
                    } else {
                        resultat.Distance = null;
                    }
                    resultat.Position = (responsable.Id == lastOwnerProject) ? 1 : 2;
                    resultat.RoleName = responsable.UserRole.Name;
                    resultat.Vendeur = responsable;
                    resultat.UserId = responsable.Id;
                    resultat.UserName = String.escapeSingleQuotes(responsable.Name);
                    resultat.isResponsable = true;
                    vendeurDistanceList.add(resultat);
                    distanceList.add(resultat.distance);
                    vendeursList = [SELECT Id, Name, localisationLongitude__c, localisationLatitude__c, libelleMagasin__c, IsActive, UserRoleId, UserRole.Name,
                                        CodeDR__c, CodeDV__c, CodeMagasin__c, FirstName, LastName, SmallPhotoUrl, effectueVentes__c FROM User Where codeMagasin__c = :magCode AND IsActive = true];
                }
            }

            // Pour tous les vendeurs , on calcul le distance
            for(User vendeur : vendeursList) {
                Utils_InnerClasses.vendeurinfos resultat = new Utils_InnerClasses.vendeurinfos();
                // Si le adresse du vendeur spécifié, calcul
                if(vendeur.localisationLatitude__c != null && vendeur.localisationLongitude__c != null && latitude != null && longitude != null){
                    Decimal distanceUser = ObjectDetailUtils.CalculationByDistance(latitude, longitude, vendeur.localisationLatitude__c, vendeur.localisationLongitude__c);
                    resultat.Distance = distanceUser;
                } else {
                    resultat.Distance = null;
                }
                resultat.Position = (vendeur.Id == lastOwnerProject) ? 1 : 2;
                resultat.RoleName = vendeur.UserRole.Name;
                resultat.Vendeur = vendeur;
                resultat.UserId = vendeur.Id;
                resultat.UserName = String.escapeSingleQuotes(vendeur.Name);
                resultat.isResponsable = false;
                if(responsableMagId == null || (responsableMagId != null && responsableMagId != resultat.UserId)) {
                    vendeurDistanceList.add(resultat);
                    distanceList.add(resultat.distance);
                }
            }

            distanceList.sort();
            for(Decimal d : distanceList){
                if (d != null) vendeurDistanceSet.add(d);
            }
            vendeurDistanceSet.add(null);

            for(Decimal de : vendeurDistanceSet){
                for(Utils_InnerClasses.vendeurinfos vi : vendeurDistanceList){
                    if(vi.Distance == de){
                        finalVendeurList.add(vi);
                    }
                }
            }

            System.debug('### FIN Récupération vendeurs pour affectation');
            String finalVendeurListToString = JSON.serialize(finalVendeurList);
            return finalVendeurListToString;
        } catch (Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Modification du jour et/ou de l'heure d'un event
    *
    **/
    @RemoteAction
    public static void changeEventDateTime(String eventId, Boolean allDayEvent, String eventStartTime, String eventEndTime) {
        System.debug('### DEBUT changeEventDateTime');
        Datetime eventStartTimeFormated;
        Datetime eventEndTimeFormated;

        try {
            if (allDayEvent) {
                eventStartTimeFormated =  Datetime.valueOfGmt(eventStartTime);
                eventEndTimeFormated =  Datetime.valueOfGmt(eventEndTime);
                if (!eventStartTimeFormated.isSameDay(eventEndTimeFormated))
                    eventEndTimeFormated = eventEndTimeFormated.addDays(-1);
            } else {
                eventStartTimeFormated =  Datetime.valueOf(eventStartTime);
                eventEndTimeFormated =  Datetime.valueOf(eventEndTime);
            }
            System.debug('eventId : ' + eventId);
            // Modification des champs Event
            if(eventId.startsWith('00U')){
                Event event = new Event();
                event.Id = eventId;
                event.StartDateTime = eventStartTimeFormated;
                event.EndDateTime = eventEndTimeFormated;
                // Mise à jour
                update event;
            // Modification des champs Task
            } else if (eventId.startsWith('00T')){
                Task taskTemp = new Task();
                taskTemp.Id = eventId;
                taskTemp.ActivityDate = eventStartTimeFormated.date();
                // Mise à jour
                update taskTemp;
            }
            System.debug('### FIN changeEventDateTime');
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Construction de la liste du projet (ou création) pour la création du RDV
    *
    **/
    @RemoteAction
    public static ObjetsInfos objectCreate(String objectId, String vendeurId) {
        ObjetsInfos result = new ObjetsInfos();
        System.debug('### DEBUT objectCreate');
        System.debug('objectId : ' + objectId);
        System.debug('vendeurId : ' + vendeurId);
        try {
            User vendeur = [SELECT Id, Name FROM User WHERE Id = :vendeurId LIMIT 1];

            // Si l'objet envoyé est un compte
            if(objectId.startsWith('001')){
                Account account = [SELECT Id, Name, rue__c, codePostal__c, ville__c, pays__c, OwnerId, IsPersonAccount,
                                            contactParDefaut__c, PersonContactId FROM Account WHERE Id = :objectId];
                String contactId = '';
                if(!account.isPersonAccount) {
                    // Si compte pro, et pas de contact par défaut, on utilise l'id du compte
                    if(account.contactParDefaut__c != null)
                        contactId = account.contactParDefaut__c;
                    else {
                        Contact c = new Contact(LastName='Contact calendrier', AccountId = account.Id);
                        insert c;
                        contactId = c.Id;
                    }
                } else if(account.isPersonAccount) {
                    contactId = account.PersonContactId;
                }
                // Récupération information du contact
                Contact contact = [SELECT Id, Name FROM Contact WHERE Id = :contactId LIMIT 1];
                result.contactId = contactId;
                result.contactName = contact.Name;
                result.accountName = account.Name;
                result.accountId = account.Id;
            }
            // Si l'objet envoyé est un chantier
            else if(objectId.startsWith('a08')){
                Chantier__c chantier = [SELECT Id, Name, OwnerId, locataire__c, proprietaire__c, occupant__c FROM Chantier__c WHERE Id = :objectId];
                // Id de l'occupant du chantier
                String accountId = '';
                Boolean locataire = false;
                if(chantier.occupant__c != null) {
                    accountId = chantier.occupant__c;
                } else if(chantier.locataire__c != null) {
                    accountId = chantier.locataire__c;
                    locataire = true;
                } else {
                    accountId = chantier.proprietaire__c;
                }
                Account account = [SELECT Id, Name, LastName, FirstName, ville__c, AccountSource FROM Account WHERE Id = :accountId];
                // Création de l'opportunité
                RecordType rtOpportunity = [SELECT id , Name FROM RecordType WHERE sobjectType = 'Opportunity' AND isActive = true LIMIT 1];
                Opportunity oppAccount = new Opportunity(Name= ('PRJ _ ' + System.today().year() + (System.today().month() < 10 ? '0' + System.today().month() : System.today().month().format())
                                                                 + ' _ ' + (account.Name == null ? '' : account.Name)
                                                                 + ' _ ' + account.ville__c
                                                                 + ' _ ' + (locataire ? 'Locataire' : 'Propriétaire')),
                                                         CloseDate = System.today().addMonths(1),
                                                         chantier__c = chantier.id,
                                                         accountId = accountId,
                                                         Type = 'Nouveau',
                                                         StageName = 'Analyse',
                                                         OwnerId = vendeurId,
                                                         RecordTypeId = rtOpportunity.Id,
                                                         LeadSource = account.AccountSource,
                                                         callSource__c = 'P');
                insert(oppAccount);
                result.accountId = account.Id;
                result.chantierId = objectId;
                result.opportunityId = oppAccount.Id;
                result.oppName = oppAccount.Name;
                result.contactName = account.Name;
            }
            // Si l'objet envoyé est un projet
            else if(objectId.startsWith('006')){
                Opportunity projet = [SELECT Id, Name, chantier__c, AccountId, Account.Name FROM Opportunity WHERE Id = :objectId];
                result.chantierId = projet.chantier__c;
                result.opportunityId = objectId;
                result.oppName = projet.Name;
                result.contactName = projet.Account.Name;
            }
            // Si l'objet envoyé est un contact
            else if(objectId.startsWith('003')){
                Contact contact = [SELECT Id, Name FROM Contact WHERE Id = :objectId];
                result.contactId = objectId;
                result.contactName = contact.Name;
            }
            result.vendeurId = vendeurId;
            result.vendeurName = vendeur.Name;

            System.debug('### FIN objectCreate');
            return result;
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Recherche vendeurs par magasin
    *
    **/
    @RemoteAction
    public static List<Utils_InnerClasses.vendeurinfos> getVendeursByMagasin(String codeMagasinActuel) {
        List<User> users = new List<User>();
        List<Utils_InnerClasses.vendeurinfos> vendeursList = new List<Utils_InnerClasses.vendeurinfos>();
        String responsableMagId;
        User responsable =  new User();
        Sectorisation__c sectoMag = new Sectorisation__c();

        System.debug('### DEBUT getVendeursByMagasin');
        try {
            if(codeMagasinActuel != null && codeMagasinActuel != '') {
                /*
                Boolean test = PropertiesUtils.getBooleanValue('test.calendrier', false);
                if(test)
                    responsable = TerritoryUtils.getManagersByMag(codeMagasinActuel);
                else
                    responsable = TerritoryUtils.getManager(codeMagasinActuel);
                */
                responsable = TerritoryUtils.getManager(codeMagasinActuel);
                if(responsable != null){
                    responsableMagId = responsable.Id;

                    Utils_InnerClasses.vendeurinfos resultatResponsable = new Utils_InnerClasses.vendeurinfos();
                    resultatResponsable.RoleName = responsable.UserRole.Name;
                    resultatResponsable.Vendeur = responsable;
                    resultatResponsable.UserId = responsable.Id;
                    resultatResponsable.UserName = String.escapeSingleQuotes(responsable.Name);
                    resultatResponsable.isResponsable = true;
                    resultatResponsable.vendeur = responsable;
                    vendeursList.add(resultatResponsable);
                }

                for(User vendeur : [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, FirstName, LastName, UserRoleId, UserRole.Name, SmallPhotoUrl, effectueVentes__c
                                        FROM User WHERE CodeMagasin__c =: codeMagasinActuel AND IsActive = true ORDER BY Name ASC]){
                    Utils_InnerClasses.vendeurinfos resultat = new Utils_InnerClasses.vendeurinfos();
                    resultat.RoleName = vendeur.UserRole.Name;
                    resultat.Vendeur = vendeur;
                    resultat.UserId = vendeur.Id;
                    resultat.UserName = String.escapeSingleQuotes(vendeur.Name);
                    resultat.isResponsable = false;
                    resultat.vendeur = vendeur;
                    if(responsableMagId == null || (responsableMagId != null && responsableMagId != resultat.UserId)) vendeursList.add(resultat);
                }
                System.debug('vendeursList : ' + vendeursList);
            }

            System.debug('### FIN getVendeursByMagasin');
            return vendeursList;
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Recherche des informations du magasin
    *
    **/
    @RemoteAction
    public static Account getMagasinInfos(String codeMagasinActuel) {
        System.debug('### DEBUT getMagasinInfos');
        try {
            List<Account> magEntite = new List<Account>();
            magEntite = [SELECT Id, internalMessage__c FROM Account WHERE KparKReference__c = :codeMagasinActuel LIMIT 1];

            System.debug('### FIN getMagasinInfos');
            return magEntite[0];
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Chargement des activités pour un magasin
    * @param userIds Ids du vendeur sélectionné
    * @param startDate Date de début de la période visible du calendrier 
    * @param endDate Date de fin de la période visible du calendrier 
    * @param checkPris Filtre sur le statut "Pris"
    * @param checkNonConf Filtre sur le statut "Non confirmé"
    * @param checkEff Filtre sur le statut "Effectué" 
    * @param checkNonEff Filtre sur le statut "Non effectué"
    * @param checkDep Filtre sur le statut "Déplacé"
    * @param checkReaff Filtre sur le statut "A Réaffecté"
    * @param checkTask Filtre sur les tâches
    * @param checkActif Filtre sur les RDV Actif
    * @param checkPassif Filtre sur les RDV Passif
    * @param isResponsable Vrai si l'utilisateur est un responsable
    * @param codeMagasinActuel Code du magasin sélectionné
    * @param checkAnnulC Filtre sur le statut "Annulé Call"
    * @return List<CalEvent> Liste des objets contenant les RDV
    */
    @RemoteAction
    public static List<CalEvent> getActivitiesForUser(String userIds, Datetime startDate, Datetime endDate, Boolean checkR0, Boolean checkR1,
                                                        Boolean checkR2, Boolean checkR, Boolean checkAnnexe, Boolean checkProsp, Boolean checkPris, Boolean checkNonConf, Boolean checkEff,
                                                        Boolean checkNonEff, Boolean checkDep, Boolean checkReaff, Boolean checkTask, Boolean checkActif, Boolean checkPassif,
                                                        Boolean isResponsable, String codeMagasinActuel, Boolean checkAnnulC) {
        List<CalEvent> activitiesList = new List<CalEvent>();
        List<Event> resultEventTemp = new List<Event>();
        List<Task> resultTaskTemp = new List<Task>();

        System.debug('### DEBUT getActivitiesForUser');
        Boolean soqlOrCondition = false; // Permet d'ajouter les 'OR' dans la requête
        System.debug('## userIds : ' + userIds);
        System.debug('## checkTask : ' + checkTask);
        System.debug('## isResponsable : ' + isResponsable);
        System.debug('## codeMagasinActuel: '+codeMagasinActuel);

        Sectorisation__c sectoMag = new Sectorisation__c();
        sectoMag = [SELECT Id, libelleMagasin__c FROM Sectorisation__c WHERE codeMagasin__c = :codeMagasinActuel LIMIT 1];
        String libelleMagasin = sectoMag.libelleMagasin__c;

        Date startCalDate = startDate.date();
        Date endCalDate = endDate.date();
        System.debug('## startCalDate : ' + startCalDate);
        System.debug('## endCalDate : ' + endCalDate);

        // Récupération des Record Type des Event
        Id commercialRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        Id prospectionRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
        Id taRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_TA_RT);
        Id vendeurRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_Vendeur_RT);

        // Construction requête EVENT
        String soqlQuery = 'SELECT Id, Subject, isAllDayEvent, StartDateTime, EndDateTime, Type, RecordTypeId, StatutRDV__c, OwnerID, Location, AccountId, CreatedDate, CreatedById,';
                soqlQuery += ' WhatId, NbStandGM42__c, NbFoire43__c, NbBAL50__c, NbTAP51__c, NbStandMarch54__c, NbPhone55__c FROM Event';
                soqlQuery += ' WHERE ((StartDateTime >= :startCalDate AND StartDateTime <= :endCalDate) ';
                soqlQuery += '    OR (EndDateTime >= :startCalDate AND EndDateTime <= :endCalDate) ';
                soqlQuery += '    OR (StartDateTime <= :startCalDate AND EndDateTime >= :endCalDate)) ';
                soqlQuery += ' AND RecurrenceType=\'\' ';         
                soqlQuery += ' AND OwnerID = :userIds';
        /**
        if(isResponsable)        
                soqlQuery+=' WHERE OwnerID = :userIds AND ((StartDateTime >= :startMonth AND StartDateTime <= :endMonth) OR (EndDateTime >= :startMonth AND EndDateTime <= :endMonth) OR (StartDateTime <= :startMonth AND EndDateTime >= :endMonth))';
        
        else
                soqlQuery+=' WHERE OwnerID = :userIds AND Magasin__c = :libelleMagasin AND ((StartDateTime >= :startMonth AND StartDateTime <= :endMonth) OR (EndDateTime >= :startMonth AND EndDateTime <= :endMonth) OR (StartDateTime <= :startMonth AND EndDateTime >= :endMonth))';
        **/

        if(((checkR0 || checkR1 || checkR2 || checkR) && (checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC)) || checkAnnexe || checkProsp){
            soqlQuery+=' AND ( ';
            if(checkAnnexe){
                if(soqlOrCondition) soqlQuery+=' OR';
                soqlQuery +=' RecordTypeId = ' + '\'' +  taRecordType + '\' OR RecordTypeId = ' + '\'' +  vendeurRecordType + '\'';
                soqlOrCondition = true;
            }if(checkProsp){
                if(soqlOrCondition) soqlQuery+=' OR';
                soqlQuery+=' RecordTypeId = ' + '\'' +  prospectionRecordType + '\'';
                soqlOrCondition = true;
            }if((checkR0 || checkR1 || checkR2 || checkR) && (checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC)){
                if(soqlOrCondition) soqlQuery+=' OR ( ';
                soqlOrCondition = false;
                if(checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC) soqlQuery+='( ';
                if(checkR0){
                    soqlQuery+=' Type = \'R0\'';
                    soqlOrCondition = true;
                }
                if(checkR1){
                    if(soqlOrCondition) soqlQuery+=' OR';
                    soqlQuery+=' Type = \'R1\'';
                    soqlOrCondition = true;
                }
                if(checkR2){
                    if(soqlOrCondition) soqlQuery+=' OR';
                    soqlQuery+=' Type = \'R2\'';
                    soqlOrCondition = true;
                }
                if(checkR){
                    if(soqlOrCondition) soqlQuery+=' OR';
                    soqlQuery +=' Type = \'R+\'';
                    soqlOrCondition = true;
                }
                soqlQuery+=' ) ';
                soqlOrCondition = false;
                if(checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC){
                    soqlQuery+=' AND ( ';
                    if(checkPris){
                        soqlQuery +=' StatutRDV__c = \'Pris\' ';
                        soqlOrCondition = true;
                    }if(checkNonConf){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'Non confirmé\' ';
                        soqlOrCondition = true;
                    }if(checkEff){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'Effectué\' ';
                        soqlOrCondition = true;
                    }if(checkNonEff){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c LIKE \'%Non effectué%\' ';
                        soqlOrCondition = true;
                    }if(checkReaff){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'A Réaffecter\' ';
                        soqlOrCondition = true;
                    }if(checkAnnulC){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'Annulé Call\' ';
                        soqlOrCondition = true;
                    }
                    soqlQuery+=' )) ';
                }
            }
            if(checkAnnexe || checkProsp){ soqlQuery+=' ) '; }
            System.debug('## Requête SOQL : ' + soqlQuery);
            // Exécution de la requête
            resultEventTemp = Database.query(soqlQuery);
        }

        // Récupération des taches
        resultTaskTemp = [SELECT Id, Subject, ActivityDate, IsRecurrence, Priority, Status, OwnerId, AccountId, CreatedDate, CreatedById, WhatId
                            FROM Task WHERE OwnerId = :userIds AND ActivityDate >= :startCalDate AND ActivityDate <= :endCalDate];

        // Construction du résultat
        List<String> userIdsList = new List<String>();
        userIdsList.add(userIds);
        activitiesList = processGetActivities(userIdsList, resultEventTemp, resultTaskTemp, checkTask, checkActif, checkPassif);

        System.debug('## Nb Event/Task à afficher : ' + activitiesList.size());
        System.debug('### FIN getActivitiesForUser');
        return activitiesList;
    }

    /**
    * @description REMOTEACTION - Chargement des activités pour un magasin
    * @param userIds Liste des Ids des vendeurs du magasin
    * @param startDate Date de début de la période visible du calendrier 
    * @param endDate Date de fin de la période visible du calendrier 
    * @param checkPris Filtre sur le statut "Pris"
    * @param checkNonConf Filtre sur le statut "Non confirmé"
    * @param checkEff Filtre sur le statut "Effectué" 
    * @param checkNonEff Filtre sur le statut "Non effectué"
    * @param checkDep Filtre sur le statut "Déplacé"
    * @param checkReaff Filtre sur le statut "A Réaffecté"
    * @param checkTask Filtre sur les tâches
    * @param checkActif Filtre sur les RDV Actif
    * @param checkPassif Filtre sur les RDV Passif
    * @param isResponsable Vrai si l'utilisateur est un responsable
    * @param codeMagasinActuel Code du magasin sélectionné
    * @param checkAnnulC Filtre sur le statut "Annulé Call"
    * @return List<CalEvent> Liste des objets contenant les RDV
    */
    @RemoteAction
    public static List<CalEvent> getActivitiesForStore(List<String> userIds, Datetime startDate, Datetime endDate, Boolean checkR0, Boolean checkR1,
                                                        Boolean checkR2, Boolean checkR, Boolean checkAnnexe, Boolean checkProsp, Boolean checkPris, Boolean checkNonConf, Boolean checkEff,
                                                        Boolean checkNonEff, Boolean checkDep, Boolean checkReaff, Boolean checkTask, Boolean checkActif, Boolean checkPassif,
                                                        Boolean isResponsable, String codeMagasinActuel, Boolean checkAnnulC) {
        List<CalEvent> activitiesList = new List<CalEvent>();
        List<Event> resultEventTemp = new List<Event>();
        List<Task> resultTaskTemp = new List<Task>();

        System.debug('### DEBUT getActivitiesForUser');
        Boolean soqlOrCondition = false; // Permet d'ajouter les 'OR' dans la requête
        System.debug('## userIds : ' + userIds);
        System.debug('## checkTask : ' + checkTask);
        System.debug('## isResponsable : ' + isResponsable);
        System.debug('## codeMagasinActuel: '+codeMagasinActuel);

        Sectorisation__c sectoMag = new Sectorisation__c();
        sectoMag = [SELECT Id, libelleMagasin__c FROM Sectorisation__c WHERE codeMagasin__c = :codeMagasinActuel LIMIT 1];
        String libelleMagasin = sectoMag.libelleMagasin__c;

        Date startCalDate = startDate.date();
        Date endCalDate = endDate.date();
        System.debug('## startCalDate : ' + startCalDate);
        System.debug('## endCalDate : ' + endCalDate);

        // Récupération des Record Type des Event
        Id commercialRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        Id prospectionRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
        Id taRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_TA_RT);
        Id vendeurRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_Vendeur_RT);

        // Construction requête EVENT
        String soqlQuery = 'SELECT Id, Subject, isAllDayEvent, StartDateTime, EndDateTime, Type, RecordTypeId, StatutRDV__c, OwnerID, Location, AccountId, CreatedDate, CreatedById,';
                soqlQuery += ' WhatId, NbStandGM42__c, NbFoire43__c, NbBAL50__c, NbTAP51__c, NbStandMarch54__c, NbPhone55__c FROM Event';
                soqlQuery += ' WHERE ((StartDateTime >= :startCalDate AND StartDateTime <= :endCalDate) ';
                soqlQuery += '    OR (EndDateTime >= :startCalDate AND EndDateTime <= :endCalDate) ';
                soqlQuery += '    OR (StartDateTime <= :startCalDate AND EndDateTime >= :endCalDate)) ';
                soqlQuery += ' AND RecurrenceType=\'\' ';   
                soqlQuery += ' AND (OwnerID NOT IN :userIds AND projet__r.chantier__r.salesEntity__c = \'' + getMagasinInfos(codeMagasinActuel).id + '\')';

        if(((checkR0 || checkR1 || checkR2 || checkR) && (checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC)) || checkAnnexe || checkProsp){
            soqlQuery+=' AND ( ';
            if(checkAnnexe){
                if(soqlOrCondition) soqlQuery+=' OR';
                soqlQuery +=' RecordTypeId = ' + '\'' +  taRecordType + '\' OR RecordTypeId = ' + '\'' +  vendeurRecordType + '\'';
                soqlOrCondition = true;
            }if(checkProsp){
                if(soqlOrCondition) soqlQuery+=' OR';
                soqlQuery+=' RecordTypeId = ' + '\'' +  prospectionRecordType + '\'';
                soqlOrCondition = true;
            }if((checkR0 || checkR1 || checkR2 || checkR) && (checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC)){
                if(soqlOrCondition) soqlQuery+=' OR ( ';
                soqlOrCondition = false;
                if(checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC) soqlQuery+='( ';
                if(checkR0){
                    soqlQuery+=' Type = \'R0\'';
                    soqlOrCondition = true;
                }
                if(checkR1){
                    if(soqlOrCondition) soqlQuery+=' OR';
                    soqlQuery+=' Type = \'R1\'';
                    soqlOrCondition = true;
                }
                if(checkR2){
                    if(soqlOrCondition) soqlQuery+=' OR';
                    soqlQuery+=' Type = \'R2\'';
                    soqlOrCondition = true;
                }
                if(checkR){
                    if(soqlOrCondition) soqlQuery+=' OR';
                    soqlQuery +=' Type = \'R+\'';
                    soqlOrCondition = true;
                }
                soqlQuery+=' ) ';
                soqlOrCondition = false;
                if(checkPris || checkNonConf || checkEff || checkNonEff || checkReaff || checkAnnulC){
                    soqlQuery+=' AND ( ';
                    if(checkPris){
                        soqlQuery +=' StatutRDV__c = \'Pris\' ';
                        soqlOrCondition = true;
                    }if(checkNonConf){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'Non confirmé\' ';
                        soqlOrCondition = true;
                    }if(checkEff){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'Effectué\' ';
                        soqlOrCondition = true;
                    }if(checkNonEff){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c LIKE \'%Non effectué%\' ';
                        soqlOrCondition = true;
                    }if(checkReaff){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'A Réaffecter\' ';
                        soqlOrCondition = true;
                    }if(checkAnnulC){
                        if(soqlOrCondition) soqlQuery+=' OR';
                        soqlQuery +=' StatutRDV__c = \'Annulé Call\' ';
                        soqlOrCondition = true;
                    }
                    soqlQuery+=' )) ';
                }
            }
            if(checkAnnexe || checkProsp){ soqlQuery+=' ) '; }
            System.debug('## Requête SOQL : ' + soqlQuery);
            // Exécution de la requête
            resultEventTemp = Database.query(soqlQuery);
        }

        // Récupération des taches
        /*resultTaskTemp = [SELECT Id, Subject, ActivityDate, IsRecurrence, Priority, Status, OwnerId, AccountId, CreatedDate, CreatedById, WhatId
                            FROM Task WHERE OwnerId IN :userIds AND ActivityDate >= :startCalDate AND ActivityDate <= :endCalDate];
        */

        // Construction du résultat
        activitiesList = processGetActivities(userIds, resultEventTemp, new List<Task>(), checkTask, checkActif, checkPassif);

        System.debug('## Nb Event/Task à afficher : ' + activitiesList.size());
        System.debug('### FIN getActivitiesForStore');
        return activitiesList;
    }

    /**
    * @description Fonction principale pour alimenté l'objet custom des RDV en fonction des résultats SOQL
    * @param userIds Ids du vendeur sélectionné
    * @param resultEventTemp Résultat de la requête SOQL sur les Event
    * @param resultTaskTemp Résultat de la requête SOQL sur les Task
    * @param checkTask Filtre sur les tâches
    * @param checkActif Filtre sur les RDV Actif
    * @param checkPassif Filtre sur les RDV Passif
    * @return List<CalEvent> Liste des objets contenant les RDV
    */
    public static List<CalEvent> processGetActivities(List<String> userIds, List<Event> resultEventTemp, List<Task> resultTaskTemp, 
                                                        Boolean checkTask, Boolean checkActif, Boolean checkPassif) 
    {        
        System.debug('### DEBUT processGetActivities');
        System.debug('## userIds : ' + userIds.size());
        System.debug('## resultEventTemp : ' + resultEventTemp.size());
        System.debug('## resultTaskTemp : ' + resultTaskTemp.size());
        System.debug('## checkActif: '+checkActif);
        System.debug('## checkPassif: '+checkPassif);
        System.debug('## checkTask: '+checkTask);

        List<CalEvent> activitiesList = new List<CalEvent>();
        List<Event> resultEvent = new List<Event>();
        List<Task> resultTask = new List<Task>();

        // Récupération des Record Type des Event
        Id commercialRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        Id prospectionRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);
        Id taRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_TA_RT);
        Id vendeurRecordType = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_ANNEXE_Vendeur_RT);

        // Filtres pour requêtes
        List<String> creatorsId = new List<String>();
        List<String> comptesId = new List<String>();
        List<String> projetsId = new List<String>();
        List<String> chantiersId = new List<String>();
        for(Event e : resultEventTemp){
            creatorsId.add(e.CreatedById);
            comptesId.add(e.AccountId);
            projetsId.add(e.WhatId);
            chantiersId.add(e.WhatId);
        }
        for(Task t : resultTaskTemp){
            creatorsId.add(t.CreatedById);
            comptesId.add(t.AccountId);
            projetsId.add(t.WhatId);
            chantiersId.add(t.WhatId);
        }

        // Récupération des users
        creatorsId.addAll(userIds); // ajout utilisateur courant
        Map<String, User> allUsers = new Map<String, User>([SELECT Id, Name, SmallPhotoUrl FROM User WHERE Id IN :creatorsId]);
        // Récupération des comptes
        Map<String, Account>  allAccounts = new Map<String, Account>([SELECT Id, Name FROM Account WHERE Id IN :comptesId]);
        // Récupération des projets
        Map<String, Opportunity> allOpportunities = new Map<String, Opportunity>([SELECT Id, chantier__c, actifParOrigine__c, LeadSource FROM Opportunity WHERE Id IN :projetsId]);
        // Récupération des chantiers
        for(Opportunity o : allOpportunities.values()) chantiersId.add(o.chantier__c);
        Map<String, Chantier__c> allChantiers = new Map<String, Chantier__c>([SELECT Id, Name FROM Chantier__c WHERE Id IN :chantiersId]);

        // Filtre des RDV actifs/passifs
        for(Event e : resultEventTemp){
            String WhatId = e.WhatId;
            if(WhatId != null && WhatId.startsWith('006') && (Constants.EVENT_ACTIVITE_COMMERCIALE_TYPES.contains(e.Type))) {
                if(allOpportunities != null && allOpportunities.get(WhatId) != null) {
                    Opportunity opp = allOpportunities.get(WhatId);
                    if((opp.actifParOrigine__c && checkActif) || (!opp.actifParOrigine__c && checkPassif)) {
                        resultEvent.add(e);
                    }
                }
            } else {
                resultEvent.add(e);
            }
        }

        // Filtre des taches actives/passives
        for(Task t : resultTaskTemp){
            /*String WhatIdTask = t.WhatId;
            if(WhatIdTask != null && WhatIdTask.startsWith('006')){
                for(Opportunity opp : allOpportunities){
                    if(t.WhatId == opp.Id){
                        if((opp.actifParOrigine__c && checkActif) || (!opp.actifParOrigine__c && checkPassif)) resultTask.add(t);
                    }
                }
            } else if(WhatIdTask != null && WhatIdTask.startsWith('001')){
                for(Account acc : allAccounts){
                    if(t.WhatId == acc.Id){
                        if((acc.actifParOrigine__c && checkActif) || (!acc.actifParOrigine__c && checkPassif)) resultTask.add(t);
                    }
                }
            } else {*/
                resultTask.add(t);
            //}
        }

        /*** Traitement des événements ***/
        for(Event evnt : resultEvent){
            System.debug('## Event : ' + evnt);
            String chantierName = '';
            String isActive = '';
            String WhatId = evnt.WhatId;
            DateTime startDT = evnt.StartDateTime;
            DateTime endDT = evnt.EndDateTime;
            DateTime createdDT = evnt.createdDate;
            CalEvent calEvent = new CalEvent();

            // Information de l'Event
            calEvent.eventId = evnt.Id;
            if(evnt.Location != null) {
                calEvent.emplacement = evnt.Location;
            } else {
                calEvent.emplacement = '';
            }
            calEvent.title = evnt.Subject;
            calEvent.allDay = evnt.isAllDayEvent;
            if (evnt.isAllDayEvent && !startDT.isSameDay(endDT))
                endDT = endDT.addDays(1);
            calEvent.startString = startDT.format(dtFormat) + 'T' + startDT.format(hourFormat);
            calEvent.endString = endDT.format(dtFormat) + 'T' + endDT.format(hourFormat);
            calEvent.priority = '';
            calEvent.createdDate = createdDT.format(dtFormat) + 'T' + createdDT.format(hourFormat);
            if (evnt.StatutRDV__c != null)
                calEvent.status = evnt.StatutRDV__c;
            else
                calEvent.status = '';
            calEvent.url = '/' + evnt.Id;
            // Informations des utilisateurs
            calEvent.createdName = (allUsers.get(evnt.CreatedById) == null) ? '' : allUsers.get(evnt.CreatedById).Name;
            calEvent.compte = (allAccounts == null || allAccounts.get(evnt.AccountId) == null) ? '' : allAccounts.get(evnt.AccountId).Name;
            if(allUsers != null && allUsers.get(evnt.OwnerID) != null) {
                User vendeur = allUsers.get(evnt.OwnerID);
                calEvent.vendeurName = vendeur.Name;
                calEvent.vendeurId = vendeur.Id;
                calEvent.vendeurIcon = vendeur.SmallPhotoUrl;
            }
            // Information du projet et chantier
            if(WhatId != null && WhatId.startsWith('006')) {
                if(allOpportunities != null && allOpportunities.get(WhatId) != null) {
                    Opportunity opp = allOpportunities.get(WhatId);
                    calEvent.origineProjet = opp.LeadSource;
                    chantierName = (allChantiers == null) ? '' : allChantiers.get(opp.chantier__c).Name;
                    if(Constants.EVENT_ACTIVITE_COMMERCIALE_TYPES.contains(evnt.Type)) {
                        if(opp.actifParOrigine__c) isActive = 'actif';
                        else isActive = 'passif';
                    }
                }
            } else if(WhatId != null && WhatId.startsWith('a08')){
                chantierName = (allChantiers == null) ? '' : allChantiers.get(WhatId).Name;
                isActive = 'na';
            } else isActive = 'na';
            calEvent.chantier = chantierName;
            calEvent.isActive = isActive;

            // Gestion du type et status et type pour RDV Commecial et informations pour RDV de prospection
            if(evnt.RecordTypeId == prospectionRecordType){
                calEvent.className = 'event-prospection';
                if(evnt.Type == 'Prospection Physique'){
                    calEvent.infoProspec = 'Nb BAL(50) / TAP(51) : ';
                    if(evnt.NbBAL50__c != null && evnt.NbTAP51__c != null) calEvent.champProspec = evnt.NbBAL50__c + ' / ' + evnt.NbTAP51__c;
                    else if(evnt.NbBAL50__c != null) calEvent.champProspec = evnt.NbBAL50__c + ' / 0';
                    else if(evnt.NbTAP51__c != null) calEvent.champProspec = '0 / ' + evnt.NbTAP51__c;
                } else if(evnt.Type == 'Phone'){
                    calEvent.infoProspec = 'Nb phones(55) : ';
                    calEvent.champProspec = evnt.NbPhone55__c + '';
                } else if(evnt.Type == 'Stand/Marché'){
                    calEvent.infoProspec = 'Nb stands/marchés(54) : ';
                    calEvent.champProspec = evnt.NbStandMarch54__c + '';
                } else if(evnt.Type == 'Stand/Galerie Marchande'){
                    calEvent.infoProspec = 'Nb stands/GM(42) : ';
                    calEvent.champProspec = evnt.NbStandGM42__c + '';
                } else if(evnt.Type == 'Foire'){
                    calEvent.infoProspec = 'Nb foires(43) : ';
                    calEvent.champProspec = evnt.NbFoire43__c + '';
                }
            } else if(evnt.RecordTypeId == commercialRecordType) {
                
                System.debug('########################################### event.Type = ' + evnt.Type);
                
                // Type
                if(evnt.Type == Constants.EVENT_TYPE_R0)
                    calEvent.className = 'event-r0';
                else if(evnt.Type == Constants.EVENT_TYPE_R1)
                    calEvent.className = 'event-r1';
                else if(evnt.Type == Constants.EVENT_TYPE_R2)
                    calEvent.className = 'event-r2';
                else if(evnt.Type == Constants.EVENT_TYPE_RP)
                    calEvent.className = 'event-rplus';
                else
                    calEvent.className = 'event-r1';
                // Status
                if(evnt.StatutRDV__c == 'Pris')
                    calEvent.colorBar = 'red';
                else if(evnt.StatutRDV__c == 'Non confirmé')
                    calEvent.colorBar = 'orange';
                else if(evnt.StatutRDV__c == 'Effectué')
                    calEvent.colorBar = 'green';
                else if(evnt.StatutRDV__c.contains('Non effectué'))
                    calEvent.colorBar = 'black';
                else if(evnt.StatutRDV__c == 'A Réaffecter')
                    calEvent.colorBar = 'violet';
                else if(evnt.StatutRDV__c == 'Annulé Call')
                    calEvent.colorBar = 'grey';
            } else{
                calEvent.className = 'event-other';
            }
            activitiesList.add(calEvent);
        }

        /*** Traitement des taches ***/
        if(checkTask){
            for(Task tsk: resultTask){
                System.debug('## Task : ' + tsk);
                if(!tsk.IsRecurrence && tsk.ActivityDate != null){
                    String WhatIdTask = tsk.WhatId;
                    DateTime timeDT = tsk.ActivityDate;
                    DateTime createdDT = tsk.createdDate;
                    String chantierNameTask = '';
                    String isActive = '';
                    CalEvent calTask = new CalEvent();

                    // Information de la Task
                    calTask.eventId = tsk.Id;
                    calTask.emplacement = ' ';
                    calTask.title = 'Tache : ' + tsk.Subject;
                    calTask.allDay = true;
                    calTask.startString = timeDT.format(dtFormat) + 'T' + timeDT.format(hourFormat);
                    calTask.endString = timeDT.format(dtFormat) + 'T' + timeDT.format(hourFormat);
                    calTask.priority = tsk.Priority;
                    calTask.createdDate = createdDT.format(dtFormat) + 'T' + createdDT.format(hourFormat);
                    calTask.isTask = true;
                    calTask.className = 'event-task';
                    if (tsk.Status != null)
                        calTask.status = tsk.Status;
                    else
                        calTask.status = '';
                    calTask.url = '/' + tsk.Id;
                    // Informations des utilisateurs
                    calTask.createdName = (allUsers.get(tsk.CreatedById) == null) ? '' : allUsers.get(tsk.CreatedById).Name;
                    calTask.compte = (allAccounts == null || allAccounts.get(tsk.AccountId) == null) ? '' : allAccounts.get(tsk.AccountId).Name;
                    if(allUsers != null && allUsers.get(tsk.OwnerID) != null) {
                        User vendeur = allUsers.get(tsk.OwnerID);
                        calTask.vendeurName = vendeur.Name;
                        calTask.vendeurId = vendeur.Id;
                        calTask.vendeurIcon = vendeur.SmallPhotoUrl;
                    }
                    // Information du projet et chantier
                    if(WhatIdTask != null && WhatIdTask.startsWith('006')) {
                        if(allOpportunities != null && allOpportunities.get(WhatIdTask) != null) {
                            Opportunity opp = allOpportunities.get(WhatIdTask);
                            calTask.origineProjet = opp.LeadSource;
                            chantierNameTask = (allChantiers == null) ? '' : allChantiers.get(opp.chantier__c).Name;
                            /*if(opp.actifParOrigine__c) isActive = 'actif';
                            else isActive = 'passif';*/
                        }
                    } else if(WhatIdTask != null && WhatIdTask.startsWith('a08')){
                        chantierNameTask = (allChantiers == null) ? '' : allChantiers.get(WhatIdTask).Name;
                        //isActive = 'na';
                    } //else isActive = 'na';
                    calTask.chantier = chantierNameTask;
                    calTask.isActive = isActive;
                    activitiesList.add(calTask);
                }
            }
        }
        System.debug('## Nb Event/Task à afficher : ' + activitiesList.size());
        System.debug('### FIN getActivitiesForUser');
        return activitiesList;
    }

    /**
    * @description REMOTEACTION - Cloture d'une tâche
    * @param taskId Id de la tâche
    * @return List<Task> Liste des tâches
    */
    @RemoteAction
    public static List<Task> closeTask(String taskId) {
        System.debug('### DEBUT closeTask');
        try {
            // Modification enregistrement
            List<Task> taskList = [SELECT id, Status FROM Task WHERE Id = :taskId];
            if(!taskList.isEmpty()){
                Task taskToUpdate = taskList.get(0);
                taskToUpdate.Status = 'Terminé';
                update taskToUpdate;
            }
            // Retour a la page
            System.debug('### FIN closeTask');
            return taskList;
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description AuraEnabled - Récupération des RDV de service FSL (Service Appointment) pour affichage sur le tableau     
    * @param codeMagasinActuel Code du magasin
    * @param userRole Role de l'utilisateur courant
    * @param userName Nom du vendeur
    * @param startDatetime Date de début de la période visible du calendrier 
    * @param endDatetime Date de fin de la période visible du calendrier 
    * @return List<ServiceAppointment> Liste des RDV de service
    */
    @AuraEnabled
    public static List<ServiceAppointment> getServiceAppointments(String codeMagasinActuel, String userRole, String userName, Datetime startDatetime, Datetime endDatetime){
        System.debug('### DEBUT getServiceAppointments');
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        String ownerName;
        System.debug('## codeMagasinActuel: '+codeMagasinActuel);
        System.debug('## userRole: '+userRole);
        System.debug('## userName: '+userName);
        System.debug('## startDatetime: '+startDatetime);
        System.debug('## startDatetime: '+endDatetime);

        // Récupération information user 
        User usr = [SELECT Id, FirstName, LastName FROM User WHERE Name = :userName];
        ownerName = usr.LastName+' '+usr.FirstName;
        System.debug('## ownerName: '+ownerName);
        
        // Cas d'un vendeur, affichage uniquement des RDV d'un devis appartenant au vendeur
        if(userRole.contains('K/K - Vendeur')){
            saList = [SELECT Id, Chantier__c, Chantier__r.rue__c, Chantier__r.codePostal__c, Chantier__r.ville__c, Chantier__r.localisation__latitude__s, 
                        Chantier__r.localisation__longitude__s, Chantier__r.adresseGeolocalisation__c, Account.Name,
                        Contact.Name, Contact.Id, opportunityId__c, opportunityName__c, contractNumber__c, ownerName__c, creneauArrivee__c,
                        SchedStartTime, SchedEndTime, DurationType, Duration, WorkType.Name, Longitude, Latitude, ContratK__r.devis__c,
                        ContratK__r.devis__r.OpportunityId
                    FROM ServiceAppointment
                    WHERE Chantier__r.codeMagasinActuel__c = :codeMagasinActuel 
                        AND (ownerName__c = :ownerName OR ContratK__c = null)
                        AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_ENROUTE 
                                OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                        AND SchedStartTime > :startDatetime AND SchedStartTime < :endDatetime]; 
        } else {
            // Autre cas, tous les RDV du magasin sont affichés
            saList = [SELECT Id, Chantier__c, Chantier__r.rue__c, Chantier__r.codePostal__c, Chantier__r.ville__c, Chantier__r.localisation__latitude__s, 
                        Chantier__r.localisation__longitude__s, Chantier__r.adresseGeolocalisation__c, Account.Name,
                        Contact.Name, Contact.Id, opportunityId__c, opportunityName__c, contractNumber__c, ownerName__c, creneauArrivee__c,
                        SchedStartTime, SchedEndTime, DurationType, Duration, WorkType.Name, Longitude, Latitude, ContratK__r.devis__c,
                        ContratK__r.devis__r.OpportunityId
                FROM ServiceAppointment
                WHERE Chantier__r.codeMagasinActuel__c = :codeMagasinActuel 
                AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_ENROUTE
                        OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                AND SchedStartTime > :startDatetime AND SchedStartTime < :endDatetime];                
        }
        System.debug('## saList: '+saList);
        return saList;
    }

    /**
    * @description AuraEnabled - Récupération des informations de l'utilisateur actuel
    * @return User Informations de l'utilisateur actuel
    */
    @AuraEnabled 
    public static User fetchUser() {
        return [SELECT Id,Name FROM User WHERE Id = :userInfo.getUserId()];
    }

    /**
    * @description AuraEnabled - Récupération de l'Id du type d'enregistrement des événements de prospection
    * @return String Id du type d'enregistrement
    */
    @AuraEnabled 
    public static String getEventProspectionRTId() {
        return DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_PROSPECTION_RT);
    }

    /**
    * @description Récupération du magasin de substitution
    * @return PageReference Page de référence
    */
    public PageReference magSubstitution() {
        PageReference magSubstitution = Page.VF_Calendrier;
        magSubstitution.getParameters().put('objectName', objectName);
        magSubstitution.getParameters().put('objectId', objectId);
        magSubstitution.getParameters().put('codeMagasin', codeMagasinSubstitution);
        System.debug(codeMagasinSubstitution);
        magSubstitution.setRedirect(true);
        return magSubstitution;
    }

    // Classe transformant une activité en évènement calendrier
    public class CalEvent{
        public String eventId {get;set;}
        public String title {get;set;}
        public String vendeurName {get;set;}
        public String vendeurId {get;set;}
        public String vendeurIcon {get;set;}
        public Boolean allDay {get;set;}
        public String startString {get;set;}
        public String endString {get;set;}
        public String emplacement {get;set;}
        public String priority {get;set;}
        public String status {get;set;}
        public String url {get;set;}
        public String className {get;set;}
        public String colorBar {get;set;}
        public String compte {get;set;}
        public String createdDate {get;set;}
        public String createdName {get;set;}
        public String chantier {get;set;}
        public String isActive {get;set;}
        public String origineProjet {get;set;}
        public String infoProspec {get;set;}
        public String champProspec {get;set;}
        public Boolean isTask {get;set;}
    }

    // Classe structure pour les informations des vendeurs
    public class VendeurInfos{
        public User Vendeur {get;set;}
        public String RoleName {get;set;}
        public Id UserId {get; set;}
        public String UserName {get; set;}
        public Decimal Distance {get; set;}
        public Boolean isResponsable {get;set;}
        public Integer Position {get;set;}
    }

    // Classe structure pour les informations des objets automatiquement créés
    public class ObjetsInfos{
        public Id accountId {get; set;}
        public Id chantierId {get; set;}
        public Id opportunityId {get; set;}
        public String contactId {get; set;}
        public Id vendeurId {get; set;}
        public String accountName {get; set;}
        public String contactName {get; set;}
        public String oppName {get; set;}
        public String vendeurName {get; set;}
    }
}