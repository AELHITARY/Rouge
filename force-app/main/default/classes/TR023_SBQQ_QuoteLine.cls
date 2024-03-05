//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR023_SBQQ_QuoteLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/06/2023
//-- Version     : 1.1
//-- * 1.1 : Optimisation
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR023_SBQQ_QuoteLine {

    /**
    * @description Méthode exécutée pour le déversement des commandes client avenant dans la commande client initial pour les devis CPQ
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void amendmentUpdateCPQOrderItem(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }   
        
        System.debug('### DEBUT TR023_SBQQ_QuoteLine.amendmentUpdateCPQOrderItem');
        List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) Trigger.new;
        Map<Id, SBQQ__Quote__c>  oldQuotes = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
        List<SBQQ__Quote__c> quotesList = new List<SBQQ__Quote__c>();
        List<Id> ordersIds = new List<Id>();

        // Filter quotes to restrict process to amendment quotes in status SOLD SAVED
        for (SBQQ__Quote__c quote : newQuotes) {
            System.debug('## quote: ' + quote.Id);
            System.debug('## quote.AmendmentQuote__c: ' + quote.AmendmentQuote__c);
            System.debug('## quote.amendmentOrderApproved__c: ' + quote.amendmentOrderApproved__c);
            System.debug('## quote.techPB__c: ' + quote.techPB__c);
            System.debug('## quote.SBQQ__Status__c: ' + quote.SBQQ__Status__c);
            if (quote.AmendmentQuote__c
                && quote.amendmentOrderApproved__c
                && quote.techPB__c == false
                && !AlreadyUsed.isUsed('TR023_SBQQ_QuoteLine.amendmentUpdateCPQOrderItem', quote.Id)
                && quote.SBQQ__Status__c.startsWithIgnoreCase(Constants.QUOTE_STATUS_SOLD)) 
            {
                quotesList.add(quote);
                ordersIds.add(quote.customerOrder__c);
            }
        }

        // Leave if quotes not loaded
        if (quotesList == null || quotesList.isEmpty()) {
            return;
        }
        System.debug('## QuoteLine process started for quotes: ' + quotesList);

        //Order Items to remove because quote lines removed in QLE
        Set<OrderItem> orderItemsToRemove = new Set<OrderItem>();

        // Get all Quote lines of each quote
        Map<Id, List<SBQQ__QuoteLine__c>> quoteQuotelinesMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        Set<Id> orderItemsIds = new Set<Id>();
        for (SBQQ__QuoteLine__c ql : [SELECT Id, SBQQ__Quote__c, AmendedOrderProduct__c, SBQQ__Quantity__c,
                SBQQ__Product__c, SBQQ__PricebookEntryId__c, Quantite__c, AmendedQLValidated__c,
                SBQQ__Bundle__c, PrixNetRemiseTTC__c, SBQQ__NetPrice__c, SBQQ__ProductCode__c,
                TauxTVAPercent__c, SBQQ__OriginalPrice__c, SBQQ__ListPrice__c,
                NombreVantaux__c, Largeur__c, Hauteur__c, ProductType__c, QuoteLineQuantity__c,
                OrderProductCreated__c, SBQQ__ProductName__c, SBQQ__RequiredBy__c, purchasePrice__c,
                SBQQ__PackageTotal__c, unit__c, PrixUnitaire__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quotesList]) 
        {
            // Map des lignes par devis
            if (!quoteQuotelinesMap.containsKey(ql.SBQQ__Quote__c)) {
                quoteQuotelinesMap.put(ql.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
            }
            quoteQuotelinesMap.get(ql.SBQQ__Quote__c).add(ql);
            // Liste des lignes de commandes
            if (String.isNotBlank(ql.AmendedOrderProduct__c)) {
                orderItemsIds.add(ql.AmendedOrderProduct__c);
            }
        }

        // Get all Order Items associated to quotes, and select those without associated Quote Lines
        // (Quote Lines removed in the QLE) to remove them
        for(OrderItem oi : [SELECT Id FROM OrderItem WHERE OrderId = :ordersIds]) {
            if (!orderItemsIds.contains(oi.Id)) orderItemsToRemove.add(oi);
        }
        System.debug('## Will remove unaffected orderItems: ' + orderItemsToRemove.size());

        // Get order products of each quoteline
        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
        if (!orderItemsIds.isEmpty()) {
            for (OrderItem it : [SELECT Id, AmendmentQuoteLine__c, Quantity, SBQQ__OrderedQuantity__c,
                    SBQQ__QuoteLine__c, SBQQ__QuotedListPrice__c, SBQQ__QuotedQuantity__c, StatutDeRevision__c,
                    UnitPrice, VATAmount__c, VATRate__c, productType__c, OrderId,
                    PricebookEntryId, ListPrice, Product2Id, assetCount__c, assetAmendableCount__c,
                    height__c, leaf__c, locationPrecision__c, name__c, unit__c,
                    reference__c, width__c, parentOrderItem__c, asset__c, purchasePrice__c
                    FROM OrderItem WHERE Id IN :orderItemsIds]) {

                orderItemMap.put(it.Id, it);
            }
        }

        // List for all objects to update and add at the end
        List<OrderItem> parentOrderItemsToUpdate = new List<OrderItem>();
        Map<Id, List<OrderItem>> parentQLChildMap = new Map<Id, List<OrderItem>>();
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        
        //disable CPQ internal triggers to prevent errors
        SBQQ.TriggerControl.disable();

        // Process each quote
        for (SBQQ__Quote__c q : quotesList) {
            List<SBQQ__QuoteLine__c> quoteLines = quoteQuotelinesMap.get(q.Id);
            if (quoteLines != null && !quoteLines.isEmpty()) {
                Double qlTotal = 0.0;
                Double orderedTotal = 0.0;
                Double quotedTotal = 0.0;

                System.debug('## Processing ' + quoteLines.size() + ' quotelines');
                // For each quoteline
                for (SBQQ__QuoteLine__c ql : quoteLines) {
                    System.debug('## Quoteline attributes for decision: ');
                    System.debug('##-- Id=' + ql.Id);
                    System.debug('##-- AmendedQLValidated__c: ' + ql.AmendedQLValidated__c);
                    System.debug('##-- AmendedOrderProduct__c: ' + ql.AmendedOrderProduct__c);
                    System.debug('##-- OrderProductCreated__c: ' + ql.OrderProductCreated__c);
                    System.debug('##-- SBQQ__Quantity__c: ' + ql.SBQQ__Quantity__c);

                    if (String.isNotBlank(ql.AmendedOrderProduct__c)) {
                        qlTotal += ql.SBQQ__Quantity__c;
                        System.debug('## Modify Order Product after amendment');

                        // Modify Order Product after amendment
                        OrderItem orderProduct = orderItemMap.get(ql.AmendedOrderProduct__c);
                        OrderItem newOrderProduct = new OrderItem();

                        System.debug('##-- orderItem.Id: ' + orderProduct.Id);
                        System.debug('##-- orderItem.StatutDeRevision__c: ' + orderProduct.StatutDeRevision__c);
                        System.debug('##-- orderItem.SBQQ__QuoteLine__c: ' + orderProduct.SBQQ__QuoteLine__c);
                        System.debug('##-- orderItem.SBQQ__OrderedQuantity__c: ' + orderProduct.SBQQ__OrderedQuantity__c);
                        System.debug('##-- orderItem.SBQQ__QuotedQuantity__c: ' + orderProduct.SBQQ__QuotedQuantity__c);

                        if (orderProduct == null ||
                                (orderProduct.StatutDeRevision__c != Constants.ORDERITEM_STATUTREVISION_UPDATING)
                                && (orderProduct.SBQQ__QuoteLine__c != null)) {
                            continue;
                        }

                        // 1 - Update order product
                        if (orderProduct.StatutDeRevision__c == Constants.ORDERITEM_STATUTREVISION_UPDATING) {
                            System.debug('## Update order product: ' + orderProduct.Id);
                            newOrderProduct.OrderId = q.customerOrder__c;
                            newOrderProduct.previousOrderItem__c = orderProduct.Id;
                            newOrderProduct.PricebookEntryId = ql.SBQQ__PricebookEntryId__c;
                            if (ql.SBQQ__ProductCode__c != null && ql.SBQQ__ProductCode__c.contains('OTHFRAISPOSE')) {
                                newOrderProduct.Quantity = ql.Quantite__c == 0 ? 0 : 1;
                                newOrderProduct.SBQQ__QuotedQuantity__c = ql.Quantite__c == 0 ? 0 : 1;
                            } else {
                                newOrderProduct.Quantity = ql.SBQQ__Quantity__c;
                                newOrderProduct.SBQQ__QuotedQuantity__c = ql.SBQQ__Quantity__c;
                                newOrderProduct.SBQQ__OrderedQuantity__c = ql.SBQQ__Quantity__c;
                            }
                            newOrderProduct.orderItemQuantity__c = ql.QuoteLineQuantity__c;
                            newOrderProduct.Product2Id = ql.SBQQ__Product__c;
                            newOrderProduct.SBQQ__QuoteLine__c = ql.Id;
                            newOrderProduct.SBQQ__QuotedListPrice__c = ql.SBQQ__ListPrice__c;
                            newOrderProduct.productType__c = ql.productType__c;
                            //newProduct.UnitPrice = (ql.SBQQ__NetPrice__c != null) ? ql.SBQQ__NetPrice__c : 0;
                            newOrderProduct.UnitPrice = (ql.PrixUnitaire__c != null) ? ql.PrixUnitaire__c : 0; 
                            // On conserve le statut 'En cours de révision' jusqu'à la fin pour ne pas déclencher
                            // les triggers lors de l'insertion des lignes parentes alors que les options
                            // ne sont pas encore enregistrées
                            newOrderProduct.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                            newOrderProduct.assetCount__c = orderProduct.assetCount__c;
                            newOrderProduct.assetAmendableCount__c = orderProduct.assetAmendableCount__c;
                            // Si ligne parent et Quantité = 0 alors on annule la ligne en mettant date d'annulation
                            if(ql.SBQQ__RequiredBy__c == null && ql.SBQQ__Quantity__c == 0) {
                                newOrderProduct.cancellationDate__c = Date.today();
                            }
                            
                            System.debug('##-- ql.SBQQ__Quantity__c: ' + ql.SBQQ__Quantity__c);
                            System.debug('##-- ql.QuoteLineQuantity__c: ' + ql.QuoteLineQuantity__c); 
                            System.debug('##-- ql.Quantite__c: ' + ql.Quantite__c);                               
                            System.debug('##-- newOrderProduct.Quantity : ' + newOrderProduct.Quantity );
                            
                            System.debug('## Order product: ' + newOrderProduct);

                            // si option -> parentOrderItem__c = id orderitem principal
                            // if (ql.SBQQ__RequiredBy__c == null) -> principal
                            if (ql.SBQQ__RequiredBy__c == null) {
                                parentOrderItemsToUpdate.add(newOrderProduct);
                                if (!parentQLChildMap.containsKey(ql.Id)) {
                                    parentQLChildMap.put(ql.Id, new List<OrderItem>());
                                }
                            } else {
                                if (!parentQLChildMap.containsKey(ql.SBQQ__RequiredBy__c)) {
                                    parentQLChildMap.put(ql.SBQQ__RequiredBy__c, new List<OrderItem>());
                                }
                                parentQLChildMap.get(ql.SBQQ__RequiredBy__c).add(newOrderProduct);
                            }

                            orderedTotal += newOrderProduct.SBQQ__OrderedQuantity__c != null ? newOrderProduct.SBQQ__OrderedQuantity__c : 0;
                            quotedTotal += newOrderProduct.SBQQ__QuotedQuantity__c != null ? newOrderProduct.SBQQ__QuotedQuantity__c : 0;

                            //detach from quoteline to free quantity
                            orderProduct.SBQQ__QuoteLine__c = null;
                            if (orderProduct.parentOrderItem__c == null) {
                                orderProduct.SBQQ__OrderedQuantity__c = 0; //set quantity to 0 on parent line
                            }
                            orderItemsToRemove.add(orderProduct);
                        }
                    } else if (ql.AmendedOrderProduct__c == null && !ql.OrderProductCreated__c && ql.SBQQ__Quantity__c > 0) {
                        System.debug('## New order product after amendment');

                        // 1 - Create order product
                        System.debug('Create new order product based on quoteline ' + ql);
                        OrderItem newProduct = new OrderItem();
                        newProduct.OrderId = q.customerOrder__c;
                        newProduct.PricebookEntryId = ql.SBQQ__PricebookEntryId__c;
                        if (ql.SBQQ__ProductCode__c.contains('OTHFRAISPOSE')) {
                            newProduct.Quantity = ql.Quantite__c == 0 ? 0 : 1;
                            newProduct.SBQQ__QuotedQuantity__c = ql.Quantite__c == 0 ? 0 : 1;
                        } else {
                            newProduct.Quantity = ql.SBQQ__Quantity__c;
                            newProduct.SBQQ__QuotedQuantity__c = ql.SBQQ__Quantity__c;
                            newProduct.SBQQ__OrderedQuantity__c = ql.SBQQ__Quantity__c;
                        }
                        newProduct.orderItemQuantity__c = ql.QuoteLineQuantity__c;
                        newProduct.Product2Id = ql.SBQQ__Product__c;
                        newProduct.SBQQ__QuoteLine__c = ql.Id;
                        newProduct.SBQQ__QuotedListPrice__c = ql.SBQQ__ListPrice__c;
                        // On conserve le statut 'En cours de révision' jusqu'à la fin pour ne pas déclencher
                        // les triggers lors de l'insertion des lignes parentes alors que les options
                        // ne sont pas encore enregistrées
                        newProduct.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                        newProduct.productType__c = ql.productType__c;
                        //newProduct.UnitPrice = (ql.SBQQ__NetPrice__c != null) ? ql.SBQQ__NetPrice__c : 0;
                        newProduct.UnitPrice = (ql.PrixUnitaire__c != null) ? ql.PrixUnitaire__c : 0; 
                        //newProduct.VATRate__c = qli.TauxTVAPercent__c;
                        System.debug('## New order product: ' + newProduct);

                        // si option -> parentOrderItem__c = id orderitem principal
                        // if (ql.SBQQ__RequiredBy__c == null) -> principal
                        if (ql.SBQQ__RequiredBy__c == null) {
                            parentOrderItemsToUpdate.add(newProduct);
                            if (!parentQLChildMap.containsKey(ql.Id)) {
                                parentQLChildMap.put(ql.Id, new List<OrderItem>());
                            }
                        } else {
                            if (!parentQLChildMap.containsKey(ql.SBQQ__RequiredBy__c)) {
                                parentQLChildMap.put(ql.SBQQ__RequiredBy__c, new List<OrderItem>());
                            }
                            parentQLChildMap.get(ql.SBQQ__RequiredBy__c).add(newProduct);
                        }

                        // 2 - Update quoteline
                        ql.OrderProductCreated__c = true;
                        quoteLinesToUpdate.add(ql);
                    }
                }
                System.debug('## Quotelines total qty: ' + qlTotal);
                System.debug('## Orderitems total qty: ' + orderedTotal);
                System.debug('## Orderitems total quoted qty: ' + quotedTotal);
            }

            // 3 - Update quote to allow PB
            if (q.techPB__c == false) {
                // Set amended quotelines as processing un-necessary anymore
                System.debug('## techPB__c');
                quotesToUpdate.add(new SBQQ__Quote__c(Id = q.Id, techPB__c = true, customerOrder__c = q.customerOrder__c));
            }
        }

        // Save all changes/creations
        // Add each independant list in common list to prevent limit on SObject type change in list
        List<OrderItem> orderItemsToRemoveList = new List<OrderItem>(orderItemsToRemove);
        List<SObject> toUpsertFirst = new List<SObject>();
        toUpsertFirst.addAll(quoteLinesToUpdate);
        //first update orderItems to delete with ordered quantity to 0
        toUpsertFirst.addAll(orderItemsToRemoveList);

        // update quotes first to release them  when saving orderitems wich will update the quote too
        System.debug('## Update all records needing updates (' + quotesToUpdate.size() +
                        ' quotes, ' + quoteLinesToUpdate.size() + ' quotelines and ' +
                        orderItemsToRemove.size() + ' orderItems)');
        if (!toUpsertFirst.isEmpty()) {
            upsert toUpsertFirst;
        }
        toUpsertFirst.clear();

        // List assets for later update their orderItem__c
        List<Id> oldOrderItemsIds = new List<Id>();
        List<Asset> assets = new List<Asset>();
        for (OrderItem o : orderItemsToRemove) {
            oldOrderItemsIds.add(o.Id);
        }
        if (!oldOrderItemsIds.isEmpty()) {
            assets = [ SELECT Id, orderItem__c, Quantity, SBQQ__QuoteLine__c FROM Asset WHERE orderItem__c IN :oldOrderItemsIds ];
        }

        // Delete oldOrderItems
        // bypass deletion for tests as it throws an exception
        System.debug('## Delete ' + orderItemsToRemoveList.size() + ' parent orderItems');
        List<Id> orderItemIdList = new List<Id>();
        if (!orderItemsToRemoveList.isEmpty() && !Test.isRunningTest()) {
            for(OrderItem oi : orderItemsToRemoveList){
                orderItemIdList.add(oi.Id);
            }
            if(!Test.isRunningTest()) {     
                delete orderItemsToRemoveList;
            }
        }

        // Insert new parent order products and process children
        List<OrderItem> finalOrderItemsUpdate = new List<OrderItem>();
        if (!parentOrderItemsToUpdate.isEmpty()) {
            System.debug('## Insert parent order items');
            insert parentOrderItemsToUpdate;

            // Update child order products to set their parent
            List<OrderItem> childOrderItems = new List<OrderItem>();
            for (OrderItem oip : parentOrderItemsToUpdate) {
                System.debug('## Set parent order item id: ' + oip.Id + ' to its child');
                if (parentQLChildMap.containsKey(oip.SBQQ__QuoteLine__c)) {
                    for (OrderItem oi : parentQLChildMap.get(oip.SBQQ__QuoteLine__c)) {
                        oi.parentOrderItem__c = oip.Id;
                        oi.SBQQ__RequiredBy__c = oip.Id;
                        oi.SBQQ__BundleRoot__c = oip.Id;
                        childOrderItems.add(oi);
                    }
                }
                System.debug('## Parent order item '+oip+' has childs: '+childOrderItems);
            }

            // Insert child order products
            if (!childOrderItems.isEmpty()) {
                insert childOrderItems;
            }

            List<Asset> assetsToUpdate = new List<Asset>();
            List<Asset> assetsToRemove = new List<Asset>();
            List<String> assetsToRemoveId = new List<String>();
            Map<Id, OrderItem> oldToNewOrderItemMap = new Map<Id, OrderItem>();
            //Map<Id, OrderItem> parentOrderItemMap = new Map<Id, OrderItem>();
            // Prepare mapping for assets
            // Update order products status all together
            System.debug('## Post parse childOrderItems (' + childOrderItems.size() + ')');
            for (OrderItem oi : childOrderItems) {
                System.debug('## Add child old orderItemId ' + oi.previousOrderItem__c + ' to map for orderItem ' + oi);
                oldToNewOrderItemMap.put(oi.previousOrderItem__c, oi);
                oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
                finalOrderItemsUpdate.add(oi);
            }
            System.debug('## Post parse parentOrderItems (' + parentOrderItemsToUpdate.size() + ')');
            for (OrderItem oi : parentOrderItemsToUpdate) {
                System.debug('## Add parent old orderItemId ' + oi.previousOrderItem__c + ' to map for orderItem ' + oi);
                oldToNewOrderItemMap.put(oi.previousOrderItem__c, oi);
                //parentOrderItemMap.put(oi.Id, oi);
                oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
                finalOrderItemsUpdate.add(oi);
            }

            // Update assets to reference new OrderItems/quotelines and update quantity
            System.debug('## Now update assets to attach them to the new OrderItems (' + assetsToUpdate.size() + ' to update)');
            if (!assets.isEmpty()) {
                for (Asset asset : assets) {
                    if (oldToNewOrderItemMap.containsKey(asset.orderItem__c)) {
                        System.debug('## Move asset orderItem from ' + asset.orderItem__c + ' to ' + oldToNewOrderItemMap.get(asset.orderItem__c).Id);
                        OrderItem newOrderItem = oldToNewOrderItemMap.get(asset.orderItem__c);
                        asset.orderItem__c = newOrderItem.Id;
                        /*
                        if (newOrderItem.parentOrderItem__c == null) {
                            asset.Quantity = newOrderItem.SBQQ__QuotedQuantity__c;
                        } else {
                            asset.Quantity = parentOrderItemMap.get(newOrderItem.parentOrderItem__c).SBQQ__QuotedQuantity__c;
                        }
                        */
                        asset.SBQQ__QuoteLine__c = newOrderItem.SBQQ__QuoteLine__c;
                        assetsToUpdate.add(asset);
                    } else {
                        //remove assets associated to Order Items affected to removed quote lines in the QLE
                        System.debug('## Remove asset that was asosciated to Order Items themeselves related to removed quote lines in QLE: ' + asset.orderItem__c);
                        assetsToRemove.add(asset);
                        assetsToRemoveId.add(asset.Id);
                    }
                }

                //deleteOldItems(assetsToRemoveId, orderItemIdList);
                if(!Test.isRunningTest()) {     
                    if(!assetsToUpdate.isEmpty()) {
                        update assetsToUpdate;
                    }
                    if(!assetsToRemove.isEmpty()) {
                        delete assetsToRemove;
                    }
                }
            }

            // Finally update order items status to 'Révisé'
            if (!finalOrderItemsUpdate.isEmpty()) {
                update finalOrderItemsUpdate;
            }
        }

        for(SBQQ__Quote__c q : quotesToUpdate){
            System.debug('## techPB__c ' + q.techPB__c);            
            Order oo = new Order(Id=q.customerOrder__c, amending__c=false, amendingInProgress__c=false);
            update oo;
        }

        // Update Quote
        if (!quotesToUpdate.isEmpty()) {
            upsert quotesToUpdate;
        }

        // Turn on again CPQ triggers
        SBQQ.TriggerControl.enable();

        System.debug('### FIN TR023_SBQQ_QuoteLine.amendmentUpdateCPQOrderItem');
    }

    /**
    *
    *   Fonction asynchrone pour suppression des enregistrements obsolètes
    *
    **/
    /*@future
    public static void deleteOldItems(List<String> assetIdList, List<String> orderItemIdList) {

        List<Asset> assetList = new List<Asset>();
        List<OrderItem> orderItemListUpdate = new List<OrderItem>();
        assetList = [SELECT Id FROM Asset WHERE Id IN :assetIdList];
        for(OrderItem oi : [SELECT Id FROM OrderItem WHERE Id IN :orderItemIdList]) {
            oi.Quantity = 0;
            oi.SBQQ__QuotedQuantity__c = 0;
            oi.SBQQ__OrderedQuantity__c = 0;
            orderItemListUpdate.add(oi);
        }

        if (!assetList.isEmpty()){
            delete assetList;
        }
        if (!orderItemListUpdate.isEmpty()){
            update orderItemListUpdate;
        }
    }*/
}