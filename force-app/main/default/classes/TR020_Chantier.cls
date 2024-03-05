//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Chantier
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/08/2022
//-- Version     : 1.8
//-- * 1.8 : Alimentation des entités
//-- * 1.71 : Correctif des sectorisations si existe pas
//-- * 1.72 : Correctif ligne 669
//-- * 1.73 : Déplacement de la fonction getSectorisation dans la classe SectorisationUtils
//-- --------------------------------------------------------------------------------- --
public class TR020_Chantier {
    private static final String ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

	/***** A - Validation rules *****/
  	public static void applyValidationRules(UserContext userContext) {
    	if (!Trigger.isExecuting) {
    	  	return;
    	}
  	}

  	/***** B - Update rules *****/
  	public static void applyUpdateRules(UserContext userContext) {
    	if (!Trigger.isExecuting) {
      		return;
    	}
    	if (Trigger.isInsert) {
      		initIndicators(userContext);
    	}
    	applyDataUpdateRules(userContext);  
  	}
	
  	private static void initIndicators(UserContext userContext) {
    	for (Chantier__c chantier : (List<Chantier__c>)Trigger.new) {
			chantier.civiliteProprietaires__c            = null;
			chantier.nomProprietaires__c                 = null;
			chantier.prenomProprietaires__c              = null;
			chantier.rueProprietaires__c                 = null;
			chantier.codePostalProprietaires__c          = null;
			chantier.villeProprietaires__c               = null;
			chantier.departementProprietaires__c         = null;
			chantier.paysProprietaires__c                = null;
			chantier.telephoneDomicileProprietaires__c   = null;
			chantier.telephoneMobileProprietaires__c     = null;
			chantier.telephoneProprietaires__c           = null;
			chantier.emailProprietaires__c               = null;
			chantier.civiliteLocataires__c               = null;

			chantier.nomLocataires__c                    = null;
			chantier.prenomLocataires__c                 = null;
			chantier.rueLocataires__c                    = null;
			chantier.codePostalLocataires__c             = null;
			chantier.villeLocataires__c                  = null;
			chantier.departementLocataires__c            = null;
			chantier.paysLocataires__c                   = null;
			chantier.telephoneDomicileLocataires__c      = null;
			chantier.telephoneMobileLocataires__c        = null;
			chantier.telephoneLocataires__c              = null;
			chantier.emailLocataires__c                  = null;

			chantier.civiliteOccupants__c                = null;
			chantier.nomOccupants__c                     = null;
			chantier.prenomOccupants__c                  = null;
			chantier.rueOccupants__c                     = null;
			chantier.codePostalOccupants__c              = null;
			chantier.villeOccupants__c                   = null;
			chantier.departementOccupants__c             = null;
			chantier.paysOccupants__c                    = null;
			chantier.telephoneDomicileOccupants__c       = null;
			chantier.telephoneMobileOccupants__c         = null;
			chantier.telephoneOccupants__c               = null;
			chantier.emailOccupants__c                   = null;

			chantier.datePremierProjet__c                = null;
			chantier.dateDernierProjet__c                = null;
			chantier.statutPremierProjet__c              = null;
			chantier.statutDernierProjet__c              = null;
			chantier.nbProjetsAnalyse__c                 = null;
			chantier.nbProjetsRDV__c                     = null;
			chantier.nbProjetsDevis__c                   = null;
			chantier.nbProjetsDevisEnvoye__c             = null;
			chantier.nbProjetsEnAttente__c               = null;
			chantier.nbProjetsNegociation__c             = null;
			chantier.nbProjetsReporte__c                 = null;
			chantier.nbProjetsVendu__c                   = null;
			chantier.nbProjetsRefus__c                   = null;
				
			chantier.datePremierRPlus__c                 = null;
			chantier.datePremierR1__c                    = null;
			chantier.datePremierR2__c                    = null;
			chantier.datePremierRDV__c                   = null;
			chantier.dateDernierRPlus__c                 = null;
			chantier.dateDernierR1__c                    = null;
			chantier.dateDernierR2__c                    = null;
			chantier.dateDernierRDV__c                   = null;
			chantier.nbRPlusEffectues__c                 = null;
			chantier.nbRPlusNonEffectues__c              = null;
			chantier.nbRPlusNonEffectuesAvecDep__c       = null;
			chantier.nbRPlusPris__c                      = null;
			chantier.nbRPlusDeplaces__c                  = null;
			chantier.nbR1Effectues__c                    = null;
			chantier.nbR1NonEffectues__c                 = null;
			chantier.nbR1NonEffectuesAvecDep__c          = null;
			chantier.nbR1Pris__c                         = null;
			chantier.nbR1Deplaces__c                     = null;
			chantier.nbR2NonEffectues__c                 = null;
			chantier.nbR2Effectues__c                    = null;
			chantier.nbR2NonEffectuesAvecDep__c          = null;
			chantier.nbR2Pris__c                         = null;
			chantier.nbR2Deplaces__c                     = null;
			chantier.statutPremierRPlus__c               = null;
			chantier.statutPremierR1__c                  = null;
			chantier.statutPremierR2__c                  = null;
			chantier.statutPremierRDV__c                 = null;
			chantier.statutDernierRPlus__c               = null;
			chantier.statutDernierR1__c                  = null;
			chantier.statutDernierR2__c                  = null;
			chantier.statutDernierRDV__c                 = null;

			chantier.datePremierDevis__c                 = null;
			chantier.dateDernierDevis__c                 = null;
			chantier.statutPremierDevis__c               = null;
			chantier.statutDernierDevis__c               = null;
			chantier.totalHTDevisEnAttente__c            = null;
			chantier.totalTTCDevisEnAttente__c           = null;
			chantier.totalHTDevisEnregistres__c          = null;
			chantier.totalTTCDevisEnregistres__c         = null;
			chantier.totalRemisesEnAttenteEnseigne__c    = null;
			chantier.totalRemisesEnAttenteVendeur__c     = null;
			chantier.totalRemisesEnregistreesEnseigne__c = null;
			chantier.totalRemisesEnregistreesVendeur__c  = null;
			chantier.nbDevisAConfigurer__c               = null;
			chantier.nbDevisErrones__c                   = null;
			chantier.nbDevisNonTransmis__c               = null;
			chantier.nbDevisResilies__c                  = null;
			chantier.nbDevisTransmis__c                  = null;
			chantier.nbDevisVendusEnAttente__c           = null;
			chantier.nbDevisVendusEnregistres__c         = null;
			chantier.nbDevisVendusIncontournables__c     = null;

			chantier.datePremierContrat__c               = null;
			chantier.dateDernierContrat__c               = null;
			chantier.statutPremierContrat__c             = null;
			chantier.statutDernierContrat__c             = null;
			chantier.totalHTContratsVendus__c            = null;
			chantier.totalTTCContratsVendus__c           = null;
			chantier.totalHTContratsResilies__c          = null;
			chantier.totalTTCContratsResilies__c         = null;
			chantier.nbContratsVendus__c                 = null;
			chantier.nbContratsResilies__c               = null;

			chantier.datePremierIEC__c                   = null;
			chantier.statutPremierIEC__c                 = null;
			chantier.dateDernierIEC__c                   = null;
			chantier.statutDernierIEC__c                 = null;
			chantier.nbIECEnCours__c                     = null;
			chantier.nbIECTermines__c                    = null;

			chantier.datePremierIncontournable__c        = null;
			chantier.dateDernierIncontournable__c        = null;
			chantier.nbIncontournablesEnregistres__c     = null;
			chantier.nbIncontournablesEnCours__c         = null;
			chantier.nbIncontournablesTermines__c        = null;
			chantier.statutPremierIncontournable__c      = null;
			chantier.statutDernierIncontournable__c      = null;

			chantier.datePremierAppelSortant__c          = null;
			chantier.dateDernierAppelSortant__c          = null;
			chantier.nbAppelsSortants__c                 = null;
			chantier.datePremierTagAppel__c              = null;
			chantier.dateDernierTagAppel__c              = null;
			chantier.nbTagsAppel__c                      = null;
			chantier.datePremierEmail__c                 = null;
			chantier.dateDernierEmail__c                 = null;
			chantier.nbEmails__c                         = null;
			chantier.datePremierPhoning__c               = null;
			chantier.dateDernierPhoning__c               = null;
			chantier.nbPhonings__c                       = null;
		}
	}
  
