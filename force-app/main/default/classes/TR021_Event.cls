/* ************************************************************************* *
 * Evénement : Alimentation des indicateurs                                  *
 * ************************************************************************* *
 * Version : 1.04                                                            *
 * Date    : 09/01/2014                                                      *
 *           09/10/2015 - Intérêt marketing                                  *
 *           22/01/2019 - R0                                                 *
 * ************************************************************************* *
 * To do:                                                                    *
 * - Optimisation sur update. En effet, il est inutile de recalculer         *
 *   totalement les indicateurs sur les newAccounts et newChantiers. Un      *
 *   simple incrementIndicators(Account/Chantier, Contrat) serait suffisant. *
 * ************************************************************************* *
 */
public class TR021_Event {
    private static Boolean enabledForceIndicators = PropertiesUtils.getBooleanValue('function.enabled.forceIndicators', false);
    private static final Id RT_RDVCommercial = DAL.getRecordTypeIdByDevName(Constants.ACTIVITE_COMMERCIALE_RT);
    private static final Id RT_RDVProspection = DAL.getRecordTypeIdByDevName(Constants.ACTIVITE_PROSPECTION_RT);

    /** 01 - Méthode appelée par le trigger et de répartition des tâches **/
    public static void calculateIndicators(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        /** A - Répartition et calcul des indicateurs **/
        List<Opportunity> opportunitiesToUpdate = null;
        // Insert
        if (Trigger.isInsert)
            opportunitiesToUpdate = incrementIndicators(Trigger.new);
        // Update
        else if (Trigger.isUpdate) {
            Set<ID> eventIds = new Set<ID>();

            for (Event newEvent : (List<Event>) Trigger.new)
                // Ne traite que les RDV commerciaux initiaux (pas les RDV enfants associés) sinon compteurs du nombre de RDV erronés
                // if (newEvent.isChild == FALSE && (Constants.EVENT_TYPE_R0.equalsIgnoreCase(newEvent.type) || Constants.EVENT_TYPE_R1.equalsIgnoreCase(newEvent.type) || Constants.EVENT_TYPE_R2.equalsIgnoreCase(newEvent.type) || Constants.EVENT_TYPE_RP.equalsIgnoreCase(newEvent.type))) {
                if (newEvent.isChild == FALSE && (newEvent.recordTypeId == RT_RDVCommercial || newEvent.recordTypeId == RT_RDVProspection)) {
                    Event oldEvent = (Event) Trigger.oldMap.get(newEvent.id);

                    if (enabledForceIndicators ||
                            newEvent.whatId              != oldEvent.whatId           ||
                            newEvent.type                != oldEvent.type             ||
                            newEvent.statutRDV__c        != oldEvent.type             ||
                            newEvent.resultatDuRDV__c    != oldEvent.resultatDuRDV__c ||
                            newEvent.isAllDayEvent       != oldEvent.isAllDayEvent    ||
                            newEvent.activityDate        != oldEvent.activityDate     ||
                            newEvent.activityDateTime    != oldEvent.activityDateTime ||
                            newEvent.interetMarketing__c != oldEvent.interetMarketing__c) {
                        if (newEvent.whatId != null && (Test.isRunningTest() || !AlreadyUsed.isUsed('TR021_Event', newEvent.whatId)))
                            eventIds.add(newEvent.whatId);
                        if (oldEvent.whatId != null && (Test.isRunningTest() || !AlreadyUsed.isUsed('TR021_Event', oldEvent.whatId)))
                            eventIds.add(oldEvent.whatId);
                    }
                }
            if (!eventIds.isEmpty())
                opportunitiesToUpdate = buildOpportunityIndicators(eventIds);
        }
        // Delete
        else if (Trigger.isDelete)
            opportunitiesToUpdate = buildIndicators(Trigger.old);

        /** B - Sauvegarde des indicateurs **/
        if (opportunitiesToUpdate != null && !opportunitiesToUpdate.isEmpty())
            update opportunitiesToUpdate;
    }


