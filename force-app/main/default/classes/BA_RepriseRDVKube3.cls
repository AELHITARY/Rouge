//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseRDVKube3
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/05/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseRDVKube3 implements Database.Batchable<sObject>, Database.Stateful {
    private static final String WO_KUBE3_RTID = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final String WO_KUBE2_RTID = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    private static final String SA_KUBE3_RTID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    private static final String SA_KUBE2_RTID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    private static final String ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final String CASE_NCP_RTID = DAL.getRecordTypeIdByDevName('Case', 'InternalProductNonCompliance');
    global BatchHistory__c batchHistoryStored {get;set;}
    global String serviceEntityId {get;set;}
    global Boolean migrateToK3 {get;set;}
    global List<String> orderLegRef {get;set;}

    /***** Constructor *****/
    global BA_RepriseRDVKube3(String serviceEntityId, Boolean migrateToK3, List<String> orderLegRef) {
        this.serviceEntityId = serviceEntityId; 
        this.migrateToK3 = migrateToK3; 
        this.orderLegRef = orderLegRef; 

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('Kube3 - Reprise RDV');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les données
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('### DEBUT BA_RepriseRDVKube3 : start');
        try {
            Database.QueryLocator results;

            // Si le paramètre d'entrée "serviceEntityId" est vide, on récupère tous les dépots migrés Kube3. 
            // Sinon on récupère que le dépot en entrée
            Set<String> serviceTerritoryList = new Set<String>();
            List<Account> entitiesList = new List<Account>();
            if(String.isBlank(this.serviceEntityId)) {
                entitiesList = [SELECT Id, serviceTerritory__c FROM Account WHERE RecordTypeId = :ACC_ENTITY_RTID
                                    AND entityType__r.KparKReference__c = 'DEP'
                                    AND migratedToK3__c = true
                                    AND serviceTerritory__c != null];
            } else {
                entitiesList = [SELECT Id, serviceTerritory__c FROM Account 
                                WHERE Id = :this.serviceEntityId
                                AND serviceTerritory__c != null];
            }
            for(Account acc : entitiesList) {
                serviceTerritoryList.add(acc.serviceTerritory__c);
            }
            System.debug('## serviceTerritoryList: '+serviceTerritoryList);

            // Construct query récupération RDV
            String query = 'SELECT Id, ParentRecordId, fsl_techOrdreExecutionParent__c, '+
                            ' fsl_externalId__c, HST_CustomerOrderNumber__c,' + 
                            ' Status, CreatedDate, customerOrder__c, chantier__c,' +
                            ' SchedStartTime, SchedEndTime, fsl_dateConfirmation__c, dateConfirmationClient__c, ' +
                            ' dateTransmission__c, WorkType.Name, WorkTypeId,' +
                            ' ActualStartTime, ActualEndTime, fsl_dateDebriefing__c '+
                            '   FROM ServiceAppointment '+
                            '   WHERE ServiceTerritoryId IN :serviceTerritoryList '+
                            '   AND customerOrder__c = null '+
                            '   AND (RecordTypeId = null OR RecordTypeId = :SA_KUBE2_RTID)';

            if(orderLegRef != null && !orderLegRef.isEmpty()) {
                query += ' AND HST_CustomerOrderNumber__c IN :orderLegRef';
            } else {
                query += ' AND HST_CustomerOrderNumber__c != null';
            }

            if(migrateToK3) {
                query += '  AND ((SchedStartTime >= LAST_N_DAYS:31 AND Status != \'Annulé\') OR '+
                            '(CreatedDate >= LAST_N_DAYS:31 AND Status = \'Demandé\'))';
            } else {
                query += '  AND Status IN (\'Terminé\', \'Débriefé\', \'Confirmé\', \'En cours\', \'En route\')';
            }
            System.debug('## query: '+query);
            results = Database.getQueryLocator(query);

            // Fin de l'init
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored); 
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) {
                batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            }
            System.debug('### FIN BA_RepriseRDVKube3 : start');     
            return results;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise RDV Kube2 -> Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<ServiceAppointment> scope){
        System.debug('### DEBUT BA_RepriseRDVKube3 : execute');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        System.debug('## scope (' + scope.size() +')');
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
        Set<WorkOrder> woToUpdate = new Set<WorkOrder>();
        List<WorkOrderLineItem> woliToCreate = new List<WorkOrderLineItem>();
        Set<String> prodIdLIst = new Set<String>();
        Map<String, Order> ordersMap = new Map<String, Order>();
        Map<String, List<Asset>> assetOrdersMap = new Map<String, List<Asset>>();
        Map<String, List<Case>> caseOrdersMap = new Map<String, List<Case>>();
        Set<String> orderLegacyList = new Set<String>();
        Map<String, WorkType> wkTypeMap = new Map<String, WorkType>();
        Map<String, String> mapProductPriceBook = new Map<String, String>();
        Map<String, String> mapServiceReportLayout = new Map<String, String>();

        try {
            Integer successCount = 0;

            if(!scope.isEmpty()) {      
                // Date 1 mois
                Date datePrevMonth = Date.today().addMonths(-1);
                // Get Order List
                for(ServiceAppointment sa : scope) {
                    orderLegacyList.add(sa.HST_CustomerOrderNumber__c);
                }
                System.debug('## orderLegacyList: '+orderLegacyList);
                for(Order ord : [SELECT Id, legacyReference__c, Status, chantier__c, legacyStatus__c 
                                    FROM Order WHERE legacyReference__c IN : orderLegacyList]) {
                    ordersMap.put(ord.legacyReference__c, ord);
                }       
                System.debug('## ordersMap: '+ordersMap);

                if(migrateToK3) {
                    // Get Asset List
                    List<Asset> assetsList = new List<Asset>();
                    for(Asset ast : [SELECT id, Name, customerOrder__c, Product2Id FROM Asset
                                        WHERE ParentId = null AND customerOrder__c IN :ordersMap.values()]) {
                        if(assetOrdersMap.get(ast.customerOrder__c) == null) {
                            assetsList = new List<Asset>();
                        } else {
                            assetsList = assetOrdersMap.get(ast.customerOrder__c);
                        }
                        assetsList.add(ast);
                        prodIdLIst.add(ast.Product2Id);
                        assetOrdersMap.put(ast.customerOrder__c, assetsList);
                    }
                    System.debug('## assetOrdersMap: '+assetOrdersMap);
                    
                    // Get NCP List
                    List<Case> casesList = new List<Case>();
                    for(Case cse : [SELECT Id, Subject, dateTimeReOpen__c, customerOrder__c, AssetId, ProductId
                                        FROM Case
                                        WHERE RecordTypeId = :CASE_NCP_RTID
                                        AND customerOrder__c IN :ordersMap.values()
                                        AND IsCLosed = false]) {
                        if(caseOrdersMap.get(cse.customerOrder__c) == null) {
                            casesList = new List<Case>();
                        } else {
                            casesList = caseOrdersMap.get(cse.customerOrder__c);
                        }
                        casesList.add(cse);
                        prodIdLIst.add(cse.ProductId);
                        caseOrdersMap.put(cse.customerOrder__c, casesList);
                    }
                    System.debug('## caseOrdersMap: '+caseOrdersMap);

                    // Get all Worktypes
                    for(WorkType wk : [SELECT Id, Name FROM WorkType]) {
                        wkTypeMap.put(wk.Name, wk);
                    }
                    
                    // Get PricebookEntry
                    for(PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry 
                                                WHERE Product2Id IN :prodIdLIst AND IsActive = true]) {
                        mapProductPriceBook.put(pbe.Product2Id, pbe.Id);
                    }
                    
                    // Get ServiceReportLayout 
                    for(ServiceReportLayout  sr : [SELECT Id, DeveloperName FROM ServiceReportLayout]) {
                        mapServiceReportLayout.put(sr.DeveloperName, sr.Id);
                    }
                }

                // Process RDV
                for(ServiceAppointment sa : scope) {
                    System.debug('####### SA: '+sa.Id+' / '+sa.Status+' / '+sa.WorkType.Name);
                    Order ord = ordersMap.get(sa.HST_CustomerOrderNumber__c); // ORDER
                    if(ord != null) {
                        WorkOrder wo = new WorkOrder(Id = sa.ParentRecordId); // WORKORDER
                        System.debug('## Order: '+ord);
                        //* Update order
                        sa.customerOrder__c = ord.Id;
                        wo.customerOrder__c = ord.Id;
                        //* Correct other datas                
                        wo.Pricebook2Id = Label.system_id_pricebookentry_standard;         
                        if(sa.ActualStartTime == null && (sa.Status == Constants.RDV_FSL_DEBRIEFE || sa.Status == Constants.RDV_FSL_TERMINE)) {
                            sa.ActualStartTime = sa.SchedStartTime;
                        }
                        if(sa.fsl_dateDebriefing__c != null && sa.Status == Constants.RDV_FSL_TERMINE) {
                            sa.Status = Constants.RDV_FSL_DEBRIEFE;
                        }
                        sa.chantier__c = ord.chantier__c;
                        wo.chantier__c = ord.chantier__c;

                        //* MIGRATION KUBE2 -> KUBE3
                        //* ----------------------
                        if(migrateToK3) {
                            System.debug('## Convert to K3: '+sa);
                            // Modification of SA and WO
                            sa.RecordTypeId = SA_KUBE3_RTID;       
                            wo.RecordTypeId = WO_KUBE3_RTID;  
                            /*sa.dateTransmission__c = (sa.fsl_dateConfirmation__c != null) ? sa.fsl_dateConfirmation__c.date() : null;
                            sa.fsl_dateConfirmation__c = sa.dateConfirmationClient__c;
                            sa.dateConfirmationClient__c = null;*/
                            if(sa.WorkType.Name.containsIgnoreCase('METRAGE')) {
                                sa.dateTransmission__c = (sa.fsl_dateConfirmation__c != null) ? sa.fsl_dateConfirmation__c.date() : null;
                                sa.fsl_dateConfirmation__c = sa.dateConfirmationClient__c;
                                sa.dateConfirmationClient__c = null;
                            } else { // Si type d'activité = Intervention ou Diagnostic
                                sa.dateTransmission__c = (sa.fsl_dateConfirmation__c != null) ? sa.fsl_dateConfirmation__c.date() : null;
                                sa.dateConfirmationClient__c = null; // on conserve la date de confirmation 
                            }
                            // Convert WorkType and ServiceReportTemplate
                            WorkType wk;
                            String serviceRepTemplateId = null;
                            if(sa.WorkType.Name.containsIgnoreCase('DIAGNOSTIC')) {
                                wk = wkTypeMap.get('Diagnostic');
                                serviceRepTemplateId = mapServiceReportLayout.get('Rapport de diagnostic');
                            } else if(sa.WorkType.Name.containsIgnoreCase('INSTALLATION') || sa.WorkType.Name.containsIgnoreCase('INTERVENTION')) {
                                wk = wkTypeMap.get('Intervention');
                                serviceRepTemplateId = mapServiceReportLayout.get('Rapport d\'intervention');
                            } else if(sa.WorkType.Name.containsIgnoreCase('METRAGE')) {
                                wk = wkTypeMap.get('Métrage');
                                serviceRepTemplateId = mapServiceReportLayout.get('Rapport de contrôle');
                            }
                            System.debug('## WorkType: '+wk);
                            sa.WorkTypeId = wk.Id;       
                            wo.WorkTypeId = wk.Id;  
                            wo.ServiceReportTemplateId = serviceRepTemplateId;
                            // DEBRIEF
                            sa = defineSADebrief(sa.WorkType.Name, sa, ord); 
                            // Create WOLI from Asset
                            List<Asset> assetsList = new List<Asset>();
                            assetsList = assetOrdersMap.get(ord.Id);
                            if(assetsList != null && !assetsList.isEmpty()) {
                                System.debug('## Create WOLI from Asset: '+assetsList.size());
                                for(Asset ast : assetsList) {
                                    String pbeId = mapProductPriceBook.get(ast.Product2Id);
                                    WorkOrderLineItem woli = new WorkOrderLineItem(
                                                                    WorkorderId = wo.Id, 
                                                                    AssetId = ast.Id,
                                                                    PricebookEntryId = pbeId,
                                                                    Subject = ast.Name,
                                                                    Status = 'Nouveau');
                                    woliToCreate.add(woli);
                                    System.debug('## WOLI: '+woli);
                                }
                            }
                            // Create WOLI from NCP
                            List<Case> ncpsList = new List<Case>();
                            ncpsList = caseOrdersMap.get(ord.Id);
                            if(ncpsList != null && !ncpsList.isEmpty() && String.isNotBlank(sa.fsl_externalid__c)
                                && (sa.fsl_externalid__c.containsIgnoreCase('SVI/') || sa.fsl_externalid__c.containsIgnoreCase('DVS/'))
                            ) {
                                System.debug('## Create WOLI from NCP: '+ncpsList.size());
                                for(Case ncp : ncpsList) {
                                    if(sa.CreatedDate >= ncp.dateTimeReopen__c) {
                                        String pbeId = mapProductPriceBook.get(ncp.ProductId);
                                        WorkOrderLineItem woli = new WorkOrderLineItem(
                                                                        WorkorderId = wo.Id, 
                                                                        AssetId = ncp.AssetId,
                                                                        PricebookEntryId = pbeId,
                                                                        productNonCompliance__c = ncp.Id,
                                                                        Subject = 'REPRISE HISTORIQUE',
                                                                        Status = 'Nouveau');
                                        woliToCreate.add(woli);
                                        System.debug('## WOLI: '+woli);
                                    }
                                }
                            }
                        //* REPRISE KUBE2
                        //* ----------------------   
                        } else {
                            sa.RecordTypeId = SA_KUBE2_RTID;       
                            wo.RecordTypeId = WO_KUBE2_RTID;   
                            sa = defineSADebrief(sa.WorkType.name, sa, ord); // DEBRIEF
                        }
                        saToUpdate.add(sa);
                        woToUpdate.add(wo);
                        successCount++;
                    }
                }
            }

            // MAJ
            if(!woToUpdate.isEmpty()) { 
                List<WorkOrder> woToUpdateList = new List<WorkOrder>();
                woToUpdateList.addAll(woToUpdate);
                update woToUpdateList;
            }
            if(!woliToCreate.isEmpty()) {
                insert woliToCreate;
            }
            if(!saToUpdate.isEmpty()) {
                update saToUpdate;
            }

            // MAJ Stats
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise RDV Kube2 -> Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN BA_RepriseRDVKube3 : execute');
    }

    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
        System.debug('### DEBUT BA_RepriseRDVKube3 : finish');    
        try {
            // Mise à jour des stats
            batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_RepriseRDVKube3 : finish');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise RDV Kube2 -> Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }

    private static ServiceAppointment defineSADebrief(String type, ServiceAppointment sa, Order ord) {
        if(sa.SchedStartTime <= Date.today() && sa.fsl_dateDebriefing__c == null 
            && ( ( (ord.legacyStatus__c.containsIgnoreCase('Totalement install') || ord.legacyStatus__c.containsIgnoreCase('Sold') 
                || ord.legacyStatus__c.containsIgnoreCase('En SAV'))
            && (sa.WorkType.Name.containsIgnoreCase('INSTALLATION') || sa.WorkType.Name.containsIgnoreCase('Intervention')) ) 
            || ( (ord.legacyStatus__c.containsIgnoreCase('Totalement install') || ord.legacyStatus__c.containsIgnoreCase('Sold') 
                    || ord.legacyStatus__c.containsIgnoreCase('En SAV') || ord.legacyStatus__c.containsIgnoreCase('Non install') || ord.legacyStatus__c.containsIgnoreCase('Non livr'))
                && (sa.WorkType.Name.containsIgnoreCase('METRAGE') || sa.WorkType.Name.containsIgnoreCase('Métrage') ) ) )
        ) {
            sa.ActualStartTime = (sa.ActualStartTime == null) ? sa.SchedStartTime : sa.ActualStartTime;
            sa.ActualEndTime = (sa.ActualEndTime == null) ? sa.SchedEndTime : sa.ActualEndTime;
            sa.fsl_dateDebriefing__c = sa.SchedEndTime;
            sa.Status = Constants.RDV_FSL_DEBRIEFE;
            System.debug('## Débrief: '+sa.ActualStartTime+' / '+sa.ActualEndTime+' / '+sa.fsl_dateDebriefing__c);
        }
        return sa;
    }
}