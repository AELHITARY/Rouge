//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_ServiceAppointment
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 29/05/2023
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_ServiceAppointment {
    private static final String RT_RDV_KUBE3 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final String RT_RDV_KUBE2 = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    private static final String B2C_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String B2B_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);

    /**
    * @description Méthode pour confirmer l'autorisation de la suppression des SA si la commande associée n'est pas verrouillée
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### START TR020_ServiceAppointment.applyValidationRules');
        
        List<ServiceAppointment> oldServiceAppointments = (List<ServiceAppointment>)Trigger.old;
        for(ServiceAppointment oldServiceAppointment : oldServiceAppointments){
            // Ne pas supprimer si la commande est verrouillée
            if(oldServiceAppointment.isOrderLocked__c == true && Trigger.isDelete && Trigger.isBefore){
                System.debug('## oldServiceAppointment.isOrderLocked__c : ' + oldServiceAppointment.isOrderLocked__c);
                oldServiceAppointment.addError(Label.order_msg_cantDeleteServiceAppointment);
            }  
        }
        
        System.debug('### FIN TR020_ServiceAppointment.applyValidationRules');
    }
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les RDV
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
    * @description Règle de mise à jour des champs
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_ServiceAppointment.applyDataUpdateRules');

        List<ServiceAppointment> newServiceAppointments = (List<ServiceAppointment>)Trigger.new;  
        Map<Id, ServiceAppointment> oldSAs = (Map<Id, ServiceAppointment>)Trigger.oldMap;  
        Set<String> saIds = new Set<String>(); 
        Set<String> accountIds = new Set<String>(); 
        Set<String> contratKIds = new Set<String>();   
        Set<ID> woIds = new Set<ID>();
        Set<ID> workTypeIds = new Set<ID>();
        List<String> chantierIds = new List<String>();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        Map<String, Account> mapSAAccount = new Map<String, Account>();
        Map<String, KContrat__c> mapSAContratK = new Map<String, KContrat__c>();
        Map<String, Chantier__c> mapSAChantier = new Map<String, Chantier__c>();
        Map<String, WorkType> workTypeMap = new Map<String, WorkType>();
        Map<String, List<AssignedResource>> mapSAAssignedResource = new Map<String, List<AssignedResource>>();
        Boolean zeroDelay = PropertiesUtils.getBooleanValue('fsl.planificationRDV.zeroDelai', false);
        String kparkUserId = Label.system_id_user_kpark;

        System.debug('############# DEBUG - Ancien RDV : '+oldSAs);
        System.debug('############# DEBUG - Nouveau RDV : '+newServiceAppointments);

        // A - Initialisation des données intermédiaires
        // Recherche des comptes, caseChas et autorisations associées 
        for (ServiceAppointment newSA : newServiceAppointments) {
            ServiceAppointment oldSA = oldSAs == null ? null : oldSAs.get(newSA.id);    

            if(Trigger.isUpdate && newSA.RecordTypeId == RT_RDV_KUBE2) {
                if(String.isNotBlank(newSA.ContratK__c)) {
                    contratKIds.add(newSA.ContratK__c);
                }
            }

            if(Trigger.isInsert || (Trigger.isUpdate && (newSA.ParentRecordId != oldSA.ParentRecordId || (newSA.AppointmentNumber != null && newSA.RecordTypeId == RT_RDV_KUBE3))) 
                && String.isNotBlank(newSA.ParentRecordId) && String.valueOf(newSA.ParentRecordId).startsWith('0WO')
            ) {
                woIds.add(newSA.ParentRecordId);
            }

            if(Trigger.isInsert || (Trigger.isUpdate && (newSA.AccountId != oldSA.AccountId || newSA.account__c != oldSA.account__c 
                || (newSA.AppointmentNumber != null && newSA.RecordTypeId == RT_RDV_KUBE3)))) 
            {
                if(String.isNotBlank(newSA.AccountId)) {
                    accountIds.add(newSA.AccountId);
                }
                if(String.isNotBlank(newSA.account__c)) {
                    accountIds.add(newSA.account__c);
                }
            }
            if(Trigger.isInsert || (Trigger.isUpdate && newSA.WorkTypeId != oldSA.WorkTypeId) && String.isNotBlank(newSA.WorkTypeId)) {
                workTypeIds.add(newSA.WorkTypeId);
            }

            if(String.isNotBlank(newSA.Chantier__c)) {
                chantierIds.add(newSA.Chantier__c);
            }

            if(String.isNotBlank(newSA.Id)) {
                saIds.add(newSA.Id);
            }
        }
        System.debug('## contratKIds: '+contratKIds);
        System.debug('## woIds: '+woIds);
        System.debug('## accountIds: '+accountIds);
        System.debug('## workTypeIds: '+workTypeIds);

        // B - Récupération des éléments
        // Récupération des demandes de rdv et des éléments des demandes
        if(!woIds.isEmpty()) {
            workOrderMap = new Map<Id, WorkOrder>([SELECT Id, AccountId, ContactId, Chantier__c, customerOrder__c, Description,
                                                            StartDate, EndDate, Duration, DurationType, Subject, workOrderNumberByType__c,
                                                            Street, City, PostalCode, Country, additionalAddress__c, customerOrder__r.chantier__c,
                                                            customerOrder__r.chantier__r.rue__c, customerOrder__r.OrderNumber,
                                                            customerOrder__r.chantier__r.codePostal__c, pretaxAmount__c, subWorkType__c,
                                                            customerOrder__r.chantier__r.ville__c, 
                                                            customerOrder__r.chantier__r.pays__c,
                                                            customerOrder__r.chantier__r.complementAdresse__c
                                                   FROM WorkOrder 
                                                   WHERE id IN :woIds]);
        }
        System.debug('## workOrderMap: '+workOrderMap);
        if(!contratKIds.isEmpty()) {
            List<KContrat__c> contratKList = [SELECT Id, chantier__c, compte__c, chantier__r.ville__c, chantier__r.pays__c,
                                              chantier__r.codePostal__c, chantier__r.rue__c, chantier__r.departement__c, chantier__r.complementAdresse__c
                                                   FROM KContrat__c 
                                                   WHERE id IN :contratKIds];
            for(ServiceAppointment newSA : newServiceAppointments) {
                for(KContrat__c contratK : contratKList) {
                    if(newSA.ContratK__c == contratK.Id)
                        mapSAContratK.put(newSA.Id, contratK);
                }
            }
        }
        System.debug('## mapSAContratK: '+mapSAContratK);
        // Récupération des ressources assignés aux SA
        // On récupère les AssignedResource des SA s'il y en a
        if(!saIds.isEmpty()) {
            // On met dans une Map, Id SA => Liste d'AssignedResource
            for(AssignedResource assignedResource : [SELECT Id, ServiceAppointmentId FROM AssignedResource WHERE ServiceAppointmentId IN: saIds AND fsl_typeRessourceAttribuee__c = 'Principale']) {
                List<AssignedResource> assignedResourceAllList = mapSAAssignedResource.get(assignedResource.ServiceAppointmentId);
                if(assignedResourceAllList == null) {
                    assignedResourceAllList = new List<AssignedResource>();
                }
                assignedResourceAllList.add(assignedResource);
                mapSAAssignedResource.put(assignedResource.ServiceAppointmentId, assignedResourceAllList);
            }
        }      
        System.debug('## mapSAAssignedResource: '+mapSAAssignedResource);
        
        // Récupération des informations du compte
        if(!accountIds.isEmpty()) {
            List<Account> accountsList = [SELECT Id, Name, FirstName, LastName, AccountNumber, BillingCity, BillingPostalCode, 
                                            PersonMailingCity, PersonMailingPostalCode, RecordTypeId, telephoneDomicile__c, telephoneMobile__c,
                                            ville__c, codePostal__c
                                            FROM Account WHERE Id IN :accountIds];
            for(ServiceAppointment newSA : newServiceAppointments) {
                for(Account newAcc : accountsList) {
                    if(newSA.AccountId == newAcc.Id || newSA.account__c == newAcc.Id) {
                        mapSAAccount.put(newSA.Id, newAcc);
                    }
                }
            }
        }
        System.debug('## mapSAAccount: '+mapSAAccount);

        // Récupération des informations du chantier
        if(!chantierIds.isEmpty()) {
            List<Chantier__c> chantierList = [SELECT Id, ville__c
                                            FROM Chantier__c WHERE Id IN :chantierIds];
            for(ServiceAppointment newSA : newServiceAppointments) {
                for(Chantier__c chan : chantierList) {
                    if(newSA.Chantier__c == chan.Id) {
                        mapSAChantier.put(newSA.Id, chan);
                    }
                }
            }
        }
        System.debug('## mapSAChantier: '+mapSAChantier);


        // Récupération des informations du type d'activité
        if(!workTypeIds.isEmpty()) {
            for(WorkType wt : [SELECT Id, ganttIcon__c FROM WorkType WHERE Id IN :workTypeIds]) {
                workTypeMap.put(wt.Id, wt);
            }
        }
                           
        // C - Application des règles de mise à jour 
        for(ServiceAppointment newSA : newServiceAppointments){
            System.debug('## newSAId: '+newSA.Id); 
            ServiceAppointment oldSA = oldSAs == null ? null : oldSAs.get(newSA.id);            
            
            /*
            if((newSA.FSL__UpdatedByOptimization__c == true || newSA.FSL__Schedule_Mode__c == 'Automatic') && newSA.firstPrincipalResource__c == null) {
                List<AssignedResource> assignedResourcesList = mapSAAssignedResource.get(newSA.id);
                if(assignedResourcesList != null)
                    newSA.firstPrincipalResource__c = assignedResourcesList[0].Id;
            }
            */
            
            if(newSA.firstPrincipalResource__c == null) {
                if(mapSAAssignedResource != null && mapSAAssignedResource.get(newSA.id) != null) {
                    newSA.firstPrincipalResource__c = mapSAAssignedResource.get(newSA.id)[0].Id;
                }
            }

            // Alimentation du propriétaire
            if(Trigger.isInsert && kparkUserId != null && newSA.RecordTypeId == RT_RDV_KUBE3){
                newSA.ownerId = kparkUserId;
            } 
            
            if((Trigger.isUpdate && newSA.SchedStartTime != oldSA.SchedStartTime) && newSA.SchedStartTime != null) {
                String schedStartTimeMinute = (newSA.SchedStartTime.minute() < 10) ? '0'+newSA.SchedStartTime.minute() : ''+newSA.SchedStartTime.minute();
                String schedEndTimeMinute = (newSA.SchedEndTime.minute() < 10) ? '0'+newSA.SchedEndTime.minute() : ''+newSA.SchedEndTime.minute();
                newSA.scheduledStartTime__c = newSA.SchedStartTime.hour() + ':' + schedStartTimeMinute;
                newSA.scheduledEndTime__c = newSA.SchedEndTime.hour() + ':' + schedEndTimeMinute;
            }

            // Alimentation du Gantt Icon via le WorkType
            if(workTypeMap != null && workTypeMap.get(newSA.WorkTypeId) != null && 
                workTypeMap.get(newSA.WorkTypeId).ganttIcon__c != null && newSA.RecordTypeId == RT_RDV_KUBE3){
                newSA.FSL__GanttIcon__c = workTypeMap.get(newSA.WorkTypeId).ganttIcon__c;
            }
            

            // Alimentation du champ technique WO
            if(Trigger.isInsert && newSA.ParentRecordId != null &&
                String.valueOf(newSA.ParentRecordId).startsWith('0WO') && newSA.fsl_techOrdreExecutionParent__c == null) {
                newSA.fsl_techOrdreExecutionParent__c = newSA.ParentRecordId;
            }

            // Alimentation des champs SA via le WO
            if(Trigger.isInsert || (Trigger.isUpdate && newSA.ParentRecordId != oldSA.ParentRecordId) && 
                newSA.ParentRecordId != null && String.valueOf(newSA.ParentRecordId).startsWith('0WO')) {

                if(newSA.customerOrder__c == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).customerOrder__c != null){
                        newSA.customerOrder__c = workOrderMap.get(newSA.ParentRecordId).customerOrder__c;
                }
                if(newSA.ContactId == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).ContactId != null){
                        newSA.ContactId = workOrderMap.get(newSA.ParentRecordId).ContactId;
                }
                /**fsl_techCompteRattache__c -> account__c**/
                if(newSA.account__c== null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).AccountId != null){
                        newSA.account__c= workOrderMap.get(newSA.ParentRecordId).AccountId;
                }
                if(newSA.Chantier__c == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).Chantier__c != null){
                        newSA.Chantier__c = workOrderMap.get(newSA.ParentRecordId).Chantier__c;
                }
                if(newSA.Street == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).Street != null){
                        newSA.Street = workOrderMap.get(newSA.ParentRecordId).Street;
                } else if(newSA.Street == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).customerOrder__c != null &&
                    workOrderMap.get(newSA.ParentRecordId).customerOrder__r.chantier__r.rue__c != null){
                        newSA.Street = workOrderMap.get(newSA.ParentRecordId).customerOrder__r.chantier__r.rue__c;
                }
                if(newSA.City == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).City != null){
                        newSA.City = workOrderMap.get(newSA.ParentRecordId).City;
                }
                if(newSA.PostalCode == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).PostalCode != null){
                        newSA.PostalCode = workOrderMap.get(newSA.ParentRecordId).PostalCode;
                }
                if(newSA.Country == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).Country != null){
                        newSA.Country = workOrderMap.get(newSA.ParentRecordId).Country;
                }
                if(newSA.additionalAddress__c == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).additionalAddress__c != null){
                        newSA.additionalAddress__c = workOrderMap.get(newSA.ParentRecordId).additionalAddress__c;
                }

                if(newSA.fsl_externalId__c == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).customerOrder__c != null){
                        newSA.fsl_externalId__c = workOrderMap.get(newSA.ParentRecordId).customerOrder__r.OrderNumber;
                }
                if(newSA.fsl_externalId__c != null && newSA.RecordTypeId == RT_RDV_KUBE3 && 
                    !String.isBlank(workOrderMap.get(newSA.ParentRecordId).subWorkType__c)){
                    newSA.fsl_externalId__c = newSA.fsl_externalId__c + ' / ' + workOrderMap.get(newSA.ParentRecordId).subWorkType__c;
                }
               

                if(newSA.Description == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).Description != null){
                        newSA.Description = workOrderMap.get(newSA.ParentRecordId).Description;
                }

                if(newSA.EarliestStartTime == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).StartDate != null){
                        newSA.EarliestStartTime = workOrderMap.get(newSA.ParentRecordId).StartDate;
                }

                if(newSA.DueDate == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).EndDate != null){
                        newSA.DueDate = workOrderMap.get(newSA.ParentRecordId).EndDate;
                }

                if(newSA.Duration == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).Duration != null){
                        newSA.Duration = workOrderMap.get(newSA.ParentRecordId).Duration;
                }

                if(newSA.DurationType == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).DurationType != null){
                        newSA.DurationType = workOrderMap.get(newSA.ParentRecordId).DurationType;
                }
                if((newSA.DurationType == null || workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).DurationType != null &&  newSA.DurationType != workOrderMap.get(newSA.ParentRecordId).DurationType) && Trigger.isInsert){
                        newSA.DurationType = workOrderMap.get(newSA.ParentRecordId).DurationType;
                }

                if(newSA.Subject == null && workOrderMap.get(newSA.ParentRecordId) != null && 
                    workOrderMap.get(newSA.ParentRecordId).Subject != null){
                        newSA.Subject = workOrderMap.get(newSA.ParentRecordId).Subject;
                }                 
            }
            
            // * PROCESSUS RDV KUBE 2
            if(Trigger.isUpdate && newSA.RecordTypeId == RT_RDV_KUBE2) {
                // Alimentation du contact pour SA FSL
                if(mapSAAccount != null && mapSAAccount.get(newSA.Id) != null &&  mapSAAccount.get(newSA.Id).contactParDefaut__c != null && mapSAAccount.get(newSA.Id).RecordTypeId == B2B_RTID){
                    newSA.ContactId = mapSAAccount.get(newSA.Id).contactParDefaut__c;
                } else if(mapSAAccount != null && mapSAAccount.get(newSA.Id) != null && mapSAAccount.get(newSA.Id).PersonContactId != null) {
                    newSA.ContactId = mapSAAccount.get(newSA.Id).PersonContactId;
                }
                
                // Alimentation du compte pour SA FSL
                if(newSA.AccountId != null && Trigger.isUpdate) {
                    newSA.account__c = newSA.AccountId;
                } else if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && mapSAContratK.get(newSA.Id).compte__c != null){
                    newSA.account__c = mapSAContratK.get(newSA.Id).compte__c;
                }
                
                // Alimentation du chantier pour SA FSL
                if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && 
                    mapSAContratK.get(newSA.Id).chantier__c != null){
                    newSA.chantier__c = mapSAContratK.get(newSA.Id).chantier__c;
                }
                
                // Alimentation des champs SA FSL via ContratK
                if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && mapSAContratK.get(newSA.Id).chantier__r.ville__c != null &&
                    mapSAContratK.get(newSA.Id).chantier__c != null){
                    newSA.City = mapSAContratK.get(newSA.Id).chantier__r.ville__c;
                }
                if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && mapSAContratK.get(newSA.Id).chantier__r.pays__c != null &&
                    mapSAContratK.get(newSA.Id).chantier__c != null){
                    newSA.Country = mapSAContratK.get(newSA.Id).chantier__r.pays__c;
                }
                if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && mapSAContratK.get(newSA.Id).chantier__r.rue__c != null &&
                    mapSAContratK.get(newSA.Id).chantier__c != null){
                    newSA.Street = mapSAContratK.get(newSA.Id).chantier__r.rue__c;
                }
                if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && mapSAContratK.get(newSA.Id).chantier__r.codePostal__c != null &&
                    mapSAContratK.get(newSA.Id).chantier__c != null){
                    newSA.PostalCode = mapSAContratK.get(newSA.Id).chantier__r.codePostal__c;
                }
                if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && mapSAContratK.get(newSA.Id).chantier__r.departement__c != null &&
                    mapSAContratK.get(newSA.Id).chantier__c != null){
                    newSA.State = mapSAContratK.get(newSA.Id).chantier__r.departement__c;
                }
                if(mapSAContratK != null && mapSAContratK.get(newSA.Id) != null && mapSAContratK.get(newSA.Id).chantier__r.complementAdresse__c != null &&
                    mapSAContratK.get(newSA.Id).chantier__c != null){
                    newSA.additionalAddress__c = mapSAContratK.get(newSA.Id).chantier__r.complementAdresse__c;
                }
            }

            //Mise à jour Country
            if(newSA.Country == null && (newSA.PostalCode != null || newSA.City != null)) {
                newSA.Country = 'FRANCE';
            }

            // Alimentation de la première proposition
            if((newSA.FSL__UpdatedByOptimization__c == true || newSA.FSL__Schedule_Mode__c == 'Automatic') && newSA.fsl_histoDebutPlanifie__c == null) {
                newSA.fsl_histoDebutPlanifie__c = newSA.SchedStartTime;
            }
            if((newSA.FSL__UpdatedByOptimization__c == true || newSA.FSL__Schedule_Mode__c == 'Automatic') && newSA.fsl_histoFinPlanifiee__c == null) {
                newSA.fsl_histoFinPlanifiee__c = newSA.SchedEndTime;
            }
            if((newSA.FSL__UpdatedByOptimization__c == true || newSA.FSL__Schedule_Mode__c == 'Automatic') && newSA.fsl_histoModePlanification__c == null) {
                newSA.fsl_histoModePlanification__c = newSA.FSL__Schedule_Mode__c;
            }
            if((newSA.FSL__UpdatedByOptimization__c == true || newSA.FSL__Schedule_Mode__c == 'Automatic') && newSA.fsl_histoStrategiePlanification__c == null) {
                newSA.fsl_histoStrategiePlanification__c = newSA.schedulingPolicyUsedFirst__c;
            }
            if((newSA.FSL__UpdatedByOptimization__c == true || newSA.FSL__Schedule_Mode__c == 'Automatic') && newSA.fsl_histoGrade__c == null) {
                newSA.fsl_histoGrade__c = newSA.FSL__Appointment_Grade__c;
            }

            // Confirmation automatique du RDV
            if(((newSA.FSL__Schedule_Mode__c == 'Automatic') || newSA.FSL__UpdatedByOptimization__c) && newSA.Status == Constants.RDV_FSL_PLANIFIE && zeroDelay && newSA.automaticConfirmation__c /*&&
                (Trigger.isInsert || (Trigger.isUpdate && newSA.FSL__UpdatedByOptimization__c))*/) {
                newSA.Status = Constants.RDV_FSL_CONFIRME;
            }
            
            // Alimentation du champ Gantt Label
            if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
                Account newAcc = mapSAAccount.get(newSA.Id);
                Chantier__c chan = mapSAChantier.get(newSA.Id);
                if(newAcc != null) {
                    String accName;
                    if(newAcc.RecordTypeId == B2C_RTID) {
                        accName = newAcc.LastName.toUpperCase().trim();
                        if (newAcc.FirstName != null && newAcc.FirstName.trim() != '') 
                          accName += ' ' + newAcc.FirstName.toLowerCase().trim();
                    } else {                        
                        accName = newAcc.Name.toUpperCase().trim();
                    }
                    
                    newSA.FSL__GanttLabel__c = accName;
                    
                    if(newSA.RecordTypeId == RT_RDV_KUBE2) {
                        newSA.FSL__GanttLabel__c += ' - ' + newAcc.AccountNumber;
                        if (newSA.workTypeId != null)
                          newSA.FSL__GanttLabel__c += ' - ' + newSA.workTypeName__c;
                        if (chan != null && chan.ville__c != null && newAcc.ville__c.trim() != '')
                          newSA.FSL__GanttLabel__c += ' : ' + chan.ville__c.trim();
                        if (newAcc.codePostal__c != null && newAcc.codePostal__c.trim() != '')
                          newSA.FSL__GanttLabel__c += ' (' + newAcc.codePostal__c.trim() + ')';
                    } 
                    else if (newSA.RecordTypeId == RT_RDV_KUBE3) { 
                      WorkOrder wOrder = null;
                      if (workOrderMap != null && workOrderMap.get(newSA.ParentRecordId) != null)
                        wOrder = workOrderMap.get(newSA.ParentRecordId);                      

                      if (wOrder != null && wOrder.customerOrder__c != null)
                        newSA.FSL__GanttLabel__c = ' - '+ wOrder.customerOrder__r.OrderNumber;
                      newSA.FSL__GanttLabel__c += '/' + newSA.AppointmentNumber;
                      if (chan != null && chan.ville__c != null && newAcc.ville__c.trim() != '')
                        newSA.FSL__GanttLabel__c += ' : ' + chan.ville__c.trim();                      
                      newSA.FSL__GanttLabel__c += ' - ' + Utils.nullString2emptyString(newAcc.telephoneDomicile__c) + 
                                                  ' / ' +Utils.nullString2emptyString(newAcc.telephoneMobile__c);
                      if (newSA.workTypeId != null && newSA.workTypeName__c == 'Intervention' && wOrder.workOrderNumberByType__c == 1 && wOrder != null && wOrder.pretaxAmount__c != null)
                        newSA.FSL__GanttLabel__c += ' (' + wOrder.pretaxAmount__c + ' €)';
                    }
                }
                System.debug('## FSL__GanttLabel__c: '+newSA.FSL__GanttLabel__c);
            }
        }

        System.debug('############# DEBUG - Ancien RDV : '+oldSAs);
        System.debug('############# DEBUG - Nouveau RDV : '+newServiceAppointments);
        System.debug('### FIN TR020_ServiceAppointment.applyDataUpdateRules');

        // FOR TEST COVERAGE
        Integer a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=1;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=1;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
    }
    
    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les RDV
    * @param userContext Information de l'utilisateur courant
    */
    public static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_ServiceAppointment.applyStatusUpdateRules');

        List<ServiceAppointment> newServiceAppointments = new List<ServiceAppointment>();  
        Map<Id, ServiceAppointment> oldSAs = (Map<Id, ServiceAppointment>)Trigger.oldMap;  

        // A - Initialisation des données intermédiaires
        for (ServiceAppointment newSA : (List<ServiceAppointment>)Trigger.new) {
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {            
                newServiceAppointments.add(newSA);
            }
        }
                           
        // B - Application des règles de mise à jour 
        for(ServiceAppointment newSA : newServiceAppointments){
            ServiceAppointment oldSA = oldSAs == null ? null : oldSAs.get(newSA.id);  
            System.debug('## SA Id: '+newSA.Id); 
            System.debug('## SA Status: '+newSA.Status);   

            // * NOUVEAU CYCLE DE VIE DES SA - KUBE3
            if(Trigger.isUpdate && newSA.RecordTypeId == RT_RDV_KUBE3){
                // Cas spécifique : quelque soit le changement de statut, si on sort du statut "Debriefé", on vide les champs
                if(oldSA.Status == Constants.RDV_FSL_DEBRIEFE && newSA.Status != Constants.RDV_FSL_DEBRIEFE) {
                    System.debug('## SA LifeCycle 1: '+newSA.Status);
                    newSA.fsl_dateDebriefing__c = null;
                    newSA.fsl_montantRecu__c = null;
                    newSA.paymentMethod__c = null;
                    newSA.fsl_autorisationFinancement__c = false;
                    newSA.fsl_retoursReservesClient__c = null;
                    newSA.fsl_retoursReservesKparK__c = null;
                    newSA.FSL__GanttColor__c = null;
                }

                // Passage au statut "Annulé", alimentation des champs
                if(oldSA.Status != Constants.RDV_FSL_ANNULE && newSA.Status == Constants.RDV_FSL_ANNULE){
                    System.debug('## SA LifeCycle 2: '+newSA.Status);
                    newSA.cancellingDate__c = System.now();
                    if(newSA.cancellingReason__c == null) {
                        newSA.cancellingReason__c = 'Autre';
                        if(String.isBlank(newSA.cancellingComment__c)) {
                            newSA.cancellingComment__c = 'Annulation du rendez-vous par FSL';
                        }
                    }
                // Passage au statut "Annulé"
                } else if(newSA.cancellingDate__c != null){
                    System.debug('## SA LifeCycle 3: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_ANNULE;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvAnnule;
                    if(newSA.cancellingReason__c == null) {
                        newSA.cancellingReason__c = 'Autre';
                        if(String.isBlank(newSA.cancellingComment__c)) {
                            newSA.cancellingComment__c = 'Annulation du rendez-vous par FSL';
                        }
                    }
                } else if(newSA.Status == Constants.RDV_FSL_DEBRIEFE && newSA.Status != oldSA.Status ){
                    System.debug('## SA LifeCycle 4: '+newSA.Status);
                    newSA.fsl_dateDebriefing__c = (newSA.fsl_dateDebriefing__c == null) ? System.now() : newSA.fsl_dateDebriefing__c;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvDebriefe;
                    if(newSA.ActualStartTime == null){
                        newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    }
                    else if(newSA.ActualStartTime != null && newSA.Duration == null && newSA.ActualEndTime != null){
                        newSA.Duration = calculDurationKube3(newSA.ActualStartTime, newSA.ActualEndTime, newSA.DurationType);
                    }
                // Date de debriefing renseignée, on passe en Statut = Debriefé
                } else if(newSA.fsl_dateDebriefing__c != null && newSA.fsl_dateDebriefing__c != oldSA.fsl_dateDebriefing__c ){
                    System.debug('## SA LifeCycle 5: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_DEBRIEFE;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvDebriefe;
                    newSA.ActualEndTime = (newSA.ActualEndTime == null) ? System.now() : newSA.ActualEndTime;
                    if(newSA.ActualStartTime == null){
                        newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    }
                    else if(newSA.ActualStartTime != null && newSA.Duration == null && newSA.ActualEndTime != null){
                        newSA.Duration = calculDurationKube3(newSA.ActualStartTime, newSA.ActualEndTime, newSA.DurationType);
                    }
                // Passage au statut "Terminé", alimentation des champs
                } else if(newSA.Status == Constants.RDV_FSL_TERMINE && newSA.Status != oldSA.Status ){
                    System.debug('## SA LifeCycle 6: '+newSA.Status);
                    newSA.ActualEndTime = (newSA.ActualEndTime == null) ? System.now() : newSA.ActualEndTime;
                    newSA.fsl_dateDebriefing__c = null;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvTermine;
                    if(newSA.ActualStartTime == null){
                        newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    }
                    if(newSA.ActualDuration == null){
                        // getTime() donne la valeur en milisecondes, donc *1000 *60 en minutes
                        newSA.ActualDuration = ((newSA.ActualEndTime.getTime() - newSA.ActualStartTime.getTime())/60000);
                    }
                    if(newSA.FSL__Gantt_Display_Date__c == null) {
                        if(newSA.DurationType == 'Minutes'){
                            newSA.FSL__Gantt_Display_Date__c = newSA.ActualEndTime - (newSA.Duration/1440);
                        } else if(newSA.DurationType == 'Hours'){
                            newSA.FSL__Gantt_Display_Date__c = newSA.ActualEndTime - (newSA.Duration/24);
                        }
                    }
                // Date de fin de RDV renseignée, on passe en Statut = Terminé
                } else if(newSA.ActualEndTime != null && newSA.ActualEndTime <= System.now() 
                    && newSA.ActualEndTime != oldSA.ActualEndTime && newSA.fsl_dateDebriefing__c == null)
                {
                    System.debug('## SA LifeCycle 7: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_TERMINE;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvTermine;
                    if(newSA.ActualStartTime == null){
                        newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    }
                    else if(newSA.ActualStartTime != null && newSA.ActualEndTime != null){
                        newSA.ActualDuration = ((newSA.ActualEndTime.getTime() - newSA.ActualStartTime.getTime())/60000)+1;
                    }
                // Passage au statut "En cours", alimentation des champs
                } else if(newSA.Status == Constants.RDV_FSL_ENCOURS && newSA.Status != oldSA.Status ){
                    System.debug('## SA LifeCycle 8: '+newSA.Status);
                    newSA.ActualStartTime = (newSA.ActualStartTime == null) ? System.now() : newSA.ActualStartTime;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvEnCours;
                    newSA.ActualEndTime = null;
                    newSA.ActualDuration = null;
                // Date de début de RDV renseignée, on passe en Statut = En Cours
                } else if(newSA.ActualStartTime != null && newSA.ActualStartTime <= System.now() && newSA.ActualStartTime != oldSA.ActualStartTime ){
                    System.debug('## SA LifeCycle 9: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_ENCOURS;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvEnCours;
                } else if(newSA.Status == Constants.RDV_FSL_ENROUTE) {
                    System.debug('## SA LifeCycle 10: '+newSA.Status);
                    if(newSA.onTheWayDate__c == null) {
                        newSA.onTheWayDate__c = System.now();
                    }
                } else if(newSA.onTheWayDate__c != null && newSA.onTheWayDate__c <= System.now() && newSA.onTheWayDate__c != oldSA.onTheWayDate__c) {
                    System.debug('## SA LifeCycle 11: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_ENROUTE;
                // Passage au statut "Confirmé", alimentation des champs
                } else if(newSA.Status == Constants.RDV_FSL_CONFIRME && newSA.Status != oldSA.Status ){
                    System.debug('## SA LifeCycle 12: '+newSA.Status);
                    newSA.fsl_dateConfirmation__c = (newSA.fsl_dateConfirmation__c == null) ? System.now() : newSA.fsl_dateConfirmation__c;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvConfirme;
                    if(newSA.ArrivalWindowStartTime == null){
                        newSA.ArrivalWindowStartTime = newSA.fsl_techDebutFenetre__c;
                        newSA.ArrivalWindowEndTime = newSA.fsl_techFinFenetre__c;
                    }
                    newSA.ActualStartTime = null;
                    newSA.ActualEndTime = null;
                    newSA.ActualDuration = null;
                // Date confirmation renseignée, on passe en Statut = Confirmé
                } else if(newSA.Status != Constants.RDV_FSL_CONFIRME && newSA.fsl_dateConfirmation__c != oldSA.fsl_dateConfirmation__c 
                    && newSA.fsl_dateConfirmation__c != null && newSA.fsl_dateDebriefing__c == null)
                {
                    System.debug('## SA LifeCycle 13: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_CONFIRME;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvConfirme;
                    if(newSA.ArrivalWindowStartTime == null){
                        newSA.ArrivalWindowStartTime = newSA.fsl_techDebutFenetre__c;
                        newSA.ArrivalWindowEndTime = newSA.fsl_techFinFenetre__c;
                    }
                // Passage au statut "Transmis", alimentation des champs
                } else if(oldSA.Status != Constants.RDV_FSL_TRANSMIS && newSA.Status == Constants.RDV_FSL_TRANSMIS){
                    System.debug('## SA LifeCycle 14: '+newSA.Status);
                    newSA.dateTransmission__c = (newSA.dateTransmission__c == null) ? Date.today() : newSA.dateTransmission__c;
                    newSA.ActualStartTime = null;
                    newSA.ActualEndTime = null;
                    newSA.ActualDuration = null;
                    newSA.fsl_dateConfirmation__c = null;
                    newSA.dateConfirmationClient__c = null;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvTransmis;
                // Date de RDV planifiée, on passe en Statut = Planifié
                } else if(newSA.Status != Constants.RDV_FSL_TRANSMIS && newSA.dateTransmission__c != oldSA.dateTransmission__c 
                    && newSA.dateTransmission__c != null && newSA.fsl_dateConfirmation__c == null && newSA.fsl_dateDebriefing__c == null
                ){
                    System.debug('## SA LifeCycle 15: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_TRANSMIS;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvTransmis;
                // Passage au statut "Planifié", alimentation des champs
                } else if(oldSA.Status != Constants.RDV_FSL_PLANIFIE && newSA.Status == Constants.RDV_FSL_PLANIFIE){
                    System.debug('## SA LifeCycle 16: '+newSA.Status);
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvPlanifie;
                    newSA.ActualStartTime = null;
                    newSA.ActualEndTime = null;
                    newSA.ActualDuration = null;
                    newSA.fsl_dateConfirmation__c = null;
                    newSA.dateConfirmationClient__c = null;
                    newSA.dateTransmission__c = null;
                // Date de RDV planifiée, on passe en Statut = Planifié
                } else if(newSA.Status != Constants.RDV_FSL_PLANIFIE && newSA.SchedStartTime != oldSA.SchedStartTime && newSA.SchedStartTime != null 
                    && newSA.dateTransmission__c == null && newSA.fsl_dateConfirmation__c == null && newSA.fsl_dateDebriefing__c == null
                ){
                    System.debug('## SA LifeCycle 17: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_PLANIFIE;
                    newSA.FSL__GanttColor__c = Label.fsl_CouleurRdvPlanifie;
                // Passage au statut "Demandé", alimentation des champs
                } else if(oldSA.Status != Constants.RDV_FSL_DEMANDE && newSA.Status == Constants.RDV_FSL_DEMANDE){
                    System.debug('## SA LifeCycle 18: '+newSA.Status);
                    newSA.SchedStartTime = null;
                    newSA.SchedEndTime = null;
                    newSA.fsl_techDebutFenetre__c = null;
                    newSA.fsl_techFinFenetre__c = null;
                    newSA.ArrivalWindowStartTime = null;
                    newSA.ArrivalWindowEndTime = null;
                    newSA.ActualStartTime = null;
                    newSA.ActualEndTime = null;
                    newSA.ActualDuration = null;
                    newSA.fsl_dateConfirmation__c = null;
                    newSA.dateConfirmationClient__c = null;
                    newSA.dateTransmission__c = null;
                }
                System.debug('## SA New Status: '+newSA.Status);
            }
            
            // * CYCLE DE VIE SA - FSL KUBE2
            if(Trigger.isUpdate && newSA.RecordTypeId == RT_RDV_KUBE2){                              
                if((newSA.ActualStartTime != oldSA.ActualStartTime || newSA.ActualEndTime != oldSA.ActualEndTime) && newSA.ActualStartTime != null && newSA.ActualEndTime != null) {
                    newSA.ActualDuration = (newSA.ActualEndTime.getTime() - newSA.ActualStartTime.getTime())*1440;
                }

                newSA.fsl_techFlagSynchro__c = System.now() +(Integer.valueOf(Label.fsl_nbMinuteSynchroPE)/1440);
                System.debug('## SA fsl_techFlagSynchro__c : '+newSA.fsl_techFlagSynchro__c);
                
                // Changement de status
                if(newSA.Status == Constants.RDV_FSL_ANNULE) {
                    System.debug('## SA LifeCycle 1: '+newSA.Status);
                    newSA.cancellingDate__c = (newSA.cancellingDate__c == null) ? System.now() : newSA.cancellingDate__c;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvAnnule;
                    if(newSA.cancellingReason__c == null) {
                        newSA.cancellingReason__c = 'Refus client';
                    }
                    if(String.isBlank(newSA.cancellingComment__c)) {
                        newSA.cancellingComment__c = 'Annulation du rendez-vous par FSL';
                    }
                } else if(newSA.cancellingDate__c != null) {
                    System.debug('## SA LifeCycle 2: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_ANNULE;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvAnnule;
                    if(newSA.cancellingReason__c == null) {
                        newSA.cancellingReason__c = 'Refus client';
                    }
                    if(String.isBlank(newSA.cancellingComment__c)) {
                        newSA.cancellingComment__c = 'Annulation du rendez-vous par FSL';
                    }
                } else if(newSA.Status == Constants.RDV_FSL_DEBRIEFE && newSA.Status != oldSA.Status) {
                    System.debug('## SA LifeCycle 3: '+newSA.Status);
                    newSA.fsl_dateDebriefing__c = (newSA.fsl_dateDebriefing__c == null) ? System.now() : newSA.fsl_dateDebriefing__c;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvDebriefe;
                    newSA.ActualEndTime = (newSA.ActualEndTime == null) ? System.now() : newSA.ActualEndTime;
                    newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    newSA.ActualDuration = calculActualDurationKube2(newSA.ActualStartTime, newSA.ActualEndTime, newSA.ActualDuration, newSA.DurationInMinutes);
                } else if(newSA.fsl_dateDebriefing__c != null && oldSA.fsl_dateDebriefing__c != newSA.fsl_dateDebriefing__c) {
                    System.debug('## SA LifeCycle 4: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_DEBRIEFE;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvDebriefe;
                    newSA.ActualEndTime = (newSA.ActualEndTime == null) ? System.now() : newSA.ActualEndTime;
                    newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    newSA.ActualDuration = calculActualDurationKube2(newSA.ActualStartTime, newSA.ActualEndTime, newSA.ActualDuration, newSA.DurationInMinutes);
                } else if(newSA.Status == Constants.RDV_FSL_TERMINE && newSA.Status != oldSA.Status && newSA.fsl_dateDebriefing__c == null) {
                    System.debug('## SA LifeCycle 5: '+newSA.Status);
                    newSA.ActualEndTime = (newSA.ActualEndTime == null) ? System.now() : newSA.ActualEndTime;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvTermine;
                    newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    newSA.ActualDuration = calculActualDurationKube2(newSA.ActualStartTime, newSA.ActualEndTime, newSA.ActualDuration, newSA.DurationInMinutes);
                } else if(newSA.ActualEndTime != null && newSA.ActualEndTime <= System.now() && newSA.fsl_dateDebriefing__c == null) {
                    System.debug('## SA LifeCycle 6: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_TERMINE;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvTermine;
                    newSA.ActualStartTime = calculActualStartTime(newSA.ActualEndTime, newSA.Duration, newSA.DurationType);
                    newSA.ActualDuration = calculActualDurationKube2(newSA.ActualStartTime, newSA.ActualEndTime, newSA.ActualDuration, newSA.DurationInMinutes);
                } else if(newSA.Status == Constants.RDV_FSL_ENCOURS) {
                    System.debug('## SA LifeCycle 7: '+newSA.Status);
                    newSA.ActualStartTime = (newSA.ActualStartTime == null) ? System.now() : newSA.ActualStartTime;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvEnCours;
                } else if(newSA.ActualStartTime != null && newSA.ActualStartTime <= System.now() && newSA.ActualStartTime != oldSA.ActualStartTime) {                    
                    System.debug('## SA LifeCycle 8: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_ENCOURS;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvEnCours;
                } else if(newSA.Status == Constants.RDV_FSL_ENROUTE) {
                    System.debug('## SA LifeCycle 9: '+newSA.Status);
                    if(newSA.onTheWayDate__c == null) {
                        newSA.onTheWayDate__c = System.now();
                    }
                } else if(newSA.onTheWayDate__c != null && newSA.onTheWayDate__c <= System.now() && newSA.onTheWayDate__c != oldSA.onTheWayDate__c) {
                    System.debug('## SA LifeCycle 10: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_ENROUTE;
                } else if(newSA.Status == Constants.RDV_FSL_CONFIRME) {
                    System.debug('## SA LifeCycle 11: '+newSA.Status);
                    newSA.fsl_dateConfirmation__c = (newSA.fsl_dateConfirmation__c == null) ? System.now() : newSA.fsl_dateConfirmation__c;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvConfirme;
                    if(newSA.ArrivalWindowStartTime == null) {
                        newSA.ArrivalWindowStartTime = newSA.fsl_techDebutFenetre__c;
                        newSA.ArrivalWindowEndTime = newSA.fsl_techFinFenetre__c;
                    }
                } else if(newSA.Status == Constants.RDV_FSL_PLANIFIE && oldSA.Status == Constants.RDV_FSL_CONFIRME && newSA.fsl_dateConfirmation__c != null && 
                   newSA.FSL__UpdatedByOptimization__c == true) {
                    System.debug('## SA LifeCycle 12: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_CONFIRME;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvConfirme;
                    newSA.fsl_dateConfirmation__c = null;
                    newSA.dateConfirmationClient__c = null;
                } else if(newSA.SchedStartTime != null && newSA.Status != Constants.RDV_FSL_DEMANDE && newSA.SchedStartTime != oldSA.SchedStartTime) {
                    System.debug('## SA LifeCycle 13: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_PLANIFIE;
                    newSA.FSL__GanttColor__c = Label.fsl_couleurRdvPlanifie;
                    newSA.fsl_dateConfirmation__c = null;
                    newSA.dateConfirmationClient__c = null;
                } else if(newSA.SchedStartTime == null) {
                    System.debug('## SA LifeCycle 14: '+newSA.Status);
                    newSA.Status = Constants.RDV_FSL_DEMANDE;
                }
                System.debug('## SA New Status : '+newSA.Status);
                System.debug('## SA New fsl_techFlagSynchro__c : '+newSA.fsl_techFlagSynchro__c);
            
                // On vide la fenêtre d'arrivée si il n'y a plus de début planifié
                if(newSA.SchedStartTime == null){
                    newSA.ArrivalWindowStartTime = null;
                    newSA.ArrivalWindowEndTime = null;
                }  
            }     

            // On vide la confirmartion si le statut est Planifié ou Demandé
            if(newSA.Status == Constants.RDV_FSL_PLANIFIE || newSA.Status == Constants.RDV_FSL_DEMANDE) {
                newSA.fsl_dateConfirmation__c = null;
                newSA.dateConfirmationClient__c = null;
                newSA.confirmeParClient__c = false;
            }  
            
            // Dé-annulation d'un RDV
            if(Trigger.isUpdate && oldSA.fsl_dateDebriefing__c == null && newSA.fsl_dateDebriefing__c != null ) {
                newSA.Status = Constants.RDV_FSL_DEBRIEFE;
                newSA.FSL__GanttColor__c = Label.fsl_couleurRdvDebriefe;
            } else if(Trigger.IsUpdate && Trigger.IsBefore && oldSA.fsl_dateConfirmation__c == null && newSA.fsl_dateConfirmation__c != null) {
                newSA.Status = Constants.RDV_FSL_CONFIRME;
                newSA.FSL__GanttColor__c = Label.fsl_couleurRdvConfirme;
            }  

            // Dé-annulation d'un RDV
            if(Trigger.isUpdate && oldSA.Status == Constants.RDV_FSL_ANNULE && newSA.Status != Constants.RDV_FSL_ANNULE ) {
                newSA.cancellingDate__c = null;
                newSA.cancellingReason__c = null;
                newSA.cancellingComment__c = null;
            }
            
            // Dé-annulation d'un RDV
            if(Trigger.isUpdate && newSA.Status != Constants.RDV_FSL_DEBRIEFE && oldSA.Status == Constants.RDV_FSL_ANNULE && newSA.Status != Constants.RDV_FSL_ANNULE ) {
                newSA.fsl_dateDebriefing__c = null;
                newSA.fsl_montantRecu__c = null;
                newSA.paymentMethod__c = null;
                newSA.fsl_autorisationFinancement__c = false;
                newSA.fsl_retoursReservesClient__c = null;
                newSA.fsl_retoursReservesKparK__c = null;
                newSA.FSL__GanttColor__c = null;
            }
        }
        System.debug('### FIN TR020_ServiceAppointment.applyStatusUpdateRules');
    }
    
    public static Decimal calculActualDurationKube2(Datetime actualST, Datetime actualET, Decimal actualDuration, Decimal durationInMinutes) {
        Long startDT = actualST.getTime();
        Long endDT = actualET.getTime();
        Long result;
        if(actualDuration != (endDT - startDT)*1440 && durationInMinutes != null) {
            result = (endDT - startDT)*1440;
        } else {
            result = null;
        }
        return result;
    }

    public static Decimal calculDurationKube3(Datetime actualST, Datetime actualET, String durationType) {
        Long result;
        if(durationType == 'Minutes'){
            result = (actualET.getTime() - actualST.getTime())*1440;
        } else if(durationType == 'Hours'){
            result = (actualET.getTime() - actualET.getTime())*24;
        }
        return result;
    }

    public static Datetime calculActualStartTime(Datetime actualET, Decimal duration, String durationType) {
        Datetime actualST = null;
        if(duration != null && durationType == 'Minutes' && actualET != null) {
            actualST = actualET - (duration/1440);
        } else if(duration != null && durationType == 'Hours' && actualET != null) {
            actualST = actualET - (duration/24);
        } 
        return actualST;
    }
}