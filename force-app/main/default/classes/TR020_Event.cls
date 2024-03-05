//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Event
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/12/2020
//-- Version     : 1.11
//-- * 1.11 - Ajout alimentation champ Type (Call)
//-- * 1.10 - Ajout de R0 + simplification envoi d'email
//-- * 1.9 - Optimisation
//-- --------------------------------------------------------------------------------- --
public with sharing class TR020_Event {
    private static final String SEPARATOR = ',';
    private static final Id RT_RDV_COMMERCIAL = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id RT_RDV_PROSPECTION = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_PROSPECTION_RT);

    /**
    * @description Règle de validation
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        /* VR001_K2_Event_Debrief */
        //Creation ou modification
        System.debug('### DEBUT TR020_Event.applyValidationRules');
        if (Trigger.isInsert || Trigger.isUpdate) {
            List<Event> newEvents = (List<Event>)Trigger.new;
            Map<Id, Event> oldEvents = (Map<Id, Event>)Trigger.oldMap;
            Set<ID> opportunityIDs = new Set<ID>();
            Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>();
            Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>();

            // Vérification de la validité de la date de début de l'évènement
            // TR001_EventCalendar.ManageCreateDate déplacé
            for (Event newEvent :newEvents) {
                Datetime t = newEvent.startDateTime;
                Date date2 = Date.today();
                Date startdate = Date.newInstance(t.year(),t.month(),t.day());
                Integer numberDaysDue = startdate.daysBetween(date2);
               
                if (numberDaysDue > 7)
                    newEvent.addError(Label.event_error_dateDebutMin);
            }


            // Boucle sur les events du trigger - récupération des event commerciaux et non déplacé
            for (Event newEvent : newEvents) {
                if (!Constants.StatutEventDeplace.equalsIgnoreCase(newEvent.statutRDV__c) 
                        && (Constants.EVENT_TYPE_R0.equalsIgnoreCase(newEvent.type) || Constants.EVENT_TYPE_R1.equalsIgnoreCase(newEvent.type) 
                            || Constants.EVENT_TYPE_R2.equalsIgnoreCase(newEvent.type) || Constants.EVENT_TYPE_RP.equalsIgnoreCase(newEvent.type)) 
                        && String.isNotBlank(newEvent.WhatId))
                    opportunityIDs.add(newEvent.WhatId);
            }

            if (!opportunityIDs.isEmpty()) {
                opportunities = new Map<Id, Opportunity>([SELECT Id, Account.IsPersonAccount, Account.PersonContactId, 
                                                            Account.contactParDefaut__c, chantier__c
                                                          FROM Opportunity 
                                                          WHERE Id IN :opportunityIDs]);                
            }            
            for (Event newEvent : newEvents) {
                if (!Constants.StatutEventDeplace.equalsIgnoreCase(newEvent.statutRDV__c)) {
                    String objectType = null;
                    // Obliger association d'un R1, R2 ou R+ à un projet - block a supprimer si non validé. LCL
                    if (Constants.EVENT_TYPE_R0.equalsIgnoreCase(newEvent.type) || Constants.EVENT_TYPE_R1.equalsIgnoreCase(newEvent.type) 
                            || Constants.EVENT_TYPE_R2.equalsIgnoreCase(newEvent.type) || Constants.EVENT_TYPE_RP.equalsIgnoreCase(newEvent.type)) {
                        objectType = ('' + newEvent.whatId).substring(0,3);                        
                        if((objectType!='006')|| (newEvent.whatId == null)) {//006 debut id projet
                            newEvent.addError(Label.event_error_projetAssocie);
                        }
                        else { // contact bien renseigné
                            Opportunity opp = opportunities.get(newEvent.whatId);
                            if (opp != null && opp.Account != null) {
                              ID contactID = opp.Account.IsPersonAccount ? opp.Account.PersonContactId : opp.Account.contactParDefaut__c;
                              if((newEvent.WhoId == null) || (newEvent.WhoId != null && contactID  != null && newEvent.WhoId != contactId)){
                                newEvent.addError(Label.event_error_demandeurPrincipal);
                              }
                            }                            
                        }                        
                    }
                    //obliger association d'un R1, R2 ou R+ à un projet - block a supprimer si non validé. LCL
                    //interdire association d'un rdv autre que R1, R2 ou R+ à un compte ou un chantier
                    else {
                        if(newEvent.whatId != null){
                            objectType = ('' + newEvent.whatId).substring(0,3);
                        }
                        if((objectType=='001')|| (objectType=='a08')) { //001 account et a08 chantier
                            newEvent.addError(Label.event_error_demandeurPrincipal);
                        }
                    }
                }
            }
        }

        /* VR001_K2_Event_Suppression */
        if (Trigger.isDelete && (!'K/K - DC'.equalsIgnoreCase(userContext.getProfile().name) && !'Administrateur système'.equalsIgnoreCase(userContext.getProfile().name))) {
            for (Event event : (List<Event>) Trigger.old) {
                if (Constants.EVENT_TYPE_R0.equalsIgnoreCase(event.type) || Constants.EVENT_TYPE_R1.equalsIgnoreCase(event.type) 
                        || Constants.EVENT_TYPE_R2.equalsIgnoreCase(event.type) || Constants.EVENT_TYPE_RP.equalsIgnoreCase(event.type))
                    event.addError(Label.event_error_droitSuppression);
            }
        }

        System.debug('### FIN TR020_Event.applyValidationRules');
    }

    /**
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        List<Event> newEvents = (List<Event>)Trigger.new;
        Map<Id, Event> oldEvents = (Map<Id, Event>)Trigger.oldMap;

        if (!Trigger.isExecuting)
            return;

        System.debug('### DEBUT TR020_Event.applyUpdateRules');
        Set<Id> opportunityIDs = new Set<Id>();
        Set<Id> contactIDs = new Set<Id>();
        Set<Id> chantierIDs = new Set<Id>();
        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>();
        Map<Id, Opportunity> opportunitiesForVendeurLPP = new Map<Id, Opportunity>();
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>();
        List<ObjectDetailUtils.Vendeur> vendeurList = new List<ObjectDetailUtils.Vendeur>();
        List<String> eventsOwnerIds = new List<String>();

        // ** A - Initialisation des données intermédiaires **
        for (Event newEvent : newEvents) {
            // Type de RDV
            if (!Constants.StatutEventDeplace.equalsIgnoreCase(newEvent.statutRDV__c)) {
                if (newEvent.RecordTypeID == RT_RDV_COMMERCIAL && newEvent.WhatId != null && String.isBlank(newEvent.Type))
                    opportunityIDs.add(newEvent.whatId);
            }
            // Vendeur le plus proche && champ Emplacement
            if((newEvent.RecordTypeID == RT_RDV_COMMERCIAL || newEvent.RecordTypeID == RT_RDV_PROSPECTION)) {
                if(newEvent.whatId != null) {
					opportunityIDs.add(newEvent.whatId);
				} else if(newEvent.whoId != null) {
					contactIDs.add(newEvent.whoId);
				}
                eventsOwnerIds.add(newEvent.OwnerId);
            }
        }
        if (!opportunityIDs.isEmpty()) {
            opportunities = new Map<Id, Opportunity>([SELECT Id, Account.isPersonAccount, Account.PersonContactId, Account.contactParDefaut__c, chantier__c,
                                                             chantier__r.localisation__longitude__s, chantier__r.localisation__latitude__s,
                                                             chantier__r.rue__c, chantier__r.codePostal__c, chantier__r.ville__c,
                                                             chantier__r.libelleMagasinActuel__c, nbR1Pris__c, nbR1Effectues__c,
                                                             nbR2Pris__c, nbR2Effectues__c, nbRPlusPris__c, nbRPlusEffectues__c
                                                      FROM Opportunity
                                                      WHERE id IN :opportunityIDs]);
        }
        if (!contactIDs.isEmpty()) {
            contacts = new Map<Id, Contact>([SELECT id, Name, Account.rue__c, Account.codePostal__c, Account.ville__c FROM Contact WHERE id IN :contactIDs]);
        }

        // ** B - Application des règles de mise à jour **
        for (Event newEvent : newEvents) {
            Event oldEvent = oldEvents == null ? null : oldEvents.get(newEvent.id);

            // Ancien contenu de la classe TR003_Event après suppression de la classe TR001_EventCalendar / Héritage de Kube v1
            if (!Trigger.isInsert){
                // Impossible à transcrire en standard car StartDateTime n'est pas un champ accessible.
                if(newEvent.RecordTypeId == RT_RDV_COMMERCIAL) {
                    newEvent.dateinitialeduRDV__c = newEvent.StartDateTime;
                }
			}
			
            // A la création, si créateur = Call, alors Type (Call) = Nouveau
			if (Trigger.isInsert && Trigger.isBefore && newEvent.RecordTypeID == RT_RDV_COMMERCIAL && userContext != null 
				&& userContext.isCallUser() && String.isBlank(newEvent.TypeCall__c)){
                newEvent.TypeCall__c = 'Nouveau';
            }

            // Suppression de la localisation si adresse différente
            if (oldEvent != null && (newEvent.rue__c != oldEvent.rue__c || newEvent.codePostal__c != oldEvent.codePostal__c || newEvent.ville__c != oldEvent.ville__c)) {
                newEvent.localisation__Latitude__s  = null;
                newEvent.localisation__Longitude__s = null;
            }

            // Définit le champ Emplacement pour les RDV de prospection
            if (newEvent.RecordTypeId == RT_RDV_PROSPECTION) {
                if(String.isNotBlank(newEvent.rue__c) || String.isNotBlank(newEvent.codePostal__c) || String.isNotBlank(newEvent.ville__c)) {
                    newEvent.Location = (String.isBlank(newEvent.rue__c)) ? '' : newEvent.rue__c + ', ';
                    newEvent.Location += (String.isBlank(newEvent.codePostal__c)) ? '' : newEvent.codePostal__c + ' ';
                    newEvent.Location += (String.isBlank(newEvent.ville__c)) ? '' : newEvent.ville__c;
                }
                else if(newEvent.whatId != null) {
                    Opportunity opportunity = opportunities.get(newEvent.whatId);
                    if (opportunity != null && opportunity.chantier__c != null) {
                        newEvent.Location = (String.isBlank(opportunity.chantier__r.rue__c)) ? '' : opportunity.chantier__r.rue__c + ', ';
                        newEvent.Location += (String.isBlank(opportunity.chantier__r.codePostal__c)) ? '' : opportunity.chantier__r.codePostal__c + ' ';
                        newEvent.Location += (String.isBlank(opportunity.chantier__r.ville__c)) ? '' : opportunity.chantier__r.ville__c;
                    }

                    // TR001_EventCalendar.RenseignerMagasinProjet déplacé
                    if(opportunity != null)
                        newEvent.magasin__c = opportunity.chantier__r.libelleMagasinActuel__c;
                }
                else if(newEvent.whoId != null) {
                    Contact contact = contacts.get(newEvent.whoId);
                    if (contact != null && contact.Account != null) {
                        newEvent.Location = (String.isBlank(contact.Account.rue__c)) ? '' : contact.Account.rue__c + ', ';
                        newEvent.Location += (String.isBlank(contact.Account.codePostal__c)) ? '' : contact.Account.codePostal__c + ' ';
                        newEvent.Location += (String.isBlank(contact.Account.ville__c)) ? '' : contact.Account.ville__c;
                    }
                }
                else {
                    newEvent.Location = '';
                }
                newEvent.Location = StringUtils.trim(newEvent.Location);
            }

            // Lors du changement de propriétaire sur un RDV modifié et à réaffecter, le statut doit passer à Pris
            if (Constants.StatutEventAReaffecter.equalsIgnoreCase(newEvent.statutRDV__c) && Trigger.isUpdate && newEvent.OwnerId != oldEvent.OwnerId) {
                newEvent.statutRDV__c = Constants.StatutEventPris;
            }

            // Définit le type du RDV (R1, R2, R+)
            if (!Constants.StatutEventDeplace.equalsIgnoreCase(newEvent.statutRDV__c)) {
                // Event oldEvent = oldEvents == null ? null : oldEvents.get(newEvent.id);
                if (newEvent.RecordTypeId == RT_RDV_COMMERCIAL && newEvent.whatId != null && String.isBlank(newEvent.Type)) {
                    Opportunity opportunity = opportunities.get(newEvent.whatId);
                    if (opportunity != null) {
                        newEvent.projet__c = opportunity.id;
                        newEvent.chantier__c = opportunity.chantier__c;
                        Double nbR1 = (opportunity.nbR1Pris__c                == null ? 0 : opportunity.nbR1Pris__c)
                                    + (opportunity.nbR1Effectues__c           == null ? 0 : opportunity.nbR1Effectues__c);
                        Double nbR2 = (opportunity.nbR2Pris__c                == null ? 0 : opportunity.nbR2Pris__c)
                                    + (opportunity.nbR2Effectues__c           == null ? 0 : opportunity.nbR2Effectues__c);
                        Double nbRPlus = (opportunity.nbRPlusPris__c                == null ? 0 : opportunity.nbRPlusPris__c)
                                    + (opportunity.nbRPlusEffectues__c           == null ? 0 : opportunity.nbRPlusEffectues__c);
                        if (!Constants.EVENT_TYPE_R0.equalsIgnoreCase(newEvent.Type)) {
                            if ((nbR2 + nbRPlus) > 0)
                                newEvent.Type = Constants.EVENT_TYPE_RP;
                            else if (nbR1 > 0)
                                newEvent.Type = Constants.EVENT_TYPE_R2;
                            else
                                newEvent.Type = Constants.EVENT_TYPE_R1;
                        }
                    }
                }
            }
            // Mise à jour de la date de débriefing
            if (newEvent.recordTypeID == RT_RDV_COMMERCIAL) {
                // Pour les RDV commerciaux, la date de débriefing doit être initialisée lorsque le nouveau statut RDV est différent de Pris et que l'ancien était égal à Pris
                if (!String.isBlank(newEvent.statutRDV__c) && !(Constants.StatutEventPris.equalsIgnoreCase(newEvent.statutRDV__c))) {
                    if (oldEvent == null || newEvent.statutRDV__c != oldEvent.statutRDV__c) {
                        newEvent.dateDebriefing__c = System.now();
                    }
                } else {
                    newEvent.dateDebriefing__c = null; // Actuellement non débriefé, donc initialisation de la date à NULL pour écraser la valeur précédente si elle existait
                }
            } else if (newEvent.recordTypeID == RT_RDV_PROSPECTION) {
              if (newEvent.nbBAL50__c != null     || newEvent.nbFoire43__c != null      || newEvent.nbPhone26__c != null || newEvent.nbPhone55__c != null ||
                  newEvent.nbStandGM42__c != null || newEvent.nbStandMarch54__c != null || newEvent.nbTAP51__c != null) {
                if (oldEvent == null ||
                    newEvent.nbBAL50__c   != oldEvent.nbBAL50__c   || newEvent.nbFoire43__c   != oldEvent.nbFoire43__c   || newEvent.nbPhone26__c      != oldEvent.nbPhone26__c      ||
                    newEvent.nbPhone55__c != oldEvent.nbPhone55__c || newEvent.nbStandGM42__c != oldEvent.nbStandGM42__c || newEvent.nbStandMarch54__c != oldEvent.nbStandMarch54__c ||
                    newEvent.nbTAP51__c   != oldEvent.nbTAP51__c)
                  newEvent.dateDebriefing__c = System.now();
              }
              else newEvent.dateDebriefing__c = null; // Actuellement non débriefé, donc initialisation de la date à NULL pour écraser la valeur précédente si elle existait
            }
            if (newEvent.dateDebriefing__c != null && newEvent.ActivityDateTime != null)
              newEvent.delaiDebriefing__c = newEvent.ActivityDateTime.date().daysBetween(newEvent.dateDebriefing__c.date());
            else
              newEvent.delaiDebriefing__c = null;
        }
        System.debug('### FIN TR020_Event.applyUpdateRules');
    }

    /***** B - Update Async rules *****/
    public static void applyAsyncUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
        return;

        System.debug('### DEBUT TR020_Event.applyAsyncUpdateRules');
        // ** A - Initialisation des données intermédiaires **/
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> eventIds = new Set<Id>();
        Boolean geoGoogleEnabled = PropertiesUtils.getBooleanValue('google.geocoder.enabled', Test.isRunningTest());
        Boolean geoDQEEnabled = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', Test.isRunningTest());
        System.debug('## GeoGoogleEnabled: ' + geoGoogleEnabled);
        System.debug('## GeoDQEEnabled: ' + geoDQEEnabled);
        List<Event> geocodageEvents = new List<Event>();

        if (Trigger.isInsert || Trigger.isUpdate) {
            List<Event> newEvents = (List<Event>)Trigger.new;
            Map<Id, Event> oldEvents = (Map<Id, Event>)Trigger.oldMap;
            for (Event newEvent : newEvents){
                Event oldEvent = oldEvents == null ? null : oldEvents.get(newEvent.id);
                // Mise à jour projet avec dernier RDV
                if (!Constants.StatutEventDeplace.equalsIgnoreCase(newEvent.statutRDV__c)) {
                    if ((Trigger.isInsert || newEvent.ActivityDateTime != oldEvent.ActivityDateTime) && newEvent.whatId != null && !AlreadyUsed.isUsed('TR020_Event_estDernierRDV', newEvent.whatId))
                        opportunityIds.add(newEvent.whatId);
                }
                // Notification création RV
                if((Constants.EVENT_TYPE_R0.equalsIgnoreCase(newEvent.Type) || Constants.EVENT_TYPE_R1.equalsIgnoreCase(newEvent.Type) 
                            || Constants.EVENT_TYPE_R2.equalsIgnoreCase(newEvent.Type) || Constants.EVENT_TYPE_RP.equalsIgnoreCase(newEvent.Type)) 
                        && (Constants.StatutEventAReaffecter.equalsIgnoreCase(newEvent.StatutRDV__c) || Constants.StatutEventPris.equalsIgnoreCase(newEvent.StatutRDV__c)) 
                        && Trigger.isInsert){
                    eventIds.add(newEvent.Id);
                }
                // Géocodage pour les activités de prospection
                if((geoGoogleEnabled || geoDQEEnabled) && newEvent.RecordTypeId == RT_RDV_PROSPECTION) {
                    Boolean adresseGeocodable = String.isNotBlank(newEvent.rue__c) || String.isNotBlank(newEvent.codePostal__c) || String.isNotBlank(newEvent.ville__c);
                    Boolean adresseModifiee = (String.isNotBlank(newEvent.rue__c) || String.isNotBlank(newEvent.codePostal__c) || String.isNotBlank(newEvent.ville__c))
                                              && (Trigger.isInsert ? true
                                                                   : (newEvent.rue__c != oldEvent.rue__c || newEvent.codePostal__c != oldEvent.codePostal__c || newEvent.ville__c != oldEvent.ville__c));

                    System.debug('## Event = ' + newEvent.id + ' : ' + newEvent.Subject + ' (Geocodable = ' + adresseGeocodable + ', modifiée = ' + adresseModifiee + ')');
                    if (adresseGeocodable && adresseModifiee)
                        geocodageEvents.add(newEvent);
                }
            }
        }
        else if (Trigger.isDelete) {
            List<Event> oldEvents = (List<Event>)Trigger.old;
            for (Event oldEvent : oldEvents) {
                if (!Constants.StatutEventDeplace.equalsIgnoreCase(oldEvent.statutRDV__c)) {
                    if (oldEvent.whatId != null && !AlreadyUsed.isUsed('TR020_Event_estDernierRDV', oldEvent.whatId))
                        opportunityIds.add(oldEvent.whatId);
                }
            }
        }
        // ** B - Application des règles de mise à jour **
        if (opportunityIds != null && !opportunityIds.isEmpty())
            setDernierRDV(String.join(new List<ID>(opportunityIds), SEPARATOR));
        /* >>> F.G., le 19/02/2019
        if (eventIds != null && !eventIds.isEmpty())
            notificationCreationRDV(String.join(new List<ID>(eventIds), SEPARATOR));
           <<< F.G., le 19/02/2019 */
        if (geocodageEvents != null && !geocodageEvents.isEmpty())
            GeoUtils.updateEvents(geocodageEvents);

        System.debug('### FIN TR020_Event.applyAsyncUpdateRules');
    }

    /**
    * @description Fonction asynchrone pour définir le RDV comme derniers pour le projet associé
    * @param ids Ids des projets
    */
    @future
    public static void setDernierRDV(String ids) {
        System.debug('### DEBUT TR020_Event.setDernierRDV');
        List<String> opportunityIds = new List<String>();
        List<Event> updatedEvents = new List<Event>();

        if(String.isNotBlank(ids)) {
            opportunityIds = ids.split(SEPARATOR);
            if (opportunityIds == null || opportunityIds.isEmpty())
                return;
        } else return;

        try {
            List<Opportunity> opportunities = new List<Opportunity>([SELECT id, (SELECT id, ActivityDateTime, estDernierRDV__c FROM Events
                                                                                  WHERE isChild = false AND Type IN :Constants.EVENT_ACTIVITE_COMMERCIALE_TYPES 
                                                                                    AND statutRDV__c != :Constants.StatutEventDeplace
                                                                                  ORDER BY ActivityDateTime)
                                                                     FROM Opportunity
                                                                     WHERE id IN :opportunityIds]);

            for (Opportunity opportunity : opportunities) {
                Event lastEvent = null;
                for (Event event : opportunity.events) {
                    event.estDernierRDV__c = false;
                    updatedEvents.add(event);
                    if (lastEvent == null || lastEvent.ActivityDateTime <= event.ActivityDateTime)
                        lastEvent = event;
                }

                if (lastevent != null)
                    lastEvent.estDernierRDV__c = true;
            }

            if (!updatedEvents.isEmpty())
                update updatedEvents;
            System.debug('### FIN TR020_Event.setDernierRDV');
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
}