  	private static void applyDataUpdateRules(UserContext currentUserContext) {
		/** A - Initialisation des données intermédiaires **/
		List<Chantier__c> newChantiers = new List<Chantier__c>();
		Map<Id, Chantier__c>  oldChantiers = (Map<Id, Chantier__c>)Trigger.oldMap;

		Set<String> irisUtilises = new Set<String>();
		Set<String> ccUtilises = new Set<String>();
		Set<String> cpUtilises = new Set<String>();
        Map<Id, Sectorisation__c> sectorisations = new Map<Id, Sectorisation__c>();
		Map<String, Sectorisation__c> sectorisationsByIris = new Map<String, Sectorisation__c>();
		Map<String, Id> sectorisationsKStore = new Map<String, Id>();
		Set<String> mappingKStore = new Set<String>();
        Set<String> codeEntiteList = new Set<String>();
        Map<String, Id> entitesByRef = new Map<String, Id>();
		Boolean codePostalModifie = false;

    	for (Chantier__c newChantier : (List<Chantier__c>)Trigger.new) {
      		if (!AlreadyUsed.isUsed('TR020_Chantier.applyUpdateRules', newChantier.id)) {
				/* UR001_K2_Account_Sectorisation = Calcul de la sectorisation */
				Chantier__c oldChantier = oldChantiers == null ? null : oldChantiers.get(newChantier.id);

				/* UR001_K2_Chantier_Sectorisation = Calcul de la sectorisation */
				if (newChantier.iris__c != null && (Trigger.isInsert || newChantier.iris__c != oldChantier.iris__c || newChantier.sectorisation__c == null)) {
					irisUtilises.add(newChantier.iris__c);
					ccUtilises.add(newChantier.codeCommune__c);
					cpUtilises.add(newChantier.codePostal__c);
				}

				if (!String.isEmpty(newChantier.codePostal__c)
					&& (String.isEmpty(newChantier.pays__c) || 'F'.equalsIgnoreCase(newChantier.pays__c) || 'FR'.equalsIgnoreCase(newChantier.pays__c) || 'FRA'.equalsIgnoreCase(newChantier.pays__c) || 'FRANCE'.equalsIgnoreCase(newChantier.pays__c))
					&& (Trigger.isInsert || newChantier.codePostal__c != oldChantier.codePostal__c)) {
						codePostalModifie = true;
				}

				newChantiers.add(newChantier);
			}
	  	}

    	if (newChantiers.isEmpty()) {
        	return;
		}

		// Recherche des iris utilisés et des sectorisations associées 
    	if (!irisUtilises.isEmpty()) {
        	sectorisations = new Map<Id, Sectorisation__c>([SELECT id, iris__c, codePostalAdm__c, codeCommuneAdm__c,
																	codeDepot__c, libelleDepot__c,
																	codeDS__c, libelleDS__c,
																	codeDV__c, libelleDV__c, 
																	codeMagasin__c, libelleMagasin__c, 
																	codeRegion__c, libelleRegion__c
															FROM Sectorisation__c  WHERE iris__c IN :irisUtilises 
															OR codeCommuneAdm__c IN :ccUtilises OR codePostalAdm__c IN :cpUtilises]);

            // Sectorisations par iris 
            for (Sectorisation__c sectorisation : sectorisations.values()) {
                sectorisationsByIris.put(sectorisation.iris__c, sectorisation);
                // Récupération des codes pour entité
                if(String.isNotBlank(sectorisation.codeMagasin__c)) {
                    codeEntiteList.add(sectorisation.codeMagasin__c);
                }
                if(String.isNotBlank(sectorisation.codeDepot__c)) {
                    codeEntiteList.add(sectorisation.codeDepot__c);
                }
            }
        
			// Chargement de la sectorisation K-Store 
			Map<String, Mapping__c> mappings = Mapping__c.getAll();
			for (Mapping__c mapping : mappings.values()) {
				if (mapping.repository__c.equalsIgnoreCase('k-store')) {
					sectorisationsKStore.put(mapping.convertedValue__c, null);
					mappingKStore.add(mapping.pickValue__c + ':' + mapping.convertedValue__c);
				}
			}
			for (Sectorisation__c sectorisation : [SELECT id, iris__c FROM Sectorisation__c WHERE iris__c IN :sectorisationsKStore.keySet()]) {
				sectorisationsKStore.put(sectorisation.iris__c, sectorisation.id);
			}
		}
    	Map<String, State__c> states = (codePostalModifie ? State__c.getAll() : null);

        // Recherche des entités
        if (!codeEntiteList.isEmpty()) {
            for (Account ent : [SELECT id, KparKReference__c FROM Account WHERE RecordTypeId = :ENTITY_RTID AND KparKReference__c IN :codeEntiteList]) {
                entitesByRef.put(ent.KparKReference__c, ent.Id);
            }
        }

    	/** B - Application des règles de mise à jour **/
    	List<Chantier__c> proprietairesLocatairesOccupants = new List<Chantier__c>();
    	for (Chantier__c newChantier : newChantiers) {
        	Chantier__c oldChantier = oldChantiers == null ? null : oldChantiers.get(newChantier.id);

			/* UR001_K2_Chantier_Sectorisation = Calcul de la sectorisation
				# Impossible avec WORKFLOW du fait de la recherche dans un autre objet (référentiel sectorisation) et de l'impossibilité d'initialiser la sectorisation par workflow*/        
			if (newChantier.iris__c != null 
				&& ((Trigger.isInsert && String.isBlank(newChantier.salesEntity__c))
					|| (Trigger.isUpdate && (newChantier.iris__c != oldChantier.iris__c || newChantier.sectorisation__c == null || newChantier.ownerId != oldChantier.ownerId)))
			) {
				newChantier.sectorisation__c = SectorisationUtils.getSectorisation(newChantier,oldChantier,sectorisationsByIris,sectorisationsKStore,mappingKStore);
                // Alimentation des entités
                if(String.isNotBlank(newChantier.sectorisation__c) && !entitesByRef.isEmpty()) {
                    newChantier.salesEntity__c = entitesByRef.get(sectorisations.get(newChantier.sectorisation__c).codeMagasin__c);
                    newChantier.serviceEntity__c = entitesByRef.get(sectorisations.get(newChantier.sectorisation__c).codeDepot__c);
                }
			} else if (newChantier.iris__c == null && oldChantier != null && newChantier.iris__c != oldChantier.iris__c) {        
				newChantier.sectorisation__c = null;				
				newChantier.salesEntity__c = null;
				newChantier.serviceEntity__c = null;
			}

        	if (!String.isEmpty(newChantier.codePostal__c)
					&& (String.isEmpty(newChantier.pays__c) || 'F'.equalsIgnoreCase(newChantier.pays__c) || 'FR'.equalsIgnoreCase(newChantier.pays__c) || 'FRA'.equalsIgnoreCase(newChantier.pays__c) || 'FRANCE'.equalsIgnoreCase(newChantier.pays__c))
					&& (Trigger.isInsert || newChantier.codePostal__c != oldChantier.codePostal__c)) {
          		String codePostal = newChantier.codePostal__c.left(newChantier.codePostal__c.startsWith('97') ? 3 : 2);
          		State__c state = states.get(codePostal);
          		if (state != null) {
            		newChantier.departement__c = state.libelleDepartement__c;
				}
        	}

			/* UR001_K2_Chantier_LastModifyByCall = Dernière modification par call
				UR001_K2_Chantier_LastModifyBySale = Dernière modification par vente
				# Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur un utilisateur */
			if (currentUserContext != null && currentUserContext.isCallUser()) {
				newChantier.lastModifiedByCall__c = currentUserContext.getUser().id;
			}
			if (currentUserContext != null && currentUserContext.isSaleUser()) {
				newChantier.lastModifiedBySale__c = currentUserContext.getUser().id;
			}

			/* UR001_K2_Chantier_RAZAutre = RAZ de autrePropriétaire si égal à proprietaire (respectivement autreLocataire vs locataires, et autreOccupant vs occupants) */
			if (newChantier.proprietaire__c == newChantier.autreProprietaire__c) {
				newChantier.autreProprietaire__c = null;
			}
			if (newChantier.locataire__c == newChantier.autreLocataire__c) {
				newChantier.autreLocataire__c = null;
			}
			if (newChantier.occupant__c == newChantier.autreOccupant__c) {
				newChantier.autreOccupant__c = null;
			}

			/* UR001_K2_Chantier_Precedent = Affectation des propriétaires, locataires, et occupants précédents
				# Impossible avec WORKFLOW car champs non proposé par Salesforce dans champs à mettre à jour */
			if (Trigger.isUpdate) { // Aucun intérêt en création car par définition pas de valeur précédente
				if (newChantier.autreProprietaire__c != oldChantier.autreProprietaire__c && oldChantier.autreProprietaire__c != null) {
					newChantier.proprietairePrecedent__c = oldChantier.autreProprietaire__c;
				}
				if (newChantier.proprietaire__c != oldChantier.proprietaire__c && oldChantier.proprietaire__c != null) {
					newChantier.proprietairePrecedent__c = oldChantier.proprietaire__c;
				}

				if (newChantier.autreLocataire__c != oldChantier.autreLocataire__c && oldChantier.autreLocataire__c != null) {
					newChantier.locatairePrecedent__c = oldChantier.autreLocataire__c;
				}
				if (newChantier.locataire__c != oldChantier.locataire__c && oldChantier.locataire__c != null) {
					newChantier.locatairePrecedent__c = oldChantier.locataire__c;
				}

				if (newChantier.autreOccupant__c != oldChantier.autreOccupant__c && oldChantier.autreOccupant__c != null) {
					newChantier.occupantPrecedent__c = oldChantier.autreOccupant__c;
				}
				if (newChantier.occupant__c != oldChantier.occupant__c && oldChantier.occupant__c != null) {
					newChantier.occupantPrecedent__c = oldChantier.occupant__c;
				}
			}

			if (Trigger.isInsert || (newChantier.proprietaire__c != oldChantier.proprietaire__c)
								|| (newChantier.autreProprietaire__c != oldChantier.autreProprietaire__c)
								|| (newChantier.locataire__c != oldChantier.locataire__c)
								|| (newChantier.autreLocataire__c != oldChantier.autreLocataire__c)
								|| (newChantier.occupant__c != oldChantier.occupant__c)
								|| (newChantier.autreOccupant__c != oldChantier.autreOccupant__c)) {
				proprietairesLocatairesOccupants.add(newChantier);
			}
		}

		/* UR001_K2_Chantier_XXXProprietaires/Locataires/Occupants = Nom, adresse et joignabilité des propriétaires, locataires et occupants
			# Impossible avec FORMULES ou WORKFLOWS car limite de 10 relations(jointures) dans les formules dépassée */
		if (!proprietairesLocatairesOccupants.isEmpty()) {
			setProprietairesLocatairesOccupants(proprietairesLocatairesOccupants);
		}
	}

