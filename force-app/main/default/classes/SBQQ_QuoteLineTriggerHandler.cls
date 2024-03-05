/**
 * Created by MCA on 15/09/2020.
 */

public without sharing class SBQQ_QuoteLineTriggerHandler {

    public static void removeOldProductOrdersOnAmendment(List<SBQQ__QuoteLine__c> quoteLines) {

        List<OrderItem> orderItems = new List<OrderItem>();
        Set<Id> orderItemIds = new Set<Id>();

        for (SBQQ__QuoteLine__c quotineLine : quoteLines) {
            System.debug('=============================== DELETE quotine valeurs précedentes: ' + quotineLine);
            if (quotineLine.AmendedOrderProduct__c != null) {
                orderItems.add(new OrderItem(
                        Id = quotineLine.AmendedOrderProduct__c,
                        SBQQ__BundleRoot__c = null, SBQQ__Activated__c = false,
                        StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING)
                );

                orderItemIds.add(quotineLine.AmendedOrderProduct__c);
            }
        }
/*
        System.debug('=============================== removeOldProductOrdersOnAmendment orderItemIds: ' + orderItemIds);
        if (!orderItems.isEmpty()) {
            List<Asset> assetsToDelete = new List<Asset>([SELECT Id FROM Asset WHERE orderItem__c in :orderItemIds ]);
            System.debug('=============================== removeOldProductOrdersOnAmendment assetsToDelete: ' + assetsToDelete);
            if (!assetsToDelete.isEmpty()) {
                //    delete assetsToDelete;
            }

            update orderItems;
            SBQQ.TriggerControl.disable();
            //delete orderItems;
            SBQQ.TriggerControl.enable();

        }
*/
    }
}