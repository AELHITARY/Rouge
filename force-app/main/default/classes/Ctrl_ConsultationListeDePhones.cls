//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_ConsultationListeDePhones
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/03/2020
//-- Version     : 1.3
//-- * 1.3 : RQM-70 : Evolution pour utilisation de leaflet
//-- * 1.2 : CRM-988 : Evolution de la cartographie pour secteur sans polygones
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_ConsultationListeDePhones {
	public User userinfos {get; set;}
	public String codeRegion {get; set;}
    public String codeDV {get; set;}
    public String codeMag {get; set;}
    public String nomLDP {get; set;}
    public String nomVendeur {get; set;}
    public Account vendeur {get { return vendeur;}set;}{vendeur = new Account(Type='',OwnerId = null);}
	public String dateDebut {get;set;}
    public String dateFin {get;set;}
    public String dateDebutTemp {get;set;}
    public String dateFinTemp {get;set;}
    public String motifAnnulation {get; set;}
    public Boolean unlockMagasin { get; set; }
    public Integer defaultDureeRDV {get; set;}{defaultDureeRDV = PropertiesUtils.getIntegerValue('ldp.dureeRDV');}	
	public PhoningVendeur__c phoning {get { return phoning;}set;}{phoning = new PhoningVendeur__c();}    
    Map<String,String> magasinsMap = new Map<String,String>();
    
    // DQE  
    public String licenceDQE {get; set;}
    transient public GoogleMapsSettings__c googleMapsSettings { get; private set; }
    static Set<String> codeMagWithAtt;
    public List<String> sectorNamesList { get; set; }
    public String sectorName { get; set; }

    // Statut devis
    public static List<String> STATUT_DEVIS {get{
        List<String> statutDevisList = new List<String>();
        statutDevisList.add(Constants.StatutDevisTransmis);
        statutDevisList.add(Constants.StatutDevisVenduAttente);
        statutDevisList.add(Constants.StatutDevisVenduEnregistre);
        statutDevisList.add(Constants.StatutDevisVenduIncontournable);
        return statutDevisList;
    } set;}

    // Statut LDP
    public String phoneStatutAnnule {get; set;}{phoneStatutAnnule = Constants.StatutLDPAnnulee;}

	/**
    * @description Initialisation des options DR
    */
    public List<SelectOption> optionsRegion {get; set;} {
        optionsRegion = new List<SelectOption>();
        for(AggregateResult ar : [select libelleRegion__c, codeRegion__c from Sectorisation__c GROUP BY libelleRegion__c, codeRegion__c ORDER BY libelleRegion__c]){
            if (ar.get('codeRegion__c') != null && ar.get('libelleRegion__c') != null)
                optionsRegion.add(new SelectOption(String.valueOf(ar.get('codeRegion__c')), String.valueOf(ar.get('libelleRegion__c'))));
        }
        if(!optionsRegion.isEmpty())
            codeRegion = optionsRegion[0].getValue();
    }
	/**
    * @description Initialisation des options DV
    */
    public List<SelectOption> optionsDV {get{
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));
        if(codeRegion!=null && codeRegion != '*'){
            for(AggregateResult ar : [select libelleDV__c, codeDV__c from Sectorisation__c WHERE codeRegion__c=:codeRegion GROUP BY libelleDV__c, codeDV__c ORDER BY libelleDV__c]){
                system.debug('codeRegion : '+codeRegion);
                system.debug('ar : '+ar);
                if (ar.get('codeDV__c') != null && ar.get('libelleDV__c') != null)
                    options.add(new SelectOption(String.valueOf(ar.get('codeDV__c')), String.valueOf(ar.get('libelleDV__c'))));
            }
        } else {
            for(AggregateResult ar : [select libelleDV__c, codeDV__c from Sectorisation__c GROUP BY libelleDV__c, codeDV__c ORDER BY libelleDV__c]){
                if (ar.get('codeDV__c') != null && ar.get('libelleDV__c') != null)
                    options.add(new SelectOption(String.valueOf(ar.get('codeDV__c')), String.valueOf(ar.get('libelleDV__c'))));
            }
        }
        return options;
    } set; }
	/**
    * @description Initialisation des options Magasin
    */
    public List<SelectOption> optionsMag {get{
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));
        unlockMagasin = false;        
        if(magasinsMap.size() > 1) unlockMagasin = true;    
        if(codeDV !=null && codeDV != '') {
            for(AggregateResult ar : [select libelleMagasin__c, codeMagasin__c from Sectorisation__c WHERE codeDV__c=:codeDV GROUP BY libelleMagasin__c, codeMagasin__c ORDER BY libelleMagasin__c]){
                if (ar.get('codeMagasin__c') != null && ar.get('libelleMagasin__c') != null)
                    options.add(new SelectOption(String.valueOf(ar.get('codeMagasin__c')), String.valueOf(ar.get('libelleMagasin__c'))));
            }
        } else {
            for(String magMapCode : magasinsMap.keySet()){
                options.add(new SelectOption(String.valueOf(magMapCode), String.valueOf(magasinsMap.get(magMapCode))));
            }
            //codeMag = options[0].getValue();
        }
        return options;
    } set; }
	/**
    * @description Initialisation des listes de phone
    */
    public List<SelectOption> optionsLDP {get{
        optionsLDP = new List<SelectOption>();
        optionsLDP.add(new SelectOption('', ''));
        Datetime dateDebutFormate;
        Datetime dateFinFormate;
        List<ListePhoningVendeur__c> listeDePhones = new List<ListePhoningVendeur__c>();
        system.debug('dateDebutTemp : '+dateDebutTemp);
        system.debug('dateFinTemp : '+dateFinTemp);
        if(!String.isEmpty(dateDebutTemp)){
       		List<String> strDate = dateDebutTemp.split('-');
        	dateDebutFormate = DateTime.newInstance(Integer.valueOf(strDate[0]), Integer.valueOf(strDate[1]), Integer.valueOf(strDate[2]), 0, 0, 0);
        } else dateDebutFormate = DateTime.newInstance(1970, 1, 1, 0, 0, 0);
        if(!String.isEmpty(dateFinTemp)){
        	List<String> strDate = dateFinTemp.split('-');
        	dateFinFormate = DateTime.newInstance(Integer.valueOf(strDate[0]), Integer.valueOf(strDate[1]), Integer.valueOf(strDate[2]), 23, 59, 59);
    	} else dateFinFormate = Datetime.now().addYears(1);
    	listeDePhones = [SELECT Id, Name, DR_Filtre__c, DV_Filtre__c, magasin_Filtre__c, statut__c FROM ListePhoningVendeur__c WHERE CreatedDate >= :dateDebutFormate AND CreatedDate <= :dateFinFormate ORDER BY Name];
        for(ListePhoningVendeur__c ldp : listeDePhones){
            system.debug('ldp : '+ldp);
	        if (ldp.Id != null && ldp.Name != null && (ldp.DR_Filtre__c == codeRegion || String.isBlank(codeRegion)) && 
	           (ldp.DV_Filtre__c == codeDV || String.isBlank(codeDV)) && (ldp.magasin_Filtre__c == codeMag || String.isBlank(codeMag)) &&
	           (ldp.statut__c == listePhoning.statut__c || String.isBlank(listePhoning.statut__c)))
	                optionsLDP.add(new SelectOption(String.valueOf(ldp.Id), String.valueOf(ldp.Name)));
    	}
        return optionsLDP;
    } set; }    
	/**
    * @description Initialisation de la liste des vendeurs
    */
    public List<SelectOption> optionsVendeurs {get{
        optionsVendeurs = new List<SelectOption>();
        optionsVendeurs.add(new SelectOption('', ''));
        system.debug('optionsVendeurs : '+nomVendeur);
        List<User> vendeurs = new List<User>();
        if(String.isNotBlank(codeMag)) 
			vendeurs = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c FROM User WHERE CodeMagasin__c=:codeMag AND IsActive = true ORDER BY Name];
        else if(String.isNotBlank(codeDV)) 
			vendeurs = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c FROM User WHERE CodeDV__c=:codeDV AND IsActive = true ORDER BY Name];
        else if(String.isNotBlank(codeRegion)) 
			vendeurs = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c FROM User WHERE CodeDR__c=:codeRegion AND IsActive = true ORDER BY Name];
        for(User user : vendeurs){
	        if (user.Id != null && user.Name != null && (user.CodeDR__c == codeRegion || String.isBlank(codeRegion)) 
				&& (user.CodeDV__c == codeDV || String.isBlank(codeDV)) && (user.CodeMagasin__c == codeMag || String.isBlank(codeMag)))
	                optionsVendeurs.add(new SelectOption(String.valueOf(user.Id), String.valueOf(user.Name)));
    	}
        return optionsVendeurs;
    } set; }
		    
	/**
    * @description Initialisation du champ statut du critère des listes de phones
    */
	public ListePhoningVendeur__c listePhoning {get { return listePhoning;}set;}{
		listePhoning = new ListePhoningVendeur__c(statut__c = Constants.StatutLDPEnCours);
		List<ListePhoningVendeur__c> listesDePhonesExistantes = new List<ListePhoningVendeur__c>();
		listesDePhonesExistantes = [SELECT Id, statut__c FROM ListePhoningVendeur__c WHERE statut__c = :Constants.StatutLDPDebriefeePartiellement];
		if(!listesDePhonesExistantes.isEmpty())
			listePhoning.statut__c = Constants.StatutLDPDebriefeePartiellement;
	}
		
    /**
    * @description Constructeur
    * @return Ctrl_ConsultationListeDePhones 
    */
    public Ctrl_ConsultationListeDePhones() {
        userinfos = [SELECT Id, CodeDR__c, CodeDV__c, CodeMagasin__c, ProfileId FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1];
        // Récupération liste des magasins de l'utilisateur
        UserContext context = UserContext.getContext(UserInfo.getUserId());
        magasinsMap = context.getMagasins();
        
        // Récupération des paramètres de la carte
        googleMapsSettings = GoogleMapsSettings__c.getValues('cartographie');
        // Récupération paramètre global DQE
        licenceDQE = PropertiesUtils.getStringValue('dqe.adresse.licence', '');

        // Initialisation secteurs disponible pour l'utilisateur
        codeMagWithAtt = DAL_Cartographie.attsParentIds(magasinsMap.keySet());
        sectorNamesList = new List<String>();
        for (String code : magasinsMap.keySet()) {
            //if (codeMagWithAtt.contains(code))
                sectorNamesList.add (magasinsMap.get(code));
        }
        sectorNamesList.sort();

        // Initialisation sur le premier secteur de la liste si disponible
        if (!sectorNamesList.isEmpty() && sectorNamesList != null) {
            sectorName = sectorNamesList[0];
        } 
    }
    
    public String fieldParamDR {get; set;}
    public String fieldParamDV {get; set;}
    public String fieldParamMagasin {get; set;}
    public String fieldParamVendeur {get; set;}
    public String fieldParamDebut {get; set;}
    public String fieldParamFin {get; set;}
    public String fieldParamLDP {get; set;}
    /**
    * @description Mise à jour des champs de filtrage
    */
    public void updateFields(){   
        if(String.isNotBlank(fieldParamDR) && fieldParamDR != '*') 
			codeRegion = fieldParamDR;
        else if(String.isNotBlank(userinfos.CodeDR__c)) 
			codeRegion = userinfos.CodeDR__c;
        else 
			codeRegion = optionsRegion[0].getValue();
		codeDV = optionsDV[0].getValue();
        if(String.isNotBlank(fieldParamDV) && fieldParamDV != '*') 
			codeDV = fieldParamDV;
        else 
			codeDV =  userinfos.CodeDV__c;
        codeMag = optionsMag[0].getValue();
        if(String.isNotBlank(fieldParamMagasin) && fieldParamMagasin != '*') 
			codeMag = fieldParamMagasin;
        else 
			codeMag =  userinfos.CodeMagasin__c;
        nomVendeur = optionsVendeurs[0].getValue();
        if(String.isNotBlank(fieldParamVendeur) && fieldParamVendeur != '*') 
			nomVendeur = fieldParamVendeur;
        
        if(String.isNotBlank(fieldParamDebut) && fieldParamDebut != '*' && fieldParamDebut != 'Invalid date'){ 
        	List<String> strDateDebut = fieldParamDebut.split('/');
        	dateDebut = fieldParamDebut;
        	dateDebutTemp = fieldParamDebut;
        } else {
        	dateDebut = '';
        	dateDebutTemp = '';
        }
        if(String.isNotBlank(fieldParamFin) && fieldParamFin != '*' && fieldParamFin != 'Invalid date'){
        	List<String> strDateFin = fieldParamFin.split('/');
        	dateFin = fieldParamFin;
        	dateFinTemp = fieldParamFin;
        } else {
        	dateFin = '';
        	dateFinTemp = '';
        }
        nomLDP = optionsLDP[0].getValue();
        if(String.isNotBlank(fieldParamLDP) && fieldParamLDP != '*') 
			nomLDP = fieldParamLDP;
    }

    /**
    * @description Fonction appelée lors l'ouverture de la page pour mettre à jour les statistiques
    */
    public void insertUserStats() {
        Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurConsultationListeDePhones__c');
    }

    /**
    * @description REMOTEACTION - Récupération des coordonnées d'une adresse via DQE
    * @param idVoie Id de la rue renvoyée par DQE Adresse
    * @param numero Numéro de la rue renvoyé par DQE Adresse
    * @param codePays Trigramme du pays renvoyé par DQE Adresse
    * @return Utils_DQE.GeocodeResultType Objet GeocodeResultType contenant les informations de l'adresse et sa géolocalisation
    */
    @RemoteAction
    public static Utils_DQE.GeocodeResultType DQELongLat(String idVoie, String numero, String codePays) {
        try {
            return Utils_DQE.DQELongLat(idVoie, numero, codePays);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description REMOTEACTION - Mise à jour d'un phoning vendeur
    * @param phoneId Id de l'enregistrement à mettre à jour
    * @param phoneAppel Appel effectué
    * @param phoneArgu Argumentation effectuée
    * @param dateRDV Date du RDV suite au phoning
    * @param timeStartRDV Heure du RDV suite au phoning
    * @param dureeRDV Durée du RDV suite au phoning
    * @param action Action sur l'enregistrement
    * @return PhoningVendeur__c Enregistrement de phoning à jour
    */
    @RemoteAction 
    public static PhoningVendeur__c updatePhone(String phoneId, Boolean phoneAppel, Boolean phoneArgu, String dateRDV, String timeStartRDV, String dureeRDV, String action) {
		system.debug('### DEBUT updatePhone');
		PhoningVendeur__c phone = new PhoningVendeur__c();
        try{
        	List<PhoningVendeur__c> phoneList = [SELECT Id, appelEffectue__c, argumentationEffectuee__c, dateHeureRDV__c, dureeRDV__c, debriefe__c, projet__c, RDV__c, isProcessed__c,
			        	compte__c, compte__r.Id, compte__r.dateDernierPhoning__c, compte__r.dateDernierAppelSortantKparK__c, compte__r.nbPhonings__c,
			        	compte__r.nbAppelsSortants__c
			        	FROM PhoningVendeur__c WHERE Id = :phoneId LIMIT 1];
            
			if(!phoneList.isEmpty()) {
				phone = phoneList[0];
				List<String> strDate = new List<String>(); List<String> strTimeStart = new List<String>(); Datetime datetimeRDV; Integer dureeIntRDV;
			
				if(String.isNotBlank(dateRDV) && String.isNotBlank(timeStartRDV) && String.isNotBlank(dureeRDV)){
					strDate = dateRDV.split('-');
					strTimeStart = timeStartRDV.split(':');
	            
					datetimeRDV = Datetime.newInstance(Integer.valueOf(strDate[0]), Integer.valueOf(strDate[1]), Integer.valueOf(strDate[2]), Integer.valueOf(strTimeStart[0]), Integer.valueOf(strTimeStart[1]), 0);
					dureeIntRDV = Integer.valueOf(dureeRDV);
				} else if(String.isNotBlank(dateRDV) && String.isNotBlank(timeStartRDV)) {
					strDate = dateRDV.split('-');
					datetimeRDV = Datetime.newInstance(Integer.valueOf(strDate[0]), Integer.valueOf(strDate[1]), Integer.valueOf(strDate[2]), 0, 0, 0);
				}

				if(action == 'update'){
					if(!phone.appelEffectue__c && phoneAppel){
	            		phone.compte__r.dateDernierPhoning__c = Datetime.now();
	            		if(phone.compte__r.nbPhonings__c == null) phone.compte__r.nbPhonings__c = 0;
	            		if(phone.compte__r.nbAppelsSortants__c == null) phone.compte__r.nbAppelsSortants__c = 0;
	            		phone.compte__r.nbPhonings__c = phone.compte__r.nbPhonings__c+1;
	            		update phone.compte__r;
					} else if(phone.appelEffectue__c && !phoneAppel){
						if(phone.compte__r.nbPhonings__c != null && phone.compte__r.nbPhonings__c != 0) phone.compte__r.nbPhonings__c = phone.compte__r.nbPhonings__c-1;
	            		update phone.compte__r;
					}

					phone.appelEffectue__c = phoneAppel;
					phone.argumentationEffectuee__c = phoneArgu;
					phone.dateHeureRDV__c = datetimeRDV;
					phone.dureeRDV__c = dureeIntRDV;
					if(phone.isProcessed__c && (phoneAppel || phoneArgu || String.isNotBlank(timeStartRDV))) phone.isProcessed__c = false;

					// Mise à jour du phone
					update phone;
	            
					phone = [SELECT Id, appelEffectue__c, argumentationEffectuee__c, dateHeureRDV__c, dureeRDV__c, debriefe__c, projet__c, RDV__c,
			        		compte__c, compte__r.Id, compte__r.dateDernierPhoning__c, compte__r.dateDernierAppelSortantKparK__c, compte__r.nbPhonings__c,
			        		compte__r.nbAppelsSortants__c
			        		FROM PhoningVendeur__c WHERE Id = :phoneId LIMIT 1];
				}  
			}          
			system.debug('### FIN updatePhone');
            // Retour des champs
            return phone;
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Recherche des phones selon les critères de filtrage
    * @param argument Arguments de recherche
    * @return List<PhoningVendeur__c> Liste des phones selon la recherche
    */
    @RemoteAction 
    public static List<PhoningVendeur__c> recuperePhones(Map<String,String> argument) {
		system.debug('### DEBUT recuperePhones');
        try{
        	List<PhoningVendeur__c> listPhoning = new List<PhoningVendeur__c>();
        	List<String> strDate = new List<String>();
            Date dateCondition;
        	String soqlQuery = ' ';
        	String historiqueParametres = ' ';
            String conditions = ' ';
            system.debug('## Argument : '+ argument);
        	
        	// Construction requêtre sur compte
            soqlQuery = 'SELECT Id, Name, liste__c, compte__c, appelEffectue__c,argumentationEffectuee__c, dateHeureRDV__c, dureeRDV__c, commentaires__c, projet__c, debriefe__c, RDV__c, liste__r.statut__c,';
            soqlQuery+= 'compte__r.Id, compte__r.Name, compte__r.Type, compte__r.telephoneDomicile__c, compte__r.telephoneMobile__c, compte__r.autreTelephone__c, compte__r.optinTelephoneDomicileKparK__c, compte__r.optinTelephoneMobileKparK__c, ';
            soqlQuery+= 'compte__r.nbPhonings__c, compte__r.nbAppelsSortants__c, compte__r.dateDernierAppelSortantKparK__c, compte__r.rue__c, compte__r.codePostal__c, compte__r.ville__c, compte__r.complementAdresse__c ';
            soqlQuery+= ', compte__r.y__c, compte__r.x__c, compte__r.profession__c ';
            soqlQuery+= ' FROM PhoningVendeur__c WHERE liste__r.DR_Filtre__c =\''+ argument.get('dr') +'\'';
            
            if(argument.get('dv') != null && argument.get('dv') != '' && (argument.get('magasin') == null || argument.get('magasin') == '')){
                conditions+= ' AND liste__r.DV_Filtre__c =\''+ argument.get('dv') +'\'';
                historiqueParametres += 'liste__r.DV_Filtre__c='+argument.get('dv')+';';
            }
            if(argument.get('magasin') != null && argument.get('magasin') != ''){
                conditions+= ' AND liste__r.magasin_Filtre__c =\''+ argument.get('magasin') +'\'';
                historiqueParametres += 'liste__r.magasin_Filtre__c='+argument.get('magasin')+';';
            }
            if(argument.get('vendeur') != null && argument.get('vendeur') != '' && argument.get('vendeur') != '000000000000000'){
                conditions+= ' AND liste__r.user__c =\''+ argument.get('vendeur') +'\'';
                historiqueParametres += 'liste__r.user__c='+argument.get('vendeur')+';';
            }
            if(argument.get('statut') != null && argument.get('statut') != ''){
                conditions+= ' AND liste__r.statut__c =\''+ argument.get('statut') +'\'';
                historiqueParametres += 'liste__r.statut__c='+argument.get('statut')+';';
            }
            if(argument.get('dateDebut') != null && argument.get('dateDebut') != ''){
                String[] myDateOnly2 = (argument.get('dateDebut')).split(' ');
                strDate = myDateOnly2[0].split('-');
                dateCondition = Date.newInstance(Integer.valueOf(strDate[0]), Integer.valueOf(strDate[1]), Integer.valueOf(strDate[2]));
                conditions += ' AND CreatedDate >= ' + dateCondition.year();
                if(dateCondition.month() < 10) conditions+= '-0' + dateCondition.month(); else conditions+= '-' + dateCondition.month();
                if(dateCondition.day() < 10) conditions+= '-0' + dateCondition.day(); else conditions+= '-' + dateCondition.day();
                conditions += 'T00:00:00z';
                historiqueParametres += 'CreatedDateMin='+argument.get('dateDebut')+';';
            }
            if(argument.get('dateFin') != null && argument.get('dateFin') != ''){
                String[] myDateOnly3 = (argument.get('dateFin')).split(' ');
                strDate = myDateOnly3[0].split('-');
                dateCondition = Date.newInstance(Integer.valueOf(strDate[0]), Integer.valueOf(strDate[1]), Integer.valueOf(strDate[2]));
                conditions += ' AND createdDate <= ' + dateCondition.year();
                if(dateCondition.month() < 10) conditions+= '-0' + dateCondition.month(); else conditions+= '-' + dateCondition.month();
                if(dateCondition.day() < 10) conditions+= '-0' + dateCondition.day(); else conditions+= '-' + dateCondition.day();
                conditions += 'T23:59:59z';
                historiqueParametres += 'CreatedDateMax='+argument.get('dateFin')+';';
            }
            if(argument.get('ldp') != null && argument.get('ldp') != ''){
                conditions+= ' AND liste__r.Id =\''+ argument.get('ldp') +'\'';
                historiqueParametres += 'liste__r.Id='+argument.get('ldp')+';';
            }
            
            historiqueParametres = historiqueParametres.substring(0, (historiqueParametres.length()-1));
            soqlQuery+= conditions + ' LIMIT 1000';
            system.debug('## SOQL ==> ' + soqlQuery);

            // Exécution requête
            listPhoning = database.query(soqlQuery);
        	
			system.debug('### FIN recuperePhones');
            // Retour des résultats
            return listPhoning;
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description REMOTEACTION - Recherche les comptes à afficher sur la carte, avec coordonnées
    * @param codeMagasin Code du magasin
    * @param compteIds Liste des IDs des comptes
    * @return List<Utils_InnerClasses.CustomCompte> Liste de l'objet stockant les informations des comptes à afficher
    */
    @RemoteAction 
    public static List<Utils_InnerClasses.CustomCompte> recuperePhonesAvecCoordonnees(String codeMagasin, List<String> compteIds) {
		system.debug('### DEBUT recuperePhonesAvecCoordonnees');
        try{
        	List<Utils_InnerClasses.CustomCompte> objectToReturn = new List<Utils_InnerClasses.CustomCompte>();	
        	
        	// Récupération des événements du type rdv d'aujourd'hui et des prochains jours        
            List<PhoningVendeur__c> phonesList = [SELECT Id, compte__c, debriefe__c
		                              FROM PhoningVendeur__c 
		                              WHERE compte__c IN :compteIds];
        		    
		    // Récupération des comptes liés aux événements
        	Map<String, Account> comptesMap = new Map<String, Account>([SELECT Id, Type, Name, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, 
																	codePostal__c, OwnerId, Owner.Name, email__c,autreTelephone__c,telephoneDomicile__c, 
																	telephoneMobile__c,optinTelephoneDomicileKparK__c,optinTelephoneMobileKparK__c,nbPhonings__c,nbAppelsSortants__c, 
																	dateDernierAppelSortantKparK__c,AccountNumber, x__c, y__c, profession__c 
							                                 FROM Account
							                                 WHERE Id IN :compteIds LIMIT :Constants.MAP_DOT_LIMITS]);
            if(!comptesMap.values().isEmpty()) {
            	for(PhoningVendeur__c pv : phonesList) {
                    Account compte = comptesMap.get(pv.compte__c);
            		if(null != compte) objectToReturn.add(new Utils_InnerClasses.CustomCompte(pv, compte));
            	}
            }
			system.debug('### FIN recuperePhonesAvecCoordonnees');
            return objectToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Récupération des devis vendus pour affichage du camembert
    * @param comptesId Code du magasin
    * @return Map<String, Decimal> Objet contenant le CA des devis des comptes selon leur statut
    */
    @RemoteAction 
    public static Map<String, Decimal> getPieChartInfos(List<String> comptesId) {
		system.debug('### DEBUT getPieChartInfos');
        Map<String, Decimal> caDevisParStatut = new Map<String, Decimal>();
        try{
        	if(comptesId.size() == 0) caDevisParStatut = null;
        	else {
        		List<Quote> devisDesComptes = new List<Quote>();
        		//devisDesComptes = [SELECT Id, Status FROM Quote WHERE Opportunity.Account.Id IN :comptesId];
        		devisDesComptes = [SELECT Id, Status, Total_TTC_devis__c FROM Quote 
									WHERE OpportunityId IN (SELECT projet__c FROM PhoningVendeur__c WHERE compte__c IN :comptesId)];
        		
        		Decimal caDevisTransmis = 0;
        		Decimal caDevisVenduAttente = 0;
        		Decimal caDevisVenduEnregistre = 0;
        		Decimal caDevisVenduIncontournable = 0;
        		for(Quote quote : devisDesComptes)
                {
                    if(quote.Total_TTC_devis__c != null) {
                        if(quote.Status == Constants.StatutDevisTransmis) 					caDevisTransmis += quote.Total_TTC_devis__c/1000;
                        else if(quote.Status == Constants.StatutDevisVenduAttente) 			caDevisVenduAttente+= quote.Total_TTC_devis__c/1000;
                        else if(quote.Status == Constants.StatutDevisVenduEnregistre) 		caDevisVenduEnregistre+= quote.Total_TTC_devis__c/1000;
                        else if(quote.Status == Constants.StatutDevisVenduIncontournable) 	caDevisVenduIncontournable+= quote.Total_TTC_devis__c/1000;
                    }
        		}
				caDevisParStatut.put('transmis', caDevisTransmis);
				caDevisParStatut.put('venduAttente', caDevisVenduAttente);
				caDevisParStatut.put('venduEnregistre', caDevisVenduEnregistre);
				caDevisParStatut.put('venduIncontournable', caDevisVenduIncontournable);
				        		
        		system.debug('## CA Devis : '+caDevisParStatut);
        	}
			system.debug('### FIN getPieChartInfos');
        	return caDevisParStatut;
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Récupération du phone selectionné
    * @param phoneId Id du phone
    * @return PhoningVendeur__c Phone contenant l'id envoyé
    */
    @RemoteAction 
    public static ListePhoningVendeur__c getPhoneInfos(String phoneId) {
        system.debug('### DEBUT getPhoneInfos');
        ListePhoningVendeur__c phoneSelected = new ListePhoningVendeur__c();
        system.debug('## phoneId : '+phoneId);
        try{
            if(phoneId == null) phoneSelected = null;
            else {
                List<ListePhoningVendeur__c> phoneList = new List<ListePhoningVendeur__c>();
                phoneList = [SELECT Id, statut__c FROM ListePhoningVendeur__c WHERE Id = :phoneId LIMIT 1];
                
                if(!phoneList.isEmpty()) 
                    phoneSelected = phoneList[0];
              
                system.debug('## Phone : '+phoneSelected);
            }
            system.debug('### FIN getPhoneInfos');
            return phoneSelected;
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Récupération des informations du secteur (nom, codeMagasin, coordonnées géographique)
    * @param sectorName Nom du secteur (magasin)
    * @return Sector Objet contenant le nom, codeMagasin magasin et les points cartographique (WGS84) du secteur
    */
    @RemoteAction
    public static Utils_Cartographie.Sector getSectorCoord(String sectorName) {
        try {
            return Utils_Cartographie.getSectorCoord(sectorName);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Annulation d'une liste de phones
    */
    public PageReference cancelListeDePhone(){
		system.debug('### DEBUT cancelListeDePhone');
    	ListePhoningVendeur__c listeToCancel = new ListePhoningVendeur__c();
    	List<PhoningVendeur__c> phonesToCancel = new List<PhoningVendeur__c>();
    	try{
    		if(motifAnnulation != null && nomLDP != null){
    			// récupération de la liste, des phones, et des comptes concernés.
    			listeToCancel = [SELECT Id, dateAnnulation__c, motifAnnulation__c FROM ListePhoningVendeur__c WHERE Id = :nomLDP];
    			phonesToCancel = [SELECT Id, compte__c, compte__r.Id FROM PhoningVendeur__c WHERE liste__c = :nomLDP];
    			
    			// Mise à jour de la liste de phones
    			listeToCancel.dateAnnulation__c = System.now();
    			listeToCancel.motifAnnulation__c = motifAnnulation;
    			update listeToCancel;

    			// Mise à jour des phones
    			for(PhoningVendeur__c ph : phonesToCancel){
    				ph.isProcessed__c = false;
    			}
    			update phonesToCancel;
    		}
			system.debug('### FIN cancelListeDePhone');
			return null;
    	} catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Nouvelle recherche
    */
    public PageReference nouvelleRecherche(){   
        PageReference listePhone = Page.VF_ListeDePhones;
        string retURL = ApexPages.currentPage().getUrl();
        listePhone.getParameters().put('DR' , codeRegion);
        listePhone.getParameters().put('DV' , codeDV);
        listePhone.getParameters().put('magasin' , codeMag);
        listePhone.getParameters().put('proprietaire' , nomVendeur);
        listePhone.getParameters().put('retURL' , retURL);
        listePhone.setRedirect(false);
        return listePhone;
    }
}