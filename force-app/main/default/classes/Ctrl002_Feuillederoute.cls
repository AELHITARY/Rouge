//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl002_Feuillederoute
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/08/2018
//-- Version     : 1.3
//-- * Ajout des RDV
//-- --------------------------------------------------------------------------------- --
public with sharing class Ctrl002_Feuillederoute {
	public String layers   { get { return params.get ('layers');   } }
	public map<String, Boolean> isShow { get; private set; }
	public User actualUser { get; set; }
	public Boolean isShowAll { get; private set; }
	{
		isShowAll = false;
		isShow = new map<String, Boolean> { 'ChantierAvecContrats' => false, 'ChantierSansContrats' => false, 'PoseDuJour' => false, 'PoseDeDemain' => false, 'SAV' => false, 
											'MetrageDuJour' => false, 'MetrageDeDemain' => false, 'Intervention_SAVDuJour' => false, 'Intervention_SAVDeDemain' => false, 
											'R1DuJour' => false, 'R2DuJour' => false, 'RPlusDuJour' => false, 'ProspectionsDuJour' => false };
	}

	public map<string, string> params { get { return ApexPages.currentPage ().getParameters (); } }

	public Decimal latitude_min   { get { return Decimal.valueOf (params.get ('x_left')); } }
	public Decimal latitude_max  { get { return Decimal.valueOf (params.get ('x_right')); } }
	public Decimal longitude_max    { get { return Decimal.valueOf (params.get ('y_top')); } }
	public Decimal longitude_min { get { return Decimal.valueOf (params.get ('y_bottom')); } }
	public String codeMagasin   { get { return params.get ('sector');   } }
	
    /**
    * @description Constructeur
    * @return Ctrl002_Feuillederoute 
    */
	public Ctrl002_Feuillederoute () {
		if (null == layers || 0 == layers.trim ().length ())
			isShowAll = true;
		else
			for (String k : layers.split (','))
				isShow.put (k, true);
		System.debug('##### isShow'+isShow);

		actualUser = [SELECT Id, Name, CodeDR__c, CodeDV__c, CodeMagasin__c, libelleMagasin__c, LastLoginDate, UserRoleId, UserRole.Name, ProfileId, profile.Name, IsActive
                        FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = true];
	}

    /**
    * @description Fonction appelée lors l'ouverture de la page pour incrémentation du champ compteurFeuilleRoute__c
    */
	public void insertUserStats() {
		Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurFeuilleRoute__c');
	}

	public String getChantiersAvecContratsJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratChantierFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, true)));
	}

	public String getChantiersSansContratsJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratChantierFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, false)));
	}

	public String getPoseDuJourJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratRDVbyTypeFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, 'Installation', system.today())));
	}

	public String getPoseDuDemainJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratRDVbyTypeFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, 'Installation', system.today()+1)));
	}

	public String getSAVJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratSAVFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min)));
	}

	public String getMetrageDuJourJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratRDVbyTypeFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, 'Métrage', system.today())));
	}

	public String getMetrageDeDemainJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratRDVbyTypeFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, 'Métrage', system.today()+1)));
	}

	public String getInterventionSAVDuJourJSON () {
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratRDVbyTypeFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, 'Intervention SAV', system.today())));
	}

	public String getInterventionSAVDeDemainJSON () { 
		return JSON.serialize (Utils_Cartographie.newContratFDRList (DAL_Feuillederoute.getContratRDVbyTypeFDRList (codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, 'Intervention SAV', system.today()+1)));
	}
	
	public String getR1DuJourJSON () {
		return JSON.serialize (Utils_Cartographie.newChantierFDRList(DAL_Feuillederoute.getRDVTodayList(codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, Constants.EVENT_TYPE_R1).values(), Constants.EVENT_TYPE_R1));
	}
	
	public String getR2DuJourJSON () {
		return JSON.serialize (Utils_Cartographie.newChantierFDRList(DAL_Feuillederoute.getRDVTodayList(codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, Constants.EVENT_TYPE_R2).values(), Constants.EVENT_TYPE_R2));
	}
	
	public String getRPlusDuJourJSON () {
		return JSON.serialize (Utils_Cartographie.newChantierFDRList(DAL_Feuillederoute.getRDVTodayList(codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, Constants.EVENT_TYPE_RP).values(), Constants.EVENT_TYPE_RP));
	}
	
	public String getProspectionDuJourJSON () {
		return JSON.serialize (DAL_Cartographie.getRDVProspectionList(codeMagasin, latitude_min, longitude_max, latitude_max, longitude_min, system.today(), true, actualUser.Id, actualUser.Profile.Name));
	}
}