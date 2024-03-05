//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Prospection
//-- Modifié par : SOPRA - Julien MORINEAU
//-- Modifié le  : 30/06/2014
//-- Version     : 1.1
//-- * Corrections sur la date et la sauvegarde
//-- --------------------------------------------------------------------------------- --
global with sharing class Ctrl_Prospection {
	public List<Import__c> prospects { get; set; }
	public String Ville { get; set; }
	public String Rue { get; set; }
	public String cp { get; set; }
	public Decimal Lat { get; set; }
	public Decimal Lon { get; set; }
	public String Nom { get; set; }
	public String Telephone { get; set; }

	public String Email { get; set; }
	public String Observation { get; set; }
	public String PId { get; set; }
	private String ProspectId;
	public String url { get; set; }
	public Date DateProspection { get; set; }
	public Date DateProspection2 { get; set; }
	public Map<String,String> MapId { get; set; }
	public Map<String,Resultat> Resultats  { get; set; }

	public String cp2{get; set;}
	public String ville2{get; set;}
	public String rue2{get; set;}
	public String pays2{get; set;}
	public String departement2{get; set;}

	// Google
	public String googleKeyAPI {get; set;}
	public Double adresse_latitude {get; set;}
	public Double adresse_longitude {get; set;}
	public GoogleMapsSettings__c googleMapsSettings { get; private set; }

	// Fonction appelé lors l'ouverture de la page
	public void insertUserStats() {
		insertUserStatsFuture(Userinfo.getUserId());
	}

	// Incrémentation statistique utilisateur
	@future
	public static void insertUserStatsFuture(Id userId) {
		List<UserStats__c> userStats = new List<UserStats__c>();
		UserStats__c stats;
		List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, compteurProspection__c
											FROM UserStats__c
											WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

		if (statsList.isEmpty()) {
			stats = new UserStats__c(name                   = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
									user__c                 = UserInfo.getUserId(),
									date__c                 = System.today(),
									compteurProspection__c  = 0);
		} else
			stats = statsList[0];

		system.debug('stats.compteurProspection__c : ' + stats.compteurProspection__c);
		stats.compteurProspection__c = stats.compteurProspection__c + 1;
		system.debug('stats.compteurProspection__c : ' + stats.compteurProspection__c);
		userStats.add(stats);

		if (!userStats.isEmpty())
			upsert userStats;
	}

		public Ctrl_Prospection(ApexPages.StandardController stdController) {

				//ProspectId = controller.getId();
				User user = UserContext.getContext().getUser();

				if(DateProspection != null){
						prospects = [SELECT rueCompte__c, villeCompte__c, nomCompte__c, telephoneDomicileCompte__c,
																emailCompte__c, observationsComplementaires__c, codePostalCompte__c
														FROM Import__c
														WHERE source__c = 'PORTE A PORTE VENDEUR'
														AND ((LastModifiedDate <= :DateProspection) and (LastModifiedDate >= :DateProspection))];
				}
		}

		//Récupération des informations que l'on va afficher en bas
		@RemoteAction
		public static List<Map<Integer, String>> getProspection(String DateP) {
				try{
						Map<Integer, String> lVille = new Map<Integer, String>();
						Map<Integer, String> lRue = new Map<Integer, String>();
						Map<Integer, String> lNom = new Map<Integer, String>();
						Map<Integer, String> lCp = new Map<Integer, String>();
						Map<Integer, String> lTelephone = new Map<Integer, String>();
						Map<Integer, String> lEmail = new Map<Integer, String>();
						Map<Integer, String> lObservation = new Map<Integer, String>();
						Map<Integer, String> lId = new Map<Integer, String>();
						List<Map<Integer, String>> Triple = new List<Map<Integer, String>>();
						List<Import__c> prospects = new List<Import__c>();

						// Réecriture de la variable de date
						String[] myDateOnly = DateP.split(' ');
						String[] strDate = myDateOnly[0].split('-');
						Integer myIntDate = integer.valueOf(strDate[2]);
						Integer myIntMonth = integer.valueOf(strDate[1]);
						Integer myIntYear = integer.valueOf(strDate[0]);
						Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
						//Date dmin = Date.newInstance(myIntYear, myIntMonth, myIntDate);

						if(DateP != null){
								prospects = [SELECT id, rueCompte__c, villeCompte__c, nomCompte__c, telephoneDomicileCompte__c,
																		emailCompte__c, observationsComplementaires__c, codePostalCompte__c,
																		Localisation__Latitude__s, Localisation__Longitude__s, dateDeProspection__c
																FROM Import__c
																WHERE source__c = 'PORTE A PORTE VENDEUR' AND ( dateDeProspection__c = :d)];
						}


						integer i=0;
						if(!prospects.isEmpty()){
								for(Import__c imp : prospects){
										system.debug(imp.dateDeProspection__c);
										if(imp.rueCompte__c != null) lRue.put(i, imp.rueCompte__c); else lRue.put(i, ' ');
										if(imp.villeCompte__c != null) lVille.put(i, imp.villeCompte__c);
										if(imp.nomCompte__c != null) lNom.put(i, imp.nomCompte__c);
										if(imp.codePostalCompte__c != null) lCp.put(i, imp.codePostalCompte__c);
										if(imp.telephoneDomicileCompte__c != null) lTelephone.put(i, imp.telephoneDomicileCompte__c);
										if(imp.emailCompte__c != null) lEmail.put(i, imp.emailCompte__c);
										if(imp.observationsComplementaires__c != null) lObservation.put(i, imp.observationsComplementaires__c);
										if(imp.id != null) lId.put(i, imp.id );
										i++;
								}

								Triple.add(lRue);
								Triple.add(lVille);
								Triple.add(lNom);
								Triple.add(lCp);
								Triple.add(lTelephone);
								Triple.add(lEmail);
								Triple.add(lObservation);
								Triple.add(lId);
						}

						return Triple;
				} catch(exception e) {
						system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
						throw e;
				}
		}

		@RemoteAction
		public static Map<String,String> updateProspection(Map<String,String> argument) {
				try{
						String tempDate = argument.get('dateProspection');
						String[] myDateOnly = tempDate.split(' ');
						String[] strDate = myDateOnly[0].split('-');
						Integer myIntDate = integer.valueOf(strDate[2]);
						Integer myIntMonth = integer.valueOf(strDate[1]);
						Integer myIntYear = integer.valueOf(strDate[0]);
						Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);

						Import__c upd = new Import__c();
						List<Import__c> prospects = new List<Import__c>();

						upd.rueCompte__c = argument.get('rue');
						upd.villeCompte__c = argument.get('ville');
						upd.nomCompte__c =argument.get('nom');
						upd.codePostalCompte__c = argument.get('cp');
						upd.telephoneDomicileCompte__c = argument.get('telephone');
						upd.emailCompte__c = argument.get('email');
						upd.observationsComplementaires__c = argument.get('observation');
						upd.id = argument.get('pid');

						system.debug(upd.rueCompte__c);
						system.debug(upd.villeCompte__c);
						system.debug(upd.nomCompte__c);
						system.debug(upd.codePostalCompte__c);
						system.debug(upd.telephoneDomicileCompte__c);
						system.debug(upd.emailCompte__c);
						system.debug(upd.observationsComplementaires__c);
						system.debug(upd.id);

						if(d  != null){
								prospects = [SELECT id, rueCompte__c, villeCompte__c, nomCompte__c, telephoneDomicileCompte__c,
																		emailCompte__c, observationsComplementaires__c, codePostalCompte__c,
																		Localisation__Latitude__s, Localisation__Longitude__s
																FROM Import__c
																WHERE source__c = 'PORTE A PORTE VENDEUR'
																AND ( dateDeProspection__c = :d)
																AND ( id =  :upd.id)];

								system.debug(prospects);

								for (Import__c imp : prospects){
										imp.rueCompte__c = upd.rueCompte__c ;
										imp.villeCompte__c = upd.villeCompte__c ;
										imp.nomCompte__c = upd.nomCompte__c;
										imp.codePostalCompte__c = upd.codePostalCompte__c;
										imp.telephoneDomicileCompte__c = upd.telephoneDomicileCompte__c ;
										imp.emailCompte__c = upd.emailCompte__c ;
										imp.observationsComplementaires__c = upd.observationsComplementaires__c ;
										system.debug(imp.rueCompte__c);
										system.debug(imp.observationsComplementaires__c);
								}
								update prospects;
						}
						return argument;
				} catch(exception e) {
						system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
						throw e;
				}
		}

		@RemoteAction
		public static Map<String,String> deleteProspection(Map<String,String> argument) {
				try{
						String tempDate = argument.get('dateProspection');
						String[] myDateOnly = tempDate.split(' ');
						String[] strDate = myDateOnly[0].split('-');
						Integer myIntDate = integer.valueOf(strDate[2]);
						Integer myIntMonth = integer.valueOf(strDate[1]);
						Integer myIntYear = integer.valueOf(strDate[0]);
						Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);

						Import__c del = new Import__c();
						List<Import__c> prospects = new List<Import__c>();

						del.rueCompte__c = argument.get('rue');
						del.villeCompte__c = argument.get('ville');
						del.nomCompte__c =argument.get('nom');
						del.codePostalCompte__c = argument.get('cp');
						del.telephoneDomicileCompte__c = argument.get('telephone');
						del.emailCompte__c = argument.get('email');
						del.observationsComplementaires__c = argument.get('observation');
						del.id = argument.get('pid');

						if(d  != null){
								prospects = [Select id, rueCompte__c, villeCompte__c, nomCompte__c, telephoneDomicileCompte__c,
																		emailCompte__c, observationsComplementaires__c, codePostalCompte__c,
																		Localisation__Latitude__s, Localisation__Longitude__s
																FROM Import__c
																WHERE source__c = 'PORTE A PORTE VENDEUR'
																AND ( dateDeProspection__c = :d)
																AND ( id =  :del.id)];

								delete prospects;
						}
						return argument;
				} catch(exception e) {
						system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
						throw e;
				}
		}


		//Récupération des informations du compte saisie dans le champ prospect/client
		@RemoteAction
		public static Resultat insertProspection(Map<String,String> argument) {
				try{
						Resultat res = new Resultat();
						Map<String,Resultat> MapId = new Map<String,Resultat>();

						system.debug(argument);
						String tempDate = argument.get('dateProspection');
						system.debug(tempDate);
						String[] myDateOnly = tempDate.split(' ');
						String[] strDate = myDateOnly[0].split('-');
						Integer myIntDate = integer.valueOf(strDate[2]);
						Integer myIntMonth = integer.valueOf(strDate[1]);
						Integer myIntYear = integer.valueOf(strDate[0]);
						Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);

						Import__c imp = new Import__c();
						imp.rueCompte__c = argument.get('rue');
						imp.villeCompte__c = argument.get('ville');
						imp.nomCompte__c = argument.get('nom');
						imp.codePostalCompte__c = argument.get('cp');
						imp.telephoneDomicileCompte__c = argument.get('telephone');
						imp.emailCompte__c = argument.get('email');
						imp.integrable__c = false;
						imp.observationsComplementaires__c = argument.get('observation');
						imp.dateDeProspection__c = d;
						imp.civiliteCompte__c = 'M.';
						imp.integrable__c = true;
						imp.source__c = 'PORTE A PORTE VENDEUR';
						res.Prospection = imp;
						//imp.Localisation__c = ;
						insert imp;
						return res;

				} catch(exception e) {
						system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
						throw e;
				}
		}

		//stockage de résultat.
		public class Resultat {
				public String idProspection {get;set;}
				public Import__c Prospection { get; set; }
				public String Nom { get; set;}
				public String Rue {get; set;}
				public String Ville {get; set;}
				public String Cp {get; set;}
				public String Telephone {get; set;}
				public String Email {get; set;}
				public String Observation {get; set;}
				public String PId {get; set;}
				public Date DateProspection { get; set; }

				public Resultat () {
				}
		}
}