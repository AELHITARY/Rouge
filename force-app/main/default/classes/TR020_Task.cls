//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Task
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/12/2020
//-- Version     : 1.2
//-- * 1.2 - Ajout alimentation ReminderDateTime et IsReminderSet si le créateur est TA
//-- * 1.1 : CRM-915 - Comptes pour les tâches
//-- --------------------------------------------------------------------------------- --
public with sharing class TR020_Task {  
    private static final Id RT_TODO = DAL.getRecordTypeIdByDevName('Task', Constants.TASK_A_FAIRE_RT);
    private static final Id RT_SORTANT = DAL.getRecordTypeIdByDevName('Task', Constants.TASK_APPEL_SORTANT_RT);
    private static final Id RT_ENTRANT = DAL.getRecordTypeIdByDevName('Task',Constants.TASK_APPEL_ENTRANT_RT);
    private static final TaskStatus TS_CLOSED  = [SELECT Id, MasterLabel FROM TaskStatus WHERE isClosed = TRUE ORDER BY SortOrder LIMIT 1];

    /**
    * @description Règle de validation
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
    }

    /**
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        List<Task> newTasks = new List<Task>();
        List<Task> tasksLinkAccount = new List<Task>();
        Map<Id, Task> oldTasks = (Map<Id, Task>)Trigger.oldMap;

        //Liste d'Id des objets à requêter
        Set<Id> contactIds = new Set<Id>();
        Set<Id> chantierIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> kcontratIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        //Maps contenant les objets requêtés qui doivent être utilisés pour retrouver le compte de la tâche
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        Map<Id,Chantier__c> chantiersMap = new Map<Id,Chantier__c>();
        Map<Id,Opportunity> oppsMap = new Map<Id,Opportunity>();
        Map<Id,Case> casesMap = new Map<Id,Case>();
        Map<Id,KContrat__c> kcontratsMap = new Map<Id,KContrat__c>();
        Map<Id,Quote> quotesMap = new Map<Id,Quote>();
              
        // ** A - Initialisation des données intermédiaires 
        for (Task newTask : (List<Task>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR020_Task.applyUpdateRules', newTask.id)) {
                Task oldTask;
                if(Trigger.isUpdate) oldTask = oldTasks.get(newTask.id)==null ? null : oldTasks.get(newTask.id);

                // Si tâche provient de ODIGO                
                newTask.numero_Appele__c = newTask.OdigoCti__Phone_number__c;
                newTask.Numero_Appel__c  = newTask.OdigoCti__IVR_Number__c;             
                if ('Completed'.equalsIgnoreCase(newTask.status)) {
                    newTask.status = TS_CLOSED.MasterLabel;
                }
                        
                if (Trigger.isInsert) {
                    if (newTask.recordTypeId == null || newTask.RecordTypeId == RT_TODO) {
                        if (!String.isEmpty(newTask.subject)) {
                            String subject = newTask.subject.trim();
                            if (subject.startsWithIgnoreCase('Appel entrant') || (newTask.odigoCti__call_type__c != null && newTask.odigoCti__call_type__c.equalsIgnoreCase('Inbound')))
                                newTask.RecordTypeId = RT_ENTRANT;
                            else if (subject.startsWithIgnoreCase('Appel sortant') || subject.startsWithIgnoreCase('Rappel du') || (newTask.odigoCti__call_type__c != null && newTask.odigoCti__call_type__c.equalsIgnoreCase('Outbound')))
                                newTask.RecordTypeId = RT_SORTANT;
                        }
                    }
                    if (!String.isEmpty(newTask.OdigoCti__Phone_number__c)) {
                        newTask.subject += ' N° ' + newTask.OdigoCti__Phone_number__c;
                    }
                }
                if (newTask.WhatId == null && String.isNotBlank(newTask.OdigoCti__Call_Folder_ID__c)) {
                    newTask.WhatId = newTask.OdigoCti__Call_Folder_ID__c;
                }

                // Ajout alimentation ReminderDateTime et IsReminderSet si le créateur est TA
                if (Trigger.isInsert && Trigger.isBefore && userContext != null 
                    && userContext.isCallUser() && newTask.IsReminderSet == false && newTask.ReminderDateTime == null)
                {
                    newTask.IsReminderSet = true;
                    newTask.ReminderDateTime = System.now();
                }

                // Remplissage automatique du champ Compte sur Task 
                if((Trigger.isInsert && String.isNotBlank(newTask.WhatId)) 
                    || (Trigger.isUpdate && newTask.WhatId!=oldTask.WhatId && String.isNotBlank(newTask.WhatId))) 
                {
                    String whatName=newTask.WhatId.getSObjectType().getDescribe().getName();
                    //Compte
                    if(whatName == 'Account') {
                        newTask.compte__c = newTask.WhatId;
                    }
                    /** Cas plus complexes, le traitement doit être différé **/
                    if(whatName == 'Chantier__c') {
                        chantierIds.add(newTask.WhatId);
                        tasksLinkAccount.add(newTask);
                    }
                    else if(whatName == 'Opportunity') {
                        opportunityIds.add(newTask.WhatId);
                        tasksLinkAccount.add(newTask);
                    }
                    else if(whatName == 'Case') {
                        caseIds.add(newTask.WhatId);
                        tasksLinkAccount.add(newTask);
                    }
                    else if(whatName == 'KContrat__c') {
                        kcontratIds.add(newTask.WhatId);
                        tasksLinkAccount.add(newTask);
                    }
                    else if(whatName == 'Quote') {
                        quoteIds.add(newTask.WhatId);
                        tasksLinkAccount.add(newTask);
                    }
                }
                if((Trigger.isInsert && String.isNotBlank(newTask.WhoId)) 
                    || (Trigger.isUpdate && (newTask.WhoId!=oldTask.WhoId || String.isBlank(newTask.WhatId)) && String.isNotBlank(newTask.WhoId))) 
                {
                    if(newTask.WhoId.getSObjectType().getDescribe().getName() == 'Contact') {
                        contactIds.add(newTask.WhoId);
                        tasksLinkAccount.add(newTask);
                    }
                } 
            }
        }

        // ** B - Récupération donnnées intermédiaire 
        if(!contactIds.isEmpty()) {
            contactMap = new Map<Id,Contact>([SELECT AccountId FROM Contact WHERE Id IN :contactIds]);
        }
        if(!chantierIds.isEmpty()) {
            chantiersMap = new Map<Id,Chantier__c>([SELECT proprietaire__c, autreProprietaire__c, locataire__c, autreLocataire__c, occupant__c, autreOccupant__c 
                                                        FROM Chantier__c 
                                                        WHERE Id IN :chantierIds]);
        }
        if(!opportunityIds.isEmpty()) {
            oppsMap = new Map<Id,Opportunity>([SELECT AccountId, autreCompte__c FROM Opportunity WHERE Id IN :opportunityIds]);
        }
        if(!caseIds.isEmpty()) {
            casesMap = new Map<Id,Case>([SELECT AccountId, ContactId, Contact.AccountId, Chantier__c, 
                                            Chantier__r.proprietaire__c, Chantier__r.autreProprietaire__c, Chantier__r.locataire__c, Chantier__r.autreLocataire__c, 
                                            Chantier__r.occupant__c, Chantier__r.autreOccupant__c FROM Case WHERE Id IN :caseIds]);
        }
        if(!kcontratIds.isEmpty()) {
            kcontratsMap = new Map<Id,KContrat__c>([SELECT compte__c, autreCompte__c FROM KContrat__c WHERE Id IN :kcontratIds]);
        }
        if(!quoteIds.isEmpty()) {
            quotesMap = new Map<Id,Quote>([SELECT AccountId, compte__c, autreCompte__c FROM Quote WHERE Id IN :quoteIds]);
        }
        
        // ** C - Application des règles de mise à jour 
        for(Task tsk : tasksLinkAccount) {
            Boolean accountIsSet = false;

            //WhatId
            if(tsk.WhatId != null) {
                String whatName = tsk.WhatId.getSObjectType().getDescribe().getName();
                //Compte
                if(whatName == 'Account') {
                    tsk.compte__c = tsk.WhatId;
                    if(tsk.compte__c != null) accountIsSet = true;
                }
                // Chantier
                if(whatName == 'Chantier__c') {
                    tsk.compte__c = getCompteFromChantier(chantiersMap.get(tsk.WhatId));
                    if(tsk.compte__c != null) accountIsSet = true;
                }
                // Projet
                else if(whatName == 'Opportunity') {
                    tsk.compte__c = getCompteFromOpportunity(oppsMap.get(tsk.WhatId));
                    if(tsk.compte__c != null) accountIsSet = true;
                }
                // Requête
                else if(whatName == 'Case') {
                    tsk.compte__c = getCompteFromCase(casesMap.get(tsk.WhatId));
                    if(tsk.compte__c != null) accountIsSet = true;
                }
                //Contrat K
                else if(whatName == 'KContrat__c') {
                    tsk.compte__c = getCompteFromKContrat(kcontratsMap.get(tsk.WhatId));
                    if(tsk.compte__c != null) accountIsSet = true;
                }
                //Devis
                else if(whatName == 'Quote') {
                    tsk.compte__c = getCompteFromQuote(quotesMap.get(tsk.WhatId));
                    if(tsk.compte__c != null) accountIsSet = true;
                }
            }
            // WhoId - Contact
            if(tsk.WhoId != null) {
                if(!accountIsSet && tsk.WhoId.getSObjectType().getDescribe().getName() == 'Contact') {
                    tsk.compte__c = getCompteFromContact(contactMap.get(tsk.WhoId));
                    if(tsk.compte__c != null) accountIsSet = true;
                }
            }
        }
    }

    /**
    * @description Récupère un Id de Compte à partir d'un contact
    * @param contact Contact à partir duquel récupérer le compte
    * @return Id Retourne l'AccountId du contact s'il existe, null sinon
    */
    public static Id getCompteFromContact(Contact contact) {
        if(contact == null) return null; 
        return contact.AccountId;
    }
    
    /**
    * @description Récupère un Id de Compte à partir d'un chantier
    * @param chantier Chantier à partir duquel récupérer le compte
    * @return Id Retourne l'Id du compte correspondant au proprietaire, locataire ou occupant du chantier s'il en existe, null sinon
    */
    public static Id getCompteFromChantier(Chantier__c chantier) {
        if(chantier == null) return null;
        
        Id compteId = null; 
        if(chantier.proprietaire__c != null)            compteId = chantier.proprietaire__c;
        else if(chantier.autreProprietaire__c != null)  compteId = chantier.autreProprietaire__c;
        else if(chantier.locataire__c != null)          compteId = chantier.locataire__c;
        else if(chantier.autreLocataire__c != null)     compteId = chantier.autreLocataire__c;
        else if(chantier.occupant__c != null)           compteId = chantier.occupant__c;
        else if(chantier.autreOccupant__c != null)      compteId = chantier.autreOccupant__c;
        
        return compteId;
    }
    
    /**
    * @description Récupère un Id de Compte à partir d'un Projet (Opportunity)
    * @param opp Projet à partir duquel récupérer le compte
    * @return Id Retourne l'Id du compte lié au projet s'il existe, null sinon
    */
    public static Id getCompteFromOpportunity(Opportunity opp) {
        if(opp == null) return null;
        
        Id compteId = null;
        if(opp.AccountId != null) compteId = opp.AccountId;
        else if(opp.autreCompte__c != null) compteId = opp.autreCompte__c;
        
        return compteId;
    }

    /**
    * @description Récupère un Id de Compte à partir d'une requête
    * @param case Requête à partir duquel récupérer le compte
    * @return Id Retourne l'AccountId de la requête s'il existe, null sinon
    */
    public static Id getCompteFromCase(Case req) {
        if(req == null) return null; 

        Id compteId = null;
        if(req.AccountId != null)                               compteId = req.AccountId;
        else if(req.Contact.AccountId != null)                  compteId = req.Contact.AccountId;
        else if(req.Chantier__r.proprietaire__c != null)        compteId = req.Chantier__r.proprietaire__c;
        else if(req.Chantier__r.autreProprietaire__c != null)   compteId = req.Chantier__r.autreProprietaire__c;
        else if(req.Chantier__r.locataire__c != null)           compteId = req.Chantier__r.locataire__c;
        else if(req.Chantier__r.autreLocataire__c != null)      compteId = req.Chantier__r.autreLocataire__c;
        else if(req.Chantier__r.occupant__c != null)            compteId = req.Chantier__r.occupant__c;
        else if(req.Chantier__r.autreOccupant__c != null)       compteId = req.Chantier__r.autreOccupant__c;
        return compteId;
    }

    /**
    * @description Récupère un Id de Compte à partir d'un Contrat K
    * @param contrat Contrat à partir duquel récupérer le compte
    * @return Id Retourne l'Id du compte du contrat s'il existe, null sinon
    */
    public static Id getCompteFromKContrat(KContrat__c contrat) {
        if(contrat == null) return null;

        Id compteId = null;
        if(contrat.compte__c != null) compteId = contrat.compte__c; //actuellement compte__c obligatoire
        else if(contrat.autreCompte__c != null) compteId = contrat.autreCompte__c;
        return compteId;
    }

    /**
    * @description Récupère un Id de Compte à partir d'un Devis
    * @param devis Devis à partir duquel récupérer le compte
    * @return Id Retourne l'Id du compte du devis s'il existe, null sinon
    */
    public static Id getCompteFromQuote(Quote devis) {
        if(devis == null) return null;

        Id compteId = null;
        if(devis.AccountId != null)             compteId = devis.AccountId;
        else if(devis.compte__c != null)        compteId = devis.compte__c;
        else if(devis.autreCompte__c != null)   compteId = devis.autreCompte__c;

        return compteId;
    }
}