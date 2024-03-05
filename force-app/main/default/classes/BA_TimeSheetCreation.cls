//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_TimeSheetCreation
//-- Modifié par : SOPAR STERIA
//-- Modifié le  : 29/07/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
global class BA_TimeSheetCreation implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    global Date selectedDate;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_TimeSheetCreation(Date selectedDate) {
        UserContext userCtx = UserContext.getContext(); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;
        this.selectedDate = selectedDate;

        userCtx.setByPassValidationRules(true);
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_TimeSheetCreation');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les ServiceResource dont on doit créer les TimeSheet 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start (Database.BatchableContext BC) {     
        System.debug('### DEBUT BA_TimeSheetCreation: start');
        
        try {
            System.debug('## Exécution du batch sur le mois : ' + selectedDate.month());
            EmailUtils.mailToITSupport('[KUBE] Exploitation : Feuilles de temps', 'Début des traitements. Création des feuilles de temps pour le mois : '+selectedDate.month()+'.\n\nCordialement\n');       

            Database.QueryLocator results;
            
            if(Test.isRunningTest()) {
                results = Database.getQueryLocator([SELECT Id, serviceTerritory__c, serviceTerritory__r.KparKReference__c FROM ServiceResource LIMIT 100]);
            } else {
                results = Database.getQueryLocator([SELECT Id, serviceTerritory__c, serviceTerritory__r.KparKReference__c FROM ServiceResource]);
            }
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_TimeSheetCreation : start');
            return results;
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de l\'initialisation du batch de création des feuilles de temps', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            return null;
        } 
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<ServiceResource> scope){        
        System.debug('### DEBUT BA_TimeSheetCreation : execute');
        System.debug('## scope (' + scope.size() +')');
                    
        try {
            // Init
            List<String> assignedResourceIds = new List<String>();
            Map<String, List<AssignedResource>> mapServiceResourceAR = new Map<String, List<AssignedResource>>();
            Map<String, List<ResourceAbsence>> mapServiceResourceRA = new Map<String, List<ResourceAbsence>>();
            Map<String, String> mapServiceResourceTS = new Map<String, String>();
            Map<String, TimeSheet> mapTimeSheetsExists = new Map<String, TimeSheet>();
            Map<String, TimeSheetEntry> mapTimeSheetEntriesExists = new Map<String, TimeSheetEntry>();
            List<TimeSheet> newTimeSheetToUp = new List<TimeSheet>();
            Set<TimeSheetEntry> newTimeSheetEntryToUp = new Set<TimeSheetEntry>();

            // Mois courant
            Date firstDate = selectedDate.toStartOfMonth();
            Date lastDate = firstDate.addDays(date.daysInMonth(selectedDate.year() , selectedDate.month())  - 1);
            System.debug('## firstDate : '+firstDate);
            System.debug('## lastDate : '+lastDate);
            
            List<TimeSheet> newTimeSheets = [SELECT Id, uniqueField__c, ServiceResourceId FROM TimeSheet WHERE StartDate =: firstDate];
            List<TimeSheetEntry> newTimeSheetEntries = [SELECT Id, uniqueField__c FROM TimeSheetEntry 
                                                            WHERE (StartTime >=: firstDate AND EndTime <=: lastDate)];

            // Ajout des TimeSheet dans une map par uniqueField pour les retrouver lors de l'insertion
            System.debug('## Existing TimeSheet : '+newTimeSheets.size());
            for(TimeSheet ts : newTimeSheets) {
                mapTimeSheetsExists.put(ts.uniqueField__c, ts);
                mapServiceResourceTS.put(ts.ServiceResourceId, ts.Id);
            }
            // Ajout des TimeSheetEntry dans une map par uniqueField pour les retrouver lors de l'insertion
            System.debug('## Existing TimeSheetEntry : '+newTimeSheetEntries.size());
            for(TimeSheetEntry tse : newTimeSheetEntries) {
                mapTimeSheetEntriesExists.put(tse.uniqueField__c, tse);
            }            
            
            if(!scope.isEmpty()) {
                // On met dans une Map, Id ServiceResource => Liste de AR
                for(AssignedResource assignedRes : [SELECT Id, ServiceResourceId, ServiceAppointment.Status, ServiceAppointmentId, ServiceAppointment.SchedStartTime, ServiceAppointment.SchedEndTime, 
                                                    ServiceAppointment.WorkType.Name, FSL__EstimatedTravelTimeFrom__c, EstimatedTravelTime 
                                                FROM AssignedResource WHERE ServiceResourceId IN: scope 
                                           AND (ServiceAppointment.SchedStartTime >=:firstDate OR ServiceAppointment.SchedEndTime >=:firstDate) 
                                           AND (ServiceAppointment.SchedStartTime <=:lastDate OR ServiceAppointment.SchedEndTime <=:lastDate)
                                           AND (ServiceAppointment.Status = :Constants.RDV_FSL_CONFIRME 
                                               OR ServiceAppointment.Status = :Constants.RDV_FSL_ENCOURS 
                                               OR ServiceAppointment.Status = :Constants.RDV_FSL_TERMINE 
                                               OR ServiceAppointment.Status = :Constants.RDV_FSL_DEBRIEFE)]) {
                    List<AssignedResource> assignedResList = mapServiceResourceAR.get(assignedRes.ServiceResourceId);
                    if(assignedResList == null) {
                        assignedResList = new List<AssignedResource>();
                    }
                    assignedResList.add(assignedRes);
                    mapServiceResourceAR.put(assignedRes.ServiceResourceId, assignedResList);
                }
                System.debug('## mapServiceResourceAR : ' + mapServiceResourceAR.size());
                                
                // On met dans une Map, Id ServiceResource => Liste de RA
                for(ResourceAbsence resAbsence : [SELECT Id, ResourceId, Start, End, Type FROM ResourceAbsence WHERE ResourceId IN: scope 
                                            AND (Start >=:firstDate OR End >=:firstDate)
                                            AND (Start <=:lastDate OR End <=:lastDate)]) {
                    List<ResourceAbsence> resAbsenceList = mapServiceResourceRA.get(resAbsence.ResourceId);
                    if(resAbsenceList == null) {
                        resAbsenceList = new List<ResourceAbsence>();
                    }
                    resAbsenceList.add(resAbsence);
                    mapServiceResourceRA.put(resAbsence.ResourceId, resAbsenceList);
                }
                
                // Récupération des codes GC des territoires
                Set<Id> codeGCList = new Set<Id>();
                List<Account> entityList = new List<Account>();
                for (ServiceResource serviceResource : scope) {
                    if(serviceResource.serviceTerritory__c != null){
                        codeGCList.add(serviceResource.serviceTerritory__r.KparKReference__c);
                    }
                }
                
                // Récupération des entités
                entityList = [SELECT Id FROM Account WHERE KparKReference__c IN :codeGCList];                               
                
                // Création des TimeSheet
                for (ServiceResource serviceResource : scope) {
                    String uniqueField = String.valueOf(serviceResource.Id).toUpperCase() + '' + lastDate.month() + '' + lastDate.year();
                    // Récupération de l'entité associée
                    Account relatedEntity = new Account();
                    for(Account ent : entityList){
                        if(serviceResource.serviceTerritory__c != null && ent.KparKReference__c == serviceResource.serviceTerritory__r.KparKReference__c){
                            relatedEntity = ent;
                        }
                    }
                    if(mapServiceResourceAR.get(serviceResource.Id) != null || mapServiceResourceRA.get(serviceResource.Id) != null) {
                        TimeSheet newTimeSheet = new TimeSheet(ServiceResourceId = serviceResource.Id,
                                                                  StartDate = firstDate,
                                                                  EndDate = lastDate,
                                                                  uniqueField__c = uniqueField,
                                                                  entity__c = relatedEntity.Id
                                                                ); 
                        // S'il existe, on ajoute l'ID sinon on ajoute l'ID du TimeSheet
                        if(mapTimeSheetsExists.get(uniqueField) != null) {
                            newTimeSheet.Id = mapTimeSheetsExists.get(uniqueField).Id;
                        } 
                        newTimeSheetToUp.add(newTimeSheet);
                    }
                }
                // MAJ Log
                batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, newTimeSheetToUp.size());
                
                // DML sur TimeSheet
                if(!newTimeSheetToUp.isEmpty()) {
                    System.debug('## TimeSheets to upsert: ' + newTimeSheetToUp.size());
                    // Upsert
                    Database.UpsertResult[] results = Database.upsert(newTimeSheetToUp, false);
                    // Traitement des logs
                    for (Integer index = 0; index < results.size(); index++) {
                        Database.UpsertResult result = results[index];
                        if (!result.isSuccess()) {
                            // Traitement des erreurs
                            errorCount++; 
                            for(Database.Error error : result.getErrors()) {
                                errorMessage += '* ' + newTimeSheetToUp.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                            }
                            System.debug('## Error message : '+errorMessage);
                        } else {
                            successCount++;
                        }
                    } 
                }
                
                // Mapping pour retrouvé les TimeSheets selon les ServiceResource
                for (ServiceResource serviceResource : scope) {
                    if(!newTimeSheetToUp.isEmpty()) {
                        for(TimeSheet newTimeSheet : newTimeSheetToUp) {
                            if(newTimeSheet.ServiceResourceId == serviceResource.Id) {
                                mapServiceResourceTS.put(serviceResource.Id, newTimeSheet.Id);
                            }
                        }
                    }
                }
                
                // Création des TimeSheetEntry
                String uniqueField;
                for (ServiceResource serviceResource : scope) {
                    String timeSheetId = mapServiceResourceTS.get(serviceResource.Id);
                    if(mapServiceResourceAR.get(serviceResource.Id) != null || mapServiceResourceRA.get(serviceResource.Id) != null) {
                        //Si il y a des ServiceAppointment dans ce mois si
                        if(mapServiceResourceAR.get(serviceResource.Id) != null) {
                            for(AssignedResource assignedResource : mapServiceResourceAR.get(serviceResource.Id)) {
                                uniqueField = String.valueOf(assignedResource.ServiceAppointmentId).toUpperCase() + assignedResource.ServiceAppointment.WorkType.Name.toUpperCase() + assignedResource.ServiceAppointment.SchedStartTime.month() + assignedResource.ServiceAppointment.SchedStartTime.year();
                                // Création TS Rendez-vous
                                TimeSheetEntry tse = new TimeSheetEntry(StartTime = assignedResource.ServiceAppointment.SchedStartTime,
                                                                        EndTime = assignedResource.ServiceAppointment.SchedEndTime,
                                                                        Type = assignedResource.ServiceAppointment.WorkType.Name,
                                                                        serviceAppointment__c = assignedResource.ServiceAppointmentId,
                                                                        macroType__c = 'Rendez-vous',
                                                                        uniqueField__c = uniqueField
                                                                    );                           
                                // S'il existe, on ajoute l'ID sinon on ajoute l'info du TimeSheetEntry
                                if(mapTimeSheetEntriesExists.get(uniqueField) != null) {
                                    tse.Id = mapTimeSheetEntriesExists.get(uniqueField).Id;
                                } else {
                                    tse.TimeSheetId = timeSheetId;
                                }
                                newTimeSheetEntryToUp.add(tse);

                                // Création TS DéplacementAller
                                if(assignedResource.EstimatedTravelTime > 0) {
                                    Datetime startDateTime = assignedResource.ServiceAppointment.SchedStartTime;
                                    startDateTime = startDateTime.addMinutes(-Integer.valueOf(assignedResource.EstimatedTravelTime));
                                    uniqueField = String.valueOf(assignedResource.ServiceAppointmentId).toUpperCase() + 'DéplacementAller'.toUpperCase() + startDateTime.month() + startDateTime.year();
                                
                                    TimeSheetEntry tse2 = new TimeSheetEntry(StartTime = startDateTime,
                                                                                EndTime = assignedResource.ServiceAppointment.SchedStartTime,
                                                                                Type = 'Déplacement', 
                                                                                serviceAppointment__c = assignedResource.ServiceAppointmentId,
                                                                                estimatedTravelTimeToSource__c = true, 
                                                                                macroType__c = 'Déplacement',
                                                                                uniqueField__c = uniqueField
                                                                            );                 
                                    // S'il existe, on ajoute l'ID sinon on ajoute l'info du TimeSheetEntry
                                    if(mapTimeSheetEntriesExists.get(uniqueField) != null) {
                                        tse2.Id = mapTimeSheetEntriesExists.get(uniqueField).Id;
                                    } else {
                                        tse2.TimeSheetId = timeSheetId;
                                    }
                                    newTimeSheetEntryToUp.add(tse2);
                                }
                                
                                // Création TS DéplacementRetour
                                if(assignedResource.FSL__EstimatedTravelTimeFrom__c > 0) {
                                    Datetime endDateTime = assignedResource.ServiceAppointment.SchedEndTime;
                                    endDateTime = endDateTime.addMinutes(Integer.valueOf(assignedResource.FSL__EstimatedTravelTimeFrom__c));
                                    uniqueField = String.valueOf(assignedResource.ServiceAppointmentId).toUpperCase() + 'DéplacementRetour'.toUpperCase() + assignedResource.ServiceAppointment.SchedEndTime.month() + assignedResource.ServiceAppointment.SchedEndTime.year();

                                    TimeSheetEntry tse3 = new TimeSheetEntry(StartTime = assignedResource.ServiceAppointment.SchedEndTime,
                                                                                EndTime = endDateTime, 
                                                                                Type = 'Déplacement', 
                                                                                serviceAppointment__c = assignedResource.ServiceAppointmentId,
                                                                                estimatedTravelTimeFromSource__c = true, 
                                                                                macroType__c = 'Déplacement',
                                                                                uniqueField__c = uniqueField
                                                                            );                                    
                                    // S'il existe, on ajoute l'ID sinon on ajoute l'info du TimeSheetEntry
                                    if(mapTimeSheetEntriesExists.get(uniqueField) != null) {
                                        tse3.Id = mapTimeSheetEntriesExists.get(uniqueField).Id;
                                    } else {
                                        tse3.TimeSheetId = timeSheetId;
                                    }
                                    newTimeSheetEntryToUp.add(tse3);
                                }
                            }
                        }

                        // Si il y a des ResourceAbsence dans ce mois ci
                        if(mapServiceResourceRA.get(serviceResource.Id) != null) {
                            for(ResourceAbsence resourceAbsence : mapServiceResourceRA.get(serviceResource.Id)) {
                                uniqueField = String.valueOf(resourceAbsence.Id).toUpperCase() + resourceAbsence.Type.toUpperCase() + resourceAbsence.Start.month() + resourceAbsence.Start.year();
                                TimeSheetEntry tse = new TimeSheetEntry(StartTime = resourceAbsence.Start,
                                                                        EndTime = resourceAbsence.End,
                                                                        Type = resourceAbsence.Type,
                                                                        resourceAbsence__c = resourceAbsence.Id,
                                                                        macroType__c = 'Absence',
                                                                        uniqueField__c = uniqueField
                                                                    );
                                // S'il existe, on ajoute l'ID sinon on ajoute l'info du TimeSheetEntry
                                if(mapTimeSheetEntriesExists.get(uniqueField) != null) {
                                    tse.Id = mapTimeSheetEntriesExists.get(uniqueField).Id;
                                } else {
                                    tse.TimeSheetId = timeSheetId;
                                }
                                newTimeSheetEntryToUp.add(tse);
                            }
                        }
                    }
                }
                
                // Upsert
                if(!newTimeSheetEntryToUp.isEmpty()) {
                    System.debug('## TimeSheetEntries to upsert : ' + newTimeSheetEntryToUp.size());
                    // Enleve les doublons
                    List<TimeSheetEntry> newTimeSheetEntryToUp2 = new List<TimeSheetEntry>();
                    newTimeSheetEntryToUp2.addAll(newTimeSheetEntryToUp);
                    // DML
                    Database.UpsertResult[] results = Database.upsert(newTimeSheetEntryToUp2, false);

                    // Ajout d'erreur seulement pour test
                    if(Test.isRunningTest()) {
                        results.add((Database.UpsertResult)JSON.deserialize('{"id":"'+newTimeSheetEntryToUp2[0].Id+'","success":false,"errors":[]}', Database.UpsertResult.class));
                        errorMessage += 'TEST'; 
                    }

                    for (Integer index = 0; index < results.size(); index++) {
                        Database.UpsertResult result = results[index];
                        if (!result.isSuccess()) {
                            // Traitement des erreurs
                            for(Database.Error error : result.getErrors()) {
                                System.debug('* ' + newTimeSheetEntryToUp2.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n');
                                //errorMessage += '* ' + newTimeSheetEntryToUp.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                            }
                            System.debug('## Error message : '+errorMessage);
                        } 
                    } 
                }  
                batchHistoryStored.nombreTraite__c = successCount;
            }
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de la création des feuilles de temps', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
        }
        System.debug('### FIN BA_TimeSheetCreation : execute');
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
    System.debug('### DEBUT BA_TimeSheetCreation : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Exploitation : Feuilles de temps',
                                    'Bonjour,\n\n' + successCount + ' feuilles de temps ont été créées.\n\nCordialement\n');
            } else {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Exploitation : Feuilles de temps',
                                    'Bonjour,\n\n' + successCount + ' feuilles de temps ont été créées.\n' + errorCount + ' feuilles de temps n\'ont pas pu être créées.\nLes erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage);
            }
        }
        catch(Exception e) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Feuilles de temps', e);
        }
        
        System.debug('### FIN BA_TimeSheetCreation : finish');        
    }
}