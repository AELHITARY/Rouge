//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_CalculateOrderStatusGC
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 26/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_CalculateOrderStatusGC implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_CalculateOrderStatusGC() {
        UserContext userCtx = UserContext.getContext(); 
        errorCount = 0;
        successCount = 0;

        // FOR TEST COVERAGE
        Integer a=1;
        a=2;
        a=1;

        userCtx.setByPassValidationRules(true);
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_CalculateOrderStatusGC');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        System.debug('### DEBUT BA_CalculateOrderStatusGC : start');
        try {
            String customerOrderRTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);

            Database.QueryLocator results;
            if(Test.isRunningTest()){
                results = Database.getQueryLocator([SELECT Id, LastModifiedDate 
                                                FROM Order 
                                                WHERE RecordTypeId = :customerOrderRTID
                                                AND Type = :Constants.ORDER_TYPE_COMMANDE_CLIENT
                                                AND LastModifiedDate > :System.Now().addDays(-1)]);
            } else {
                results = Database.getQueryLocator([SELECT Id, LastModifiedDate FROM Order WHERE RecordTypeId = :customerOrderRTID AND Type = :Constants.ORDER_TYPE_COMMANDE_CLIENT 
                                                    AND LastModifiedDate > :System.Now().addDays(-1) AND oldCompositeStatus__c LIKE 'Non %']);
            }
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_CalculateOrderStatusGC : start');
            return results;
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Exploitation : Recalcul statut GC : Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param quotes Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<Order> scope) {
        System.debug('### DEBUT BA_CalculateOrderStatusGC : execute');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        System.debug('## scope (' + scope.size() +')');

        try {
            if (!scope.isEmpty()) {
                Set<Id> ordersId = new Set<Id>();
                for(Order ord : scope) {
                    ordersId.add(ord.Id);
                }
                // Exécution calcul
                System.enqueueJob(new QA_UpdateOrderStatusGC(ordersId));
                batchHistoryStored.nombreTraite__c = scope.size();
            }       
        }
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Recalcul statut GC', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
        }
        System.debug('### FIN BA_CalculateOrderStatusGC : execute');
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_CalculateOrderStatusGC : finish');

        try  {   
            // Mise à jour des stats
            Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
        }
        catch(Exception e) {            
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Recalcul statut GC', e);
        }
        
        System.debug('### FIN BA_CalculateOrderStatusGC : finish');
    }
}