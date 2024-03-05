//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_CalendrierDashboard
//-- Modifié par : SOPRA STERIA - Julien MORINEAU
//-- Modifié le  : 31/08/2017
//-- Version     : 1.1
//-- * Refonte du calendrier (Retour 48 de la stabilisation Kube 2.5)
//-- --------------------------------------------------------------------------------- --
public with sharing class Ctrl_CalendrierDashboard {

    // Stockage des valeurs des différentes picklists
    public String resultatRDVListDepl { get; set; }
    public String resultatRDVListEff { get; set; }
    public String resultatRDVListNonConf { get; set; }
    public String resultatRDVListNonEff { get; set; }
    public String resultatRDVListNonEffDepl { get; set; }
    public String resultatRDVListPris { get; set; }
    public String priorityTaskList { get; set; }{ priorityTaskList = '["Faible","Normal","Élevé"]'; }
    public String statutList { get; set; }{ statutList = '["Déplacé","Effectué","Non confirmé","Non effectué","Non effectué (avec déplacement)", "Pris"]'; }
    public String statutTaskList { get; set; }{ statutTaskList = '["A faire","Terminé"]'; }

    // Stockage des RecordTypes d'évènements
    public Id getrtEventCommercial(){
        return DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
    }
    public Id getrtEventProspection(){
        return DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_PROSPECTION_RT);
    }
    public Id getrtEventAnnexe(){
        return DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_ANNEXE_Vendeur_RT);
    }
    public Id getrtTaskVendeur(){
        return DAL.getRecordTypeIdByDevName('Task',Constants.TASK_VENDEUR_RT);
    }
    public String getBaseURL(){
        return System.URL.getSalesforceBaseUrl().toExternalForm();
    }

    public String selectedDate { get; set; }{
        Datetime ajd = Date.today();
        String ajdFormate = ajd.format('dd/MM/yyyy');
        system.debug('ajdFormate : ' + ajdFormate);
        selectedDate = ajdFormate;
    }

    /**
    * @description Fonction appelée lors l'ouverture de la page pour incrémentation le champ compteurCalendrierDashboard__c de UserStats
    */
    public void insertUserStats() {
        Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurCalendrierDashboard__c');
    }

    /**
    * @description Constructeur
    * @return Ctrl_CalendrierDashboard 
    */
    public Ctrl_CalendrierDashboard() {
        if(Apexpages.currentPage().getParameters().get('changeDate') != null && Apexpages.currentPage().getParameters().get('changeDate') != '')
        selectedDate = Apexpages.currentPage().getParameters().get('changeDate');
        system.debug('selectedDate : ' + selectedDate);

        // Construction de la liste dépendante StatutRDV/RésultatDuRDV
        Map<String,List<String>> statutResultatRDV = PicklistUtils.GetDependentOptions('Event', 'StatutRDV__c', 'ResultatduRDV__c');
        system.debug('statutResultatRDV : ' + statutResultatRDV);
        
        List<String> resultatRDVdepl = statutResultatRDV.get(Constants.StatutEventAReaffecter);
        List<String> resultatRDVeff = statutResultatRDV.get(Constants.StatutEventEffectue);
        List<String> resultatRDVnonconf = statutResultatRDV.get(Constants.StatutEventNonConfirme);
        List<String> resultatRDVnoneff = statutResultatRDV.get(Constants.StatutEventNoneffectue);
        List<String> resultatRDVnoneffdepl = statutResultatRDV.get(Constants.StatutEventNoneffectueAvDep);
        List<String> resultatRDVpris = statutResultatRDV.get(Constants.StatutEventPris);

        resultatRDVListDepl = JSON.serialize(resultatRDVdepl);
        resultatRDVListEff = JSON.serialize(resultatRDVeff);
        resultatRDVListNonConf = JSON.serialize(resultatRDVnonconf);
        resultatRDVListNonEff = JSON.serialize(resultatRDVnoneff);
        resultatRDVListNonEffDepl = JSON.serialize(resultatRDVnoneffdepl);
        resultatRDVListPris = JSON.serialize(resultatRDVpris);
    }

    /**
    *
    *   REMOTEACTION
    *   Récupération des évènements du jour pour affichage selon liste de vendeurs
    *
    **/
    @RemoteAction
    public static List<Event> getSelectedEvents(Integer jour, Integer mois, Integer annee){
        List<Event> eventToReturn = new List<Event>();
        DateTime startDate = DateTime.newInstance(annee, mois+1, jour,0,0,0);
        DateTime endDate = DateTime.newInstance(annee, mois+1, jour,23,59,59);

        system.debug('### DEBUT getSelectedEvents');
        system.debug('### StartDateTime : ' + startDate);
        system.debug('### EndDateTime : ' + endDate);
        try {
            eventToReturn = [SELECT Id, Type, Subject, OwnerId, StatutRDV__c, ResultatduRDV__c,
                                    StartDateTime, EndDateTime,ActivityDate, WhoId, WhatId, who.name, Decisionnaire__c,
                                    NbBAL50__c , NbFoire43__c, NbPhone55__c, NbStandGM42__c, NbStandMarch54__c, NbTAP51__c,
                                    Motifsannulationclient__c, MotifsAnnulationnondevisable__c, Motifsannulationvendeur__c, debriefe__c
                                FROM Event WHERE OwnerId=:UserInfo.getUserId() AND
                                    ((StartDateTime >= :startDate AND StartDateTime <= :endDate) OR (EndDateTime >= :startDate AND EndDateTime <= :endDate))
                                ORDER BY StartDateTime DESC];

            system.debug('### Number of events : ' + eventToReturn.size());
            system.debug('### FIN getSelectedEvents');
            return eventToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Récupération des taches du jour pour affichage selon liste de vendeurs
    *
    **/
    @RemoteAction
    public static List<Task> getSelectedTasks(Integer jour, Integer mois, Integer annee){
        List<Task> taskToReturn = new List<Task>();
        Date actualDate = Date.newInstance(annee, mois+1, jour);

        system.debug('### DEBUT getSelectedTasks');
        system.debug('### ActivityDate : ' + actualDate);
        try {
            taskToReturn = [SELECT Id, Type, Subject, OwnerId, Priority, ActivityDate, StatutRDV__c, ResultatduRDV__c, WhatId, WhoId, Status, Owner.Name, Description
                                FROM Task WHERE OwnerId=:UserInfo.getUserId() AND ActivityDate = :actualDate
                            ORDER BY ActivityDate DESC];

            system.debug('### Number of tasks : ' + taskToReturn.size());
            system.debug('### FIN getSelectedTasks');
            return taskToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Mise à jour d'un évènement commercial
    *
    **/
    @RemoteAction
    public static Event updateEventCommercial(String eventId, String eventStatut, String eventDeci, String eventResultat, String eventMotif){
        List<Event> updatedEvent = new List<Event>();

        system.debug('### DEBUT updateEventCommercial');
        try {
            system.debug('### Event Id : ' + eventId);
            updatedEvent = [SELECT Id, StatutRDV__c, ResultatduRDV__c, Decisionnaire__c,
                        Motifsannulationclient__c, MotifsAnnulationnondevisable__c, Motifsannulationvendeur__c FROM Event WHERE Id = :eventId LIMIT 1];

            updatedEvent[0].StatutRDV__c = eventStatut;
            if(eventDeci == 'Oui') updatedEvent[0].Decisionnaire__c = true;
            else updatedEvent[0].Decisionnaire__c = false;
            updatedEvent[0].ResultatduRDV__c = eventResultat;
            if(eventResultat == 'Annulé/client avec report de RDV' || eventResultat == 'Annulé/client sans report de RDV' ||
                                eventResultat == 'Refus de visite' || eventResultat == 'imprévu dernière minute' || eventResultat == 'Absent/A rappeler') updatedEvent[0].Motifsannulationclient__c = eventMotif;
            if(eventResultat == 'Non devisable') updatedEvent[0].MotifsAnnulationnondevisable__c = eventMotif;
            if(eventResultat == 'Annulé/vendeur') updatedEvent[0].Motifsannulationvendeur__c = eventMotif;

            update updatedEvent[0];
            system.debug('### FIN updateEventCommercial');
            return updatedEvent[0];
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Mise à jour d'un évènement de prospection
    *
    **/
    @RemoteAction
    public static Event updateEventProspection(String eventId, Decimal fieldValue, Decimal fieldValueTAP, String fieldName){
        List<Event> updatedEvent = new List<Event>();

        system.debug('### DEBUT updateEventProspection');
        try {
            system.debug('### Event Id : ' + eventId);
            updatedEvent = [SELECT Id, NbBAL50__c , NbFoire43__c, NbPhone55__c, NbStandGM42__c, NbStandMarch54__c, NbTAP51__c, debriefe__c FROM Event WHERE Id = :eventId LIMIT 1];
            if(fieldValue == 0) fieldValue = null;
            if(fieldValueTAP == 0) fieldValueTAP = null;
            if(fieldName == 'BAL' || fieldName == 'TAP'){
                updatedEvent[0].NbBAL50__c = fieldValue;
                updatedEvent[0].NbTAP51__c = fieldValueTAP;
            }
            if(fieldName == 'phone') updatedEvent[0].NbPhone55__c = fieldValue;
            if(fieldName == 'marché') updatedEvent[0].NbStandMarch54__c = fieldValue;
            if(fieldName == 'GM') updatedEvent[0].NbStandGM42__c = fieldValue;
            if(fieldName == 'foire') updatedEvent[0].NbFoire43__c = fieldValue;

            update updatedEvent[0];
            system.debug('### FIN updateEventProspection');
            return updatedEvent[0];
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    *
    *   REMOTEACTION
    *   Mise à jour d'une tache
    *
    **/
    @RemoteAction
    public static Task updateTask(String taskId, String taskPriority, String taskStatut, String taskDescription){
        Task updatedTask = new Task();

        system.debug('### DEBUT updateTask');
        try {
            system.debug('### Task Id : ' + taskId);
            updatedTask.Id = taskId;
            updatedTask.Priority = taskPriority;
            updatedTask.Status = taskStatut;
            updatedTask.Description = taskDescription;

        update updatedTask;
        system.debug('### FIN updateTask');
        return updatedTask;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    // Refresh de la page lors d'un changement de date
    public PageReference refreshDate() {
        system.debug('selectedDate : ' + selectedDate);
        PageReference pageVF = Page.VF_CalendrierDashboard;
        pageVF.getParameters().put('changeDate', selectedDate);
        pageVF.setRedirect(true);
        return pageVF;
    }
}