//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Account
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/04/2023
//-- Version     : 1.8
//-- * 1.8 : Mise à jour pour KUBE3 - Ajout téléphone international
//-- * 1.75 : Vérification des noms si création ou modification
//-- * 1.74 : Mise en place des nouveaux types d'enregistrement des comptes
//-- * 1.73 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Account {
    private static final String  CHECK_LETTER = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    private static final String  CHECK_OTHER  = '0123456789,;:!?./§*%µ^$¨£¤²&~"#{([|`_\\^@';
    private static final Boolean TESTING      = Test.isRunningTest();
    private static final String ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final String PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);
    private static final String EXRESOURCE_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_EXTERNE_RT);
    private static final String FUNDINGORG_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_FUNDINGORG_RT);
    private static final String PRO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);
    private static final String PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    
    /**
    * @description Méthode exécutant les règles de validation pour les comptes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        List<Account> checkParrainAcc = new List<Account>();
        Map<Id, Account> oldAccounts = (Map<Id, Account>)Trigger.oldMap;
        Set<Id> parrainIds = new Set<Id>();

        System.debug('### DEBUT TR020_Account.applyValidationRules');
        for (Account newAccount : (List<Account>)Trigger.new) {
            Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);
            
            if (!AlreadyUsed.isUsed('TR020_Account.applyValidationRules', newAccount.id)) {
                // Vérification du nom uniquement si nouveau compte ou modification du nom
                if (oldAccount == null || newAccount.name != oldAccount.name || newAccount.firstName != oldAccount.firstName  || newAccount.lastName != oldAccount.lastName)
                    checkName(newAccount);
                if (newAccount.RecordTypeId != ENTITY_RTID && newAccount.RecordTypeId != PROVIDER_RTID 
                    && newAccount.RecordTypeId != EXRESOURCE_RTID && newAccount.RecordTypeId != FUNDINGORG_RTID 
                    && (Trigger.isInsert || newAccount.parrain__c != oldAccount.parrain__c)) 
                {
                    parrainIds.add(newAccount.parrain__c);
                    checkParrainAcc.add(newAccount);
                }
            }
        }

        // B - Application des règles de mise à jour synchrone 
        // Vérification que le parrain est bien un client
        if (!checkParrainAcc.isEmpty()) {
            Map<Id, Account> parrains = new Map<Id, Account>([SELECT id, type FROM Account WHERE id IN :parrainIds]);            
            for (Account newAccount : checkParrainAcc) {
                System.debug('## Check Parrain: '+newAccount.Id);
                Account parrain = parrains.get(newAccount.parrain__c);                
                if (parrain != null && !('Client'.equalsIgnoreCase(parrain.type))) {
                    newAccount.parrain__c.addError('Le parrain doit être de type client!');
                }
            }
        }
        System.debug('### FIN TR020_Account.applyValidationRules');
    }

    /**
    * @description Méthode exécutant les différentes règles de modification pour les comptes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        System.debug('### DEBUT TR020_Account.applyUpdateRules');
        if (Trigger.isInsert) {
            initIndicators(userContext);
        }

        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
        if (Trigger.isInsert) {
            applyRTUpdateRules(userContext);
            applyEntitiesRules(userContext);
        }
        System.debug('### FIN TR020_Account.applyUpdateRules');
    }

    /**
    * @description Méthode afin d'initialiser les différents indicateurs
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void initIndicators(UserContext userContext) {
        System.debug('### DEBUT TR020_Account.initIndicators');

        for (Account account : (List<Account>)Trigger.new) {
            if(account.RecordTypeId != ENTITY_RTID && account.RecordTypeId != PROVIDER_RTID 
               && account.RecordTypeId != EXRESOURCE_RTID && account.RecordTypeId != FUNDINGORG_RTID) {                   
                System.debug('## Init Indicators: '+account.Id);
                account.dateDerniereCampagne__c             = null;
                account.nbCampagnes__c                      = null;

                account.nbChantiersLocataire__c             = null;
                account.nbChantiersExLocataire__c           = null;
                account.nbChantiersOccupant__c              = null;
                account.nbChantiersExOccupant__c            = null;
                account.nbChantiersProprietaire__c          = null;
                account.nbChantiersExProprietaire__c        = null;
                account.nbChantiersUniques__c               = null;

                account.datePremierProjet__c                = null;
                account.dateDernierProjet__c                = null;
                account.statutPremierProjet__c              = null;
                account.statutDernierProjet__c              = null;
                account.nbProjetsAnalyse__c                 = null;
                account.nbProjetsRDV__c                     = null;
                account.nbProjetsDevis__c                   = null;
                account.nbProjetsDevisEnvoye__c             = null;
                account.nbProjetsEnAttente__c               = null;
                account.nbProjetsNegociation__c             = null;
                account.nbProjetsReporte__c                 = null;
                account.nbProjetsVendu__c                   = null;
                account.nbProjetsRefus__c                   = null;

                account.datePremierRPlus__c                 = null;
                account.datePremierR1__c                    = null;
                account.datePremierR2__c                    = null;
                account.datePremierRDV__c                   = null;
                account.dateDernierRPlus__c                 = null;
                account.dateDernierR1__c                    = null;
                account.dateDernierR2__c                    = null;
                account.dateDernierRDV__c                   = null;
                account.nbRPlusEffectues__c                 = null;
                account.nbRPlusNonEffectues__c              = null;
                account.nbRPlusNonEffectuesAvecDep__c       = null;
                account.nbRPlusPris__c                      = null;
                account.nbRPlusDeplaces__c                  = null;
                account.nbR1Effectues__c                    = null;
                account.nbR1NonEffectues__c                 = null;
                account.nbR1NonEffectuesAvecDep__c          = null;
                account.nbR1Pris__c                         = null;
                account.nbR1Deplaces__c                     = null;
                account.nbR2NonEffectues__c                 = null;
                account.nbR2Effectues__c                    = null;
                account.nbR2NonEffectuesAvecDep__c          = null;
                account.nbR2Pris__c                         = null;
                account.nbR2Deplaces__c                     = null;
                account.nbRDVDevisables__c                  = null;
                account.statutPremierRPlus__c               = null;
                account.statutPremierR1__c                  = null;
                account.statutPremierR2__c                  = null;
                account.statutPremierRDV__c                 = null;
                account.statutDernierRPlus__c               = null;
                account.statutDernierR1__c                  = null;
                account.statutDernierR2__c                  = null;
                account.statutDernierRDV__c                 = null;

                account.datePremierDevis__c                 = null;
                account.dateDernierDevis__c                 = null;
                account.statutPremierDevis__c               = null;
                account.statutDernierDevis__c               = null;
                account.totalHTDevisEnAttente__c            = null;
                account.totalTTCDevisEnAttente__c           = null;
                account.totalHTDevisEnregistres__c          = null;
                account.totalTTCDevisEnregistres__c         = null;
                account.totalRemisesEnAttenteEnseigne__c    = null;
                account.totalRemisesEnAttenteVendeur__c     = null;
                account.totalRemisesEnregistreesEnseigne__c = null;
                account.totalRemisesEnregistreesVendeur__c  = null;
                account.nbDevisAConfigurer__c               = null;
                account.nbDevisErrones__c                   = null;
                account.nbDevisNonTransmis__c               = null;
                account.nbDevisResilies__c                  = null;
                account.nbDevisTransmis__c                  = null;
                account.nbDevisVendusEnAttente__c           = null;
                account.nbDevisVendusEnregistres__c         = null;
                account.nbDevisVendusIncontournables__c     = null;

                account.datePremierContrat__c               = null;
                account.dateDernierContrat__c               = null;
                account.statutPremierContrat__c             = null;
                account.statutDernierContrat__c             = null;
                account.totalHTContratsVendus__c            = null;
                account.totalTTCContratsVendus__c           = null;
                account.totalHTContratsResilies__c          = null;
                account.totalTTCContratsResilies__c         = null;
                account.nbContratsVendus__c                 = null;
                account.nbContratsResilies__c               = null;

                account.datePremierIEC__c                   = null;
                account.statutPremierIEC__c                 = null;
                account.dateDernierIEC__c                   = null;
                account.statutDernierIEC__c                 = null;
                account.nbIECEnCours__c                     = null;
                account.nbIECTermines__c                    = null;

                account.datePremierIncontournable__c        = null;
                account.dateDernierIncontournable__c        = null;
                account.nbIncontournablesEnregistres__c     = null;
                account.nbIncontournablesEnCours__c         = null;
                account.nbIncontournablesTermines__c        = null;
                account.statutPremierIncontournable__c      = null;
                account.statutDernierIncontournable__c      = null;

                account.datePremierAppelSortant__c          = null;
                account.dateDernierAppelSortant__c          = null;
                account.nbAppelsSortants__c                 = null;
                account.datePremierTagAppel__c              = null;
                account.dateDernierTagAppel__c              = null;
                account.nbTagsAppel__c                      = null;
                account.datePremierEmail__c                 = null;
                account.dateDernierEmail__c                 = null;
                account.nbEmails__c                         = null;
                account.datePremierPhoning__c          = null;
                account.dateDernierPhoning__c          = null;
                account.nbPhonings__c                 = null; 
            }
            //TMA RQM-303 Suppression de données issues du parcours de formation et d'intégration vendeur
            if((account.RecordTypeId == PRO_RTID || account.RecordTypeId == PERSO_RTID) && (account.FirstName != null || account.LastName != null || account.Name != null)) {
                
                if(account.LastName != null && (account.LastName.toUpperCase() == 'TEST' || account.LastName.toUpperCase().contains('TEST ') 
                  || account.LastName.toUpperCase().contains(' TEST ') || account.LastName.toUpperCase().contains(' TEST'))) {
                    
                       account.simulation__c = true;
                }
                if(account.FirstName != null && (account.FirstName.toUpperCase() == 'TEST' || account.FirstName.toUpperCase().contains('TEST ') 
                  || account.FirstName.toUpperCase().contains(' TEST ') || account.FirstName.toUpperCase().contains(' TEST'))) {
                    
                       account.simulation__c = true;
                }
                if(account.Name != null && (account.Name.toUpperCase() == 'TEST' || account.Name.toUpperCase().contains('TEST ') 
                  || account.Name.toUpperCase().contains(' TEST ') || account.Name.toUpperCase().contains(' TEST'))) {
                    
                       account.simulation__c = true;
                }
            }
        }
        System.debug('### FIN TR020_Account.initIndicators');
    }

    /**
    * @description Méthode permettant de modifier les différents champs des comptes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyDataUpdateRules(UserContext currentUserContext) {
        System.debug('### DEBUT TR020_Account.applyDataUpdateRules');

        /** A - Initialisation des données intermédiaires **/
        List<Account> newAccounts = new List<Account>();
        Map<Id, Account> oldAccounts = (Map<Id, Account>)Trigger.oldMap;

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
        Set<ID> B2BIds = new Set<ID>();      
        List<Id> idParrain = new List<Id>();
    
        for (Account newAccount : (List<Account>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR020_Account.applyDataRules', newAccount.id)) {
                Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);
                Boolean isCustomerRT = (newAccount.RecordTypeId == ENTITY_RTID || newAccount.RecordTypeId == PROVIDER_RTID 
                                        || newAccount.RecordTypeId == EXRESOURCE_RTID || newAccount.RecordTypeId == FUNDINGORG_RTID) ? false : true;
                                      
                // Alimentation du contact par défaut 
                if (isCustomerRT && Trigger.isUpdate && !newAccount.IsPersonAccount && newAccount.contactParDefaut__c == null) {
                    B2BIds.add(newAccount.id);
                }

                // UR001_K2_Account_Sectorisation = Calcul de la sectorisation 
                if (isCustomerRT && newAccount.iris__c != null 
                        && (Trigger.isInsert || newAccount.iris__c != oldAccount.iris__c || newAccount.sectorisation__c == null || newAccount.ownerId != oldAccount.ownerId)) {
                    irisUtilises.add(newAccount.iris__c);
                    ccUtilises.add(newAccount.codeCommune__c);
                    cpUtilises.add(newAccount.codePostal__c);
                }

                // Changement d'adresse
                if (isCustomerRT && (newAccount.IsPersonAccount && !String.isBlank(newAccount.PersonMailingPostalCode)
                        && isInFrance(newAccount.PersonMailingCountry)
                        && (Trigger.isInsert || newAccount.PersonMailingPostalCode != oldAccount.PersonMailingPostalCode))
                    ||
                    (!newAccount.IsPersonAccount && !String.isBlank(newAccount.BillingPostalCode)
                        && isInFrance(newAccount.BillingCountry)
                        && (Trigger.isInsert || newAccount.BillingPostalCode != oldAccount.BillingPostalCode))) {
                        codePostalModifie = true;
                }   

                // Parrain
                if(newAccount.parrain__c != null) {
                    idParrain.add(newAccount.parrain__c);
                }

                newAccounts.add(newAccount);
            }
        }

        System.debug('## newAccounts: '+newAccounts.size());
        if (newAccounts.isEmpty()) {
            return;
        }

        // * A - Recherche des données intermédiaire

        // Recherche des iris utilisés et des sectorisations associées 
        System.debug('## irisUtilises: '+irisUtilises.size());
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

        // Recherche des contacts par defaut pour les comptes B2B sans contact par défaut
        Map<ID, ID> contactsParDefaut = new Map<ID, ID>();
        System.debug('## B2BIds: '+B2BIds.size());
        if (!B2BIds.isEmpty()) {
            for (Contact contact : [SELECT id, accountId FROM contact WHERE accountId IN :B2BIds]) {
                if (!contactsParDefaut.containsKey(contact.accountId)) {
                    contactsParDefaut.put(contact.accountId, contact.id);
                }
            }
        }

        // Recherche des entités
        System.debug('## codeEntiteList: '+codeEntiteList.size());
        if (!codeEntiteList.isEmpty()) {
            for (Account ent : [SELECT id, KparKReference__c FROM Account WHERE RecordTypeId = :ENTITY_RTID AND KparKReference__c IN :codeEntiteList]) {
                entitesByRef.put(ent.KparKReference__c, ent.Id);
            }
        }
        System.debug('## Entities found: '+entitesByRef.size());

        // On recupere la liste des parrains concernés
        Map<ID, Account> parrainMap = new Map<ID, Account>();
        if(!idParrain.isEmpty()) {
            for(Account acc : [SELECT id, email__c, parrain__c FROM Account WHERE Id IN :idParrain]){
                parrainMap.put(acc.Id, acc);
            }
        }
        System.debug('## Parrain found: '+parrainMap.size());

        // * B - Application des règles de mise à jour **/        
        Map<String, State__c> states = (codePostalModifie ? State__c.getAll() : null);
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);
            Boolean isCustomerRT = (newAccount.RecordTypeId == ENTITY_RTID || newAccount.RecordTypeId == PROVIDER_RTID 
                                    || newAccount.RecordTypeId == EXRESOURCE_RTID || newAccount.RecordTypeId == FUNDINGORG_RTID) ? false : true;

            /* UR001_K2_Account_State = Département
            # Impossible avec WORKFLOW du fait des custom parameters non accessibles */
            if ((newAccount.IsPersonAccount && !String.isBlank(newAccount.PersonMailingPostalCode)
                    && isInFrance(newAccount.PersonMailingCountry)
                    && (Trigger.isInsert || newAccount.PersonMailingPostalCode != oldAccount.PersonMailingPostalCode))
                ||
                (!newAccount.IsPersonAccount && !String.isBlank(newAccount.BillingPostalCode)
                    && isInFrance(newAccount.BillingCountry)
                    && (Trigger.isInsert || newAccount.BillingPostalCode != oldAccount.BillingPostalCode))) 
            {
                System.debug('## Département: '+newAccount.Id);
                if (newAccount.IsPersonAccount) {
                    String codePostal = newAccount.PersonMailingPostalCode.left(newAccount.PersonMailingPostalCode.startsWith('97') ? 3 : 2);
                    State__c state = states.get(codePostal);
                    if (state != null) {
                        newAccount.PersonMailingState = state.libelleDepartement__c;
                    }
                } else {
                    String codePostal = newAccount.BillingPostalCode.left(newAccount.BillingPostalCode.startsWith('97') ? 3 : 2);
                    State__c state = states.get(codePostal);
                    if (state != null) {
                        newAccount.BillingState = state.libelleDepartement__c;
                    }
                }
            }
            
            /**********************/
            /* TRAITEMENTS SPECIFIQUES AU COMPTE PERSO OU PRO (PAS ENTITE NI FOURNISEUR) */
            /**********************/
            if (isCustomerRT) 
            {          
                //* UR001_K2_Account_ContactParDefaut  
                if (Trigger.isUpdate && newAccount.contactParDefaut__c == null) {                
                    System.debug('## Alimentation contact Par defaut: '+newAccount.Id);
                    newAccount.contactParDefaut__c = (newAccount.IsPersonAccount == false) ? contactsParDefaut.get(newAccount.id) : newAccount.PersonContactId;
                    System.debug('## Alimentation contact Par defaut: '+newAccount.contactParDefaut__c);
                }

                /* UR001_K2_Account_Sectorisation = Calcul de la sectorisation
                    # Impossible avec WORKFLOW du fait de la recherche dans un autre objet (référentiel sectorisation) et de l'impossibilité d'initialiser la sectorisation par workflow*/
                if (newAccount.iris__c != null && (Trigger.isInsert || newAccount.iris__c != oldAccount.iris__c || newAccount.sectorisation__c == null || newAccount.ownerId != oldAccount.ownerId)) 
                {
                    newAccount.sectorisation__c = SectorisationUtils.getSectorisation(newAccount,oldAccount,sectorisationsByIris,sectorisationsKStore,mappingKStore);                    
                    System.debug('## Sectorisation: '+newAccount.sectorisation__c);
                    // Alimentation des entités
                    if(String.isNotBlank(newAccount.sectorisation__c) && !entitesByRef.isEmpty()) {
                        String salesEntity = entitesByRef.get(sectorisations.get(newAccount.sectorisation__c).codeMagasin__c);
                        String serviceEntity = entitesByRef.get(sectorisations.get(newAccount.sectorisation__c).codeDepot__c);
                        System.debug('## Entité de vente: '+salesEntity);
                        System.debug('## Entité de service: '+serviceEntity);                    
                        if(newAccount.IsPersonAccount) {
                            newAccount.personSalesEntity__pc = salesEntity;
                            newAccount.personServiceEntity__pc = serviceEntity;
                        } else {
                            newAccount.billingSalesEntity__c = salesEntity;
                            newAccount.billingServiceEntity__c = serviceEntity;
                        }
                    }
                } else if (newAccount.iris__c == null && oldAccount != null && newAccount.iris__c != oldAccount.iris__c) {
                    newAccount.sectorisation__c = null;             
                    newAccount.billingSalesEntity__c = null;
                    newAccount.billingServiceEntity__c = null;  
                    newAccount.personSalesEntity__pc = null;
                    newAccount.personServiceEntity__pc = null;
                }

                //* UR001_K2_Notification_Prosodie 
                if (newAccount.callbackProsodie__c == null &&
                    ('44 - Formulaire site KparK'.equalsIgnoreCase(newAccount.accountCallSource__c) ||
                    '15 - Batiweb'.equalsIgnoreCase(newAccount.accountCallSource__c)              ||
                    '15 - Quotatis'.equalsIgnoreCase(newAccount.accountCallSource__c)             ||
                    '44 - Batiweb'.equalsIgnoreCase(newAccount.accountCallSource__c)              ||
                    '44 - Affiliation'.equalsIgnoreCase(newAccount.accountCallSource__c)          ||
                    '44 - Formulaire site QTS'.equalsIgnoreCase(newAccount.accountCallSource__c)
                    ) &&
                    (!String.isBlank(newAccount.telephoneDomicile__c) || !String.isBlank(newAccount.telephoneMobile__c) || !String.isBlank(newAccount.autreTelephone__c) || !String.isBlank(newAccount.phone))) 
                {
                    System.debug('## Callback Prosodie: '+newAccount.Id);
                    // Données interne pour le calcul de la skill Prosodie 
                    DateTime now = DateTime.now();
                    Date today = Date.today();
                    Date weekStart = today.toStartofWeek();
                    Integer jourSemaine = weekStart.daysBetween(today);

                    newAccount.callbackProsodie__c = System.now();
                    
                    /* Jour de déclanchement vers la skill FormulaireDIM  
                    0 : Lundi
                    1 : Mardi
                    2 : Mercredi
                    3 : Jeudi
                    4 : Vendredi
                    5 : samedi
                    6 : Dimanche */
                    if (jourSemaine == 6 && now.hour() >= Utils_Odigo.ODIGO_DIM_OUVERTURE && now.hour() < Utils_Odigo.ODIGO_DIM_FERMETURE) {
                        newAccount.skillProsodie__c = Utils_Odigo.ODIGO_DIM_SKILL;
                    } else {
                        newAccount.skillProsodie__c = Utils_Odigo.ODIGO_SKILL;
                    }
                    newAccount.logProsodie__c = 'Now = ' + now.format() + ' / Jour = ' + now.hour() + ' / Today = ' + today + ' / WeekStart = ' + weekStart + ' / Jour = ' + jourSemaine + '/ Ouv = ' + Utils_Odigo.ODIGO_DIM_OUVERTURE + ' / Ferm = ' + Utils_Odigo.ODIGO_DIM_FERMETURE + ' / Cnd1 = ' + (jourSemaine == 6) + ' / Cnd2 = ' + (now.hour() >= Utils_Odigo.ODIGO_DIM_OUVERTURE) + ' / Cnd3 = ' + (now.hour() < Utils_Odigo.ODIGO_DIM_FERMETURE);                 
                }

                /* UR001_K2_Account_AccountSource
                    # Conversion via mapping impossible avec les workflows */
                if (newAccount.accountSource == null && newAccount.accountCallSource__c != null) {
                    System.debug('## AccountSource: '+newAccount.Id);
                    newAccount.accountSource = MappingUtils.getOrigineVenteFromCall(newAccount.accountCallSource__c);
                }

                /* UR001_K2_Account_1ereSource & UR001_K2_Account_1ereSourceCall
                    # Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur une valeur spécifique
                        et workflows ne fonctionne pas pour la détection des changements de valeur TEXT(PRIORVALUE(...)) */
                if (newAccount.premiereSource__c == null && newAccount.accountSource != null) {
                    newAccount.premiereSource__c = newAccount.accountSource;
                }
                if (newAccount.premiereSourceCall__c == null && newAccount.accountCallSource__c != null) {
                    newAccount.premiereSourceCall__c = newAccount.accountCallSource__c;
                }
                if (oldAccount != null && newAccount.accountSource != oldAccount.accountSource) {
                    newAccount.nbSources__c = (newAccount.nbSources__c == null ? 0 : newAccount.nbSources__c) + 1;
                }
                if (oldAccount != null && newAccount.accountCallSource__c != oldAccount.accountCallSource__c) {
                    newAccount.nbSourcesCall__c = (newAccount.nbSourcesCall__c == null ? 0 : newAccount.nbSourcesCall__c) + 1;
                }

                /* UR001_K2_Account_Owner = Affectation du propriétaire
                    # Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur un utilisateur */
                if (Trigger.isUpdate && newAccount.OwnerId == oldAccount.OwnerId) {
                    /** F.G., le 19/09/2013
                    if (currentUserContext.isSaleUser())
                        newAccount.ownerId = currentUserContext.getUser().Id;
                    **/
                    newAccount.publicsharing__c = false;
                }

                /* UR001_K2_Account_LastModifyByCall = Dernière modification par call
                    UR001_K2_Account_LastModifyBySale = Dernière modification par vente
                    # Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur un utilisateur */
                if (currentUserContext != null && currentUserContext.isCallUser()) {
                    newAccount.lastModifiedByCall__c = currentUserContext.getUser().id;
                }
                if (currentUserContext != null && currentUserContext.isSaleUser()) {
                    newAccount.lastModifiedBySale__c = currentUserContext.getUser().id;
                }

                //* UR001_K2_Account_ExchangePhones 
                Boolean enFrance = false;
                if (newAccount.IsPersonAccount) {
                    enFrance = isInFrance(newAccount.PersonMailingCountry);
                } else {
                    enFrance = isInFrance(newAccount.BillingCountry); 
                }
                        
                if (oldAccount == null || newAccount.PersonHomePhone != oldAccount.PersonHomePhone) {
                    newAccount.PersonHomePhone = convertPhone(newAccount.PersonHomePhone, enFrance);
                }
                if (oldAccount == null || newAccount.PersonMobilePhone != oldAccount.PersonMobilePhone) {
                    newAccount.PersonMobilePhone = convertPhone(newAccount.PersonMobilePhone, enFrance);
                }
                if (oldAccount == null || newAccount.PersonOtherPhone != oldAccount.PersonOtherPhone) {
                    newAccount.PersonOtherPhone = convertPhone(newAccount.PersonOtherPhone, enFrance);
                }
                if (oldAccount == null || newAccount.Phone != oldAccount.Phone) {
                    newAccount.Phone = convertPhone(newAccount.Phone, enFrance);
                }
                if (oldAccount == null || newAccount.Fax != oldAccount.Fax) {
                    newAccount.Fax = convertPhone(newAccount.Fax, enFrance);
                }

                if (newAccount.IsPersonAccount && (oldAccount                    == null                         ||
                                                    newAccount.PersonHomePhone   != oldAccount.PersonHomePhone   ||
                                                    newAccount.PersonMobilePhone != oldAccount.PersonMobilePhone ||
                                                    newAccount.PersonOtherPhone  != oldAccount.PersonOtherPhone)) {
                    String homePhone   = newAccount.PersonHomePhone;
                    String mobilePhone = newAccount.PersonMobilePhone;
                    if (isInFrance(newAccount.PersonMailingCountry)) {
                        if (!String.isBlank(homePhone) && (homePhone.startsWith('06') || homePhone.startsWith('07') || homePhone.startsWith('+336') || homePhone.startsWith('+337')) && String.isBlank(mobilePhone)) {
                            newAccount.PersonMobilePhone = homePhone;
                            newAccount.PersonHomePhone   = null;
                        }
                        else if (!String.isBlank(mobilePhone) && (!mobilePhone.startsWith('06') && !mobilePhone.startsWith('07') && !mobilePhone.startsWith('+336') && !mobilePhone.startsWith('+337')) && String.isBlank(homePhone)) {
                            newAccount.PersonMobilePhone = null;
                            newAccount.PersonHomePhone   = mobilePhone;
                        }
                        else if (!String.isBlank(homePhone) && !String.isBlank(mobilePhone) && (homePhone.startsWith('06') || homePhone.startsWith('07') || homePhone.startsWith('+336') || homePhone.startsWith('+337')) && (!mobilePhone.startsWith('06') && !mobilePhone.startsWith('07') && !mobilePhone.startsWith('+336') && !mobilePhone.startsWith('+337'))) {
                            newAccount.PersonHomePhone = mobilePhone;
                            newAccount.PersonMobilePhone = homePhone;
                        }
                        else {
                            newAccount.PersonHomePhone = homePhone;
                            newAccount.PersonMobilePhone = mobilePhone;
                        }
                    }
                    else {
                        newAccount.PersonHomePhone = homePhone;
                        newAccount.PersonMobilePhone = mobilePhone;
                    }
                }

                //* Conversion téléphone au format international
                if (Trigger.isInsert || Trigger.isUpdate) {
                    String mobilePhone = (String.isBlank(newAccount.telephoneMobile__c)) ? newAccount.PersonMobilePhone : newAccount.telephoneMobile__c; 
                    newAccount.mobilePhoneInternational__c = convertPhoneInternational(mobilePhone, enFrance);
                }

                //* Traitment de l'alimentation du opt-out par un système externe (ex: ExactTarget) 
                if (newAccount.IsPersonAccount && newAccount.personDoNotCall && (oldAccount == null || newAccount.personDoNotCall != oldAccount.personDoNotCall) 
                    && (String.isBlank(newAccount.fichiersOpposition__c) || !newAccount.fichiersOpposition__c.containsIgnoreCase('K par K'))) 
                {
                    if (String.isBlank(newAccount.fichiersOpposition__c)) {
                        newAccount.fichiersOpposition__c = 'K par K';
                    } else {
                        newAccount.fichiersOpposition__c += 'K par K';
                    }
                }

                //* UR001_K2_Account_Opposition & UR001_K2_Account_optinXXXXX 
                if (newAccount.IsPersonAccount && (oldAccount                        == null                             ||
                    newAccount.fichiersOpposition__c != oldAccount.fichiersOpposition__c ||
                    newAccount.PersonEmail           != oldAccount.PersonEmail           ||
                    newAccount.PersonHomePhone       != oldAccount.PersonHomePhone       ||
                    newAccount.PersonMobilePhone     != oldAccount.PersonMobilePhone)) 
                {
                    String fichiers = ';' + newAccount.fichiersOpposition__c + ';';
                    Boolean oppTotale = fichiers.containsIgnoreCase('CNIL') || fichiers.containsIgnoreCase('K par K');
                    Boolean oppTelephone = fichiers.containsIgnoreCase('Pacitel') || fichiers.containsIgnoreCase('Bloctel');                
                    Boolean emailDisabled = String.isBlank(newAccount.PersonEmail);
                    Boolean homePhoneDisabled = String.isBlank(newAccount.PersonHomePhone);
                    Boolean mobilePhoneDisabled = String.isBlank(newAccount.PersonMobilePhone);
                    Boolean isClient = (newAccount.Type == 'Client' || newAccount.Type == 'Ex-client');

                    // optinAdresseEmailXXXXX__c
                    if (!isClient && (oppTotale || emailDisabled)) {
                        newAccount.optinAdresseEmailKparK__c      = false;
                        newAccount.optinAdresseEmailPartenaire__c = false;
                    }
                    // Par défaut optin coché. Donc, en cas de modification de valeur si l'optin était déjà décochée alors on recoche
                    else if (isClient && !emailDisabled && Trigger.isUpdate && newAccount.PersonEmail != oldAccount.PersonEmail 
                        && !newAccount.optinAdresseEmailKparK__c && !oldAccount.optinAdresseEmailKparK__c) {
                        newAccount.optinAdresseEmailKparK__c = true;
                    }

                    // optinTelephoneDomicileXXXXX__c
                    if (!isClient && (oppTotale || oppTelephone || homePhoneDisabled)) {
                        newAccount.optinTelephoneDomicileKparK__c      = false;
                        newAccount.optinTelephoneDomicilePartenaire__c = false;
                    }
                    // Par défaut optin coché. Donc, en cas de modification de valeur si l'optin était déjà décochée alors on recoche
                    else if (isClient && !homePhoneDisabled && Trigger.isUpdate && newAccount.PersonHomePhone != oldAccount.PersonHomePhone 
                        && !newAccount.optinTelephoneDomicileKparK__c && !oldAccount.optinTelephoneDomicileKparK__c) {
                        newAccount.optinTelephoneDomicileKparK__c = true;
                    }

                    // optinSMSXXXXX__c
                    if (!isClient && (oppTotale || oppTelephone || mobilePhoneDisabled)) {
                        newAccount.optinTelephoneMobileKparK__c      = false;
                        newAccount.optinTelephoneMobilePartenaire__c = false;
                        newAccount.optinSMSKparK__c                  = false;
                        newAccount.optinSMSPartenaire__c             = false;
                    }
                    // Par défaut optin coché. Donc, en cas de modification de valeur si l'optin était déjà décochée alors on recoche
                    else if (isClient && !mobilePhoneDisabled && Trigger.isUpdate && newAccount.PersonMobilePhone != oldAccount.PersonMobilePhone) {
                        if (!newAccount.optinTelephoneMobileKparK__c && !oldAccount.optinTelephoneMobileKparK__c) {
                            newAccount.optinTelephoneMobileKparK__c = true;
                        }
                        if (!newAccount.optinSMSKparK__c && !oldAccount.optinSMSKparK__c) {
                            newAccount.optinSMSKparK__c = true;
                        }
                    }

                    newAccount.PersonHasOptedOutOfEmail = !newAccount.optinAdresseEmailKparK__c;
                    newAccount.PersonDoNotCall = !(newAccount.optinTelephoneDomicileKparK__c || newAccount.optinTelephoneMobileKparK__c);
                }

                //* UR001_K2_ChangeEmailParrain  
                if(String.isNotBlank(newAccount.parrain__c) && parrainMap.get(newAccount.parrain__c) != null) {
                    // on met a jour l'email parrain dans les comptes filleuls
                    newAccount.emailParrain__c = parrainMap.get(newAccount.parrain__c).email__c;
                }
            }
            newAccount.owner__c = newAccount.ownerId;
        }

        System.debug('### FIN TR020_Account.applyDataUpdateRules');
    }

    /**
    * @description Méthode permettant de modifier le RecordType des comptes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyRTUpdateRules(UserContext userContext) {
        /** A - Initialisation des données intermédiaires **/
        List<Account> newAccounts = (List<Account>)Trigger.new;

        /** B - Application des règles de mise à jour **/
        for (Account newAccount : newAccounts) {
            if (newAccount.RecordTypeId != ENTITY_RTID && newAccount.IsPersonAccount && newAccount.PersonEmail != null 
                    && newAccount.PersonEmail.startsWith('contact.ccm.depot.') && newAccount.PersonEmail.endsWith('@kpark.fr')) 
            {
                newAccount.RecordTypeId = ENTITY_RTID;
            }
        }
    }

    /**
    * @description Méthode permettant de modifier le type des comptes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        /** A - Initialisation des données intermédiaires **/
        List<Account> newAccounts = (List<Account>)Trigger.new;

        /** B - Application des règles de mise à jour **/
        for (Account newAccount : newAccounts) {
            Boolean isCustomerRT = (newAccount.RecordTypeId == ENTITY_RTID || newAccount.RecordTypeId == PROVIDER_RTID 
                                    || newAccount.RecordTypeId == EXRESOURCE_RTID || newAccount.RecordTypeId ==FUNDINGORG_RTID) ? false : true;
            /* UR001_K2_Account_Type = Calcul du type/statut du compte
                # Impossible avec WORKFLOW car Salesforce ne permet que d'affecter en dur une valeur spécifique
                    sinon il aurait fallu définir un workflow avec chaque cas comme condition d'entrée =>
                            - Trop de paramétrage par rapport au développement
                            - Consomme trop de Workflows (limité à 50)
                            - Pas de prioritisation des workflows (exécution en parallèle). Il aurait donc fallu que les conditions d'entrée d'1 seul workflow soit ses propres conditions plus l'exclusion des conditions de tous les autres statuts : Impossible car limité à 5 conditions simples */
            if(isCustomerRT) {
                if (newAccount.forcageType__c != null) {
                    newAccount.type = newAccount.forcageType__c;
                } else if ((newAccount.nbTotalContrats__c > 0 && newAccount.nbTotalContrats__c == newAccount.nbContratsResilies__c)
                        || (newAccount.customerOrderCount__c > 0 && newAccount.customerOrderCount__c == newAccount.customerOrderCanceledCount__c)) {
                    newAccount.type = 'Ex-client';
                } else if (newAccount.nbTotalContrats__c > 0 || newAccount.customerOrderCount__c > 0) {
                    newAccount.type = 'Client';
                } else if (newAccount.nbRDVDevisables__c > 0 || newAccount.quoteCount__c > 0 || newAccount.SBQQQuoteCount__c > 0) {
                    newAccount.type = 'Prospect';
                } else if (newAccount.nbTotalRDV__c > 0) {
                    newAccount.type = 'Contact';
                } else if (newAccount.nbTotalProjets__c > 0) {
                    newAccount.type = 'Pré-contact';
                } else {
                    newAccount.type = 'Piste';
                }
            }
        }
    }

    /**
    * @description Méthode asynchrone permettant de modifier les différents champs des comptes
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyAsyncUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Account.applyAsyncUpdateRules');

        if (!Trigger.isExecuting)
            return;

        /** A - Initialisation des données intermédiaires **/
        List<Account> newAccounts = (List<Account>)Trigger.new;
        Map<Id, Account>  oldAccounts = (Map<Id, Account>)Trigger.oldMap;
        Boolean geoEnabled = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false);
        Boolean optoutEnabled = PropertiesUtils.getBooleanValue('optout.files.enabled', false);
        List<Account> geoAccounts = new List<Account>();
        List<Account> optoutAccounts = new List<Account>();
        List<Account> passwordInsertAccounts = new List<Account>();
        List<Account> passwordUpdateAccounts = new List<Account>();

        for (Account newAccount : newAccounts) {
            if (!AlreadyUsed.isUsed('TR020_Account.applyAsyncUpdateRules', newAccount.id)) {
                System.debug('## Id : '+newAccount.id);
                Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);

                if(geoEnabled) {
                    // Géocodage
                    Boolean adresseGeocodable = ((newAccount.IsPersonAccount) && (!String.isBlank(newAccount.PersonMailingPostalCode) || !String.isBlank(newAccount.personMailingCity)))
                                                ||
                                                ((!newAccount.IsPersonAccount) && (!String.isBlank(newAccount.BillingPostalCode) || !String.isBlank(newAccount.billingCity)));
                    Boolean adresseModifiee = Trigger.isInsert ? true
                                                : ((newAccount.IsPersonAccount)
                                                && isInFrance(newAccount.PersonMailingCountry)
                                                && (newAccount.personMailingStreet != oldAccount.personMailingStreet || newAccount.PersonMailingPostalCode != oldAccount.PersonMailingPostalCode || newAccount.personMailingCity != oldAccount.personMailingCity || newAccount.PersonMailingCountry != oldAccount.PersonMailingCountry || newAccount.Localisation__Longitude__s != oldAccount.Localisation__Longitude__s || newAccount.Localisation__Latitude__s != oldAccount.Localisation__Latitude__s))
                                                ||
                                                ((!newAccount.IsPersonAccount)
                                                && isInFrance(newAccount.BillingCountry)
                                                && (newAccount.billingStreet != oldAccount.billingStreet || newAccount.BillingPostalCode != oldAccount.BillingPostalCode || newAccount.billingCity != oldAccount.billingCity || newAccount.BillingCountry != oldAccount.BillingCountry || newAccount.Localisation__Longitude__s != oldAccount.Localisation__Longitude__s || newAccount.Localisation__Latitude__s != oldAccount.Localisation__Latitude__s));

                    System.debug('## adresseGeocodable : ' + adresseGeocodable);
                    System.debug('## adresseModifiee : ' + adresseModifiee);
                    
                    if (adresseGeocodable &&
                            ((Trigger.isInsert && String.isBlank(newAccount.iris__c)) // Condition String.isBlank(newAccount.iris__c) nécéssaire afin de ne pas écraser un géocodage manuel
                            ||
                            String.isBlank(newAccount.iris__c)
                            ||
                            (Trigger.isUpdate && adresseModifiee && (System.isBatch() || String.isBlank(newAccount.methodeGeocodage__c) || 'Batch'.equalsIgnoreCase(newAccount.methodeGeocodage__c))))) 
                    {
                        System.debug('## Géocodage : ' + newAccount.Id);
                        geoAccounts.add(newAccount);
                    }
                }

                // Vérification oppositions démarchages
                if (oldAccount == null || newAccount.PersonHomePhone != oldAccount.PersonHomePhone
                                        || newAccount.PersonMobilePhone != oldAccount.PersonMobilePhone
                                        || newAccount.PersonOtherPhone != oldAccount.PersonOtherPhone
                                        || newAccount.phone != oldAccount.phone
                                        || newAccount.fax != oldAccount.fax) 
                {
                    optoutAccounts.add(newAccount);
                }

                // Espace client
                if (userContext != null && !userContext.canByPassTrigger('QA_GenerateAccountPassword') && !Test.isRunningTest()) {
                    if (!AlreadyUsed.isUsed('QA_GenerateAccountPassword.execute', newAccount.id)) {        
                        if (Trigger.isInsert && newAccount.RecordTypeId != ENTITY_RTID && newAccount.RecordTypeId != PROVIDER_RTID && newAccount.RecordTypeId != FUNDINGORG_RTID) {
                            System.debug('## ESPACE CLIENT >>> création mot de passe du compte : ' + newAccount.AccountNumber + ' ' + newAccount.Id);
                            passwordInsertAccounts.add(newAccount);
                        }
                        if (Trigger.isUpdate && newAccount.type == 'Client' && ((oldAccount.type != 'Client' && oldAccount.type != 'Ex-client'))) {
                            System.debug('## ESPACE CLIENT >>> envoi email au compte : ' + newAccount.AccountNumber + ' ' + newAccount.Id);
                            passwordUpdateAccounts.add(newAccount);
                        }
                    }
                }
            }
        }

        /** B - Application des règles de mise à jour asynchrone **/
        if (geoEnabled && !geoAccounts.isEmpty()) {
            GeoUtils.updateAccounts(geoAccounts);
        }
        if (optoutEnabled && !optoutAccounts.isEmpty()) {
            OptoutUtils.updateAccounts(optoutAccounts);
        }
        if(!passwordInsertAccounts.isEmpty() && !(System.isBatch() || System.isFuture())) {
            ID jobID = System.enqueueJob(new QA_GenerateAccountPassword(passwordInsertAccounts, false, true, false));
            System.debug('## ID Job Génération mot de passe 1 : ' + jobID);
        }
        if(!passwordUpdateAccounts.isEmpty() && !(System.isBatch() || System.isFuture())) {
            Boolean enablePasswordEmail = (PropertiesUtils.getBooleanValue('espaceclient.email.password', false)) ? true : false;
            ID jobID = System.enqueueJob(new QA_GenerateAccountPassword(passwordUpdateAccounts, enablePasswordEmail, true, false));
            System.debug('## ID Job Génération mot de passe 2 : ' + jobID);
        }
        System.debug('### FIN TR020_Account.applyAsyncUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de gestion des entités
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyEntitiesRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Account.applyEntitiesRules');
        Map<Id, Account> oldAccounts = (Map<Id, Account>)Trigger.oldMap;
        List<Account> createEntityRecords = new List<Account>();     
        List<Account> updateEntityRecords = new List<Account>();

        for (Account newAccount : (List<Account>)Trigger.new) {
            Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);
            
            if (Trigger.isAfter && Trigger.isInsert && newAccount.RecordTypeId == ENTITY_RTID) {   
                // Création des enregistrements    
                createEntityRecords.add(newAccount);
            }
                    
            // Mise à jour des enregistrements liés
            if (Trigger.isAfter && Trigger.isUpdate && newAccount.RecordTypeId == ENTITY_RTID
                && oldAccount != null && (oldAccount.Name != newAccount.Name ||
                                            oldAccount.BillingStreet != newAccount.BillingStreet ||
                                            oldAccount.BillingPostalCode != newAccount.BillingPostalCode ||
                                            oldAccount.BillingCity != newAccount.BillingCity ||
                                            oldAccount.BillingCountry != newAccount.BillingCountry ||
                                            oldAccount.emailPro__c != newAccount.emailPro__c ||
                                            oldAccount.isActive__c != newAccount.isActive__c ||
                                            oldAccount.startDate__c != newAccount.startDate__c ||
                                            oldAccount.endDate__c != newAccount.endDate__c ||
                                            oldAccount.Localisation__Latitude__s != newAccount.Localisation__Latitude__s ||
                                            oldAccount.Localisation__Longitude__s != newAccount.Localisation__Longitude__s ||
                                            oldAccount.Phone != newAccount.Phone)) 
                                                    
            {
                updateEntityRecords.add(newAccount);
            }
        }

        // Création des objets relatif à l'entité
        if(!createEntityRecords.isEmpty()) {
            TR022_Account.createEntityRecords(createEntityRecords);
        }
        // Mise à jour des objets relatif à l'entité
        if(!updateEntityRecords.isEmpty()) {
            TR022_Account.updateEntityRecords(updateEntityRecords);
        }
        System.debug('### FIN TR020_Account.applyEntitiesRules');
    }

    /**
    * @description Fonction pour convertir un numéro de téléphone selon le format français
    * @param phone Numéro de téléphone à convertir
    * @param enFrance Numéro en France
    */
    private static String convertPhone(String phone, Boolean enFrance) {
        System.debug('## convertPhone: ' + phone + ' (France : ' + enFrance + ')');
        if (String.isBlank(phone)) {
            return '';
        }

        String convertedPhone = '';

        for (Integer i = 0; i < phone.length(); i++) {
            String s = phone.substring(i, i + 1).toUpperCase();
            
            System.debug('## convertPhone: ' + phone + '[' + i + '] = ' + s);

            if (s >= '0' && s <= '9') {
                convertedPhone += s;
            } else if (s >= 'A' && s <= 'C') {
                convertedPhone += '2';
            } else if (s >= 'D' && s <= 'F') {
                convertedPhone += '3';
            } else if (s >= 'G' && s <= 'I') {
                convertedPhone += '4';
            } else if (s >= 'J' && s <= 'L') {
                convertedPhone += '5';
            } else if (s >= 'M' && s <= 'O') {
                convertedPhone += '6';
            } else if (s >= 'P' && s <= 'S') {
                convertedPhone += '7';
            } else if (s >= 'T' && s <= 'V') {
                convertedPhone += '8';
            } else if (s >= 'W' && s <= 'Z') {
                convertedPhone += '9';
            } else if (s == '+' && i == 0) {
                convertedPhone += s;
            }
        }
        if (enFrance) {
            convertedPhone = '0' + convertedPhone.right(9);
        }

        System.debug('## convertPhone: ' + phone + ' -> ' + convertedPhone);
        return convertedPhone;
    }

    /**
    * @description Fonction pour convertir un numéro de téléphone selon le format international (avec code pays)
    * @param phone Numéro de téléphone à convertir
    * @param enFrance Numéro en France
    */
    private static String convertPhoneInternational(String phone, Boolean enFrance) {
        System.debug('## convertPhoneInternational: ' + phone + ' (France : ' + enFrance + ')');
        if (String.isBlank(phone)) {
            return '';
        }

        String convertedPhone = '';
        if (phone.startsWith('+')) {
            convertedPhone = phone;
        } else if(enFrance) {
            convertedPhone = '+33' + phone.right(9);
        }

        System.debug('## convertPhoneInternational: ' + phone + ' -> ' + convertedPhone);
        return convertedPhone;
    }

    /**
    * @description Vérifie si le nom et prénom du compte ne comporte pas des caractère interdit, exécute une erreur si oui
    * @param account Compte à vérifier
    */
    private static void checkName(Account account) {
        if (account.IsPersonAccount) {
            Pattern namePattern = Pattern.compile('(?:\\bei\\b|\\bEI\\b|\\beirl\\b|\\bEIRL\\b|\\beurl\\b|\\bEURL\\b|'+
                '\\bgie\\b|\\bGIE\\b|\\bsa\\b|\\bSA\\b|\\bsarl\\b|\\bSARL\\b|\\bsas\\b|\\bSAS\\b|\\bsasu\\b|\\bSASU\\b|'+
                '\\bsca\\b|\\bSCA\\b|\\bsci\\b|\\bSCI\\b|\\bscm\\b|\\bSCM\\b|\\bscop\\b|\\bSCOP\\b|\\bscp\\b|\\bSCP\\b|\\bscs\\b|\\bSCS\\b|\\bsel\\b|\\bSEL\\b|\\bselarl\\b|\\bSELARL\\b|'+
                '\\bsnc\\b|\\bSNC\\b|\\bsoc\\b|\\bSOC\\b|\\bsociete\\b|\\bSOCIETE\\b|\\bsocieté\\b\\bass\\b|\\bASS\\b|\\bassoc\\b|\\bASSOC\\b|\\bassociation\\b|\\bASSOCIATION\\b)');
            if (String.isNotBlank(account.FirstName) && !account.FirstName.containsAny(CHECK_LETTER)) {
                account.FirstName.addError('Prénom du compte personnel invalide (au moins une lettre est requise) !');
            }
            if (!TESTING && String.isNotBlank(account.FirstName) && account.FirstName.containsAny(CHECK_OTHER)) {
                account.FirstName.addError('Prénom du compte personnel invalide (chiffre ou caractère spécial interdit) !');
            }
            if (String.isNotBlank(account.LastName) && !account.LastName.containsAny(CHECK_LETTER)) {
                account.LastName.addError('Nom du compte personnel invalide (au moins une lettre est requise) !');
            }
            if (!TESTING && String.isNotBlank(account.LastName) && account.LastName.containsAny(CHECK_OTHER)) {
                account.LastName.addError('Nom du compte personnel invalide (chiffre ou caractère spécial interdit) !');
            }
            // 13/10/2022 JMU Limite due à la migration Kube3 :
            DateTime kube_date = DateTime.newInstance(2022, 10, 12, 0, 0, 0);
            if(String.isNotBlank(account.FirstName) && namePattern.matcher(account.FirstName).find() &&
            account.CreatedDate >= kube_date) {
                account.FirstName.addError('Utilisation d\'un mot réservé aux comptes professionnels. Le type de compte semble invalide (utilisation d\'un compte personnel (B2C) au lieu d\'un compte professionnel (B2B))!'); 
            }
            if(String.isNotBlank(account.LastName) && namePattern.matcher(account.LastName).find() &&
            account.CreatedDate >= kube_date) {
                account.LastName.addError('Utilisation d\'un mot réservé aux comptes professionnels. Le type de compte semble invalide (utilisation d\'un compte personnel (B2C) au lieu d\'un compte professionnel (B2B))!');  
            }
        }
        else {
            if (String.isNotBlank(account.name) && !account.name.containsAny(CHECK_LETTER)) {
                account.name.addError('Nom du compte professionnel invalide (au moins une lettre est requise) !');
            }
        }
    }

    /**
    * @description Vérifie si la valeur dans le champ pays est en France
    * @param country Ville à vérifier
    * @return Boolean Vrai si le pays est France
    */
    private static Boolean isInFrance(String country) {
        return String.isBlank(country) || 'F'.equalsIgnoreCase(country) || 'FR'.equalsIgnoreCase(country) || 'FRA'.equalsIgnoreCase(country) || 'FRANCE'.equalsIgnoreCase(country);
    }
    
}