	public static void applyAsyncUpdateRules(UserContext userContext) {
		if (!Trigger.isExecuting) {
			return;
		}

		/** A - Initialisation des données intermédiaires **/
		List<Chantier__c> newChantiers = (List<Chantier__c>)Trigger.new;
		Map<Id, Chantier__c>  oldChantiers = (Map<Id, Chantier__c>)Trigger.oldMap;
		Boolean geoEnabled = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', False);
		List<Chantier__c> asyncChantiers = new List<Chantier__c>();

		/* UR001_K2_Chantier__Geocodage */
		if (geoEnabled) {
			for (Chantier__c newChantier : newChantiers) {
				if (!AlreadyUsed.isUsed('TR020_Chantier.applyAsyncUpdateRules', newChantier.id)) {
					Chantier__c oldChantier = oldChantiers == null ? null : oldChantiers.get(newChantier.id);

					Boolean adresseGeocodable = !String.isEmpty(newChantier.codePostal__c) || !String.isEmpty(newChantier.ville__c);

					Boolean adresseModifiee = Trigger.isInsert ? True
																: (String.isEmpty(newChantier.pays__c) || 'F'.equalsIgnoreCase(newChantier.pays__c) || 'FR'.equalsIgnoreCase(newChantier.pays__c) || 'FRA'.equalsIgnoreCase(newChantier.pays__c) || 'FRANCE'.equalsIgnoreCase(newChantier.pays__c))
																&&
																(newChantier.rue__c != oldChantier.rue__c || newChantier.codePostal__c != oldChantier.codePostal__c || newChantier.ville__c != oldChantier.ville__c || newChantier.pays__c != oldChantier.pays__c);

					if (adresseGeocodable &&
							((Trigger.isInsert && String.isEmpty(newChantier.iris__c)) // Condition String.isEmpty(newAccount.iris__c) nécéssaire afin de ne pas écraser un géocodage manuel
							||
							String.isEmpty(newChantier.iris__c)
							||
							(Trigger.isUpdate && adresseModifiee && (System.isBatch() || String.isEmpty(newChantier.methodeGeocodage__c) || newChantier.methodeGeocodage__c.equalsIgnoreCase('Batch'))))) {
						asyncChantiers.add(newChantier);
					}
				}
			}
		}

		/** B - Application des règles de mise à jour **/
		if (geoEnabled && !asyncChantiers.isEmpty()) {
			GeoUtils.updateChantiers(asyncChantiers);
		}
	}

