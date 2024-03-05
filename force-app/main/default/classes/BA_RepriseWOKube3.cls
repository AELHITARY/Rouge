//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseWOKube3
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/05/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseWOKube3 implements Database.Batchable<sObject>, Database.Stateful {
    private static final String WO_KUBE3_RTID = DAL.getRecordTypeIdByDevName('WorkOrder', 'workOrderService');
    private static final String ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    global BatchHistory__c batchHistoryStored {get;set;}
    global String serviceEntityId {get;set;}

    /***** Constructor *****/
    global BA_RepriseWOKube3(String serviceEntityId) {
        this.serviceEntityId = serviceEntityId; 

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('Kube3 - Reprise WO');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les données
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('### DEBUT BA_RepriseWOKube3 : start');
        try {
            Database.QueryLocator results;

            // Si le paramètre d'entrée "serviceEntityId" est vide, on récupère tous les dépots migrés Kube3. 
            // Sinon on récupère que le dépot en entrée
            List<Account> entitiesList = new List<Account>();
            if(String.isBlank(this.serviceEntityId)) {
                entitiesList = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_ENTITY_RTID
                                    AND entityType__r.KparKReference__c = 'DEP'
                                    AND migratedToK3__c = true];
            } else {
                entitiesList = [SELECT Id FROM Account 
                                WHERE Id = :this.serviceEntityId];
            }
            System.debug('## entitiesList: '+entitiesList);

            // Requête commande client
            results = Database.getQueryLocator([SELECT Id FROM Order
                                                WHERE serviceEntity__c IN :entitiesList
                                                AND isLegacy__c = true]);

            // Fin de l'init
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored); 
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) {
                batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            }
            System.debug('### FIN BA_RepriseWOKube3 : start');     
            return results;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise WO Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Order> scope){
        System.debug('### DEBUT BA_RepriseWOKube3 : execute');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        System.debug('## scope (' + scope.size() +')');
        List<WorkOrder> woToUpdate = new List<WorkOrder>();
        Map<String, List<WorkOrder>> mapWOCustomer = new Map<String, List<WorkOrder>>();

        try {
            Integer successCount = 0;

            if(!scope.isEmpty()) {      
                // Get WO List by CustomerOrder
                for(WorkOrder wo : [SELECT Id, customerOrder__c, WorkTypeId, WorkType.Name, CreatedDate, 
                                        Status, workOrderNumberByType__c FROM WorkOrder 
                                        WHERE customerOrder__c IN :scope
                                        AND RecordTypeId = :WO_KUBE3_RTID
                                        ORDER BY CreatedDate ASC]) {
                    List<WorkOrder> mapList = new List<WorkOrder>();
                    if (mapWOCustomer.get(wo.customerOrder__c) != null) {
                        mapList = mapWOCustomer.get(wo.customerOrder__c);
                    }
                    mapList.add(wo);
                    mapWOCustomer.put(wo.customerOrder__c, mapList);
                }
                System.debug('## mapWOCustomer: '+mapWOCustomer);

                // Process Order
                for(Order ord : scope) {
                    System.debug('####### Order: '+ord.Id);
                    List<WorkOrder> woList = mapWOCustomer.get(ord.Id); // WORKORDER        
                    if(woList != null && !woList.isEmpty()) {            
                        System.debug('## woList: '+woList.size());
                        Integer woMetrage = 1;
                        Integer woInter = 1;
                        Integer woDiag = 1;
                        for(WorkOrder wo : woList) {
                            System.debug('## WorkOrder: '+wo.Id+' / '+wo.WorkType.Name+' / '+wo.Status);
                            if(wo.Status == 'Annulé') {
                                wo.workOrderNumberByType__c = null;
                            } else {
                                if(wo.WorkType.Name.containsIgnoreCase('Diagnostic')) {
                                    wo.workOrderNumberByType__c = woDiag;
                                    woDiag++;
                                } else if(wo.WorkType.Name.containsIgnoreCase('Intervention')) {
                                    wo.workOrderNumberByType__c = woInter;
                                    woInter++;
                                } else if(wo.WorkType.Name.containsIgnoreCase('Métrage')) {
                                    wo.workOrderNumberByType__c = woMetrage;
                                    woMetrage++;
                                }
                                System.debug('## WO Number: '+wo.workOrderNumberByType__c);
                            }
                            woToUpdate.add(wo);
                            successCount++;
                        }
                    }
                }
            }

            // MAJ
            if(!woToUpdate.isEmpty()) {
                Database.update(woToUpdate, false);
            }

            // MAJ Stats
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise WO Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN BA_RepriseWOKube3 : execute');
    }

    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
        System.debug('### DEBUT BA_RepriseWOKube3 : finish');    
        try {
            // Mise à jour des stats
            batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_RepriseWOKube3 : finish');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise WO Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
}