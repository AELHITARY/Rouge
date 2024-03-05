//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR023_Order
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/01/2023
//-- Version     : 1.1
//-- * 1.1 - Update for amendment on standard quote
//-- * 1.0 - Created by Gregory Quinet on 13/10/2020
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR023_Order {

    /**
    * @description Création des lignes de devis CPQ pour des avenants
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void amendmentCreateCPQQuoteLines(UserContext userContext) {
        System.debug('### DEBUT TR023_Order : amendmentCreateCPQQuoteLines');

        //Pour chaque OrderItem avec conditions suivantes :
        // - Order.amendmentQuote != null
        // - Order.amending__c = true et a changé
        //     remplace - orderitem.statutDeRevision changé
        //     remplace - orderitem.statutDeRevision = "En cours de révision"
        // - orderitem.sbqq__QuoteLine != null
        // - orderitem.Quantity != 0

        Map<Id, Order> oldMap = (Map<Id, Order>)Trigger.oldMap;
        Map<Id, Order> newMap = (Map<Id, Order>)Trigger.newMap;
        Map<Id, List<OrderItem>> orderOrderItemsMap = new Map<Id, List<OrderItem>>();
        Map<Id, SBQQ__QuoteLine__c> quoteLinesMap = new Map<Id, SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> parentQuoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        Map<Id, List<SBQQ__QuoteLine__c>> parentOrderItemChildMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        //TO DELETE
        List<SBQQ__QuoteLine__c> quoteLinesToInsert = new List<SBQQ__QuoteLine__c>();
        List<Id> ordersIds = new List<Id>();

        for (Order order : newMap.values()) {
            // Si order #En cours de révision = true et a changé et qu'il y a bien un devis avenant associé,
            // on prends la commande en compte pour traitement
            Order oldOrder = oldMap == null ? null : oldMap.get(order.Id);
            System.debug('## oldOrder: '+oldOrder);
            System.debug('## oldOrder.amendmentQuote__c: '+oldOrder.amendmentQuote__c);
            System.debug('## order: '+order);
            System.debug('## order.amendmentQuote__c: '+ order.amendmentQuote__c);
            System.debug('## order.amending__c: '+ order.amending__c);
            System.debug('## ordersIds: '+ordersIds);
            if ( oldOrder.amendmentQuote__c != order.amendmentQuote__c
                    && order.amending__c
                    && order.amendmentQuote__c != null && !ordersIds.contains(order.Id) ) {
                ordersIds.add(order.Id);
            }
        }

        // On sort du process s'il n'y a pas d'order valide à traiter
        System.debug('## ordersIds: '+ordersIds);
        if (ordersIds.isEmpty()) return;

        // On charge toutes les quotelines associées aux order
        List<Id> quoteLinesIds = new List<Id>();
        for (OrderItem orderItem : [SELECT Id, OrderId, assetAmendableCount__c, locationPrecision__c, name__c,
                                        height__c, width__c, leaf__c, UnitPrice, PricebookEntryId, SBQQ__QuotedQuantity__c,
                                        Product2Id, SBQQ__QuoteLine__c, SBQQ__QuotedListPrice__c, SBQQ__RequiredBy__c, parentOrderItem__c
                                    FROM OrderItem WHERE OrderId IN :ordersIds AND Quantity != 0 AND SBQQ__QuoteLine__c != null]) 
        {
            if (!orderOrderItemsMap.containsKey(orderItem.OrderId)) {
                orderOrderItemsMap.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderOrderItemsMap.get(orderItem.OrderId).add(orderItem);
            quoteLinesIds.add(orderItem.SBQQ__QuoteLine__c);
        }
        System.debug('## quoteLinesIds: '+quoteLinesIds);
        System.debug('## orderOrderItemsMap: '+orderOrderItemsMap);

        // On cherche les quotelines de chaque order item originales
        if (!quoteLinesIds.isEmpty()) {
            for (SBQQ__QuoteLine__c ql : [
                    SELECT Id, CoefficientThermique__c, DateValiditeTarif__c, SBQQ__BundledQuantity__c,
                            ExcluBonusProjet__c, ExclusionPromo__c,
                            IdPromotionRetenue__c, IndexParent__c,
                            SBQQ__Quantity__c, PrixUnitaireHTManuel__c, KBMAXSB__Id__c, KBMax_ID_Static__c,
                            MethodePrixOption__c, NbTauxReduits__c, quoteLineLabelManual__c,
                            SBQQ__AdditionalDiscount__c, SBQQ__AdditionalQuantity__c, SBQQ__Bundle__c,
                            SBQQ__ComponentListTotal__c, SBQQ__SubscriptionScope__c, SBQQ__ComponentSubscriptionScope__c,
                            SBQQ__ComponentTotal__c, SBQQ__Discount__c, SBQQ__DistributorDiscount__c,
                            SBQQ__NonDiscountable__c, SBQQ__Number__c, SBQQ__OptionType__c, SBQQ__OriginalPrice__c,
                            SBQQ__PackageProductCode__c, SBQQ__PartnerDiscount__c, SBQQ__PartnerPrice__c,
                            SBQQ__PriceEditable__c, SBQQ__PricingMethod__c, SBQQ__ProductOption__c,
                            SBQQ__ProratedListPrice__c, SBQQ__ProratedPrice__c, SBQQ__RegularPrice__c,
                            SBQQ__SubscriptionBase__c, SBQQ__SubscriptionCategory__c, SBQQ__SubscriptionPercent__c,
                            SBQQ__AdditionalDiscountAmount__c, SBQQ__NetPrice__c, VATAmount__c,
                            VATAmountWithoutDiscount__c, enseignDiscountAmount__c,
                            SBQQ__CustomerPrice__c,
                            SBQQ__ListPrice__c, SBQQ__PricingMethodEditable__c, SBQQ__RequiredBy__c, SBQQ__Bundled__c,
                            SBQQ__OptionLevel__c, SBQQ__DynamicOptionId__c, SBQQ__Product__c, productType__c,
                            copieOptionPercent__c, amendInitialQuoteline__c, parentQuoteLine__c, location__c,
                            locationPrecision__c, TypeOptionsLibres__c, prixProduitParent__c, 
                            VATAmountHigh__c, VATAmountMedium__c, VATAmountLow__c, packageVATAmount__c, 
                            techTotalPromoParentEnfant__c, reconfigurable__c, comment__c
                    FROM SBQQ__QuoteLine__c
                    WHERE Id IN :quoteLinesIds]) {
                quoteLinesMap.put(ql.Id, ql);
            }
        }
        System.debug('## quoteLinesMap: '+quoteLinesMap);

        for (Id orderId : ordersIds) {
            // Ne pas traiter les commandes qui n'ont pas de concordance sur les critères
            if (!orderOrderItemsMap.containsKey(orderId)) {
                continue;
            }

            Order order = newMap.get(orderId);
            System.debug('## Order: '+order);
            for (OrderItem orderItem : orderOrderItemsMap.get(orderId)) {
                // Ne peut pas créer la quoteline si la quote originale n'est pas trouvée
                if (!quoteLinesMap.containsKey(orderItem.SBQQ__QuoteLine__c)) {
                    continue;
                }
                System.debug('## Create QuoteLine for OrderItem');
                SBQQ__QuoteLine__c oldQL = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c);
                System.debug('## OrderItem: '+orderItem.name__c+' / '+orderItem.Id);
                System.debug('## QuoteLine: '+oldQL.Id);

                // Clone the old record and create new one
                SBQQ__QuoteLine__c newQl = oldQL.clone(false, false, false, false);
                newQl.Id = null;
                newQl.SBQQ__Quote__c = order.amendmentQuote__c;
                newQl.AmendedOrderProduct__c = orderItem.Id;
                newQl.AssetAmendableCount__c = orderItem.assetAmendableCount__c;
                // Link to parent quoteline and initial quoteline to help RemVRP calculations
                newQl.parentQuoteLine__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).Id;
                if (String.isNotBlank(quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).amendInitialQuoteline__c)) {
                    newQl.amendInitialQuoteline__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).amendInitialQuoteline__c;
                } else {
                    newQl.amendInitialQuoteline__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).Id;
                }
                newQl.Hauteur__c = orderItem.height__c;
                newQl.Largeur__c = orderItem.width__c;
                newQl.NombreVantaux__c = orderItem.leaf__c;
                newQl.SBQQ__PricebookEntryId__c = orderItem.PricebookEntryId;
                /*
                newQl.SBQQ__PricebookEntryId__c = orderItem.PricebookEntryId;
                newQl.CoefficientThermique__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).CoefficientThermique__c;
                newQl.DateValiditeTarif__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).DateValiditeTarif__c;
                newQl.location__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).location__c;
                newQl.locationPrecision__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).locationPrecision__c;
                newQl.ExcluBonusProjet__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).ExcluBonusProjet__c;
                newQl.ExclusionPromo__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).ExclusionPromo__c;
                newQl.IdPromotionRetenue__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).IdPromotionRetenue__c;
                newQl.IndexParent__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).IndexParent__c;
                newQl.SBQQ__Quantity__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__Quantity__c;
                newQl.KBMAXSB__Id__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).KBMAXSB__Id__c;
                newQl.KBMax_ID_Static__c= quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).KBMax_ID_Static__c;
                newQl.MethodePrixOption__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).MethodePrixOption__c;
                newQl.NbTauxReduits__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).NbTauxReduits__c;
                newQl.quoteLineLabelManual__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).quoteLineLabelManual__c;
                newQl.PrixUnitaireHTManuel__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).PrixUnitaireHTManuel__c;
                newQl.TypeOptionsLibres__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).TypeOptionsLibres__c;
                newQl.SBQQ__Bundle__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__Bundle__c;
                newQl.SBQQ__ComponentListTotal__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__ComponentListTotal__c;
                newQl.SBQQ__ComponentSubscriptionScope__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__ComponentSubscriptionScope__c;
                newQl.SBQQ__ComponentTotal__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__ComponentTotal__c;
                newQl.SBQQ__NetPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__NetPrice__c;
                newQl.SBQQ__AdditionalDiscountAmount__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__AdditionalDiscountAmount__c;
                newQl.SBQQ__AdditionalQuantity__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__AdditionalQuantity__c;
                newQl.SBQQ__Discount__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__Discount__c;
                newQl.SBQQ__DistributorDiscount__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__DistributorDiscount__c;
                newQl.SBQQ__ListPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__ListPrice__c;
                newQl.SBQQ__CustomerPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__CustomerPrice__c;
                newQl.SBQQ__NonDiscountable__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__NonDiscountable__c;
                newQl.SBQQ__Number__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__Number__c;
                newQl.SBQQ__OptionType__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__OptionType__c;
                newQl.SBQQ__OriginalPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__OriginalPrice__c;
                newQl.SBQQ__PackageProductCode__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__PackageProductCode__c;
                newQl.SBQQ__PartnerPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__PartnerPrice__c;
                newQl.SBQQ__PriceEditable__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__PriceEditable__c;
                newQl.SBQQ__PricingMethodEditable__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__PricingMethodEditable__c;
                newQl.SBQQ__PricingMethod__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__PricingMethod__c;
                newQl.SBQQ__ProductOption__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__ProductOption__c;
                System.debug(' Copy to new quoteline, order product2Id is: ' + orderItem.Product2Id);
                System.debug('                        old quoteline product is: ' + quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__Product__c);
                newQl.SBQQ__Product__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__Product__c;                      //orderItem.Product2Id; product2Id null at this time now?
                newQl.SBQQ__ProratedListPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__ProratedListPrice__c;
                newQl.SBQQ__ProratedPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__ProratedPrice__c;
                newQl.SBQQ__Quantity__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__Quantity__c;
                newQl.SBQQ__RegularPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__RegularPrice__c;
                newQl.SBQQ__SubscriptionBase__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__SubscriptionBase__c;
                newQl.SBQQ__SubscriptionCategory__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__SubscriptionCategory__c;
                newQl.SBQQ__SubscriptionPercent__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__SubscriptionPercent__c;
                newQl.SBQQ__SubscriptionScope__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__SubscriptionScope__c;
                newQl.ValoPourcentPromoProduit__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).ValoPourcentPromoProduit__c;
                newQl.SBQQ__BundledQuantity__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__BundledQuantity__c;
                newQl.SBQQ__OptionLevel__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__OptionLevel__c;
                newQl.SBQQ__DynamicOptionId__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__DynamicOptionId__c;
                newQl.copieOptionPercent__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).copieOptionPercent__c;
                newQl.productType__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).productType__c;
                newQl.VATAmountHigh__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).VATAmountHigh__c;
                newQl.VATAmountMedium__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).VATAmountMedium__c;
                newQl.VATAmountLow__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).VATAmountLow__c;
                newQl.packageVATAmount__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).packageVATAmount__c;
                newQl.VATAmount__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).VATAmount__c;
                newQl.VATAmountWithoutDiscount__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).VATAmountWithoutDiscount__c;
                newQl.prixProduitParent__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).prixProduitParent__c;
                newQl.enseignDiscountAmount__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).enseignDiscountAmount__c;
                newQl.SBQQ__CustomerPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__CustomerPrice__c;
                newQl.techTotalPromoParentEnfant__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).techTotalPromoParentEnfant__c;
                newQl.reconfigurable__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).reconfigurable__c;
                newQl.SBQQ__CustomerPrice__c = quoteLinesMap.get(orderItem.SBQQ__QuoteLine__c).SBQQ__CustomerPrice__c;
                */
                
                if (orderItem.SBQQ__RequiredBy__c == null) {
                    System.debug('## Parent OrderItem: '+orderItem.Id);
                    parentQuoteLinesToUpdate.add(newQl);
                    if (!parentOrderItemChildMap.containsKey(newQl.AmendedOrderProduct__c)) {
                        parentOrderItemChildMap.put(newQl.AmendedOrderProduct__c, new List<SBQQ__QuoteLine__c>());
                    }
                } else {
                    System.debug('## Child OrderItem: '+orderItem.Id+' / '+orderItem.SBQQ__RequiredBy__c);
                    if (!parentOrderItemChildMap.containsKey(orderItem.parentOrderItem__c)) {
                        parentOrderItemChildMap.put(orderItem.parentOrderItem__c, new List<SBQQ__QuoteLine__c>());
                    }
                    parentOrderItemChildMap.get(orderItem.parentOrderItem__c).add(newQl);
                }
            }
        }

        // save all new quotelines
        // Insert new parent order products and process children
        if (!parentQuoteLinesToUpdate.isEmpty()) {
            System.debug('## Insert parent order items');
            insert parentQuoteLinesToUpdate;

            // Update child order products to set their parent
            List<SBQQ__QuoteLine__c> childQuoteLines = new List<SBQQ__QuoteLine__c>();
            for (SBQQ__QuoteLine__c oip : parentQuoteLinesToUpdate) {
                System.debug('## Set parent order item id: ' + oip.Id + ' to its child');
                if (parentOrderItemChildMap.containsKey(oip.AmendedOrderProduct__c)) {
                    for (SBQQ__QuoteLine__c ql : parentOrderItemChildMap.get(oip.AmendedOrderProduct__c)) {
                        ql.SBQQ__RequiredBy__c = oip.Id;
                        childQuoteLines.add(ql);
                    }
                }
                System.debug('## Parent order item '+oip+' has childs: ' + childQuoteLines);
            }

            // Insert child order products
            if (!childQuoteLines.isEmpty()) {
                insert childQuoteLines;
            }
        }

        System.debug('### FIN TR023_Order : amendmentCreateCPQQuoteLines');
    }

    /**
    * @description Méthode exécutée lorsque la commande intermédiaire de type Avenant est validée pour un devis CPQ
    * Modification des lignes de la commande principal associé au devis initial
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void amendmentUpdateCPQOrderItem(UserContext userContext){
        if (!Trigger.isExecuting) {
            return;
        }   
        
        System.debug('### DEBUT TR023_Order : amendmentUpdateCPQOrderItem');
        List<Order> ordersToProcess = new List<Order>();
        List<String> initialOrderIds = new List<String>();
        Map<String, String> newQuoteForOrders = new Map<String, String>();
        List<String> quotesIds = new List<String>();
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        String customerOrderRtId = DAL.getRecordTypeIdByDevName('Order', 'CustomerOrder');

        
        // Se déclenche uniquement à la validation de commandes client de type Avenant avec un devis CPQ associé
        for (Order ord : (List<Order>)Trigger.new) {
            Order oldOrder = (oldOrders == null) ? null : oldOrders.get(ord.id);
            
            if (ord.Type == Constants.ORDER_TYPE_AVENANT && ord.recordTypeId == customerOrderRtId && ord.isValid__c
                && oldOrder.isValid__c != ord.isValid__c
                && String.isNotBlank(ord.SBQQ__Quote__c)) 
            {
                ordersToProcess.add(ord);
                initialOrderIds.add(ord.parentOrder__c);
                newQuoteForOrders.put(ord.SBQQ__Quote__c,ord.parentOrder__c);
                quotesIds.add(ord.SBQQ__Quote__c);
            }
        }

        System.debug('## ordersToProcess :'+ordersToProcess);
        if (!ordersToProcess.isEmpty()) {
            
            // Sauvegarde en cas d'erreur
            System.Savepoint sp = Database.setSavepoint();

            try{

                // *************** Validation commande initiale ************************************
                // *********************************************************************************
                //#region validateparentorder                

                //Process validation initiale abandonné - à la place renvoie une erreur si on tente de valider l'avenant avant la commande initiale


                //récupération des infos des commandes initiales
                string intialOrdersQuery = 'SELECT Id, amendmentQuote__c, isValid__c FROM Order WHERE';
                if(!initialOrderIds.isEmpty()){
                    intialOrdersQuery += ' (';
                    for(Integer i =0; i<initialOrderIds.size()-1; i++){
                        intialOrdersQuery+=' Id = \''+initialOrderIds[i]+'\' OR';
                    }
                    intialOrdersQuery += ' Id = \''+initialOrderIds[initialOrderIds.size()-1]+'\')';
                }
                List<Order> initialOrders = Database.query(intialOrdersQuery);
                List<Order> invalidOrderstoProcess = new List<Order>();
                //List<Id> initialOrderIdsToValidate = new List<Id>();
                //List<Order> initialOrderToUpdateAfterValidation = new List<Order>();

                //Vérification si commande initiale nn validée
                for(Order initialOrder : initialOrders){
                    //Cas Commande initiale nn validée
                    if(!initialOrder.isValid__c){
                        //Erreur processus
                        //CalloutException ce = new CalloutException('Commande parent non validée.');
                        //throw ce;
                        Order amendingOrder = null;
                        for(Order o : ordersToProcess){
                            if(o.parentOrder__c == initialOrder.Id){
                                amendingOrder = o;
                            }
                        }
                        invalidOrderstoProcess.Add(amendingOrder);
                        
                        /*Order InitialOrderToUpdate = new order(id = initialOrder.Id);
                        //Validation de la commande via Process d'approbation
                        initialOrderIdsToValidate.Add(initialOrder.Id);
                        
                        //Maj de l'entité commerciale et de service à partir des infos de la commande avenant
                        Order amendingOrder = null;
                        for(Order o : ordersToProcess){
                            if(o.parentOrder__c == initialOrder.Id){
                                amendingOrder = o;
                            }
                        }
                        System.debug('## amendingOrder:'+amendingOrder);
                        System.debug('## orderToProcess salesEntity:'+amendingOrder.salesEntity__c);
                        System.debug('## orderToProcess serviceEntity__c:'+amendingOrder.serviceEntity__c);
                        InitialOrderToUpdate.salesEntity__c = amendingOrder.salesEntity__c;
                        InitialOrderToUpdate.serviceEntity__c = amendingOrder.serviceEntity__c;
                        initialOrderToUpdateAfterValidation.Add(InitialOrderToUpdate);*/
                    }
                }

                // Cas présence de commande parent non validée - Validation des commandes parent
                /*if(!initialOrderIdsToValidate.isEmpty()){                    

                    //Récupération des Demandes d'approbations
                    string workitemRequestQuery = 'SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE';
                    workitemRequestQuery += ' (';
                    for(Integer i =0; i<initialOrderIdsToValidate.size()-1; i++){
                        workitemRequestQuery+=' ProcessInstance.TargetObjectId = \''+initialOrderIdsToValidate[i]+'\' OR';
                    }
                    workitemRequestQuery += ' ProcessInstance.TargetObjectId = \''+initialOrderIdsToValidate[initialOrderIdsToValidate.size()-1]+'\')';
                    
                    List<ProcessInstanceWorkitem> processInstanceWorkItemList = Database.query(workitemRequestQuery);
                    List<Approval.ProcessWorkitemRequest> pwrList = new List<Approval.ProcessWorkitemRequest>();
                    if(!processInstanceWorkItemList.isEmpty()){
                        for(ProcessInstanceWorkitem piwi : processInstanceWorkItemList){
                            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
                            pwr.setAction('Approve');
                            pwr.setWorkItemId(piwi.Id);
                            pwr.setComments(Label.order_msg_orderValidatedByAmendment);
                            pwrList.Add(pwr);
                        }
                    }
                    
                    // Approbation
                    if(!pwrList.isEmpty()){
                        List<Approval.ProcessResult> resultList = Approval.process(pwrList);
                        for(Approval.ProcessResult result : resultList){
                            if (!result.isSuccess()) {
                                CalloutException ce = new CalloutException('Erreur à la validation de commande parent');
                                throw ce;         
                            }
                        }
                    }

                    update initialOrderToUpdateAfterValidation;
                }*/
                //#endregion

                //Erreur et fin de processus si il existe des commandes initiales non validées
                if(!invalidOrderstoProcess.isEmpty()){
                    for(Order o : invalidOrderstoProcess){
                        o.addError('La commande parent n\'a pas été approuvée, impossible de procéder au déversement de l\'avenant');
                        System.debug('## initial order not approved end of process');
                    }
                }
                else {
                  
                    // *************** Récupération des données pour le déversement ********************
                    // *********************************************************************************
                    //#region dataquerying

                    //récupération des infos avenant (devis CPQ, Lignes de devis, orderItem)
                    List<SBQQ__Quote__c> cpqQuoteList = new List<SBQQ__Quote__c>();
                    //Infos devis
                    string amendementQuery = 'SELECT id, customerOrder__c, SBQQ__BillingCity__c, SBQQ__BillingCountry__c, SBQQ__BillingPostalCode__c, SBQQ__BillingState__c,'
                    +' SBQQ__BillingStreet__c, SBQQ__ShippingCity__c, SBQQ__ShippingCountry__c, SBQQ__ShippingPostalCode__c, SBQQ__ShippingState__c, SBQQ__ShippingStreet__c,'
                    +' VATAmountDisplay__c,RemiseComplementaireDeviseDisplay__c, MontantAcompteAttendu__c, MontantAcompte2Attendu__c, PctAcompteAttendu__c, PctAcompte2Attendu__c,'
                    +' totalAmount__c, billingAdditionalAddress__c, SBQQ__BillingName__c, comment__c,enseignDiscountAmount__c, financingMethod__c,maxCommercialDelay__c,'
                    +' minCommercialDelay__c,SBQQ__ListAmount__c,pretaxTotalAmount__c, shippingAdditionalAddress__c, SBQQ__ShippingName__c, sourceRef__c, specialTerms__c, termsAndConditions__c,';
                    //Infos ligne de devis
                    amendementQuery += ' (SELECT Id, SBQQ__Quote__c, AmendedOrderProduct__c, SBQQ__Quantity__c, SBQQ__Product__c, SBQQ__PricebookEntryId__c, Quantite__c, AmendedQLValidated__c,'
                    +' SBQQ__Bundle__c, PrixNetRemiseTTC__c, SBQQ__NetPrice__c, SBQQ__ProductCode__c, TauxTVAPercent__c, SBQQ__OriginalPrice__c, SBQQ__ListPrice__c, NombreVantaux__c, Largeur__c,'
                    +' Hauteur__c, ProductType__c, QuoteLineQuantity__c, OrderProductCreated__c, SBQQ__ProductName__c, SBQQ__RequiredBy__c, purchasePrice__c, SBQQ__PackageTotal__c, unit__c,'
                    +' PrixUnitaire__c,';
                    //infos OrderItem
                    amendementQuery += ' AmendedOrderProduct__r.Id, AmendedOrderProduct__r.AmendmentQuoteLine__c, AmendedOrderProduct__r.Quantity, AmendedOrderProduct__r.SBQQ__OrderedQuantity__c,'
                    +' AmendedOrderProduct__r.SBQQ__QuoteLine__c, AmendedOrderProduct__r.SBQQ__QuotedListPrice__c, AmendedOrderProduct__r.SBQQ__QuotedQuantity__c,'
                    +' AmendedOrderProduct__r.StatutDeRevision__c, AmendedOrderProduct__r.UnitPrice, AmendedOrderProduct__r.VATAmount__c, AmendedOrderProduct__r.VATRate__c,'
                    +' AmendedOrderProduct__r.productType__c, AmendedOrderProduct__r.OrderId, AmendedOrderProduct__r.PricebookEntryId, AmendedOrderProduct__r.ListPrice,'
                    +' AmendedOrderProduct__r.Product2Id, AmendedOrderProduct__r.assetCount__c, AmendedOrderProduct__r.assetAmendableCount__c, AmendedOrderProduct__r.height__c,'
                    +' AmendedOrderProduct__r.leaf__c, AmendedOrderProduct__r.locationPrecision__c, AmendedOrderProduct__r.name__c, AmendedOrderProduct__r.unit__c,'
                    +' AmendedOrderProduct__r.reference__c, AmendedOrderProduct__r.width__c, AmendedOrderProduct__r.parentOrderItem__c, AmendedOrderProduct__r.asset__c,'
                    +' AmendedOrderProduct__r.purchasePrice__c';
                    amendementQuery += ' FROM SBQQ__LineItems__r)';
                    amendementQuery += ' FROM SBQQ__Quote__c WHERE';
                    if(!quotesIds.isEmpty()){
                        amendementQuery += ' (';
                        for(Integer i =0; i<quotesIds.size()-1; i++){
                            amendementQuery+=' Id = \''+quotesIds[i]+'\' OR';
                        }
                        amendementQuery += ' Id = \''+quotesIds[quotesIds.size()-1]+'\')';
                    }
                    cpqQuoteList = Database.query(amendementQuery);

                    //#endregion

                    // *************** Création des listes de mises à jour et Mapping des données ********************
                    // ***********************************************************************************************
                    //#region datamapping

                    List<OrderItem> parentOrderItemsToUpdate = new List<OrderItem>();
                    Map<Id, List<OrderItem>> parentQLChildMap = new Map<Id, List<OrderItem>>();
                    List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
                    List<OrderItem> oldOrderItemToUpdateList = new List<OrderItem>();
                    Map<String,OrderItem> oldOrderItemToUpdateMap = new Map<String,OrderItem>();
                    Set<Id> oldOrderItemToUpdateSet = new Set<Id>();
                    List<Order> initialOrderToUpdate = new List<Order>();
                    List<Asset> assetsToUpdate = new List<Asset>();
                    Set<Id> oldOrderItemsIds = new Set<Id>();
                    
                    if(!cpqQuoteList.isEmpty()){
                        System.debug('## CPQ Quote infos get');
                
                        //Pour chaque devis à deverser
                        for (SBQQ__Quote__c q : cpqQuoteList) {
                            System.debug('## Processing SBQQ_Quote :'+q.Id);
                            System.debug('## customerOrder on q :'+q.customerOrder__c);

                            //Maj commande
                            if(newQuoteForOrders.ContainsKey(q.Id)){
                                Order orderToUpdate = new Order(Id = newQuoteForOrders.get(q.Id));
                                Order initialOrder = null;                         
                                //Mapping entre commande et devis

                                if(orderToUpdate.Id != null){       
                                    //Vérification que le champ dernier avenant de la commande parent correspond bien au devis CPQ traité
                                    for(Order o : initialOrders){
                                        if(orderToUpdate.Id == o.Id){
                                            initialOrder = o;
                                        }
                                    }
                                    if(initialOrder.amendmentQuote__c != q.Id){
                                        //Si Devis ne correspond pas le déversement s'arrête
                                        System.debug('## amendingQuote is not the most recent abort process for quote:'+q.Id);
                                        continue;
                                    }

                                    //Indicateur de lancement du processus
                                    orderToUpdate.amendingInProgress__c = true;

                                    //champs mappés depuis le devis
                                    orderToUpdate.BillingCity = q.SBQQ__BillingCity__c;
                                    orderToUpdate.BillingCountry = q.SBQQ__BillingCountry__c;
                                    orderToUpdate.BillingPostalCode = q.SBQQ__BillingPostalCode__c;
                                    orderToUpdate.BillingState = q.SBQQ__BillingState__c;
                                    orderToUpdate.BillingStreet = q.SBQQ__BillingStreet__c;
                                    orderToUpdate.SBQQ__Quote__c = q.Id;
                                    orderToUpdate.ShippingCity = q.SBQQ__ShippingCity__c;
                                    orderToUpdate.ShippingCountry = q.SBQQ__ShippingCountry__c;
                                    orderToUpdate.ShippingState = q.SBQQ__ShippingState__c;
                                    orderToUpdate.ShippingStreet = q.SBQQ__ShippingStreet__c;
                                    orderToUpdate.VATAmount__c = q.VATAmountDisplay__c != null ? q.VATAmountDisplay__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.additionalDiscount__c = q.RemiseComplementaireDeviseDisplay__c != null ? q.RemiseComplementaireDeviseDisplay__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.advancePaymentAmount1__c = q.MontantAcompteAttendu__c !=null ? q.MontantAcompteAttendu__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.advancePaymentAmount2__c = q.MontantAcompte2Attendu__c !=null ? q.MontantAcompte2Attendu__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.advancePaymentPercent1__c = q.PctAcompteAttendu__c;
                                    orderToUpdate.advancePaymentPercent2__c = q.PctAcompte2Attendu__c;
                                    orderToUpdate.amount__c = q.totalAmount__c !=null ? q.totalAmount__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.billingAdditionalAddress__c = q.billingAdditionalAddress__c;
                                    orderToUpdate.billingName__c = q.SBQQ__BillingName__c;
                                    orderToUpdate.comment__c = q.comment__c;
                                    orderToUpdate.dateDernierAvenant__c = Date.Today();
                                    orderToUpdate.ensignDiscount__c =  q.enseignDiscountAmount__c !=null ? q.enseignDiscountAmount__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.financingMethod__c = q.financingMethod__c;
                                    orderToUpdate.maxCommercialDelay__c = q.maxCommercialDelay__c;
                                    orderToUpdate.minCommercialDelay__c = q.minCommercialDelay__c;
                                    orderToUpdate.pretaxAmountWithoutDiscount__c = q.SBQQ__ListAmount__c !=null ? q.SBQQ__ListAmount__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.pretaxAmount__c = q.pretaxTotalAmount__c !=null ? q.pretaxTotalAmount__c.setscale(2, RoundingMode.HALF_UP) : null;
                                    orderToUpdate.shippingAdditionalAddress__c = q.shippingAdditionalAddress__c;
                                    orderToUpdate.shippingName__c = q.SBQQ__ShippingName__c;
                                    orderToUpdate.source__c = q.sourceRef__c;
                                    orderToUpdate.specialTerms__c = q.specialTerms__c;
                                    orderToUpdate.termsAndConditions__c = q.termsAndConditions__c;

                                    initialOrderToUpdate.add(orderToUpdate);
                                    System.debug('## Order '+orderToUpdate.Id + ' mapped');
                                    //System.debug('## order to update: '+JSON.serializePretty(orderToUpdate));
                                }
                            }

                            //Maj ligne de commande
                            //Pour chaque ligne de devis associées au devis avenant
                            for(SBQQ__QuoteLine__c ql : q.SBQQ__LineItems__r){
                                System.debug('## Processing SBQQ__QuoteLine__c:'+ql.Id);
                                Boolean addToList = false;
                                OrderItem newOrderProduct = new OrderItem();

                                //Mapping entre ligne de commande et devis/ligne de devis
                                newOrderProduct.OrderId = q.customerOrder__c;
                                System.debug('## newOrderProduct.OrderId:'+newOrderProduct.OrderId);
                                newOrderProduct.PricebookEntryId = ql.SBQQ__PricebookEntryId__c;
                                if (ql.SBQQ__ProductCode__c.contains('OTHFRAISPOSE')) {
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
                                newOrderProduct.UnitPrice = (ql.PrixUnitaire__c != null) ? ql.PrixUnitaire__c : 0;
                                // On conserve le statut 'En cours de révision' jusqu'à la fin pour ne pas déclencher
                                // les triggers lors de l'insertion des lignes parentes alors que les options
                                // ne sont pas encore enregistrées
                                newOrderProduct.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                                    
                                /*System.debug('## ql.AmendedOrderProduct__r.Id :'+ql.AmendedOrderProduct__r.Id);
                                System.debug('## ql.AmendedOrderProduct__r.StatutDeRevision__c :'+ql.AmendedOrderProduct__r.StatutDeRevision__c);
                                System.debug('## ql.AmendedOrderProduct__r.SBQQ__QuoteLine__c :'+ql.AmendedOrderProduct__r.SBQQ__QuoteLine__c);*/
                                //Cas update de ligne de commande existante sur la commande initiale
                                if(ql.AmendedOrderProduct__r.Id !=null && ql.AmendedOrderProduct__r.StatutDeRevision__c == Constants.ORDERITEM_STATUTREVISION_UPDATING
                                    && ql.AmendedOrderProduct__r.SBQQ__QuoteLine__c != null){
                                    System.debug('## existing amendedOrderItem found:'+ql.AmendedOrderProduct__r.Id); 

                                    //Mapping des infos de la ligne précedente avant mise à jour
                                    newOrderProduct.previousOrderItem__c = ql.AmendedOrderProduct__r.Id;
                                    newOrderProduct.assetCount__c = ql.AmendedOrderProduct__r.assetCount__c;
                                    newOrderProduct.assetAmendableCount__c = ql.AmendedOrderProduct__r.assetAmendableCount__c;
                                    // Si ligne parent et Quantité = 0 alors on annule la ligne en mettant date d'annulation
                                    if(ql.SBQQ__RequiredBy__c == null && ql.SBQQ__Quantity__c == 0) {
                                        newOrderProduct.cancellationDate__c = Date.today();
                                    }
                                    
                                    //Mise à jour de l'ancienne ligne avant supression pour vider les infos de lignes de devis et quantité
                                    OrderItem oldOrderItemToUpdate = new OrderItem(Id = ql.AmendedOrderProduct__r.Id);
                                    oldOrderItemToUpdate.SBQQ__QuoteLine__c = null;
                                    if (ql.AmendedOrderProduct__r.parentOrderItem__c == null) {
                                        oldOrderItemToUpdate.SBQQ__OrderedQuantity__c = 0;
                                    }   
                                    oldOrderItemToUpdateSet.add(oldOrderItemToUpdate.Id);   
                                    oldOrderItemToUpdateMap.put(oldOrderItemToUpdate.Id, oldOrderItemToUpdate);                         

                                    addToList = true;
                                }
                                //Cas création d'une nouvelle ligne de commande
                                else if(ql.AmendedOrderProduct__c == null && !ql.OrderProductCreated__c && ql.SBQQ__Quantity__c > 0){
                                    System.debug('## new orderitem after amendment');

                                    //Mise à jour de la ligne de devis pour indiquer que le produit a été créé 
                                    ql.OrderProductCreated__c = true;
                                    quoteLinesToUpdate.add(ql);

                                    addToList = true;
                                }
                                //Ajout dans la liste des lignes à créer/update
                                if(addToList){
                                    //une liste pour les parents
                                    //une map pour les enfants

                                    //cas parent
                                    if (ql.SBQQ__RequiredBy__c == null) {                                    
                                        parentOrderItemsToUpdate.add(newOrderProduct);
                                        
                                        if (!parentQLChildMap.containsKey(ql.Id)) {
                                            parentQLChildMap.put(ql.Id, new List<OrderItem>());
                                        }
                                    }
                                    //Cas enfant (option) 
                                    else {
                                        if (!parentQLChildMap.containsKey(ql.SBQQ__RequiredBy__c)) {
                                            parentQLChildMap.put(ql.SBQQ__RequiredBy__c, new List<OrderItem>());
                                        }
                                        parentQLChildMap.get(ql.SBQQ__RequiredBy__c).add(newOrderProduct);
                                    }
                                }
                                System.debug('## Processing SBQQ__QuoteLine__c:'+ql.Id + ' finished');
                            }
                            System.debug('## Processing SBQQ__Quote:'+q.Id + ' finished');
                        }
                    }
                    
                    // Add Set OrderItem to the List OrderItem to remove duplicates
                    for(String oiId : oldOrderItemToUpdateSet){
                        oldOrderItemToUpdateList.add(oldOrderItemToUpdateMap.get(oiId));
                    } 

                    System.debug('## Number of initialOrder to update :'+initialOrderToUpdate.size());
                    System.debug('## Number of quoteLines to update (new lines) :'+quoteLinesToUpdate.size());
                    System.debug('## Number of parent orderItem to update :'+parentOrderItemsToUpdate.size());
                    System.debug('## Total number of orderItem to update :'+oldOrderItemToUpdateList.size());
                    //System.debug('## Number of Asset to update :'+assetsToUpdate.size());
                    
                    /*System.debug('## parent orderItem to update: '+JSON.serializePretty(parentOrderItemsToUpdate));
                    System.debug('## Child Map extract: '+JSON.serializePretty(parentQLChildMap));
                    System.debug('## Quote lines to update: '+JSON.serializePretty(quoteLinesToUpdate));
                    System.debug('## Old orderItem to update: '+JSON.serializePretty(oldOrderItemToUpdateList));
                    System.debug('## Asset to update: '+JSON.serializePretty(assetsToUpdate));*/

                    //#endregion

                    // *************** Début des transactions ********************
                    // ***********************************************************
                    //#region transactionstart
                    List<SObject> finalUpdate = new List<SObject>();
                    List<SObject> toUpsertFirst = new List<SObject>();
                    List<OrderItem> childOrderItems = new List<OrderItem>();
                    Map<Id, OrderItem> oldToNewOrderItemMap = new Map<Id, OrderItem>();


                    

                    //Désactive Trigger interne CPQ pour éviter des erreurs
                    SBQQ.TriggerControl.disable();

                    // 1 - Upsert intial : Mise à jour des lignes de devis, ancien orderItem et commande parent

                    //Maj indicateur produit crée pour les nouvelles lignes
                    if(!quoteLinesToUpdate.isEmpty()){
                        toUpsertFirst.addAll(quoteLinesToUpdate);
                    }
                    //Maj anciens orderItem pour vider les infos de lignes de devis et quantité
                    if(!oldOrderItemToUpdateList.isEmpty()){
                        toUpsertFirst.addAll(oldOrderItemToUpdateList);
                    }
                    //Maj infos administratives et financieres sur commande parent et indicateur de processus avenant en cours
                    if(!initialOrderToUpdate.isEmpty()){
                        toUpsertFirst.addAll(initialOrderToUpdate);
                    }
                    
                    if(!toUpsertFirst.isEmpty()) {
                        System.debug('## upsert toUpsertFirst : '+toUpsertFirst);
                        //System.debug('## toUpsertFirst: '+JSON.serializePretty(toUpsertFirst));
                        upsert toUpsertFirst;
                    }

                    //Récupération des actifs existants à partir de la liste des anciennes lignes de commande à mettre à jour avant suppression
                    if(!oldOrderItemToUpdateList.isEmpty()){
                        for (OrderItem o : oldOrderItemToUpdateList) {
                            oldOrderItemsIds.add(o.Id);
                        }
                        assetsToUpdate = [ SELECT Id, orderItem__c, Quantity, SBQQ__QuoteLine__c FROM Asset WHERE orderItem__c IN :oldOrderItemsIds ];
                    }

                    System.debug('## assetsToUpdate: '+JSON.serializePretty(assetsToUpdate));
            
                    // 2 - Supression de tous les orderItem existant
                    if(!oldOrderItemToUpdateList.isEmpty() && !Test.isRunningTest()) {
                        System.debug('## delete oldOrderItemToUpdateList');
                        //System.debug('## oldOrderItemToUpdateList: '+JSON.serializePretty(oldOrderItemToUpdateList));
                        delete oldOrderItemToUpdateList;
                    }

                    if(!parentOrderItemsToUpdate.isEmpty()) {
                        // 3 - Insert des OrderItem parent (existant mis a jour ou nouveau)
                        System.debug('## insert parentOrderItemsToUpdate');
                        //System.debug('## parentOrderItemsToUpdate: '+JSON.serializePretty(parentOrderItemsToUpdate));
                        insert parentOrderItemsToUpdate;
                        
                        for (OrderItem oip : parentOrderItemsToUpdate) {            
                            
                            //Map entre les nouveaux et anciens order Item parent (utilisé pour la réattribution des asset)
                            oldToNewOrderItemMap.put(oip.previousOrderItem__c, oip);
                            //Maj statut pour l'update final 
                            oip.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
                            finalUpdate.add(oip);

                            //Association des OrderItem enfants aux parents nouvellement crées
                            if (parentQLChildMap.containsKey(oip.SBQQ__QuoteLine__c)) {
                                for (OrderItem oi : parentQLChildMap.get(oip.SBQQ__QuoteLine__c)) {
                                    oi.parentOrderItem__c = oip.Id;
                                    oi.SBQQ__RequiredBy__c = oip.Id;
                                    oi.SBQQ__BundleRoot__c = oip.Id;                                
                                    childOrderItems.add(oi);
                                }
                            }
                        }

                        // 4 - Insert des Orderitem enfant
                        if (!childOrderItems.isEmpty()) {
                            System.debug('## insert childOrderItems');
                            //System.debug('## childOrderItems: '+JSON.serializePretty(childOrderItems));
                            insert childOrderItems;
                        
                            for (OrderItem oi : childOrderItems) {
                                //Map entre les nouveaux et anciens order Item enfant (utilisé pour la réattribution des asset)
                                oldToNewOrderItemMap.put(oi.previousOrderItem__c, oi);
                                //Maj statut pour l'update final
                                oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
                                finalUpdate.add(oi);
                            }
                        }

                        if(!oldToNewOrderItemMap.isEmpty() && !assetsToUpdate.isEmpty()){
                            //Mapping des asset
                            for(Asset asset : assetsToUpdate){
                                if (oldToNewOrderItemMap.containsKey(asset.orderItem__c)) {
                                    //Réattribution des asset existant au nouvel OrderItem
                                    OrderItem newOrderItem = oldToNewOrderItemMap.get(asset.orderItem__c);
                                    asset.orderItem__c = newOrderItem.Id;
                                    asset.SBQQ__QuoteLine__c = newOrderItem.SBQQ__QuoteLine__c;
                                }
                            }

                            // 5 - Update des Asset
                            System.debug('## update assetsToUpdate');
                            //System.debug('## assetsToUpdate: '+JSON.serializePretty(assetsToUpdate));
                            update assetsToUpdate;
                        }
                        
                        //Update des commandes initiales en fin de process pour maj les indicateurs de Porcessus avenant 
                        if(!initialOrderToUpdate.isEmpty()){
                            for(Order o : initialOrderToUpdate){
                                Order updatedOrder = new Order(Id=o.Id, amending__c=false, amendingInProgress__c=false);
                                finalUpdate.Add(updatedOrder);
                            }
                        }

                        // 6 - Update Final des OrderItem pour passer en statut 'Révisé' et commandes pour retirer le champ bypass
                        if(!finalUpdate.isEmpty()){
                            System.debug('## update finalUpdate');
                            //System.debug('## finalUpdate: '+JSON.serializePretty(finalUpdate));
                            update finalUpdate;
                        }
                    }

                    SBQQ.TriggerControl.enable();
                    //#endregion
                }             
            }
            catch (Exception e) {
                System.debug('ERREUR # TR023_Order.amendmentUpdateCPQOrderItem (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
                throw e;        
            }
        }
        System.debug('### FIN TR023_Order : amendmentUpdateCPQOrderItem');
    }


    /**
    * @description Méthode exécutée lorsque la commande intermédiaire de type Avenant est validée pour un devis Sales (standard) Kube2
    * Modification des lignes de la commande principal associé au devis initial
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void amendmentSalesQuoteValidated(UserContext userContext) {
        System.debug('### DEBUT TR023_Order : amendmentSalesQuoteValidated');
        List<Order> ordersToProcess = new List<Order>();
        List<String> initialOrderIds = new List<String>();
        Map<String, String> newQuoteForOrders = new Map<String, String>();
        List<String> quotesIds = new List<String>();
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;

        // Filtre pour récupérer que les commandes de type Avenant validée
        for (Order ord : (List<Order>)Trigger.new) {
            Order oldOrder = (oldOrders == null) ? null : oldOrders.get(ord.id);
            if (ord.Type == Constants.ORDER_TYPE_AVENANT && ord.isValid__c 
                && oldOrder.isValid__c != ord.isValid__c
                && String.isNotBlank(ord.QuoteId)) 
            {
                ordersToProcess.add(ord);
                initialOrderIds.add(ord.parentOrder__c);
                newQuoteForOrders.put(ord.parentOrder__c, ord.QuoteId);
                quotesIds.add(ord.QuoteId);
            }
        }

        if (!ordersToProcess.isEmpty()) {
            Set<Id> orderItemsIds = new Set<Id>();
            Set<Id> quoteLineItemsIds = new Set<Id>();
            Set<String> optProductCodeList = new Set<String>();
            List<OrderItem> orderItemsToRemove = new List<OrderItem>();
            List<OrderItem> orderItemsToCancel = new List<OrderItem>();
            Map<Id, List<QuoteLineItem>> quoteQuotelinesMap = new Map<Id, List<QuoteLineItem>>();
            Map<Id, List<Option__c>> quoteOptionsMap = new Map<Id, List<Option__c>>();
            List<Order> ordersInitToUpdate = new List<Order>();

            // Sauvegarde en cas d'erreur
            System.Savepoint sp = Database.setSavepoint();
            
            try {                
                System.debug('## Processus pour les commandes: ' + ordersToProcess);
                
                // Récupération des lignes pour chaque devis
                for (QuoteLineItem qli : [SELECT Id, QuoteId, amendedOrderProduct__c, Quantity, ListPrice, TVApourcentage__c, Prix_TVA__c, Discount,
                                            Product2Id, PricebookEntryId, productName__c, productCode__c, Subtotal, TotalTTCligneRemise__c, remiseUnitaire__c,
                                            prixHTTarifRemise__c, Nombredevantaux__c, Hauteur__c, Largeur__c, UnitPrice, prix_TVA_Ligne__c, Remise_Enseigne_HT__c,
                                            productUnit__c, PrixTTCtarif__c, Emplacement__c, PrixunitaireHTtarif__c, productType__c, thermalCoefficients__c
                                            FROM QuoteLineItem WHERE QuoteId IN :quotesIds AND cancelledLine__c = false]) 
                {
                    if (!quoteQuotelinesMap.containsKey(qli.QuoteId)) {
                        quoteQuotelinesMap.put(qli.QuoteId, new List<QuoteLineItem>());
                    }
                    quoteQuotelinesMap.get(qli.QuoteId).add(qli);
                    quoteLineItemsIds.add(qli.Id);    
                    if(String.isNotBlank(qli.amendedOrderProduct__c)) {
                        orderItemsIds.add(qli.amendedOrderProduct__c);
                    }        
                }
                System.debug('## QuoteLineItems: ' + quoteQuotelinesMap);

                // Récupération des options pour chaque lignes de devis
                for (Option__c opt : [SELECT Id, ligneDevis__c, ligneDevis__r.QuoteId, amendedOrderProduct__c, PrixHT__c, PrixunitaireHT__c, Quantite__c,
                                            ligneDevis__r.ListPrice, ligneDevis__r.TVApourcentage__c, ligneDevis__r.Prix_TVA__c, ligneDevis__r.Discount,
                                            ligneDevis__r.Product2Id, ligneDevis__r.PricebookEntryId, ligneDevis__r.productName__c, ligneDevis__r.productType__c,
                                            ligneDevis__r.productCode__c, ligneDevis__r.Subtotal, ligneDevis__r.Nombredevantaux__c, ligneDevis__r.Hauteur__c, 
                                            ligneDevis__r.Largeur__c, ligneDevis__r.UnitPrice, ligneDevis__r.Remise_Enseigne_HT__c, ligneDevis__r.remiseUnitaire__c, 
                                            Libelleoption__c, Codeoption__c, ligneDevis__r.productUnit__c, ligneDevis__r.Emplacement__c, ligneDevis__r.Quantity
                                            FROM Option__c WHERE ligneDevis__c IN :quoteLineItemsIds]) 
                {
                    if (!quoteOptionsMap.containsKey(opt.ligneDevis__r.QuoteId)) {
                        quoteOptionsMap.put(opt.ligneDevis__r.QuoteId, new List<Option__c>());
                    }
                    quoteOptionsMap.get(opt.ligneDevis__r.QuoteId).add(opt);
                    optProductCodeList.add(opt.Codeoption__c);
                    if(String.isNotBlank(opt.amendedOrderProduct__c)) {
                        orderItemsIds.add(opt.amendedOrderProduct__c);
                    }
                }
                System.debug('## quoteOptionsMap: ' + quoteOptionsMap);
                System.debug('## orderItemsIds: ' + orderItemsIds.size());

                // Get all Order Items associated to quotes, and select those without associated Quote Lines
                // (Quote Lines removed in the QLE) to remove them
                for(OrderItem oi : [SELECT Id, name__c FROM OrderItem WHERE OrderId IN :initialOrderIds]) {
                    if (!orderItemsIds.contains(oi.Id)) {
                        System.debug('## OrderItems a annuler: '+oi.Id+' - '+ oi.name__c);
                        orderItemsToCancel.add(oi);
                    }
                }
                System.debug('## OrderItems a annuler: ' + orderItemsToCancel.size());

                // Get order products of each quoteline
                Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
                if (!initialOrderIds.isEmpty()) {
                    for (OrderItem it : [SELECT Id, Quantity, QuoteLineItemId, QuoteLineItem.AmendedOrderProduct__c,
                            StatutDeRevision__c, UnitPrice, VATAmount__c, VATRate__c, amount__c, productType__c, OrderId,
                            PricebookEntryId, ListPrice, Product2Id, assetCount__c, assetAmendableCount__c,
                            height__c, leaf__c, locationPrecision__c, name__c, unit__c, quoteOption__c,
                            reference__c, width__c, parentOrderItem__c, asset__c, purchasePrice__c
                            FROM OrderItem WHERE Id IN :orderItemsIds]) 
                    {                    
                        orderItemMap.put(it.Id, it);
                    }
                }

                // Get Product2 for each option
                Map<String, PricebookEntry> productPBEMap = new Map<String, PricebookEntry>();
                if (!optProductCodeList.isEmpty()) {
                    for (PricebookEntry pbe : [SELECT Id, Product2Id, ProductCode
                                                FROM PricebookEntry WHERE ProductCode IN :optProductCodeList]) 
                    {
                        productPBEMap.put(pbe.ProductCode, pbe);
                    }
                }

                // List for all objects to update and add at the end
                Set<OrderItem> parentOrderItemsToUpdate = new Set<OrderItem>();
                Set<Id> parentOrderItemsId = new Set<Id>();
                List<OrderItem> parentOrderItemsToInsert = new List<OrderItem>();
                Map<Id, List<OrderItem>> parentQLChildMap = new Map<Id, List<OrderItem>>();

                // Processus pour chaque commandes
                for (Order ord : ordersToProcess) {
                    if (quoteQuotelinesMap.containsKey(ord.QuoteId)) {
                        System.debug('## Devis: ' + ord.QuoteId);
                        System.debug('## Processus sur ' + quoteQuotelinesMap.get(ord.QuoteId).size() + ' lignes');

                        // * 1 - Pour chaque lignes parent
                        for (QuoteLineItem qli : quoteQuotelinesMap.get(ord.QuoteId)) {
                            System.debug('## ----- LIGNE DE DEVIS - '+qli.Id+' - '+qli.productName__c+' - '+qli.Emplacement__c);
                            System.debug('## amendedOrderProduct__c: ' + qli.amendedOrderProduct__c);
                            System.debug('## Quantity: ' + qli.Quantity);

                            // Modify Order Product after amendment
                            if (qli.AmendedOrderProduct__c != null) {
                                System.debug('## Modification de la ligne de commande après avenant');
                                OrderItem orderProduct = orderItemMap.get(qli.amendedOrderProduct__c);
                                OrderItem newOrderProduct = new OrderItem();

                                System.debug('## orderItem.statutDeRevision__c: ' + orderProduct.statutDeRevision__c);
                                System.debug('## orderItem.QuoteLineItemId: ' + orderProduct.QuoteLineItemId);
                                System.debug('## orderItem.Quantity: ' + orderProduct.Quantity);

                                if (orderProduct == null || (orderProduct.StatutDeRevision__c != Constants.ORDERITEM_STATUTREVISION_UPDATING)
                                        && (orderProduct.QuoteLineItemId != null)) {
                                    continue;
                                }

                                // # Mise à jour de la ligne de commande
                                if (orderProduct.statutDeRevision__c == Constants.ORDERITEM_STATUTREVISION_UPDATING) {
                                    Boolean idAlreadyUpdated = false;
                                    for(String opId : parentOrderItemsId){
                                        if(opId == orderProduct.Id){
                                            idAlreadyUpdated = true;
                                        }
                                    }
                                    System.debug('## Mise à jour ligne de commande: ' + orderProduct.Id);
                                    if(!idAlreadyUpdated){
                                        newOrderProduct.Id = orderProduct.Id;
                                        //newOrderProduct.OrderId = ord.parentOrder__c;
                                        //newOrderProduct.previousOrderItem__c = orderProduct.Id;
                                        //newOrderProduct.PricebookEntryId = qli.PricebookEntryId;
                                        newOrderProduct.Quantity = qli.Quantity;
                                        newOrderProduct.orderItemQuantity__c = qli.Quantity;
                                        //newOrderProduct.Product2Id = qli.Product2Id;
                                        newOrderProduct.QuoteLineItemId = qli.Id; // Ne pas être modifié car la ligne de devis de l'OrderItem doit être égale au devis de la commande
                                        //newOrderProduct.ListPrice = (qli.ListPrice == null) ? 0 : qli.ListPrice;
                                        // On conserve le statut 'En cours de révision' jusqu'à la fin pour ne pas déclencher
                                        // les triggers lors de l'insertion des lignes parentes alors que les options
                                        // ne sont pas encore enregistrées
                                        newOrderProduct.statutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                                        newOrderProduct.UnitPrice = qli.PrixunitaireHTtarif__c;
                                        newOrderProduct.VATAmount__c = qli.prix_TVA_Ligne__c;
                                        newOrderProduct.VATRate__c = qli.TVApourcentage__c;
                                        newOrderProduct.pretaxAmount__c = qli.prixHTTarifRemise__c;
                                        newOrderProduct.amount__c = qli.TotalTTCligneRemise__c;
                                        newOrderProduct.height__c = qli.Hauteur__c;
                                        newOrderProduct.width__c = qli.Largeur__c;
                                        newOrderProduct.leaf__c = qli.Nombredevantaux__c;
                                        newOrderProduct.name__c = qli.productName__c;
                                        newOrderProduct.reference__c = qli.productCode__c;
                                        newOrderProduct.enseignDiscount__c = qli.Remise_Enseigne_HT__c;
                                        newOrderProduct.additionalDiscount__c = qli.remiseUnitaire__c * qli.Quantity;
                                        newOrderProduct.productType__c = qli.productType__c;
                                        newOrderProduct.unit__c = qli.productUnit__c;
                                        newOrderProduct.thermalCoefficients__c = qli.thermalCoefficients__c;
                                        newOrderProduct.assetCount__c = orderProduct.assetCount__c;
                                        newOrderProduct.assetAmendableCount__c = orderProduct.assetAmendableCount__c;
                                        // Gestion de l'emplacement
                                        newOrderProduct.location__c = defineOrderItemSalesLocation(qli.Emplacement__c);
                                        newOrderProduct.locationPrecision__c = defineOrderItemSalesPrecisionLocation(qli.Emplacement__c);

                                        // Gestion de la ligne parent
                                        parentOrderItemsToUpdate.add(newOrderProduct);
                                        parentOrderItemsId.add(orderProduct.Id);
                                        if (!parentQLChildMap.containsKey(qli.Id)) {
                                            parentQLChildMap.put(qli.Id, new List<OrderItem>());
                                        }
                                        System.debug('## parentQLChildMap: ' + parentQLChildMap);

                                        //detach from quoteline to free quantity
                                        //orderItemsToRemove.add(orderProduct);
                                    }
                                }
                            // New order product after amendment
                            } else if (qli.amendedOrderProduct__c == null && qli.Quantity > 0) {
                                System.debug('## Création de la ligne basée sur la ligne: ' + qli);
                                OrderItem newProduct = new OrderItem();
                                newProduct.OrderId = ord.parentOrder__c;
                                newProduct.PricebookEntryId = qli.PricebookEntryId;
                                newProduct.Quantity = qli.Quantity;
                                newProduct.orderItemQuantity__c = qli.Quantity;
                                newProduct.Product2Id = qli.Product2Id;
                                newProduct.QuoteLineItemId = qli.Id; // Ne pas être modifié car la ligne de devis de l'OrderItem doit être égale au devis de la commande
                                newProduct.ListPrice = (qli.ListPrice == null) ? 0 : qli.ListPrice;
                                // On conserve le statut 'En cours de révision' jusqu'à la fin pour ne pas déclencher
                                // les triggers lors de l'insertion des lignes parentes alors que les options
                                // ne sont pas encore enregistrées
                                newProduct.statutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                                newProduct.UnitPrice = qli.PrixunitaireHTtarif__c;
                                newProduct.VATAmount__c = qli.prix_TVA_Ligne__c;
                                newProduct.VATRate__c = qli.TVApourcentage__c;
                                newProduct.pretaxAmount__c = qli.prixHTTarifRemise__c;
                                newProduct.amount__c = qli.TotalTTCligneRemise__c;
                                newProduct.height__c = qli.Hauteur__c;
                                newProduct.width__c = qli.Largeur__c;
                                newProduct.leaf__c = qli.Nombredevantaux__c;
                                newProduct.name__c = qli.productName__c;
                                newProduct.reference__c = qli.productCode__c;
                                newProduct.enseignDiscount__c = qli.Remise_Enseigne_HT__c;
                                newProduct.additionalDiscount__c = qli.remiseUnitaire__c * qli.Quantity;
                                newProduct.productType__c = qli.productType__c;
                                newProduct.unit__c = qli.productUnit__c;
                                newProduct.thermalCoefficients__c = qli.thermalCoefficients__c;
                                // Gestion de l'emplacement
                                newProduct.location__c = defineOrderItemSalesLocation(qli.Emplacement__c);
                                newProduct.locationPrecision__c = defineOrderItemSalesPrecisionLocation(qli.Emplacement__c);

                                // Gestion de la ligne parent
                                //parentOrderItemsToUpdate.add(newProduct);
                                parentOrderItemsToInsert.add(newProduct);
                                if (!parentQLChildMap.containsKey(qli.Id)) {
                                    parentQLChildMap.put(qli.Id, new List<OrderItem>());
                                }
                                System.debug('## parentQLChildMap: ' + parentQLChildMap);
                            }
                        }

                        System.debug('## --------------------------------------------------------------------');
                        // * 2 - Pour chaque options
                        if(quoteOptionsMap.get(ord.QuoteId) != null) {
                            System.debug('## Processus sur ' + quoteOptionsMap.get(ord.QuoteId).size() + ' options');
                            for (Option__c opt : quoteOptionsMap.get(ord.QuoteId)) {
                                System.debug('## ----- OPTION - '+opt.Id+' - '+opt.ligneDevis__r.productName__c+' - '+opt.ligneDevis__r.Emplacement__c+' - '+opt.Libelleoption__c);
                                System.debug('## amendedOrderProduct__c: ' + opt.amendedOrderProduct__c);
                                System.debug('## Quantite__c: ' + opt.Quantite__c);

                                // Modify Order Product after amendment
                                if (opt.AmendedOrderProduct__c != null) {
                                    System.debug('## Modification de la ligne de commande après avenant');
                                    OrderItem orderProduct = orderItemMap.get(opt.amendedOrderProduct__c);
                                    OrderItem newOrderProduct = new OrderItem();

                                    System.debug('## orderItem.statutDeRevision__c: ' + orderProduct.statutDeRevision__c);
                                    System.debug('## orderItem.QuoteLineItemId: ' + orderProduct.QuoteLineItemId);
                                    System.debug('## orderItem.quoteOption__c: ' + orderProduct.quoteOption__c);
                                    System.debug('## orderItem.Quantity: ' + orderProduct.Quantity);

                                    if (orderProduct == null || (orderProduct.StatutDeRevision__c != Constants.ORDERITEM_STATUTREVISION_UPDATING)
                                            && (orderProduct.QuoteLineItemId != null) && (orderProduct.quoteOption__c != null)) {
                                        continue;
                                    }

                                    // # Mise à jour de la ligne de commande
                                    if (orderProduct.statutDeRevision__c == Constants.ORDERITEM_STATUTREVISION_UPDATING) {
                                        System.debug('## Mise à jour ligne de commande: ' + orderProduct.Id);
                                        newOrderProduct.Id = orderProduct.Id;
                                        //newOrderProduct.OrderId = ord.parentOrder__c;
                                        //newOrderProduct.previousOrderItem__c = orderProduct.Id;
                                        //newOrderProduct.PricebookEntryId = opt.ligneDevis__r.PricebookEntryId;
                                        //newOrderProduct.Quantity = opt.Quantite__c;
                                        newOrderProduct.Quantity = opt.Quantite__c*opt.ligneDevis__r.Quantity;
                                        newOrderProduct.orderItemQuantity__c = opt.Quantite__c;
                                        //newOrderProduct.Product2Id = opt.ligneDevis__r.Product2Id;
                                        newOrderProduct.QuoteLineItemId = opt.ligneDevis__c; // Ne pas être modifié car la ligne de devis de l'OrderItem doit être égale au devis de la commande
                                        newOrderProduct.quoteOption__c = opt.Id;
                                        //newOrderProduct.ListPrice = 1;
                                        // On conserve le statut 'En cours de révision' jusqu'à la fin pour ne pas déclencher
                                        // les triggers lors de l'insertion des lignes parentes alors que les options
                                        // ne sont pas encore enregistrées
                                        newOrderProduct.statutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                                        newOrderProduct.UnitPrice = opt.PrixunitaireHT__c;
                                        newOrderProduct.pretaxAmount__c = opt.PrixHT__c;
                                        newOrderProduct.height__c = opt.ligneDevis__r.Hauteur__c;
                                        newOrderProduct.width__c = opt.ligneDevis__r.Largeur__c;
                                        newOrderProduct.leaf__c = opt.ligneDevis__r.Nombredevantaux__c;
                                        newOrderProduct.name__c = opt.Libelleoption__c;
                                        newOrderProduct.reference__c = opt.Codeoption__c;
                                        newOrderProduct.productType__c = 'Component';
                                        newOrderProduct.unit__c = opt.ligneDevis__r.productUnit__c;
                                        newOrderProduct.assetCount__c = orderProduct.assetCount__c;
                                        newOrderProduct.assetAmendableCount__c = orderProduct.assetAmendableCount__c;

                                        // Gestion de la ligne enfant
                                        System.debug('## parentQLChildMap.get(opt.ligneDevis__c): ' + parentQLChildMap.get(opt.ligneDevis__c));
                                        if (!parentQLChildMap.containsKey(opt.ligneDevis__c)) {
                                            parentQLChildMap.put(opt.ligneDevis__c, new List<OrderItem>());
                                        }
                                        parentQLChildMap.get(opt.ligneDevis__c).add(newOrderProduct);
                                        System.debug('## parentQLChildMap: ' + parentQLChildMap);

                                        //detach from quoteline to free quantity
                                        //orderItemsToRemove.add(orderProduct);
                                    }

                                // New order product after amendment
                                } else if (opt.amendedOrderProduct__c == null && opt.Quantite__c > 0) {
                                    // # Création de la ligne de commande
                                    System.debug('## Création de la ligne basée sur l\'option: ' + opt);
                                    // Récupération lien produit 
                                    PricebookEntry pbe = productPBEMap.get(opt.Codeoption__c);
                                    OrderItem newProduct = new OrderItem();
                                    newProduct.OrderId = ord.parentOrder__c;
                                    newProduct.PricebookEntryId = (pbe == null) ? opt.ligneDevis__r.PricebookEntryId : pbe.Id;
                                    newProduct.Product2Id = (pbe == null) ? opt.ligneDevis__r.Product2Id : pbe.Product2Id;
                                    //newProduct.Quantity = opt.Quantite__c;
                                    newProduct.Quantity = opt.Quantite__c*opt.ligneDevis__r.Quantity;
                                    newProduct.orderItemQuantity__c = opt.Quantite__c;
                                    newProduct.QuoteLineItemId = opt.ligneDevis__c; // Ne pas être modifié car la ligne de devis de l'OrderItem doit être égale au devis de la commande
                                    newProduct.quoteOption__c = opt.Id;
                                    //newProduct.ListPrice = 1; // NE PAS DECOMMENTER SINON ERREUR
                                    // On conserve le statut 'En cours de révision' jusqu'à la fin pour ne pas déclencher
                                    // les triggers lors de l'insertion des lignes parentes alors que les options
                                    // ne sont pas encore enregistrées
                                    newProduct.statutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                                    newProduct.UnitPrice = opt.PrixunitaireHT__c;
                                    newProduct.pretaxAmount__c = opt.PrixHT__c;
                                    newProduct.height__c = opt.ligneDevis__r.Hauteur__c;
                                    newProduct.width__c = opt.ligneDevis__r.Largeur__c;
                                    newProduct.leaf__c = opt.ligneDevis__r.Nombredevantaux__c;
                                    newProduct.name__c = opt.Libelleoption__c;
                                    newProduct.reference__c = opt.Codeoption__c;
                                    newProduct.productType__c = 'Component';
                                    newProduct.unit__c = opt.ligneDevis__r.productUnit__c;

                                    // Gestion de la ligne enfant
                                    if (!parentQLChildMap.containsKey(opt.ligneDevis__c)) {
                                        parentQLChildMap.put(opt.ligneDevis__c, new List<OrderItem>());
                                    }
                                    parentQLChildMap.get(opt.ligneDevis__c).add(newProduct);
                                }
                            }
                        }
                    }
                }

                // Mise à jour des commandes initiales pour activer le flag "Processus avenant en cours" et mettre à jour les champs de la commande
                for (Order ord : ordersToProcess) {
                    String devisId = newQuoteForOrders.get(ord.parentOrder__c);
                    ordersInitToUpdate.add(new Order(Id = ord.parentOrder__c, amendingInProgress__c = true, QuoteId = ord.QuoteId,
                                                    BillingCity = ord.BillingCity, BillingCountry = ord.BillingCountry, 
                                                    BillingPostalCode = ord.BillingPostalCode, BillingState = ord.BillingState, 
                                                    BillingStreet = ord.BillingStreet,
                                                    ShippingCity = ord.ShippingCity, ShippingCountry = ord.ShippingCountry, 
                                                    ShippingPostalCode = ord.ShippingPostalCode, ShippingState = ord.ShippingState, ShippingStreet = ord.ShippingStreet,
                                                    ensignDiscount__c = ord.ensignDiscount__c, additionalDiscount__c = ord.additionalDiscount__c, financingMethod__c  = ord.financingMethod__c,
                                                    source__c = ord.source__c, specialTerms__c = ord.specialTerms__c, termsAndConditions__c = ord.termsAndConditions__c,
                                                    billingName__c = ord.billingName__c, shippingName__c = ord.shippingName__c,
                                                    dateDernierAvenant__c = Date.today(),
                                                    advancePaymentAmount1__c = ord.advancePaymentAmount1__c, advancePaymentAmount2__c = ord.advancePaymentAmount2__c,
                                                    advancePaymentPercent1__c= ord.advancePaymentPercent1__c, advancePaymentPercent2__c = ord.advancePaymentPercent2__c,
                                                    amount__c = ord.amount__c, pretaxAmount__c = ord.pretaxAmount__c, VATAmount__c = ord.VATAmount__c, 
                                                    pretaxAmountWithoutDiscount__c = ord.pretaxAmountWithoutDiscount__c)); 
                }
                System.debug('## Mise à jour des commandes initiales (' + ordersInitToUpdate.size()+ ')');
                update ordersInitToUpdate;

                // List assets for later update their orderItem__c
                //TO DELETE
                Set<Id> oldOrderItemsIds = new Set<Id>();
                List<OrderItem> finalOrderItemsUpdate = new List<OrderItem>();
                List<Asset> assets = new List<Asset>();
                /*System.debug('## OrderItems a supprimer: ' + orderItemsToRemove.size());
                for (OrderItem o : orderItemsToRemove) {
                    System.debug('## OrderItems a supprimer: '+ o.Id+' - '+ o.name__c);
                    oldOrderItemsIds.add(o.Id);
                }
                for (OrderItem o : orderItemsToCancel) {
                    oldOrderItemsIds.add(o.Id);
                }
                if (!oldOrderItemsIds.isEmpty()) {
                    assets = [ SELECT Id, orderItem__c, Quantity FROM Asset WHERE orderItem__c IN :oldOrderItemsIds ];
                }*/

                if (!orderItemsIds.isEmpty()) {
                    assets = [ SELECT Id, orderItem__c, Quantity FROM Asset WHERE orderItem__c IN :orderItemsIds ];
                }

                // Delete oldOrderItems
                // bypass deletion for tests as it throws an exception
                System.debug('## Suppression ' + orderItemsToRemove.size() + ' ligne commande parent');
                if (!orderItemsToRemove.isEmpty() && !Test.isRunningTest()) {
                    delete orderItemsToRemove;
                }

                // Cancel OrderItem removed on amendment quote
                System.debug('## OrderItems a annuler ' + orderItemsToCancel.size());
                if (!orderItemsToCancel.isEmpty()) {
                    for (OrderItem oic : orderItemsToCancel) {
                        oic.cancellationDate__c = Date.today();
                        oic.Quantity = 0;
                        oic.orderItemQuantity__c = 0;
                        oic.status__c = Constants.ORDERITEM_STATUS_CANCELLED;
                        oic.statutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                    }
                    update orderItemsToCancel;
                    for (OrderItem oic : orderItemsToCancel) {
                        oic.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
                        finalOrderItemsUpdate.add(oic);
                    }
                }

                System.debug('## parentOrderItemsToUpdate: ' + parentOrderItemsToUpdate);
                if (!parentOrderItemsToUpdate.isEmpty()) {
                    // JMU 28/10/2022 : Passage de List à Set à cause de doublons
                    List<OrderItem> listToUpdate = new List<OrderItem>();
                    listToUpdate.addAll(parentOrderItemsToUpdate);
                    
                    System.debug('## MAJ des lignes de commande parent (' + parentOrderItemsToUpdate.size() + ')');
                    update listToUpdate;
                }

                // Insert new parent order products and process children
                if (!parentOrderItemsToInsert.isEmpty()) {
                    System.debug('## Création des lignes de commande parent (' + parentOrderItemsToInsert.size() + ')');
                    insert parentOrderItemsToInsert;
                    parentOrderItemsToUpdate.addAll(parentOrderItemsToInsert);
                }

                System.debug('## parentOrderItemsToUpdate: ' + parentOrderItemsToUpdate);
                if (!parentOrderItemsToUpdate.isEmpty()) {
                    System.debug('## MAJ des lignes de commande parent');
                    //insert parentOrderItemsToUpdate;

                    // Update child order products to set their parent
                    List<OrderItem> childOrderItems = new List<OrderItem>();
                    for (OrderItem oip : parentOrderItemsToUpdate) {
                        System.debug('## Attache la ligne parent : ' + oip.Id + ' a ces enfants');
                        if (parentQLChildMap.containsKey(oip.QuoteLineItemId)) {
                            for (OrderItem oi : parentQLChildMap.get(oip.QuoteLineItemId)) {    
                                System.debug('## A pour enfant: ' + oi.Id+' - '+oi.name__c);                            
                                oi.parentOrderItem__c = oip.Id;
                                childOrderItems.add(oi);
                            }
                        }
                        System.debug('## Enfants: ' + childOrderItems.size());
                    }

                    // Insert child order products
                    if (!childOrderItems.isEmpty()) {
                        upsert childOrderItems;
                    }

                    List<Asset> assetsToUpdate = new List<Asset>();
                    List<Asset> assetsToRemove = new List<Asset>();
                    Map<Id, OrderItem> oldToNewOrderItemMap = new Map<Id, OrderItem>();
                    Map<Id, OrderItem> parentOrderItemMap = new Map<Id, OrderItem>();
                    // Prepare mapping for assets
                    // Update order products status all together
                    System.debug('## Post traitement childOrderItems (' + childOrderItems.size() + ')');
                    for (OrderItem oi : childOrderItems) {
                        System.debug('## Add enfant ancien orderItemId ' + oi.Id + ' pour liaison avec orderItem ' + oi);
                        oldToNewOrderItemMap.put(oi.Id, oi);
                        oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
                        finalOrderItemsUpdate.add(oi);
                    }
                    System.debug('## Post traitement parentOrderItems (' + parentOrderItemsToUpdate.size() + ')');
                    for (OrderItem oi : parentOrderItemsToUpdate) {
                        System.debug('## Add parent ancien orderItemId ' + oi.Id + ' pour liaison avec orderItem ' + oi);
                        oldToNewOrderItemMap.put(oi.Id, oi);
                        parentOrderItemMap.put(oi.Id, oi);
                        oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATED;
                        finalOrderItemsUpdate.add(oi);
                    }

                    // Update assets to reference new OrderItems/quotelines and update quantity
                    System.debug('## MAJ assets pour les lier aux nouveaux OrderItems (' + assets.size() + ' à MAJ)');
                    if (!assets.isEmpty()) {
                        for (Asset asset : assets) {
                            if (oldToNewOrderItemMap.containsKey(asset.orderItem__c)) {
                                System.debug('## MAJ asset ' + asset.Id + ' de orderItem ' + asset.orderItem__c + ' vers ' + oldToNewOrderItemMap.get(asset.orderItem__c).Id);
                                OrderItem newOrderItem = oldToNewOrderItemMap.get(asset.orderItem__c);
                                asset.orderItem__c = newOrderItem.Id;
                                asset.orderItem__c = newOrderItem.Id;
                                assetsToUpdate.add(asset);
                            } else {
                                //remove assets associated to Order Items affected to removed quote lines in the QLE
                                System.debug('## Suppr asset ' + asset.Id + ' qui était associé à une ligne de commande liée à une ligne de devis supprimée: ' + asset.orderItem__c);
                                assetsToRemove.add(asset);
                            }
                        }

                        if (!assetsToRemove.isEmpty()) {
                            delete assetsToRemove;
                        }
                        if (!assetsToUpdate.isEmpty()) {
                            update assetsToUpdate;
                        }
                    }

                    // Finally update order items status to 'Révisé'
                    if (!finalOrderItemsUpdate.isEmpty()) {
                        update finalOrderItemsUpdate;
                    }
                }

                // Mise à jour des commandes initiales pour désactiver le flag "Processus avenant en cours"
                System.debug('## Mise à jour des commandes initiales: ' + ordersInitToUpdate);
                ordersInitToUpdate.clear();
                for (Order ord : ordersToProcess) {
                    ordersInitToUpdate.add(new Order(Id = ord.parentOrder__c, amendingInProgress__c = false, amending__c = false));
                }
                if(!ordersInitToUpdate.isEmpty()) {
                    System.debug('## Mise à jour des commandes initiales: ' + ordersInitToUpdate);
                    update ordersInitToUpdate;
                }
            } catch(Exception e) {
                Database.rollback(sp);
                System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
        System.debug('### FIN TR023_Order : amendmentSalesQuoteValidated');
    }
        
    /**
    * @description Méthode pour définir l'emplacement des lignes de commande pour des lignes de devis Sales
    * @param emplacement Emplacement de la ligne de devis
    * @return Emplacement de la ligne de commande
    */
    public static String defineOrderItemSalesLocation(String emplacement) {
        String result;
        if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('entrée')) {
            result = 'Entrée';
        } else if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('salon')) {
            result = 'Salon';
        } else if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('cuisine')) {
            result = 'Cuisine';
        } else if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('chambre')) {
            result = 'Chambre';
        } else {
            result = 'Autre';
        }
        return result;
    }
        
    /**
    * @description Méthode pour définir la précision de l'emplacement des lignes de commande pour des lignes de devis Sales
    * @param emplacement Emplacement de la ligne de devis
    * @return Précision de l'emplacement de la ligne de commande
    */
    public static String defineOrderItemSalesPrecisionLocation(String emplacement) {
        String result = emplacement;
        if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('entrée')) {
            result = result.replace('entrée', '');
        } else if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('salon')) {
            result = result.replace('salon', '');
        } else if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('cuisine')) {
            result = result.replace('cuisine', '');
        } else if(String.isNotBlank(emplacement) && emplacement.toLowerCase().contains('chambre')) {
            result = result.replace('chambre', '');
        } 
        return result;
    }
}