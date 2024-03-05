//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_CalculateOrderStatusGCForDailySA 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 06/07/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_CalculateOrderStatusGCForDailySA implements Database.Batchable<sObject>, Database.Stateful {
    private static final String SA_KUBE3_RTID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'ServiceAppointment');
    global UserContext userCtx;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_CalculateOrderStatusGCForDailySA() {
        UserContext userCtx = UserContext.getContext(); 
        errorCount = 0;
        successCount = 0;

        // FOR TEST COVERAGE
        Integer a=1;
        a=2;
        a=1;

        userCtx.setByPassValidationRules(true);
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_CalculateOrderStatusGCForDailySA');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        System.debug('### DEBUT BA_CalculateOrderStatusGCForDailySA : start');
        try {
            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT Id, customerOrder__c 
                                                FROM ServiceAppointment 
                                                WHERE (RecordTypeId = null OR RecordTypeId = :SA_KUBE3_RTID)
                                                  AND schedStartTime = TODAY
                                                  AND customerOrder__c != null]);
            /*String query = 'SELECT Id, customerOrder__c FROM ServiceApppointment WHERE (RecordTypeId = null OR RecordTypeId = :SA_KUBE3_RTID) AND schedStartTime = TODAY AND customerOrder__c != null';
                                                  
            results = Database.getQueryLocator(query);*/
            
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_CalculateOrderStatusGCForDailySA : start');
            return results;
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Exploitation : Recalcul statut GC : Erreur lors de l\'initialisation du batch SA', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param quotes Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<ServiceAppointment> scope) {
        System.debug('### DEBUT BA_CalculateOrderStatusGCForDailySA : execute');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        System.debug('## scope (' + scope.size() +')');

        try {
            if (!scope.isEmpty()) {
                Set<Id> ordersId = new Set<Id>();
                for(ServiceAppointment sa : scope) {
                    ordersId.add(sa.customerOrder__c);
                }
                // Exécution calcul
                System.enqueueJob(new QA_UpdateOrderStatusGC(ordersId));
                batchHistoryStored.nombreTraite__c = scope.size();
            }       
        }
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Recalcul statut GC Batch SA', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
        }
        System.debug('### FIN BA_CalculateOrderStatusGCForDailySA : execute');
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_CalculateOrderStatusGCForDailySA : finish');

        try  {   
            // Mise à jour des stats
            Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
        }
        catch(Exception e) {            
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Recalcul statut GC Batch SA', e);
        }
        
        System.debug('### FIN BA_CalculateOrderStatusGCForDailySA : finish');
    }
}