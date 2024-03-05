//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_ServiceAppointment
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2022
//-- Version     : 1.2
//-- * 1.2 : Ne pas prendre en compte les notifications GC pour les dépots migré Kube3
//-- * 1.1 : Ajout de la gestion des notifications GC en Synchrone
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_ServiceAppointment {  
    private static final String RT_FSL_RDV = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    private static final String RT_RDV_SERVICE = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final String ACTIVITY_TYPE_INTERVENTION = Constants.ACTIVITY_TYPE_INTERVENTION;
    private static final String ACTIVITY_TYPE_INSTALLATION = Constants.ACTIVITY_TYPE_INSTALLATION; 

    /**
    * @description Règle de mise à jour des objets 
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR022_ServiceAppointment.applyUpdateRules');

        List<ServiceAppointment> newServiceAppointments = (List<ServiceAppointment>)Trigger.new;  
        Map<Id, ServiceAppointment> oldSAs = (Map<Id, ServiceAppointment>)Trigger.oldMap;   
        List<Case> pncList = new List<Case>();
        List<String> pncIdList = new List<String>();
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();  
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(); 
        Set<ID> woIds = new Set<ID>();
        Map<String, WorkOrder> woListStatusMap = new Map<String, WorkOrder>();
        Set<WorkOrder> workOrderToUpdate = new Set<WorkOrder>();
        Set<Case> casesToUpdate = new Set<Case>();
        Set<WorkOrderLineItem> woliToUpdate = new Set<WorkOrderLineItem>();
        String interventionId = null;
        // Utilisé pour les notifs GC Synchrone
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
        List<ServiceAppointment> saSendNotif = new List<ServiceAppointment>();
        GlobalProperties__c synchronisation = null;
        Set<Id> orderIdsList= new Set<Id>();
        Set<Id> savIdsList= new Set<Id>();
      
        // A - Initialisation des données intermédiaires 
        for (ServiceAppointment newSA : newServiceAppointments) {
            ServiceAppointment oldSA = oldSAs == null ? null : oldSAs.get(newSA.id);  

            if((Trigger.isInsert || Trigger.isUpdate) && newSA.ParentRecordId != null && String.valueOf(newSA.ParentRecordId).startsWith('0WO')) {
                woIds.add(newSA.ParentRecordId);
            }
            if((Trigger.isInsert || (Trigger.isUpdate && newSA.Status != oldSA.Status)) && newSA.ParentRecordId != null && String.valueOf(newSA.ParentRecordId).startsWith('0WO')) {
                woListStatusMap.put(newSa.Id, new WorkOrder(Id = newSA.ParentRecordId));
            }
            if((Trigger.isInsert || Trigger.isUpdate) && String.isNotBlank(newSa.customerOrder__c)) {
                orderIdsList.add(newSa.customerOrder__c);
            }
            if((Trigger.isInsert || Trigger.isUpdate) && String.isNotBlank(newSa.afterSalesService__c) && (newSa.workTypeName__c == Constants.ACTIVITY_TYPE_INTERVENTION ||  newSa.workTypeName__c == Constants.ACTIVITY_TYPE_DIAGNOSTIC)) {
                savIdsList.add(newSa.afterSalesService__c);
            }
        }

        // Récupération des informations des WOLI
        if(!woIds.isEmpty()) {
            woliList = [SELECT Id, WorkOrderId, productNonCompliance__c, installDuration__c, installCrewSize__c, Status
                            FROM WorkOrderLineItem 
                            WHERE WorkOrderId IN :woIds];
        
            // Récupération du worktype Intervention
            List<Worktype> inter = [SELECT Id, Name FROM WorkType WHERE Name = :Constants.ACTIVITY_TYPE_INTERVENTION LIMIT 1];
            if(!inter.isEmpty()) {
                interventionId = inter[0].Id;
            }
        }

        // Récupération des informations des NCP
        if(!woliList.isEmpty()) {
            for(WorkOrderLineItem woli : woliList) {
                if(String.isNotBlank(woli.productNonCompliance__c)) {
                    pncIdList.add(woli.productNonCompliance__c);
                }
            }
            if(!pncIdList.isEmpty()) {
                pncList = [SELECT Id, diagnosticDate__c FROM Case 
                            WHERE Id IN :pncIdList AND diagnosticDate__c != null 
                            AND Status != :Constants.REQUETE_STATUS_INPROGRESS AND isClosed = false];
            }
        }
                           
        // B - Application des règles de mise à jour 
        for(ServiceAppointment newSA : newServiceAppointments){
            System.debug('## SA: ' + newSA.Id);
            ServiceAppointment oldSA = oldSAs == null ? null : oldSAs.get(newSA.id);

            if(!woliList.isEmpty() && !pncList.isEmpty() && newSA.workTypeId == interventionId){
                for(WorkOrderLineItem woli : woliList) {
                    if(woli.WorkOrderId == newSA.ParentRecordId){
                        System.debug('## Update PNC linked to: '+woli.WorkOrderId);
                        for(Case pnc : pncList){
                            if(pnc.Id == woli.productNonCompliance__c && pnc.diagnosticDate__c != null){
                                System.debug('## Update Status PNC: '+woli.productNonCompliance__c);
                                pnc.Status = Constants.REQUETE_STATUS_INPROGRESS;
                                casesToUpdate.add(pnc);
                            }
                        }
                    }
                }
            }
            
            if(!woListStatusMap.isEmpty()) {
                WorkOrder wo = woListStatusMap.get(newSA.Id);
                if(wo != null) {
                    System.debug('## Update Status of WorkOrder: '+wo.Id);
                    System.debug('## SA Status: '+newSA.Status);
                    if(newSA.Status == Constants.RDV_FSL_DEBRIEFE || newSA.Status == Constants.RDV_FSL_ANNULE || newSA.Status == Constants.RDV_FSL_TERMINE) {
                        wo.Status = Constants.WO_FSL_TERMINE;
                    } else if(newSA.Status == Constants.RDV_FSL_DEMANDE) {
                        wo.Status = Constants.WO_FSL_DEMANDE;
                    } else {
                        wo.Status = Constants.WO_FSL_ENCOURS;
                    }
                    System.debug('## Status of WorkOrder: '+wo.Status);
                    workOrderToUpdate.add(wo);
                } 
            }

            // RDV FSL - Dé-annulation d'un RDV (mise à jour des WOLI)
            if(Trigger.isUpdate && oldSA != null && newSA.RecordTypeId == RT_FSL_RDV
                && newSA.Status != Constants.RDV_FSL_DEBRIEFE 
                && newSA.Status != Constants.RDV_FSL_TERMINE
                && newSA.Status != Constants.RDV_FSL_ANNULE ) 
            {
                for(WorkOrderLineItem woli : woliList){
                    if(woli.WorkOrderId == newSA.ParentRecordId){
                        System.debug('## Update WOLI: '+woli.Id);
                        woli.Status = Constants.WOLI_FSL_NOUVEAU;
                        woli.installDuration__c = null;
                        woli.installCrewSize__c = null;
                        woliToUpdate.add(woli);
                    }
                }
            }

            // RDV SERVICE - Quelque soit le changement de statut, si on sort du statut "Debriefé", on vide les champs des WOLI
            if(Trigger.isUpdate && oldSA != null && newSA.RecordTypeId == RT_RDV_SERVICE
                && oldSA.Status == Constants.RDV_FSL_DEBRIEFE && newSA.Status != Constants.RDV_FSL_DEBRIEFE
            ) 
            {
                for(WorkOrderLineItem woli : woliList){
                    if(woli.WorkOrderId == newSA.ParentRecordId){
                        System.debug('## Update WOLI: '+woli.Id);
                        woli.Status = Constants.WOLI_FSL_NOUVEAU;
                        woli.installDuration__c = null;
                        woli.installCrewSize__c = null;
                        woliToUpdate.add(woli);
                    }
                }
            }

            // Process notification Synchrone GC
            System.debug('### synchronousGCNotification__c : '+newSA.synchronousGCNotification__c);
            if(newSA.synchronousGCNotification__c==true){
                System.debug('### Process notif Synchrone GC');
                synchronisation = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.sync.sa');    
                DateTime now=System.now();  
                DateTime lastSynchronisation=null; 
                if(synchronisation.dateTimeValue__c != null){            
                    lastSynchronisation=synchronisation.dateTimeValue__c;
                }else{            
                    lastSynchronisation= Datetime.newInstance(2018, 1, 1, 0, 0, 0);    
                }
                /* Debug LOGS

                System.debug('### Last Synchro '+lastSynchronisation);
                System.debug('### now '+now);
                System.debug('### lastSynchronisation '+ lastSynchronisation);
                System.debug('### newSA.fsl_techFlagSynchro__c '+newSA.fsl_techFlagSynchro__c);
                System.debug('### newSA.RecordTypeId '+newSA.RecordTypeId);
                System.debug('### RT_RDV_SERVICE '+RT_RDV_SERVICE);

                Boolean one = newSA.fsl_techFlagSynchro__c == now;
                Boolean two = newSA.fsl_techFlagSynchro__c > lastSynchronisation;
                Boolean three = newSA.fsl_techFlagSynchro__c < now;

                System.debug('### Condition 1  '+one);
                System.debug('### Condition 2.1  '+two);
                System.debug('### Condition 2.2  '+three);
                */

                // CONDITIONS NOTIFICATION GC
                if( (newSA.fsl_techFlagSynchro__c == now || (newSA.fsl_techFlagSynchro__c > lastSynchronisation && newSA.fsl_techFlagSynchro__c < now))
                    && newSA.RecordTypeId != RT_RDV_SERVICE && newSA.entityMigratedToK3__c == false)
                {
                    saSendNotif.add(newSA);
                } else if(!Trigger.isAfter){
                    newSA.fsl_techFlagSynchro__c=now;
                    saToUpdate.add(newSA);
                }            
            }
        }

        if(!woliToUpdate.isEmpty()) {
            List<WorkOrderLineItem> woliListToUpdate = new List<WorkOrderLineItem>();
            woliListToUpdate.addAll(woliToUpdate);
            update woliListToUpdate;
        }
        
        if(!workOrderToUpdate.isEmpty()) {
            List<WorkOrder> workOrderListToUpdate = new List<WorkOrder>();
            workOrderListToUpdate.addAll(workOrderToUpdate);
            update workOrderListToUpdate;
        }

        if(!casesToUpdate.isEmpty()) {
            List<Case> casesListToUpdate = new List<Case>();
            casesListToUpdate.addAll(casesToUpdate);
            update casesListToUpdate;
        }

        // Gestion des notifications Synchrone
        if(!saSendNotif.isEmpty()){
            GlobalProperties__c emailException = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.exception.email');  
            Integer successCounter = 0;
            List<NotificationSA__e> listeNotificationSA = PlatformEvent_fsl_Notifications.getNotificationSA(saSendNotif);
            System.debug('### PE NotificationSA**'+ listeNotificationSA);
            List<Database.SaveResult> results = EventBus.publish(listeNotificationSA);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {                    
                    successCounter=successCounter+1;  
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('**Error publication NotificationSA**: ' + err.getStatusCode() +  ' - ' +  err.getMessage());
                        //Envoyer email alert si publication des notifications est échoué 
                        FieldServiceUtils.serviceEmailAlert(null,err,'Erreur de publication des notificationsSA via platform events ',null,null,emailException);
                    }
                }   
            }
            if(successCounter>0){
                synchronisation.dateTimeValue__c=System.now();      
                Database.update(synchronisation, false);
                
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();   
                String message = '';                    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                GlobalProperties__c emailCheck = FieldServiceUtils.getGlobalPropertiesValue('fsl.platformEvent.check.email'); 
                List<String> sendTo = emailCheck.stringValue__c.split(';');                  
                mail.setToAddresses(sendTo);                          
                mail.setReplyTo('FieldServiceLightning@salesforce.com');
                mail.setSenderDisplayName('Field Service Lightning');                                         
                mail.setSubject(successCounter+' NotificationSA publiées');
                for (NotificationSA__e notif : listeNotificationSA) {  
                    message = message +'<br/><br/><br/>'+notif;
                }
                mail.setHtmlBody(message);                            
                mails.add(mail);   
                if(emailCheck.actif__c)
                Messaging.sendEmail(mails);
            }
            System.debug('### '+successCounter+' events publiés notificationSA**');
        }
        // Mise à jour du champ fsl_techFlagSynchro__c des Rendez-vous
        if(!saToUpdate.isEmpty()) {
            update saToUpdate;
        }

        // LEGACY KUBE 2 : Calcul ancien statut GC
        if(orderIdsList.isEmpty() == false && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            System.debug('## Exec queueable update old status GC: ' + orderIdsList);
            System.enqueueJob(new QA_UpdateOrderStatusGC(orderIdsList));
        } 

        // LEGACY KUBE 2 : Calcul ancien statut GC Dossier SAV
        if(savIdsList.isEmpty() == false && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            System.debug('## Exec queueable update old status GC: ' + savIdsList);
            System.enqueueJob(new QA_UpdateAfterSalesServiceStatusGC(savIdsList));
        } 
        
        System.debug('### FIN TR022_ServiceAppointment.applyUpdateRules');
    }
    
    /**
    * @description Méthode appelée par les trigger MAJ des Order pour créer des tâches au changement de statut
    * @param userContext Objet contexte de l'utilisateur courant
    */
    /*
    public static void createTaskOnStatus(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR022_ServiceAppointment.createTaskOnStatus');
        
        // A - Initialisation et alimentation des données intermédiaires        
        List<ServiceAppointment> newSAsList = new List<ServiceAppointment>();
        Map<Id, ServiceAppointment> oldSAs = (Map<Id, ServiceAppointment>)Trigger.oldMap;
        List<Task> tasksToInsert = new List<Task>();
        
        // On récupère les ids de chaque SA
        for (ServiceAppointment newSA : (List<ServiceAppointment>)Trigger.new) {
            ServiceAppointment oldSA = oldSAs == null ? null : oldSAs.get(newSA.Id);
            if (!AlreadyUsed.isUsed('TR022_ServiceAppointment.createTaskOnStatus', newSA.id)) {
                if(oldSA != null && oldSA.Status != Constants.RDV_FSL_PLANIFIE && newSA.Status == Constants.RDV_FSL_PLANIFIE) {
                    newSAsList.add(newSA);
                }
            }
        }
        
        if(!newSAsList.isEmpty()) {  
            // B - Calcul
            for (ServiceAppointment newSA : newSAsList) {
                System.debug('## SA: ' + newSA.Id);
                // Création de la tâche
                Date shedStartDate = date.newinstance(newSA.SchedStartTime.year(), newSA.SchedStartTime.month(), newSA.SchedStartTime.day());
                Task newTask = new Task(WhatId = newSA.Id,
                                        Status = 'A faire',
                                        Subject = newSA.workTypeName__c,
                                        ActivityDate = shedStartDate);
                
                System.debug('## Tâche: ' + newTask);
                tasksToInsert.add(newTask);
            }
            System.debug(tasksToInsert);
        }

        // C - DML
        if(!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
        
        System.debug('### FIN TR022_ServiceAppointment.createTaskOnStatus');
    }
    */
    
    /**
    * @description Méthode appelée par les trigger MAJ des SA pour créer des ServiceReport
    * @param userContext Information de l'utilisateur courant
    */
    public static void createServiceReport(UserContext userContext) {
        System.debug('### DEBUT TR022_ServiceAppointment.createServiceReport');
        
        // A - Initialisation et alimentation des données intermédiaires      
        Map<Id, ServiceAppointment> oldSAs = (Map<Id, ServiceAppointment>)Trigger.oldMap;  
        List<String> newSAsIdList = new List<String>();
        List<ServiceReport> serviceReportToCreate = new List<ServiceReport>();
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
        
        // On récupère les ids de chaque SA
        for (ServiceAppointment newSA : (List<ServiceAppointment>)Trigger.new) {
            ServiceAppointment oldSA = oldSAs == null ? null : oldSAs.get(newSA.Id);
            if (!AlreadyUsed.isUsed('TR022_ServiceAppointment.createServiceReport', newSA.id)) {
                if(oldSA != null && oldSA.serviceReportToCreate__c != newSA.serviceReportToCreate__c && newSA.serviceReportToCreate__c == true) {
                    System.debug('## SA: ' + newSA.Id);
                    newSAsIdList.add(newSA.Id);
                }
            }
        }
                    
        // B - Mise à jour des données
        System.debug('## newSAsIdList: ' + newSAsIdList);
        if(!newSAsIdList.isEmpty()) {  
            // Appel de la méthode asynchrone pour mettre à jour le RDV après
            createServiceReportAsync(newSAsIdList);
        }

        System.debug('### FIN TR022_ServiceAppointment.createServiceReport');
    }

    /**
    * @description Méthode appelée par les trigger MAJ des SA pour créer des ServiceReport
    * @param userContext Information de l'utilisateur courant
    */
    @future(callout=true)
    private static void createServiceReportAsync(List<String> newSAsIdList) {
        System.debug('### DEBUT TR022_ServiceAppointment.createServiceReportAsync');
        
        // A - Initialisation et alimentation des données intermédiaires      
        List<ServiceAppointment> newSAsList = new List<ServiceAppointment>();
        List<ServiceReport> serviceReportToCreate = new List<ServiceReport>();
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
                    
        // B - Mise à jour des données
        if(!newSAsIdList.isEmpty()) {  
            newSAsList = [SELECT Id, workTypeName__c FROM ServiceAppointment WHERE Id = :newSAsIdList];

            // Récupération de ServiceReportLayout
            Map<String, String> serviceReportLayoutMap = new Map<String, String>();
            for(ServiceReportLayout sRL : [SELECT Id, MasterLabel FROM ServiceReportLayout]) {
                serviceReportLayoutMap.put(sRL.MasterLabel , sRL.Id);
            }
            
            // Création des rapports
            for(ServiceAppointment newSA : newSAsList){
                System.debug('## SA: ' + newSA.Id);
                String reportName = null;
                // On détermine le nom du rapport à utiliser
                if(newSA.workTypeName__c == Constants.ACTIVITY_TYPE_INTERVENTION) {
                    reportName = PropertiesUtils.getStringValue('fsl.serviceReport.install', 'Rapport d\'intervention');
                } else if(newSA.workTypeName__c == Constants.ACTIVITY_TYPE_DIAGNOSTIC) {
                    reportName = PropertiesUtils.getStringValue('fsl.serviceReport.diagnostic', 'Rapport de diagnostic');
                } else {
                    reportName = PropertiesUtils.getStringValue('fsl.serviceReport.control', 'Rapport de contrôle');
                }
                System.debug('## reportName: ' + reportName );
                if(reportName != null) {
                    // Création du rapport
                    ServiceReport SR = new ServiceReport();
                    SR.ParentId = newSA.Id;
                    SR.Template = serviceReportLayoutMap.get(reportName);
                    serviceReportToCreate.add(SR);
                    // MAJ SA
                    newSA.serviceReportToCreate__c = false;
                    saToUpdate.add(newSA);
                }                
            }
        
            if(!serviceReportToCreate.isEmpty()) {
                //insert serviceReportToCreate;
            }
            
            if(!saToUpdate.isEmpty()) {
                //update saToUpdate;
            }
        }

        System.debug('### FIN TR022_ServiceAppointment.createServiceReportAsync');
    }
    
    /**
    * @description Règle de mise à jour des champs selon le Status
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR022_ServiceAppointment.applyValidationRules');

        List<ServiceAppointment> newServiceAppointments = (List<ServiceAppointment>)Trigger.new;
        Map<Id, ServiceAppointment> oldSAs = (Map<Id, ServiceAppointment>)Trigger.oldMap;  

        /** B - Application des règles de mise à jour **/   
        for(ServiceAppointment newSA : newServiceAppointments){
            if(newSA.RecordTypeId == RT_RDV_SERVICE) {
                System.debug('## newSAId: '+newSA.Id); 

                //Status Demandé
                if(newSA.Status == Constants.RDV_FSL_DEMANDE) {

                    //Date de début de planification interdit
                    if(newSA.SchedStartTime != null)
                        newSA.AddError('La Date de début planification est interdite pour ce statut');

                    //Date de fin planification interdit
                    if(newSA.SchedEndTime != null)
                        newSA.AddError('La Date de fin planification est interdite pour ce statut');
                    
                    //Date de transmission interdit
                    if(newSA.dateTransmission__c != null)
                        newSA.AddError('La Date de transmission est interdite pour ce statut');
                    
                    //Date de confirmation interdit
                    if(newSA.fsl_dateConfirmation__c != null)
                        newSA.AddError('La Date de confirmation est interdite pour ce statut');
                    
                    //Date de début réel interdit
                    if(newSA.ActualStartTime != null)
                        newSA.AddError('La Date de début réel est interdite pour ce statut');
                    
                    //Date de fin rééelle interdit
                    if(newSA.ActualEndTime != null)
                        newSA.AddError('La Date de fin rééelle est interdite pour ce statut');
                    
                    //Date de débriefing interdit
                    if(newSA.fsl_dateDebriefing__c != null)
                        newSA.AddError('La Date de débriefing est interdite pour ce statut');
                    
                    //Date d'annulation interdit
                    if(newSA.cancellingDate__c != null)
                        newSA.AddError('La Date d\'annulation est interdite pour ce statut');
                    
                    //Motif d'annulation interdit
                    if(newSA.cancellingReason__c != null)
                        newSA.AddError('Le Motif d\'annulation est interdit pour ce statut');
                    
                    //Commentaires d'annulation interdit
                    if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');

                }
                //Status Planifié
                if(newSA.Status == Constants.RDV_FSL_PLANIFIE) {

                    //Date de début de planification obligatoire
                    if(newSA.SchedStartTime == null)
                        newSA.AddError('La Date de début planification est obligatoire pour ce statut');

                    //Date de fin planification obligatoire
                    if(newSA.SchedEndTime == null)
                        newSA.AddError('La Date de fin planification est obligatoire pour ce statut');
                    
                    //Date de transmission interdit
                    if(newSA.dateTransmission__c != null)
                        newSA.AddError('La Date de transmission est interdite pour ce statut');
                    
                    //Date de confirmation interdit
                    if(newSA.fsl_dateConfirmation__c != null)
                        newSA.AddError('La Date de confirmation est interdite pour ce statut');
                    
                    //Date de début réel interdit
                    if(newSA.ActualStartTime != null)
                        newSA.AddError('La Date de début réel est interdite pour ce statut');
                    
                    //Date de fin rééelle interdit
                    if(newSA.ActualEndTime != null)
                        newSA.AddError('La Date de fin rééelle est interdite pour ce statut');
                    
                    //Date de débriefing interdit
                    if(newSA.fsl_dateDebriefing__c != null)
                        newSA.AddError('La Date de débriefing est interdite pour ce statut');
                    
                    //Date d'annulation interdit
                    if(newSA.cancellingDate__c != null)
                        newSA.AddError('La Date d\'annulation est interdite pour ce statut');
                    
                    //Motif d'annulation interdit
                    if(newSA.cancellingReason__c != null)
                        newSA.AddError('Le Motif d\'annulation est interdit pour ce statut');
                    
                    //Commentaires d'annulation interdit
                    if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');

                }
                //Status Transmis
                if(newSA.Status == Constants.RDV_FSL_TRANSMIS) {

                    //Date de début de planification obligatoire
                    if(newSA.SchedStartTime == null)
                        newSA.AddError('La Date de début planification est obligatoire pour ce statut');

                    //Date de fin planification obligatoire
                    if(newSA.SchedEndTime == null)
                        newSA.AddError('La Date de fin planification est obligatoire pour ce statut');
                    
                    //Date de transmission obligatoire
                    if(newSA.dateTransmission__c == null)
                        newSA.AddError('La Date de transmission est obligatoire pour ce statut');
                    
                    //Date de confirmation interdit
                    if(newSA.fsl_dateConfirmation__c != null)
                        newSA.AddError('La Date de confirmation est interdite pour ce statut');
                    
                    //Date de début réel interdit
                    if(newSA.ActualStartTime != null)
                        newSA.AddError('La Date de début réel est interdite pour ce statut');
                    
                    //Date de fin rééelle interdit
                    if(newSA.ActualEndTime != null)
                        newSA.AddError('La Date de fin rééelle est interdite pour ce statut');
                    
                    //Date de débriefing interdit
                    if(newSA.fsl_dateDebriefing__c != null)
                        newSA.AddError('La Date de débriefing est interdite pour ce statut');
                    
                    //Date d'annulation interdit
                    if(newSA.cancellingDate__c != null)
                        newSA.AddError('La Date d\'annulation est interdite pour ce statut');
                    
                    //Motif d'annulation interdit
                    if(newSA.cancellingReason__c != null)
                        newSA.AddError('Le Motif d\'annulation est interdit pour ce statut');
                    
                    //Commentaires d'annulation interdit
                    if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');

                }
                //Status Confirmé
                if(newSA.Status == Constants.RDV_FSL_CONFIRME) {

                    //Date de début de planification obligatoire
                    if(newSA.SchedStartTime == null)
                        newSA.AddError('La Date de début planification est obligatoire pour ce statut');

                    //Date de fin planification obligatoire
                    if(newSA.SchedEndTime == null)
                        newSA.AddError('La Date de fin planification est obligatoire pour ce statut');
                    
                    //Date de transmission facultatife
                    /*if(newSA.dateTransmission__c == null)
                        newSA.AddError('La Date de transmission est obligatoire pour ce statut');*/
                    
                    //Date de confirmation obligatoire
                    if(newSA.fsl_dateConfirmation__c == null)
                        newSA.AddError('La Date de confirmation est obligatoire pour ce statut');
                    
                    //Date de début réel interdit
                    if(newSA.ActualStartTime != null)
                        newSA.AddError('La Date de début réel est interdite pour ce statut');
                    
                    //Date de fin rééelle interdit
                    if(newSA.ActualEndTime != null)
                        newSA.AddError('La Date de fin rééelle est interdite pour ce statut');
                    
                    //Date de débriefing interdit
                    if(newSA.fsl_dateDebriefing__c != null)
                        newSA.AddError('La Date de débriefing est interdite pour ce statut');
                    
                    //Date d'annulation interdit
                    if(newSA.cancellingDate__c != null)
                        newSA.AddError('La Date d\'annulation est interdite pour ce statut');
                    
                    //Motif d'annulation interdit
                    if(newSA.cancellingReason__c != null)
                        newSA.AddError('Le Motif d\'annulation est interdit pour ce statut');
                    
                    //Commentaires d'annulation interdit
                    if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');

                }
                //Status En cours
                if(newSA.Status == Constants.RDV_FSL_ENCOURS) {

                    //Date de début de planification obligatoire
                    if(newSA.SchedStartTime == null)
                        newSA.AddError('La Date de début planification est obligatoire pour ce statut');

                    //Date de fin planification obligatoire
                    if(newSA.SchedEndTime == null)
                        newSA.AddError('La Date de fin planification est obligatoire pour ce statut');
                    
                    //Date de transmission facultatife
                    /*if(newSA.dateTransmission__c == null)
                        newSA.AddError('La Date de transmission est obligatoire pour ce statut');*/
                    
                    //Date de confirmation obligatoire
                    if(newSA.fsl_dateConfirmation__c == null)
                        newSA.AddError('La Date de confirmation est obligatoire pour ce statut');
                    
                    //Date de début réel obligatoire
                    if(newSA.ActualStartTime == null)
                        newSA.AddError('La Date de début réel est obligatoire pour ce statut');
                    
                    //Date de fin rééelle interdit
                    if(newSA.ActualEndTime != null)
                        newSA.AddError('La Date de fin rééelle est interdite pour ce statut');
                    
                    //Date de débriefing interdit
                    if(newSA.fsl_dateDebriefing__c != null)
                        newSA.AddError('La Date de débriefing est interdite pour ce statut');
                    
                    //Date d'annulation interdit
                    if(newSA.cancellingDate__c != null)
                        newSA.AddError('La Date d\'annulation est interdite pour ce statut');
                    
                    //Motif d'annulation interdit
                    if(newSA.cancellingReason__c != null)
                        newSA.AddError('Le Motif d\'annulation est interdit pour ce statut');
                    
                    //Commentaires d'annulation interdit
                    if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');

                }
                //Status Terminé
                if(newSA.Status == Constants.RDV_FSL_TERMINE) {

                    //Date de début de planification obligatoire
                    if(newSA.SchedStartTime == null)
                        newSA.AddError('La Date de début planification est obligatoire pour ce statut');

                    //Date de fin planification obligatoire
                    if(newSA.SchedEndTime == null)
                        newSA.AddError('La Date de fin planification est obligatoire pour ce statut');
                    
                    //Date de transmission facultatife
                    /*if(newSA.dateTransmission__c == null)
                        newSA.AddError('La Date de transmission est obligatoire pour ce statut');*/
                    
                    //Date de confirmation obligatoire
                    if(newSA.fsl_dateConfirmation__c == null)
                        newSA.AddError('La Date de confirmation est obligatoire pour ce statut');
                    
                    //Date de début réel obligatoire
                    if(newSA.ActualStartTime == null)
                        newSA.AddError('La Date de début réel est obligatoire pour ce statut');
                    
                    //Date de fin rééelle obligatoire
                    if(newSA.ActualEndTime == null)
                        newSA.AddError('La Date de fin rééelle est obligatoire pour ce statut');
                    
                    //Date de débriefing interdit
                    if(newSA.fsl_dateDebriefing__c != null)
                        newSA.AddError('La Date de débriefing est interdite pour ce statut');
                    
                    //Date d'annulation interdit
                    if(newSA.cancellingDate__c != null)
                        newSA.AddError('La Date d\'annulation est interdite pour ce statut');
                    
                    //Motif d'annulation interdit
                    if(newSA.cancellingReason__c != null)
                        newSA.AddError('Le Motif d\'annulation est interdit pour ce statut');
                    
                    //Commentaires d'annulation interdit
                    if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');

                }
                //Status Debriefé
                if(newSA.Status == Constants.RDV_FSL_DEBRIEFE) {

                    //Date de début de planification obligatoire
                    if(newSA.SchedStartTime == null)
                        newSA.AddError('La Date de début planification est obligatoire pour ce statut');

                    //Date de fin planification obligatoire
                    if(newSA.SchedEndTime == null)
                        newSA.AddError('La Date de fin planification est obligatoire pour ce statut');
                    
                    //Date de transmission facultatife
                    /*if(newSA.dateTransmission__c == null)
                        newSA.AddError('La Date de transmission est obligatoire pour ce statut');*/
                    
                    //Date de confirmation obligatoire
                    if(newSA.fsl_dateConfirmation__c == null)
                        newSA.AddError('La Date de confirmation est obligatoire pour ce statut');
                    
                    //Date de début réel obligatoire
                    if(newSA.ActualStartTime == null)
                        newSA.AddError('La Date de début réel est obligatoire pour ce statut');
                    
                    //Date de fin rééelle obligatoire
                    if(newSA.ActualEndTime == null)
                        newSA.AddError('La Date de fin rééelle est obligatoire pour ce statut');
                    
                    //Date de débriefing obligatoire
                    if(newSA.fsl_dateDebriefing__c == null)
                        newSA.AddError('La Date de débriefing est obligatoire pour ce statut');
                    
                    //Date d'annulation interdit
                    if(newSA.cancellingDate__c != null)
                        newSA.AddError('La Date d\'annulation est interdite pour ce statut');
                    
                    //Motif d'annulation interdit
                    if(newSA.cancellingReason__c != null)
                        newSA.AddError('Le Motif d\'annulation est interdit pour ce statut');
                    
                    //Commentaires d'annulation interdit
                    if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');

                }
                //Status Annulé
                if(newSA.Status == Constants.RDV_FSL_ANNULE) {

                    //Date de début de planification facultatife
                    /*if(newSA.SchedStartTime == null)
                        newSA.AddError('La Date de début planification est obligatoire pour ce statut');*/

                    //Date de fin planification facultatife
                    /*if(newSA.SchedEndTime == null)
                        newSA.AddError('La Date de fin planification est obligatoire pour ce statut');*/
                    
                    //Date de transmission facultatife
                    /*if(newSA.dateTransmission__c == null)
                        newSA.AddError('La Date de transmission est obligatoire pour ce statut');*/
                    
                    //Date de confirmation facultatife
                    /*if(newSA.fsl_dateConfirmation__c == null)
                        newSA.AddError('La Date de confirmation est obligatoire pour ce statut');*/
                    
                    //Date de début réel facultatife
                    /*if(newSA.ActualStartTime == null)
                        newSA.AddError('La Date de début réel est obligatoire pour ce statut');*/
                    
                    //Date de fin rééelle facultatife
                    /*if(newSA.ActualEndTime == null)
                        newSA.AddError('La Date de fin rééelle est obligatoire pour ce statut');*/
                    
                    //Date de débriefing interdit
                    if(newSA.fsl_dateDebriefing__c != null)
                        newSA.AddError('La Date de débriefing est interdite pour ce statut');
                    
                    //Date d'annulation obligatoire
                    if(newSA.cancellingDate__c == null)
                        newSA.AddError('La Date d\'annulation est obligatoire pour ce statut');
                    
                    //Motif d'annulation obligatoire
                    if(newSA.cancellingReason__c == null)
                        newSA.AddError('Le Motif d\'annulation est obligatoire pour ce statut');
                    
                    //Commentaires d'annulation facultatifs
                    /*if(newSA.cancellingComment__c != null)
                        newSA.AddError('Les Commentaires d\'annulation sont interdits pour ce statut');*/

                }
            }
        }
        System.debug('### FIN TR022_ServiceAppointment.applyValidationRules');
    }

    /** 
    * @description Méthode appelée pour MAJ la date min d'installation des commandes associés
    * @param userContext Objet contexte de l'utilisateur courant
    **/   
    public static void updateMinInsallationDate(UserContext userContext) {
        System.debug('### DEBUT TR022_ServiceAppointment.updateMinInsallationDate');

        List<ServiceAppointment> newServiceAppointments = (List<ServiceAppointment>)Trigger.new;  
        Map<Id, ServiceAppointment> oldSAs = (Map<Id, ServiceAppointment>)Trigger.oldMap;
        Map<Id, Order> mapOrders = new Map<Id, Order>();
        List<String> orderIds = new List<String>();  
        List<Order> ordersToUpdate = new List<Order>();
        Map<Id, Datetime> saAggregateMap = new Map<Id, Datetime>();

        if (Trigger.isInsert) {
            for (ServiceAppointment newSA : newServiceAppointments) {
                if ((newSA.workTypeName__c == ACTIVITY_TYPE_INTERVENTION || newSA.workTypeName__c == ACTIVITY_TYPE_INSTALLATION) 
                    && newSA.customerOrder__c != null 
                    && newSA.schedStartTime != null 
                    && (newSA.fsl_dateConfirmation__c != null || newSA.dateConfirmationClient__c != null) 
                    && newSA.cancellingDate__c == null) 
                {
                    orderIds.add(newSA.customerOrder__c);
                }
            }
        }
        else if (Trigger.isUpdate) {
            for (ServiceAppointment newSA : newServiceAppointments) {
                ServiceAppointment oldSA = oldSAs.get(newSA.id);
                if ((newSA.workTypeName__c == ACTIVITY_TYPE_INTERVENTION || newSA.workTypeName__c == ACTIVITY_TYPE_INSTALLATION) 
                    && newSA.customerOrder__c != null 
                    && (newSA.schedStartTime != oldSA.schedStartTime 
                    || newSA.fsl_dateConfirmation__c != oldSA.fsl_dateConfirmation__c 
                    || newSA.dateConfirmationClient__c != oldSA.dateConfirmationClient__c 
                    || newSA.cancellingDate__c != oldSA.cancellingDate__c)) 
                {
                    orderIds.add(newSA.customerOrder__c);
                }   
            }
        }
        else if (Trigger.isDelete) {
            for (ServiceAppointment oldSA : (List<ServiceAppointment>)Trigger.old) {
                if ((oldSA.workTypeName__c == ACTIVITY_TYPE_INTERVENTION || oldSA.workTypeName__c == ACTIVITY_TYPE_INSTALLATION) 
                    && oldSA.customerOrder__c != null 
                    && oldSA.schedStartTime != null 
                    && (oldSA.fsl_dateConfirmation__c != null || oldSA.dateConfirmationClient__c != null) 
                    && oldSA.cancellingDate__c == null)
                {
                    orderIds.add(oldSA.customerOrder__c);
                }
            }
        }
        if (!orderIds.isEmpty()) {
            // Récupéraion des RDVs de la commande
            List <AggregateResult>  saAggregate  = [SELECT customerOrder__c, MIN(schedStartTime) minInstallationDate FROM ServiceAppointment WHERE customerOrder__c IN :orderIds
                    AND (workTypeName__c =: ACTIVITY_TYPE_INTERVENTION OR workTypeName__c =: ACTIVITY_TYPE_INSTALLATION)
                    AND schedStartTime != null
                    AND (fsl_dateConfirmation__c != null OR dateConfirmationClient__c != null) 
                    AND cancellingDate__c = null
                    GROUP BY customerOrder__c];

            for (AggregateResult aggr : saAggregate) {
                Id aggregatedOrderId = (Id)aggr.get('customerOrder__c');
                Datetime minInstallationDate = (Datetime)aggr.get('minInstallationDate');
                saAggregateMap.put(aggregatedOrderId, minInstallationDate);
            }
        
            List <Order> orders = [SELECT Id, minInstallationDate__c FROM Order WHERE Id IN :orderIds];    
            for (Order order : orders) {
                if (saAggregateMap.containsKey(order.Id)) {
                    order.minInstallationDate__c = saAggregateMap.get(order.Id);                        
                }else{
                    order.minInstallationDate__c = null;                        
                }
                ordersToUpdate.add(order); 
            }
        }
        // MAj des commandes 
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
        System.debug('### FIN TR022_ServiceAppointment.updateMinInsallationDate');       
    }
}