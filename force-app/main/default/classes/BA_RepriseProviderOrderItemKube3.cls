//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseProviderOrderItemKube3
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/04/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseProviderOrderItemKube3 implements Database.Batchable<sObject>, Database.Stateful {
    private static final String ORD_PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final String ACC_ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    global BatchHistory__c batchHistoryStored {get;set;}
    global String serviceEntityId {get;set;}

    /***** Constructor *****/
    global BA_RepriseProviderOrderItemKube3(String serviceEntityId) {
        this.serviceEntityId = serviceEntityId; 

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('Kube3 - Reprise ProviderOrder');
        }
    }
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les données
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('### DEBUT BA_RepriseProviderOrderItemKube3 : start');
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

            // Requête récupération RDV
            results = Database.getQueryLocator([SELECT Id, status__c
                                                FROM OrderItem WHERE Order.AccountId IN :entitiesList 
                                                AND isLegacy__c = true
                                                AND status__c = 'Enregistré' 
                                                AND Order.RecordTypeId = :ORD_PROVIDER_RTID]);

            // Fin de l'init
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored); 
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) {
                batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            }
            System.debug('### FIN BA_RepriseProviderOrderItemKube3 : start');     
            return results;
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise ProviderOrderItem Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<OrderItem> scope){
        System.debug('### DEBUT BA_RepriseProviderOrderItemKube3 : execute');
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        System.debug('## scope (' + scope.size() +')');

        try {
            Integer successCount = scope.size();
            if(!scope.isEmpty()) {
                Database.update(scope, false);
            }

            // MAJ Stats
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise ProviderOrderItem Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN BA_RepriseProviderOrderItemKube3 : execute');
    }

    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC){
        System.debug('### DEBUT BA_RepriseProviderOrderItemKube3 : finish');    
        try {
            // Mise à jour des stats
            batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_RepriseProviderOrderItemKube3 : finish');
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] KUBE3 : Reprise ProviderOrderItem Kube3', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
}