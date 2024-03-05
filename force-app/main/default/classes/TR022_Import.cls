//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Import
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/09/2023
//-- Version     : 3.1
//-- * 3.1 - Gestion des pergolas + carport au niveau national --> envoi vers Odigo
//-- * 3.0 - Gestion des pergolas + carport
//-- * 2.9 - Gestion des pergolas + carport
//-- * 2.8 - Ajout de vendeur recommandé
//-- * 2.7 - Ajout de l'isolation des combles
//-- * 2.6 - RQM-74 : Ajout de la copie de la valeur GCLID
//-- * 2.5 - RQM-34 : Evolution pour type de dotation filleul
//-- * 2.4 - FGO : Ajout fichier source et id interne fournisseur sur les projets
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Import {
    private static final DAteTime   ABORT_DT                     = DateTime.newInstanceGmt(1900, 1, 1, 12, 0, 0);
    private static final Date       TODAY                        = System.today();
    private static final String     DEFAULT_SOURCE               = 'WEB';
    private static final Integer    MAX_NAME_LENGTH              = 80;
    private static final Boolean    FORCE_OPPORTUNITY            = PropertiesUtils.getBooleanValue('import.opportunity.force', true);
    /* >>> F.G., le 20/03/2017 - Désactivation lors de la création du dictionaire DQE */
    private static final Boolean    DEVERSEMENT_ENABLED          = PropertiesUtils.getBooleanValue('import.deversement.enabled', true);
    /* <<< F.G., le 20/03/2017 - Désactivation lors de la création du dictionaire DQE */
    private static final String     FIELD_EXCEPTION              = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
    private static final Integer    EVENT_DURATION               = PropertiesUtils.getIntegerValue('import.event.duration', 120);
    private static final Integer    MODIFICATION_PERIOD_DURATION = PropertiesUtils.getIntegerValue('import.modification.duration', 30);

    private static final List<User>       USER_INTERFACE               = [SELECT id FROM User WHERE name = 'Interface API'];
    private static final List<ReferentielOperation__c> OPERATION_FOIRE = [SELECT id, name, dateDebut__c, dateFin__c, surfaceDuStand__c 
                                                                    FROM ReferentielOperation__c
                                                                    WHERE dateDebut__c <= TODAY
                                                                      AND dateFin__c >= TODAY
                                                                      AND origine__c = 'FOIRE'
                                                                      AND surfaceDuStand__c like 'HC%'
                                                                    LIMIT 1]; /* Pas de Gx car on veut uniquement les grandes foires */
                                                        
    private static final Id RT_ACTIVITE_COMMERCIALE = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id RT_IMPORT_EXTERNE = DAL.getRecordTypeIdByDevName('Import__c',Constants.RT_IMPORT_EXTERNE);
    private static final Id RT_FICHE_CONTACT = DAL.getRecordTypeIdByDevName('Import__c',Constants.RT_IMPORT_CONTACT);
    private static final Id RT_COMPTE_PERSO = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_PERSO_RT);

    /**
    * @description Méthode principale pour traiter tous les enregistrements de l'objet Import__c
    * @param userContext Contexte de l'utilisateur courant
    */ 
    public static void import(UserContext userContext) {
        system.debug('#### START import');
        if (!Trigger.isExecuting || Trigger.isDelete || Trigger.isAfter)
            return;
        /* >>> F.G., le 20/03/2017 - Désactivation lors de la création du dictionaire DQE */
        if (!DEVERSEMENT_ENABLED)
            return;
        /* <<< F.G., le 20/03/2017 - Désactivation lors de la création du dictionaire DQE */

        // *********************************************************************
        // * INITIALISATION DES DONNEES                                        *
        // *********************************************************************
        // Définition des structures de données
        List<Import__c>             items       = new List<Import__c>();        

        // Détermination des items à prendre en compte
        for(Import__c item : (List<Import__c>)Trigger.new) {
            if (item.RecordTypeId == RT_IMPORT_EXTERNE && Trigger.isInsert && !USER_INTERFACE.isEmpty()) {
                item.OwnerId = USER_INTERFACE[0].id;
            }
              
            if (item.integrable__c != null && item.integrable__c == true) {                        
                if (((item.RecordTypeId == null || item.RecordTypeId == RT_IMPORT_EXTERNE) && item.dateIntegration__c == null) || (item.RecordTypeId == RT_FICHE_CONTACT)) {
                    item.journalIntegration__c += '\n[' + System.now() + '] Erreur avant déversement des IMPORT__C\n - ' + item.messageException__c + '\n - ' + item.classeException__c;

                    item.messageException__c = null;
                    item.classeException__c  = null;
                    items.add(item);
                }
            }
        }  
          
        if (items.isEmpty())
            return;
        
        Map<String, Account> parrains = new Map<String, Account>();  
        Account[]     comptes     = new Account[items.size()];        
        Chantier__c[] chantiers   = new Chantier__c[items.size()];        
        Opportunity[] projets     = new Opportunity[items.size()];        
        Event[]       rendezVous  = new Event[items.size()];
        Integer       nbRDV       = 0;        

        // Récupération des données
        initData(items, comptes, chantiers, projets, rendezVous, parrains);
        
        // *********************************************************************
        // * ALIMENTATION DES DONNEES                                          *
        // *********************************************************************
        if (Trigger.isInsert) {
            Integer index = 0;
            for(Import__c item : items) {
                if (item.integrable__c != null && item.integrable__c == true) {
                    Account     compte   = getOrCreateCompte(userContext, item, comptes[index]);
                    Chantier__c chantier = getOrCreateChantier(userContext, item, chantiers[index]);
                    Opportunity projet   = getOrCreateProjet(userContext, item, projets[index]);
                    Event       RDV      = getOrCreateRendezVous(userContext, item, rendezVous[index]);

                    compte   = buildCompte(userContext, compte, item, parrains);
                    comptes[index] = compte;

                    if (chantier != null) {
                        chantier = buildChantier(userContext, chantier, item);
                        chantiers[index] = chantier;
                    }

                    if (projet != null) {
                        projet   = buildProjet(userContext, projet, item);
                        projets[index] = projet;
                    }

                    if (RDV != null) {
                        RDV = buildRendezVous(userContext, RDV, item);
                        rendezVous[index] = RDV;
                        nbRDV++;
                    }
                }            
                index++;            
            }  
        } else { // Trigger.isUpdate
            Integer index = 0;
            for(Import__c item : items) {
                if (item.integrable__c != null && item.integrable__c == true) {
                    Account     compte   = getOrCreateCompte(userContext, item, comptes[index]);
                    Chantier__c chantier = getOrCreateChantier(userContext, item, chantiers[index]);
                    Opportunity projet   = getOrCreateProjet(userContext, item, projets[index]);
                    Event       RDV      = getOrCreateRendezVous(userContext, item, rendezVous[index]);

                    String error = checkModification(item, compte, chantier, projet, RDV);
                    if (error != null && !String.isEmpty(error)) {
                        item.messageException__c = error;
                        item.addError(error);                
                    } else {
                        compte   = buildCompte(userContext, compte, item, parrains);
                        comptes[index] = compte;
  
                        if (chantier != null) {
                            chantier = buildChantier(userContext, chantier, item);
                            chantiers[index] = chantier;
                        }
  
                        if (projet != null) {
                            projet   = buildProjet(userContext, projet, item);
                            projets[index] = projet;
                        }
  
                        if (RDV != null) {
                            RDV = buildRendezVous(userContext, RDV, item);
                            rendezVous[index] = RDV;
                            nbRDV++;
                        }
                    }
                }
                index++;
            }  
        }
        
        // *********************************************************************
        // * SAUVEGARDE DES DONNEES                                            *
        // *********************************************************************
        // Enregistrements des comptes   
        System.debug('### SAVE COMPTE >>> ' + comptes);     
        Database.UpsertResult[] compteResults = Database.upsert(comptes, false);
        
        Map<ID, Account> updatedComptes = new Map<ID, Account>([SELECT id, LastModifiedDate FROM Account WHERE id IN :comptes]);
        Map<ID, ID>      contacts       = new Map<ID, ID>();
        if (nbRDV > 0) {
            for (Contact contact : [SELECT id, accountId FROM Contact WHERE accountId != null AND accountId IN :comptes])
                contacts.put(contact.accountId, contact.id);
        }

        Integer index = 0;
        for(Import__c item : items) {
            if (item.integrable__c != null && item.integrable__c == true) {
                Database.UpsertResult result   = compteResults[index];
                Account               compte   = comptes[index];
                Chantier__c           chantier = chantiers[index];
                Opportunity           projet   = projets[index];
                Event                 RDV      = rendezVous[index];
            
                if (result.isSuccess()) {
                    item.versioningCompte__c = getVersion(updatedComptes.get(compte.id).LastModifiedDate);
                    item.compte__c = compte.id;
                    item.journalIntegration__c += '\n[' + System.now() + '] Déversement des comptes OK';
                    if (projet != null)
                        projet.accountId = compte.id;
                    if (RDV != null)
                        RDV.whoId = contacts.get(compte.id);                  
                    if (chantier != null) {
                        if (item.locataire__c == null || !item.locataire__c) {
                            chantier.proprietaire__c = compte.id;
                            chantier.locataire__c = null;
                        } else {
                            chantier.proprietaire__c = null;
                            chantier.locataire__c = compte.id;
                        }  
                    }
                    //ajout à l'update etape2 QTS
                    if (projet != null)
                        projet.accountId = compte.id;
                } else {
                    item.messageException__c = getSimpleExceptionMessage(result.getErrors()[0].getMessage()).left(255);
                    item.classeException__c  = ('ACCOUNT : ' + result.getErrors()[0].getStatusCode()).left(255);
                    
                    item.journalIntegration__c += '\n[' + System.now() + '] Erreur lors du déversement des comptes\n - ' + item.messageException__c + '\n - ' + item.classeException__c;
  
                    // Suppression des chantiers, projets & rendez-vous afin de pas les prendre en compte lors de l'enregistrement des données
                    chantiers[index] = null;
                    projets[index] = null;
                    rendezVous[index] = null;
                }
            }
            index++;
        }                             

        // Enregistrements des chantiers
        List<Chantier__c> chantiersToUpdate = new List<Chantier__c>();
        index = 0;
        for(Import__c item : items) {
            if (item.integrable__c != null && item.integrable__c == true && chantiers[index] != null)
                chantiersToUpdate.add(chantiers[index]);
            index++;
        }
        if (!chantiersToUpdate.isEmpty()) {
            Database.UpsertResult[] chantierResults = Database.upsert(chantiersToUpdate, false);
            Map<ID, Chantier__c> updatedChantiers = new Map<ID, Chantier__c>([SELECT id, LastModifiedDate FROM Chantier__c WHERE id IN :chantiersToUpdate]);

            index = 0;
            Integer resultIndex = 0;
            for(Import__c item : items) {
                if (item.integrable__c != null && item.integrable__c == true && chantiers[index] != null) {
                    Database.UpsertResult result   = chantierResults[resultIndex++];
                    Account               compte   = comptes[index];
                    Chantier__c           chantier = chantiers[index];
                    Opportunity           projet   = projets[index];
                    Event                 RDV      = rendezVous[index];
              
                    if (result.isSuccess()) {
                        item.versioningChantier__c = getVersion(updatedChantiers.get(chantier.id).LastModifiedDate);
                        item.chantier__c = chantier.id;

                        item.journalIntegration__c += '\n[' + System.now() + '] Déversement des chantiers OK';

                        if (projet != null)
                            projet.chantier__c = chantier.id;                    
                        //ajout à l'update etape2 QTS
                        if (projet != null)
                            projet.chantier__c = chantier.id;
                    } else {
                        item.messageException__c = getSimpleExceptionMessage(result.getErrors()[0].getMessage()).left(255);
                        item.classeException__c  = ('CHANTIER : ' + result.getErrors()[0].getStatusCode()).left(255);

                        item.journalIntegration__c += '\n[' + System.now() + '] Erreur lors du déversement des chantiers\n - ' + item.messageException__c + '\n - ' + item.classeException__c;
  
                        // Suppression des chantiers, projets & rendez-vous afin de pas les prendre en compte lors de l'enregistrement des données
                        projets[index] = null;
                        rendezVous[index] = null;
                    } 
                }
                index++;
            }          
        }

        // Enregistrements des projets
        List<Opportunity> projetsToUpdate = new List<Opportunity>();
        index = 0;
        for(Import__c item : items) {
            if (item.integrable__c != null && item.integrable__c == true && projets[index] != null)
                projetsToUpdate.add(projets[index]);
            index++;
        }
        if (!projetsToUpdate.isEmpty()) {
            Database.UpsertResult[] projetResults = Database.upsert(projetsToUpdate, false);
            Map<ID, Opportunity> updatedProjets = new Map<ID, Opportunity>([SELECT id, LastModifiedDate FROM Opportunity WHERE id IN :projetsToUpdate]);

            index = 0;
            Integer resultIndex = 0;
            for(Import__c item : items) {
                if (item.integrable__c != null && item.integrable__c == true && projets[index] != null) {
                    Database.UpsertResult result   = projetResults[resultIndex++];
                    Account               compte   = comptes[index];
                    Chantier__c           chantier = chantiers[index];
                    Opportunity           projet   = projets[index];
                    Event                 RDV      = rendezVous[index];
                  
                    if (result.isSuccess()) {
                        item.versioningProjet__c = getVersion(updatedProjets.get(projet.id).LastModifiedDate);
                        item.projet__c = projet.id;

                        item.journalIntegration__c += '\n[' + System.now() + '] Déversement des projets OK';

                        if (RDV != null)
                        RDV.whatId = projet.id;
                    } else {
                        item.messageException__c = getSimpleExceptionMessage(result.getErrors()[0].getMessage()).left(255);
                        item.classeException__c  = ('PROJET : ' + result.getErrors()[0].getStatusCode()).left(255);

                        item.journalIntegration__c += '\n[' + System.now() + '] Erreur lors du déversement des projets\n - ' + item.messageException__c + '\n - ' + item.classeException__c;
      
                        // Suppression des chantiers, projets & rendez-vous afin de pas les prendre en compte lors de l'enregistrement des données
                        rendezVous[index] = null;
                    } 
                }
                index++;
            }          
        }              

        // Enregistrements des rendez-vous
        List<Event> rendezVousToUpdate = new List<Event>();
        index = 0;
        for(Import__c item : items) {
            if (item.integrable__c != null && item.integrable__c == true && rendezVous[index] != null)
                rendezVousToUpdate.add(rendezVous[index]);
            index++;
        }
        if (!rendezVousToUpdate.isEmpty()) {
            Database.UpsertResult[] rendezVousResults = Database.upsert(rendezVousToUpdate, false);
            Map<ID, Event> updatedRendezVous = new Map<ID, Event>([SELECT id, LastModifiedDate FROM Event WHERE id IN :rendezVousToUpdate]);

            index = 0;
            Integer resultIndex = 0;
            for(Import__c item : items) {
                if (item.integrable__c != null && item.integrable__c == true && rendezVous[index] != null) {
                    Database.UpsertResult result   = rendezVousResults[resultIndex++];
                    Account               compte   = comptes[index];
                    Chantier__c           chantier = chantiers[index];
                    Opportunity           projet   = projets[index];
                    Event                 RDV      = rendezVous[index];
              
                    if (result.isSuccess()) {
                        item.versioningRDV__c = getVersion(updatedRendezVous.get(RDV.id).LastModifiedDate);
                        if (Trigger.isInsert)
                            item.idRDV__c = RDV.id;                  
                    } else {
                        item.messageException__c = getSimpleExceptionMessage(result.getErrors()[0].getMessage()).left(255);
                        item.classeException__c  = ('RDV : ' + result.getErrors()[0].getStatusCode()).left(255);
                    } 
                }
                index++;
            }          
        }         

        // *********************************************************************
        // * ACQUITTEMENT DE L'ÉLÉMENT IMPORTÉ                                 *
        // *********************************************************************
        for(Import__c item : items) {
            if ((item.messageException__c == null || String.isEmpty(item.messageException__c)) && (item.classeException__c == null || String.isEmpty(item.classeException__c)))
                item.dateIntegration__c = System.now();
            else
                item.addError((item.messageException__c == null || String.isEmpty(item.messageException__c)) ? item.classeException__c : item.messageException__c);
        }
        system.debug('#### END import');
    }

    /**
    * @description Méthode principale d'initialisation des données pour l'import des enregistrements
    * @param items Liste des fiches d'import
    * @param comptes Liste des comptes à créer
    * @param chantiers Liste des chantiers à créer
    * @param projets Liste des projets à créer
    * @param rendezVous Liste des RDV à créer
    * @param parrains Liste des parrains portentiels pour le compte
    */ 
    private static void initData(List<Import__c> items, Account[] comptes, Chantier__c[] chantiers, Opportunity[] projets, Event[] rendezVous, Map<String, Account> parrains) {
        system.debug('#### START initData');
        List<ID>     compteIds      = new List<ID>();
        List<ID>     chantierIds    = new List<ID>();
        List<ID>     projetIds      = new List<ID>();
        List<ID>     RDVIds         = new List<ID>();
        List<String> parrainNumbers = new List<String>();

        // Récupération des ID et numéros des enregistrements référencés dans Import__c
        for(Import__c item : items) {
            if (item.compte__c != null) compteIds.add(item.compte__c);
            if (item.chantier__c != null) chantierIds.add(item.chantier__c);
            if (item.projet__c != null) projetIds.add(item.projet__c);
            if (item.idRDV__c != null) RDVIds.add(item.idRDV__c);
            if (item.RecordTypeId == RT_IMPORT_EXTERNE) {
                if (!String.isEmpty(item.numeroParrain__c))
                    parrainNumbers.add(item.numeroParrain__c);
                else if (!String.isEmpty(item.departementCompte__c) && (item.departementCompte__c.startsWith('FOY/') || item.departementCompte__c.startsWith('CPT/')))
                    parrainNumbers.add(item.departementCompte__c);
            }
        }

        // Chargement des données associées
        Map<ID, Account> aMap = new Map<ID, Account>([SELECT Id, CreatedDate, LastModifiedDate, OwnerId, RecordTypeId,
                                                           Salutation, FirstName, LastName,
                                                           PersonMailingStreet, PersonMailingPostalCode, PersonMailingCity, PersonMailingState, PersonMailingCountry,
                                                           codeAcces__c, etage__c,
                                                           adresseGeolocalisation__c, iris__c, localisation__Latitude__s, localisation__Longitude__s,
                                                           methodeGeocodage__c,
                                                           PersonHomePhone, PersonMobilePhone, Phone, Fax, PersonEmail,
                                                           optinAdresseEmailKparK__c, optinTelephoneDomicileKparK__c, optinTelephoneMobileKparK__c, optinSMSKparK__c,
                                                           accountSource, accountCallSource__c,
                                                           nomFichierSource__c, dateFichierSource__c, typeFichierSource__c, dateExpiration__c,
                                                           idInterneFournisseurFichierSource__c, sourceWeb__c,
                                                           description, parrain__c
                                                    FROM Account
                                                    WHERE Id IN :compteIds]);
        Map<ID, Chantier__c> cMap = new Map<ID, Chantier__c>([SELECT Id, CreatedDate, LastModifiedDate, OwnerId, Name,
                                                                   rue__c, codePostal__c, ville__c, departement__c, pays__c,
                                                                   etage__c, adresseGeolocalisation__c, iris__c, localisation__Latitude__s, localisation__Longitude__s,
                                                                   methodeGeocodage__c, typeHabitation__c
                                                            FROM Chantier__c
                                                            WHERE Id IN :chantierIds]);
        Map<ID, Opportunity> pMap = new Map<ID, Opportunity>([SELECT Id, CreatedDate, LastModifiedDate, OwnerId, Name,
                                                                   Type, StageName, CloseDate, LeadSource, callSource__c,
                                                                   materiauxCoulissant__c, materiauxFenetre__c, materiauxMoustiquaire__c,
                                                                   materiauxPersienne__c, materiauxPortail__c, materiauxPorteBlindee__c,
                                                                   materiauxPorteEntree__c, materiauxPorteInterieur__c, materiauxPorteGarage__c,
                                                                   materiauxPorteService__c, materiauxPorteFenetre__c, materiauxStoreBanne__c,
                                                                   materiauxVoletBattant__c, materiauxVoletRoulant__c, materiauxIsolationCombles__c, 
                                                                   materiauxPergola__c, materiauxCarport__c,
                                                                   quantiteCoulissant__c, quantiteFenetre__c, quantiteMoustiquaire__c,
                                                                   quantitePersienne__c, quantitePortail__c, quantitePorteBlindee__c,
                                                                   quantitePorteEntree__c, quantitePorteInterieur__c, quantitePorteGarage__c,
                                                                   quantitePorteService__c, quantitePorteFenetre__c, quantiteStoreBanne__c,
                                                                   quantiteVoletBattant__c, quantiteVoletRoulant__c, quantiteIsolationCombles__c, 
                                                                   quantitePergola__c, quantiteCarport__c,
                                                                   description, sourceWeb__c, GCLID__c
                                                            FROM Opportunity
                                                            WHERE Id IN :projetIds]);
        Map<ID, Event> rMap = new Map<ID, Event>([SELECT Id, CreatedDate, LastModifiedDate, RecordTypeId, Type, WhoId, WhatId, OwnerId,
                                                       Subject, confirm__c, couplePresent__c, statutRDV__c, StartDateTime, EndDateTime
                                                    FROM Event
                                                    WHERE Id IN :RDVIds]);
        if (!parrainNumbers.isEmpty()) {
            for (Account account : [SELECT Id, AccountNumber FROM Account WHERE AccountNumber IN :parrainNumbers])
                parrains.put(account.AccountNumber, account);
        }

        // Initialisation des associations import/compte/chantier/projet/rendez-vous
        Integer index = 0;
        for(Import__c item : items) {
            if (item.compte__c != null) comptes[index] = aMap.get(item.compte__c);
            if (item.chantier__c != null) chantiers[index] = cMap.get(item.chantier__c);
            if (item.projet__c != null) projets[index] = pMap.get(item.projet__c);
            if (item.idRDV__c != null) rendezVous[index] = rMap.get(item.idRDV__c);
        }       
        system.debug('#### END initData');
    }

    /**
    * @description Méthode pour initialiser un nouveau enregistrement Account si le compte n'existe pas dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param item Fiche d'import
    * @param compte Compte
    * @return Account Compte initialisé
    */ 
    private static Account getOrCreateCompte(UserContext userContext, Import__c item, Account compte) {
        system.debug('#### START getOrCreateCompte');
        if (compte == null) {
            compte = new Account();
            compte.OwnerId = item.OwnerId;
        }
        system.debug('#### END getOrCreateCompte');
        return compte;
    }

    /**
    * @description Méthode pour initialiser un nouveau enregistrement Chantier si le chantier n'existe pas dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param item Fiche d'import
    * @param compte Chantier
    * @return Chantier__c Chantier initialisé
    */ 
    private static Chantier__c getOrCreateChantier(UserContext userContext, Import__c item, Chantier__c chantier) {
        system.debug('#### START getOrCreateChantier');
        if (chantier == null && (FORCE_OPPORTUNITY || item.chantierExistant__c || item.projetExistant__c || item.RDVExistant__c)) {
            chantier = new Chantier__c();
            chantier.OwnerId = item.OwnerId;
            chantier.Name    = ('CHA _ ' + TODAY.year() + (TODAY.month() < 10 ? '0' + TODAY.month() : TODAY.month().format())
                                     + ' _ ' + (item.prenomCompte__c == null ? '' : item.prenomCompte__c.toLowerCase())
                                     + ' '   + (item.nomCompte__c    == null ? '' : item.nomCompte__c.toUpperCase())
                                     + ' _ ' + item.villeCompte__c
                                     + ' _ ' + (item.locataire__c ? 'Locataire' : 'Proprietaire'))
                           .left(MAX_NAME_LENGTH);                           
        }      
        system.debug('#### END getOrCreateChantier');
        return chantier;
    }

    /**
    * @description Méthode pour initialiser un nouveau enregistrement projet si le chantier n'existe pas dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param item Fiche d'import
    * @param projet Projet (Opportunity)
    * @return Opportunity Projet initialisé
    */ 
    private static Opportunity getOrCreateProjet(UserContext userContext, Import__c item, Opportunity projet) {
        system.debug('#### START getOrCreateProjet');
        if (projet == null && (FORCE_OPPORTUNITY || item.projetExistant__c || item.RDVExistant__c)) {
            projet = new Opportunity();
            projet.OwnerId   = item.OwnerId;
            projet.Name      = ('PRJ _ ' + TODAY.year() + (TODAY.month() < 10 ? '0' + TODAY.month() : TODAY.month().format())
                                     + ' _ ' + (item.prenomCompte__c == null ? '' : item.prenomCompte__c.toLowerCase())
                                     + ' '   + (item.nomCompte__c    == null ? '' : item.nomCompte__c.toUpperCase())
                                     + ' _ ' + item.villeCompte__c
                                     + ' _ ' + (item.locataire__c ? 'Locataire' : 'Proprietaire'))
                           .left(MAX_NAME_LENGTH);
            projet.Type      = 'Nouveau';
            projet.StageName = 'Analyse';
            projet.CloseDate = System.today().addDays(3);
            system.debug('## ID Compte: ' + item.compte__c);
        }
        system.debug('#### END getOrCreateProjet');
        return projet;
    }

    /**
    * @description Méthode pour initialiser un nouveau enregistrement Activiy si le RDV n'existe pas dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param item Fiche d'import
    * @param projet Activity (RDV)
    * @return Event RDV initialisé
    */ 
    private static Event getOrCreateRendezVous(UserContext userContext, Import__c item, Event RDV) {
        system.debug('#### START getOrCreateRendezVous');
        if (RDV == null && item.RDVExistant__c) {
            RDV = new Event(OwnerId      = item.OwnerId,
                            RecordTypeId = RT_ACTIVITE_COMMERCIALE,
                            Type         = Constants.EVENT_TYPE_R1,
                            WhoId        = null, // Contact du compte
                            WhatId       = null, // Projet
                            Subject      = 'Activité Commerciale');
        }
        system.debug('#### END getOrCreateRendezVous');
        return RDV;
    }

    /**
    * @description Méthode de définition des champs de l'objet Account selon les données présentes dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param compte Compte à créer
    * @param item Fiche d'import
    * @param parrains Liste des parrains portentiels pour le compte
    * @return Account Compte à créer avec les champs à jour
    */ 
    private static Account buildCompte(UserContext userContext, Account compte, Import__c item, Map<String, Account> parrains) {
        system.debug('#### START buildCompte');
        if (item.RecordTypeId == RT_IMPORT_EXTERNE && String.isBlank(item.civiliteCompte__c))
            compte.Salutation                       = 'M.';
        else
            compte.Salutation                       = item.civiliteCompte__c;
        compte.FirstName                            = item.prenomCompte__c;
        compte.LastName                             = item.nomCompte__c;
        compte.PersonMailingStreet                  = item.rueCompte__c;
        compte.PersonMailingPostalCode              = item.codePostalCompte__c;
        compte.PersonMailingCity                    = item.villeCompte__c;
        if (item.RecordTypeId == RT_FICHE_CONTACT ||
           (item.RecordTypeId == RT_IMPORT_EXTERNE && !String.isEmpty(item.departementCompte__c) && !item.departementCompte__c.startsWith('FOY/') && !item.departementCompte__c.startsWith('CPT/')))
            compte.personMailingState               = item.departementCompte__c;
        compte.PersonMailingCountry                 = StringUtils.defaultIfEmpty(item.paysCompte__c, 'FRANCE');
        compte.codeAcces__c                         = item.codeAccesCompte__c;
        compte.etage__c                             = item.etageCompte__c;
        compte.adresseGeolocalisation__c            = item.adresseGeolocalisation__c;
        compte.iris__c                              = item.iris__c;
        compte.codeCommune__c                       = item.codeCommune__c;
        compte.methodeGeocodage__c                  = getMethodeGeocodage(item.methodeGeocodage__c);
        compte.Localisation__Latitude__s            = item.Localisation__Latitude__s;
        compte.Localisation__Longitude__s           = item.Localisation__Longitude__s;
        compte.PersonHomePhone                      = item.telephoneDomicileCompte__c;
        compte.PersonMobilePhone                    = item.telephoneMobileCompte__c;
        compte.Phone                                = item.telephoneProfessionnelCompte__c;
        compte.Fax                                  = item.faxCompte__c;
        compte.PersonEmail                          = item.emailCompte__c;
        compte.optinAdresseEmailKparK__c            = item.optinAdresseEmailKparK__c;
        compte.optinTelephoneDomicileKparK__c       = item.optinTelephoneDomicileKparK__c;
        compte.optinTelephoneMobileKparK__c         = item.optinTelephoneMobileKparK__c;
        compte.optinSMSKparK__c                     = item.optinSMSKparK__c;
        compte.accountSource                        = StringUtils.defaultIfEmpty(item.source__c, DEFAULT_SOURCE);
        compte.accountCallSource__c                 = StringUtils.defaultIfEmpty(item.callSource__c, getCallSource(item.RecordTypeId, item.nomFichierSource__c));
        compte.nomFichierSource__c                  = String.isBlank(item.nomFichierSource__c) ? (item.RecordTypeId == RT_FICHE_CONTACT ? 'Fiche contact' : null) : item.nomFichierSource__c;
        compte.dateFichierSource__c                 = item.dateFichierSource__c;
        compte.typeFichierSource__c                 = item.typeFichierSource__c;
        compte.dateExpiration__c                    = item.dateExpiration__c;
        if (String.isBlank(item.idInterneFournisseurFichierSource__c) && 'formulaire_site_kpark.fr'.equalsIgnoreCase(item.nomFichierSource__c))
            compte.idInterneFournisseurFichierSource__c = (System.isBatch() ? 'BATCH' : 'SITE') + ' - ' + item.name;
        else
            compte.idInterneFournisseurFichierSource__c = item.idInterneFournisseurFichierSource__c;
        compte.sourceWeb__c                         = item.sourceWeb__c;
        compte.description                          = item.description__c;
        compte.typeDotation__c                      = item.typeDotation__c;
        
        /* >>> F.G., le 16/02/2023, code annulé le 26/09/2023 car carport + pergolas déployé au niveau national --> en,voi vers Odigo des fiches
        if ((item.quantitePergola__c != null && item.quantitePergola__c >= 1) || (item.quantiteCarport__c != null && item.quantiteCarport__c >= 1)) {
            Double autreQuantite = 0;
            if (item.quantiteCoulissant__c != null)
                autreQuantite += item.quantiteCoulissant__c;
            if (item.quantiteFenetre__c != null)
                autreQuantite += item.quantiteFenetre__c;
            if (item.quantiteMoustiquaire__c != null)
                autreQuantite += item.quantiteMoustiquaire__c;
            if (item.quantitePersienne__c != null)
                autreQuantite += item.quantitePersienne__c;
            if (item.quantitePortail__c != null)
                autreQuantite += item.quantitePortail__c;
            if (item.quantitePorteBlindee__c != null)
                autreQuantite += item.quantitePorteBlindee__c;
            if (item.quantitePorteEntree__c != null)
                autreQuantite += item.quantitePorteEntree__c;
            if (item.quantitePorteInterieur__c != null)
                autreQuantite += item.quantitePorteInterieur__c;
            if (item.quantitePorteGarage__c != null)
                autreQuantite += item.quantitePorteGarage__c;
            if (item.quantitePorteService__c != null)
                autreQuantite += item.quantitePorteService__c;
            if (item.quantitePorteFenetre__c != null)
                autreQuantite += item.quantitePorteFenetre__c;
            if (item.quantiteStoreBanne__c != null)
                autreQuantite += item.quantiteStoreBanne__c;
            if (item.quantiteVoletBattant__c != null)
                autreQuantite += item.quantiteVoletBattant__c;
            if (item.quantiteVoletRoulant__c != null)
                autreQuantite += item.quantiteVoletRoulant__c;
            if (item.quantiteIsolationCombles__c != null)
                autreQuantite += item.quantiteIsolationCombles__c;
            
             if (autreQuantite == 0) // Blocage uniquement si pergola ou carport
                compte.callbackprosodie__c              = ABORT_DT;
        }
           <<< F.G., le 16/02/2023 */

        // Définir le type d'enregistrement en Compte personnel si création du compte
        if (compte.RecordTypeId == null) {
            compte.RecordTypeId = RT_COMPTE_PERSO;
        }

        // Récupération du parrain 
        if (!String.isEmpty(item.numeroParrain__c)) {
            Account parrain = parrains.get(item.numeroParrain__c);
            if (parrain != null)
                compte.parrain__c = parrain.id;
        }
        else if (!String.isEmpty(item.departementCompte__c) && (item.departementCompte__c.startsWith('FOY/') || item.departementCompte__c.startsWith('CPT/'))) {
            Account parrain = parrains.get(item.departementCompte__c);
            if (parrain != null)
                compte.parrain__c = parrain.id;
        }
        
        system.debug('#### END buildCompte');
        return compte;
    }

    /**
    * @description Méthode de définition des champs de l'objet Chantier selon les données présentes dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param chantier Chantier à créer
    * @param item Fiche d'import
    * @return Chantier__c Chantier à créer avec les champs à jour
    */ 
    private static Chantier__c buildChantier(UserContext userContext, Chantier__c chantier, Import__c item) {
        system.debug('#### START buildChantier');
        if (item.chantierExistant__c) {
            chantier.rue__c                 = StringUtils.defaultIfEmpty(item.rueChantier__c, item.rueCompte__c);
            chantier.codePostal__c          = StringUtils.defaultIfEmpty(item.codePostalChantier__c, item.codePostalCompte__c);
            chantier.ville__c               = StringUtils.defaultIfEmpty(item.villeChantier__c, item.villeCompte__c);
            chantier.departement__c         = item.departementChantier__c;
            chantier.pays__c                = StringUtils.defaultIfEmpty(item.paysChantier__c, 'FRANCE');
        }
        else {
            chantier.rue__c                 = item.rueCompte__c;
            chantier.codePostal__c          = item.codePostalCompte__c;
            chantier.ville__c               = item.villeCompte__c;
            chantier.departement__c         = item.departementCompte__c;
            chantier.pays__c                = StringUtils.defaultIfEmpty(item.paysCompte__c, 'FRANCE');
        }
        chantier.etage__c                   = item.etageChantier__c;
        chantier.adresseGeolocalisation__c  = item.adresseGeolocalisation__c;
        chantier.iris__c                    = item.iris__c;
        chantier.codeCommune__c             = item.codeCommune__c;
        chantier.methodeGeocodage__c        = getMethodeGeocodage(item.methodeGeocodage__c);
        chantier.Localisation__Latitude__s  = item.Localisation__Latitude__s;
        chantier.Localisation__Longitude__s = item.Localisation__Longitude__s;
        chantier.typeHabitation__c          = item.typeHabitation__c;
        system.debug('## IRIS Chantier: '+item.iris__c);

        system.debug('#### END buildChantier');
        return chantier;
    }

    /**
    * @description Méthode de définition des champs de l'objet Opportunity (projet) selon les données présentes dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param projet Projet à créer
    * @param item Fiche d'import
    * @return Opportunity Projet à créer avec les champs à jour
    */ 
    private static Opportunity buildProjet(UserContext userContext, Opportunity projet, Import__c item) {
        system.debug('#### START buildProjet');
        projet.LeadSource                 = StringUtils.defaultIfEmpty(item.source__c, DEFAULT_SOURCE);
        projet.callSource__c              = StringUtils.defaultIfEmpty(item.callSource__c, getCallSource(item.RecordTypeId, item.nomFichierSource__c));
        projet.nomFichierSource__c        = String.isBlank(item.nomFichierSource__c) ? (item.RecordTypeId == RT_FICHE_CONTACT ? 'Fiche contact' : null) : item.nomFichierSource__c;
        if (String.isBlank(item.idInterneFournisseurFichierSource__c) && 'formulaire_site_kpark.fr'.equalsIgnoreCase(item.nomFichierSource__c))
            projet.idInterneFournisseurFichierSource__c = (System.isBatch() ? 'BATCH' : 'SITE') + ' - ' + item.name;
        else
            projet.idInterneFournisseurFichierSource__c = item.idInterneFournisseurFichierSource__c;
        projet.materiauxCoulissant__c     = item.materiauxCoulissant__c;
        projet.materiauxFenetre__c        = item.materiauxFenetre__c;
        projet.materiauxMoustiquaire__c   = item.materiauxMoustiquaire__c;
        projet.materiauxPersienne__c      = item.materiauxPersienne__c;
        projet.materiauxPortail__c        = item.materiauxPortail__c;
        projet.materiauxPorteBlindee__c   = item.materiauxPorteBlindee__c;
        projet.materiauxPorteEntree__c    = item.materiauxPorteEntree__c;
        projet.materiauxPorteInterieur__c = item.materiauxPorteInterieur__c;
        projet.materiauxPorteGarage__c    = item.materiauxPorteGarage__c;
        projet.materiauxPorteService__c   = item.materiauxPorteService__c;
        projet.materiauxPorteFenetre__c   = item.materiauxPorteFenetre__c;
        projet.materiauxStoreBanne__c     = item.materiauxStoreBanne__c;
        projet.materiauxVoletBattant__c   = item.materiauxVoletBattant__c;
        projet.materiauxVoletRoulant__c   = item.materiauxVoletRoulant__c;
        projet.materiauxIsolationCombles__c   = item.materiauxIsolationCombles__c;
        projet.materiauxPergola__c        = item.materiauxPergola__c;
        projet.materiauxCarport__c        = item.materiauxCarport__c;
        projet.quantiteCoulissant__c      = item.quantiteCoulissant__c;
        projet.quantiteFenetre__c         = item.quantiteFenetre__c;
        projet.quantiteMoustiquaire__c    = item.quantiteMoustiquaire__c;
        projet.quantitePersienne__c       = item.quantitePersienne__c;
        projet.quantitePortail__c         = item.quantitePortail__c;
        projet.quantitePorteBlindee__c    = item.quantitePorteBlindee__c;
        projet.quantitePorteEntree__c     = item.quantitePorteEntree__c;
        projet.quantitePorteInterieur__c  = item.quantitePorteInterieur__c;
        projet.quantitePorteGarage__c     = item.quantitePorteGarage__c;
        projet.quantitePorteService__c    = item.quantitePorteService__c;
        projet.quantitePorteFenetre__c    = item.quantitePorteFenetre__c;
        projet.quantiteStoreBanne__c      = item.quantiteStoreBanne__c;
        projet.quantiteVoletBattant__c    = item.quantiteVoletBattant__c;
        projet.quantiteVoletRoulant__c    = item.quantiteVoletRoulant__c;
        projet.quantiteIsolationCombles__c= item.quantiteIsolationCombles__c;
        projet.quantitePergola__c         = item.quantitePergola__c;
        projet.quantiteCarport__c         = item.quantiteCarport__c;
        projet.description                = item.observationsComplementaires__c;
        projet.periodePrevisionnelleInstallation__c = item.periodePrevisionnelleInstallation__c;
        projet.sourceWeb__c               = item.sourceWeb__c;
        projet.GCLID__c                   = item.GCLID__c;
        if (projet.leadSource == 'FOIRE' && !OPERATION_FOIRE.isEmpty())
            projet.operation__c = OPERATION_FOIRE[0].id;
        projet.recommendedSeller__c       = item.recommendedSeller__c;
        
        system.debug('#### END buildProjet');
        return projet;
    }

    /**
    * @description Méthode de définition des champs de l'objet Activity (RDV) selon les données présentes dans la fiche import
    * @param userContext Contexte de l'utilisateur courant
    * @param RDV RDV à créer
    * @param item Fiche d'import
    * @return Event RDV à créer avec les champs à jour
    */ 
    private static Event buildRendezVous(UserContext userContext, Event RDV, Import__c item) {
        system.debug('#### START buildRendezVous');
        RDV.confirm__c       = !item.aConfirmer__c;
        RDV.couplePresent__c = item.couplePresent__c;
        RDV.statutRDV__c     = 'Pris';
        RDV.StartDateTime    = item.dateRDV__c;
        RDV.EndDateTime      = RDV.StartDateTime.addMinutes(EVENT_DURATION);
        RDV.Description      = item.precisions__c;

        system.debug('#### END buildRendezVous');
        return RDV;
    }

    /**
    * @description Méthode de vérification si les différents objets de la fiche (account, chantier etc...) n'ont pas été modifiés pendant le traitement
    * @param item Fiche d'import
    * @param compte Compte à créer
    * @param chantier Chantier à créer
    * @param projet Projet à créer
    * @param RDV RDV à créer
    * @return String Message d'erreur si des modifications ont eu lieu
    */ 
    private static String checkModification(Import__c item, Account compte, Chantier__c chantier, Opportunity projet, Event RDV) {
        system.debug('#### START checkModification');
        String errorMessage = null;

        // Vérification des modifications apportées aux données
        Integer index = 1;
        String modifiedObjects = '';
        if (compte != null && compte.LastModifiedDate != null && item.versioningCompte__c != null && compte.LastModifiedDate.getTime() > item.versioningCompte__c)
            modifiedObjects += '-' + (index++) + '- compte ';
        if (chantier != null && chantier.LastModifiedDate != null && item.versioningChantier__c != null && chantier.LastModifiedDate.getTime() > item.versioningChantier__c)
            modifiedObjects += '-' + (index++) + '- chantier ';
        if (projet != null && projet.LastModifiedDate != null && item.versioningProjet__c != null && projet.LastModifiedDate.getTime() > item.versioningProjet__c)
            modifiedObjects += '-' + (index++) + '- projet ';
        if (RDV != null && RDV.LastModifiedDate != null && item.versioningRDV__c != null && RDV.LastModifiedDate.getTime() > item.versioningRDV__c)
            modifiedObjects += '-' + (index++) + '- RDV ';

        if (!String.isEmpty(modifiedObjects))
            errorMessage = Label.import_erreur_ObjectsChanged+' '+modifiedObjects.trim();
        
        system.debug('#### END checkModification');
        return errorMessage;
    }

    /**
    * @description Mappage de la source Call selon le nom du fichier
    * @param recordTypeId Id du type d'enregistrement
    * @param s Nom du fichier
    * @return String Source Call
    */ 
    private static String getCallSource(Id recordTypeId, String s) {
        if (RecordTypeId == RT_IMPORT_EXTERNE) {
          s = StringUtils.trim(s);
          if ('formulaire_site_kpark.fr'.equalsIgnoreCase(s))              
              return '44 - Formulaire site KparK';
          if ('formulaire_site_parrainage'.equalsIgnoreCase(s))
              return '53 - Parrainage';
          if ('formulaire_site_qts'.equalsIgnoreCase(s))
              return '44 - Formulaire site QTS';
          if ('formulaire_site_affil'.equalsIgnoreCase(s))
              return '44 - Affiliation';
        }
        return null;
    }

    /**
    * @description Récupère le message d'erreur stocké dans l'exception FIELD_CUSTOM_VALIDATION_EXCEPTION
    * @param message Texte de l'exception
    * @return String Message d'erreur formaté de l'exception
    */ 
    private static String getSimpleExceptionMessage(String message) {
        Integer index1 = message.indexOfIgnoreCase(FIELD_EXCEPTION);
        if (index1 == -1)
            return message;
        index1 += FIELD_EXCEPTION.length();
        Integer index2 = message.indexOfIgnoreCase(': ', index1);
        Integer index3 = message.indexOfIgnoreCase('Class.', index1);
        return message.substring(index1, Math.min(index2, index3)).trim();
    }
    
    /**
    * @description Détermine le type de géocodage selon l'exécution du code (Batch, asynchrone, synchrone)
    * @param methodeGeocodage Méthode de géocodage par défaut
    * @return String Méthode de géocodage par défaut ou BATCH si le code est exécuté par un batch ou une méthode asynchrone
    */ 
    private static String getMethodeGeocodage(String methodeGeocodage) {
        if (String.isBlank(methodeGeocodage) || (System.isBatch() || System.isFuture()))
            return 'BATCH';
        return methodeGeocodage;
    }
    
    /**
    * @description Méthode de construction du numéro de version de l'enregistrement
    * @param dt Date/heure de la dernière modification
    * @return Long Numéro de version de l'enregistrement
    */ 
    private static Long getVersion(DateTime dt) {
        if (dt == null)
            return null;
        return DateTime.newInstance(dt.year(), dt.month(), dt.day(), dt.hour(), dt.minute(), dt.second() + MODIFICATION_PERIOD_DURATION).getTime(); // 1 minute de décalage afin que les futures puissent être exécutées  
    }
}