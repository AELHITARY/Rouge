//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_OrderNonCompliance 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 06/01/2022
//-- Version     : 1.0
//-- * 1.0 :  Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR022_OrderNonCompliance {

    /**
      * @description Mise à jour du statut GC des commandes
      * @param userContext Contexte de l'utilisateur courant
      */
      public static void updateOrderGCStatus(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        
        Set<Id> orderIdsList = new Set<Id>();
        for(OrderNonCompliance__c ncc : (List<OrderNonCompliance__c>)Trigger.new){
            if(ncc.customerOrder__c != null){
                orderIdsList.add(ncc.customerOrder__c);
            }             
        }

        // LEGACY KUBE 2 : Calcul ancien statut GC
        if(!orderIdsList.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            System.debug('## Exec queueable update old status GC: ' + orderIdsList);
            System.enqueueJob(new QA_UpdateOrderStatusGC(orderIdsList));
        }
  
    }

    /**
      * @description Mise à jour des commissions si nécessaire
      * @param userContext Contexte de l'utilisateur courant
      */
      public static void updateCommissions(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        
        Set<Id> orderIdsList = new Set<Id>();
        if(Trigger.isUpdate){
            Map<Id, OrderNonCompliance__c> oldNCCs = (Map<Id, OrderNonCompliance__c>)Trigger.oldMap;
            for(OrderNonCompliance__c ncc : (List<OrderNonCompliance__c>)Trigger.new){
                OrderNonCompliance__c oldNCC = oldNCCs.get(ncc.Id);
                if(oldNCC.closeDate__c != ncc.closeDate__c){
                    orderIdsList.add(ncc.customerOrder__c);
                }             
            }

            // Récupération des devis des commandes concernées
            List<Order> orderList = new List<Order>();
            orderList = [SELECT Id, QuoteId, SBQQ__Quote__c FROM Order WHERE id IN :orderList];

            List<String> quoteIdList = new List<String>();
            if(!orderIdsList.isEmpty()){
                for(Order o : orderList){
                    if(o.QuoteId != null){
                        quoteIdList.add(o.QuoteId);
                    }
                    if(o.SBQQ__Quote__c != null){
                        quoteIdList.add(o.SBQQ__Quote__c);
                    }
                }
            }

            // LEGACY KUBE 2 : Calcul ancien statut GC
            if(!quoteIdList.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Exec queueable update old status GC: ' + quoteIdList);
                System.enqueueJob(new QA_QuoteProcessCommissions(quoteIdList));
            }
        }
    }

    /**
    * @description Méthode pour mettre à jour les commande associé a la NN
    * @param userContext contexte utilisateur
    */
    public static void updateAsset(UserContext userContext) {
        System.debug('### DEBUT TR022_OrderNonCompliance.updateParentOrderAndAsset');
        List<OrderNonCompliance__c> NCCList = Trigger.new;
        Map<Id, OrderNonCompliance__c> oldNCCs = (Map<Id, OrderNonCompliance__c>)Trigger.oldMap;
        List<String> orderIdList = new List<String>();
        List<Order> ordersToUpdate = new List<Order>();
        Map<Id,List<Asset>> orderIdToAsset = new Map<Id,List<Asset>>();
        Boolean updateAsset = false;
        
        
        for (OrderNonCompliance__c NCC : NCCList){
            if((Trigger.isUpdate && NCC.closeDate__c != oldNCCS.get(NCC.Id).closeDate__c) || 
                (Trigger.isInsert && NCC.duration__c != null)){
                if(NCC.customerOrder__c != null && orderIdList.contains(NCC.customerOrder__c) == false){
                    orderIdList.add(NCC.customerOrder__c);
                }
                updateAsset = true;
            }
        }
        
        if(updateAsset){
            Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id FROM Order WHERE Id IN :orderIdList]);
        
            for (OrderNonCompliance__c newNCC : NCCList){
                OrderNonCompliance__c oldNCC = oldNCCs == null ? null : oldNCCs.get(newNCC.Id);
                if(newNCC.customerOrder__c != null && orderMap.get(newNCC.customerOrder__c) != null && 
                    oldNCC != null && newNCC.duration__c != oldNCC.duration__c){
                        ordersToUpdate.add(orderMap.get(newNCC.customerOrder__c));
                }   
            }
        
            List<Asset> assetsToUpdate = [SELECT Id, customerOrder__c FROM Asset WHERE customerOrder__c IN :ordersToUpdate AND ParentId = null];
        
            if(!assetsToUpdate.isEmpty()){
                update assetsToUpdate;
            }
        }
		System.debug('### FIN TR022_OrderNonCompliance.updateParentOrderAndAsset');
    }
}