	public static void setProprietairesLocatairesOccupants(List<Chantier__c> chantiers) {
		Set<ID> accountIds = new Set<ID>();
		String typeAccount;
		String villeAccount;
		String prenomAccount;
		String nomAccount;

		for (Chantier__c chantier : chantiers) {
			/* Comptes associés au chantier */
			if (chantier.proprietaire__c != null) {
				accountIds.add(chantier.proprietaire__c);
			}
			if (chantier.autreProprietaire__c != null) {
				accountIds.add(chantier.autreProprietaire__c);
			}
			if (chantier.locataire__c != null) {
				accountIds.add(chantier.locataire__c);
			}
			if (chantier.autreLocataire__c != null) {
				accountIds.add(chantier.autreLocataire__c);
			}
			if (chantier.occupant__c != null) {
				accountIds.add(chantier.occupant__c);
			}
			if (chantier.autreOccupant__c != null) {
				accountIds.add(chantier.autreOccupant__c);
			}
		}

		Map<Id, Account> accounts = new Map<Id, Account>([SELECT isPersonAccount,
																salutation, firstName, lastName, name,
																rue__c, codePostal__c, ville__c, departement__c, pays__c,
																telephoneDomicile__c, telephoneMobile__c, phone, email__c,
																autreTelephone__c, fichiersOpposition__c
														FROM Account
														WHERE id IN :accountIds]);
		
		for (Chantier__c chantier : chantiers) {
			Account proprietaire = accounts.get(chantier.proprietaire__c);
			Account autreProprietaire = accounts.get(chantier.autreProprietaire__c);
			Account locataire = accounts.get(chantier.locataire__c);
			Account autreLocataire = accounts.get(chantier.autreLocataire__c);
			Account occupant = accounts.get(chantier.occupant__c);
			Account autreOccupant = accounts.get(chantier.autreOccupant__c);
			
			if (chantier.occupant__c != null || chantier.autreOccupant__c != null) {
				chantier.interditProspection__c = opposition(occupant) || opposition(autreOccupant);
			} else if (chantier.locataire__c != null || chantier.autreLocataire__c != null) {
				chantier.interditProspection__c = opposition(locataire) || opposition(autreLocataire);
			} else if (chantier.proprietaire__c != null || chantier.autreProprietaire__c != null) {
				chantier.interditProspection__c = opposition(proprietaire) || opposition(autreProprietaire);
			}
			
			if (chantier.proprietaire__c == null) {
				if (chantier.autreProprietaire__c == null) { // Pas de propriétaire principal, ni propriétaire secondaire
					chantier.civiliteProprietaires__c          = null;
					chantier.nomProprietaires__c               = null;
					chantier.prenomProprietaires__c            = null;
					chantier.rueProprietaires__c               = null;
					chantier.codePostalProprietaires__c        = null;
					chantier.villeProprietaires__c             = null;
					chantier.departementProprietaires__c       = null;
					chantier.paysProprietaires__c              = null;
					chantier.telephoneDomicileProprietaires__c = null;
					chantier.telephoneMobileProprietaires__c   = null;
					chantier.telephoneProprietaires__c         = null;
					chantier.autreTelephoneProprietaires__c    = null;
					chantier.emailProprietaires__c             = null;          
				} else { // Pas de propriétaire principal mais un propriétaire secondaire
					chantier.civiliteProprietaires__c          = autreProprietaire.isPersonAccount ? autreProprietaire.salutation : null;
					chantier.nomProprietaires__c               = autreProprietaire.isPersonAccount ? autreProprietaire.lastName : autreProprietaire.name;
					chantier.prenomProprietaires__c            = autreProprietaire.isPersonAccount ? autreProprietaire.firstName : null;
					chantier.rueProprietaires__c               = autreProprietaire.rue__c;
					chantier.codePostalProprietaires__c        = autreProprietaire.codePostal__c;
					chantier.villeProprietaires__c             = autreProprietaire.ville__c;
					chantier.departementProprietaires__c       = autreProprietaire.departement__c;
					chantier.paysProprietaires__c              = autreProprietaire.pays__c;
					chantier.telephoneDomicileProprietaires__c = autreProprietaire.telephoneDomicile__c;
					chantier.telephoneMobileProprietaires__c   = autreProprietaire.telephoneMobile__c;
					chantier.telephoneProprietaires__c         = autreProprietaire.phone;
					chantier.autreTelephoneProprietaires__c    = autreProprietaire.autreTelephone__c;
					chantier.emailProprietaires__c             = autreProprietaire.email__c;
					typeAccount = 'Autre propriétaire';
					villeAccount = chantier.villeProprietaires__c;
					nomAccount = chantier.nomProprietaires__c;
					prenomAccount = chantier.prenomProprietaires__c;
				}
			}
			else { // Un propriétaire principal mais pas de propriétaire secondaire
				if (chantier.autreProprietaire__c == null) {
					chantier.civiliteProprietaires__c          = proprietaire.isPersonAccount ? proprietaire.salutation : null;
					chantier.nomProprietaires__c               = proprietaire.isPersonAccount ? proprietaire.lastName : proprietaire.name;
					chantier.prenomProprietaires__c            = proprietaire.isPersonAccount ? proprietaire.firstName : null;
					chantier.rueProprietaires__c               = proprietaire.rue__c;
					chantier.codePostalProprietaires__c        = proprietaire.codePostal__c;
					chantier.villeProprietaires__c             = proprietaire.ville__c;
					chantier.departementProprietaires__c       = proprietaire.departement__c;
					chantier.paysProprietaires__c              = proprietaire.pays__c;
					chantier.telephoneDomicileProprietaires__c = proprietaire.telephoneDomicile__c;
					chantier.telephoneMobileProprietaires__c   = proprietaire.telephoneMobile__c;
					chantier.telephoneProprietaires__c         = proprietaire.phone;
					chantier.autreTelephoneProprietaires__c    = proprietaire.autreTelephone__c;
					chantier.emailProprietaires__c             = proprietaire.email__c;
				} else {
					String nomPrincipal     = StringUtils.defaultIfEmpty(proprietaire.isPersonAccount ? proprietaire.lastName : proprietaire.name, '');
					String prenomPrincipal  = proprietaire.isPersonAccount ? StringUtils.defaultIfEmpty(proprietaire.firstName, '') : '';
					String nomSecondaire    = StringUtils.defaultIfEmpty(autreProprietaire.isPersonAccount ? autreProprietaire.lastName : autreProprietaire.name, '');
					String prenomSecondaire = autreProprietaire.isPersonAccount ? StringUtils.defaultIfEmpty(autreProprietaire.firstName, '') : '';

					chantier.civiliteProprietaires__c          = proprietaire.isPersonAccount && autreProprietaire.isPersonAccount ? 'MM' : null;
					chantier.nomProprietaires__c               = nomPrincipal.equalsIgnoreCase(nomSecondaire) ? nomPrincipal : nomPrincipal + ' et ' + nomSecondaire;
					chantier.prenomProprietaires__c            = prenomPrincipal.equalsIgnoreCase(prenomSecondaire) ? prenomPrincipal : prenomPrincipal + ' et ' + prenomSecondaire;
					chantier.rueProprietaires__c               = proprietaire.rue__c;
					chantier.codePostalProprietaires__c        = proprietaire.codePostal__c;
					chantier.villeProprietaires__c             = proprietaire.ville__c;
					chantier.departementProprietaires__c       = proprietaire.departement__c;
					chantier.paysProprietaires__c              = proprietaire.pays__c;
					chantier.telephoneDomicileProprietaires__c = proprietaire.telephoneDomicile__c;
					chantier.telephoneMobileProprietaires__c   = proprietaire.telephoneMobile__c;
					chantier.telephoneProprietaires__c         = proprietaire.phone;
					chantier.autreTelephoneProprietaires__c    = proprietaire.autreTelephone__c;
					chantier.emailProprietaires__c             = proprietaire.email__c;          
				}
				typeAccount = 'Propriétaire';
				villeAccount = chantier.villeProprietaires__c;
				nomAccount = chantier.nomProprietaires__c;
				prenomAccount = chantier.prenomProprietaires__c;
			}

			if (chantier.locataire__c == null) {
				if (chantier.autreLocataire__c == null) { // Pas de propriétaire principal, ni propriétaire secondaire
					chantier.civiliteLocataires__c          = null;
					chantier.nomLocataires__c               = null;
					chantier.prenomLocataires__c            = null;
					chantier.rueLocataires__c               = null;
					chantier.codePostalLocataires__c        = null;
					chantier.villeLocataires__c             = null;
					chantier.departementLocataires__c       = null;
					chantier.paysLocataires__c              = null;
					chantier.telephoneDomicileLocataires__c = null;
					chantier.telephoneMobileLocataires__c   = null;
					chantier.telephoneLocataires__c         = null;
					chantier.autreTelephoneLocataires__c    = null;
					chantier.emailLocataires__c             = null;
				} else { // Pas de propriétaire principal mais un propriétaire secondaire
					chantier.civiliteLocataires__c          = autreLocataire.isPersonAccount ? autreLocataire.salutation : null;
					chantier.nomLocataires__c               = autreLocataire.isPersonAccount ? autreLocataire.lastName : autreLocataire.name;
					chantier.prenomLocataires__c            = autreLocataire.isPersonAccount ? autreLocataire.firstName : null;
					chantier.rueLocataires__c               = autreLocataire.rue__c;
					chantier.codePostalLocataires__c        = autreLocataire.codePostal__c;
					chantier.villeLocataires__c             = autreLocataire.ville__c;
					chantier.departementLocataires__c       = autreLocataire.departement__c;
					chantier.paysLocataires__c              = autreLocataire.pays__c;
					chantier.telephoneDomicileLocataires__c = autreLocataire.telephoneDomicile__c;
					chantier.telephoneMobileLocataires__c   = autreLocataire.telephoneMobile__c;
					chantier.telephoneLocataires__c         = autreLocataire.phone;
					chantier.autreTelephoneLocataires__c    = autreLocataire.autreTelephone__c;
					chantier.emailLocataires__c             = autreLocataire.email__c;
					typeAccount = 'Autre locataire';
					villeAccount = chantier.villeLocataires__c;
					nomAccount = chantier.nomLocataires__c;
					prenomAccount = chantier.prenomLocataires__c;
				}
			} else { // Un propriétaire principal mais pas de propriétaire secondaire
				if (chantier.autreLocataire__c == null) {
					chantier.civiliteLocataires__c          = locataire.isPersonAccount ? locataire.salutation : null;
					chantier.nomLocataires__c               = locataire.isPersonAccount ? locataire.lastName : locataire.name;
					chantier.prenomLocataires__c            = locataire.isPersonAccount ? locataire.firstName : null;
					chantier.rueLocataires__c               = locataire.rue__c;
					chantier.codePostalLocataires__c        = locataire.codePostal__c;
					chantier.villeLocataires__c             = locataire.ville__c;
					chantier.departementLocataires__c       = locataire.departement__c;
					chantier.paysLocataires__c              = locataire.pays__c;
					chantier.telephoneDomicileLocataires__c = locataire.telephoneDomicile__c;
					chantier.telephoneMobileLocataires__c   = locataire.telephoneMobile__c;
					chantier.telephoneLocataires__c         = locataire.phone;
					chantier.autreTelephoneLocataires__c    = locataire.autreTelephone__c;
					chantier.emailLocataires__c             = locataire.email__c;
				}
				else {
					String nomPrincipal     = StringUtils.defaultIfEmpty(locataire.isPersonAccount ? locataire.lastName : Locataire.name, '');
					String prenomPrincipal  = locataire.isPersonAccount ? StringUtils.defaultIfEmpty(locataire.firstName, '') : '';
					String nomSecondaire    = StringUtils.defaultIfEmpty(autreLocataire.isPersonAccount ? autreLocataire.lastName : autreLocataire.name, '');
					String prenomSecondaire = autreLocataire.isPersonAccount ? StringUtils.defaultIfEmpty(autreLocataire.firstName, '') : '';

					chantier.civiliteLocataires__c          = locataire.isPersonAccount && autreLocataire.isPersonAccount ? 'MM' : null;
					chantier.nomLocataires__c               = nomPrincipal.equalsIgnoreCase(nomSecondaire) ? nomPrincipal : nomPrincipal + ' et ' + nomSecondaire;
					chantier.prenomLocataires__c            = prenomPrincipal.equalsIgnoreCase(prenomSecondaire) ? prenomPrincipal : prenomPrincipal + ' et ' + prenomSecondaire;
					chantier.rueLocataires__c               = locataire.rue__c;
					chantier.codePostalLocataires__c        = locataire.codePostal__c;
					chantier.villeLocataires__c             = locataire.ville__c;
					chantier.departementLocataires__c       = locataire.departement__c;
					chantier.paysLocataires__c              = locataire.pays__c;
					chantier.telephoneDomicileLocataires__c = locataire.telephoneDomicile__c;
					chantier.telephoneMobileLocataires__c   = locataire.telephoneMobile__c;
					chantier.telephoneLocataires__c         = locataire.phone;
					chantier.autreTelephoneLocataires__c    = locataire.autreTelephone__c;
					chantier.emailLocataires__c             = locataire.email__c;
				}
				typeAccount = 'Locataire';
				villeAccount = chantier.villeLocataires__c;
				nomAccount = chantier.nomLocataires__c;
				prenomAccount = chantier.prenomLocataires__c;
			}

			if (chantier.Occupant__c == null) {
				if (chantier.autreOccupant__c == null) { // Pas de propriétaire principal, ni propriétaire secondaire
					chantier.civiliteOccupants__c          = null;
					chantier.nomOccupants__c               = null;
					chantier.prenomOccupants__c            = null;
					chantier.rueOccupants__c               = null;
					chantier.codePostalOccupants__c        = null;
					chantier.villeOccupants__c             = null;
					chantier.departementOccupants__c       = null;
					chantier.paysOccupants__c              = null;
					chantier.telephoneDomicileOccupants__c = null;
					chantier.telephoneMobileOccupants__c   = null;
					chantier.telephoneOccupants__c         = null;
					chantier.autreTelephoneOccupants__c    = null;
					chantier.emailOccupants__c             = null;
				} else { // Pas de propriétaire principal mais un propriétaire secondaire
					chantier.civiliteOccupants__c          = autreOccupant.isPersonAccount ? autreOccupant.salutation : null;
					chantier.nomOccupants__c               = autreOccupant.isPersonAccount ? autreOccupant.lastName : autreOccupant.name;
					chantier.prenomOccupants__c            = autreOccupant.isPersonAccount ? autreOccupant.firstName : null;
					chantier.rueOccupants__c               = autreOccupant.rue__c;
					chantier.codePostalOccupants__c        = autreOccupant.codePostal__c;
					chantier.villeOccupants__c             = autreOccupant.ville__c;
					chantier.departementOccupants__c       = autreOccupant.departement__c;
					chantier.paysOccupants__c              = autreOccupant.pays__c;
					chantier.telephoneDomicileOccupants__c = autreOccupant.telephoneDomicile__c;
					chantier.telephoneMobileOccupants__c   = autreOccupant.telephoneMobile__c;
					chantier.telephoneOccupants__c         = autreOccupant.phone;
					chantier.autreTelephoneOccupants__c    = autreOccupant.autreTelephone__c;
					chantier.emailOccupants__c             = autreOccupant.email__c;
					typeAccount = 'Autre occupant';
					villeAccount = chantier.villeOccupants__c;
					nomAccount = chantier.nomOccupants__c;
					prenomAccount = chantier.prenomOccupants__c;
				}
			} else { // Un propriétaire principal mais pas de propriétaire secondaire
				if (chantier.autreOccupant__c == null) {
					chantier.civiliteOccupants__c          = Occupant.isPersonAccount ? Occupant.salutation : null;
					chantier.nomOccupants__c               = Occupant.isPersonAccount ? Occupant.lastName : Occupant.name;
					chantier.prenomOccupants__c            = Occupant.isPersonAccount ? Occupant.firstName : null;
					chantier.rueOccupants__c               = Occupant.rue__c;
					chantier.codePostalOccupants__c        = Occupant.codePostal__c;
					chantier.villeOccupants__c             = Occupant.ville__c;
					chantier.departementOccupants__c       = Occupant.departement__c;
					chantier.paysOccupants__c              = Occupant.pays__c;
					chantier.telephoneDomicileOccupants__c = Occupant.telephoneDomicile__c;
					chantier.telephoneMobileOccupants__c   = Occupant.telephoneMobile__c;
					chantier.telephoneOccupants__c         = Occupant.phone;
					chantier.autreTelephoneOccupants__c    = Occupant.autreTelephone__c;
					chantier.emailOccupants__c             = Occupant.email__c;
				} else {
					String nomPrincipal     = StringUtils.defaultIfEmpty(Occupant.isPersonAccount ? Occupant.lastName : Occupant.name, '');
					String prenomPrincipal  = Occupant.isPersonAccount ? StringUtils.defaultIfEmpty(Occupant.firstName, '') : '';
					String nomSecondaire    = StringUtils.defaultIfEmpty(autreOccupant.isPersonAccount ? autreOccupant.lastName : autreOccupant.name, '');
					String prenomSecondaire = autreOccupant.isPersonAccount ? StringUtils.defaultIfEmpty(autreOccupant.firstName, '') : '';

					chantier.civiliteOccupants__c          = Occupant.isPersonAccount && autreOccupant.isPersonAccount ? 'MM' : null;
					chantier.nomOccupants__c               = nomPrincipal.equalsIgnoreCase(nomSecondaire) ? nomPrincipal : nomPrincipal + ' et ' + nomSecondaire;
					chantier.prenomOccupants__c            = prenomPrincipal.equalsIgnoreCase(prenomSecondaire) ? prenomPrincipal : prenomPrincipal + ' et ' + prenomSecondaire;
					chantier.rueOccupants__c               = Occupant.rue__c;
					chantier.codePostalOccupants__c        = Occupant.codePostal__c;
					chantier.villeOccupants__c             = Occupant.ville__c;
					chantier.departementOccupants__c       = Occupant.departement__c;
					chantier.paysOccupants__c              = Occupant.pays__c;
					chantier.telephoneDomicileOccupants__c = Occupant.telephoneDomicile__c;
					chantier.telephoneMobileOccupants__c   = Occupant.telephoneMobile__c;
					chantier.telephoneOccupants__c         = Occupant.phone;
					chantier.autreTelephoneOccupants__c    = Occupant.autreTelephone__c;
					chantier.emailOccupants__c             = Occupant.email__c;
				}
				typeAccount = 'Occupant';
				villeAccount = chantier.villeOccupants__c;
				nomAccount = chantier.nomOccupants__c;
				prenomAccount = chantier.prenomOccupants__c;
			}
		}
	}
  