    /** 02 - Méthodes de calcul **/
    private static List<Opportunity> incrementIndicators(List<Event> events) {
        /** A - Initialisation des données intermédiaires **/
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, Opportunity> opportunities = null;

        for (Event event : events)
            // Ne traite que les RDV commerciaux initiaux (pas les RDV enfants associés) sinon compteurs du nombre de RDV erronés
            // if (event.isChild == FALSE && (Constants.EVENT_TYPE_R0.equalsIgnoreCase(event.type) || Constants.EVENT_TYPE_R1.equalsIgnoreCase(event.type) || Constants.EVENT_TYPE_R2.equalsIgnoreCase(event.type) || Constants.EVENT_TYPE_RP.equalsIgnoreCase(event.type)) && event.whatId != null && !AlreadyUsed.isUsed('TR021_Event', event.whatId))
            if (event.isChild == FALSE && (event.recordTypeId == RT_RDVCommercial || event.recordTypeId == RT_RDVProspection) && event.whatId != null && !AlreadyUsed.isUsed('TR021_Event', event.whatId))
                opportunityIds.add(event.whatId);

        if (!opportunityIds.isEmpty())
                opportunities = new Map<Id, Opportunity>([SELECT datePremierRPlus__c, datePremierR0__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                                                 dateDernierRPlus__c, dateDernierR0__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                                                 nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                                                 nbR0Effectues__c, nbR0NonEffectues__c, nbR0NonEffectuesAvecDep__c, nbR0Pris__c, nbR0Deplaces__c,
                                                                 nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                                                 nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                                                 nbRDVDevisables__c, interetMarketing__c,
                                                                 statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                                                 statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c
                                                          FROM Opportunity
                                                          WHERE id in :opportunityIds]);

        /** B - Mise à jour des indicateurs **/
        if (!opportunityIds.isEmpty() && opportunities != null && !opportunities.isEmpty()) {
            for (Event event : events)
                // Ne traite que les RDV commerciaux initiaux (pas les RDV enfants associés) sinon compteurs du nombre de RDV erronés
                if (event.isChild == FALSE && (event.recordTypeId == RT_RDVCommercial || event.recordTypeId == RT_RDVProspection) && event.whatId != null)
                    incrementIndicators(opportunities.get(event.whatId), event);

        /** C - Retour des contrats dont il faut sauvegarder les indicateurs **/
            return opportunities.values();
        }
        return null;
    }

    private static List<Opportunity> buildIndicators(List<Event> events) {
        /** A - Initialisation des données intermédiaires **/
        Set<Id> opportunityIds = new Set<Id>();

        for (Event event : events)
            // Ne traite que les RDV commerciaux initiaux (pas les RDV enfants associés) sinon compteurs du nombre de RDV erronés
            if (event.isChild == FALSE && (event.recordTypeId == RT_RDVCommercial || event.recordTypeId == RT_RDVProspection) && event.whatId != null && !AlreadyUsed.isUsed('TR021_Event', event.whatId))
                opportunityIds.add(event.whatId);

        /** B - Mise à jour des indicateurs et retour des contrat à sauvegarder **/
        return buildOpportunityIndicators(opportunityIds);
    }

