//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomOrderManagerWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 26/05/2020
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CustomOrderManagerWizard {

    /**
    * @description Get actual Order
    * @param orderId Order Id
    * @return Order with all the needed information from the current order
    */
    @AuraEnabled(Cacheable = true)
    public static Order getOrder(String orderId){
        System.debug('### DEBUT LWC_CustomOrderManagerWizard.getOrder'); 
        Order result = new Order();

        // Query the order information
        if(String.isNotBlank(orderId)) {
            result = [SELECT  Id, Name, RecordType.DeveloperName, Status, transmissionDate__c
                        FROM Order WHERE Id = :orderId LIMIT 1];
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomOrderManagerWizard.getOrder');  
        return result;
    }

    /**
    * @description Get actual Cancelling Reasons
    * @param orderId Order Id
    * @return List with all reasons and details
    */
    @AuraEnabled(Cacheable = true)
    public static List<Referencial__c> getCancellingReasons(String sOrderId){
        System.debug('### DEBUT LWC_CustomOrderManagerWizard.getCancellingReasons'); 
        List<Referencial__c> result = new List<Referencial__c>();

        // Query the order information
        result = [SELECT  Id, Name
                    FROM Referencial__c
                    WHERE RecordType.DeveloperName = 'CancellationReason'];
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomOrderManagerWizard.getCancellingReasons');  
        return result;
    }
    
    /**
    * @description Get all the providers order opened from the customer order
    * @param orderId order id
    * @return Map with the provider orders
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, String> getProviderOrders(String orderId){
        System.debug('### DEBUT LWC_CustomOrderManagerWizard.getProviderOrders'); 
        Map<String, String> result = new Map<String, String>();
        List<Order> providerOrders = new List<Order>();
        System.debug('## orderId: '+orderId); 
        String providersOrderLabel;

        // Query the orders information
        if(String.isNotBlank(orderId)) {
            providerOrders = [SELECT  Id, Name, Status, estimatedShippingCost__c, shippingCost__c,
                                provider__r.Name, providerReference__c 
                                FROM Order WHERE parentOrder__c = :orderId 
                                AND transmissionDate__c != null AND Status != :Constants.ORDER_STATUS_CLOSED 
                                AND Status != :Constants.ORDER_STATUS_CANCELLED];
        }        
        System.debug('## providerOrders: '+providerOrders); 
        for(Order po : providerOrders) {
            providersOrderLabel = po.Name + ' - ' + po.provider__r.Name;
            if(po.providerReference__c != null){
                providersOrderLabel = providersOrderLabel + ' (' + po.providerReference__c + ')';
            }
            if(po.Status != 'Paid'){
                result.put(po.Id, providersOrderLabel);
                break;
            }
        }    
        
        for(Order po : providerOrders) {
            providersOrderLabel = po.Name + ' - ' + po.provider__r.Name;
            if(po.providerReference__c != null){
                providersOrderLabel = providersOrderLabel + ' (' + po.providerReference__c + ')';
            }
            if(!result.containsKey(po.Id)){
                result.put(po.Id, providersOrderLabel);
            }
        } 
        System.debug('### FIN LWC_CustomOrderManagerWizard.getProviderOrders');  
        return result;
    }

    /**
    * @description Get the orderItems list from the selected provider orders
    * @param orderId order id
    * @return List of the selected provider orders
    */
    @AuraEnabled
    public static List<OrderItem> getOrderItems(String orderId){
        System.debug('### DEBUT LWC_CustomOrderManagerWizard.getOrderItems'); 
        List<OrderItem> result = new List<OrderItem>();
        System.debug('## orderId: '+orderId); 

        // Get all orderItems
        if(String.isNotBlank(orderId)) {
            for(OrderItem ordItem : [SELECT  Id, name__c, productCost__c, asset__r.Name, Product2.Name, assetName__c, confirmationNumber__c,
                            estimatedProductCost__c, cancellationDate__c, shippingDate__c, dimensions__c, invoiceNumber__c, invoiceLineNumber__c,
                            confirmationDate__c, manufacturingStart__c, billingDate__c, manufacturingEnd__c, deliveryDate__c, deliveryNumber__c, 
                            contractualDeliveryDate__c, estimatedDeliveryDate__c, cancellationReason__c, location__c, receivedDate__c, deliveryLineNumber__c
                        FROM OrderItem 
                        WHERE OrderId = :orderId AND status__c != :Constants.ORDERITEM_STATUS_CANCELLED]) {
                if(String.isBlank(ordItem.name__c) || (String.isNotBlank(ordItem.name__c) && ordItem.name__c.containsIgnoreCase('inconnu'))) {
                    ordItem.name__c = ordItem.Product2.Name;
                } 
                if(String.isBlank(ordItem.assetName__c)) {
                    ordItem.assetName__c = ordItem.asset__r.Name;
                } 
                result.add(ordItem);
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomOrderManagerWizard.getOrderItems'); 
        return result;
    }

    /**
    * @description Method to update all orderItems with the new values
    * @param newValues List of Map containing for each of the updated elements : Id, updated fields with new value
    */
    @AuraEnabled
    public static String updateOrderItems(List<Map<String,String>> newValues, Decimal expeditionCostPrev, Decimal expeditionCostReal, 
                                            String orderId, Boolean showCostPrevField, Boolean showCostRealField, String selectedActionValue){
        System.debug('### DEBUT LWC_CustomOrderManagerWizard.updateOrderItems'); 
        String result;
        Map<String,OrderItem> orderItemsMap = new Map<String,OrderItem>();
        List<String> orderItemIdList = new List<String>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();  
        System.debug('## Order Id: '+orderId);
        System.debug('## New Values: '+newValues);
        System.debug('## Show Expedition Cost Prev: '+showCostPrevField);
        System.debug('## Expedition Cost Prev: '+expeditionCostPrev);
        System.debug('## Show Expedition Cost Real: '+showCostRealField);
        System.debug('## Expedition Cost Real: '+expeditionCostReal);
        System.debug('## selectedActionValue: '+selectedActionValue);
        
        if(String.isNotBlank(orderId)) {
            Order orderToUpdate = new Order();
            orderToUpdate.Id = orderId;
            if(showCostPrevField) {
                orderToUpdate.estimatedShippingCost__c = expeditionCostPrev;
            }
            if(showCostRealField) {
                orderToUpdate.shippingCost__c = expeditionCostReal;
            }
            System.debug('## Order to update: '+orderToUpdate); 
            update orderToUpdate;
        }

        try {   
            // Transform values define in the datatable
            for(Map<String, String> obj : newValues){
                OrderItem oi = new OrderItem();
                oi = transformDraftValuesToOrderItem(obj, selectedActionValue);
                orderItemsToUpdate.add(oi);
                System.debug('## Order Items to update: '+oi); 
            }
            // Update order items values
            if(!orderItemsToUpdate.isEmpty()) {
                Database.update(orderItemsToUpdate, true);
                result = 'OK';
            }
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('### FIN LWC_CustomOrderManagerWizard.updateOrderItems'); 
        return result;
    }

    /**
    * @description Transform values define in the datatable
    * @param obj Map of field and value defined by the user in the datatable
    * @return OrderItem OrderItem object with fields
    */
    private static OrderItem transformDraftValuesToOrderItem(Map<String,String> obj, String selectedActionValue){
        OrderItem oi = new OrderItem();
        OrderItem oiValues = new OrderItem();
        if(String.isNotBlank(obj.get('Id'))) {
            oi.Id = obj.get('Id');
            oiValues = [SELECT Id, providerReference__c, Order.provider__r.interfaceStreamPrefix__c, deliveryLineNumber__c FROM OrderItem WHERE Id =: oi.Id];
        }
        if(obj.containsKey('confirmationDate__c')) {
            oi.confirmationDate__c = String.isNotBlank(obj.get('confirmationDate__c')) ? Date.valueOf(obj.get('confirmationDate__c')) : null;
        }     
        if(obj.containsKey('confirmationNumber__c')) {
            oi.confirmationNumber__c = String.isNotBlank(obj.get('confirmationNumber__c')) ? obj.get('confirmationNumber__c') : null;
        }   
        if(obj.containsKey('productCost__c')) {
            oi.productCost__c = String.isNotBlank(obj.get('productCost__c')) ? Decimal.valueOf(obj.get('productCost__c')) : null;
        }    
        if(obj.containsKey('estimatedProductCost__c')) {
            oi.estimatedProductCost__c = String.isNotBlank(obj.get('estimatedProductCost__c')) ? Decimal.valueOf(obj.get('estimatedProductCost__c')) : null;
        }        
        if(obj.containsKey('cancellationDate__c')) {
            oi.cancellationDate__c = String.isNotBlank(obj.get('cancellationDate__c')) ? Date.valueOf(obj.get('cancellationDate__c')) : null;
        }        
        if(obj.containsKey('shippingDate__c')) {
            oi.shippingDate__c = String.isNotBlank(obj.get('shippingDate__c')) ? Date.valueOf(obj.get('shippingDate__c')) : null;
        }        
        if(obj.containsKey('manufacturingStart__c')) {
            oi.manufacturingStart__c = String.isNotBlank(obj.get('manufacturingStart__c')) ? Date.valueOf(obj.get('manufacturingStart__c')) : null;
        }        
        if(obj.containsKey('billingDate__c')) {
            oi.billingDate__c = String.isNotBlank(obj.get('billingDate__c')) ? Date.valueOf(obj.get('billingDate__c')) : null;
        }        
        if(obj.containsKey('manufacturingEnd__c')) {
            oi.manufacturingEnd__c = String.isNotBlank(obj.get('manufacturingEnd__c')) ? Date.valueOf(obj.get('manufacturingEnd__c')) : null;
        }        
        if(obj.containsKey('deliveryDate__c')) {
            oi.deliveryDate__c = String.isNotBlank(obj.get('deliveryDate__c')) ? Date.valueOf(obj.get('deliveryDate__c')) : null;
        }        
        if(obj.containsKey('contractualDeliveryDate__c')) {
            oi.contractualDeliveryDate__c = String.isNotBlank(obj.get('contractualDeliveryDate__c')) ? Date.valueOf(obj.get('contractualDeliveryDate__c')) : null;
        }        
        if(obj.containsKey('estimatedDeliveryDate__c')) {
            oi.estimatedDeliveryDate__c = String.isNotBlank(obj.get('estimatedDeliveryDate__c')) ? Date.valueOf(obj.get('estimatedDeliveryDate__c')) : null;
        }        
        if(obj.containsKey('cancellationReason__c')) {
            oi.cancellationReason__c = String.isNotBlank(obj.get('cancellationReason__c')) ? obj.get('cancellationReason__c') : null;
        }        
        if(obj.containsKey('receivedDate__c')) {
            oi.receivedDate__c = String.isNotBlank(obj.get('receivedDate__c')) ? Date.valueOf(obj.get('receivedDate__c')) : null;
        }
        if(obj.containsKey('productCost__c')) {
            oi.productCost__c = String.isNotBlank(obj.get('productCost__c')) ? Decimal.valueOf(obj.get('productCost__c')) : null;
        }  
        if(obj.containsKey('deliveryNumber__c')) {
            oi.deliveryNumber__c = String.isNotBlank(obj.get('deliveryNumber__c')) ? obj.get('deliveryNumber__c') : null;
        }   
        if(obj.containsKey('deliveryLineNumber__c')) {
            oi.deliveryLineNumber__c = String.isNotBlank(obj.get('deliveryLineNumber__c')) ? obj.get('deliveryLineNumber__c') : null;
        } 
        if(obj.containsKey('invoiceNumber__c')) {
            oi.invoiceNumber__c = String.isNotBlank(obj.get('invoiceNumber__c')) ? obj.get('invoiceNumber__c') : null;
        }   
        if(obj.containsKey('invoiceLineNumber__c')) {
            oi.invoiceLineNumber__c = String.isNotBlank(obj.get('invoiceLineNumber__c')) ? obj.get('invoiceLineNumber__c') : null;
        } 
        // Donnée technique Interface Fournisseur
        String billingNumber = '';
        String deliveryNumber = '';
        if(oiValues.Order.provider__r.interfaceStreamPrefix__c != null && String.isNotBlank(obj.get('Id'))) {
            billingNumber = oiValues.Order.provider__r.interfaceStreamPrefix__c + '/';
            deliveryNumber = oiValues.Order.provider__r.interfaceStreamPrefix__c + '/';
        }
        System.debug('selectedActionValue: '+selectedActionValue); 
        if(selectedActionValue == 'Facturation') {
            System.debug('oi.invoiceNumber__c: '+oi.invoiceNumber__c); 
            if(String.isNotBlank(oi.invoiceNumber__c)) {
                oi.billingNumber__c = billingNumber + obj.get('invoiceNumber__c') + '/' + obj.get('invoiceLineNumber__c');
            } else {
                oi.billingNumber__c = null;
            }
            System.debug('oi.billingNumber__c: '+oi.billingNumber__c); 
            /*if(obj.containsKey('invoiceNumber__c')) {
                oi.billingNumber__c = billingNumber + obj.get('invoiceNumber__c') + '/' + obj.get('invoiceLineNumber__c');
            }*/
        }
        if(selectedActionValue == 'Livraison') {
            if(String.isNotBlank(oi.deliveryNumber__c)) {
                oi.deliveryNumberRef__c = deliveryNumber + obj.get('deliveryNumber__c') + '/' + obj.get('deliveryLineNumber__c');
            } else {
                oi.deliveryNumberRef__c = null;
            }
            /*if(obj.containsKey('deliveryNumber__c')) {
                oi.deliveryNumberRef__c = deliveryNumber + obj.get('deliveryNumber__c') + '/' + obj.get('deliveryLineNumber__c');
            }*/
        }
        return oi;
    }
}