    /**
    * @description Retourne les 3 premières lettres du mois en cours (sauf juin et juillet)
    * @param month Numéro du mois en cours
    * @return String Préfixe du mois
    */
    private static String getMonthValue(Integer month) {
		String monthStr;
        switch on month {
			when 1 { monthStr = 'JAN';}
			when 2 { monthStr = 'FEV'; }
			when 3 { monthStr = 'MAR'; }
			when 4 { monthStr = 'AVR'; }
			when 5 { monthStr = 'MAI'; }
			when 6 { monthStr = 'JUIN'; }
			when 7 { monthStr = 'JUIL'; }
			when 8 { monthStr = 'AOU'; }
			when 9 { monthStr = 'SEP'; }
			when 10 { monthStr = 'OCT'; }
			when 11 { monthStr = 'NOV'; }
			when 12 { monthStr = 'DEC'; }
			when else { monthStr = 'N/A'; }
		}
        return monthStr;
    }
  
    /**
    * @description Retourne false si le compte est dans un fichier d'opposition
    * @param account Compte
    * @return Boolean False si compte en opposition
    */
    private static Boolean opposition(Account account) {
        if (account == null) {
            return false;
		}
        return (!String.isEmpty(account.fichiersOpposition__c) && (account.fichiersOpposition__c.contains('K par K') || account.fichiersOpposition__c.contains('CNIL')));
    }
}