    private static List<Opportunity> buildOpportunityIndicators(Set<ID> opportunityIds) {
        /** A - Initialisation des données intermédiaires **/
        /* List<Opportunity> opportunities = [SELECT datePremierRPlus__c, datePremierR0__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                                     dateDernierRPlus__c, dateDernierR0__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                                     nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                                     nbR0Effectues__c, nbR0NonEffectues__c, nbR0NonEffectuesAvecDep__c, nbR0Pris__c, nbR0Deplaces__c,
                                                     nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                                     nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                                     nbRDVDevisables__c, interetMarketing__c,
                                                     statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                                     statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c,
                                                     (SELECT type, statutRDV__c, resultatDuRDV__c, interetMarketing__c, activityDate, activityDateTime, isAllDayEvent
                                                      FROM events
                                                      WHERE isChild = FALSE
                                                        AND type IN ('R1', 'R2', 'R+')
                                                      ORDER BY id)
                                              FROM Opportunity
                                              WHERE id in :opportunityIds]; */

        List<Opportunity> opportunities = [SELECT datePremierRPlus__c, datePremierR0__c, datePremierR1__c, datePremierR2__c, datePremierRDV__c,
                                                  dateDernierRPlus__c, dateDernierR0__c, dateDernierR1__c, dateDernierR2__c, dateDernierRDV__c,
                                                  nbRPlusEffectues__c, nbRPlusNonEffectues__c, nbRPlusNonEffectuesAvecDep__c, nbRPlusPris__c, nbRPlusDeplaces__c,
                                                  nbR0Effectues__c, nbR0NonEffectues__c, nbR0NonEffectuesAvecDep__c, nbR0Pris__c, nbR0Deplaces__c,
                                                  nbR1Effectues__c, nbR1NonEffectues__c, nbR1NonEffectuesAvecDep__c, nbR1Pris__c, nbR1Deplaces__c,
                                                  nbR2Effectues__c, nbR2NonEffectues__c, nbR2NonEffectuesAvecDep__c, nbR2Pris__c, nbR2Deplaces__c,
                                                  nbRDVDevisables__c, interetMarketing__c,
                                                  statutPremierRPlus__c, statutPremierR1__c, statutPremierR2__c, statutPremierRDV__c,
                                                  statutDernierRPlus__c, statutDernierR1__c, statutDernierR2__c, statutDernierRDV__c
                                           FROM Opportunity
                                           WHERE id in :opportunityIds];

        // CRM-492 - WDO - Utilisation du mot clés ALL ROWS afin de récupérer les events archivés
        List<Event> events = [SELECT type, statutRDV__c, resultatDuRDV__c, activityDate, activityDateTime, isAllDayEvent, WhatId, recordTypeId, interetMarketing__c
                              FROM Event
                              WHERE isChild = false AND (recordTypeId = :RT_RDVCommercial OR recordTypeId = :RT_RDVProspection) AND IsDeleted = false AND WhatId in :opportunities
                              ORDER BY id ALL ROWS];

        // CRM-492 - WDO - Construction de la liste des opportunités avec leurs events
        Map<Id, List<Event>> opportunityEvents = new Map<Id, List<Event>>();
        for (Opportunity opportunity : opportunities) {
            List<Event> oppEvents = new List<Event>();
            for (Event event : events) {
                if(event.WhatId == opportunity.Id)
                    oppEvents.add(event);
            }
            opportunityEvents.put(opportunity.Id, oppEvents);
        }

        /** B - Mise à jour des indicateurs **/
        for (Opportunity opportunity : opportunities)
            buildIndicators(opportunity, opportunityEvents.get(opportunity.Id));

        /** C - Retour des objets (account et chantier) dont il faut sauvegarder les indicateurs **/
        return opportunities;
    }

    /** 03 - Méthodes de calcul unitaire **/

