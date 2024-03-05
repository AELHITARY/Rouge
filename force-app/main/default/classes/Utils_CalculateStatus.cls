//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_CalculateStatus
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/12/2019
//-- Version     : 1.1
//-- * Classe utilitaire pour le recalcul du statut de différents objets
//-- * 1.1 : KPKCRM_RQM-177 : Mise en place des nouveaux types d'enregistrement des comptes
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_CalculateStatus{

    /**
    * @description Méthode exécutant les règles de mise à jour du type du compte (A appeler dans des classes en dehors des transactions des comptes)
    * @param toUpdate Vrai si un update doit être effectué
    * @param accIds Liste des Ids des comptes
    */
    public static void updateAccountType(Boolean toUpdate, List<String> accIds){
        // A - Initialisation des données intermédiaires 
        /*List<Account> newAccounts = new List<Account>();

        // SOQL - Récupération des informations associés aux comptes
        if(!accIds.isEmpty()) {
            newAccounts = [SELECT Id, Type, forcageType__c, (SELECT AccountId FROM Opportunities LIMIT 1), (SELECT AccountId FROM autreCompteOpportunites__r LIMIT 1), 
                            (SELECT ResultatduRDV__c FROM Events), (SELECT ResultatduRDV__c FROM PersonEvents), (SELECT compte__c FROM compteContrats__r LIMIT 1) 
                            FROM Account WHERE Id IN :accIds];
            updateAccountType(toUpdate, newAccounts, false);
        }*/
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du type du compte (a appeler dans les triggers Account)
    * @param toUpdate Vrai si un update doit être effectué
    * @param newAccounts Liste des comptes
    * @param isAccountTrigger Vrai pour définir que l'appel est effectué dans un trigger Account
    */
    public static void updateAccountType(Boolean toUpdate, List<Account> newAccounts, Boolean isAccountTrigger){
        /*system.debug('### DEBUT Utils_CalculateStatus : updateAccountType');
        // A - Initialisation des données intermédiaires 
        List<Account> accList = new List<Account>();
        Map<String,Boolean> isClient = new Map<String,Boolean>();
        Map<String,Boolean> isProspect = new Map<String,Boolean>();
        Map<String,Boolean> isContact = new Map<String,Boolean>();
        Map<String,Boolean> isPreContact = new Map<String,Boolean>();

        if(!newAccounts.isEmpty()) {
            if(isAccountTrigger) {
                // SOQL - Récupération des informations associés aux comptes
                accList = [SELECT Id, Type, forcageType__c, (SELECT AccountId FROM Opportunities LIMIT 1), (SELECT AccountId FROM autreCompteOpportunites__r LIMIT 1), 
                            (SELECT ResultatduRDV__c FROM Events), (SELECT ResultatduRDV__c FROM PersonEvents), (SELECT compte__c FROM compteContrats__r LIMIT 1) 
                            FROM Account WHERE Id IN :newAccounts];
            } else {
                accList = newAccounts;
            }
            // SOQL - Récupération des informations des devies associés aux comptes
            List<Quote> quoteList = [SELECT Id, Status, AccountId, autreCompte__c FROM Quote WHERE AccountId IN :accList OR autreCompte__c IN :accList]; 
            for(Account acc : accList) {
                if(acc.Opportunities != null  && !acc.Opportunities.isEmpty()) {
                    isPreContact.put(acc.Id, true);
                }
                if(acc.autreCompteOpportunites__r != null  && !acc.autreCompteOpportunites__r.isEmpty()) {
                    isPreContact.put(acc.Id, true);
                }
                if(quoteList != null && !quoteList.isEmpty()) {
                    for(Quote q : quoteList) {
                        if(q.AccountId == acc.Id || q.autreCompte__c == acc.Id) {
                            isProspect.put(acc.Id, true);
                            if(q.Status.contains('Vendu')) {
                                isClient.put(acc.Id, true);
                                break;
                            }
                        }
                    }
                }
                List<Event> allEvents = new List<Event>();
                allEvents.addAll(acc.Events); // Event en tant que compte pro
                allEvents.addAll(acc.PersonEvents); // Event en tant que compte perso
                if(allEvents != null && !allEvents.isEmpty()) {
                    isContact.put(acc.Id, true);
                    for(Event ev : allEvents) { 
                        if(ev.ResultatduRDV__c == 'Devisable' || ev.ResultatduRDV__c == 'Devis transmis') {
                            isProspect.put(acc.Id, true);
                            break;
                        }
                    }
                }
                allEvents = null;
                if(acc.compteContrats__r != null && !acc.compteContrats__r.isEmpty()) {
                    isClient.put(acc.Id, true);
                }
            }
        }
        system.debug('## isClient: '+isClient);
        system.debug('## isProspect: '+isProspect);
        system.debug('## isContact: '+isContact);
        system.debug('## isPreContact: '+isPreContact);
        
        // B - Application des règles de mise à jour 
        for (Account newAccount : newAccounts) {
            system.debug('## Account Id: '+newAccount.Id);
            String newType = newAccount.Type;
            String oldType = newAccount.Type;
            if (String.isNotBlank(newAccount.forcageType__c))
                newAccount.Type = newAccount.forcageType__c;
            else {
                if (isClient.get(newAccount.Id) != null && isClient.get(newAccount.Id))
                    newType = Constants.ACCOUNT_TYPE_CLIENT;
                else if (isProspect.get(newAccount.Id) != null && isProspect.get(newAccount.Id))
                    newType = Constants.ACCOUNT_TYPE_PROSPECT;
                else if (isContact.get(newAccount.Id) != null && isContact.get(newAccount.Id))
                    newType = Constants.ACCOUNT_TYPE_CONTACT;
                else if (isPreContact.get(newAccount.Id) != null && isPreContact.get(newAccount.Id))
                    newType = Constants.ACCOUNT_TYPE_PRECONTACT;
                else newType = Constants.ACCOUNT_TYPE_PISTE;
                // Vérification priorité (pas de retour arriere)
                if(Constants.ACCOUNT_TYPE_PRIORITY.get(newType) < Constants.ACCOUNT_TYPE_PRIORITY.get(oldType))
                    newAccount.Type = newType;
            }
            system.debug('## Account Type: '+newAccount.Type);
        }

        // Mise à jour du compte
        if(!newAccounts.isEmpty() && toUpdate) {
            system.debug('## Mise à jour Account: '+newAccounts);
            update newAccounts;
        }
        system.debug('### FIN Utils_CalculateStatus : updateAccountType');
        */
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD à la création d'un chantier
    * @param chantierList Liste des chantiers
    */
    public static void refreshAccountStatusFromChantier(List<Chantier__c> chantierList){
        List<Account> accListToUpdate = new List<Account>();
        List<String> accIdList =  new List<String>();
        for(Chantier__c cha : chantierList){
            if(String.isNotBlank(cha.autreLocataire__c)) accIdList.add(cha.autreLocataire__c);
            if(String.isNotBlank(cha.autreOccupant__c)) accIdList.add(cha.autreOccupant__c);
            if(String.isNotBlank(cha.autreProprietaire__c)) accIdList.add(cha.autreProprietaire__c);
            if(String.isNotBlank(cha.locataire__c)) accIdList.add(cha.locataire__c);
            if(String.isNotBlank(cha.occupant__c)) accIdList.add(cha.occupant__c);
            if(String.isNotBlank(cha.proprietaire__c)) accIdList.add(cha.proprietaire__c);
        }

        // Mise à jour
        accListToUpdate = updateAccountDates(accIdList);
        if(!accListToUpdate.isEmpty())
            update accListToUpdate;
    }

    /**
    * @description Fonction de mise à jour du champ du type de compte à la création d'un devis
    * @param quoteList Liste des devis
    */
    public static void refreshAccountStatusFromQuote(List<Quote> quoteList){
        Set<Opportunity> oppList = new Set<Opportunity>();
        for(Quote devis : quoteList){
            if(String.isNotBlank(devis.OpportunityId)) oppList.add(new Opportunity(Id = devis.OpportunityId));
        }
        // Mise à jour des projets
        if(!oppList.isEmpty()) {
            List<Opportunity> oppUp = new List<Opportunity>(oppList);
            update oppUp;
        }
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD à la création d'une requête
    * @param caseList Liste des chantiers
    */
    public static void refreshAccountStatusFromCase(List<Case> caseList){
        List<Account> accListToUpdate = new List<Account>();
        List<String> accIdList =  new List<String>();
        for(Case ca : caseList){
            if(ca.AccountId != null) accIdList.add(ca.AccountId);
        }

        // Mise à jour
        accListToUpdate = updateAccountDates(accIdList);
        if(!accListToUpdate.isEmpty())
            update accListToUpdate;
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD et type à la création d'un projet
    * @param oppList Liste des projets
    */
    public static void refreshAccountStatusFromOpportunity(List<Opportunity> oppList){
        List<Account> accListToUpdate = new List<Account>();
        List<String> accIdList = new List<String>();

        // Mise à jour GDPR Date
        accListToUpdate = updateAccountDates(oppList, accIdList);
        if(!accListToUpdate.isEmpty())
            update accListToUpdate;
        // Appel de la méthode de mise à jour du type du compte
        for(Opportunity opp : oppList){
            if(opp.AccountId != null) accIdList.add(opp.AccountId);
            if(opp.autreCompte__c != null) accIdList.add(opp.autreCompte__c);
        }
        //updateAccountType(true, accIdList);
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD et type à la création d'un RDV commercial
    * @param eventList Liste des événements
    */
    public static void refreshAccountStatusFromEvent(List<Event> eventList){
        system.debug('### DEBUT Utils_CalculateStatus.refreshAccountStatusFromEvent');
        List<Opportunity> oppList = new List<Opportunity>();
        List<Account> accListToUpdate = new List<Account>();
        List<String> accIdList =  new List<String>();
        List<String> oppIdList =  new List<String>();
        Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);

        for(Event ev : eventList){
            String whatId = ev.WhatId;
            if(String.isNotBlank(whatId) && whatId.startsWith('006') && ev.RecordTypeId == rtActiviteCommerciale) {
                oppIdList.add(whatId);
            } else if(String.isNotBlank(whatId) && whatId.startsWith('001') && ev.RecordTypeId == rtActiviteCommerciale){
                accIdList.add(whatId);
            }
            if(String.isNotBlank(ev.AccountId))
                accIdList.add(ev.AccountId);
        }

        if(!oppIdList.isEmpty()){
            // SOQL - Récupération des informations des projets associés aux comptes
            oppList = [SELECT Id, AccountId, autreCompte__c FROM Opportunity WHERE Id IN :oppIdList];
            for(Opportunity opp : oppList){
                if(String.isNotBlank(opp.AccountId)) accIdList.add(opp.AccountId);
                if(String.isNotBlank(opp.autreCompte__c)) accIdList.add(opp.autreCompte__c);
            }
            update oppList;
        }
        system.debug('## oppList: '+oppList);
        system.debug('## accIdList: '+accIdList);

        // Mise à jour GDPR Date
        accListToUpdate = updateAccountDates(oppList, accIdList);
        system.debug('## accListToUpdate: '+accListToUpdate);
        if(!accListToUpdate.isEmpty())
            update accListToUpdate;
        // Appel de la méthode de mise à jour du type du compte
        //updateAccountType(true, accIdList);
        system.debug('### FIN Utils_CalculateStatus.refreshAccountStatusFromEvent');
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD et type lors d'un RDV commercial effectué
    * @param eventList Liste des événements
    */
    public static void refreshAccountStatusFromEventEffectue(List<Event> eventList){
        system.debug('### DEBUT Utils_CalculateStatus.refreshAccountStatusFromEventEffectue');
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Account> accListToUpdate = new List<Account>();
        List<String> accIdList =  new List<String>();
        List<String> oppIdList =  new List<String>();
        Id rtActiviteCommerciale = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);

        for(Event ev : eventList) {
            String whatId = ev.WhatId;
            if(ev.StatutRDV__c == Constants.StatutEventEffectue && ev.ActivityDate != null && ev.RecordTypeId == rtActiviteCommerciale){
                if(String.isNotBlank(whatId) && whatId.startsWith('006')) {
                    oppIdList.add(whatId);
                } else if(String.isNotBlank(whatId) && whatId.startsWith('001')){
                    accIdList.add(whatId);
                }
                if(String.isNotBlank(ev.AccountId))
                    accIdList.add(ev.AccountId);
            }
        }

        if(!oppIdList.isEmpty()){
            // SOQL - Récupération des informations des projets associés aux comptes pour MAJ
            oppList = [SELECT Id, AccountId, autreCompte__c FROM Opportunity WHERE Id IN :oppIdList];
            update oppList;
        }
        system.debug('## oppList: '+oppList);
        system.debug('## accIdList: '+accIdList);

        // Mise à jour
        accListToUpdate = updateAccountDates(oppList, accIdList);
        system.debug('## accListToUpdate: '+accListToUpdate);
        if(!accListToUpdate.isEmpty())
            update accListToUpdate;
        // Appel de la méthode de mise à jour du type du compte
        //updateAccountType(true, accIdList);
        system.debug('### FIN Utils_CalculateStatus.refreshAccountStatusFromEventEffectue');
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD lors d'une tâche
    * @param taskList Liste des événements
    */
    public static void refreshAccountStatusFromTask(List<Task> taskList){
        system.debug('### DEBUT Utils_CalculateStatus.refreshAccountStatusFromTask');
        List<Opportunity> oppList = new List<Opportunity>();
        List<Account> accListToUpdate = new List<Account>();
        List<String> accIdList =  new List<String>();
        List<String> devisIdList =  new List<String>();
        List<String> caseIdList =  new List<String>();

        for(Task task : taskList){
            String whatId = task.WhatId;
            // Tâche lié à un compte/contact
            if(String.isNotBlank(whatId) && whatId.startsWith('001')){
                accIdList.add(whatId);
            } 
            // Tâche lié à un devis
            if(String.isNotBlank(whatId) && whatId.startsWith('0Q0')){
                devisIdList.add(whatId);
            } 
            // Tâche lié à une requête
            if(String.isNotBlank(whatId) && whatId.startsWith('500')){
                caseIdList.add(whatId);
            } 
            if(String.isNotBlank(task.AccountId))
                accIdList.add(task.AccountId);
        }

        // SOQL - Récupération des Ids des Accounts
        for(Quote devis : [SELECT Id, AccountId, autreCompte__c FROM Quote WHERE Id IN :devisIdList]){
            if(String.isNotBlank(devis.AccountId)) accIdList.add(devis.AccountId);
            if(String.isNotBlank(devis.autreCompte__c)) accIdList.add(devis.autreCompte__c);
        }
        for(Case req : [SELECT Id, AccountId FROM Case WHERE Id IN :caseIdList]){
            if(String.isNotBlank(req.AccountId)) accIdList.add(req.AccountId);
        }
        system.debug('## accIdList: '+accIdList);

        // Mise à jour
        accListToUpdate = updateAccountDates(accIdList);
        system.debug('## accListToUpdate: '+accListToUpdate);
        if(!accListToUpdate.isEmpty()){
            Map<String, Account> accMap = new Map<String, Account>();
            for(Account acc : accListToUpdate){
                accMap.put(acc.id, acc);
            }
            List<Account> uniqueAccListToUpdate = new List<Account>();
            for(String accId : accMap.keySet()){
                uniqueAccListToUpdate.add(accMap.get(accId));
            }
            update uniqueAccListToUpdate; //update accListToUpdate;
        }
        system.debug('### FIN Utils_CalculateStatus.refreshAccountStatusFromTask');
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD et type lors d'un contrat
    * @param contratList Liste des contrats
    */
    public static void refreshAccountStatusFromContrat(List<KContrat__c> contratList){
        system.debug('### DEBUT Utils_CalculateStatus.refreshAccountStatusFromContrat');
        List<Account> accListToUpdate = new List<Account>();
        List<String> accIds = new List<String>(); 
        Map<String, Account> accountMap = new Map<String, Account>();
        List<String> codeOptList = new List<String>();
        // Récupération Id des comptes
        for(KContrat__c contrat : contratList){
            if(String.isNotBlank(contrat.compte__c)) 
                accIds.add(contrat.compte__c);
            if(String.isNotBlank(contrat.autreCompte__c)) 
                accIds.add(contrat.autreCompte__c);
        }
        if(!accIds.isEmpty()) {
            // Récupération RT compte externe (pour ignorer calcul GDPR)            
            Id rtAccountFSL = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_EXTERNE_RT);

            // SOQL - Récupération infos des comptes
            accountMap = new Map<String, Account>([SELECT Id, dateDernierContact__c, GDPR_dateExpiration__c, Type, RecordTypeId FROM Account WHERE Id IN :accIds]);

            for(KContrat__c contrat : contratList){
                // Mise à jour des champs pour le compte
                if(String.isNotBlank(contrat.compte__c)) {
                    Account acc = accountMap.get(contrat.compte__c);
                    if(contrat.dateFinGarantie__c > acc.dateDernierContact__c) {
                        acc.dateDernierContact__c = contrat.dateFinGarantie__c;
                    } if(acc.Type == Constants.ACCOUNT_TYPE_CLIENT) {
                        acc.relationContractuelle__c = true;
                        // Ignorer calcul GDPR pour compte externe
                        if(acc.RecordTypeId != rtAccountFSL) {
                            acc.GDPR_dateExpiration__c = contrat.dateFinGarantie__c;
                        }
                    }
                    accListToUpdate.add(acc);
                } 
                // Mise à jour des champs pour l'autre compte
                if(String.isNotBlank(contrat.autreCompte__c)) {
                    Account acc = accountMap.get(contrat.autreCompte__c);
                    if(contrat.dateFinGarantie__c > acc.dateDernierContact__c) {
                        acc.dateDernierContact__c = contrat.dateFinGarantie__c;
                    }
                    if(acc.Type == Constants.ACCOUNT_TYPE_CLIENT){
                        acc.relationContractuelle__c = true;
                        // Ignorer calcul GDPR pour compte externe
                        if(acc.RecordTypeId != rtAccountFSL) {
                            acc.GDPR_dateExpiration__c = contrat.dateFinGarantie__c;
                        }
                    }
                    accListToUpdate.add(acc);
                } 
            }
        }

        // Mise à jour
        system.debug('## accListToUpdate: '+accListToUpdate);
        if(!accListToUpdate.isEmpty()){
            Map<String, Account> accMap = new Map<String, Account>();
            for(Account acc : accListToUpdate){
                accMap.put(acc.id, acc);
            }
            List<Account> uniqueAccListToUpdate = new List<Account>();
            for(String accId : accMap.keySet()){
                uniqueAccListToUpdate.add(accMap.get(accId));
            }
            update uniqueAccListToUpdate; //update accListToUpdate;
        }
        // Appel de la méthode de mise à jour du type du compte
        //updateAccountType(true, accIds);
        system.debug('### FIN Utils_CalculateStatus.refreshAccountStatusFromContrat');
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD
    * @param oppList Information de l'utilisateur courant
    * @param accIdList Id des comptes à mettre à jour
    * @return Liste des comptes mis à jour
    */
    private static List<Account> updateAccountDates(List<Opportunity> oppList, List<String> accIdList){
        List<Account> accListToUpdate = new List<Account>();
        for(Opportunity opp : oppList){
            if(opp.AccountId != null) accIdList.add(opp.AccountId);
            if(opp.autreCompte__c != null) accIdList.add(opp.autreCompte__c);
        }

        // Mise à jour
        accListToUpdate = updateAccountDates(accIdList);
        return accListToUpdate;
    }

    /**
    * @description Fonction de mise à jour du champ de dernier contact des comptes et de la date d'expiration RGPD
    * @param accIdList Id des comptes à mettre à jour
    * @return Liste des comptes mis à jour
    */
    private static List<Account> updateAccountDates(List<String> accIdList){
        List<Account> accListToUpdate = new List<Account>();
        if(!accIdList.isEmpty()) {
            // Récupération RT compte externe (pour ignorer calcul GDPR)            
            Id rtAccountFSL = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_EXTERNE_RT);
            Id RT_AccEntity = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);

            // SOQL - Récupération infos des comptes
            for(Account acc : [SELECT Id, dateDernierContact__c, GDPR_dateExpiration__c, Type, RecordTypeId FROM Account WHERE Id IN :accIdList]){
                if(acc.dateDernierContact__c < Date.today()){
                    acc.dateDernierContact__c = Date.today();
                    if(acc.RecordTypeId == RT_AccEntity || acc.Type == Constants.ACCOUNT_TYPE_CLIENT || acc.RecordTypeId == rtAccountFSL) {
                        acc.GDPR_dateExpiration__c = null;
                    } else if(acc.dateDernierContact__c != null) {
                        acc.GDPR_dateExpiration__c = acc.dateDernierContact__c.addYears(3);
                    }
                    accListToUpdate.add(acc);
                }
            }
        }
        return accListToUpdate;
    }    
}