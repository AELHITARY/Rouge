//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Order
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/06/2023
//-- Version     : 1.1
//-- * 1.1 : Correction déversement actif peut importe le statut
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Order {
    private static final String RT_CUSTOMER_ORDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
    private static final String RT_PROVIDER_ORDER = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    private static final String RT_ASSET_CARPENTRY = DAL.getRecordTypeIdByDevName('Asset', 'Carpentry');
    private static final String RT_ASSET_COMPONENT = DAL.getRecordTypeIdByDevName('Asset', 'Component');
    private static final String RT_ASSET_ACCESSORY = DAL.getRecordTypeIdByDevName('Asset', 'Accessory');
    private static final String RT_ASSET_SERVICE = DAL.getRecordTypeIdByDevName('Asset', 'Service');
    
    /**
    * @description Méthode appelée par les trigger MAJ des Order pour exécuter les flux et approval process
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void executeManagementFlow(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_Order.executeManagementFlow');
        // A - Initialisation et alimentation des données intermédiaires
        List<Order> newOrdersList = new List<Order>();
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        List<Order> ordersList = new List<Order>();
        List<Order> orderAssetToCreate = new List<Order>();
        List<String> orderIds = new List<String>();     
        List<String> accIds = new List<String>();     
        List<String> approvalOrderIds = new List<String>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<String, ProcessInstanceWorkItem> MapPval = new Map<String, ProcessInstanceWorkItem>();
        System.debug('## Trigger.isAfter : '+Trigger.isAfter);
        System.debug('## Trigger.isUpdate : '+Trigger.isUpdate);
        System.debug('## Trigger.isInsert : '+Trigger.isInsert);
        
        // A - On récupère les ids de chaque Order
        for (Order newOrder : (List<Order>)Trigger.new) {
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
            //if (!AlreadyUsed.isUsed('TR022_Order.executeManagementFlow', newOrder.id)) {
                newOrdersList.add(newOrder);
            //}
            
            if(newOrder.isInApprovalProcess__c == true && newOrder.RecordTypeId == RT_CUSTOMER_ORDER) {
                approvalOrderIds.add(newOrder.Id);
            }
        }
        
        if(!approvalOrderIds.isEmpty()) {
            for(ProcessInstanceWorkItem Pval : [SELECT Id, ProcessInstance.targetObjectId FROM ProcessInstanceWorkItem 
                                                WHERE ProcessInstance.targetObjectId IN :approvalOrderIds AND ProcessInstance.Status = 'Pending']) {
                MapPval.put(Pval.ProcessInstance.targetObjectId, Pval);
            }
        }
        System.debug('## newOrdersList: '+newOrdersList);
        System.debug('## MapPval: '+MapPval);
             
        // B - Calcul
        for (Order newOrder : newOrdersList) {
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
            System.debug('## Commande: ' + newOrder.Id);
            System.debug('## newOrder.Status : ' + newOrder.Status);
            System.debug('## newOrder.nccFinished__c : ' + newOrder.nccFinished__c);
            System.debug('## newOrder.inescapableCount__c : ' + newOrder.inescapableCount__c);
            System.debug('## newOrder.isRefused__c : ' + newOrder.isRefused__c);
            System.debug('## newOrder.isInApprovalProcess__c : '+ newOrder.isInApprovalProcess__c);
            System.debug('## newOrder.Name : '+ newOrder.Id);
            System.debug('## newOrder.orderItemCount__c : ' + newOrder.orderItemCount__c);
            System.debug('## newOrder.quoteCPQLineCount__c  : ' + newOrder.quoteCPQLineCount__c  );
            System.debug('## approvalReason__ : '+newOrder.approvalReason__c);
            System.debug('String.isNotBlank(newOrder.approvalReason__c) : '+String.isNotBlank(newOrder.approvalReason__c));
            System.debug('String.isBlank(newOrder.approvalReason__c) : '+String.isBlank(newOrder.approvalReason__c));
            System.debug('## newOrder.assetCount__c : '+newOrder.assetCount__c);

            // COMMANDE CLIENT - Exécution du processus d'approbation PA_Order_Approbation lorsque le Statut = Registered
            if(newOrder.Status == Constants.ORDER_STATUS_REGISTERED && newOrder.RecordTypeId == RT_CUSTOMER_ORDER  && newOrder.isLegacy__c == false
                && Trigger.isUpdate && Trigger.isAfter && newOrder.orderItemCount__c > 0 && newOrder.isInApprovalProcess__c == false
                && String.isNotBlank(newOrder.entityServiceQueueId__c) && newOrder.isRefused__c == false && String.isNotBlank(newOrder.approvalReason__c) && !Test.isRunningTest()
            ) {
                System.debug('## Execute ApprovalProcess : PA_Order_Approbation');
                // Si processus déja async, exécute en sync
                if(System.isFuture() || System.isBatch() || System.isQueueable()) {
                    executeApprovalProcessCustomerOrder(newOrder.id, newOrder.entityServiceQueueId__c, 'PA_Order_Approbation3');
                } else {
                    executeApprovalProcessCustomerOrderAsync(newOrder.id, newOrder.entityServiceQueueId__c, 'PA_Order_Approbation3');
                }
            }
            
            // COMMANDE CLIENT - Création actif si Statut IsChanged, si Statut = Validated, si type != "Avenant"
            // si RecordType = CustomerOrder et si aucun Actif sur la Commande Client et si commande non legacy
            if(newOrder.RecordTypeId == RT_CUSTOMER_ORDER && String.isBlank(newOrder.legacyReference__c) && newOrder.Status == Constants.ORDER_STATUS_VALIDATED
                && newOrder.Type != 'Avenant'  && (newOrder.assetCount__c == 0 || newOrder.assetCount__c == null)
                && Trigger.isUpdate && oldOrder != null && oldOrder.Status != newOrder.Status && newOrder.orderItemCount__c > 0
            ) {
                System.debug('## Create Assets for order: '+newOrder.Id);
                orderAssetToCreate.add(newOrder);
            }
                
            // COMMANDE CLIENT - Exécution du flow si Date d'annulation IsChanged, et si date d'annulation est vide sur la Commande Client
            if(Trigger.isAfter && Trigger.isUpdate && oldOrder != null && oldOrder.cancellingDate__c != newOrder.cancellingDate__c 
                && newOrder.cancellingDate__c == null && oldOrder.cancellingDate__c != null && (String.isNotBlank(newOrder.approvalReason__c) || Test.isRunningTest()) 
                && String.isNotBlank(newOrder.entityServiceQueueId__c) && newOrder.isInApprovalProcess__c == false && newOrder.RecordTypeId == RT_CUSTOMER_ORDER) 
            {
                System.debug('## Reopen Order: ' + oldOrder.cancellingDate__c);
                System.debug('## Execute Flow : Order_Customer_Validation');
                Map<String, Object> params = new Map<String, Object>();
                params.put('Order', oldOrder);
                Flow.Interview.Order_Customer_Validation orderFlow = new Flow.Interview.Order_Customer_Validation(params);
                orderFlow.start();
                if(newOrder.isValid__c != true) {
                    System.debug('## Execute ApprovalProcess : PA_Order_Approbation');
                    executeApprovalProcessCustomerOrder(newOrder.id, newOrder.entityServiceQueueId__c, 'PA_Order_Approbation3');
                }
            }
            
            // COMMANDE CLIENT - Exécution du flow si tout les assets sont installés, et si statut différent de Facturé sur la Commande Client
            if(newOrder.RecordTypeId == RT_CUSTOMER_ORDER && Trigger.isAfter && Trigger.isUpdate && oldOrder != null
                && oldOrder != null && oldOrder.installedAssetCount__c != newOrder.installedAssetCount__c 
                && newOrder.assetCount__c != null && newOrder.installedAssetCount__c != null && newOrder.installedAssetCount__c > 0
                && newOrder.installedAssetCount__c == newOrder.assetCount__c 
                && newOrder.Status != Constants.ORDER_STATUS_BILLED && oldOrder.Status != Constants.ORDER_STATUS_BILLED
                ) 
            {
                System.debug('## Execute Flow : Order_Customer_Facturation');
                Map<String, Object> params = new Map<String, Object>();
                params.put('recordId', newOrder.Id);
                Flow.Interview.Order_Customer_Facturation orderFlow = new Flow.Interview.Order_Customer_Facturation(params);
                orderFlow.start();
            }
            
            // COMMANDE CLIENT - Check sur le nombre de NCC levées pour relancer le process d'approbation si besoin
            if(newOrder.nccFinished__c == newOrder.inescapableCount__c && 
                newOrder.inescapableCount__c > 0 && String.isNotBlank(newOrder.entityServiceQueueId__c) && oldOrder != null && oldOrder.isRefused__c == newOrder.isRefused__c &&
                newOrder.isRefused__c && String.isNotBlank(newOrder.approvalReason__c) && newOrder.isInApprovalProcess__c == false && newOrder.RecordTypeId == RT_CUSTOMER_ORDER && Trigger.isUpdate) 
            {
                System.debug('## Execute ApprovalProcess : PA_Order_Approbation');
                executeApprovalProcessCustomerOrder(newOrder.id, newOrder.entityServiceQueueId__c, 'PA_Order_Approbation3');
            }
            
            if(newOrder.RecordTypeId == RT_CUSTOMER_ORDER && oldOrder != null && oldOrder.Status != newOrder.Status && newOrder.Status == Constants.ORDER_STATUS_CANCELLED 
               && newOrder.isInApprovalProcess__c == true) {
                   if(MapPval.get(newOrder.Id) != null) {
                       List<Id> approverId = new List<Id>();
                       Approval.ProcessWorkitemRequest req1 = new Approval.ProcessWorkitemRequest();
                       ProcessInstanceWorkItem workItem = MapPval.get(newOrder.Id);
                       req1.setComments('Rejet après annulation de la commande');
                       req1.setAction('Reject');
                       req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                       req1.setWorkitemId(workItem.Id);
                       Approval.ProcessResult result = Approval.process(req1);
                   }
               }
        }
        
        // Exécution du code pour créer les actifs
        if(!orderAssetToCreate.isEmpty()) {
            createAssets(orderAssetToCreate);
        }
        
        System.debug('### FIN TR022_Order.executeManagementFlow');
    }

    /**
    * @description Méthode appelée par les trigger MAJ des Order pour mettre à jour les cases SAV
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void updateCasesSAV(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR022_Order.updateCasesSAV');
        // A - Initialisation et alimentation des données intermédiaires
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        List<Case> caseList = new List<Case>();
        List<Case> caseListToUpdate = new List<Case>();
        List<String> cpqQuoteIds = new List<String>(); 
        
        // A - On récupère les ids de chaque Order
        for (Order newOrder : (List<Order>)Trigger.new) {
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);

            if (!AlreadyUsed.isUsed('TR022_Order.updateCasesSAV', newOrder.id)) {
                System.debug('## installedAssetCount__c: ' + newOrder.installedAssetCount__c);
                System.debug('## assetCount__c: ' + newOrder.assetCount__c);
                System.debug('## Type: ' + newOrder.Type);                
                if (newOrder.installedAssetCount__c == newOrder.assetCount__c && newOrder.assetCount__c > 0 
                    && oldOrder.installedAssetCount__c != newOrder.installedAssetCount__c && newOrder.Type == 'Commande SAV') 
                {
                    cpqQuoteIds.add(newOrder.SBQQ__Quote__c);
                }
            }
        }

        // Récupération des requêtes
        if(!cpqQuoteIds.isEmpty()) {
            caseList = [SELECT Id, Status, isClosed, afterSalesServiceQuote__c FROM Case WHERE afterSalesServiceQuote__c IN :cpqQuoteIds];
        }
        System.debug('## caseList: ' + caseList);
             
        // B - Calcul
        if(!caseList.isEmpty()) {
            for(Case newCase : caseList) {
                System.debug('## newCase.Status: ' + newCase.Status);  
                if(newCase.isClosed == false) {      
                    newCase.aCloturer__c = true;       
                    newCase.Status = Constants.REQUETE_STATUS_CLOSED;
                    caseListToUpdate.add(newCase);
                }
            }
        }
        
        if(!caseListToUpdate.isEmpty()) {
            update caseListToUpdate;  
        }

        System.debug('### FIN TR022_Order.updateCasesSAV');
    }

    /**
    * @description Méthode appelée par les trigger MAJ des Order pour mettre à jour les OrderItem enfants
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void updateRelatedOrderItems(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR022_Order.updateRelatedOrderItems');
        // A - Initialisation et alimentation des données intermédiaires
        List<Order> newOrdersList = new List<Order>();
        List<String> newOrdersIdList = new List<String>();
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        Map<String, List<OrderItem>> mapOrderOrderItems = new Map<String, List<OrderItem>>();
        List<OrderItem> orderItemToUpdate = new List<OrderItem>();
        
        // A - On récupère les ids de chaque Order
        for (Order newOrder : (List<Order>)Trigger.new) {
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);

            if (!AlreadyUsed.isUsed('TR022_Order.updateRelatedOrderItems', newOrder.id) || Test.isRunningTest()) {
                newOrdersList.add(newOrder);
                // Filtre pour récupération des lignes de commandes fournisseur
                if(newOrder.RecordTypeId == RT_PROVIDER_ORDER && (newOrder.transmissionDate__c != oldOrder.transmissionDate__c 
                    || (newOrder.cancellingDate__c != oldOrder.cancellingDate__c && newOrder.isRefused__c) )) 
                {
                    newOrdersIdList.add(newOrder.id);
                }
                // Filtre pour récupération des lignes de commandes client
                if((newOrder.RecordTypeId == RT_CUSTOMER_ORDER && newOrder.amending__c && newOrder.amending__c != oldOrder.amending__c) || Test.isRunningTest()) {
                    newOrdersIdList.add(newOrder.id);
                }
            }
        }

        // Récupération des lignes de commande
        if(!newOrdersIdList.isEmpty()) {
            List<OrderItem> oiList = [SELECT Id, status__c, stageName__c, OrderId, StatutDeRevision__c 
                                        FROM OrderItem WHERE OrderId IN :newOrdersIdList];        
            for (Order order : newOrdersList) {
                List<OrderItem> OrderItemByOrder = new List<OrderItem>();
                for (OrderItem oi : oiList) {
                    if(oi.OrderId == order.Id) {
                        OrderItemByOrder.add(oi);
                    }
                }
                mapOrderOrderItems.put(order.Id, OrderItemByOrder);
            }
        }
             
        // B - Calcul
        if(!mapOrderOrderItems.isEmpty()) {
            for (Order newOrder : newOrdersList) {
                Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);
                System.debug('## Commande: ' + newOrder.Id);
                List<OrderItem> orderItemsFromOrder = mapOrderOrderItems.get(newOrder.Id);

                //* Commande fournisseur
                if(newOrder.RecordTypeId == RT_PROVIDER_ORDER && orderItemsFromOrder != null) {                    
                    // Mise à jour des lignes de commande fournisseur lorsque la date de transmission est changée à null
                    if(newOrder.transmissionDate__c == null && oldOrder.transmissionDate__c != null)
                    {
                        System.debug('## Provider OrderItems Validated ' +newOrder.Id);
                        for(OrderItem oi : orderItemsFromOrder){
                            if(oi.status__c != Constants.ORDERITEM_STATUS_VALIDATED && oi.status__c != Constants.ORDERITEM_STATUS_CANCELLED){
                                oi.status__c = Constants.ORDERITEM_STATUS_VALIDATED;
                                orderItemToUpdate.add(oi);
                            }
                        }
                    }

                    // Mise à jour des lignes de commande fournisseur lorsque la date de transmission est remplie
                    if(newOrder.transmissionDate__c != null && oldOrder.transmissionDate__c != newOrder.transmissionDate__c)
                    {
                        System.debug('## Provider OrderItems Transmitted ' +newOrder.Id);
                        for(OrderItem oi : orderItemsFromOrder){
                            if(oi.status__c != Constants.ORDERITEM_STATUS_TRANSMITTED && oi.status__c != Constants.ORDERITEM_STATUS_CANCELLED){
                                oi.status__c = Constants.ORDERITEM_STATUS_TRANSMITTED;
                                oi.stageName__c = Constants.ORDERITEM_STAGE_CONFIRM;
                                orderItemToUpdate.add(oi);
                            }
                        }
                    }
                    
                    // Mise à jour des lignes de commande fournisseur lorsque la date d'annulation est remplie
                    if(newOrder.cancellingDate__c != null && oldOrder.cancellingDate__c != newOrder.cancellingDate__c && newOrder.isRefused__c)
                    {
                        System.debug('## Provider OrderItems Cancel ' +newOrder.Id);
                        for(OrderItem oi : orderItemsFromOrder){
                            if(oi.status__c != Constants.ORDERITEM_STATUS_CANCELLED){
                                oi.status__c = Constants.ORDERITEM_STATUS_CANCELLED;
                                oi.cancellationDate__c = date.today();
                                oi.cancellationReason__c = 'Refus K par K';
                                orderItemToUpdate.add(oi);
                            }
                        }
                    }
                }

                //* Commande client
                // Mise à jour des lignes de commande clients lorsqu'un avenant est en cours
                if(newOrder.RecordTypeId == RT_CUSTOMER_ORDER && newOrder.amending__c && newOrder.amending__c != oldOrder.amending__c) {
                    System.debug('## Customer OrderItems Amendement ' +newOrder.Id);
                    for(OrderItem oi : orderItemsFromOrder){
                        if(oi.StatutDeRevision__c != Constants.ORDERITEM_STATUTREVISION_UPDATING){
                            oi.StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_UPDATING;
                            orderItemToUpdate.add(oi);
                        }
                    }
                }
            }
        }

        if(!orderItemToUpdate.isEmpty()) {
            Database.update(orderItemToUpdate, false);
        }
        System.debug('### FIN TR022_Order.updateRelatedOrderItems');
    }

    /**
    * @description Méthode appelée par les trigger Order ou OrderItem afin de créer les actifs
    * @param newOrdersList Liste des commandes
    */
    public static void createAssets(List<Order> newOrdersList) {        
        try {
            // A - Initialisation et alimentation des données intermédiaires
            List<OrderItem> newOrderItemsList = new List<OrderItem>();
            newOrderItemsList = [SELECT Id, parentOrderItem__c, productConvertibleAsset__c, OrderId, productType__c, reference__c, assetQuantity__c, height__c, width__c,
                                    name__c, locationPrecision__c, Quantity, orderAccountId__c, assetAmendableCount__c, leaf__c, location__c, productCode__c, assetComponent__c,
                                    orderContactId__c, orderChantierId__c, orderServiceEntityId__c, orderEffectiveDate__c, UnitPrice, Product2Id, unit__c, 
                                    locationFormula__c, thermalCoefficients__c
                                    FROM OrderItem WHERE OrderId IN :newOrdersList];

            // B - MAJ
            if(!newOrderItemsList.isEmpty()) {
                createAssets(newOrderItemsList, false);
            }
        } catch (Exception e) {
            throw e;
        }
    }
    
    /**
    * @description Méthode appelée par les trigger Order ou OrderItem afin de créer les actifs
    * @param newOrdersList Liste des lignes des commandes
    * @param isAmending Mode avenant ou non
    */
    public static void createAssets(List<OrderItem> newOrderItemsList, Boolean isAmending) {
        try {
            System.debug('### DEBUT TR022_Order.createAssets');
            // A - Initialisation et alimentation des données intermédiaires
            List<OrderItem> newOrderItemsParentList = new List<OrderItem>();
            List<OrderItem> newOrderItemsChildList = new List<OrderItem>();
            List<Asset> assetParentToIns = new List<Asset>();
            List<Asset> assetChildToIns = new List<Asset>();
            //Map<String, Asset> mapAssetParent = new Map<String, Asset>();
            Map<String, List<Asset>> mapAssetChildByParent = new Map<String, List<Asset>>();
            // Création d'un SET pour dédoublonner les actifs parent
            List<Asset> assetParentInserted = new List<Asset>();
            Set<String> parentOrderItemIdList = new Set<String>();

            // Pas de création des actifs lors de la validation de la commande initiale en mode asynchrone.
            // La création des actifs s'effectuera directement par le processus d'avenant lorsque isAmending == true
            if(UserInfo.getName() == 'Automated Process' && isAmending == false) {
                return;
            }
            
            // On récupère les ids de chaque OrderItem
            for (OrderItem newOrderItem : newOrderItemsList) {
                if (!AlreadyUsed.isUsed('TR022_Order.createAssets', newOrderItem.id)) {
                    System.debug('## newOrderItem: ' +newOrderItem.Id+' - '+newOrderItem.productConvertibleAsset__c);
                    if(newOrderItem.productConvertibleAsset__c) {
                        if(newOrderItem.parentOrderItem__c == null) {
                            newOrderItemsParentList.add(newOrderItem);
                        } else {
                            newOrderItemsChildList.add(newOrderItem);
                        }
                    }
                }
            }
            System.debug('## OLI Parent list size: ' +newOrderItemsParentList.size());
            System.debug('## OLI Child list size: ' +newOrderItemsChildList.size());
            
            // B - Création des actifs parent
            for(OrderItem orderItemParent : newOrderItemsParentList) {
                if(orderItemParent.parentOrderItem__c == null) {
                    System.debug('## Création actif parent: ' +orderItemParent.Id);
                    assetParentToIns.addAll(constructAssetObject(orderItemParent, null, isAmending));
                } 
            }
            
            // Commit des actifs parent
            if(!assetParentToIns.isEmpty()) {
                insert assetParentToIns;
            }

            // Récupération actif parent si pas de création (cas de reconfiguration produit)
            if(!newOrderItemsChildList.isEmpty() && isAmending) {
                System.debug('## Récupération des actifs parents déjà insérés');
                for(OrderItem orderItemChild : newOrderItemsChildList) {
                    parentOrderItemIdList.add(orderItemChild.parentOrderItem__c);
                }
                System.debug('## parentOrderItemIdList: ' +parentOrderItemIdList);
                assetParentInserted.addAll([SELECT Id, Name, ParentId, orderItem__c, SBQQ__QuoteLine__c, assetComponent__c 
                                                FROM Asset WHERE orderItem__c IN :parentOrderItemIdList AND ParentId = null]);
            } else {
                assetParentInserted.addAll(assetParentToIns); 
            }
            System.debug('## Asset Parent List: ' +assetParentInserted.size() +' / '+assetParentInserted);
            
            // Récupération des actifs enfants
            if(!assetParentInserted.isEmpty() && isAmending) {
                System.debug('## Récupération des actifs enfants présents');
                // Récupération des Id des actifs parent
                Set<String> assetParentIdList = new Set<String>();
                for(Asset ast : assetParentInserted) {
                    assetParentIdList.add(ast.Id);
                }
                // Construction de la map des actifs enfant par clé
                for (Asset childAsset : [SELECT Id, ParentId, ProductCode, SBQQ__QuoteLine__c, Name 
                                            FROM Asset WHERE ParentId IN :assetParentIdList]) {
                    List<Asset> newAssetlist = null;
                    // Clé selon si asset CPQ ou Sales
                    String key;
                    if(String.isBlank(childAsset.SBQQ__QuoteLine__c)) {
                        key = childAsset.ParentId+childAsset.Name;
                    } else {
                        key = childAsset.ParentId+childAsset.ProductCode;
                    }
                    // Création de la map
                    if(mapAssetChildByParent.get(key) == null) {
                        newAssetlist = new List<Asset>();
                    } else {
                        newAssetlist = mapAssetChildByParent.get(key);
                    }
                    newAssetlist.add(childAsset);
                    mapAssetChildByParent.put(key, newAssetlist);
                }
                System.debug('## Asset Child List: ' +mapAssetChildByParent.size() +' / '+mapAssetChildByParent.values());
            }

            // C - Création des actifs enfant            
            for(Asset assetParent : assetParentInserted) {
                for(OrderItem orderItemChild : newOrderItemsChildList) {
                    // Récupération des actifs enfants du produit
                    // Clé selon si asset CPQ ou Sales
                    String key;
                    if(String.isBlank(assetParent.SBQQ__QuoteLine__c)) {
                        key = assetParent.Id+orderItemChild.reference__c+' - '+orderItemChild.name__c;
                    } else {
                        key = assetParent.Id+orderItemChild.productCode__c;
                    }
                    List<Asset> astChildList = mapAssetChildByParent.get(key);
                    // Vérification si l'actif parent n'a pas déjà l'actif enfant
                    if(assetParent.orderItem__c == orderItemChild.parentOrderItem__c && astChildList == null) {
                        System.debug('## Création actif enfant: ' +orderItemChild.Id +' - OLI Parent: '+orderItemChild.parentOrderItem__c);
                        assetChildToIns.addAll(constructAssetObject(orderItemChild, assetParent, isAmending));
                    }
                }
            }
            
            // Commit des actifs enfant
            if(!assetChildToIns.isEmpty()) {
                insert assetChildToIns;
            }
            System.debug('### FIN TR022_Order.createAssets');
        } catch (Exception e) {
            System.debug('ERREUR # TR022_Order.createAssets (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            throw e;
        }
    }

    /**
    * @description Méthode interne pour créer l'objet Asset
    * @param newOrderItem Objet contenant les informations de la ligne de commande
    * @param assetParent Objet contenant les informations de l'actif parent, null si c'est pour un actif enfant
    * @param isAmending Mode avenant ou non
    * @return List<Asset> Liste d'actifs
    */
    private static List<Asset> constructAssetObject(OrderItem newOrderItem, Asset assetParent, Boolean isAmending) {
        List<Asset> result = new List<Asset>();

        // Nom de l'actif
        String assetName;
        if(newOrderItem.productType__c ==  'Carpentry') {
            assetName = newOrderItem.reference__c + ' - ' + newOrderItem.locationFormula__c;
        } else {
            assetName = newOrderItem.reference__c + ' - ' + newOrderItem.name__c;
        }
        System.debug('## --- assetName: ' +assetName);
        System.debug('## assetQuantity__c: ' +newOrderItem.assetQuantity__c);
        System.debug('## assetAmendableCount__c: ' +newOrderItem.assetAmendableCount__c);
        System.debug('## Quantité: ' +newOrderItem.Quantity);
        System.debug('## OrderId: ' +newOrderItem.OrderId);
        System.debug('## AccountId: ' +newOrderItem.orderAccountId__c);
        System.debug('## isAmending: ' +isAmending);
        System.debug('## productType__c: ' +newOrderItem.productType__c);
        System.debug('## unit__c: ' +newOrderItem.unit__c);
        // Boucle par rapport à la quantité
        Decimal nbLoop;
        if(isAmending) {
            nbLoop = newOrderItem.Quantity - (newOrderItem.assetAmendableCount__c == null ? 0 : newOrderItem.assetAmendableCount__c);
        } else {                
            nbLoop = newOrderItem.assetQuantity__c - (newOrderItem.assetAmendableCount__c == null ? 0 : newOrderItem.assetAmendableCount__c);
        }
        // Si l'unité de la ligne de commande est différent de UNIT alors il faudra alors créer un seul et unique asset avec la quantité indiquée.
        if (newOrderItem.parentOrderItem__c != null || newOrderItem.productType__c == 'Component' || newOrderItem.unit__c != 'UNIT') {
            nbLoop = 1;
        }
        System.debug('## nbLoop: ' +nbLoop);
        // Création actif parent - Boucle par rapport à la quantité
        for(Integer i = 0; nbLoop > i ; i++) {
            Asset newAsset = new Asset(
                customerOrder__c = newOrderItem.OrderId,
                Name = assetName,
                Quantity = (nbLoop != 1) ? 1 : newOrderItem.Quantity,
                Product2Id = newOrderItem.Product2Id,
                orderItem__c = newOrderItem.Id,
                AccountId = newOrderItem.orderAccountId__c,
                ContactId = newOrderItem.orderContactId__c,
                chantier__c = newOrderItem.orderChantierId__c,
                AssetServicedById = newOrderItem.orderServiceEntityId__c,
                location__c = newOrderItem.location__c,
                locationPrecision__c = newOrderItem.locationPrecision__c,
                assetComponent__c = newOrderItem.assetComponent__c,
                thermalCoefficients__c = newOrderItem.thermalCoefficients__c
                /*PurchaseDate = newOrderItem.orderEffectiveDate__c,
                height__c = newOrderItem.height__c,
                width__c = newOrderItem.width__c,
                leaf__c = newOrderItem.leaf__c,
                unit__c = newOrderItem.unit__c,
                IsInternal = true*/
            );
            // RecordType
            if(newOrderItem.productType__c == 'Carpentry') {
                newAsset.RecordTypeId = RT_ASSET_CARPENTRY;
            } else if (newOrderItem.productType__c =='Component') {
                newAsset.RecordTypeId = RT_ASSET_COMPONENT;
            } else if (newOrderItem.productType__c =='Service') {
                newAsset.RecordTypeId = RT_ASSET_SERVICE;       
            } else {
                newAsset.RecordTypeId = RT_ASSET_ACCESSORY;
            }
            
            // Parent ou enfant
            if(assetParent == null) {
                System.debug('## Actif parent');
                newAsset.ParentId = null;
            } else {
                newAsset.ParentId = assetParent.Id;
                System.debug('## Actif enfant : Parent = '+newAsset.ParentId);
            }
            System.debug('## Nouvel actif:' +newAsset);
            result.add(newAsset);
        }
        return result;
    }
    
    /**
    * @description Méthode appelée par les trigger Order lors de l'approbation d'une commande avenant
    * Mise à jour des NCC et des documents attendu de la commande parent avec détection de doublon
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void updateAmendmentOrder(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_Order.updateAmendmentOrder');
        // A - Initialisation et alimentation des données intermédiaires
        List<Order> newOrdersList = new List<Order>();
        List<String> initialOrdersList = new List<String>();
        List<OrderNonCompliance__c> nccToInsert = new List<OrderNonCompliance__c>();
        List<AssignedExpectedDocument__c> docToInsert = new List<AssignedExpectedDocument__c>();
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        Map<String, Set<OrderNonCompliance__c>> mapNCCByOrder = new Map<String, Set<OrderNonCompliance__c>>();
        Map<String, Set<String>> mapNCCNameByOrder = new Map<String, Set<String>>();
        Map<String, Set<AssignedExpectedDocument__c>> mapDocByOrder = new Map<String, Set<AssignedExpectedDocument__c>>();
        Map<String, Set<String>> mapDocNameByOrder = new Map<String, Set<String>>();

        // A - On récupère les ids de chaque Order
        for (Order newOrder : (List<Order>)Trigger.new) {
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.Id);

            if (!AlreadyUsed.isUsed('TR022_Order.updateAmendmentOrder', newOrder.id)) {      
                if (newOrder.RecordTypeId == RT_CUSTOMER_ORDER && Trigger.isUpdate && Trigger.isAfter && newOrder.Type == 'Avenant' 
                    && oldOrder != null && oldOrder.isValid__c != newOrder.isValid__c && newOrder.isValid__c) 
                {
                    newOrdersList.add(newOrder);
                    initialOrdersList.add(newOrder.parentOrder__c);
                }
            }
        }
        System.debug('## newOrdersList: ' +newOrdersList.size());
        System.debug('## initialOrdersList: ' +initialOrdersList.size());
        
        if(!newOrdersList.isEmpty()) {
            // B - Récupération des NCC 
            for(OrderNonCompliance__c orderNCC : [SELECT Name, Id, customerOrder__c, expirationAction__c, immediateAction__c, criticity__c,
                                                        expirationDate__c, startDate__c, description__c, responsability__c, type__c FROM OrderNonCompliance__c 
                                                    WHERE (customerOrder__c IN :newOrdersList OR customerOrder__c IN :initialOrdersList)]) {
                Set<String> nccNameList = null;
                Set<OrderNonCompliance__c> nccList = null;
                String key = orderNCC.customerOrder__c;
                nccNameList = new Set<String>();
                nccList = new Set<OrderNonCompliance__c>();
                nccList.add(orderNCC);
                nccNameList.add(orderNCC.Name);
                mapNCCByOrder.put(key, nccList);
                mapNCCNameByOrder.put(key, nccNameList);
            }
            System.debug('## mapNCCByOrder: ' +mapNCCByOrder.size());
            System.debug('## mapNCCByOrder: ' +mapNCCByOrder);
            
            // C - Récupération des documents attendus
            for(AssignedExpectedDocument__c orderDoc : [SELECT Name, Id, customerOrder__c, receptionDate__c, expectedDate__c, expectedDocument__c,
                                                    expectedDocument__r.KparKReference__c, orderNonCompliance__c FROM AssignedExpectedDocument__c 
                                                    WHERE (customerOrder__c IN :newOrdersList OR customerOrder__c IN :initialOrdersList)]) {
                Set<String> docNameList = null;
                Set<AssignedExpectedDocument__c> docList = null;
                String key = orderDoc.customerOrder__c;
                docNameList = new Set<String>();
                docList = new Set<AssignedExpectedDocument__c>();
                docList.add(orderDoc);
                docNameList.add(orderDoc.expectedDocument__r.KparKReference__c);
                mapDocByOrder.put(key, docList);
                mapDocNameByOrder.put(key, docNameList);
            }
            System.debug('## mapDocByOrder: ' +mapDocByOrder.size());
            System.debug('## mapDocByOrder: ' +mapDocByOrder);

            for(Order amendmentOrder : newOrdersList) {
                List<String> nccNameToAdd = new List<String>();
                List<String> docCodeToAdd = new List<String>();
                System.debug('## Check ONC and documents for: ' +amendmentOrder.Id);

                // D - Détection des doublons des documents et création
                if(String.isNotBlank(amendmentOrder.parentOrder__c) && mapDocNameByOrder.get(amendmentOrder.Id) != null) {
                    System.debug('## Check documents for: ' +amendmentOrder.Id);
                    Set<String> docParentCodeList = mapDocNameByOrder.get(amendmentOrder.parentOrder__c);
                    Set<AssignedExpectedDocument__c> docOrderList = mapDocByOrder.get(amendmentOrder.Id);

                    // Vérification par rapport au code des document parent
                    for(String docCode : mapDocNameByOrder.get(amendmentOrder.Id)) {
                        // Vérification par rapport au code
                        if(docParentCodeList != null && docParentCodeList.contains(docCode) == false) {
                            docCodeToAdd.add(docCode);
                        }
                    } 
                    System.debug('## Document Codes: ' +docCodeToAdd);

                    // Création des documents à copier sur la commande parent
                    for(String docCode : docCodeToAdd) {
                        for(AssignedExpectedDocument__c docOrder : docOrderList) {
                            // Vérification par rapport au code et création de l'objet
                            if(docOrder.expectedDocument__r.KparKReference__c == docCode) {
                                docToInsert.add(new AssignedExpectedDocument__c(customerOrder__c = amendmentOrder.parentOrder__c, receptionDate__c = docOrder.receptionDate__c,expectedDate__c = docOrder.expectedDate__c, expectedDocument__c = docOrder.expectedDocument__c, orderNonCompliance__c = docOrder.orderNonCompliance__c));
                            }
                        } 
                    } 
                }

                // E - Détection des doublons des NCC et création
                if(String.isNotBlank(amendmentOrder.parentOrder__c) && mapNCCNameByOrder.get(amendmentOrder.Id) != null) {
                    System.debug('## Check ONC for: ' +amendmentOrder.Id);
                    Set<String> nccParentNameList = mapNCCNameByOrder.get(amendmentOrder.parentOrder__c);
                    Set<OrderNonCompliance__c> nccOrderList = mapNCCByOrder.get(amendmentOrder.Id);

                    // Vérification par rapport au nom des NCC Parent
                    for(String nccName : mapNCCNameByOrder.get(amendmentOrder.Id)) {
                        // Vérification par rapport au nom des NCC Parent
                        if(nccParentNameList != null && nccParentNameList.contains(nccName) == false) {
                            nccNameToAdd.add(nccName);
                        }
                    } 
                    System.debug('## ONC Names: ' +nccNameToAdd);

                    // Création des NCC à copier sur la commande parent
                    for(String nccName : nccNameToAdd) {
                        for(OrderNonCompliance__c nccOrder : nccOrderList) {
                            // Vérification par rapport au nom et création de l'objet
                            if(nccOrder.Name == nccName) {
                                nccToInsert.add(new OrderNonCompliance__c(customerOrder__c = amendmentOrder.parentOrder__c, expirationAction__c = nccOrder.expirationAction__c,immediateAction__c = nccOrder.immediateAction__c, criticity__c = nccOrder.criticity__c, expirationDate__c = nccOrder.expirationDate__c, startDate__c = nccOrder.startDate__c, description__c = nccOrder.description__c, responsability__c = nccOrder.responsability__c,type__c = nccOrder.type__c, Name = nccOrder.Name));
                            }
                        } 
                    } 
                }
                System.debug('## ONC To Insert: ' +nccToInsert);
            }
            
            // Commit des documents
            if(!docToInsert.isEmpty()) {
                insert docToInsert;
            }
            // Commit des NCC
            if(!nccToInsert.isEmpty()) {
                insert nccToInsert;
            }
        }
        System.debug('### FIN TR022_Order.updateAmendmentOrder');
    }

    /**
    * @description Méthode appelée par les trigger Order à la création pour récuperer les documents du devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void getDocumentsFromQuote(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_Order.getDocumentsFromQuote');
        // A - Initialisation et alimentation des données intermédiaires
        List<Order> newOrdersList = new List<Order>();
        Map<String, String> salesQuotesId = new Map<String, String>();
        Map<String, String> cpqQuotesId = new Map<String, String>();
        Map<String, Attachment> attachmentsMap = new Map<String, Attachment>();
        List<ContentDocumentLink> cDocumentLinkToInsert = new List<ContentDocumentLink>();

        // A - On récupère les ids de chaque Order
        for (Order newOrder : (List<Order>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR022_Order.getDocumentsFromQuote', newOrder.id)) {      
                if (newOrder.RecordTypeId == RT_CUSTOMER_ORDER && Trigger.isInsert && Trigger.isAfter) {
                    newOrdersList.add(newOrder);
                    if(String.isNotBlank(newOrder.QuoteId)) {
                        salesQuotesId.put(newOrder.QuoteId, newOrder.id);
                    }
                    if(String.isNotBlank(newOrder.SBQQ__Quote__c)) {
                        cpqQuotesId.put(newOrder.SBQQ__Quote__c, newOrder.id);
                    }
                }
            }
        }
        System.debug('## newOrdersList: ' +newOrdersList.size());
        System.debug('## salesQuotesId: ' +salesQuotesId.size());
        System.debug('## cpqQuotesId: ' +cpqQuotesId.size());

        if(!newOrdersList.isEmpty()) {
            // B - Récupération des Attachment si devis Sales 
            if(!salesQuotesId.isEmpty()) {
                System.debug('## Récupération des pièces jointe sur les devis Sales');
                for(Attachment att : [SELECT Id, ParentId, Name, body FROM Attachment WHERE ParentId IN :salesQuotesId.keySet()]) {
                    //Attachment newAtta = new Attachment(parentId = salesQuotesId.get(att.ParentId), name = att.Name, body = att.body);
                    //attToInsert.add(newAtta);
                    System.debug('## Attachment: ' +att.Id + ' / ' + att.Name);
                    
                    //Define the document type
                    String documentCategory;
                    if(att.Name.contains('DIPC')) {
                        documentCategory = 'DIP';
                    } else if(att.Name.contains('Contrat')) {
                        documentCategory = 'Contrat';
                    } else if(att.Name.contains('Attestation TVA')) {
                        documentCategory = 'Attestation TVA';
                    }

                    // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
                    Utils_APIMerkure.deleteCtDocumentByCategory(salesQuotesId.get(att.ParentId), null, documentCategory);

                    // Insertion ContentVersion
                    ContentVersion cVersion = new ContentVersion();
                    cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                    cVersion.PathOnClient = att.Name;
                    cVersion.Title = att.Name;//Name of the file
                    cVersion.VersionData = att.body;//File content
                    cVersion.category__c = documentCategory; // Catégorie du doc
                    insert cVersion;
                    
                    //After saved the Content Verison, get the ContentDocumentId
                    Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                    
                    //Insert ContentDocumentLink
                    ContentDocumentLink fileContentLink = new ContentDocumentLink();
                    fileContentLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                    fileContentLink.LinkedEntityId = salesQuotesId.get(att.ParentId);//Add attachment parentId
                    fileContentLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                    insert fileContentLink;
                    System.debug('## fileContentLink: ' +fileContentLink.Id );
                }
            }
            // C - Récupération des Attachment si devis CPQ 
            if(!cpqQuotesId.isEmpty()) {
                System.debug('## Récupération des pièces jointe sur les devis CPQ');
                for(ContentDocumentLink att : [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType FROM ContentDocumentLink WHERE LinkedEntityId IN :cpqQuotesId.keySet()]) {
                    System.debug('## ContentDocumentLink: ' +att.Id + ' / ' + att.ContentDocumentId);
                    
                    // Insert ContentDocumentLink
                    ContentDocumentLink fileContentLink = new ContentDocumentLink();
                    fileContentLink.ContentDocumentId = att.ContentDocumentId;//Add ContentDocumentId
                    fileContentLink.LinkedEntityId = cpqQuotesId.get(att.LinkedEntityId);//Add attachment parentId
                    fileContentLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                    cDocumentLinkToInsert.add(fileContentLink);
                }
            }
        }
        
        // Commit des ContentDocumentLink
        if(!cDocumentLinkToInsert.isEmpty()) {
            System.debug('## cDocumentLinkToInsert: ' +cDocumentLinkToInsert);
            insert cDocumentLinkToInsert;
        }
        System.debug('### FIN TR022_Order.getDocumentsFromQuote');
    }
    
    public static void executeApprovalProcessCustomerOrder(String recordId, String approverId, String approvalName) {
        System.debug('### DEBUT TR022_Order.executeApprovalProcessCustomerOrder');
        List<Id> approverListId = new List<Id>();
        approverListId.add(approverId);
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setObjectId(recordId);
        req1.setProcessDefinitionNameOrId(approvalName);
        req1.setSkipEntryCriteria(true);
        req1.setNextApproverIds(approverListId);
        Approval.ProcessResult result = Approval.process(req1);
        System.debug('## result: '+result);
        System.debug('### FIN TR022_Order.executeApprovalProcessCustomerOrder');
    }

    @future
    public static void executeApprovalProcessCustomerOrderAsync(String recordId, String approverId, String approvalName) {
        System.debug('### DEBUT TR022_Order.executeApprovalProcessCustomerOrderAsync');
        executeApprovalProcessCustomerOrder(recordId, approverId, approvalName);
        System.debug('### FIN TR022_Order.executeApprovalProcessCustomerOrderAsync');
    }

    public static void scheduleKMDCEinstein(UserContext userContext) {
        System.debug('### DEBUT TR022_Order.scheduleKMDCEinstein');

        List<Order> newOrders = (List<Order>)Trigger.new;
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap; 
        List<Order> ordersToUp = new List<Order>();
        List<Order> ordersValidatedToUp = new List<Order>();
        List<Order> ordersAmendValidatedToUp = new List<Order>();
        Decimal totalAmountCustomerOrder;
        Decimal pretaxAmountCustomerOrder;

        for(Order newOrder : newOrders) {
            Order oldOrder = oldOrders == null ? null : oldOrders.get(newOrder.id);

            System.debug('## oldOrder TTC: '+oldOrder.amount__c);
            System.debug('## newOrder TTC: '+newOrder.amount__c);
            System.debug('## oldOrder HT: '+oldOrder.pretaxAmount__c);
            System.debug('## newOrderHT: '+newOrder.pretaxAmount__c);

            // Récupération commande validée
            if(Trigger.isUpdate && oldOrder != null && newOrder.isValid__c && oldOrder.isValid__c != newOrder.isValid__c && newOrder.Type == Constants.ORDER_TYPE_COMMANDE_CLIENT) {
                System.debug('## Order Validated Id: '+newOrder.Id);
                ordersValidatedToUp.add(newOrder);
            }

            // Récupération commande avenant validée
            else if(Trigger.isUpdate && oldOrder != null && newOrder.isValid__c && oldOrder.amount__c != newOrder.amount__c && newOrder.Type == Constants.ORDER_TYPE_COMMANDE_CLIENT) {
                System.debug('## Order Amendment Validated Id: '+newOrder.Id);
                totalAmountCustomerOrder = oldOrder.amount__c;
                pretaxAmountCustomerOrder = oldOrder.pretaxAmount__c;
                System.debug('## totalAmountCustomerOrder: '+oldOrder.amount__c);
                System.debug('## pretaxAmountCustomerOrder: '+oldOrder.pretaxAmount__c);
                ordersAmendValidatedToUp.add(newOrder);
            }

            // Récupération commande annulée
            else if(Trigger.isUpdate && oldOrder != null && newOrder.cancellingDate__c != null && oldOrder.cancellingDate__c != newOrder.cancellingDate__c && newOrder.Type == Constants.ORDER_TYPE_COMMANDE_CLIENT) {
                System.debug('## Order Cancelled Id: '+newOrder.Id);
                ordersToUp.add(newOrder);
            }
            // Récupération commande réouverte
            else if(Trigger.isUpdate && oldOrder != null && /*newOrder.cancellingDate__c == null &&*/ newOrder.isReopen__c && oldOrder.isReopen__c != newOrder.isReopen__c && newOrder.Type == Constants.ORDER_TYPE_COMMANDE_CLIENT) {
                System.debug('## Order Reopen Id: '+newOrder.Id);
                ordersToUp.add(newOrder);
            }
        }

        if(!ordersToUp.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
           System.enqueueJob(new QA_KMDCEinstein('Quote', ordersToUp, null, null)); // Alimentation KMDC pour einstein
        } else if(!ordersValidatedToUp.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            System.enqueueJob(new QA_KMDCEinstein('QuoteValidation', ordersValidatedToUp, null, null)); // Alimentation KMDC pour einstein
        } else if(!ordersAmendValidatedToUp.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
            System.enqueueJob(new QA_KMDCEinstein('QuoteAmendmentValidation', ordersAmendValidatedToUp, totalAmountCustomerOrder, pretaxAmountCustomerOrder)); // Alimentation KMDC pour einstein
        }
        System.debug('### FIN TR022_Order.scheduleKMDCEinstein');
    }


    /**
      * @description Mise à jour du statut GC des commandes
      * @param userContext Contexte de l'utilisateur courant
      */
      public static void updateOrderGCStatus(UserContext userContext) {
        System.debug('### DEBUT TR022_Order.updateOrderGCStatus');
        if (!Trigger.isExecuting)
            return;
        
        Set<Id> orderIdsList = new Set<Id>();
        Set<Id> providerOrderIdsList = new Set<Id>();
        List<Order> customerOrderListFromProviders = new List<Order>();

        try {
            // A - Initialisation et alimentation des données intermédiaires
            for(Order o : (List<Order>)Trigger.new){
                if(o.Status != null && o.Status != Constants.ORDER_STATUS_REGISTERED && o.RecordTypeId == RT_CUSTOMER_ORDER && 
                    (o.Type == Constants.ORDER_TYPE_COMMANDE_CLIENT || o.Type == Constants.ORDER_TYPE_RECOMMANDE_CLIENT) &&
                    (o.installableAssetCount__c != 0 || o.installedAssetCount__c != 0)){
                    orderIdsList.add(o.Id);
                    System.debug('### orderIdList add Order : '+o.Id);
                } else if(o.RecordTypeId == RT_PROVIDER_ORDER){
                    orderIdsList.add(o.parentOrder__c);
                    System.debug('### orderIdList add Provider Parent from : '+o.Id);
                }
            }
            
            System.debug('orderIdsList : '+orderIdsList);
            
            // B - MAJ
            // LEGACY KUBE 2 : Calcul ancien statut GC
            if(!orderIdsList.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Exec queueable update old status GC: ' + orderIdsList);
                System.enqueueJob(new QA_UpdateOrderStatusGC(orderIdsList));
            }
        } catch (Exception e) {
            throw e;
        }
        System.debug('### FIN TR022_Order.updateOrderGCStatus');
    }

    /**
      * @description Mise à jour du statut GC des commandes
      * @param userContext Contexte de l'utilisateur courant
      */
      public static void updateAfterSalesServiceGCStatus(UserContext userContext) {
        System.debug('### DEBUT TR022_Order.updateAfterSalesServiceGCStatus');
        if (!Trigger.isExecuting)
            return;
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        Set<Id> savIdsList = new Set<Id>();
        Set<Id> caseIdsList = new Set<Id>();

        try {
            // A - Initialisation et alimentation des données intermédiaires
            for(Order o : (List<Order>)Trigger.new){
                Order oldOrder = oldOrders == null ? null : oldOrders.get(o.Id);
                //A la modification de commande de type SAV avec Dossier SAV rattaché
                //A la création ou a la modif des champs impactant le statut GC : netBalance__c, installationCompletionDate__c, cancellingDate__c, afterSalesService__c
                if(o.Type == Constants.ORDER_TYPE_COMMANDE_SAV && o.afterSalesService__c != null){
                    String savId =  o.afterSalesService__c;
                    if(Trigger.isInsert || (Trigger.isUpdate && 
                        (o.netBalance__c != oldOrder.netBalance__c || o.installationCompletionDate__c != oldOrder.installationCompletionDate__c ||
                        o.cancellingDate__c != oldOrder.cancellingDate__c || o.afterSalesService__c != oldOrder.afterSalesService__c))){
                            if(!savIdsList.contains(savId)){
                                savIdsList.Add(savId);
                                System.debug('### savIdList add sav : '+savId);
                            }
                        }
                }
                //Commande fournisseur associés a des commandes SAV 
                //A la création ou a la modif des champs impactant le statut GC : confirmationDate__c,deliveryDate__c, cancellingDate__c,
                if(o.RecordTypeId == RT_PROVIDER_ORDER && (o.productNonCompliance__c != null || o.afterSalesService__c != null)){
                    //String savId =  o.afterSalesService__c;
                    if(Trigger.isInsert || (Trigger.isUpdate && 
                        (o.confirmationDate__c != oldOrder.confirmationDate__c || o.deliveryDate__c != oldOrder.deliveryDate__c || o.cancellingDate__c != oldOrder.cancellingDate__c))){
                            if(o.afterSalesService__c != null && !savIdsList.contains(o.afterSalesService__c)){
                                savIdsList.Add(o.afterSalesService__c);
                                System.debug('### savIdList add sav : '+o.afterSalesService__c);
                            }
                            else if(!caseIdsList.contains(o.productNonCompliance__c)){
                                caseIdsList.Add(o.productNonCompliance__c);
                                System.debug('### caseIdList add sav : '+o.productNonCompliance__c);
                            }
                        }
                }
            }

            System.debug('### caseIdsList : '+caseIdsList);

            if(!caseIdsList.isEmpty()){
                List<Case> caseList = [SELECT afterSalesService__c FROM Case WHERE RecordType.DeveloperName = 'InternalProductNonCompliance' AND afterSalesService__c != null AND Id IN:caseIdsList];
                if(!caseList.isEmpty()){
                    for(Case ncp : caseList){
                        String savId =  ncp.afterSalesService__c;
                        if(!savIdsList.contains(savId)){
                            savIdsList.Add(savId);
                            System.debug('### savIdList add sav : '+savId);
                        }
                    }
                }
            }
            
            System.debug('savIdList : '+savIdsList);

            // B - MAJ
            // LEGACY KUBE 2 : Calcul ancien statut GC sur dossier SAV
            if(!savIdsList.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Exec queueable update old status GC SAV : ' + savIdsList);
                System.enqueueJob(new QA_UpdateAfterSalesServiceStatusGC(savIdsList));
            }
        } catch (Exception e) {
            throw e;
        }
        System.debug('### FIN TR022_Order.updateAfterSalesServiceGCStatus');
    }

    public static void updateNCC(UserContext userContext) {
        List<Order> allUpdatedOrder = new List<Order>();
        List<Order> ordersList = (List<Order>)Trigger.new;
        Map<Id, Order> oldOrders = (Map<Id, Order>)Trigger.oldMap;
        if (Trigger.isUpdate){
            for(Order nOrder : ordersList){
                if(oldOrders.get(nOrder.Id).controlDateForm__c != nOrder.controlDateForm__c || 
                oldOrders.get(nOrder.Id).transmissionDate__c != nOrder.transmissionDate__c)
                {
                    allUpdatedOrder.add(nOrder);
                }  
            }
            if(!allUpdatedOrder.isEmpty()){
                List<OrderNonCompliance__c> allNCC = [SELECT Id FROM OrderNonCompliance__c WHERE customerOrder__c IN :allUpdatedOrder];

                if(!allNCC.isEmpty()){
                    update allNCC;
                }
            }
        }
        
    }
}