//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Triptyque_Analytique
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/09/2019
//-- Version     : 1.3
//-- * 1.3 - RQM-113 : Ajout des constantes pour les nouveaux rôles/profils
//-- * 1.2 - CRM-757 : Ajout des nouveaux rôles pour la picklist des magasins
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Triptyque_Analytique {
    public User actualUser { get; set; }
    public Profile actualUserProfile { get; set; }
    public List<SelectOption> magasinOptionList { get; set; }
    public Map<String,String> magasinsMap { get; set; }
    public string codeMagasinActuel { get; set; }
    public string libelleMagasinActuel { get; set; }
    public List<User> vendeursList { get; set; }
    public List<User> allVendeursList { get; set; }
    public Map<String, Integer> vendeursListNbConnexions { get; set; }
    public String vendeursListJSON { get; set; }
    public String vendeursListNbConnexionsJSON { get; set; }

    public List<IndicateursVendeurAll> valeursExportPDF { get; set; }
    public String dateDebutExport { get; set; }
    public String dateFinExport { get; set; }
    public String dateExportFormated { get; set; }
    public Boolean showLegende {get { return PropertiesUtils.getBooleanValue('triptyque.pdf.legende', true); } set;}
    public String walkMeURL {get { return PropertiesUtils.getStringValue('walkme.snippet.url', ''); } set;}

    private static final List<String> statutRDVNonEffectue = new List<String> { 'Non effectué', 'Non effectué (avec déplacement)' };
    private static final Set<String> sourcesDevis = new Set<String> { 'BAL VENDEUR', 'PORTE A PORTE VENDEUR', 'COMPLEMENT VENDEUR',
                                                                        'PARRAINAGE VENDEUR', 'STAND MARCHE VENDEUR', 'TELEPHONE VENDEUR' };
    private static final Id RT_RDVCommercial = DAL.getRecordTypeIdByDevName(Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id RT_RDVProspection = DAL.getRecordTypeIdByDevName(Constants.ACTIVITE_PROSPECTION_RT);

    /**
    *
    *   GETTER : Récupération de la date de début
    *
    **/
    public String dateDebut { get; set; }{
        Datetime ajd = Date.today();
        Date ajdDate = Date.today();
        Datetime hier;

        if(ajdDate.toStartofWeek() == ajdDate) hier = ajd.addDays(-2);
        else hier = ajd.addDays(-1);

        String ajdFormate = hier.format('dd/MM/yyyy');
        system.debug('ajdFormate : ' + ajdFormate);
        dateDebut = ajdFormate;
    }

    /**
    *
    *   GETTER : Récupération de la date de fin
    *
    **/
    public String dateFin { get; set; }{
        Datetime ajd = Date.today();
        Date ajdDate = Date.today();
        Datetime hier;

        if(ajdDate.toStartofWeek() == ajdDate) hier = ajd.addDays(-2);
        else hier = ajd.addDays(-1);

        String ajdFormate = hier.format('dd/MM/yyyy');
        system.debug('ajdFormate : ' + ajdFormate);
        dateFin = ajdFormate;
    }

    /**
    *
    *   Fonction appelée lors l'ouverture de la page pour incrémentation des stats
    *
    **/
    public void insertUserStats() {
        insertUserStatsFuture(Userinfo.getUserId());
    }

    /**
    *
    *   Fonction asynchrone pour incrémentation statistique utilisateur
    *
    **/
    @future
    public static void insertUserStatsFuture(Id userId) {
        List<UserStats__c> userStats = new List<UserStats__c>();
        UserStats__c stats;
        List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, compteurTriptyqueAnalysePonctuelle__c
                                            FROM UserStats__c
                                            WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

        if (statsList.isEmpty()) {
                stats = new UserStats__c(name = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
                                        user__c                 = UserInfo.getUserId(),
                                        date__c                 = System.today(),
                                        compteurTriptyqueAnalysePonctuelle__c    = 0);
        } else
            stats = statsList[0];
        system.debug('stats.compteurTriptyqueAnalysePonctuelle__c : ' + stats.compteurTriptyqueAnalysePonctuelle__c);
        stats.compteurTriptyqueAnalysePonctuelle__c = stats.compteurTriptyqueAnalysePonctuelle__c + 1;
        system.debug('stats.compteurTriptyqueAnalysePonctuelle__c : ' + stats.compteurTriptyqueAnalysePonctuelle__c);
        userStats.add(stats);
        if (!userStats.isEmpty())
            upsert userStats;
    }

    /**
    *
    *   Constructeur
    *
    **/
    public Ctrl_Triptyque_Analytique() {
        magasinsMap = new Map<String,String>();

        // Récupération des informations de l'utilisateur pour magasin
        actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, LastLoginDate,
                            CreatedDate, UserRoleId, UserRole.Name, ProfileId, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
        actualUserProfile = [SELECT id, name FROM Profile WHERE Id = :actualUser.ProfileId];
        /*if ((actualUser.CodeDR__c == null || actualUser.CodeDR__c == '*') && (actualUser.CodeDV__c == null || actualUser.CodeDV__c == '*') && (actualUser.CodeMagasin__c == null || actualUser.CodeMagasin__c == '*'))
            magasinsMap = DAL_Cartographie.getAllMagasins();
        else if(actualUser.UserRole.Name.containsIgnoreCase(' - REF - ') ){
            // Cas d'un référent  (JMU / CRM-757 / 14-03-2016)
            magasinsMap = DAL_Cartographie.getAllMagasinsByRole(actualUser.UserRole);
        } else {
            magasinsMap = DAL_Cartographie.getAllMagasinsByUser(actualUser);
        }*/
        UserContext context = UserContext.getContext(Userinfo.getUserId());
        magasinsMap = context.getMagasins();

        // Trie
        List<String> libelleMagasinList = new List<String>(magasinsMap.Values());
        libelleMagasinList.sort();

        // Initialisation de la picklist de sélection de magasin
        magasinOptionList = new List<SelectOption>();
        for(String libelleMag : libelleMagasinList) {
            for (String code : magasinsMap.keySet()) {
                if(magasinsMap.get(code) == libelleMag) {
                    magasinOptionList.add(new SelectOption(code, magasinsMap.get(code)));
                    break;
                }
            }
        }

        // Initialisation sur le premier magasin de la liste si disponible
        if(actualUser.CodeMagasin__c != null && actualUser.CodeMagasin__c != '*') {
            codeMagasinActuel = actualUser.CodeMagasin__c;
            libelleMagasinActuel = actualUser.libelleMagasin__c;
        } else if (!magasinsMap.isEmpty() && magasinsMap != null) {
            codeMagasinActuel = magasinOptionList.get(0).getValue();
            libelleMagasinActuel = magasinOptionList.get(0).getLabel();
        }
        if(magasinOptionList.isEmpty()) magasinOptionList.add(new SelectOption('Aucun', 'Aucun'));
        system.debug('magasinOptionList ' + magasinOptionList.get(0).getValue());

        // Initialisation de la liste des vendeurs à afficher
        vendeursList = new List<User>();
        vendeursListNbConnexions = new Map<String, Integer>();
        refreshVendeurs();
    }

    /**
    *
    *   Récupération des vendeurs du magasin
    *
    **/
    public void refreshVendeurs() {
        if(dateDebut != null && dateDebut != '' && dateFin != null && dateFin != ''){
            Date startDateFormat = Date.parse(dateDebut);
            Date endDateFormat = Date.parse(dateFin);
            system.debug('startDateFormat : ' + startDateFormat);
            system.debug('endDateFormat : ' + endDateFormat);

            libelleMagasinActuel = magasinsMap.get(codeMagasinActuel);
            system.debug('codeMagasinActuel : ' + codeMagasinActuel);
            system.debug('libelleMagasinActuel : ' + libelleMagasinActuel);

            // Si Vendeur, on ajoute seulement le vendeur
            if(actualUserProfile.Name == Constants.PROFIL_Vendeur) {
                if(vendeursList.isEmpty()) vendeursList.add(actualUser);
            }
            /*else if (actualUserProfile.Name.containsIgnoreCase('K/K - RVJ')) {
                // Si RVJ, on ajoute les vendeurs du magasins sauf RV
                allVendeursList = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, isActive, LastLoginDate, CreatedDate,
                                    (SELECT Id FROM ObjectifsVendeur__r) FROM User
                                    WHERE codeMagasin__c = :codeMagasinActuel AND Profile.Name = :Constants.PROFIL_Vendeur ORDER BY LastName ASC];
                allVendeursList.add(actualUser);
            }*/ else {
                // Si RV et supérieur, on ajoute tous les vendeurs du magasin
                allVendeursList = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, isActive, LastLoginDate, CreatedDate,
                                    (SELECT nbVentesS5__c, nbVentesS4__c, nbVentesS3__c, nbVentesS2__c, nbVentesS1__c, nbContactsActifsS5__c, nbContactsActifsS4__c,
                                            nbContactsActifsS3__c, nbContactsActifsS2__c, nbContactsActifsS1__c, moisObjectif__c, chiffreAffaireVenduS5__c,
                                            chiffreAffaireVenduS4__c, chiffreAffaireVenduS3__c, chiffreAffaireVenduS2__c, chiffreAffaireVenduS1__c, anneeObjectif__c
                                        FROM ObjectifsVendeur__r) FROM User
                                    WHERE codeMagasin__c = :codeMagasinActuel ORDER BY LastName ASC];
            }
            system.debug('actualUserProfile.Name : ' + actualUserProfile.Name);
            system.debug('allVendeursList : ' + allVendeursList);

            // Affiche seulement les vendeurs dont la date de création est inférieur à la date de fin de recherche
            // et dont la date de dernière connexion est supérieur à la date de début de recherche
            if(!actualUserProfile.Name.containsIgnoreCase('Vendeur')) {
                vendeursList.clear();
                for(User vendeur : allVendeursList) {
                    if((vendeur.CreatedDate != null && vendeur.CreatedDate.date() <= endDateFormat)
                        && (vendeur.LastLoginDate != null && vendeur.LastLoginDate.date() >= startDateFormat))
                    {
                        vendeursList.add(vendeur);
                    }
                }
            }
            system.debug('vendeursList : ' + vendeursList);

            // Récupération du nombre de connexion dans la période des vendeurs
            vendeursListNbConnexions.clear();
            for (AggregateResult nbConnexions : [SELECT UserId vendeur, COUNT(Id) total From LoginHistory
                                                    WHERE UserId IN :vendeursList AND DAY_ONLY(LoginTime) >= :startDateFormat AND DAY_ONLY(LoginTime) <= :endDateFormat GROUP BY UserId]) {
                vendeursListNbConnexions.put((String)nbConnexions.get('vendeur'), (Integer)nbConnexions.get('total'));
            }
            for(User vendeur : vendeursList) {
                if(vendeursListNbConnexions.get(vendeur.Id) == null) {
                    vendeursListNbConnexions.put(vendeur.Id, 0);
                }
            }
            system.debug('vendeursListNbConnexions : ' + vendeursListNbConnexions);
        }
        // Sérialisation pour utilisation en JS
        vendeursListJSON = JSON.serialize(vendeursList);
        vendeursListNbConnexionsJSON = JSON.serialize(vendeursListNbConnexions);
    }

    public PageReference setDeb() {
        system.debug('dateDebut : ' + dateDebut);
        return null;
    }

    public PageReference setFin() {
        return null;
    }

    /**
    *
    *   Récupération des informations hebdomadaires pour les vendeurs du magasin
    *
    **/
    @RemoteAction
    public static List<IndicateursVendeurHebdomadaire> getHebdomadaireData(String startDate, String endDate, List<String> vendeursIdList) {
        Map<String, Set<Date>> vendeurNbActiveDays = new Map<String, Set<Date>>();
        Map<String, List<Event>> vendeurEvents = new Map<String, List<Event>>();
        List<IndicateursVendeurHebdomadaire> indicateursVendeurList = new List<IndicateursVendeurHebdomadaire>();
        system.debug('DEBUT getHebdomadaireData');

        Date startDateFormat = Date.parse(startDate);
        Date endDateFormat = Date.parse(endDate);
        system.debug('startDateFormat : ' + startDateFormat);
        system.debug('endDateFormat : ' + endDateFormat);

        try {
            if(vendeursIdList != null && !vendeursIdList.isEmpty()) {
                // Récupération des devis vendu des vendeurs
                Map<Id, AggregateResult> vendeurQuotesVendu = new Map<Id, AggregateResult>([SELECT Opportunity.OwnerId Id, COUNT(Id) total, SUM(TotalHTDevis__c) ca
                                                                                            FROM Quote
                                                                                            WHERE dateAcceptationClient__c >= :startDateFormat
                                                                                              AND dateAcceptationClient__c <= :endDateFormat
                                                                                              AND status LIKE 'Vendu%'
                                                                                              AND opportunity.ownerId IN :vendeursIdList
                                                                                            GROUP BY opportunity.ownerId]);

                // Récupération du nombre de jours travaillés (Fix pour éviter erreur de queryMore())
                for (Event eventResult : [SELECT OwnerId, ActivityDate
                                          FROM Event
                                          WHERE ActivityDate >= :startDateFormat
                                            AND ActivityDate <= :endDateFormat
                                            AND IsDeleted = false
                                            AND Type NOT IN :Constants.EVENT_ACTIVITE_CONGE_TYPES
                                            AND OwnerId IN :vendeursIdList]) {
                    Set<Date> dateList = new Set<Date>();
                    if(vendeurNbActiveDays.get(eventResult.OwnerId) != null)
                        dateList = vendeurNbActiveDays.get(eventResult.OwnerId);
                    dateList.add(eventResult.ActivityDate);
                    vendeurNbActiveDays.put(eventResult.OwnerId, dateList);
                }

                // Récupération des activités (événements) pour la semaine des vendeurs
                DateTime dtBegin = DateTime.newInstance(startDateFormat.year(), startDateFormat.month(), startDateFormat.day(), 0, 0, 0);
                DateTime dtEnd = DateTime.newInstance(endDateFormat.year(), endDateFormat.month(), endDateFormat.day(), 23, 59, 59);
                List<Event> eventsResult = [SELECT Id, OwnerId, Type, nbBAL50__c, NbTAP51__c, NbPhone55__c, StatutRDV__c, IsAllDayEvent, CreatedDate, ActivityDate,
                                                   StartDateTime, EndDateTime, RecordTypeId, WhatId, IsChild, Subject
                                            FROM Event
                                            WHERE (recordTypeId = :RT_RDVCommercial OR recordTypeId = :RT_RDVProspection)
                                              AND (
                                                   (createdDate >= :dtBegin AND createdDate <= :dtEnd)
                                                   OR
                                                   (activityDate >= :startDateFormat AND activityDate <= :endDateFormat)
                                                  )
                                              AND isDeleted = false
                                              AND ownerId IN :vendeursIdList];
                Set<String> OppId = new Set<String>();
                for(Event event : eventsResult){
                    if (event.type == 'R1')
                      OppId.add(event.WhatId);
                    List<Event> eventList;
                    if(vendeurEvents.get(event.OwnerId) != null)
                      eventList = vendeurEvents.get(event.OwnerId);
                    else {
                      eventList = new List<Event>();
                      vendeurEvents.put(event.OwnerId, eventList);
                    }

                    eventList.add(event);
                }


                Map<Id, Opportunity> vendeurOppEvents = new Map<Id, Opportunity>([SELECT Id, OwnerId, actifParOrigine__c, accountSource__c, leadSource
                                                                                  FROM Opportunity
                                                                                  WHERE OwnerId IN :vendeursIdList
                                                                                    AND Id IN :OppId]);

                // Construction de la liste de résultat
                for(String vendeur : vendeursIdList) {
                    Decimal nbRDVTotal = 0;
                    Decimal nbRDVR1_Pris = 0;
                    Decimal nbRDVR1_Effec = 0;
                    Decimal nbRDVR2_Pris = 0;
                    Decimal nbRDVR2_Effec = 0;
                    Decimal nbRDVBAL50 = 0;
                    Decimal nbRDVTAP51 = 0;
                    Decimal nbRDVPhone55 = 0;
                    Decimal nbRDVGalerieMarchande = 0;
                    Decimal nbRDVFoire = 0;
                    Decimal nbRDVMarche = 0;
                    Decimal nbRDVTotalWithCreatedDate = 0;
                    Decimal nbRDVTotalNonPris = 0;
                    Decimal nbRDVCreatedRdvDate = 0;
                    Decimal nbRDVDebrief = 0;
                    Decimal nbRDVCreeAPosteriori = 0;
                    Decimal nbRDVADebriefer = 0;
                    Decimal nbRDVAccompagne = 0;
                    Decimal nbRDVAccompagnant = 0;
                    Decimal nbContactActif = 0;
                    Decimal nbContactPassif = 0;
                    Decimal nbContactBAL = 0;
                    Decimal nbContactTAP = 0;
                    Decimal nbContactPhone = 0;
                    Decimal nbContactComplement = 0;
                    Decimal nbContactParrainage = 0;
                    Decimal nbContactGalerieMarchande = 0;
                    Decimal nbContactFoire = 0;
                    Decimal nbContactMarche = 0;

                    if(vendeurEvents.get(vendeur) != null) {
                        for(Event event : vendeurEvents.get(vendeur)) {
                            // Nombre de RDV en tant qu'accompagnant et en tant qu'accompagné
                            if(event.StartDateTime >= startDateFormat && event.StartDateTime <= endDateFormat.addDays(1)){
                                if(!event.IsChild && event.RecordTypeId == RT_RDVCommercial) nbRDVAccompagne = nbRDVAccompagne + 1;
                                if(event.IsChild && event.RecordTypeId == RT_RDVCommercial) nbRDVAccompagnant = nbRDVAccompagnant + 1;
                            }

                            // Calcul Créés à Posteriori et A débriefer
                            if(event.StatutRDV__c != 'Déplacé' && (event.CreatedDate.Date() >= startDateFormat && event.CreatedDate.Date() <= endDateFormat) && (event.StartDateTime <= event.CreatedDate) && (event.Type == 'R1' || event.Type == 'R2' || event.Type == 'R+'))
                              nbRDVCreeAPosteriori = nbRDVCreeAPosteriori + 1;
                            if(event.StatutRDV__c == 'Pris' && (Datetime.now() > event.StartDateTime.Date()) && (event.StartDateTime.Date() >= startDateFormat) && (event.StartDateTime.Date() <= endDateFormat))
                              nbRDVADebriefer = nbRDVADebriefer + 1;
                            system.debug(vendeur + 'avec' + event + 'avec' + date.today() + 'avec' + event.StartDateTime);

                            // Gestion des RDV
                            if((event.ActivityDate >= startDateFormat) && (event.ActivityDate <= endDateFormat)){
                                // Calcul R1, R2 et R+
                                if (event.Type == 'R1') {
                                    if(event.StatutRDV__c == 'Pris')
                                      nbRDVR1_Pris = nbRDVR1_Pris + 1;
                                    else if (event.StatutRDV__c == 'Effectué')
                                      nbRDVR1_Effec = nbRDVR1_Effec + 1;
                                }
                                else if (event.Type == 'R2' || event.Type == 'R+') {
                                    if (event.StatutRDV__c == 'Pris')
                                      nbRDVR2_Pris = nbRDVR2_Pris + 1;
                                    else if (event.StatutRDV__c == 'Effectué')
                                      nbRDVR2_Effec = nbRDVR2_Effec + 1;
                                }
                                // Calcul des indicateur des événements
                                else if (event.Type == 'Prospection physique' || event.Type == 'Visite de pose') {
                                    if(event.nbBAL50__c != null)
                                      nbRDVBAL50 = nbRDVBAL50 + event.nbBAL50__c;
                                    if(event.NbTAP51__c != null)
                                      nbRDVTAP51 = nbRDVTAP51 + event.NbTAP51__c;
                                }
                                else if (event.Type == 'Phone') {
                                    if(event.NbPhone55__c != null)
                                      nbRDVPhone55 = nbRDVPhone55 + event.NbPhone55__c;
                                }
                                else if (event.Type == 'Stand/Galerie Marchande')
                                    nbRDVGalerieMarchande = nbRDVGalerieMarchande + (event.IsAllDayEvent ? 2 : 1);
                                else if (event.Type == 'Foire')
                                    nbRDVFoire = nbRDVFoire + (event.IsAllDayEvent ? 2 : 1);
                                else if(event.Type == 'Stand/Marché')
                                    nbRDVMarche = nbRDVMarche + (event.IsAllDayEvent ? 2 : 1);
                            }

                            if (event.recordTypeId == RT_RDVCommercial) {
                              if (event.ActivityDate == event.CreatedDate.date())
                                nbRDVTotalWithCreatedDate = nbRDVTotalWithCreatedDate + 1;
                              if (event.StatutRDV__c != 'Pris')
                                nbRDVTotalNonPris = nbRDVTotalNonPris + 1;
                            }

                            if(event.Type == 'R1') {
                              // Lien avec les infos du projet
                              Opportunity opp = vendeurOppEvents.get(event.whatId);
                              if(opp != null) {
                                // Calcul Actif et Passif (Compte passif si origine call est renseignée, sinon actif)
                                if (event.CreatedDate.date() >= startDateFormat && event.CreatedDate.date() <= endDateFormat) {
                                  if (opp.actifParOrigine__c)
                                    nbContactActif = nbContactActif + 1;
                                  else
                                    nbContactPassif = nbContactPassif + 1;

                                  // Calcul du nombre des comptes avec source
/* >>> F.G., le 30/09/2015
                                  if(opp.accountSource__c == 'BAL VENDEUR') nbContactBAL = nbContactBAL + 1;
                                  if(opp.accountSource__c == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP + 1;
                                  if(opp.accountSource__c == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone + 1;
                                  if(opp.accountSource__c == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement + 1;
                                  if(opp.accountSource__c == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage + 1;
                                  if(opp.accountSource__c == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande + 1;
                                  if(opp.accountSource__c == 'FOIRE') nbContactFoire = nbContactFoire + 1;
                                  if(opp.accountSource__c == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche + 1;
   --- F.G., le 30/09/2015 */
                                  if(opp.leadSource == 'BAL VENDEUR') nbContactBAL = nbContactBAL + 1;
                                  if(opp.leadSource == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP + 1;
                                  if(opp.leadSource == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone + 1;
                                  if(opp.leadSource == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement + 1;
                                  if(opp.leadSource == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage + 1;
                                  if(opp.leadSource == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande + 1;
                                  if(opp.leadSource == 'FOIRE') nbContactFoire = nbContactFoire + 1;
                                  if(opp.leadSource == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche + 1;
/* <<< F.G., le 30/09/2015 */
                                }

                                if (event.StartDateTime.date() >= startDateFormat && event.StartDateTime.date() <= endDateFormat && (event.StatutRDV__c == statutRDVNonEffectue[1] || event.StatutRDV__c == statutRDVNonEffectue[0])) {
                                  if(opp.actifParOrigine__c)
                                    nbContactActif = nbContactActif - 1;
                                  else
                                    nbContactPassif = nbContactPassif - 1;

                                  // Calcul du nombre des comptes avec source
/* >>> F.G., le 30/09/2015
                                  if (opp.accountSource__c == 'BAL VENDEUR') nbContactBAL = nbContactBAL - 1;
                                  if (opp.accountSource__c == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP - 1;
                                  if (opp.accountSource__c == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone - 1;
                                  if (opp.accountSource__c == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement - 1;
                                  if (opp.accountSource__c == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage - 1;
                                  if (opp.accountSource__c == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande - 1;
                                  if (opp.accountSource__c == 'FOIRE') nbContactFoire = nbContactFoire - 1;
                                  if (opp.accountSource__c == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche - 1;
   --- F.G., le 30/09/2015 */
                                  if (opp.leadSource == 'BAL VENDEUR') nbContactBAL = nbContactBAL - 1;
                                  if (opp.leadSource == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP - 1;
                                  if (opp.leadSource == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone - 1;
                                  if (opp.leadSource == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement - 1;
                                  if (opp.leadSource == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage - 1;
                                  if (opp.leadSource == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande - 1;
                                  if (opp.leadSource == 'FOIRE') nbContactFoire = nbContactFoire - 1;
                                  if (opp.leadSource == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche - 1;
/* <<< F.G., le 30/09/2015 */
                                }
                              }
                            }
                        }
                    }

                    // Construction résultat
                    //***************************
                    IndicateursVendeurHebdomadaire resultat = new IndicateursVendeurHebdomadaire();
                    resultat.vendeurId = vendeur;
                    resultat.joursTravaille = (vendeurNbActiveDays.get(vendeur) == null) ? 0 : vendeurNbActiveDays.get(vendeur).size();
                    resultat.nbRDVAccompagne = nbRDVAccompagne;
                    resultat.nbRDVAccompagnant = nbRDVAccompagnant;
                    resultat.nbContactActif = nbContactActif;
                    resultat.nbContactPassif = nbContactPassif;
                    resultat.nbRDVTotal = nbRDVR1_Pris + nbRDVR2_Pris + nbRDVR1_Effec + nbRDVR2_Effec;
                    if (vendeurQuotesVendu.get(vendeur) != null) {
                        Decimal devisCA = (Decimal)vendeurQuotesVendu.get(vendeur).get('ca');
                        if(devisCA != null)
                          resultat.nbCADevisVendu = Math.round((devisCA / 1000).setScale(2, RoundingMode.HALF_EVEN));
                        else
                          resultat.nbCADevisVendu = 0;
                    }
                      else resultat.nbCADevisVendu = 0;
                    resultat.nbDevisVendu = (vendeurQuotesVendu.get(vendeur) == null) ? 0 : (Integer) vendeurQuotesVendu.get(vendeur).get('total');
                    resultat.nbRDVCreatedRdvDate = nbRDVCreeAPosteriori;
                    resultat.nbRDVDebrief = nbRDVADebriefer;
                    resultat.nbRDVR1_Pris = nbRDVR1_Pris;
                    resultat.nbRDVR1_Effec = nbRDVR1_Effec;
                    resultat.nbRDVR2_Pris = nbRDVR2_Pris;
                    resultat.nbRDVR2_Effec = nbRDVR2_Effec;
                    resultat.nbRDVBAL50 = nbRDVBAL50;
                    resultat.nbContactBAL = nbContactBAL;
                    resultat.nbRDVTAP51 = nbRDVTAP51;
                    resultat.nbContactTAP = nbContactTAP;
                    resultat.nbContactComplement = nbContactComplement;
                    resultat.nbContactParrainage = nbContactParrainage;
                    resultat.nbRDVPhone55 = nbRDVPhone55;
                    resultat.nbContactPhone = nbContactPhone;
                    resultat.nbRDVGalerieMarchande = nbRDVGalerieMarchande;
                    resultat.nbContactGalerieMarchande = nbContactGalerieMarchande;
                    resultat.nbRDVFoire = nbRDVFoire;
                    resultat.nbContactFoire = nbContactFoire;
                    resultat.nbRDVMarche = nbRDVMarche;
                    resultat.nbContactMarche = nbContactMarche;
                    //resultat.objectifContactTotal = resultat.objectifContactActif;
                    resultat.nbContactTotal = nbContactActif + nbContactPassif;

                    // Calcul
                    //***************************
                    // Taux de réalisation : % du réalisé par rapport aux objectifs
                    // Taux Transformation des RDV : % de RDV par rapport au nombre total de contacts réalisés
                    resultat.tauxTransformationRDV = (resultat.nbContactTotal == 0) ? 0 : ((resultat.nbRDVTotal / resultat.nbContactTotal) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    // Taux Transformation des ventes : % de ventes par rapport au nombre total de RDV réalisés
                    resultat.tauxTransformationVentes = (resultat.nbRDVTotal == 0) ? 0 : ((resultat.nbDevisVendu / resultat.nbRDVTotal) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    // Taux de participation aux contacts vente : % de contacts réalisés sur l'origine observée par rapport aux nombre total de contacts de type vente/actifs réalisés
                    resultat.tauxPartContactBAL = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactBAL / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactTAP = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactTAP / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactCOMP = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactComplement / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactPHONE = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactPhone / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactGM = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactGalerieMarchande / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactFOIRE = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactFoire / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactMARCHE = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactMarche / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.panierMoyenRealiseVente = (resultat.nbDevisVendu == 0) ? 0 : (resultat.nbCADevisVendu / resultat.nbDevisVendu).setScale(2, RoundingMode.HALF_EVEN);
                    // CRM-610 JMU : Nombre de RDVs & Ratios sur les nombres d'argument par origine
                    resultat.ratioParJourBAL = (resultat.joursTravaille == 0) ? 0 : ((resultat.nbRDVBAL50 / resultat.joursTravaille)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParContactBAL = (resultat.nbContactBAL == 0) ? 0 : ((resultat.nbRDVBAL50 / resultat.nbContactBAL)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParJourTAP = (resultat.joursTravaille == 0) ? 0 : ((resultat.nbRDVTAP51 / resultat.joursTravaille)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParContactTAP = (resultat.nbContactTAP == 0) ? 0 : ((resultat.nbRDVTAP51 / resultat.nbContactTAP)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParJourPhone = (resultat.joursTravaille == 0) ? 0 : ((resultat.nbRDVPhone55 / resultat.joursTravaille)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParContactPhone = (resultat.nbContactPhone == 0) ? 0 : ((resultat.nbRDVPhone55 / resultat.nbContactPhone)).setScale(2, RoundingMode.HALF_EVEN);

                    indicateursVendeurList.add(resultat);
                }
            }
            system.debug('FIN getHebdomadaireData');
            return indicateursVendeurList;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   Fonction formatant le résultat pour l'export PDF
    *
    **/
    public List<IndicateursVendeurAll> formatValeursExport(String dateDebutExport, String dateFinExport) {
        // Initialisation des objets / Compteurs
        List<IndicateursVendeurAll> finalresult = new List<IndicateursVendeurAll>();
        List<IndicateursVendeurHebdomadaire> hebdoresult = new List<IndicateursVendeurHebdomadaire>();
        List<IndicateursVendeurTotaux> totauxresult = new List<IndicateursVendeurTotaux>();
        IndicateursVendeurTotaux resTotaux = new IndicateursVendeurTotaux();
        Integer compteur = 0;
        Integer i = 1;
        Decimal j = 0;

        // Initialisation du tableau des semaines
        Map<Integer, List<Integer>> Somme_valeursMensuelByWeek = new Map<Integer, List<Integer>>();
        Integer Somme_objectifcaDevisS1 = 0;
        Integer Somme_caDevisS1 = 0;
        Integer Somme_nbContactActifS1 = 0;
        Integer Somme_nbContactPassifS1 = 0;
        Integer Somme_objectifcaDevisS2 = 0;
        Integer Somme_caDevisS2 = 0;
        Integer Somme_nbContactActifS2 = 0;
        Integer Somme_nbContactPassifS2 = 0;
        Integer Somme_objectifcaDevisS3 = 0;
        Integer Somme_caDevisS3 = 0;
        Integer Somme_nbContactActifS3 = 0;
        Integer Somme_nbContactPassifS3 = 0;
        Integer Somme_objectifcaDevisS4 = 0;
        Integer Somme_caDevisS4 = 0;
        Integer Somme_nbContactActifS4 = 0;
        Integer Somme_nbContactPassifS4 = 0;
        Integer Somme_objectifcaDevisS5 = 0;
        Integer Somme_caDevisS5 = 0;
        Integer Somme_nbContactActifS5 = 0;
        Integer Somme_nbContactPassifS5 = 0;
        // Initialisation des totaux (CRM-610 JMU)
        resTotaux.Somme_nbRDVHebdoAccompagne = 0;
        resTotaux.Somme_nbRDVHebdoAccompagnant = 0;
        // Initialisation des totaux
        resTotaux.Somme_nbContactTotal = 0;
        resTotaux.Somme_nbContactActif = 0;
        resTotaux.Somme_nbContactPassif = 0;
        resTotaux.Somme_nbRDVTotal = 0;
        resTotaux.Somme_nbDevisVendu = 0;
        resTotaux.Somme_nbRDVCreatedRdvDate = 0;
        resTotaux.Somme_nbRDVDebrief = 0;
        resTotaux.Somme_nbRDVR1_Pris = 0;
        resTotaux.Somme_nbRDVR1_Effec = 0;
        resTotaux.Somme_nbRDVR2_Pris = 0;
        resTotaux.Somme_nbRDVR2_Effec = 0;
        resTotaux.Somme_nbRDVBAL50 = 0;
        resTotaux.Somme_nbContactBAL = 0;
        resTotaux.Somme_nbRDVTAP51 = 0;
        resTotaux.Somme_nbContactTAP = 0;
        resTotaux.Somme_nbContactComplement = 0;
        resTotaux.Somme_nbContactParrainage = 0;
        resTotaux.Somme_nbRDVPhone55 = 0;
        resTotaux.Somme_nbContactPhone = 0;
        resTotaux.Somme_nbRDVGalerieMarchande = 0;
        resTotaux.Somme_nbContactGalerieMarchande = 0;
        resTotaux.Somme_nbRDVFoire = 0;
        resTotaux.Somme_nbContactFoire = 0;
        resTotaux.Somme_nbRDVMarche = 0;
        resTotaux.Somme_nbContactMarche = 0;
        resTotaux.Somme_nbDevisVendu = 0;
        resTotaux.Somme_nbCADevisVendu = 0;
        resTotaux.Somme_realisationContact = 0;
        resTotaux.Somme_panierMoyenRealiseVente = 0;

        // Récupération des ID vendeurs et des résultats des Remote Action
        List<String> vendeursIdList = new List<String>();
        for(User use : vendeursList) {
            vendeursIdList.add(use.Id);
        }
        hebdoresult = Ctrl_Triptyque_Analytique.getHebdomadaireData(dateDebutExport, dateFinExport, vendeursIdList);

        Integer index = 0;
        for(User vendeur : vendeursList) {
            IndicateursVendeurAll resAll = new IndicateursVendeurAll();
            IndicateursVendeurHebdomadaire resHebdomadaire = new IndicateursVendeurHebdomadaire();
            compteur++;
            i=1;
            j=0;

            for(IndicateursVendeurHebdomadaire IVHData : hebdoresult){
                if(vendeur.Id == IVHData.vendeurId){
                    resHebdomadaire = IVHData;
                }
            }

            // Préparation des résultats (pour chaque vendeur)
            resAll.vendeurId = vendeur.Id;
            resAll.vendeurName = vendeur.Name;
            resAll.vendeurActive = vendeur.IsActive;
            resAll.vendeurLastLoginDate = vendeur.LastLoginDate;
            resAll.vendeurNbLogin = vendeursListNbConnexions.get(vendeur.Id);
            resAll.IVH = resHebdomadaire;
            system.debug('resAll.IVH.nbDevisVendu : ' + resAll.IVH.nbDevisVendu);

            // Récupération des résultats (totaux CRM-610 JMU)
            resTotaux.Somme_nbRDVHebdoAccompagne += resAll.IVH.nbRDVAccompagne;
            resTotaux.Somme_nbRDVHebdoAccompagnant += resAll.IVH.nbRDVAccompagnant;
            // Récupération des résultats (totaux)
            resTotaux.Somme_nbContactTotal += resAll.IVH.nbContactTotal;
            resTotaux.Somme_nbContactActif += resAll.IVH.nbContactActif;
            resTotaux.Somme_nbContactPassif += resAll.IVH.nbContactPassif;
            resTotaux.Somme_nbRDVTotal += resAll.IVH.nbRDVTotal;
            resTotaux.Somme_nbDevisVendu += resAll.IVH.nbDevisVendu;
            resTotaux.Somme_nbRDVCreatedRdvDate += resAll.IVH.nbRDVCreatedRdvDate;
            resTotaux.Somme_nbRDVDebrief += resAll.IVH.nbRDVDebrief;
            resTotaux.Somme_nbRDVR1_Pris += resAll.IVH.nbRDVR1_Pris;
            resTotaux.Somme_nbRDVR1_Effec += resAll.IVH.nbRDVR1_Effec;
            resTotaux.Somme_nbRDVR2_Pris += resAll.IVH.nbRDVR2_Pris;
            resTotaux.Somme_nbRDVR2_Effec += resAll.IVH.nbRDVR2_Effec;
            resTotaux.Somme_nbRDVBAL50 += resAll.IVH.nbRDVBAL50;
            resTotaux.Somme_nbContactBAL += resAll.IVH.nbContactBAL;
            resTotaux.Somme_nbRDVTAP51 += resAll.IVH.nbRDVTAP51;
            resTotaux.Somme_nbContactTAP += resAll.IVH.nbContactTAP;
            resTotaux.Somme_nbContactComplement += resAll.IVH.nbContactComplement;
            resTotaux.Somme_nbContactParrainage += resAll.IVH.nbContactParrainage;
            resTotaux.Somme_nbRDVPhone55 += resAll.IVH.nbRDVPhone55;
            resTotaux.Somme_nbContactPhone += resAll.IVH.nbContactPhone;
            resTotaux.Somme_nbRDVGalerieMarchande += resAll.IVH.nbRDVGalerieMarchande;
            resTotaux.Somme_nbContactGalerieMarchande += resAll.IVH.nbContactGalerieMarchande;
            resTotaux.Somme_nbRDVFoire += resAll.IVH.nbRDVFoire;
            resTotaux.Somme_nbContactFoire += resAll.IVH.nbContactFoire;
            resTotaux.Somme_nbRDVMarche += resAll.IVH.nbRDVMarche;
            resTotaux.Somme_nbContactMarche += resAll.IVH.nbContactMarche;
            resTotaux.Somme_nbCADevisVendu += resAll.IVH.nbCADevisVendu;

            // Ajout des valeurs uniques dans le résultat (totaux)
            if(compteur == vendeursList.size()){
                resTotaux.Somme_panierMoyenRealiseVente = (resTotaux.Somme_nbDevisVendu == 0) ? 0 : (resTotaux.Somme_nbCADevisVendu / resTotaux.Somme_nbDevisVendu).setScale(2, RoundingMode.HALF_EVEN);
                resAll.IVT = resTotaux;
            }
            resAll.index = index;
            index++;
            finalresult.add(resAll);
        }
        return finalresult;
    }

    /**
    *
    *   Export PDF
    *
    **/
    public PageReference exportPDF() {
        if(codeMagasinActuel!=null && dateDebut!=null && dateFin!=null) {
            system.debug('DEBUT exportPDF');
            dateDebutExport = Date.parse(dateDebut).format();
            dateFinExport = Date.parse(dateFin).format();
            system.debug('Date de Debut : ' + dateDebutExport);
            system.debug('Date de Fin : ' + dateFinExport);

            // Formatage des résultats pour l'export
            valeursExportPDF = formatValeursExport(dateDebutExport, dateFinExport);
            dateExportFormated = DateTime.now().format('dd/MM/yyyy à HH:mm:ss', UserInfo.getTimeZone().getID());
            // Affichage PDF
            PageReference TriptyqueAnalytiquePdf = Page.VF_Triptyque_Analytique_PDF;
            TriptyqueAnalytiquePdf.setRedirect(false);
            system.debug('FIN exportPDF');
            return TriptyqueAnalytiquePdf;
        }
        else
          return null;
    }

    // Suivi Hebdomadaire
    public PageReference triptyqueSuiviHebdo() {
        PageReference triptyqueSuiviPage = Page.VF_Triptyque;
        triptyqueSuiviPage.setRedirect(false);
        return triptyqueSuiviPage;
    }

    // Objectifs Vendeurs
    public PageReference objVendeurs() {
        PageReference ObjectifsVendeurs = Page.VF_ObjectifsVendeurs;
        ObjectifsVendeurs.setRedirect(false);
        return ObjectifsVendeurs;
    }

    public Id getLogoKparKId(){
        return DAL.getDocumentByName(Constants.KparK_logo_NB).id;
    }

    // Stockage de résultat des indicateurs d'un vendeur - Hebdomadaire
    public class IndicateursVendeurHebdomadaire {
        public String vendeurId {get;set;}
        public Integer joursTravaille {get;set;}
        public Decimal nbContactActif {get;set;}                // C02
        public Decimal nbContactPassif {get;set;}               // C04
        public Decimal nbRDVTotal {get;set;}                    // C05
        public Decimal nbDevisVendu {get;set;}                  // C06 et V03
        public Decimal nbRDVR1_Pris {get;set;}                  // C07
        public Decimal nbRDVR1_Effec {get;set;}                 // C07
        public Decimal nbRDVR2_Pris {get;set;}                  // C08
        public Decimal nbRDVR2_Effec {get;set;}                 // C08
        public Decimal nbRDVBAL50 {get;set;}                    // C09
        public Decimal nbContactBAL {get;set;}                  // C10
        public Decimal nbRDVTAP51 {get;set;}                    // C11
        public Decimal nbContactTAP {get;set;}                  // C12
        public Decimal nbContactComplement {get;set;}           // C13
        public Decimal nbContactParrainage {get;set;}           // C14
        public Decimal nbRDVPhone55 {get;set;}                  // C15
        public Decimal nbContactPhone {get;set;}                // C16
        public Decimal nbRDVGalerieMarchande {get;set;}         // C17
        public Decimal nbContactGalerieMarchande {get;set;}     // C18
        public Decimal nbRDVFoire {get;set;}                    // C19
        public Decimal nbContactFoire {get;set;}                // C20
        public Decimal nbRDVMarche {get;set;}                   // C21
        public Decimal nbContactMarche {get;set;}               // C22
        public Decimal nbContactTotal {get;set;}                // C24
        public Decimal nbRDVCreatedRdvDate {get;set;}           // C25
        public Decimal nbRDVDebrief {get;set;}                  // C26
        public Integer nbCADevisVendu {get;set;}                // V04
        // Nombre de RDVs
        public Decimal nbRDVAccompagne {get;set;}               // CRM-610 JMU
        public Decimal nbRDVAccompagnant {get;set;}             // CRM-610 JMU
        // Ratios sur les nombres d'argument par origine
        public Decimal ratioParJourBAL {get;set;}               // CRM-610 JMU
        public Decimal ratioParContactBAL {get;set;}            // CRM-610 JMU
        public Decimal ratioParJourTAP {get;set;}               // CRM-610 JMU
        public Decimal ratioParContactTAP {get;set;}            // CRM-610 JMU
        public Decimal ratioParJourPhone {get;set;}             // CRM-610 JMU
        public Decimal ratioParContactPhone {get;set;}          // CRM-610 JMU
        // Taux Transformation des RDV : % de RDV par rapport au nombre total de contacts réalisés
        public Decimal tauxTransformationRDV {get;set;}
        // Taux Transformation des ventes : % de ventes par rapport au nombre total de RDV réalisés
        public Decimal tauxTransformationVentes {get;set;}
        // Taux de participation aux contacts vente : % de contacts réalisés sur l'origine observée par rapport aux nombre total de contacts de type vente/actifs réalisés
        public Decimal tauxPartContactBAL {get;set;}
        public Decimal tauxPartContactTAP {get;set;}
        public Decimal tauxPartContactCOMP {get;set;}
        public Decimal tauxPartContactPHONE {get;set;}
        public Decimal tauxPartContactGM {get;set;}
        public Decimal tauxPartContactFOIRE {get;set;}
        public Decimal tauxPartContactMARCHE {get;set;}
        // Panier moyen de la période observée (CA en K€ / nombre de vente) arrondi à 2 décimales
        public Decimal panierMoyenRealiseVente {get;set;}
        public IndicateursVendeurHebdomadaire() {
        }
    }

    // Stockage de résultat des indicateurs d'un vendeur - Totaux
    public class IndicateursVendeurTotaux {
        // Hebdo (Contact et RDV)
        public Decimal Somme_nbContactTotal {get;set;}                      // Somme C24
        public Decimal Somme_nbContactActif {get;set;}                      // Somme C02
        public Decimal Somme_nbContactPassif {get;set;}                     // Somme C04
        public Decimal Somme_nbRDVTotal {get;set;}                          // Somme C05
        public Decimal Somme_nbDevisVendu {get;set;}                        // Somme C06 et V03
        public Decimal Somme_nbRDVCreatedRdvDate {get;set;}                 // Somme C25
        public Decimal Somme_nbRDVDebrief {get;set;}                        // Somme C26
        public Decimal Somme_nbRDVR1_Pris {get;set;}                        // Somme C07
        public Decimal Somme_nbRDVR1_Effec {get;set;}                       // Somme C07
        public Decimal Somme_nbRDVR2_Pris {get;set;}                        // Somme C08
        public Decimal Somme_nbRDVR2_Effec {get;set;}                       // Somme C08
        // Hebdo (Contact par origine)
        public Decimal Somme_nbRDVBAL50 {get;set;}                          // Somme C09
        public Decimal Somme_nbContactBAL {get;set;}                        // Somme C10
        public Decimal Somme_nbRDVTAP51 {get;set;}                          // Somme C11
        public Decimal Somme_nbContactTAP {get;set;}                        // Somme C12
        public Decimal Somme_nbContactComplement {get;set;}                 // Somme C13
        public Decimal Somme_nbContactParrainage {get;set;}                 // Somme C14
        public Decimal Somme_nbRDVPhone55 {get;set;}                        // Somme C15
        public Decimal Somme_nbContactPhone {get;set;}                      // Somme C16
        public Decimal Somme_nbRDVGalerieMarchande {get;set;}               // Somme C17
        public Decimal Somme_nbContactGalerieMarchande {get;set;}           // Somme C18
        public Decimal Somme_nbRDVFoire {get;set;}                          // Somme C19
        public Decimal Somme_nbContactFoire {get;set;}                      // Somme C20
        public Decimal Somme_nbRDVMarche {get;set;}                         // Somme C21
        public Decimal Somme_nbContactMarche {get;set;}                     // Somme C22
        // Hebdo (Vente)
        public Decimal Somme_nbRDVHebdoAccompagne {get;set;}                // CRM-610 JMU
        public Decimal Somme_nbRDVHebdoAccompagnant {get;set;}              // CRM-610 JMU
        // public Decimal Somme_nbDevisVendu {get;set;}                     // Somme V03
        public Decimal Somme_nbCADevisVendu {get;set;}                      // Somme V04
        // Calculs Hebdo (Contact et RDV)
        public Decimal Somme_realisationContact  {get;set;}                 // [TR] Somme C23 C24
        // Calculs Hebdo (Vente)
        public Decimal Somme_panierMoyenRealiseVente {get;set;}             // [PM] Somme V03 V04
        public IndicateursVendeurTotaux(){
        }
    }

    // Stockage de résultat des indicateurs d'un vendeur - Export
    public class IndicateursVendeurAll {
        public String vendeurId {get;set;}
        public String vendeurName {get;set;}
        public Boolean vendeurActive {get;set;}
        public Datetime vendeurLastLoginDate {get;set;}
        public Integer vendeurNbLogin {get;set;}
        public Integer index {get;set;}
        public IndicateursVendeurHebdomadaire IVH {get;set;}
        public IndicateursVendeurTotaux IVT {get;set;}
        public IndicateursVendeurAll(){
        }
    }
}