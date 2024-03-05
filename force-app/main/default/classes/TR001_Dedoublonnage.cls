//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_Dedoublonnage
//-- Modifié par : SOPRA STERIA - Julien Morineau
//-- Modifié le  : 19/07/2018
//-- Version     : 1.2
//-- * 1.2 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- * 1.1 : Gestion de la synchronisation des comptes via batch (CRM-954)
//-- --------------------------------------------------------------------------------- --
public without sharing class TR001_Dedoublonnage {
    private static final Boolean DQE_SYNCHRO = PropertiesUtils.getBooleanValue('dqe.dedup.sync.enabled', true);

    /**
    * @description Passerelle entre les déclencheurs des objets et l'appel Webservice DQE
    * @param userContext Context utilisateur
    * @param objecttype Type de l'objet (Account ou Chantier__c)
    * @param actionType Type de l'action (Add, Update, Delete)
    */
    public static void enqueueDedoublonnageJob(UserContext userContext, String objectType, String actionType) {  
        system.debug('### DEBUT TR001_Dedoublonnage.enqueueDedoublonnageJob');      
        if (!Trigger.isExecuting)
            return;     

        List<SObject> objectToUpdate = new List<SObject>();
        List<SObject> newObjects = new List<SObject>();
        
        // Traitement selon le type de déclencheur
        if (Trigger.isAfter && Trigger.isDelete)
            objectToUpdate=(List<SObject>)Trigger.old;
        // JMU 23/09/2016 - Correction du bug impliquant Signea
        else if(Trigger.isUpdate){
            if(objectType.equalsIgnoreCase('Account')){
                for (Account newTrig : (List<Account>)Trigger.new){
                    Map<Id, Account> oldAccounts = (Map<Id, Account>)Trigger.oldMap;
                    Account oldTrig = oldAccounts == null ? null : oldAccounts.get(newTrig.id);
                    if(oldTrig.codePostal__c != newTrig.codePostal__c || oldTrig.LastName != newTrig.LastName || oldTrig.FirstName != newTrig.FirstName 
                                || oldTrig.rue__c != newTrig.rue__c || oldTrig.ville__c != newTrig.ville__c || oldTrig.PersonEmail != newTrig.PersonEmail
                                || oldTrig.PersonHomePhone != newTrig.PersonHomePhone || oldTrig.PersonMobilePhone != newTrig.PersonMobilePhone
                                || oldTrig.Name != newTrig.Name || oldTrig.Phone != newTrig.Phone || oldTrig.Fax != newTrig.Fax){
                    
                        objectToUpdate.add(newTrig);
                    }
                }
            } else if(objectType.equalsIgnoreCase('Chantier')){
                for (Chantier__c newTrig : (List<Chantier__c>)Trigger.new){
                    Map<Id, Chantier__c> oldChantiers = (Map<Id, Chantier__c>)Trigger.oldMap;
                    Chantier__c oldTrig = oldChantiers == null ? null : oldChantiers.get(newTrig.id);
                    if(oldTrig.proprietaire__c != newTrig.proprietaire__c || oldTrig.autreProprietaire__c != newTrig.autreProprietaire__c
                                || oldTrig.codePostal__c != newTrig.codePostal__c || oldTrig.rue__c != newTrig.rue__c || oldTrig.ville__c != newTrig.ville__c 
                                || oldTrig.complementAdresse__c != newTrig.complementAdresse__c || oldTrig.etage__c != newTrig.etage__c){
                    
                        objectToUpdate.add(newTrig);
                    }
                }
            }
        }
        else
            objectToUpdate=(List<SObject>)Trigger.new;

        if(objectToUpdate.isEmpty())
            return;
        
        // Evite les appels multiples pour le même objet
        for (SObject obj : objectToUpdate) {
            if (!AlreadyUsed.isUsed('TR001_Dedoublonnage.enqueueJob', obj.Id)) {
                newObjects.add(obj);
            }
        }
        if (newObjects.isEmpty())
            return;

        // Appel à la classe Queueable correspondant à l'objet et à l'action envoyés en paramètres
        if(DQE_SYNCHRO && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            system.debug('## MAJ DQE Dedup: '+ newObjects);
            system.debug('## Type d\'action: '+actionType+' - Type d\'objet: '+objectType);
            // Account
            if(objectType.equalsIgnoreCase('Account')){
                System.enqueueJob(new QA_DQEAccount(newObjects,actionType,false,null));
            // Chantier
            } else if(objectType.equalsIgnoreCase('Chantier')){
                System.enqueueJob(new QA_DQEChantier(newObjects, actionType,false,null));
            }
        }
        system.debug('### FIN TR001_Dedoublonnage.enqueueDedoublonnageJob');      
    }
}