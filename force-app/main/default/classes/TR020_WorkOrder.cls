//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_WorkOrder
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/02/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_WorkOrder {
    private static final String RT_WORK_ORDER_K3 = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final String RT_WORK_ORDER_FSL = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');

    /**
    * @description Règles de validation pour l'enregistrement
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_WorkOrder.applyValidationRules');
        
        /** A - Initialisation des données intermédiaires **/
        List<WorkOrder> oldWorkOrders = (List<WorkOrder>)Trigger.old;
        Map<Id, WorkOrder> oldWOsMap = (Map<Id, WorkOrder>)Trigger.oldMap;
        Map<Id, WorkOrderLineItem> WOLIMap = new Map<Id, WorkOrderLineItem>(); 
        List<String> woIdsList = new List<String>();
        
        /** B - Application des règles de validation (DELETE) **/         
        if(Trigger.isDelete) { 
            for(WorkOrder oldWorkOrder : oldWorkOrders) 
                if (oldWorkOrder.recordTypeId == RT_WORK_ORDER_K3) {
                    // Ne pas supprimer si le profil est: K/K - FSL Responsable planification ou K/K - FSL Planificateur ou 
                    // K/K - FSL Ressource ou K/K - K par K (Administrateur fonctionnel) ou K/K - K par K (Réf/Données) ou K/K - K par K (RH)
                    if(userContext != null && userContext.getProfile() != null && (userContext.getProfile().Name == 'K/K - FSL Responsable planification' 
                            || userContext.getProfile().Name == 'K/K - FSL Planificateur' 
                            || userContext.getProfile().Name == 'K/K - FSL Ressource' || userContext.getProfile().Name == 'K/K - K par K (Administrateur fonctionnel)' 
                            || userContext.getProfile().Name == 'K/K - K par K (Réf/Données)' 
                            || userContext.getProfile().Name == 'K/K - K par K (RH)')
                    ) {
                        oldWorkOrder.addError('Votre profil ne dispose pas les droits pour supprimer une demande de rendez-vous');
                    }

                    // Ne pas supprimer si la commande est verrouillé
                    if(oldWorkOrder.isOrderLocked__c == true && Trigger.isDelete && Trigger.isBefore){
                        System.debug('## oldWorkOrder.isOrderLocked__c : ' + oldWorkOrder.isOrderLocked__c);
                        oldWorkOrder.addError(Label.order_msg_cantDeleteWorkOrder);
                    } 
                }
        } else {  
            List<WorkOrder> newWorkOrders = (List<WorkOrder>)Trigger.new;  
            for (WorkOrder newWO : newWorkOrders) 
                if (newWO.recordTypeId == RT_WORK_ORDER_K3) {
                    WorkOrder oldWO = oldWOsMap == null ? null : oldWOsMap.get(newWO.id); 
        
                    // Liste des Ids des WO 
                    if(Trigger.isUpdate && Trigger.isBefore && String.isNotBlank(newWO.chantier__c) && newWO.chantier__c != oldWO.chantier__c) {
                        woIdsList.add(newWO.Id);
                    }
                }
    
            // Récupération des demandes de rdv
            if(!woIdsList.isEmpty()) {
                WOLIMap = new Map<Id, WorkOrderLineItem>([SELECT Id, WorkOrderId, AssetId, Asset.chantier__c
                                                                FROM WorkOrderLineItem WHERE WorkOrderId IN :woIdsList]);
            }

            /** C - Application des règles de validation (NO DELETE) **/  
            for(WorkOrder newWO : newWorkOrders) 
                if (newWO.recordTypeId == RT_WORK_ORDER_K3) {
                    WorkOrder oldWO = oldWOsMap == null ? null : oldWOsMap.get(newWO.id); 
                    
                    //Si le RDV dure moins de 15min, message d'erreur
                    if(newWO.Duration == null || (newWO.DurationType == 'Minutes' && newWO.Duration < 15) || (newWO.DurationType == 'Hours' && newWO.Duration < 0.25)) {
                        newWO.Duration.addError(Label.fsl_dureeMinimum15min);
                    }
        
                    // Interdire la mise à jour dans le cas d'un chantier non valide
                    if(Trigger.isUpdate && Trigger.isBefore && String.isNotBlank(newWO.chantier__c) && newWO.chantier__c != oldWO.chantier__c) {
                        for(String woliId : WOLIMap.keySet()){
                            if(WOLIMap.get(woliId).AssetId != null){
                                if(WOLIMap.get(woliId).Asset.chantier__c != null && WOLIMap.get(woliId).WorkOrderId == newWO.Id && WOLIMap.get(woliId).Asset.chantier__c != newWO.chantier__c)
                                {
                                    System.debug('## newWO.chantier__c : ' + newWO.chantier__c);
                                    System.debug('## WOLIMap.get(woliId).Asset.chantier__c : ' + WOLIMap.get(woliId).Asset.chantier__c);
                                    newWO.addError(Label.workOrder_msg_cantChangeChantier);
                                }
                            }
                        }
                    }
                }
        }
        System.debug('### FIN TR020_WorkOrder.applyValidationRules');
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les demandes de RDV
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }        
        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
    }
    
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les demandes de RDV
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyDataUpdateRules(UserContext userContext) {          
        System.debug('### DEBUT TR020_WorkOrder.applyDataUpdateRules');
        
        List<WorkOrder> newWorkOrders = (List<WorkOrder>)Trigger.new;   
        Map<Id, WorkOrder> oldWOs = (Map<Id, WorkOrder>)Trigger.oldMap;     
        List<String> chantiersId = new List<String>(); 
        List<String> accId = new List<String>();
        Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>();
        Map<Id, Account> accounts = new Map<Id, Account>();
        
        // A - Initialisation des données intermédiaires 
        for (WorkOrder newWO : newWorkOrders) {
            WorkOrder oldWO = oldWOs == null ? null : oldWOs.get(newWO.id);
            
            // Faire old != new chantier et faire des labels
            if((Trigger.isInsert || (Trigger.isUpdate && newWO.chantier__c != oldWO.chantier__c)) 
                && Trigger.isBefore && String.isNotBlank(newWO.chantier__c)
                && (String.isBlank(newWO.AccountId) || String.isBlank(newWO.ServiceTerritoryId) || String.isBlank(newWO.PostalCode))) 
            {
                chantiersId.add(newWO.chantier__c);
            }
            // Alimentation du contact
            if(String.isBlank(newWO.ContactId) && String.isNotBlank(newWO.AccountId)) {
                accId.add(newWO.AccountId);
            }
        }
        
        // Récupération chantiers
        if(!chantiersId.isEmpty()) {
            chantiers = new Map<Id, chantier__c>([SELECT Id, proprietaire__c, rue__c, codePostal__c, ville__c, departement__c, 
                                                    proprietaire__r.isPersonAccount, pays__c, serviceEntity__c, serviceEntity__r.serviceTerritory__c, 
                                                    proprietaire__r.contactParDefaut__c, occupant__r.contactParDefaut__c, locataire__r.contactParDefaut__c,
                                                    autreLocataire__r.contactParDefaut__c, autreOccupant__r.contactParDefaut__c,
                                                    occupant__c, autreOccupant__c, locataire__c, autreLocataire__c, complementAdresse__c,
                                                    proprietaire__r.PersonContactId
                                                  FROM Chantier__c 
                                                  WHERE id IN :chantiersId]);     
        }       
        System.debug('## chantiers: ' + chantiers);
        // Récupération des accounts
        if(!accId.isEmpty()) {
            accounts = new Map<Id, Account>([SELECT Id, contactParDefaut__c, PersonContactId, 
                                                IsPersonAccount FROM Account WHERE id IN :accId]);
        }
        System.debug('## accounts: ' + accounts);
           
        // B - Application des règles de mise à jour 
        for(WorkOrder newWO : newWorkOrders){
            WorkOrder oldWO = oldWOs == null ? null : oldWOs.get(newWO.id);
            System.debug('## WorkOrder: '+newWO.Id); 
            
            // Mise à jour Country
            if(newWO.Country == null && (newWO.PostalCode != null || newWO.City != null)) {
                newWO.Country = 'FRANCE';
            }

            // * PROCESSUS POUR WORKORDER KUBE2
            if(newWO.RecordTypeId == RT_WORK_ORDER_FSL || String.isBlank(newWO.RecordTypeId)) {
                if(newWO.StartDate == null) {
                    newWO.StartDate = System.now();
                }
                if(newWO.EndDate == null) {
                    String stringTime = System.Label.fsl_heureDateAuPlusTardParDefaut;
                    Time endTime = Time.newInstance(Integer.valueOf(stringTime.substringBefore(':')), 
                                                    Integer.valueOf(stringTime.substringBetween(':')), 
                                                    Integer.valueOf(stringTime.substringAfterLast(':')), 0);
                    Datetime endDate = DateTime.newInstance(newWO.StartDate.addMonths(3).date(), endTime);
                    newWO.EndDate = endDate;
                }
            }
            
            // * PROCESSUS POUR WORKORDER KUBE3
            else if(newWO.RecordTypeId == RT_WORK_ORDER_K3) {
                
                // Alimentation des infos depuis le chantier
                if(chantiers.get(newWO.chantier__c) != null) {
                    Chantier__c cha = chantiers.get(newWO.chantier__c);

                    // Si le compte est vide on le remplit avec le chantier
                    if(String.isBlank(newWO.AccountId)) {
                        if(String.isNotBlank(cha.proprietaire__c)) {
                            newWO.AccountId = cha.proprietaire__c;
                            newWO.ContactId = cha.proprietaire__r.contactParDefaut__c; 
                        } else {
                            newWO.AccountId.addError(Label.VR_Message_AccountChantierNotDefined);
                        }
                        System.debug('## WorkOrder AccountId: '+newWO.AccountId);
                    }
                    // Si le territoire est vide on le remplit avec le chantier
                    if(String.isBlank(newWO.ServiceTerritoryId)) {
                        if(String.isNotBlank(cha.serviceEntity__c) && String.isNotBlank(cha.serviceEntity__r.serviceTerritory__c)) {
                            newWO.ServiceTerritoryId = cha.serviceEntity__r.serviceTerritory__c;
                        } else {
                            newWO.ServiceTerritoryId.addError(Label.VR_Message_TerritoryChantierNotDefined);
                        }
                        System.debug('## WorkOrder ServiceTerritoryId: '+newWO.ServiceTerritoryId);
                    }
                    // Si l'adresse est vide on la remplit avec le chantier
                    if(String.isBlank(newWO.City) || String.isBlank(newWO.PostalCode)) {
                        if(String.isNotBlank(cha.ville__c) || String.isNotBlank(cha.codepostal__c)) {
                            newWO.City = cha.ville__c;
                            newWO.PostalCode = cha.codepostal__c;
                            newWO.Street = cha.rue__c;
                            newWO.Country = cha.pays__c;
                            newWO.State = cha.departement__c;
                            newWO.additionalAddress__c = cha.complementAdresse__c;
                        } else {
                            newWO.City.addError(Label.VR_Message_AddressChantierNotDefined);
                        }
                        System.debug('## WorkOrder Street: '+newWO.Street);
                        System.debug('## WorkOrder PostalCode: '+newWO.PostalCode);
                        System.debug('## WorkOrder City: '+newWO.City);
                    }

                    // Si le contact est vide on le remplit avec le chantier
                    if(String.isBlank(newWO.ContactId) && cha != null) {
                        if(String.isNotBlank(cha.occupant__c)){
                            newWO.ContactId = cha.occupant__r.contactParDefaut__c;
                        } else if(String.isNotBlank(cha.autreOccupant__c)){
                            newWO.ContactId = cha.autreOccupant__r.contactParDefaut__c;
                        } else if(String.isNotBlank(cha.locataire__c)){
                            newWO.ContactId = cha.locataire__r.contactParDefaut__c;
                        } else if(String.isNotBlank(cha.autreLocataire__c)){
                            newWO.ContactId = cha.autreLocataire__r.contactParDefaut__c;
                        } else if(String.isNotBlank(cha.proprietaire__c)){
                            newWO.ContactId = cha.proprietaire__r.contactParDefaut__c;
                        } 
                        System.debug('## WorkOrder ContactId: '+newWO.ContactId);
                    }
                }
            }
        }
        System.debug('### FIN TR020_WorkOrder.applyDataUpdateRules');
    }
    
    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les demandes de RDV
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_WorkOrder : applyStatusUpdateRules');

        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        Map<Id, WorkOrder> oldWorkOrders = (Map<Id, WorkOrder>)Trigger.oldMap;

        // A - Initialisation des données intermédiaires 
        for (WorkOrder newWorkOrder : (List<WorkOrder>)Trigger.new) {
            //if (!AlreadyUsed.isUsed('TR020_WorkOrder.applyStatusUpdateRules', newWorkOrder.id)) {
                newWorkOrders.add(newWorkOrder);
            //}
        }

        for(WorkOrder newWO : newWorkOrders){
            WorkOrder oldWorkOrder = oldWorkOrders == null ? null : oldWorkOrders.get(newWO.id);
            
            // Vérification des valeurs pour le changement de statut
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {   
                System.debug('## Change status for WorkOrder: ' + newWO.Id);
                
                //Mise à jour statut
                System.debug('## ServiceAppointmentCount: '+newWO.ServiceAppointmentCount);
                System.debug('## cancelledSACount__c: '+newWO.cancelledSACount__c);
                System.debug('## confirmedOrInProgressSACount__c: '+newWO.confirmedOrInProgressSACount__c);
                System.debug('## debriefedTerminedSACount__c: '+newWO.debriefedTerminedSACount__c);
                if(newWO.ServiceAppointmentCount == newWO.cancelledSACount__c && newWO.ServiceAppointmentCount != 0 && newWO.ServiceAppointmentCount != null) {
                    newWO.Status = Constants.WO_FSL_ANNULE;
                } else if(newWO.confirmedOrInProgressSACount__c > 0 && newWO.ServiceAppointmentCount != 0 && newWO.ServiceAppointmentCount != null) {
                    newWO.Status = Constants.WO_FSL_ENCOURS;
                } else if(newWO.debriefedTerminedSACount__c > 0 && newWO.ServiceAppointmentCount == newWO.debriefedTerminedSACount__c 
                    && newWO.ServiceAppointmentCount != 0 && newWO.ServiceAppointmentCount != null)
                {
                    newWO.Status = Constants.WO_FSL_TERMINE;
                } else {
                    newWO.Status = Constants.WO_FSL_DEMANDE;
                }
                System.debug('## WorkOrder Status: '+newWO.Status);

            }

        }
        System.debug('### FIN TR020_WorkOrder : applyStatusUpdateRules');
    }
}