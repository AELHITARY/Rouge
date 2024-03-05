//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_ObjectifsVendeurs
//-- Modifié par : SOPRA - Julien MORINEAU
//-- Modifié le  : 14/03/2016
//-- Version     : 1.2
//-- * CRM-757 : Ajout des nouveaux rôles pour la picklist des magasins
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_ObjectifsVendeurs {
	public User actualUser { get; set; }
	public List<SelectOption> magasinOptionList { get; set; }
	public string codeMagasinActuel { get; set; }
	public String moisActuel { get; set; }
	public String anneeActuelle { get; set; }
	public String periodId { get; set; }
	public String semaineActuelle { get; set; }
	public Map<String, String> periodIdMap { get; set; }
	public String fiscalSettingsId { get; set; }
	public Map<String, String> fiscalSettingsIdMap { get; set; }
	public static final Integer CA_MIN = PropertiesUtils.getIntegerValue('triptyque.objectif.ca', 18);
	public Integer CA_MIN_VF {get{ return PropertiesUtils.getIntegerValue('triptyque.objectif.ca', 18); } set;}

	// Period SOQL
	private static List<Period> periodYears = [SELECT StartDate, EndDate, Type FROM Period WHERE Type='Year'];
	private static List<Period> periodMonthYearCurrentWeek = [SELECT StartDate, EndDate, Type, Number FROM Period WHERE (Type='Month' OR Type='Year') AND StartDate <= TODAY AND EndDate >= TODAY LIMIT 2];

	/**
	*
	* 	GETTER : Récupération des mois de l'année commerciale
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

		if(anneeActuelle!=null && anneeActuelle!='')
			Year = Integer.valueOf(this.anneeActuelle);
		else
			Year = yearTmp.Year();

		if(Year == Date.Today().Year()){
			for(Period pm : periodMonthYearCurrentWeek){
				if (pm.Type == 'Month' && Date.Today() >= pm.StartDate && Date.today() <= pm.EndDate)
					Month = pm.Number;
			}
			for (i=1;i<=Month;i++){
				options.add(new SelectOption('' + i + '', Constants.MONTHS[i-1]));
			}
			// Ajout du mois suivant le mois actuel (Evolution JMU 23/09/2014)
			if(Month <= 11){
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
	* 	GETTER : Récupération des années commerciales
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
	* 	GETTER : Récupération des semaines du mois et année commercial
	*
	**/
	public List<SelectOption> getsemaine() {
		List<SelectOption> options = new List<SelectOption>();
		Integer i = 0;
		Period monthRef = new Period();
		String annee = anneeActuelle +'%';
		Integer Month = 0;
		List<Period> allPeriod = [SELECT Id, StartDate, EndDate, Type, Number FROM Period
									WHERE FiscalYearSettingsId IN (SELECT Id FROM FiscalYearSettings WHERE Name LIKE :annee) ORDER BY Number ASC];

		system.debug('DEBUT getsemaine');

		system.debug('anneeActuelle ' + anneeActuelle);
		system.debug('moisActuel ' + moisActuel);
		if(anneeActuelle != null && anneeActuelle != ''){
			if(moisActuel != null && moisActuel != ''){
				Month = Integer.valueOf(this.moisActuel);
				for(Period p : allPeriod){
					if (p.Type == 'Month' && p.Number == Month){
						monthRef = p;
					}
				}
				system.debug('anneeActuelle' + anneeActuelle);
				system.debug('moisActuel' + moisActuel);
				system.debug('Month' + Month);
				system.debug('MonthRef.Number' + MonthRef.Number);
			}
		} else {
			for(Period p : allPeriod){
				if (p.Type == 'Month' && p.EndDate >= date.today() && p.StartDate <= date.today())
					monthRef = p;
			}
		}

		for(Period p : allPeriod){
			if ((p.Type == 'Week') && (p.EndDate <= monthRef.EndDate) && (p.StartDate >= monthRef.StartDate)){
				i++;
				//options.add(new SelectOption('' + i + '|' + p.Id + '', 'Semaine S' + i + ' du ' + p.StartDate.Day() + '/' + p.StartDate.Month() + ' au ' + p.EndDate.Day() + '/' + p.EndDate.Month() + ''));
				options.add(new SelectOption('' + i + '', 'Semaine S' + i + ' du ' + p.StartDate.Day() + '/' + p.StartDate.Month() + ' au ' + p.EndDate.Day() + '/' + p.EndDate.Month() + ''));
				periodIdMap.put(String.valueOf(i), p.Id);
				system.debug('option de la semaine ' + p.StartDate.Day() + '/' + p.StartDate.Month());
				system.debug('valeur ' + i);
			}
		}
		return options;
	}

	/**
	*
	* 	Fonction appelée lors l'ouverture de la page pour incrémentation des stats
	*
	**/
	public void insertUserStats() {
		insertUserStatsFuture(Userinfo.getUserId());
	}

	/**
	*
	* 	Fonction asynchrone pour incrémentation statistique utilisateur
	*
	**/
	@future
	public static void insertUserStatsFuture(Id userId) {
		List<UserStats__c> userStats = new List<UserStats__c>();
		UserStats__c stats;
		List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, compteurObjectifVendeur__c
											FROM UserStats__c
											WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

		if (statsList.isEmpty()) {
			stats = new UserStats__c(name                   = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
									user__c                 = UserInfo.getUserId(),
									date__c                 = System.today(),
									compteurObjectifVendeur__c    = 0);
		} else
			stats = statsList[0];

		system.debug('stats.compteurObjectifVendeur__c : ' + stats.compteurObjectifVendeur__c);
		stats.compteurObjectifVendeur__c = stats.compteurObjectifVendeur__c + 1;
		system.debug('stats.compteurObjectifVendeur__c : ' + stats.compteurObjectifVendeur__c);
		userStats.add(stats);

		if (!userStats.isEmpty())
			upsert userStats;
	}

	/**
	*
	* 	Constructeur
	*
	**/
	public Ctrl_ObjectifsVendeurs() {
		Map<String,String> magasinsMap = new Map<String,String>();
		List<Integer> lundis = new List<Integer>();
		Integer i=1;
		Integer yearTmp = 0;
		Integer monthTmp = 0;
		periodIdMap = new Map<String, String>();

		// Récupération des informations de l'utilisateur pour magasin
		actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, LastLoginDate, UserRoleId, UserRole.Name, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];
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
		if(actualUser.CodeMagasin__c != null && actualUser.CodeMagasin__c != '*')
			codeMagasinActuel = actualUser.CodeMagasin__c;
		else if (!magasinsMap.isEmpty() && magasinsMap != null) {
			codeMagasinActuel = magasinOptionList.get(0).getValue();
		}
		if(magasinOptionList.isEmpty()) magasinOptionList.add(new SelectOption('Aucun', 'Aucun'));
		system.debug('magasinOptionList ' + magasinOptionList.get(0).getValue());

		if(ApexPages.currentPage().getParameters().get('pMag') != null) codeMagasinActuel = ApexPages.currentPage().getParameters().get('pMag');

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
		if(ApexPages.currentPage().getParameters().get('pAnnee') != null) anneeActuelle = ApexPages.currentPage().getParameters().get('pAnnee');

		moisActuel = String.valueOf(monthTmp);
		if(ApexPages.currentPage().getParameters().get('pMois') != null) moisActuel = ApexPages.currentPage().getParameters().get('pMois');

		system.debug('moisActuel4' + moisActuel);
		for(Period per : [SELECT StartDate, EndDate, Type FROM Period WHERE Type ='Week' AND StartDate >= :periodActuelle.StartDate AND EndDate<= :periodActuelle.EndDate]){
			if(per.EndDate <= Date.today()){
				i++;
			}
		}
		semaineActuelle = '' + i + '';
		if(ApexPages.currentPage().getParameters().get('pSemaine') != null) semaineActuelle = ApexPages.currentPage().getParameters().get('pSemaine');
		system.debug('SEMAINE ACTUELLE' + i);

		// Init des MAPS pour les périodes
		getsemaine();
		periodId = periodIdMap.get(semaineActuelle);
		fiscalSettingsId = fiscalSettingsIdMap.get(anneeActuelle);
	}

	/**
	*
	* 	Récupération des vendeurs du magasin
	*
	**/
	@RemoteAction
	public static List<User> getActiveVendeurs(String codeMagasinActuel) {
		// On ajoute tous les vendeurs actifs du magasin
		List<User> vendeursList = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, isActive, LastLoginDate FROM User WHERE codeMagasin__c = :codeMagasinActuel ORDER BY LastName ASC];
		if(vendeursList.isEmpty()) {
			User actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, isActive, LastLoginDate FROM User WHERE Id = :UserInfo.getUserId()];
			vendeursList.add(actualUser);
		}

		system.debug('vendeursList : ' + vendeursList);
		return vendeursList;
	}

	/**
	*
	* 	Création des objectifs pour les vendeurs du magasin
	*
	**/
	@RemoteAction
	public static Map<String, ObjectifsVendeur__c> createObjectifsVendeurs(String anneeActuelle, String moisActuel, List<String> vendeursIdList) {
		Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
		Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueOf(moisActuel);
		List<ObjectifsVendeur__c> objectifsVendeurList = new List<ObjectifsVendeur__c>();
		List<ObjectifsVendeur__c> objectifsVendeurListCreate = new List<ObjectifsVendeur__c>();
		Map<String, ObjectifsVendeur__c> objectifsVendeurMensuel = new Map<String, ObjectifsVendeur__c>();
		List<String> idVendeurCreateObjectifs = new List<String>();

		system.debug('DEBUT createObjectifsVendeurs');

		try {
			// Récupération des objectifs
			if(vendeursIdList != null && !vendeursIdList.isEmpty()) {
				objectifsVendeurList = [SELECT Id, vendeur__c FROM ObjectifsVendeur__c
											WHERE vendeur__c IN :vendeursIdList AND anneeObjectif__c = :annee AND moisObjectif__c = :Constants.MONTHS[mois-1] ORDER BY vendeur__r.LastName ASC];

				// Construction de la map des objectifs
				for(String vendeur : vendeursIdList) {
					for(ObjectifsVendeur__c objectif : objectifsVendeurList) {
						if(vendeur == objectif.vendeur__c)
							objectifsVendeurMensuel.put(vendeur, objectif);
					}
				}

				// Création des objectifs pour les vendeurs sans objectifs pour l'année et le mois
				for(String vendeur : vendeursIdList) {
					if(objectifsVendeurMensuel.get(vendeur) == null) {
						ObjectifsVendeur__c obj = new ObjectifsVendeur__c(anneeObjectif__c = annee,
																			moisObjectif__c = Constants.MONTHS[mois-1],
																			vendeur__c = vendeur);
						objectifsVendeurListCreate.add(obj);
						objectifsVendeurMensuel.put(vendeur, obj);
					}
				}
				if(!objectifsVendeurListCreate.isEmpty())
					insert objectifsVendeurListCreate;
			}

			system.debug('objectifsVendeurListCreate : ' + objectifsVendeurListCreate);
			system.debug('FIN createObjectifsVendeurs');
			return objectifsVendeurMensuel;
		} catch (Exception e) {
			system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
			throw e;
		}
	}

	/**
	*
	* 	Récupération des objectifs pour les vendeurs du magasin
	*
	**/
	@RemoteAction
	public static Map<String, ObjectifsVendeur__c> getObjectifsVendeurs(String anneeActuelle, String moisActuel, List<String> vendeursIdList) {
		Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
		Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueOf(moisActuel);
		List<ObjectifsVendeur__c> objectifsVendeurList = new List<ObjectifsVendeur__c>();
		Map<String, ObjectifsVendeur__c> objectifsVendeurMensuel = new Map<String, ObjectifsVendeur__c>();

		system.debug('DEBUT getObjectifsVendeurs');

		try {
			// Récupération des objectifs
			if(vendeursIdList != null && !vendeursIdList.isEmpty()) {
				objectifsVendeurList = [SELECT Id, anneeObjectif__c, vendeur__c, moisObjectif__c,
										chiffreAffaireVenduS1__c, chiffreAffaireVenduS2__c, chiffreAffaireVenduS3__c, chiffreAffaireVenduS4__c, chiffreAffaireVenduS5__c,
										nbContactsActifsS1__c, nbContactsActifsS2__c, nbContactsActifsS3__c, nbContactsActifsS4__c, nbContactsActifsS5__c,
										nbVentesS1__c, nbVentesS2__c, nbVentesS3__c, nbVentesS4__c, nbVentesS5__c FROM ObjectifsVendeur__c
										WHERE vendeur__c IN :vendeursIdList AND anneeObjectif__c = :annee AND moisObjectif__c = :Constants.MONTHS[mois-1] ORDER BY vendeur__r.LastName ASC];

				// Construction de la map des objectifs
				for(String vendeur : vendeursIdList) {
					for(ObjectifsVendeur__c objectif : objectifsVendeurList) {
						if(vendeur == objectif.vendeur__c)
							objectifsVendeurMensuel.put(vendeur, objectif);
					}
				}
			}

			system.debug('objectifsVendeurMensuel : ' + objectifsVendeurMensuel);
			system.debug('FIN getObjectifsVendeurs');
			return objectifsVendeurMensuel;
		} catch (Exception e) {
			system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
			throw e;
		}
	}

	/**
	*
	* 	Mise à jour des objectifs pour les vendeurs du tableau
	*
	**/
	@RemoteAction
	public static Boolean updateObjectifs(String anneeActuelle, String moisActuel, String semaineActuelle, String fiscalSettingId, List<Map<String,String>> arguments) {
		Integer annee = (anneeActuelle == null) ? date.today().year() : Integer.valueof(anneeActuelle);
		Integer mois = (moisActuel == null) ? date.today().month() : Integer.valueOf(moisActuel);
		List<ObjectifsVendeur__c> objectifsVendeurList = new List<ObjectifsVendeur__c>();
		Map<String, Map<String, Decimal>> objectifsVendeurs = new Map<String, Map<String, Decimal>>();
		Map<Integer, List<Date>> weeksOfMonth = new Map<Integer, List<Date>>();
		Integer semaine = (semaineActuelle == null) ? 1 : Integer.valueof(semaineActuelle);
		Boolean CAMensuelMini = true;

		system.debug('DEBUT updateObjectifs');
		system.debug('arguments : ' + arguments);

		try{
			for(Map<String,String> mapArguments : arguments) {
				// Construction de la MAP pour les valeurs
				Map<String, Decimal> values = new Map<String, Decimal>();
				values.put('contactActif', Decimal.valueOf(mapArguments.get('contactActif')));
				values.put('ventes', Decimal.valueOf(mapArguments.get('ventes')));
				values.put('caVendu', Decimal.valueOf(mapArguments.get('caVendu')));
				objectifsVendeurs.put(mapArguments.get('id'), values);
			}

			// Period
			Period period = [SELECT StartDate, EndDate FROM Period WHERE Number = :mois AND Type = 'Month' AND FiscalYearSettingsId = :fiscalSettingId LIMIT 1];
			Integer i = 1;
			for(Period week : [SELECT StartDate, EndDate, Number FROM Period WHERE Type = 'Week'
								AND StartDate >= :period.StartDate AND EndDate <= :period.EndDate ORDER BY Number ASC]) {
				weeksOfMonth.put(i, new List<Date>{week.StartDate, week.EndDate});
				i++;
			}

			system.debug('objectifsVendeurs : ' + objectifsVendeurs);

			// Récupération des objectifs
			Decimal totalCAMonth = 0;
			if(objectifsVendeurs != null && !objectifsVendeurs.isEmpty()) {
				objectifsVendeurList = [SELECT Id, anneeObjectif__c, vendeur__c, moisObjectif__c,
										chiffreAffaireVenduS1__c, chiffreAffaireVenduS2__c, chiffreAffaireVenduS3__c, chiffreAffaireVenduS4__c, chiffreAffaireVenduS5__c,
										nbContactsActifsS1__c, nbContactsActifsS2__c, nbContactsActifsS3__c, nbContactsActifsS4__c, nbContactsActifsS5__c,
										nbVentesS1__c, nbVentesS2__c, nbVentesS3__c, nbVentesS4__c, nbVentesS5__c FROM ObjectifsVendeur__c
										WHERE vendeur__c IN :objectifsVendeurs.keySet() AND anneeObjectif__c = :annee AND moisObjectif__c = :Constants.MONTHS[mois-1]];

				for (ObjectifsVendeur__c obj : objectifsVendeurList){
					// Récupère les valeurs
					Map<String, Decimal> values = objectifsVendeurs.get(obj.vendeur__c);
					Integer contactsActifs = Integer.valueOf(values.get('contactActif'));
					Integer nbVentes = Integer.valueOf(values.get('ventes'));
					Decimal chiffreAffaireVendu = values.get('caVendu');

					// Settage
					if(semaineActuelle == '1') {
						obj.nbContactsActifsS1__c = contactsActifs;
						obj.nbVentesS1__c = nbVentes;
						obj.chiffreAffaireVenduS1__c = chiffreAffaireVendu;
					} else if(semaineActuelle == '2') {
						obj.nbContactsActifsS2__c = contactsActifs;
						obj.nbVentesS2__c = nbVentes;
						obj.chiffreAffaireVenduS2__c = chiffreAffaireVendu;
					} else if(semaineActuelle == '3') {
						obj.nbContactsActifsS3__c = contactsActifs;
						obj.nbVentesS3__c = nbVentes;
						obj.chiffreAffaireVenduS3__c = chiffreAffaireVendu;
					} else if(semaineActuelle == '4') {
						obj.nbContactsActifsS4__c = contactsActifs;
						obj.nbVentesS4__c = nbVentes;
						obj.chiffreAffaireVenduS4__c = chiffreAffaireVendu;
					} else if(semaineActuelle == '5') {
						obj.nbContactsActifsS5__c = contactsActifs;
						obj.nbVentesS5__c = nbVentes;
						obj.chiffreAffaireVenduS5__c = chiffreAffaireVendu;
					}

					system.debug('CA_MIN : ' + CA_MIN);
					if(weeksOfMonth.size() == 4 && obj.chiffreAffaireVenduS4__c != 0){
						if(!objectifsVendeurList.isEmpty()){
							if((obj.chiffreAffaireVenduS1__c + obj.chiffreAffaireVenduS2__c + obj.chiffreAffaireVenduS3__c + obj.chiffreAffaireVenduS4__c) < CA_MIN){
								CAMensuelMini = false;
							}
						}
					}else if(weeksOfMonth.size() == 5 && obj.chiffreAffaireVenduS5__c != 0){
						if(!objectifsVendeurList.isEmpty()){
							if((obj.chiffreAffaireVenduS1__c + obj.chiffreAffaireVenduS2__c + obj.chiffreAffaireVenduS3__c + obj.chiffreAffaireVenduS4__c + obj.chiffreAffaireVenduS5__c) < CA_MIN){
								CAMensuelMini = false;
							}
						}
					}
				}

				if(CAMensuelMini){
					if(!objectifsVendeurList.isEmpty())
						update objectifsVendeurList;
				}
			}
			system.debug('FIN updateObjectifs');
			return CAMensuelMini;
		} catch(exception e) {
			system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
			throw e;
		}
	}
}