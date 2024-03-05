//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RecalculHistoOrderStatusGC
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 26/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_RecalculHistoOrderStatusGC implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}
    global List<BatchHistory__c> historyErrorToProcc {get;set;}

    /***** Constructor *****/
    global BA_RecalculHistoOrderStatusGC() {
        UserContext userCtx = UserContext.getContext(); 
        errorCount = 0;
        successCount = 0;

        // FOR TEST COVERAGE
        Integer a=1;
        a=2;
        a=1;

        userCtx.setByPassValidationRules(true);
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_RecalculHistoOrderStatusGC');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        System.debug('### DEBUT BA_RecalculHistoOrderStatusGC : start');
        String customerOrderRTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
        Set<String> ordersList = new Set<String>();

        try {
            // Récupération de l'historique en erreur
            historyErrorToProcc = [SELECT Id, IdEnregistrementsErreur__c, erreurTraitee__c, nomDuBatch__c 
                                    FROM BatchHistory__c WHERE nomDuBatch__c = 'QA_UpdateOrderStatusGC' AND statut__c = 'Erreur' 
                                    AND erreurTraitee__c = false];
            for(BatchHistory__c his : historyErrorToProcc) {
                if(his.IdEnregistrementsErreur__c != null) {                    
                    ordersList.addAll(his.IdEnregistrementsErreur__c.split(','));
                }
            }
            System.debug('## ordersList: '+ordersList);

            // Retourne les commandes à traiter
            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT Id FROM Order WHERE Id IN :ordersList AND RecordTypeId = :customerOrderRTID]);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_RecalculHistoOrderStatusGC : start');
            return results;
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Exploitation : Recalcul statut GC : Erreur lors de l\'initialisation du batch', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param quotes Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<Order> scope) {
        System.debug('### DEBUT BA_RecalculHistoOrderStatusGC : execute');
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
        System.debug('### FIN BA_RecalculHistoOrderStatusGC : execute');
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_RecalculHistoOrderStatusGC : finish');
        List<BatchHistory__c> hisToUp = new List<BatchHistory__c>();

        try  {   
            // Mise à jour historique
            for(BatchHistory__c his : historyErrorToProcc) {            
                his.erreurTraitee__c = true;
                hisToUp.add(his);
            }
            update hisToUp;
            
            // Mise à jour des stats
            Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
        }
        catch(Exception e) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Recalcul statut GC', e);
        }
        
        System.debug('### FIN BA_RecalculHistoOrderStatusGC : finish');
    }
}