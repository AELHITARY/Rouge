//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Triptyque
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/01/2021
//-- Version     : 1.7
//-- Version     : 1.8
//-- * 1.7 - Correctif pour les vendeurs Signea
//-- * 1.7 - Mise à jour lightning
//-- * 1.6 - CRM-757 : Ajout des nouveaux rôles pour la picklist des magasins
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Triptyque {
    public User actualUser { get; set; }
    public Profile actualUserProfile { get; set; }
    public List<SelectOption> magasinOptionList { get; set; }
    public Map<String,String> magasinsMap { get; set; }
    public string codeMagasinActuel { get; set; }
    public string libelleMagasinActuel { get; set; }
    public String moisActuel { get; set; }
    public String anneeActuelle { get; set; }
    public String semaineActuelle { get; set; }
    public Integer actualDayStartWeek { get; set; }
    public String actualMonthStartWeek { get; set; }
    public List<User> vendeursList { get; set; }
    public List<User> allVendeursList { get; set; }
    public List<User> allVendeursMagasin { get; set; }
    public Map<String, Integer> vendeursListNbConnexions { get; set; }

    public String periodId { get; set; }
    public String fiscalSettingsId { get; set; }
    public Map<String, String> periodIdMap { get; set; }
    public Map<String, String> fiscalSettingsIdMap { get; set; }

    public List<IndicateursVendeurAll> valeursExportPDF { get; set; }
    public String dateExportFormated { get; set; }
    public Boolean showLegende {get { return PropertiesUtils.getBooleanValue('triptyque.pdf.legende', true); } set;}
    public String walkMeURL {get { return PropertiesUtils.getStringValue('walkme.snippet.url', ''); } set;}

    private static final List<String> statutRDVNonEffectue = new List<String> { 'Non effectué', 'Non effectué (avec déplacement)' };
    private static final Set<String> sourcesDevis = new Set<String> { 'BAL VENDEUR', 'PORTE A PORTE VENDEUR', 'COMPLEMENT VENDEUR',
                                                                        'PARRAINAGE VENDEUR', 'STAND MARCHE VENDEUR', 'TELEPHONE VENDEUR' };
    private static final Id RT_RDVCommercial = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id RT_RDVProspection = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_PROSPECTION_RT);

    // Period SOQL
    private static List<Period> periodYears = [SELECT StartDate, EndDate, Type FROM Period WHERE Type='Year'];
    private static List<Period> periodMonthYearCurrentWeek = [SELECT StartDate, EndDate, Type, Number FROM Period WHERE (Type='Month' OR Type='Year') AND StartDate <= TODAY AND EndDate >= TODAY LIMIT 2];

    /**
    *
    *   GETTER : Récupération des mois de l'année commerciale
    *
    **/
    public List<SelectOption> mois {get{
        List<SelectOption> options = new List<SelectOption>();
        Integer i = 1;
        Integer j = 1;
        Integer Month = 0;
        Integer Year = 0;
        Date yearTmp = Date.today();

        for(Period p : periodYears){
            if (p.Type == 'Year' && Date.Today() >= p.StartDate && Date.today() <= p.EndDate)
                yearTmp = p.EndDate.addDays(-7);
        }

        if(anneeActuelle!=null && anneeActuelle!=''){
            Year = Integer.valueOf(this.anneeActuelle);
        } else {
            Year = yearTmp.Year();
        }

        if(Year == Date.Today().Year()){
            for(Period pm : periodMonthYearCurrentWeek){
                if (pm.Type == 'Month' && Date.Today() >= pm.StartDate && Date.today() <= pm.EndDate)
                    Month = pm.Number;
            }
            for (i=1;i<=Month;i++){
                options.add(new SelectOption('' + i + '', Constants.MONTHS[i-1]));
            }
        } else {
            for (i=1;i<=12;i++){
                options.add(new SelectOption('' + i + '', Constants.MONTHS[i-1]));
            }
        }

        return options;
    } set; } {
        Integer i = 1;
        mois = new List<SelectOption>();
        for (i=1;i<=12;i++){
            mois.add(new SelectOption('' + i + '', Constants.MONTHS[i-1]));
        }
    }

    /**
    *
    *   GETTER : Récupération des années commerciales
    *
    **/
    public List<SelectOption> annee { get; set; }{
        List<Period> yearPeriod = new List<Period>();
        annee = new List<SelectOption>();
        fiscalSettingsIdMap = new Map<String, String>();
        for(Period p : [SELECT EndDate, Type, FiscalYearSettingsId FROM Period WHERE Type='Year' AND FiscalYearSettingsId IN (SELECT Id FROM FiscalYearSettings WHERE Name LIKE '%Com') ORDER BY StartDate ASC]){
            if(p.EndDate.addDays(-7).Year() != p.EndDate.Year()) {
                annee.add(new SelectOption('' + p.EndDate.addDays(-7).Year() + '', '' + p.EndDate.addDays(-7).Year() + ''));
                fiscalSettingsIdMap.put(String.valueOf(p.EndDate.addDays(-7).Year()), p.FiscalYearSettingsId);
            } else {
                annee.add(new SelectOption('' + p.EndDate.Year() + '', '' + p.EndDate.Year() + ''));
                fiscalSettingsIdMap.put(String.valueOf(p.EndDate.Year()), p.FiscalYearSettingsId);
            }
        }
    }

    /**
    *
    *   GETTER : Récupération des semaines du mois et année commercial
    *
    **/
    public List<SelectOption> getsemaine() {
        List<SelectOption> options = new List<SelectOption>();
        Integer i = 0;
        Period monthRef = new Period();
        String annee = anneeActuelle +'%';
        Integer Month = 0;
        List<Period> allPeriod = [SELECT Id, StartDate, EndDate, Type, Number FROM Period
                                    WHERE FiscalYearSettingsId IN (SELECT Id FROM FiscalYearSettings WHERE Name LIKE :annee) AND StartDate <= TODAY ORDER BY Number ASC];

        System.debug('DEBUT getsemaine');

        System.debug('anneeActuelle ' + anneeActuelle);
        System.debug('moisActuel ' + moisActuel);
        if(anneeActuelle != null && anneeActuelle != ''){
            if(moisActuel != null && moisActuel != ''){
                Month = Integer.valueOf(this.moisActuel);
                for(Period p : allPeriod){
                    if (p.Type == 'Month' && p.Number == Month){
                        monthRef = p;
                        System.debug('monthRef ' + monthRef);
                    }
                }
            }
        } else {
            for(Period p : allPeriod){
                if (p.Type == 'Month' && p.EndDate >= date.today() && p.StartDate <= date.today()){
                    monthRef = p;
                    System.debug('monthRef' + monthRef);
                }
            }
        }

        for(Period p : allPeriod){
            if ((p.Type == 'Week') && (p.EndDate <= monthRef.EndDate) && (p.StartDate >= monthRef.StartDate)){
                i++;
                options.add(new SelectOption('' + i + '', 'Semaine S' + i + ' du ' + p.StartDate.Day() + '/' + p.StartDate.Month() + ' au ' + p.EndDate.Day() + '/' + p.EndDate.Month() + ''));
                periodIdMap.put(String.valueOf(i), p.Id);
                System.debug('option de la semaine ' + p.StartDate.Day() + '/' + p.StartDate.Month());
                System.debug('valeur ' + i);
            }
        }
        System.debug('FIN getsemaine');
        return options;
    }

    // Récupère le numéro de la semaine du mois
    public static Integer currentWeekOfMonth(Date todaysDate, Map<Integer, List<Date>> weeksOfMonth){
        Integer i = 0;
        Integer semaine;
        for(List<Date> dates : weeksOfMonth.values()) {
            if(todaysDate >= dates[0] && todaysDate <= dates[1]) {
                List<Integer> li = new List<Integer>();
                li.addAll(weeksOfMonth.keySet());
                semaine = li[i];
                break;
            }
            i++;
        }
        return semaine;
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
        List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, compteurTriptyque__c
                                            FROM UserStats__c
                                            WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

        if (statsList.isEmpty()) {
            stats = new UserStats__c(name                   = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
                                    user__c                 = UserInfo.getUserId(),
                                    date__c                 = System.today(),
                                    compteurTriptyque__c    = 0);
        } else
        stats = statsList[0];
        System.debug('stats.compteurTriptyque__c : ' + stats.compteurTriptyque__c);
        stats.compteurTriptyque__c = stats.compteurTriptyque__c + 1;
        System.debug('stats.compteurTriptyque__c : ' + stats.compteurTriptyque__c);
        userStats.add(stats);
        if (!userStats.isEmpty())
            upsert userStats;
    }

    /**
    *
    *   Constructeur
    *
    **/
    public Ctrl_Triptyque() {
        magasinsMap = new Map<String,String>();
        Integer i=1;
        Integer yearTmp = 0;
        Integer monthTmp = 0;
        periodIdMap = new Map<String, String>();

        // Récupération des informations de l'utilisateur pour magasin
        actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, LastLoginDate, UserRoleId, UserRole.Name, ProfileId, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
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
        System.debug('magasinOptionList ' + magasinOptionList.get(0).getValue());

        // Initialisation sur la date du jour
        Period periodActuelle = new Period();
        for(Period period : periodMonthYearCurrentWeek){
            if (period.Type == 'Year'){
                yearTmp = period.EndDate.addDays(-7).Year();

            }
            if (period.Type == 'Month'){
                // Fix si il y a deux mois dans la période
                if(period.StartDate.monthsBetween(period.EndDate) == 2) {
                    monthTmp = period.EndDate.addMonths(-1).Month();
                    periodActuelle = period;
                } else {
                    monthTmp = period.EndDate.Month();
                    periodActuelle = period;
                }
            }
        }
        anneeActuelle = String.valueOf(yearTmp);
        moisActuel = String.valueOf(monthTmp);
        System.debug('ANNEE ACTUELLE : ' + anneeActuelle);
        System.debug('MOIS ACTUELLE : ' + moisActuel);
        for(Period per : [SELECT StartDate, EndDate, Type FROM Period WHERE Type ='Week' AND StartDate >= :periodActuelle.StartDate AND EndDate<= :periodActuelle.EndDate]){
            if(per.EndDate < Date.today()){
                i++;
            }
        }
        semaineActuelle = '' + i + '';
        System.debug('SEMAINE ACTUELLE : ' + i);

        // Init des MAPS pour les périodes
        getsemaine();
        periodId = periodIdMap.get(semaineActuelle);
        fiscalSettingsId = fiscalSettingsIdMap.get(anneeActuelle);

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
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueof(moisActuel);
        Integer semaine = (semaineActuelle == null) ? 1 : Integer.valueof(semaineActuelle);
        Integer i = 0;
        periodId = periodIdMap.get(semaineActuelle);
        fiscalSettingsId = fiscalSettingsIdMap.get(anneeActuelle);

        libelleMagasinActuel = magasinsMap.get(codeMagasinActuel);
        System.debug('codeMagasinActuel : ' + codeMagasinActuel);
        System.debug('libelleMagasinActuel : ' + libelleMagasinActuel);

        System.debug('anneeActuelle : ' + anneeActuelle);
        System.debug('moisActuel : ' + moisActuel);
        System.debug('semaineActuelle : ' + semaineActuelle);
        System.debug('periodid : ' + periodId);

        // Period
        Period period = [SELECT StartDate, EndDate FROM Period WHERE Id = :periodId LIMIT 1];
        Period monthPeriod = [SELECT StartDate, EndDate FROM Period WHERE Type = 'Month' AND StartDate <= :period.StartDate AND Type = 'Month' AND EndDate >= :period.EndDate LIMIT 1];
        actualDayStartWeek = period.StartDate.day();
        actualMonthStartWeek = Constants.MONTHS[period.StartDate.month()-1];
        System.debug('period.StartDate : ' + period.StartDate);
        System.debug('period.EndDate : ' + period.EndDate);

        // Récupération vendeurs du magasin
        allVendeursMagasin = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, isActive, LastLoginDate,
                                    (SELECT nbVentesS5__c, nbVentesS4__c, nbVentesS3__c, nbVentesS2__c, nbVentesS1__c, nbContactsActifsS5__c, nbContactsActifsS4__c,
                                            nbContactsActifsS3__c, nbContactsActifsS2__c, nbContactsActifsS1__c, moisObjectif__c, chiffreAffaireVenduS5__c,
                                            chiffreAffaireVenduS4__c, chiffreAffaireVenduS3__c, chiffreAffaireVenduS2__c, chiffreAffaireVenduS1__c, anneeObjectif__c
                                     FROM ObjectifsVendeur__r
                                     WHERE anneeObjectif__c = :annee
                                       AND moisObjectif__c = :Constants.MONTHS[mois-1])
                              FROM User
                              WHERE codeMagasin__c = :codeMagasinActuel
                              ORDER BY LastName ASC];

        // Récupération des vendeurs selon le profil de l'utilisateur actuel pour la liste
        // Si Vendeur, on ajoute seulement le vendeur
        if(actualUserProfile.Name.containsIgnoreCase('Vendeur')) {
            if(vendeursList.isEmpty()) vendeursList.add(actualUser);
        /*}
        else if (actualUserProfile.Name.containsIgnoreCase('RVJ')) {
            // Si RVJ, on ajoute les vendeurs du magasins sauf RV
            allVendeursList = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, isActive, LastLoginDate,
                                      (SELECT Id FROM ObjectifsVendeur__r WHERE anneeObjectif__c = :annee AND moisObjectif__c = :Constants.MONTHS[mois-1])
                               FROM User
                               WHERE codeMagasin__c = :codeMagasinActuel
                                 AND Profile.Name = :Constants.PROFIL_Vendeur
                               ORDER BY LastName ASC];
            allVendeursList.add(actualUser);*/
        } else {
            // Si RV et supérieur, on ajoute tous les vendeurs du magasin
            allVendeursList = allVendeursMagasin;
        }
        System.debug('actualUserProfile.Name : ' + actualUserProfile.Name);
        System.debug('allVendeursList : ' + allVendeursList);

        // Affiche seulement les vendeurs connecté dans la semaine ou ayant des objectifs dans la semaine si ce n'est pas un vendeur
        if(!actualUserProfile.Name.containsIgnoreCase('Vendeur')) {
            vendeursList.clear();
            for(User vendeur : allVendeursList) {
                if(vendeur.LastLoginDate != null && vendeur.LastLoginDate.date() >= period.StartDate)
                    vendeursList.add(vendeur);
                else if (vendeur.ObjectifsVendeur__r != null && vendeur.ObjectifsVendeur__r.size() != 0){
                    vendeursList.add(vendeur);
                }
            }
        }
        System.debug('vendeursList : ' + vendeursList);

        // Récupération du nombre de connexion dans la semaine des vendeurs
        vendeursListNbConnexions.clear();
        for (AggregateResult nbConnexions : [SELECT UserId vendeur, COUNT(Id) total From LoginHistory
                                                WHERE UserId IN :vendeursList AND DAY_ONLY(LoginTime) >= :monthPeriod.StartDate AND DAY_ONLY(LoginTime) <= :monthPeriod.EndDate GROUP BY UserId]) {
            vendeursListNbConnexions.put((String)nbConnexions.get('vendeur'), (Integer)nbConnexions.get('total'));
        }
        for(User vendeur : vendeursList) {
            if(vendeursListNbConnexions.get(vendeur.Id) == null) {
                vendeursListNbConnexions.put(vendeur.Id, 0);
            }
        }
        System.debug('vendeursListNbConnexions : ' + vendeursListNbConnexions);
    }

    /**
    *
    *   Récupération des infos pour les indicateurs des RDV
    *
    **/
    @RemoteAction
    public static IndicateursPie getNumberRDVInfo(List<String> actualUser, String magasin){
        System.debug('### DEBUT getNumberRDVInfo');
        try{
            // Init
            IndicateursPie resultat = new IndicateursPie();
            resultat.vendeurAjd = 0;
            resultat.vendeurDemain = 0;
            resultat.vendeurADemain = 0;
            resultat.magasinAjd = 0;
            resultat.magasinDemain = 0;
            resultat.magasinADemain = 0;
            // Récupération des vendeurs du magasin
            List<User> allVendeursList = [SELECT Id FROM User WHERE CodeMagasin__c = :magasin];
            // Formatage des dates
            Date dateToday = Datetime.now().date();
            Date dateTomorrow = Datetime.now().addDays(1).date();
            Date date2DaysAfter = Datetime.now().addDays(2).date();
            // Récuperation des Events
            List<Event> eventsResult = [SELECT Id, OwnerId, Type, StatutRDV__c, IsAllDayEvent, StartDateTime, WhatId, Subject
                                        FROM Event
                                        WHERE recordTypeId = :RT_RDVCommercial
                                          AND (Type = 'R1' OR Type = 'R2' OR Type = 'R+')
                                          AND activityDate >= :dateToday AND activityDate <= :date2DaysAfter
                                          AND IsDeleted = false
                                          AND (OwnerId IN :allVendeursList OR OwnerId IN :actualUser)];
            for(Event evnt : eventsResult) {
                Date formatedStartDateTime = evnt.StartDateTime.date();
                // Indicateurs magasin
                if(formatedStartDateTime == dateToday) resultat.magasinAjd++;
                if(formatedStartDateTime == dateTomorrow) resultat.magasinDemain++;
                if(formatedStartDateTime == date2DaysAfter) resultat.magasinADemain++;
                // Indicateurs vendeur
                if(actualUser[0] == evnt.OwnerId){
                    if(formatedStartDateTime == dateToday) resultat.vendeurAjd++;
                    if(formatedStartDateTime == dateTomorrow) resultat.vendeurDemain++;
                    if(formatedStartDateTime == date2DaysAfter) resultat.vendeurADemain++;
                }
            }
            System.debug('resultat : ' + resultat);
            System.debug('### FIN getNumberRDVInfo');
            return resultat;
        }
        catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   Récupération des objectifs pour l'utilisateur courant pour affichage des indicateurs
    *
    **/
    @RemoteAction
    public static IndicateursObjectifUser getObjectifsVendeurs(String anneeActuelle, String moisActuel, String semaineActuelle, String periodId, List<String> userId) {
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueof(moisActuel);
        Integer semaine = (semaineActuelle == null) ? 1 : Integer.valueof(semaineActuelle);
        Map<String, List<Event>> vendeurEvents = new Map<String, List<Event>>();
        System.debug('### DEBUT getObjectifsVendeursUser');
        System.debug('annee : ' + annee);
        System.debug('mois : ' + mois);
        System.debug('semaine : ' + semaine);
        System.debug('periodId : ' + periodId);

        try {
            // Period
            Period period = [SELECT StartDate, EndDate FROM Period WHERE Id = :periodId LIMIT 1];
            System.debug('period.StartDate : ' + period.StartDate);
            System.debug('period.EndDate : ' + period.EndDate);

            // Récupération des devis vendu pour la semaine de l'utilisateur
            Decimal nbDevisVendu = 0;
            Decimal caDevisVendu = 0;
            List<AggregateResult> quotesResult = [SELECT Opportunity.OwnerId vendeur, COUNT(Id) total, SUM(TotalHTDevis__c) ca FROM Quote
                                                    WHERE dateAcceptationClient__c >= :period.StartDate AND dateAcceptationClient__c <= :period.EndDate
                                                    AND Opportunity.OwnerId IN :userId AND Status LIKE 'Vendu%' GROUP BY Opportunity.OwnerId];
            if(!quotesResult.isEmpty()) {
                for(AggregateResult result : quotesResult) {
                    nbDevisVendu = nbDevisVendu + (Integer)result.get('total');
                    if((Decimal)result.get('ca') != null)
                        caDevisVendu = caDevisVendu + (Decimal)result.get('ca');
                }
            }

            // Objectifs utilisateur
            Map<String, ObjectifsVendeur__c> objectifsVendeurs = getObjectifsVendeursMensuel(anneeActuelle, moisActuel, userId);

            // Construction liste pour contact actif
            DateTime dtBegin = DateTime.newInstance(period.startDate.year(), period.startDate.month(), period.startDate.day(), 0, 0, 0);
            DateTime dtEnd = DateTime.newInstance(period.endDate.year(), period.endDate.month(), period.endDate.day(), 23, 59, 59);
            List<Event> eventsResult = [SELECT Id, OwnerId, Type, nbBAL50__c, NbTAP51__c, NbPhone55__c, StatutRDV__c, IsAllDayEvent,
                                               CreatedDate, ActivityDate, StartDateTime, EndDateTime, WhatId, Subject
                                        FROM Event
                                        WHERE (recordTypeId = :RT_RDVCommercial OR recordTypeId = :RT_RDVProspection)
                                          AND (
                                               (createdDate >= :dtBegin AND createdDate <= :dtEnd)
                                               OR
                                               (activityDate >= :period.StartDate AND activityDate <= :period.EndDate)
                                              )
                                          AND isDeleted = false
                                          AND ownerId IN :userId];
            Set<String> OppId = new Set<String>();
            for(Event event : eventsResult){
                OppId.add(event.WhatId);

                // Construction liste des EVENT
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
                                                                              WHERE OwnerId IN :userId
                                                                                AND Id IN :OppId]);

            // Construction résultat
            /*****************************/
            IndicateursObjectifUser resultat = new IndicateursObjectifUser();
            resultat.objectifContactActif = 0;
            resultat.objectifnbDevisVendu = 0;
            resultat.objectifCADevisVendu = 0;
            resultat.nbContactActif = 0;
            resultat.nbDevisVendu = 0;
            resultat.nbCADevisVendu = 0;
            Decimal nbContactActif = 0;

            for(String vendeur : userId) {
                ObjectifsVendeur__c objectif = objectifsVendeurs.get(vendeur);
                if(objectif == null) {
                    resultat.objectifContactActif += 0;
                    resultat.objectifnbDevisVendu += 0;
                    resultat.objectifCADevisVendu += 0;
                } else {
                    if(semaine == 1) {
                        resultat.objectifContactActif += objectif.nbContactsActifsS1__c;
                        resultat.objectifnbDevisVendu += objectif.nbVentesS1__c;
                        resultat.objectifCADevisVendu += objectif.chiffreAffaireVenduS1__c;
                    } else if(semaine == 2) {
                        resultat.objectifContactActif += objectif.nbContactsActifsS2__c;
                        resultat.objectifnbDevisVendu += objectif.nbVentesS2__c;
                        resultat.objectifCADevisVendu += objectif.chiffreAffaireVenduS2__c;
                    } else if(semaine == 3) {
                        resultat.objectifContactActif += objectif.nbContactsActifsS3__c;
                        resultat.objectifnbDevisVendu += objectif.nbVentesS3__c;
                        resultat.objectifCADevisVendu += objectif.chiffreAffaireVenduS3__c;
                    } else if(semaine == 4) {
                        resultat.objectifContactActif += objectif.nbContactsActifsS4__c;
                        resultat.objectifnbDevisVendu += objectif.nbVentesS4__c;
                        resultat.objectifCADevisVendu += objectif.chiffreAffaireVenduS4__c;
                    } else if(semaine == 5) {
                        resultat.objectifContactActif += objectif.nbContactsActifsS5__c;
                        resultat.objectifnbDevisVendu += objectif.nbVentesS5__c;
                        resultat.objectifCADevisVendu += objectif.chiffreAffaireVenduS5__c;
                    }
                }

                // Calcul des totaux des comptes
                if (vendeurEvents.get(vendeur) != null) {
                    for (Event event : vendeurEvents.get(vendeur)) {
                        // Contacts Actifs
                        Opportunity opp = vendeurOppEvents.get(event.whatId);
                        if(opp != null) {
                            if (event.Type == 'R1') {
                              if (event.CreatedDate.date() >= period.StartDate && event.CreatedDate.date() <= period.EndDate && opp.actifParOrigine__c)
                                nbContactActif = nbContactActif + 1;
                              if (event.StartDateTime.date() >= period.StartDate && event.StartDateTime.date() <= period.EndDate && opp.actifParOrigine__c && (event.StatutRDV__c == statutRDVNonEffectue[1] || event.StatutRDV__c == statutRDVNonEffectue[0]))
                                nbContactActif = nbContactActif - 1;
                            }
                        }
                    }
                }
            }

            resultat.nbDevisVendu = nbDevisVendu;
            resultat.nbCADevisVendu = caDevisVendu;
            resultat.nbContactActif = nbContactActif;
            resultat.nbCADevisVendu = (resultat.nbCADevisVendu / 1000).setScale(2, RoundingMode.HALF_EVEN);
            resultat.realisationContactActif = (resultat.objectifContactActif == 0) ? 0 : ((nbContactActif / resultat.objectifContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationNbDevis = (resultat.objectifnbDevisVendu == 0) ? 0 : ((nbDevisVendu / resultat.objectifnbDevisVendu) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationCADevis = (resultat.objectifCADevisVendu == 0) ? 0 : ((resultat.nbCADevisVendu / resultat.objectifCADevisVendu) * 100).setScale(0, RoundingMode.HALF_EVEN);

            System.debug('### FIN getObjectifsVendeursUser');
            return resultat;
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   Récupération des objectifs du mois pour les vendeurs
    *
    **/
    public static Map<String, ObjectifsVendeur__c> getObjectifsVendeursMensuel(String anneeActuelle, String moisActuel, List<String> vendeursIdList) {
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueOf(moisActuel);
        List<ObjectifsVendeur__c> objectifsVendeurList = new List<ObjectifsVendeur__c>();
        Map<String, ObjectifsVendeur__c> objectifsVendeurMensuel = new Map<String, ObjectifsVendeur__c>();

        // Récupération des objectifs
        if(vendeursIdList != null && !vendeursIdList.isEmpty()) {
            objectifsVendeurList = [SELECT Id, anneeObjectif__c, vendeur__c, moisObjectif__c, chiffreAffaireVenduS1__c, chiffreAffaireVenduS2__c, chiffreAffaireVenduS3__c,
                                           chiffreAffaireVenduS4__c, chiffreAffaireVenduS5__c, nbContactsActifsS1__c, nbContactsActifsS2__c, nbContactsActifsS3__c,
                                           nbContactsActifsS4__c, nbContactsActifsS5__c, nbVentesS1__c, nbVentesS2__c, nbVentesS3__c, nbVentesS4__c, nbVentesS5__c
                                    FROM ObjectifsVendeur__c
                                    WHERE vendeur__c IN :vendeursIdList
                                      AND anneeObjectif__c = :annee
                                      AND moisObjectif__c = :Constants.MONTHS[mois-1]];

            // Construction de la map des objectifs
            for(ObjectifsVendeur__c objectif : objectifsVendeurList) {
                objectifsVendeurMensuel.put(objectif.vendeur__c, objectif);
            }
        }

        System.debug('objectifsVendeurMensuel : ' + objectifsVendeurMensuel);
        return objectifsVendeurMensuel;
    }
    
    /**
    *
    *   Récupération des informations mensuelles pour les vendeurs du magasin
    *
    **/
    @RemoteAction
    public static List<IndicateursVendeurMensuel> getMensuelData(String moisActuel, String anneeActuelle, String fiscalSettingId, String periodId, List<String> vendeursIdList) {
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueof(moisActuel);
        Map<String, Map<Integer, Decimal>> vendeurMensuelCAQuotes = new Map<String, Map<Integer, Decimal>>();
        Map<String, Map<Integer, Decimal>> vendeurMensuelNbQuotes = new Map<String, Map<Integer, Decimal>>();
        Map<String, List<Event>> vendeurEvents = new Map<String, List<Event>>();
        List<IndicateursVendeurMensuel> indicateursVendeurList = new List<IndicateursVendeurMensuel>();
        Map<Integer, List<Date>> weeksOfMonth = new Map<Integer, List<Date>>();

        System.debug('### DEBUT getMensuelData');

        try {
            if(vendeursIdList != null && !vendeursIdList.isEmpty()) {
                // Period semaine actuelle
                Period weekPeriod = [SELECT StartDate, EndDate FROM Period WHERE Id = :periodId LIMIT 1];
                System.debug('weekPeriod.StartDate : ' + weekPeriod.StartDate);
                System.debug('weekPeriod.EndDate : ' + weekPeriod.EndDate);
                // Period
                Period period = [SELECT StartDate, EndDate FROM Period WHERE Number = :mois AND Type = 'Month' AND FiscalYearSettingsId = :fiscalSettingId LIMIT 1];
                System.debug('period.StartDate : ' + period.StartDate);
                System.debug('period.EndDate : ' + period.EndDate);

                Integer index = 1;
                for(Period week : [SELECT StartDate, EndDate, Number
                                   FROM Period
                                   WHERE Type = 'Week'
                                     AND StartDate >= :period.StartDate
                                     AND EndDate <= :period.EndDate
                                  ORDER BY Number ASC]) {
                    weeksOfMonth.put(index, new List<Date>{week.StartDate, week.EndDate});
                    index++;
                }

                // Récupération des devis vendu pour le mois des vendeurs, découpé en semaine
                for (Quote quoteResult : [SELECT Opportunity.OwnerId, dateAcceptationClient__c, TotalHTTarif__c, TotalHTDevis__c, source__c
                                          FROM Quote
                                          WHERE dateAcceptationClient__c >= :period.StartDate
                                            AND dateAcceptationClient__c <= :period.EndDate
                                            AND Opportunity.OwnerId IN :vendeursIdList
                                            AND Status LIKE 'Vendu%']) {
                    String vendeur = quoteResult.Opportunity.OwnerId;
                    Map<Integer, Decimal> valeursCA = new Map<Integer, Decimal>();
                    Map<Integer, Decimal> valeursNb = new Map<Integer, Decimal>();

                    // Calcul du numéro de la semaine
                    Integer semaine = Ctrl_Triptyque.currentWeekOfMonth(quoteResult.dateAcceptationClient__c, weeksOfMonth);
                    System.debug('semaine : ' + semaine);

                    // Si des valeurs CA existe pour le vendeur, on récupérer la MAP
                    if(vendeurMensuelCAQuotes.get(vendeur) != null)
                        valeursCA = vendeurMensuelCAQuotes.get(vendeur);
                    Decimal ca = (valeursCA.get(semaine) == null ? 0 : valeursCA.get(semaine)) + (quoteResult.TotalHTDevis__c == null ? 0 : quoteResult.TotalHTDevis__c);
                    valeursCA.put(semaine, ca);
                    System.debug('valeursCA : ' + valeursCA);
                    vendeurMensuelCAQuotes.put(vendeur, valeursCA);

                    // Si des valeurs totaux existe pour le vendeur, on récupérer la MAP
                    if(vendeurMensuelNbQuotes.get(vendeur) != null)
                        valeursNb = vendeurMensuelNbQuotes.get(vendeur);
                    Decimal nb = (valeursNb.get(semaine) == null) ? 1 : (valeursNb.get(semaine) + 1);
                    valeursNb.put(semaine, nb);
                    System.debug('valeursNb : ' + valeursNb);
                    vendeurMensuelNbQuotes.put(vendeur, valeursNb);
                }
                System.debug('vendeurMensuelCAQuotes : ' + vendeurMensuelCAQuotes);

                // Récupération des activités (événements) pour le mois des vendeurs
                DateTime dtBegin = DateTime.newInstance(period.startDate.year(), period.startDate.month(), period.startDate.day(), 0, 0, 0);
                DateTime dtEnd = DateTime.newInstance(period.endDate.year(), period.endDate.month(), period.endDate.day(), 23, 59, 59);
                List<Event> eventsResult = [SELECT Id, OwnerId, Type, nbBAL50__c, NbTAP51__c, NbPhone55__c, StatutRDV__c, IsAllDayEvent,
                                                   CreatedDate, ActivityDate, StartDateTime, EndDateTime, RecordTypeId, WhatId, IsChild, Subject
                                            FROM Event
                                            WHERE (RecordTypeId = :RT_RDVCommercial OR RecordTypeId = :RT_RDVProspection)
                                              AND (
                                                   (CreatedDate >= :dtBegin AND CreatedDate <= :dtEnd)
                                                   OR
                                                   (ActivityDate >= :period.StartDate AND ActivityDate <= :period.EndDate)
                                                  )
                                              AND IsDeleted = false
                                              AND OwnerId IN :vendeursIdList];
                Set<String> OppId = new Set<String>();
                for(Event event : eventsResult){
                    if (event.Type == 'R1')
                        OppId.add(event.whatId);

                    // Construction liste des EVENT
                    List<Event> eventList;
                    if(vendeurEvents.get(event.OwnerId) != null)
                      eventList = vendeurEvents.get(event.OwnerId);
                    else {
                      eventList = new List<Event>();
                    }
                    eventList.add(event);
                    vendeurEvents.put(event.OwnerId, eventList);
                }

                Map<Id, Opportunity> vendeurOppEvents = new Map<Id, Opportunity>([SELECT Id, OwnerId, actifParOrigine__c, accountSource__c, leadSource
                                                                                  FROM Opportunity
                                                                                  WHERE OwnerId IN :vendeursIdList
                                                                                    AND Id IN :OppId]);

                // Objectifs mensuels
                Map<String, ObjectifsVendeur__c> objectifsVendeurs = getObjectifsVendeursMensuel(anneeActuelle, moisActuel, vendeursIdList);

                // Construction de la liste de résultat
                for(String vendeur : vendeursIdList) {
                    // Calcul des totaux des Comptes
                    Decimal nbContactActif = 0;
                    Decimal nbContactPassif = 0;
                    Integer nbContactActifS1 = 0;
                    Integer nbContactPassifS1 = 0;
                    Integer nbContactActifS2 = 0;
                    Integer nbContactPassifS2 = 0;
                    Integer nbContactActifS3 = 0;
                    Integer nbContactPassifS3 = 0;
                    Integer nbContactActifS4 = 0;
                    Integer nbContactPassifS4 = 0;
                    Integer nbContactActifS5 = 0;
                    Integer nbContactPassifS5 = 0;

                    // Calcul des totaux des RDV
                    /*****************************/
                    Decimal nbRDVBAL50 = 0;
                    Decimal nbRDVTAP51 = 0;
                    Decimal nbRDVPhone55 = 0;
                    Decimal nbRDVGalerieMarchande = 0;
                    Decimal nbRDVFoire = 0;
                    Decimal nbRDVMarche = 0;
                    Decimal nbRDVAccompagne = 0;
                    Decimal nbRDVAccompagnant = 0;

                    // Calcul des totaux des Contacts
                    /*****************************/
                    Decimal nbContactBAL = 0;
                    Decimal nbContactTAP = 0;
                    Decimal nbContactPhone = 0;
                    Decimal nbContactComplement = 0;
                    Decimal nbContactParrainage = 0;
                    Decimal nbContactGalerieMarchande = 0;
                    Decimal nbContactFoire = 0;
                    Decimal nbContactMarche = 0;

                    // Variables utilisées pour compter le nombre de jours travaillés
                    Set<Integer> eventActiveDaysMonth = new Set<Integer>();
                    Set<Integer> eventActiveDays = new Set<Integer>();

                    if(vendeurEvents.get(vendeur) != null) {
                        for(Event event : vendeurEvents.get(vendeur)) {
                            // Nombre de RDV en tant qu'accompagnant et en tant qu'accompagné
                            if(event.StartDateTime >= period.StartDate && event.StartDateTime <= period.EndDate.addDays(1)){
                                if(!event.IsChild && event.RecordTypeId == RT_RDVCommercial)
                                  nbRDVAccompagne = nbRDVAccompagne + 1;
                                if(event.IsChild && event.RecordTypeId == RT_RDVCommercial)
                                  nbRDVAccompagnant = nbRDVAccompagnant + 1;
                            }

                            if((event.ActivityDate >= period.StartDate) && (event.ActivityDate <= period.EndDate)){
                              if(!Constants.EVENT_ACTIVITE_CONGE_TYPES.contains(event.Type)) {
                                // Vérification des jours travaillés du mois
                                eventActiveDaysMonth.add(event.ActivityDate.day());
                                // Vérification des jours travaillés
                                eventActiveDays.add(event.ActivityDate.day());
                              }

                              // Calcul des indicateur des événements
                              if(event.Type == 'Prospection physique' || event.Type == 'Visite de pose') {
                                if(event.nbBAL50__c != null)
                                  nbRDVBAL50 = nbRDVBAL50 + event.nbBAL50__c;
                                if(event.NbTAP51__c != null)
                                  nbRDVTAP51 = nbRDVTAP51 + event.NbTAP51__c;
                              }
                              else if(event.Type == 'Phone') {
                                if(event.NbPhone55__c != null)
                                  nbRDVPhone55 = nbRDVPhone55 + event.NbPhone55__c;
                              }
                              else if(event.Type == 'Stand/Galerie Marchande')
                                nbRDVGalerieMarchande = nbRDVGalerieMarchande + (event.IsAllDayEvent ? 2 : 1);
                              else if(event.Type == 'Foire')
                                nbRDVFoire = nbRDVFoire + (event.IsAllDayEvent ? 2 : 1);
                              else if(event.Type == 'Stand/Marché')
                                nbRDVMarche = nbRDVMarche + (event.IsAllDayEvent ? 2 : 1);
                            }

                            // Calcul Actif et Passif (Compte passif si origine call est renseignée, sinon actif)
                            Opportunity opp = vendeurOppEvents.get(event.whatId);
                            if(opp != null) {
                              if (event.Type == 'R1') {
                                if((event.CreatedDate.date() >= period.StartDate && event.CreatedDate.date() <= period.EndDate)) {
                                    Integer eventCreatedSemaine = Ctrl_Triptyque.currentWeekOfMonth(event.CreatedDate.date(), weeksOfMonth);
                                    if (eventCreatedSemaine == 1) {
                                        if (opp.actifParOrigine__c) nbContactActifS1 = nbContactActifS1 + 1;
                                        else nbContactPassifS1 = nbContactPassifS1 + 1;
                                    }
                                    else if (eventCreatedSemaine == 2) {
                                        if (opp.actifParOrigine__c) nbContactActifS2 = nbContactActifS2 + 1;
                                        else nbContactPassifS2 = nbContactPassifS2 + 1;
                                    }
                                    else if (eventCreatedSemaine == 3) {
                                        if (opp.actifParOrigine__c) nbContactActifS3 = nbContactActifS3 + 1;
                                        else nbContactPassifS3 = nbContactPassifS3 + 1;
                                    }
                                    else if (eventCreatedSemaine == 4) {
                                        if (opp.actifParOrigine__c) nbContactActifS4 = nbContactActifS4 + 1;
                                        else nbContactPassifS4 = nbContactPassifS4 + 1;
                                    }
                                    else if (eventCreatedSemaine == 5) {
                                        if (opp.actifParOrigine__c) nbContactActifS5 = nbContactActifS5 + 1;
                                        else nbContactPassifS5 = nbContactPassifS5 + 1;
                                    }
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

                                if((event.StartDateTime.date() >= period.StartDate && event.StartDateTime.date() <= period.EndDate)
                                    && (event.StatutRDV__c == statutRDVNonEffectue[1] || event.StatutRDV__c == statutRDVNonEffectue[0]))
                                {
                                    Integer eventRDVSemaine = Ctrl_Triptyque.currentWeekOfMonth(event.StartDateTime.date(), weeksOfMonth);
                                    if (eventRDVSemaine == 1) {
                                        if(opp.actifParOrigine__c) nbContactActifS1 = nbContactActifS1 - 1;
                                        else nbContactPassifS1 = nbContactPassifS1 - 1;
                                    }
                                    else if (eventRDVSemaine == 2) {
                                        if(opp.actifParOrigine__c) nbContactActifS2 = nbContactActifS2 - 1;
                                        else nbContactPassifS2 = nbContactPassifS2 - 1;
                                    }
                                    else if (eventRDVSemaine == 3) {
                                        if(opp.actifParOrigine__c) nbContactActifS3 = nbContactActifS3 - 1;
                                        else nbContactPassifS3 = nbContactPassifS3 - 1;
                                    }
                                    else if (eventRDVSemaine == 4) {
                                        if(opp.actifParOrigine__c) nbContactActifS4 = nbContactActifS4 - 1;
                                        else nbContactPassifS4 = nbContactPassifS4 - 1;
                                    }
                                    else if (eventRDVSemaine == 5) {
                                        if(opp.actifParOrigine__c) nbContactActifS5 = nbContactActifS5 - 1;
                                        else nbContactPassifS5 = nbContactPassifS5 - 1;
                                    }
                                    // Calcul du nombre des comptes avec source (décremnte si pas créé lors de la période et non effectué)
/* >>> F.G., le 30/09/2015
                                    if(opp.accountSource__c == 'BAL VENDEUR') nbContactBAL = nbContactBAL - 1;
                                    if(opp.accountSource__c == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP - 1;
                                    if(opp.accountSource__c == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone - 1;
                                    if(opp.accountSource__c == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement - 1;
                                    if(opp.accountSource__c == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage - 1;
                                    if(opp.accountSource__c == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande - 1;
                                    if(opp.accountSource__c == 'FOIRE') nbContactFoire = nbContactFoire - 1;
                                    if(opp.accountSource__c == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche - 1;
   --- F.G., le 30/09/2015 */
                                    if(opp.leadSource == 'BAL VENDEUR') nbContactBAL = nbContactBAL - 1;
                                    if(opp.leadSource == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP - 1;
                                    if(opp.leadSource == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone - 1;
                                    if(opp.leadSource == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement - 1;
                                    if(opp.leadSource == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage - 1;
                                    if(opp.leadSource == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande - 1;
                                    if(opp.leadSource == 'FOIRE') nbContactFoire = nbContactFoire - 1;
                                    if(opp.leadSource == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche - 1;
/* <<< F.G., le 30/09/2015 */
                                }
                              }
                            }
                        }
                    }

                    nbContactActif = nbContactActifS1 + nbContactActifS2 + nbContactActifS3 + nbContactActifS4 + nbContactActifS5;
                    nbContactPassif = nbContactPassifS1 + nbContactPassifS2 + nbContactPassifS3 + nbContactPassifS4 + nbContactPassifS5;
                    // Calcul Devis
                    Integer caDevisS1 = 0;
                    Integer caDevisS2 = 0;
                    Integer caDevisS3 = 0;
                    Integer caDevisS4 = 0;
                    Integer caDevisS5 = 0;
                    if (vendeurMensuelCAQuotes.get(vendeur) != null) {
                        caDevisS1 = Math.round((vendeurMensuelCAQuotes.get(vendeur).get(1) == null) ? 0 : (vendeurMensuelCAQuotes.get(vendeur).get(1) / 1000).setScale(2, RoundingMode.HALF_EVEN));
                        caDevisS2 = Math.round((vendeurMensuelCAQuotes.get(vendeur).get(2) == null) ? 0 : (vendeurMensuelCAQuotes.get(vendeur).get(2) / 1000).setScale(2, RoundingMode.HALF_EVEN));
                        caDevisS3 = Math.round((vendeurMensuelCAQuotes.get(vendeur).get(3) == null) ? 0 : (vendeurMensuelCAQuotes.get(vendeur).get(3) / 1000).setScale(2, RoundingMode.HALF_EVEN));
                        caDevisS4 = Math.round((vendeurMensuelCAQuotes.get(vendeur).get(4) == null) ? 0 : (vendeurMensuelCAQuotes.get(vendeur).get(4) / 1000).setScale(2, RoundingMode.HALF_EVEN));
                        caDevisS5 = Math.round((vendeurMensuelCAQuotes.get(vendeur).get(5) == null) ? 0 : (vendeurMensuelCAQuotes.get(vendeur).get(5) / 1000).setScale(2, RoundingMode.HALF_EVEN));
                    }
                    Integer objectifcaDevisS1 = 0;
                    Integer objectifcaDevisS2 = 0;
                    Integer objectifcaDevisS3 = 0;
                    Integer objectifcaDevisS4 = 0;
                    Integer objectifcaDevisS5 = 0;
                    ObjectifsVendeur__c objectif = objectifsVendeurs.get(vendeur);
                    if(objectif != null) {
                        objectifcaDevisS1 = Math.round(objectif.chiffreAffaireVenduS1__c);
                        objectifcaDevisS2 = Math.round(objectif.chiffreAffaireVenduS2__c);
                        objectifcaDevisS3 = Math.round(objectif.chiffreAffaireVenduS3__c);
                        objectifcaDevisS4 = Math.round(objectif.chiffreAffaireVenduS4__c);
                        objectifcaDevisS5 = Math.round(objectif.chiffreAffaireVenduS5__c);
                    }

                    Decimal nbDevisVendu = 0;
                    if (vendeurMensuelNbQuotes.get(vendeur) != null) {
                        nbDevisVendu = (vendeurMensuelNbQuotes.get(vendeur).get(1) == null ? nbDevisVendu + 0 : nbDevisVendu + vendeurMensuelNbQuotes.get(vendeur).get(1));
                        nbDevisVendu = (vendeurMensuelNbQuotes.get(vendeur).get(2) == null) ? nbDevisVendu + 0 : nbDevisVendu + vendeurMensuelNbQuotes.get(vendeur).get(2);
                        nbDevisVendu = (vendeurMensuelNbQuotes.get(vendeur).get(3) == null) ? nbDevisVendu + 0 : nbDevisVendu + vendeurMensuelNbQuotes.get(vendeur).get(3);
                        nbDevisVendu = (vendeurMensuelNbQuotes.get(vendeur).get(4) == null) ? nbDevisVendu + 0 : nbDevisVendu + vendeurMensuelNbQuotes.get(vendeur).get(4);
                        nbDevisVendu = (vendeurMensuelNbQuotes.get(vendeur).get(5) == null) ? nbDevisVendu + 0 : nbDevisVendu + vendeurMensuelNbQuotes.get(vendeur).get(5);
                    }

                    // Construction résultat
                    IndicateursVendeurMensuel resultat = new IndicateursVendeurMensuel();
                    resultat.vendeurId = vendeur;
                    resultat.joursTravaille = eventActiveDays.size();
                    resultat.joursTravailleMonth = eventActiveDaysMonth.size();
                    resultat.nbRDVAccompagne = nbRDVAccompagne;
                    resultat.nbRDVAccompagnant = nbRDVAccompagnant;
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
                    Map<Integer, List<Integer>> valeursMensuelByWeek = new Map<Integer, List<Integer>>();
                    valeursMensuelByWeek.put(1 , new List<Integer>{objectifcaDevisS1, caDevisS1, nbContactActifS1, nbContactPassifS1});
                    valeursMensuelByWeek.put(2 , new List<Integer>{objectifcaDevisS2, caDevisS2, nbContactActifS2, nbContactPassifS2});
                    valeursMensuelByWeek.put(3 , new List<Integer>{objectifcaDevisS3, caDevisS3, nbContactActifS3, nbContactPassifS3});
                    valeursMensuelByWeek.put(4 , new List<Integer>{objectifcaDevisS4, caDevisS4, nbContactActifS4, nbContactPassifS4});
                    valeursMensuelByWeek.put(5 , new List<Integer>{objectifcaDevisS5, caDevisS5, nbContactActifS5, nbContactPassifS5});
                    resultat.objectifDevisVendu = objectifcaDevisS1 + objectifcaDevisS2 + objectifcaDevisS3 + objectifcaDevisS4 + objectifcaDevisS5;
                    resultat.nbCADevisVendu = caDevisS1 + caDevisS2 + caDevisS3 + caDevisS4 + caDevisS5;
                    resultat.nbContactActif = nbContactActif;
                    resultat.nbContactPassif = nbContactPassif;
                    resultat.valeursMensuelByWeek = valeursMensuelByWeek;
                    resultat.nbDevisVendu = nbDevisVendu;
                    resultat.numberOfWeek = weeksOfMonth.size();

                    // Calcul
                    // Taux de réalisation : % du réalisé par rapport aux objectifs
                    resultat.realisationCADevis = (resultat.objectifDevisVendu == 0) ? 0 : ((resultat.nbCADevisVendu / resultat.objectifDevisVendu) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    // Taux de participation aux contacts vente : % de contacts réalisés sur l'origine observée par rapport aux nombre total de contacts de type vente/actifs réalisés
                    resultat.tauxPartContactBAL = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactBAL / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactTAP = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactTAP / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactCOMP = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactComplement / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactPHONE = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactPhone / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactGM = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactGalerieMarchande / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactFOIRE = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactFoire / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.tauxPartContactMARCHE = (resultat.nbContactActif == 0) ? 0 : ((resultat.nbContactMarche / resultat.nbContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    // CRM-610 JMU : Nombre de RDVs & Ratios sur les nombres d'argument par origine
                    resultat.ratioParJourBAL = (resultat.joursTravailleMonth == 0) ? 0 : ((resultat.nbRDVBAL50 / resultat.joursTravailleMonth)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParContactBAL = (resultat.nbContactBAL == 0) ? 0 : ((resultat.nbRDVBAL50 / resultat.nbContactBAL)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParJourTAP = (resultat.joursTravailleMonth == 0) ? 0 : ((resultat.nbRDVTAP51 / resultat.joursTravailleMonth)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParContactTAP = (resultat.nbContactTAP == 0) ? 0 : ((resultat.nbRDVTAP51 / resultat.nbContactTAP)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParJourPhone = (resultat.joursTravailleMonth == 0) ? 0 : ((resultat.nbRDVPhone55 / resultat.joursTravailleMonth)).setScale(2, RoundingMode.HALF_EVEN);
                    resultat.ratioParContactPhone = (resultat.nbContactPhone == 0) ? 0 : ((resultat.nbRDVPhone55 / resultat.nbContactPhone)).setScale(2, RoundingMode.HALF_EVEN);

                    indicateursVendeurList.add(resultat);
                }
                System.debug('indicateursVendeurList : ' + indicateursVendeurList);
            }
            System.debug('### FIN getMensuelData');
            return indicateursVendeurList;
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   Récupération des informations hebdomadaires pour les vendeurs du magasin
    *
    **/
    @RemoteAction
    public static List<IndicateursVendeurHebdomadaire> getHebdomadaireData(String semaineActuelle, String moisActuel, String anneeActuelle, String periodId, List<String> vendeursIdList) {
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueof(moisActuel);
        Integer semaine = (semaineActuelle == null) ? 1 : Integer.valueof(semaineActuelle);
        Map<String, Integer> vendeurNbActiveDays = new Map<String, Integer>();
        Map<String, List<Event>> vendeurEvents = new Map<String, List<Event>>();
        List<IndicateursVendeurHebdomadaire> indicateursVendeurList = new List<IndicateursVendeurHebdomadaire>();

        System.debug('### DEBUT getHebdomadaireData');
        System.debug('annee : ' + annee);
        System.debug('mois : ' + mois);
        System.debug('semaine : ' + semaine);

        try {
            if(vendeursIdList != null && !vendeursIdList.isEmpty()) {
                // Period
                Period period = [SELECT StartDate, EndDate FROM Period WHERE Id = :periodId LIMIT 1];
                System.debug('period.StartDate : ' + period.StartDate);
                System.debug('period.EndDate : ' + period.EndDate);
                // Period mois actuelle
                Period monthPeriod = [SELECT StartDate, EndDate FROM Period WHERE Type = 'Month' AND StartDate <= :period.StartDate AND Type = 'Month' AND EndDate >= :period.EndDate LIMIT 1];
                System.debug('monthPeriod.StartDate : ' + monthPeriod.StartDate);
                System.debug('monthPeriod.EndDate : ' + monthPeriod.EndDate);

                // Récupération des devis vendu pour la semaine des vendeurs
                Map<Id, AggregateResult> vendeurAnnualQuotesVendu = new Map<Id, AggregateResult>([SELECT Opportunity.OwnerId Id, COUNT(Id) total, SUM(TotalHTDevis__c) ca
                                                                                                  FROM Quote
                                                                                                  WHERE dateAcceptationClient__c >= :period.StartDate
                                                                                                    AND dateAcceptationClient__c <= :period.EndDate
                                                                                                    AND opportunity.ownerId IN :vendeursIdList
                                                                                                    AND status LIKE 'Vendu%'
                                                                                                  GROUP BY Opportunity.OwnerId]);
                System.debug('vendeurAnnualQuotesVendu : ' + vendeurAnnualQuotesVendu);

                // Récupération du nombre de jours travaillés
                DateTime dtBegin = DateTime.newInstance(monthPeriod.startDate.year(), monthPeriod.startDate.month(), monthPeriod.startDate.day(), 0, 0, 0);
                DateTime dtEnd = DateTime.newInstance(monthPeriod.endDate.year(), monthPeriod.endDate.month(), monthPeriod.endDate.day(), 23, 59, 59);
                for (AggregateResult objResult : [SELECT OwnerId vendeur, COUNT(Id) total
                                                  FROM Event
                                                  WHERE activityDate >= :monthPeriod.StartDate
                                                    AND activityDate <= :monthPeriod.EndDate
                                                    AND isDeleted = false
                                                    AND type NOT IN :Constants.EVENT_ACTIVITE_CONGE_TYPES
                                                    AND ownerId IN :vendeursIdList
                                                  GROUP BY OwnerId, ActivityDate ]) {
                    Integer index = 0;
                    if(vendeurNbActiveDays.get((String)objResult.get('vendeur')) != null) index = vendeurNbActiveDays.get((String)objResult.get('vendeur'));
                    index++;
                    vendeurNbActiveDays.put((String)objResult.get('vendeur'), index);
                }

                // Récupération des activités (événements) pour la semaine des vendeurs
                dtBegin = DateTime.newInstance(period.startDate.year(), period.startDate.month(), period.startDate.day(), 0, 0, 0);
                dtEnd = DateTime.newInstance(period.endDate.year(), period.endDate.month(), period.endDate.day(), 23, 59, 59);

                List<Event> eventsResult = [SELECT Id, OwnerId, Type, nbBAL50__c, NbTAP51__c, NbPhone55__c, StatutRDV__c, IsAllDayEvent, CreatedDate,
                                                   ActivityDate, StartDateTime, EndDateTime, RecordTypeId, WhatId, IsChild, Subject
                                            FROM Event
                                            WHERE (RecordTypeId = :RT_RDVCommercial OR RecordTypeId = :RT_RDVProspection)
                                              AND (
                                                   (CreatedDate >= :dtBegin AND CreatedDate <= :dtEnd)
                                                   OR
                                                   (ActivityDate >= :period.StartDate AND ActivityDate <= :period.EndDate)
                                                   )
                                              AND IsDeleted = false
                                              AND OwnerId IN :vendeursIdList];
                Set<String> OppId = new Set<String>();
                for(Event event : eventsResult){
                    if (event.Type == 'R1')
                        OppId.add(event.whatId);

                    // Construction liste des EVENT
                    List<Event> eventList;
                    if(vendeurEvents.get(event.OwnerId) != null)
                      eventList = vendeurEvents.get(event.OwnerId);
                    else {
                      eventList = new List<Event>();
                    }
                    eventList.add(event);
                    vendeurEvents.put(event.OwnerId, eventList);
                }

                Map<Id, Opportunity> vendeurOppEvents = new Map<Id, Opportunity>([SELECT Id, OwnerId, actifParOrigine__c, accountSource__c, leadSource
                                                                                  FROM Opportunity
                                                                                  WHERE OwnerId IN :vendeursIdList
                                                                                    AND Id IN :OppId]);

                // Objectifs mensuels
                Map<String, ObjectifsVendeur__c> objectifsVendeurs = getObjectifsVendeursMensuel(anneeActuelle, moisActuel, vendeursIdList);

                // Construction de la liste de résultat
                for(String vendeur : vendeursIdList) {
                    // Calcul des totaux des RDV
                    /*****************************/
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

                    // Calcul des totaux des Contacts
                    /*****************************/
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
                            if(event.StartDateTime >= period.StartDate && event.StartDateTime <= period.EndDate.addDays(1)){
                                if(!event.IsChild && event.RecordTypeId == RT_RDVCommercial)
                                  nbRDVAccompagne = nbRDVAccompagne + 1;
                                if(event.IsChild && event.RecordTypeId == RT_RDVCommercial)
                                  nbRDVAccompagnant = nbRDVAccompagnant + 1;
                            }

                            // Calcul Créés à Posteriori et A débriefer
                            if(event.StatutRDV__c != 'Déplacé' && (event.CreatedDate.Date() >= period.StartDate && event.CreatedDate.Date() <= period.EndDate) && (event.StartDateTime <= event.CreatedDate) && (event.Type == 'R1' || event.Type == 'R2' || event.Type == 'R+'))
                              nbRDVCreeAPosteriori = nbRDVCreeAPosteriori + 1;
                            if(event.StatutRDV__c == 'Pris' && (Datetime.now() > event.StartDateTime.Date()) && (event.StartDateTime.Date() >= period.StartDate) && (event.StartDateTime.Date() <= period.EndDate))
                                nbRDVADebriefer = nbRDVADebriefer + 1;
                            System.debug(vendeur + ' avec ' + event + ' avec ' + date.today() + ' avec ' + event.StartDateTime);

                            // Gestion des RDV
                            if((event.ActivityDate >= period.StartDate) && (event.ActivityDate <= period.EndDate)){
                                // Calcul R1, R2 et R+
                                if(event.Type == 'R1') {
                                    if(event.StatutRDV__c == 'Pris')
                                      nbRDVR1_Pris = nbRDVR1_Pris + 1;
                                    else if(event.StatutRDV__c == 'Effectué')
                                      nbRDVR1_Effec = nbRDVR1_Effec + 1;
                                }
                                else if(event.Type == 'R2' || event.Type == 'R+') {
                                    if(event.StatutRDV__c == 'Pris')
                                      nbRDVR2_Pris = nbRDVR2_Pris + 1;
                                    else if(event.StatutRDV__c == 'Effectué')
                                      nbRDVR2_Effec = nbRDVR2_Effec + 1;
                                }

                                // Calcul des indicateur des événements
                                else if (event.Type == 'Prospection physique' || event.Type == 'Visite de pose') {
                                    if (event.nbBAL50__c != null)
                                      nbRDVBAL50 = nbRDVBAL50 + event.nbBAL50__c;
                                    if (event.NbTAP51__c != null)
                                      nbRDVTAP51 = nbRDVTAP51 + event.NbTAP51__c;
                                }
                                else if (event.Type == 'Phone') {
                                    if(event.NbPhone55__c != null)
                                        nbRDVPhone55 = nbRDVPhone55 + event.NbPhone55__c;
                                }
                                else if (event.Type == 'Stand/Galerie Marchande')
                                    nbRDVGalerieMarchande = nbRDVGalerieMarchande +  (event.IsAllDayEvent ? 2 : 1);
                                else if(event.Type == 'Foire')
                                    nbRDVFoire = nbRDVFoire + (event.IsAllDayEvent ? 2 : 1);
                                else if(event.Type == 'Stand/Marché')
                                    nbRDVMarche = nbRDVMarche + (event.IsAllDayEvent ? 2 : 1);
                            }

                            if((event.Type == 'R1' || event.Type == 'R2' || event.Type == 'R+') && event.ActivityDate == event.CreatedDate.date())
                                nbRDVTotalWithCreatedDate = nbRDVTotalWithCreatedDate + 1;
                            if((event.Type == 'R1' || event.Type == 'R2' || event.Type == 'R+') && event.StatutRDV__c != 'Pris')
                                nbRDVTotalNonPris = nbRDVTotalNonPris + 1;

                            if (event.Type == 'R1') {
                              // Lien avec les infos du projet
                              Opportunity opp = vendeurOppEvents.get(event.whatId);
                              if(opp != null) {
                                // Calcul Actif et Passif (Compte passif si origine call est renseignée, sinon actif)
                                if (event.CreatedDate.date() >= period.StartDate && event.CreatedDate.date() <= period.EndDate) {
                                  if(opp.actifParOrigine__c)
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

                                if(event.StartDateTime.date() >= period.StartDate && event.StartDateTime.date() <= period.EndDate
                                    && (event.StatutRDV__c == statutRDVNonEffectue[1] || event.StatutRDV__c == statutRDVNonEffectue[0]))
                                {
                                    if(opp.actifParOrigine__c)
                                        nbContactActif = nbContactActif - 1;
                                    else
                                        nbContactPassif = nbContactPassif - 1;
                                    // Calcul du nombre des comptes avec source (décremnte si pas créé lors de la période et non effectué)
/* >>> F.G., le 30/09/2015
                                    if(opp.accountSource__c == 'BAL VENDEUR') nbContactBAL = nbContactBAL - 1;
                                    if(opp.accountSource__c == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP - 1;
                                    if(opp.accountSource__c == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone - 1;
                                    if(opp.accountSource__c == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement - 1;
                                    if(opp.accountSource__c == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage - 1;
                                    if(opp.accountSource__c == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande - 1;
                                    if(opp.accountSource__c == 'FOIRE') nbContactFoire = nbContactFoire - 1;
                                    if(opp.accountSource__c == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche - 1;
   --- F.G., le 30/09/2015 */
                                    if(opp.leadSource == 'BAL VENDEUR') nbContactBAL = nbContactBAL - 1;
                                    if(opp.leadSource == 'PORTE A PORTE VENDEUR') nbContactTAP = nbContactTAP - 1;
                                    if(opp.leadSource == 'TELEPHONE VENDEUR') nbContactPhone = nbContactPhone - 1;
                                    if(opp.leadSource == 'COMPLEMENT VENDEUR') nbContactComplement = nbContactComplement - 1;
                                    if(opp.leadSource == 'PARRAINAGE VENDEUR') nbContactParrainage = nbContactParrainage - 1;
                                    if(opp.leadSource == 'STAND GM') nbContactGalerieMarchande = nbContactGalerieMarchande - 1;
                                    if(opp.leadSource == 'FOIRE') nbContactFoire = nbContactFoire - 1;
                                    if(opp.leadSource == 'STAND MARCHE VENDEUR') nbContactMarche = nbContactMarche - 1;
/* <<< F.G., le 30/09/2015 */
                                }
                              }
                            }
                        }
                    }
                    // Construction résultat
                    /*****************************/
                    IndicateursVendeurHebdomadaire resultat = new IndicateursVendeurHebdomadaire();
                    resultat.vendeurId = vendeur;
                    resultat.joursTravaille = (vendeurNbActiveDays.get(vendeur) == null) ? 0 : vendeurNbActiveDays.get(vendeur);
                    resultat.nbRDVAccompagne = nbRDVAccompagne;
                    resultat.nbRDVAccompagnant = nbRDVAccompagnant;
                    ObjectifsVendeur__c objectif = objectifsVendeurs.get(vendeur);
                    if(objectif == null) {
                        resultat.objectifContactActif = 0;
                        resultat.objectifnbDevisVendu = 0;
                        resultat.objectifCADevisVendu = 0;
                    }
                    else {
                        if(semaine == 1) {
                            resultat.objectifContactActif = objectif.nbContactsActifsS1__c;
                            resultat.objectifnbDevisVendu = objectif.nbVentesS1__c;
                            resultat.objectifCADevisVendu = Math.round(objectif.chiffreAffaireVenduS1__c);
                        } else if(semaine == 2) {
                            resultat.objectifContactActif = objectif.nbContactsActifsS2__c;
                            resultat.objectifnbDevisVendu = objectif.nbVentesS2__c;
                            resultat.objectifCADevisVendu = Math.round(objectif.chiffreAffaireVenduS2__c);
                        } else if(semaine == 3) {
                            resultat.objectifContactActif = objectif.nbContactsActifsS3__c;
                            resultat.objectifnbDevisVendu = objectif.nbVentesS3__c;
                            resultat.objectifCADevisVendu = Math.round(objectif.chiffreAffaireVenduS3__c);
                        } else if(semaine == 4) {
                            resultat.objectifContactActif = objectif.nbContactsActifsS4__c;
                            resultat.objectifnbDevisVendu = objectif.nbVentesS4__c;
                            resultat.objectifCADevisVendu = Math.round(objectif.chiffreAffaireVenduS4__c);
                        } else if(semaine == 5) {
                            resultat.objectifContactActif = objectif.nbContactsActifsS5__c;
                            resultat.objectifnbDevisVendu = objectif.nbVentesS5__c;
                            resultat.objectifCADevisVendu = Math.round(objectif.chiffreAffaireVenduS5__c);
                        }
                    }
                    resultat.nbContactActif = nbContactActif;
                    resultat.nbContactPassif = nbContactPassif;
                    resultat.nbRDVTotal = nbRDVR1_Pris + nbRDVR2_Pris + nbRDVR1_Effec + nbRDVR2_Effec;
                    resultat.nbDevisVendu = (vendeurAnnualQuotesVendu.get(vendeur) == null) ? 0 : ((Decimal)vendeurAnnualQuotesVendu.get(vendeur).get('total'));
                    if(vendeurAnnualQuotesVendu.get(vendeur) != null) {
                        Decimal devisCA = (Decimal)vendeurAnnualQuotesVendu.get(vendeur).get('ca');
                        if(devisCA != null) resultat.nbCADevisVendu = Math.round((devisCA / 1000).setScale(2, RoundingMode.HALF_EVEN));
                        else resultat.nbCADevisVendu = 0;
                    }
                    else resultat.nbCADevisVendu = 0;
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
                    resultat.objectifContactTotal = resultat.objectifContactActif;
                    resultat.nbContactTotal = nbContactActif + nbContactPassif;

                    // Calcul
                    /*****************************/
                    // Taux de réalisation : % du réalisé par rapport aux objectifs
                    resultat.realisationContact = (resultat.objectifContactTotal == 0) ? 0 : ((resultat.nbContactTotal / resultat.objectifContactTotal) * 100).setScale(0, RoundingMode.HALF_EVEN);
                    resultat.realisationContactActif = (resultat.objectifContactActif == 0) ? 0 : ((resultat.nbContactActif / resultat.objectifContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
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
                    resultat.panierMoyenObjectifVente = (resultat.objectifnbDevisVendu == 0) ? 0 : (resultat.objectifCADevisVendu / resultat.objectifnbDevisVendu).setScale(2, RoundingMode.HALF_EVEN);
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
                System.debug('indicateursVendeurList : ' + indicateursVendeurList);
            }
            System.debug('### FIN getHebdomadaireData');
            return indicateursVendeurList;
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   Fonction formatant le résultat pour l'export PDF
    *
    **/
    public List<IndicateursVendeurAll> formatValeursExport() {
        // Initialisation des objets / Compteurs
        List<IndicateursVendeurAll> finalresult = new List<IndicateursVendeurAll>();
        IndicateursVendeurTotaux resTotaux = new IndicateursVendeurTotaux();
        Integer compteur = 0;

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
        resTotaux.Somme_nbRDVMensuelAccompagne = 0;
        resTotaux.Somme_nbRDVMensuelAccompagnant = 0;
        resTotaux.Somme_nbRDVBAL50Mensuel = 0;
        resTotaux.Somme_nbContactBALMensuel = 0;
        resTotaux.Somme_nbRDVTAP51Mensuel = 0;
        resTotaux.Somme_nbContactTAPMensuel = 0;
        resTotaux.Somme_nbContactComplementMensuel = 0;
        resTotaux.Somme_nbContactParrainageMensuel = 0;
        resTotaux.Somme_nbRDVPhone55Mensuel = 0;
        resTotaux.Somme_nbContactPhoneMensuel = 0;
        resTotaux.Somme_nbRDVGalerieMarchandeMensuel = 0;
        resTotaux.Somme_nbContactGalerieMarchandeMensuel = 0;
        resTotaux.Somme_nbRDVFoireMensuel = 0;
        resTotaux.Somme_nbContactFoireMensuel = 0;
        resTotaux.Somme_nbRDVMarcheMensuel = 0;
        resTotaux.Somme_nbContactMarcheMensuel = 0;

        // Initialisation des totaux
        resTotaux.Somme_objectifContactTotal = 0;
        resTotaux.Somme_nbContactTotal = 0;
        resTotaux.Somme_objectifContactActif = 0;
        resTotaux.Somme_nbContactActif = 0;
        //resTotaux.Somme_objectifContactPassif = 0;
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
        resTotaux.Somme_objectifnbDevisVendu = 0;
        resTotaux.Somme_objectifCADevisVendu = 0;
        resTotaux.Somme_nbDevisVendu = 0;
        resTotaux.Somme_nbCADevisVendu = 0;
        resTotaux.Somme_realisationContact = 0;
        resTotaux.Somme_realisationContactActif = 0;
        resTotaux.Somme_realisationContactPassif = 0;
        resTotaux.Somme_panierMoyenObjectifVente = 0;
        resTotaux.Somme_panierMoyenRealiseVente = 0;
        resTotaux.Somme_objectifDevisVenduMensuel = 0;
        resTotaux.Somme_nbCADevisVenduMensuel = 0;
        resTotaux.Somme_nbContactActifMensuel = 0;
        resTotaux.Somme_nbContactPassifMensuel = 0;
        resTotaux.Somme_nbDevisVenduMensuel = 0;

        // Récupération des ID vendeurs et des résultats des Remote Action
        List<String> vendeursIdList = new List<String>();
        for(User use : vendeursList) vendeursIdList.add(use.Id);
        List<IndicateursVendeurMensuel> mensuelresult = Ctrl_Triptyque.getMensuelData(moisActuel, anneeActuelle, fiscalSettingsId, periodId, vendeursIdList);
        List<IndicateursVendeurHebdomadaire> hebdoresult = Ctrl_Triptyque.getHebdomadaireData(semaineActuelle, moisActuel, anneeActuelle, periodId, vendeursIdList);

        for(User vendeur : vendeursList) {
            IndicateursVendeurAll resAll = new IndicateursVendeurAll();
            IndicateursVendeurMensuel resMensuel = new IndicateursVendeurMensuel();
            IndicateursVendeurHebdomadaire resHebdomadaire = new IndicateursVendeurHebdomadaire();
            compteur++;

            for(IndicateursVendeurMensuel IVMData : mensuelresult){
                if(vendeur.Id == IVMData.vendeurId){
                    resMensuel = IVMData;
                }
            }
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
            resAll.IVM = resMensuel;
            resAll.IVH = resHebdomadaire;

            System.debug('resAll.IVH.nbDevisVendu : ' + resAll.IVH.nbDevisVendu);

            // Récupération des résultats (totaux CRM-610 JMU)
            resTotaux.Somme_nbRDVHebdoAccompagne += resAll.IVH.nbRDVAccompagne;
            resTotaux.Somme_nbRDVHebdoAccompagnant += resAll.IVH.nbRDVAccompagnant;
            resTotaux.Somme_nbRDVMensuelAccompagne += resAll.IVM.nbRDVAccompagne;
            resTotaux.Somme_nbRDVMensuelAccompagnant += resAll.IVM.nbRDVAccompagnant;

            resTotaux.Somme_nbRDVBAL50Mensuel += resAll.IVM.nbRDVBAL50;
            resTotaux.Somme_nbContactBALMensuel += resAll.IVM.nbContactBAL;
            resTotaux.Somme_nbRDVTAP51Mensuel += resAll.IVM.nbRDVTAP51;
            resTotaux.Somme_nbContactTAPMensuel += resAll.IVM.nbContactTAP;
            resTotaux.Somme_nbContactComplementMensuel += resAll.IVM.nbContactComplement;
            resTotaux.Somme_nbContactParrainageMensuel += resAll.IVM.nbContactParrainage;
            resTotaux.Somme_nbRDVPhone55Mensuel += resAll.IVM.nbRDVPhone55;
            resTotaux.Somme_nbContactPhoneMensuel += resAll.IVM.nbContactPhone;
            resTotaux.Somme_nbRDVGalerieMarchandeMensuel += resAll.IVM.nbRDVGalerieMarchande;
            resTotaux.Somme_nbContactGalerieMarchandeMensuel += resAll.IVM.nbContactGalerieMarchande;
            resTotaux.Somme_nbRDVFoireMensuel += resAll.IVM.nbRDVFoire;
            resTotaux.Somme_nbContactFoireMensuel += resAll.IVM.nbContactFoire;
            resTotaux.Somme_nbRDVMarcheMensuel += resAll.IVM.nbRDVMarche;
            resTotaux.Somme_nbContactMarcheMensuel += resAll.IVM.nbContactMarche;

            // Récupération des résultats (totaux)
            resTotaux.Somme_objectifContactTotal += resAll.IVH.objectifContactTotal;
            resTotaux.Somme_nbContactTotal += resAll.IVH.nbContactTotal;
            resTotaux.Somme_objectifContactActif += resAll.IVH.objectifContactActif;
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
            resTotaux.Somme_objectifnbDevisVendu += resAll.IVH.objectifnbDevisVendu;
            resTotaux.Somme_objectifCADevisVendu += resAll.IVH.objectifCADevisVendu;
            resTotaux.Somme_nbCADevisVendu += resAll.IVH.nbCADevisVendu;
            resTotaux.Somme_objectifDevisVenduMensuel += resAll.IVM.objectifDevisVendu;
            resTotaux.Somme_nbCADevisVenduMensuel += resAll.IVM.nbCADevisVendu;
            resTotaux.Somme_nbContactActifMensuel += resAll.IVM.nbContactActif;
            resTotaux.Somme_nbContactPassifMensuel += resAll.IVM.nbContactPassif;
            resTotaux.Somme_nbDevisVenduMensuel += resAll.IVM.nbDevisVendu;

            Somme_objectifcaDevisS1 += resAll.IVM.valeursMensuelByWeek.get(1).get(0);
            Somme_caDevisS1 += resAll.IVM.valeursMensuelByWeek.get(1).get(1);
            Somme_nbContactActifS1 += resAll.IVM.valeursMensuelByWeek.get(1).get(2);
            Somme_nbContactPassifS1 += resAll.IVM.valeursMensuelByWeek.get(1).get(3);
            Somme_objectifcaDevisS2 += resAll.IVM.valeursMensuelByWeek.get(2).get(0);
            Somme_caDevisS2 += resAll.IVM.valeursMensuelByWeek.get(2).get(1);
            Somme_nbContactActifS2 += resAll.IVM.valeursMensuelByWeek.get(2).get(2);
            Somme_nbContactPassifS2 += resAll.IVM.valeursMensuelByWeek.get(2).get(3);
            Somme_objectifcaDevisS3 += resAll.IVM.valeursMensuelByWeek.get(3).get(0);
            Somme_caDevisS3 += resAll.IVM.valeursMensuelByWeek.get(3).get(1);
            Somme_nbContactActifS3 += resAll.IVM.valeursMensuelByWeek.get(3).get(2);
            Somme_nbContactPassifS3 += resAll.IVM.valeursMensuelByWeek.get(3).get(3);
            Somme_objectifcaDevisS4 += resAll.IVM.valeursMensuelByWeek.get(4).get(0);
            Somme_caDevisS4 += resAll.IVM.valeursMensuelByWeek.get(4).get(1);
            Somme_nbContactActifS4 += resAll.IVM.valeursMensuelByWeek.get(4).get(2);
            Somme_nbContactPassifS4 += resAll.IVM.valeursMensuelByWeek.get(4).get(3);
            Somme_objectifcaDevisS5 += resAll.IVM.valeursMensuelByWeek.get(5).get(0);
            Somme_caDevisS5 += resAll.IVM.valeursMensuelByWeek.get(5).get(1);
            Somme_nbContactActifS5 += resAll.IVM.valeursMensuelByWeek.get(5).get(2);
            Somme_nbContactPassifS5 += resAll.IVM.valeursMensuelByWeek.get(5).get(3);

            // Ajout des valeurs uniques dans le résultat (totaux)
            if(compteur == vendeursList.size()){
                resTotaux.Somme_realisationContact = (resTotaux.Somme_objectifContactTotal == 0) ? 0 : ((resTotaux.Somme_nbContactTotal / resTotaux.Somme_objectifContactTotal) * 100).setScale(0, RoundingMode.HALF_EVEN);
                resTotaux.Somme_realisationContactActif = (resTotaux.Somme_objectifContactActif == 0) ? 0 : ((resTotaux.Somme_nbContactActif / resTotaux.Somme_objectifContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
                resTotaux.Somme_panierMoyenObjectifVente = (resTotaux.Somme_objectifnbDevisVendu == 0) ? 0 : (resTotaux.Somme_objectifCADevisVendu / resTotaux.Somme_objectifnbDevisVendu).setScale(2, RoundingMode.HALF_EVEN);
                resTotaux.Somme_panierMoyenRealiseVente = (resTotaux.Somme_nbDevisVendu == 0) ? 0 : (resTotaux.Somme_nbCADevisVendu / resTotaux.Somme_nbDevisVendu).setScale(2, RoundingMode.HALF_EVEN);

                Somme_valeursMensuelByWeek.put(1 , new List<Integer>{Somme_objectifcaDevisS1, Somme_caDevisS1, Somme_nbContactActifS1, Somme_nbContactPassifS1});
                Somme_valeursMensuelByWeek.put(2 , new List<Integer>{Somme_objectifcaDevisS2, Somme_caDevisS2, Somme_nbContactActifS2, Somme_nbContactPassifS2});
                Somme_valeursMensuelByWeek.put(3 , new List<Integer>{Somme_objectifcaDevisS3, Somme_caDevisS3, Somme_nbContactActifS3, Somme_nbContactPassifS3});
                Somme_valeursMensuelByWeek.put(4 , new List<Integer>{Somme_objectifcaDevisS4, Somme_caDevisS4, Somme_nbContactActifS4, Somme_nbContactPassifS4});
                Somme_valeursMensuelByWeek.put(5 , new List<Integer>{Somme_objectifcaDevisS5, Somme_caDevisS5, Somme_nbContactActifS5, Somme_nbContactPassifS5});
                resTotaux.Somme_valeursMensuelByWeek = Somme_valeursMensuelByWeek;

                resTotaux.Somme_panierMoyenCAMensuel = (resTotaux.Somme_nbDevisVenduMensuel == 0) ? 0 : (resTotaux.Somme_nbCADevisVenduMensuel / resTotaux.Somme_nbDevisVenduMensuel).setScale(0, RoundingMode.HALF_EVEN);

                resAll.IVT = resTotaux;
            }
            resAll.index = compteur-1;
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
        if(codeMagasinActuel!=null && semaineActuelle!=null && moisActuel!=null && anneeActuelle!=null) {
            // Formatage des résultats pour l'export
            valeursExportPDF = formatValeursExport();
            dateExportFormated = DateTime.now().format('dd/MM/yyyy à HH:mm:ss', UserInfo.getTimeZone().getID());
            // Affichage PDF
            PageReference triptyquePdf = Page.VF_Triptyque_PDF;
            /*triptyquePdf.getParameters().put('pAnnee', anneeActuelle);
            triptyquePdf.getParameters().put('pMois', moisActuel);
            triptyquePdf.getParameters().put('pSemaine', semaineActuelle);
            triptyquePdf.getParameters().put('pMag', codeMagasinActuel);
            triptyquePdf.getParameters().put('pFiscId', fiscalSettingsId);
            triptyquePdf.getParameters().put('pPeriodId', periodId);*/
            triptyquePdf.setRedirect(false);
            return triptyquePdf;
        } else {
            return null;
        }
    }

    // Analyse Ponctuelle
    public PageReference triptyqueAnalytique() {
        Pagereference triptyqueAnalytiquePage = new PageReference('/apex/VF_triptyque_Analytique');
        triptyqueAnalytiquePage.setRedirect(false);
        return triptyqueAnalytiquePage;
    }

    // Objectifs Vendeurs
    public PageReference objVendeurs() {
        // Affichage PDF
        PageReference ObjectifsVendeurs = Page.VF_ObjectifsVendeurs;
        ObjectifsVendeurs.getParameters().put('pAnnee', anneeActuelle);
        ObjectifsVendeurs.getParameters().put('pMois', moisActuel);
        ObjectifsVendeurs.getParameters().put('pSemaine', semaineActuelle);
        ObjectifsVendeurs.getParameters().put('pMag', codeMagasinActuel);
        ObjectifsVendeurs.setRedirect(false);
        return ObjectifsVendeurs;
    }

    public Id getLogoKparKId(){
        return DAL.getDocumentByName(Constants.KparK_logo_NB).id;
    }

    // Stockage de résultat des objectifs de l'utilisateur
    public class IndicateursObjectifUser {
        public Decimal objectifContactActif {get;set;}
        public Decimal objectifnbDevisVendu {get;set;}
        public Decimal objectifCADevisVendu {get;set;}
        public Decimal nbContactActif {get;set;}
        public Decimal nbDevisVendu {get;set;}
        public Decimal nbCADevisVendu {get;set;}
        public Decimal realisationContactActif {get;set;}
        public Decimal realisationNbDevis {get;set;}
        public Decimal realisationCADevis {get;set;}

        public IndicateursObjectifUser() {
        }
    }

    // Stockage de résultat des indicateurs d'un vendeur - Hebdomadaire
    public class IndicateursVendeurHebdomadaire {
        public String vendeurId {get;set;}
        public Integer joursTravaille {get;set;}
        public Decimal objectifContactActif {get;set;}          // C01
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
        public Decimal objectifContactTotal {get;set;}          // C23
        public Decimal nbContactTotal {get;set;}                // C24
        public Decimal nbRDVCreatedRdvDate {get;set;}           // C25
        public Decimal nbRDVDebrief {get;set;}                  // C26
        public Decimal objectifnbDevisVendu {get;set;}          // V01
        public Integer objectifCADevisVendu {get;set;}          // V02
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

        // Taux de réalisation : % du réalisé par rapport aux objectifs
        public Decimal realisationContact {get;set;}
        public Decimal realisationContactActif {get;set;}
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
        public Decimal panierMoyenObjectifVente {get;set;}
        public Decimal panierMoyenRealiseVente {get;set;}

        public IndicateursVendeurHebdomadaire() {
        }
    }

    // Stockage de résultat des indicateurs d'un vendeur - Mensuel
    public class IndicateursVendeurMensuel {
        public String vendeurId {get;set;}
        public Integer joursTravaille {get;set;}
        public Integer joursTravailleMonth {get;set;}           // CRM-610
        public Decimal objectifDevisVendu {get;set;}    // M05
        public Decimal nbCADevisVendu {get;set;}        // M06
        public Decimal nbContactActif {get;set;}        // M07
        public Decimal nbContactPassif {get;set;}       // M08
        public Map<Integer, List<Integer>> valeursMensuelByWeek {get;set;}      // M01 à M04
        public Decimal nbDevisVendu {get;set;}
        public Integer numberOfWeek {get;set;}
        // Contact par origine // CRM-610 JMU
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
        // Taux de participation aux contacts vente : % de contacts réalisés sur l'origine observée par rapport aux nombre total de contacts de type vente/actifs réalisés
        public Decimal tauxPartContactBAL {get;set;}            // CRM-610 JMU
        public Decimal tauxPartContactTAP {get;set;}            // CRM-610 JMU
        public Decimal tauxPartContactCOMP {get;set;}           // CRM-610 JMU
        public Decimal tauxPartContactPHONE {get;set;}          // CRM-610 JMU
        public Decimal tauxPartContactGM {get;set;}             // CRM-610 JMU
        public Decimal tauxPartContactFOIRE {get;set;}          // CRM-610 JMU
        public Decimal tauxPartContactMARCHE {get;set;}         // CRM-610 JMU
        // Taux de réalisation : % du réalisé par rapport aux objectifs
        public Decimal realisationCADevis {get;set;}

        public IndicateursVendeurMensuel() {
        }
    }

    // Stockage de résultat des indicateurs d'un vendeur - Totaux
    public class IndicateursVendeurTotaux {
        // Hebdo (Contact et RDV)
        public Decimal Somme_objectifContactTotal {get;set;}                // Somme C23
        public Decimal Somme_nbContactTotal {get;set;}                      // Somme C24
        public Decimal Somme_objectifContactActif {get;set;}                // Somme C01
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
        public Decimal Somme_objectifnbDevisVendu {get;set;}                // Somme V01
        public Decimal Somme_objectifCADevisVendu {get;set;}                // Somme V02
        // public Decimal Somme_nbDevisVendu {get;set;}                     // Somme V03
        public Decimal Somme_nbCADevisVendu {get;set;}                      // Somme V04
        // Mensuel
        public Decimal Somme_nbRDVMensuelAccompagne {get;set;}              // CRM-610 JMU
        public Decimal Somme_nbRDVMensuelAccompagnant {get;set;}            // CRM-610 JMU
        public Decimal Somme_objectifDevisVenduMensuel {get;set;}           // Somme M05
        public Decimal Somme_nbCADevisVenduMensuel {get;set;}               // Somme M06
        public Decimal Somme_nbContactActifMensuel {get;set;}               // Somme M07
        public Decimal Somme_nbContactPassifMensuel {get;set;}              // Somme M08
        public Map<Integer, List<Integer>> Somme_valeursMensuelByWeek {get;set;}        // Somme M01 à M04
        public Decimal Somme_nbDevisVenduMensuel {get;set;}
        // Mensuel (par origine)
        public Decimal Somme_nbRDVBAL50Mensuel {get;set;}                   // CRM-610 JMU
        public Decimal Somme_nbContactBALMensuel {get;set;}                 // CRM-610 JMU
        public Decimal Somme_nbRDVTAP51Mensuel {get;set;}                   // CRM-610 JMU
        public Decimal Somme_nbContactTAPMensuel {get;set;}                 // CRM-610 JMU
        public Decimal Somme_nbContactComplementMensuel {get;set;}          // CRM-610 JMU
        public Decimal Somme_nbContactParrainageMensuel {get;set;}          // CRM-610 JMU
        public Decimal Somme_nbRDVPhone55Mensuel {get;set;}                 // CRM-610 JMU
        public Decimal Somme_nbContactPhoneMensuel {get;set;}               // CRM-610 JMU
        public Decimal Somme_nbRDVGalerieMarchandeMensuel {get;set;}        // CRM-610 JMU
        public Decimal Somme_nbContactGalerieMarchandeMensuel {get;set;}    // CRM-610 JMU
        public Decimal Somme_nbRDVFoireMensuel {get;set;}                   // CRM-610 JMU
        public Decimal Somme_nbContactFoireMensuel {get;set;}               // CRM-610 JMU
        public Decimal Somme_nbRDVMarcheMensuel {get;set;}                  // CRM-610 JMU
        public Decimal Somme_nbContactMarcheMensuel {get;set;}              // CRM-610 JMU

        // Calculs Hebdo (Contact et RDV)
        public Decimal Somme_realisationContact  {get;set;}                 // [TR] Somme C23 C24
        public Decimal Somme_realisationContactActif {get;set;}             // [TR] Somme C01 C02
        public Decimal Somme_realisationContactPassif {get;set;}            // [TR] Somme C03 C04
        // Calculs Hebdo (Vente)
        public Decimal Somme_panierMoyenObjectifVente {get;set;}            // [PM] Somme V01 V02
        public Decimal Somme_panierMoyenRealiseVente {get;set;}             // [PM] Somme V03 V04
        // Calculs Mensuels / Annuels
        public Decimal Somme_panierMoyenCAMensuel {get;set;}                // [PM] Mensuel

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

        public IndicateursVendeurMensuel IVM {get;set;}
        public IndicateursVendeurHebdomadaire IVH {get;set;}
        public IndicateursVendeurTotaux IVT {get;set;}

        public IndicateursVendeurAll(){

        }
    }

    // Stockage des valeurs des PieCharts
    public class IndicateursPie {
        public Integer vendeurAjd {get;set;}
        public Integer vendeurDemain {get;set;}
        public Integer vendeurADemain {get;set;}
        public Integer magasinAjd {get;set;}
        public Integer magasinDemain {get;set;}
        public Integer magasinADemain {get;set;}

        public IndicateursPie(){

        }
    }
}