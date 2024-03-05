//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_ObjectifsDashboard
//-- Modifié par : SOPRA - Julien MORINEAU
//-- Modifié le  : 14/03/2016
//-- Version     : 1.2
//-- * CRM-757 : Ajout des nouveaux rôles pour la picklist des magasins
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_ObjectifsDashboard {
	public User actualUser { get; set; }
	public List<SelectOption> magasinOptionList { get; set; }
	public Map<String,String> magasinsMap { get; set; }
	public string codeMagasinActuel { get; set; }
	public string libelleMagasinActuel { get; set; }
    public String moisActuel { get; set; }
    public String anneeActuelle { get; set; }
    public String semaineActuelle { get; set; }
	public String allVendeursMagasinJSON { get; set; }

	public String periodId { get; set; }
    public String fiscalSettingsId { get; set; }
    public Map<String, String> periodIdMap { get; set; }
    public Map<String, String> fiscalSettingsIdMap { get; set; }

    private static final Set<String> statutRDVNonEffectue = new Set<String> { 'Non effectué', 'Non effectué (avec déplacement)' };

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

        system.debug('DEBUT getsemaine');

        system.debug('anneeActuelle ' + anneeActuelle);
        system.debug('moisActuel ' + moisActuel);
        if(anneeActuelle != null && anneeActuelle != ''){
            if(moisActuel != null && moisActuel != ''){
                Month = Integer.valueOf(this.moisActuel);
                for(Period p : allPeriod){
                    if (p.Type == 'Month' && p.Number == Month){
                        monthRef = p;
                        system.debug('monthRef ' + monthRef);
                    }
                }
            }
        } else {
            for(Period p : allPeriod){
                if (p.Type == 'Month' && p.EndDate >= date.today() && p.StartDate <= date.today()){
                    monthRef = p;
                    system.debug('monthRef' + monthRef);
                }
            }
        }

        for(Period p : allPeriod){
            if ((p.Type == 'Week') && (p.EndDate <= monthRef.EndDate) && (p.StartDate >= monthRef.StartDate)){
                i++;
                options.add(new SelectOption('' + i + '', 'Semaine S' + i + ' du ' + p.StartDate.Day() + '/' + p.StartDate.Month() + ' au ' + p.EndDate.Day() + '/' + p.EndDate.Month() + ''));
                periodIdMap.put(String.valueOf(i), p.Id);
                system.debug('option de la semaine ' + p.StartDate.Day() + '/' + p.StartDate.Month());
                system.debug('valeur ' + i);
            }
        }
        system.debug('FIN getsemaine');
        return options;
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
        List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, compteurAtteinteObjectifs__c
                                            FROM UserStats__c
                                            WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

        if (statsList.isEmpty()) {
            stats = new UserStats__c(name                   = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
                                    user__c                 = UserInfo.getUserId(),
                                    date__c                 = system.today(),
                                    compteurAtteinteObjectifs__c    = 0);
        } else
        	stats = statsList[0];
        system.debug('stats.compteurAtteinteObjectifs__c : ' + stats.compteurAtteinteObjectifs__c);
        stats.compteurAtteinteObjectifs__c = stats.compteurAtteinteObjectifs__c + 1;
        system.debug('stats.compteurAtteinteObjectifs__c : ' + stats.compteurAtteinteObjectifs__c);
        userStats.add(stats);
        if (!userStats.isEmpty())
            upsert userStats;
    }

	/**
    *
    *   Constructeur
    *
    **/
    public Ctrl_ObjectifsDashboard() {
        magasinsMap = new Map<String,String>();
        Integer i=1;
        Integer yearTmp = 0;
        Integer monthTmp = 0;
        periodIdMap = new Map<String, String>();

        // Récupération des informations de l'utilisateur pour magasin
        actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, LastLoginDate, UserRoleId, UserRole.Name, ProfileId, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
        /*if ((actualUser.CodeDR__c == null || actualUser.CodeDR__c == '*') && (actualUser.CodeDV__c == null || actualUser.CodeDV__c == '*') && (actualUser.CodeMagasin__c == null || actualUser.CodeMagasin__c == '*'))
            magasinsMap = DAL_Cartographie.getAllMagasins();
        else if(actualUser.UserRole.Name.containsIgnoreCase(' - REF - ') ){
			// Cas d'un référent  (JMU / CRM-757 / 14-03-2016)
			magasinsMap = DAL_Cartographie.getAllMagasinsByRole(actualUser.UserRole);
		} else {
            magasinsMap = DAL_Cartographie.getAllMagasinsByUser(actualUser);
        }*/

        UserContext context = UserContext.getContext(UserInfo.getUserId());
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
        system.debug('ANNEE ACTUELLE : ' + anneeActuelle);
        system.debug('MOIS ACTUELLE : ' + moisActuel);
        for(Period per : [SELECT StartDate, EndDate, Type FROM Period WHERE Type ='Week' AND StartDate >= :periodActuelle.StartDate AND EndDate<= :periodActuelle.EndDate]){
            if(per.EndDate < Date.today()){
                i++;
            }
        }
        semaineActuelle = '' + i + '';
        system.debug('SEMAINE ACTUELLE : ' + i);

        // Init des MAPS pour les périodes
        getsemaine();
        periodId = periodIdMap.get(semaineActuelle);
        fiscalSettingsId = fiscalSettingsIdMap.get(anneeActuelle);

        // Initialisation de la liste des vendeurs du magasin
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
        periodId = periodIdMap.get(semaineActuelle);
        fiscalSettingsId = fiscalSettingsIdMap.get(anneeActuelle);
        system.debug('codeMagasinActuel : ' + codeMagasinActuel);

        // Récupération vendeurs du magasin
        List<User> allVendeursMagasin = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, isActive, LastLoginDate,
                                (SELECT nbVentesS5__c, nbVentesS4__c, nbVentesS3__c, nbVentesS2__c, nbVentesS1__c, nbContactsActifsS5__c, nbContactsActifsS4__c,
                                        nbContactsActifsS3__c, nbContactsActifsS2__c, nbContactsActifsS1__c, moisObjectif__c, chiffreAffaireVenduS5__c,
                                        chiffreAffaireVenduS4__c, chiffreAffaireVenduS3__c, chiffreAffaireVenduS2__c, chiffreAffaireVenduS1__c, anneeObjectif__c
                                    FROM ObjectifsVendeur__r WHERE anneeObjectif__c = :annee AND moisObjectif__c = :Constants.MONTHS[mois-1]) FROM User
                                WHERE codeMagasin__c = :codeMagasinActuel AND isActive = true ORDER BY LastName ASC];

		// Sérialisation pour utilisation en JS
		allVendeursMagasinJSON = JSON.serialize(allVendeursMagasin);
    }

    /**
    *
    *   Récupération des objectifs pour l'utilisateur ou les vendeurs pour la semaine
    *
    **/
    @RemoteAction
    public static IndicateursObjectifUser getObjectifsVendeursHebdomadaire(String anneeActuelle, String moisActuel, String semaineActuelle, String periodId, List<String> userId) {
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueof(moisActuel);
        Integer semaine = (semaineActuelle == null) ? 1 : Integer.valueof(semaineActuelle);
        Map<String, List<Event>> vendeurEvents = new Map<String, List<Event>>();
        Map<String, Opportunity> vendeurOppEvents = new Map<String, Opportunity>();
        system.debug('### DEBUT getObjectifsVendeursHebdomadaire');

        try {
            // Period
            Period period = [SELECT StartDate, EndDate FROM Period WHERE Id = :periodId LIMIT 1];
            system.debug('period StartDate : ' + period.StartDate);
            system.debug('period EndDate : ' + period.EndDate);

			// Récupération du nombre de vendeurs ayant travaillés dans le mois
			Integer nbVendeursMagasinEff = 0;
			List<AggregateResult> workResult = [SELECT Count(Id), OwnerId FROM Event
													WHERE (
														(DAY_ONLY(CreatedDate) >= :period.StartDate AND DAY_ONLY(CreatedDate) <= :period.EndDate) OR
	                                            		(DAY_ONLY(StartDateTime) >= :period.StartDate AND DAY_ONLY(StartDateTime) <= :period.EndDate)
                                           			) AND IsDeleted = false AND OwnerId IN :userId
			                                        AND TYPE NOT IN :Constants.EVENT_ACTIVITE_CONGE_TYPES GROUP BY OwnerId];
			nbVendeursMagasinEff = workResult.size();

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
            Map<String, ObjectifsVendeur__c> objectifsVendeurs = getObjectifsMensuel(anneeActuelle, moisActuel, userId);

            // Construction liste pour contact actif
            List<Event> eventsResult = [SELECT Id, OwnerId, Type, nbBAL50__c, NbTAP51__c, NbPhone55__c, StatutRDV__c, IsAllDayEvent, CreatedDate,
            									ActivityDate, StartDateTime, EndDateTime, WhatId, Subject FROM Event
                                        WHERE (
                                            (DAY_ONLY(CreatedDate) >= :period.StartDate AND DAY_ONLY(CreatedDate) <= :period.EndDate) OR
                                            (DAY_ONLY(StartDateTime) >= :period.StartDate AND DAY_ONLY(StartDateTime) <= :period.EndDate)
                                            )
                                        AND IsDeleted = false AND OwnerId IN :userId];
            Set<String> OppId = new Set<String>();
            for(Event event : eventsResult){
                OppId.add(event.WhatId);
        		// Construction liste des EVENT
                List<Event> eventList = new List<Event>();
                if(vendeurEvents.get(event.OwnerId) != null) eventList = vendeurEvents.get(event.OwnerId);
                eventList.add(event);
                vendeurEvents.put(event.OwnerId, eventList);
            }
            for(Opportunity opp : [SELECT Id, OwnerId, actifParOrigine__c FROM Opportunity WHERE OwnerId IN :userId AND Id IN :OppId]) {
            	for(Event event : eventsResult){
                    // Construction liste des OPP
            		if(opp.Id == event.WhatId)
            			vendeurOppEvents.put(event.Id, opp);
            	}
            }

            // Construction résultat
            /*****************************/
            IndicateursObjectifUser resultat = new IndicateursObjectifUser();
            resultat.objectifContactActif = 0;
            resultat.objectifnbDevisVendu = 0;
            resultat.objectifCADevisVendu = 0;
            resultat.nbContactActif = 0;
            resultat.nbVendeurEffectif = 0;
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
                if(vendeurEvents.get(vendeur) != null) {
                    for(Event event : vendeurEvents.get(vendeur)) {
                        // Contacts Actifs
                        Opportunity opp = vendeurOppEvents.get(event.Id);
                    	if(opp != null) {
                            if(event.Type == 'R1' && (event.CreatedDate.date() >= period.StartDate && event.CreatedDate.date() <= period.EndDate)){
                                if(opp.actifParOrigine__c) nbContactActif = nbContactActif + 1;
                            }
                            if(event.Type == 'R1' &&
                                (event.StartDateTime.date() >= period.StartDate && event.StartDateTime.date() <= period.EndDate) &&
                                (statutRDVNonEffectue.contains(event.StatutRDV__c))
                            ){
                                if(opp.actifParOrigine__c) nbContactActif = nbContactActif - 1;
                            }
                        }
                    }
                }
            }

            resultat.nbDevisVendu = nbDevisVendu;
            resultat.nbCADevisVendu = caDevisVendu;
            resultat.nbContactActif = nbContactActif;
            resultat.nbVendeurEffectif = nbVendeursMagasinEff;
            resultat.nbCADevisVendu = (resultat.nbCADevisVendu / 1000).setScale(2, RoundingMode.HALF_EVEN);
            resultat.nbContactActifEff = (nbVendeursMagasinEff == 0) ? 0 : (nbContactActif / nbVendeursMagasinEff).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationContactActif = (resultat.objectifContactActif == 0) ? 0 : ((nbContactActif / resultat.objectifContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationContactActifEffectif = (nbVendeursMagasinEff == 0) ? 0 : ((nbContactActif / nbVendeursMagasinEff) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationNbDevis = (resultat.objectifnbDevisVendu == 0) ? 0 : ((nbDevisVendu / resultat.objectifnbDevisVendu) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationCADevis = (resultat.objectifCADevisVendu == 0) ? 0 : ((resultat.nbCADevisVendu / resultat.objectifCADevisVendu) * 100).setScale(0, RoundingMode.HALF_EVEN);

            system.debug('### FIN getObjectifsVendeursHebdomadaire');
            return resultat;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   Récupération des objectifs pour l'utilisateur ou les vendeurs pour le mois
    *
    **/
    @RemoteAction
    public static IndicateursObjectifUser getObjectifsVendeursMensuel(String anneeActuelle, String moisActuel, String fiscalSettingId, List<String> userId) {
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueof(moisActuel);
        Map<String, List<Event>> vendeurEvents = new Map<String, List<Event>>();
        Map<String, Opportunity> vendeurOppEvents = new Map<String, Opportunity>();
        system.debug('### DEBUT getObjectifsVendeursMensuel');

        try {
            // Period
            Period period = [SELECT StartDate, EndDate FROM Period WHERE Number = :mois AND Type = 'Month' AND FiscalYearSettingsId = :fiscalSettingId LIMIT 1];
            system.debug('period.StartDate : ' + period.StartDate);
            system.debug('period.EndDate : ' + period.EndDate);

			// Récupération du nombre de vendeurs ayant travaillés dans le mois
			Integer nbVendeursMagasinEff = 0;
			List<AggregateResult> workResult = [SELECT Count(Id), OwnerId FROM Event
													WHERE (
														(DAY_ONLY(CreatedDate) >= :period.StartDate AND DAY_ONLY(CreatedDate) <= :period.EndDate) OR
	                                            		(DAY_ONLY(StartDateTime) >= :period.StartDate AND DAY_ONLY(StartDateTime) <= :period.EndDate)
                                           			) AND IsDeleted = false AND OwnerId IN :userId
			                                        AND TYPE NOT IN :Constants.EVENT_ACTIVITE_CONGE_TYPES GROUP BY OwnerId];
			nbVendeursMagasinEff = workResult.size();

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
            Map<String, ObjectifsVendeur__c> objectifsVendeurs = getObjectifsMensuel(anneeActuelle, moisActuel, userId);

            // Construction liste pour contact actif
            List<Event> eventsResult = [SELECT Id, OwnerId, Type, nbBAL50__c, NbTAP51__c, NbPhone55__c, StatutRDV__c, IsAllDayEvent, CreatedDate,
            									ActivityDate, StartDateTime, EndDateTime, WhatId, Subject FROM Event
                                        WHERE (
                                            (DAY_ONLY(CreatedDate) >= :period.StartDate AND DAY_ONLY(CreatedDate) <= :period.EndDate) OR
                                            (DAY_ONLY(StartDateTime) >= :period.StartDate AND DAY_ONLY(StartDateTime) <= :period.EndDate)
                                            )
                                        AND IsDeleted = false AND OwnerId IN :userId];
            Set<String> OppId = new Set<String>();
            for(Event event : eventsResult){
                OppId.add(event.WhatId);
        		// Construction liste des EVENT
                List<Event> eventList = new List<Event>();
                if(vendeurEvents.get(event.OwnerId) != null) eventList = vendeurEvents.get(event.OwnerId);
                eventList.add(event);
                vendeurEvents.put(event.OwnerId, eventList);
            }
            for(Opportunity opp : [SELECT Id, OwnerId, actifParOrigine__c FROM Opportunity WHERE OwnerId IN :userId AND Id IN :OppId]) {
            	for(Event event : eventsResult){
                    // Construction liste des OPP
            		if(opp.Id == event.WhatId)
            			vendeurOppEvents.put(event.Id, opp);
            	}
            }

            // Construction résultat
            /*****************************/
            IndicateursObjectifUser resultat = new IndicateursObjectifUser();
            resultat.objectifContactActif = 0;
            resultat.objectifnbDevisVendu = 0;
            resultat.objectifCADevisVendu = 0;
            resultat.nbContactActif = 0;
            resultat.nbContactActifEff = 0;
            resultat.nbVendeurEffectif = 0;
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
                    resultat.objectifContactActif += objectif.nbContactsActifsS1__c + objectif.nbContactsActifsS2__c + objectif.nbContactsActifsS3__c + objectif.nbContactsActifsS4__c + objectif.nbContactsActifsS5__c;
                    resultat.objectifnbDevisVendu += objectif.nbVentesS1__c + objectif.nbVentesS2__c + objectif.nbVentesS3__c + objectif.nbVentesS4__c + objectif.nbVentesS5__c;
                    resultat.objectifCADevisVendu += objectif.chiffreAffaireVenduS1__c + objectif.chiffreAffaireVenduS2__c + objectif.chiffreAffaireVenduS3__c + objectif.chiffreAffaireVenduS4__c + objectif.chiffreAffaireVenduS5__c;
                }

                // Calcul des totaux des comptes
                if(vendeurEvents.get(vendeur) != null) {
                    for(Event event : vendeurEvents.get(vendeur)) {
                        // Contacts Actifs
                        Opportunity opp = vendeurOppEvents.get(event.Id);
                    	if(opp != null) {
                            if(event.Type == 'R1' && (event.CreatedDate.date() >= period.StartDate && event.CreatedDate.date() <= period.EndDate)){
                                if(opp.actifParOrigine__c) nbContactActif = nbContactActif + 1;
                            }
                            if(event.Type == 'R1' &&
                                (event.StartDateTime.date() >= period.StartDate && event.StartDateTime.date() <= period.EndDate) &&
                                (statutRDVNonEffectue.contains(event.StatutRDV__c))
                            ){
                                if(opp.actifParOrigine__c) nbContactActif = nbContactActif - 1;
                            }
                        }
                    }
                }
            }

            resultat.nbDevisVendu = nbDevisVendu;
            resultat.nbCADevisVendu = caDevisVendu;
            resultat.nbContactActif = nbContactActif;
            resultat.nbVendeurEffectif = nbVendeursMagasinEff;
            resultat.nbCADevisVendu = (resultat.nbCADevisVendu / 1000).setScale(2, RoundingMode.HALF_EVEN);
            resultat.nbContactActifEff = (nbVendeursMagasinEff == 0) ? 0 : (nbContactActif / nbVendeursMagasinEff).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationContactActif = (resultat.objectifContactActif == 0) ? 0 : ((nbContactActif / resultat.objectifContactActif) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationContactActifEffectif = (nbVendeursMagasinEff == 0) ? 0 : ((nbContactActif / nbVendeursMagasinEff) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationNbDevis = (resultat.objectifnbDevisVendu == 0) ? 0 : ((nbDevisVendu / resultat.objectifnbDevisVendu) * 100).setScale(0, RoundingMode.HALF_EVEN);
            resultat.realisationCADevis = (resultat.objectifCADevisVendu == 0) ? 0 : ((resultat.nbCADevisVendu / resultat.objectifCADevisVendu) * 100).setScale(0, RoundingMode.HALF_EVEN);

            system.debug('### FIN getObjectifsVendeursMensuel');
            return resultat;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   Récupération des objectifs du mois pour les vendeurs
    *
    **/
    public static Map<String, ObjectifsVendeur__c> getObjectifsMensuel(String anneeActuelle, String moisActuel, List<String> vendeursIdList) {
        Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
        Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueOf(moisActuel);
        List<ObjectifsVendeur__c> objectifsVendeurList = new List<ObjectifsVendeur__c>();
        Map<String, ObjectifsVendeur__c> objectifsVendeurMensuel = new Map<String, ObjectifsVendeur__c>();

        // Récupération des objectifs
        if(vendeursIdList != null && !vendeursIdList.isEmpty()) {
            objectifsVendeurList = [SELECT Id, anneeObjectif__c, vendeur__c, moisObjectif__c,
                                        chiffreAffaireVenduS1__c, chiffreAffaireVenduS2__c, chiffreAffaireVenduS3__c, chiffreAffaireVenduS4__c, chiffreAffaireVenduS5__c,
                                        nbContactsActifsS1__c, nbContactsActifsS2__c, nbContactsActifsS3__c, nbContactsActifsS4__c, nbContactsActifsS5__c,
                                        nbVentesS1__c, nbVentesS2__c, nbVentesS3__c, nbVentesS4__c, nbVentesS5__c FROM ObjectifsVendeur__c
                                        WHERE vendeur__c IN :vendeursIdList AND anneeObjectif__c = :annee AND moisObjectif__c = :Constants.MONTHS[mois-1]];

            // Construction de la map des objectifs
            for(ObjectifsVendeur__c objectif : objectifsVendeurList) {
                objectifsVendeurMensuel.put(objectif.vendeur__c, objectif);
            }
        }

        system.debug('objectifsVendeurMensuel : ' + objectifsVendeurMensuel);
        return objectifsVendeurMensuel;
    }

    // Stockage de résultat des objectifs de l'utilisateur
    public class IndicateursObjectifUser {
        public Decimal objectifContactActif {get;set;}
        public Decimal objectifnbDevisVendu {get;set;}
        public Decimal objectifCADevisVendu {get;set;}
        public Decimal nbContactActif {get;set;}
        public Decimal nbContactActifEff {get;set;}
        public Decimal nbVendeurEffectif {get;set;}
        public Decimal nbDevisVendu {get;set;}
        public Decimal nbCADevisVendu {get;set;}
        public Decimal realisationContactActif {get;set;}
        public Decimal realisationContactActifEffectif {get;set;}
        public Decimal realisationNbDevis {get;set;}
        public Decimal realisationCADevis {get;set;}

        public IndicateursObjectifUser() {
        }
    }
}