    private static void incrementIndicators(Opportunity opportunity, Event event) {
      if (event.recordTypeId == RT_RDVCommercial) {
        // MAJ date de 1er et dernier RDV
        Datetime dateRDV = event.isAllDayEvent ? event.activityDate : event.activityDateTime;
        String typeRDV = null;
        String premierRDV = null;
        String dernierRDV = null;
        String premierStatut = null;
        String dernierStatut = null;

        if (Constants.EVENT_TYPE_R0.equalsIgnoreCase(event.type)) {
            typeRDV = 'R0';
            premierRDV = 'datePremierR0__c';
            dernierRDV = 'dateDernierR0__c';
            premierStatut = 'statutPremierR0__c';
            dernierStatut = 'statutDernierR0__c';
        }
        else if (Constants.EVENT_TYPE_R1.equalsIgnoreCase(event.type)) {
            typeRDV = 'R1';
            premierRDV = 'datePremierR1__c';
            dernierRDV = 'dateDernierR1__c';
            premierStatut = 'statutPremierR1__c';
            dernierStatut = 'statutDernierR1__c';
        }
        else if (Constants.EVENT_TYPE_R2.equalsIgnoreCase(event.type)) {
            typeRDV = 'R2';
            premierRDV = 'datePremierR2__c';
            dernierRDV = 'dateDernierR2__c';
            premierStatut = 'statutPremierR2__c';
            dernierStatut = 'statutDernierR2__c';
        }
        else if (Constants.EVENT_TYPE_RP.equalsIgnoreCase(event.type)) {
            typeRDV = 'RPlus';
            premierRDV = 'datePremierRPlus__c';
            dernierRDV = 'dateDernierRPlus__c';
            premierStatut = 'statutPremierRPlus__c';
            dernierStatut = 'statutDernierRPlus__c';
        }

        if (dateRDV != null && premierRDV != null && dernierRDV != null && premierStatut != null && dernierStatut != null) {
            if (opportunity.get(premierRDV) == null || dateRDV < (DateTime) opportunity.get(premierRDV)) {
                opportunity.put(premierRDV,    dateRDV);
                opportunity.put(premierStatut, event.statutRDV__c);
            }
            if (opportunity.get(dernierRDV) == null || dateRDV > (DateTime) opportunity.get(dernierRDV)) {
                opportunity.put(dernierRDV,    dateRDV);
                opportunity.put(dernierStatut, event.statutRDV__c);
            }

            if (opportunity.datePremierRDV__c == null || dateRDV < opportunity.datePremierRDV__c) {
                opportunity.datePremierRDV__c   = dateRDV;
                opportunity.statutPremierRDV__c = event.statutRDV__c;
            }
            if (opportunity.dateDernierRDV__c == null || dateRDV > opportunity.dateDernierRDV__c) {
                opportunity.dateDernierRDV__c   = dateRDV;
                opportunity.statutDernierRDV__c = event.statutRDV__c;
            }
        }

        // MAJ du nombre de RDV
        if (typeRDV != null && event.statutRDV__c != null) {
            String fieldName = null;
            if (Constants.StatutEventPris.equalsIgnoreCase(event.statutRDV__c) || Constants.StatutEventAReaffecter.equalsIgnoreCase(event.statutRDV__c))
                fieldName = 'nb' + typeRDV + 'Pris__c';
            else if (Constants.StatutEventEffectue.equalsIgnoreCase(event.statutRDV__c))
                fieldName = 'nb' + typeRDV + 'Effectues__c';
            else if (Constants.StatutEventNoneffectue.equalsIgnoreCase(event.statutRDV__c))
                fieldName = 'nb' + typeRDV + 'NonEffectues__c';
            else if (Constants.StatutEventNoneffectueAvDep .equalsIgnoreCase(event.statutRDV__c))
                fieldName = 'nb' + typeRDV + 'NonEffectuesAvecDep__c';
            else if (Constants.StatutEventDeplace.equalsIgnoreCase(event.statutRDV__c))
                fieldName = 'nb' + typeRDV + 'Deplaces__c';

            if (fieldName != null)
                opportunity.put(fieldName, (opportunity.get(fieldName) == null ? 0 : (Double)opportunity.get(fieldName)) + 1);

            if (event.resultatDuRDV__c != null && ('Devisable'.equalsIgnoreCase(event.resultatDuRDV__c) || 'Devis transmis'.equalsIgnoreCase(event.resultatDuRDV__c)))
                opportunity.nbRDVDevisables__c = (opportunity.nbRDVDevisables__c == null ? 0 : opportunity.nbRDVDevisables__c) + 1;
        }
      }
      else if (event.recordTypeId == RT_RDVProspection) {
        if (event.interetMarketing__c)
          opportunity.interetMarketing__c = TRUE;
      }
    }

    private static void buildIndicators(Opportunity opportunity, List<Event> events) {
        // Réinitialisation des indicateurs
        opportunity.datePremierRPlus__c           = null;
        opportunity.datePremierR1__c              = null;
        opportunity.datePremierR2__c              = null;
        opportunity.datePremierRDV__c             = null;
        opportunity.dateDernierRPlus__c           = null;
        opportunity.dateDernierR1__c              = null;
        opportunity.dateDernierR2__c              = null;
        opportunity.dateDernierRDV__c             = null;
        opportunity.nbRPlusEffectues__c           = null;
        opportunity.nbRPlusNonEffectues__c        = null;
        opportunity.nbRPlusNonEffectuesAvecDep__c = null;
        opportunity.nbRPlusPris__c                = null;
        opportunity.nbRPlusDeplaces__c            = null;
        opportunity.nbR1Effectues__c              = null;
        opportunity.nbR1NonEffectues__c           = null;
        opportunity.nbR1NonEffectuesAvecDep__c    = null;
        opportunity.nbR1Pris__c                   = null;
        opportunity.nbR1Deplaces__c               = null;
        opportunity.nbR2NonEffectues__c           = null;
        opportunity.nbR2Effectues__c              = null;
        opportunity.nbR2NonEffectuesAvecDep__c    = null;
        opportunity.nbR2Pris__c                   = null;
        opportunity.nbR2Deplaces__c               = null;
        opportunity.nbRDVDevisables__c            = null;
        opportunity.statutPremierRPlus__c         = null;
        opportunity.statutPremierR1__c            = null;
        opportunity.statutPremierR2__c            = null;
        opportunity.statutPremierRDV__c           = null;
        opportunity.statutDernierRPlus__c         = null;
        opportunity.statutDernierR1__c            = null;
        opportunity.statutDernierR2__c            = null;
        opportunity.statutDernierRDV__c           = null;
        opportunity.interetMarketing__c           = FALSE;


        // Calcul des indicateurs
        for (Event event : events)
            incrementIndicators(opportunity, event);
    }
}