//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR023_Order_Commission
//-- Créé par    : 4C (25/03/2021)
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/06/2023
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public with sharing class TR023_Order_Commission {
    public static final Id customerOrderRTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final ID RT_PROVIDER_ORDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    
    /**
     * @description When an order is updated, start remVRP processing to calculate commissions (if needed)
     * @param context User context
     */
    public static void processCommission(UserContext context) {
        System.debug('### DEBUT TR023_Order_Commission : processCommission');

        Map<Id, SObject> oldMap = Trigger.oldMap;
        Map<Id, SObject> newMap = Trigger.newMap;
        List<Id> cpqQuoteIds = new List<Id>();
        List<Id> quoteIds = new List<Id>();
        List<Id> remVRPQuotesIds = new List<Id>();
        List<Id> remVRPQuotesAlreadyCalculatedIds = new List<Id>();
        List<Id> orderIdList = new List<Id>();
        List<Order> providerOrderList = new List<Order>();
        Map<Id,Decimal> providerLinesConfirmed = new Map<Id, Decimal>();
        
        for(Order order : (List<Order>)newMap.values()){
            orderIdList.add(order.Id);
        }
        providerOrderList = [SELECT Id, confirmedOrderItemCount__c, parentOrder__c FROM Order WHERE parentOrder__c IN :orderIdList AND RecordTypeId = :RT_PROVIDER_ORDER];
        for(Order po : providerOrderList){
            if(providerLinesConfirmed.get(po.parentOrder__c) == null && po.confirmedOrderItemCount__c != null){
                providerLinesConfirmed.put(po.parentOrder__c, po.confirmedOrderItemCount__c);
            } else if(po.confirmedOrderItemCount__c != null){
                Decimal nbConfrmedLines = 0;
                nbConfrmedLines = providerLinesConfirmed.get(po.parentOrder__c);
                nbConfrmedLines+= po.confirmedOrderItemCount__c;
                providerLinesConfirmed.put(po.parentOrder__c, nbConfrmedLines);
            }
        }

        //Get all related quotes Ids (sales and CPQ)
        for (Order order : (List<Order>)newMap.values()) {
            // Si order validée,
            // relance le calcul des commissions pour mise à jour du statut des commissions
            if (order.Type != Constants.ORDER_TYPE_AVENANT && // FIX JMU 14/06 Commissions en double
                //((Order)oldMap.get(order.Id)).Status != Constants.ORDER_STATUS_AMENDING && // FIX JMU 10/07/2023 Empêcher le calcul de l'initial lors du déversement
                order.RecordTypeId == customerOrderRTID && (order.Status == Constants.ORDER_STATUS_VALIDATED || order.Status == Constants.ORDER_STATUS_CONTROLLED || 
                order.Status == Constants.ORDER_STATUS_ORDERED || order.Status == Constants.ORDER_STATUS_CANCELLED)
                    && ((order.Status != ((Order)oldMap.get(order.Id)).Status) || /*order.oldCompositeStatus__c != ((Order)oldMap.get(order.Id)).oldCompositeStatus__c) ||
                    (order.unconfirmedProviderOrderCount__c != ((Order)oldMap.get(order.Id)).unconfirmedProviderOrderCount__c))*/ 
                    (providerLinesConfirmed.get(order.Id) != null && providerLinesConfirmed.get(order.Id) > 0))) {

                //cas des quotes CPQ
                if (order.SBQQ__Quote__c != null) {
                    cpqQuoteIds.add(order.SBQQ__Quote__c);
                    //quoteIds.add(order.SBQQ__Quote__c);
                }

                //cas des quotes sales, inutile car changement de statut de la quote
                if (order.QuoteId != null) {
                    quoteIds.add(order.QuoteId);
                }
            }
        }

        //List CPQ Quotes
        if (!cpqQuoteIds.isEmpty()) {
            System.debug('Commission has ' + cpqQuoteIds.size() + ' CPQ Quotes to process');
            for (SBQQ__Quote__c q : [SELECT Id, SBQQ__Status__c, amendInitialQuote__c, previousQuote__c FROM SBQQ__Quote__c WHERE Id IN :cpqQuoteIds]) {
                System.debug('       bypass: ' + (context != null && context.canByPassTrigger('TR023_Order_Commission')));
                if (context == null || !context.canByPassTrigger('TR023_Order_Commission')) {
                    if (!remVRPQuotesIds.contains(q.Id) && !remVRPQuotesAlreadyCalculatedIds.contains(q.Id) && !AlreadyUsed.isUsed('TR023_Order_Commission.QA_QuoteProcessCommissions', q.Id)) {
                        remVRPQuotesIds.add(q.Id);
                        remVRPQuotesAlreadyCalculatedIds.add(q.Id);
                        remVRPQuotesAlreadyCalculatedIds.add(q.amendInitialQuote__c);
                        remVRPQuotesAlreadyCalculatedIds.add(q.previousQuote__c);
                    }
                }
                System.debug('       remVRPQuotesIds: ' + remVRPQuotesIds);
            }
        }

        //List sales quotes, inutile car changement de statut de la quote
        if (!quoteIds.isEmpty()) {
            System.debug('Commission has ' + quoteIds.size() + ' sales Quotes to process');
            for (String qId : quoteIds) {
                if (context == null || !context.canByPassTrigger('TR023_SBQQ__Quote')) {
                    if (!remVRPQuotesIds.contains(qId) && !AlreadyUsed.isUsed('TR023_SBQQ__Quote.QA_QuoteProcessCommissions', qId)) {
                        remVRPQuotesIds.add(qId);
                    }
                }
            }
        }

        //If quotes found, start processing remuneration
        if (!remVRPQuotesIds.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())) {
            System.debug('Order_AfterUpdate launch remVRP commissions calculation for quotes ' + remVRPQuotesIds);
            QA_QuoteProcessCommissions job = new QA_QuoteProcessCommissions(remVRPQuotesIds);
            System.enqueueJob(job);
        }

        System.debug('### FIN TR023_Order_Commission : processCommission');
    }

}