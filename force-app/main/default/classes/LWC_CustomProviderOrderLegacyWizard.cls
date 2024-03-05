//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomProviderOrderLegacyWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 13/10/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_CustomProviderOrderLegacyWizard {

    /**
    * @description Récupération du N° legacy et billingName de la commande client
    * @param customerOrderId Id de la commande client
    * @return Commande cliente avec les champs concernés
    */
    @AuraEnabled(Cacheable = true)
    public static List<Order> getCustomerOrder(String customerOrderId){
        System.debug('### DEBUT LWC_CustomProviderOrderLegacyWizard.getCustomerOrder'); 
        List<Order> result = [SELECT Id, legacyReference__c, billingName__c FROM Order WHERE Id=:customerOrderId];
        System.debug('### FIN LWC_CustomProviderOrderLegacyWizard.getCustomerOrder');
        return result;
    }
    
    /**
     * @description Récupération du produit inconnu
    * @return Id du produit inconnu
	*/
    @AuraEnabled(Cacheable = true)
    public static String getUnknownProduct() {
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.getUnknownProduct');        
        String result;

        List<Product2> unknownProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'INCONNU' LIMIT 1];        
        if(!unknownProduct.isEmpty()) {
            result = unknownProduct[0].Id;
        }
        
        System.debug('### FIN LWC_CustomProviderOrderWizard.getUnknownProduct'); 
        return result;
    }

    /**
    * @description Récupération des orderItems de la commande fournisseur avec comme Produit 'REPRISE GC'
    * @param customerOrderId Id de la commande client
    * @return Commande cliente avec les champs concernés
    */
    @AuraEnabled(Cacheable = true)
    public static List<OrderItem> hasOrderItemRepriseGC(String recordId){
        System.debug('### DEBUT LWC_CustomProviderOrderLegacyWizard.hasOrderItemRepriseGC');
        List<OrderItem> result = new List<OrderItem>(); 
        System.debug('## recordId: '+recordId); 

        List<OrderItem> orderItems = [SELECT Id, Product2.Name, deliveryNumber__c, billingNumber__c FROM OrderItem WHERE OrderId=:recordId AND Product2.Name = 'REPRISE GC' LIMIT 1];
        if(!orderItems.isEmpty()){
            result = orderItems;
        }
        System.debug('## orderItems: '+orderItems);
        System.debug('### FIN LWC_CustomProviderOrderLegacyWizard.hasOrderItemRepriseGC');
        return result;
    }
    
    /**
    * @description Récupération de la liste des actifs d'une commande client
    * @param customerOrderId Id de la commande client
    * @param providerId Id du fournisseur
    * @return Liste des actifs de la commande
    */
   @AuraEnabled(Cacheable = true)
   public static List<Asset> getAssets(String customerOrderId, String providerId){
       System.debug('### DEBUT LWC_CustomProviderOrderLegacyWizard.getAssets'); 
       List<Asset> assets = new List<Asset>();
       List<Asset> result = new List<Asset>();
       List<String> assetProductList = new List<String>();
       System.debug('## customerOrderId: '+customerOrderId); 
       System.debug('## providerId: '+providerId); 

       // Récupération des produits (ASSET)
       if(String.isNotBlank(customerOrderId) && String.isNotBlank(providerId)) {  
        for(Asset ast : [SELECT  Id, Name, customerOrder__c, Quantity ,	leaf__c, height__c, width__c, location__c,
                            AssetProvidedById, Product2Id, Product2.Name, ParentId, dimensions__c
                            FROM Asset 
                            WHERE customerOrder__c = :customerOrderId AND ParentId = null]) {     
            result.add(ast);   
        }          
           /*for(Asset ast : [SELECT  Id, Name, customerOrder__c, Quantity ,	leaf__c, height__c, width__c, location__c,
                               AssetProvidedById, Product2Id, Product2.Name, ParentId
                               FROM Asset 
                               WHERE customerOrder__c = :customerOrderId AND ParentId = null]) {     
               if(String.isNotBlank(ast.Product2Id)) {
                   assetProductList.add(ast.Product2Id);   
               }
               assets.add(ast);   
           }

           // Récupération des fournisseurs pour chaque produit d'asset 
           for(Product_Provider__c prodSup : [SELECT Id, provider__c, provider__r.Name, product__c
                                           FROM Product_Provider__c
                                           WHERE product__c IN :assetProductList AND provider__c = :providerId]) {
               // On sélectionne les assets qui ont le même fournisseur que celui de la commande fournisseur
               for(Asset asset : assets){
                   if(asset.Product2Id == prodSup.product__c){
                        if(!result.contains(asset)){
                            result.add(asset);
                        }
                   }
               }
           }*/
       }
       System.debug('## result: '+result); 
       System.debug('### FIN LWC_CustomProviderOrderLegacyWizard.getAssets'); 
       return result;
   }

    /**
    * @description Récupération de la liste des actifs présélectionné
    * @param assetsId Liste de Id des Assets
    * @param recordId Id de la commande fournisseur
    * @param providerId Id du fournisseur
    * @return Liste d'enregistrement par défaut des non-conformités produits
    */
    @AuraEnabled(Cacheable = true)
    public static List<String> getAssetsByDefault(List<String> assetsId, String recordId, String providerId){
        System.debug('### DEBUT LWC_CustomProviderOrderLegacyWizard.getAssetsByDefault'); 
        List<String> result = new List<String>();
        Set<Asset> assetsList = new Set<Asset>();
        Set<String> assetsIdWithOrderItem = new Set<String>();
        Set<String> assetsIdWithProvider = new Set<String>();
        Set<String> assetProductList = new Set<String>();
        System.debug('## assetsId: '+ assetsId);
        System.debug('## providerId: '+ providerId);
        System.debug('## recordId: '+ recordId);

        for(Asset ast : [SELECT  Id, Product2Id FROM Asset WHERE Id IN :assetsId]) {     
            if(String.isNotBlank(ast.Product2Id)) {
                assetProductList.add(ast.Product2Id);   
            }
            assetsList.add(ast);
        }
        System.debug('## assetsList: '+ assetsList);

        //On présélectionne les orderItems dont leurs Assets ne sont pas déjà lié à d'autres providerOrderItem
        for(orderItem oi : [SELECT Id, asset__c, asset__r.Product2Id, asset__r.Id, OrderId, Order.RecordType.DeveloperName
                            FROM OrderItem 
                            WHERE asset__c=:assetsId AND orderRecordType__c = 'ProviderOrder' ]){
            assetsIdWithOrderItem.add(oi.asset__c);
        }
        System.debug('## assetsIdWithOrderItem: '+ assetsIdWithOrderItem);

        // Récupération des fournisseurs pour chaque produit d'asset 
        if(!assetProductList.isEmpty()) {
            for(Product_Provider__c prodSup : [SELECT Id, provider__c, provider__r.Name, product__c
                                            FROM Product_Provider__c
                                            WHERE product__c IN :assetProductList AND provider__c = :providerId]) {
                // On sélectionne les assets qui ont le même fournisseur que celui de la commande fournisseur
                for(Asset asset : assetsList){
                    if(asset.Product2Id == prodSup.product__c){
                        if(!assetsIdWithProvider.contains(asset.Id)){
                            assetsIdWithProvider.add(asset.Id);
                        }
                    }
                }
            }
            System.debug('## assetsIdWithProvider: '+ assetsIdWithProvider);
        }

        // Seuls les assets associés au fournisseur de la commande à lettrer et non déjà commandés seront présélectionnés.
        for(String assetId : assetsId){
            if(!assetsIdWithOrderItem.contains(assetId) && assetsIdWithProvider.contains(assetId)){
                result.add(assetId);
            }
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderLegacyWizard.getAssetsByDefault'); 
        return result;
    }

    /**
    * @description Création de nouvelles lignes de commandes fournisseurs fictives avec les nouvelles données 
    * @param recordId Id de la commande
    * @return Liste des actifs de la commande
    */
    @AuraEnabled(Cacheable = true)
    public static List<OrderItem> getOrderLines(String recordId, List<Asset> selectedAssets, Integer orderItemCount, Decimal orderTotalCost, Decimal orderEstimatedTotalCost,
                                                String orderBillingNumber, String orderDeliveryNumber, Date orderEffectiveDate, Date orderBillingDate,
                                                Date orderConfirmationDate, Date orderEstimatedDeliveryDate, Date orderDeliveryDate
                                                ){
        System.debug('### DEBUT LWC_CustomProviderOrderLegacyWizard.getOrderLines');
        List<OrderItem> result = new List<OrderItem>();
        List<String> selectedAssetsId = new List<String>();
        List<String> selectedAssetsIdDone = new List<String>(); 
        System.debug('## recordId: '+ recordId);
        System.debug('## selectedAssets: '+ selectedAssets);
        System.debug('## orderItemCount: '+ orderItemCount);
        System.debug('## orderTotalCost: '+ orderTotalCost);
        System.debug('## orderEstimatedTotalCost: '+ orderEstimatedTotalCost);
        
        /*
        Pour éviter les pertes de valeurs de coutReelParLigne et coutPrevParLine s'ils ne tombent pas sur des valeurs rondes, 
        on somme les coutParLignes, on fait la différence entre la somme des couts par ligne et les couts totaux, 
        cette différence est ajouté à la première ligne de commande 
        */

        // Si une valeur est null, alors mettre 0
        //orderTotalCost = (orderTotalCost == null) ? 0 : orderTotalCost;
        //orderEstimatedTotalCost = (orderEstimatedTotalCost == null) ? 0 : orderEstimatedTotalCost;

        // Flag pour savoir si on est sur la première ligne de commande
        boolean flagDifferenceEntreLesCouts=false;
        Decimal coutPrevParLine;

        Decimal sommeCoutPrevParLine;
        Decimal compteur = 1;
        Decimal estimatedProductCost;                                           

        Decimal coutReelParLigne;
        Decimal productCostWithDiff;
        Decimal sommeCoutReelParLigne;                                          

        if(orderTotalCost!=null){
            coutReelParLigne = (orderTotalCost/orderItemCount).setScale(2);
            sommeCoutReelParLigne = (coutReelParLigne*orderItemCount);
            productCostWithDiff = (coutReelParLigne + (orderTotalCost - sommeCoutReelParLigne)).setScale(2);
        } else{
            productCostWithDiff=null;
            coutReelParLigne=null;
        } 
        if(orderEstimatedTotalCost != null) {
            coutPrevParLine = (orderEstimatedTotalCost/orderItemCount).setScale(2);
            sommeCoutPrevParLine = (coutPrevParLine*orderItemCount);
            estimatedProductCost = (coutPrevParLine + (orderEstimatedTotalCost - sommeCoutPrevParLine)).setScale(2);
        } else {
            coutPrevParLine = null;
            estimatedProductCost = null;            
        }                                           
                            

        // Création des orderItems
        if(String.isNotBlank(recordId)) {       
            // Construction de la liste des lignes pour les tableaux
            for(Asset selectedAsset : selectedAssets){
                OrderItem oi; 
                String leaf = '';
                String dimensions;
                if(selectedAsset.height__c != null && selectedAsset.width__c != null) {
                    if(selectedAsset.leaf__c == '1') {
                        leaf = selectedAsset.leaf__c + ' VTL ';
                    } else if (String.isNotBlank(selectedAsset.leaf__c) && selectedAsset.leaf__c != '1') {
                        leaf = selectedAsset.leaf__c + ' VTX ';
                    } 
                    dimensions = leaf + 'H' + selectedAsset.height__c + 'xL' + selectedAsset.width__c;
                }
                if(flagDifferenceEntreLesCouts==false){
                    oi = new OrderItem(
                        estimatedProductCost__c=estimatedProductCost,
                        productCost__c=productCostWithDiff,
                        assetName__c=selectedAsset.Name,
                        Product2Id=selectedAsset.Product2Id,
                        asset__c = selectedAsset.Id,
                        location__c = selectedAsset.location__c,
                        Quantity = selectedAsset.Quantity,
                        leaf__c = selectedAsset.leaf__c,
                        height__c = selectedAsset.height__c,
                        width__c = selectedAsset.width__c,
                        invoiceNumber__c = dimensions, // champ tampon mais qui ne sera pas modifier
                        orderItemNumber__c= String.valueOf(compteur),
                        confirmationDate__c = orderConfirmationDate,
                        estimatedDeliveryDate__c = orderEstimatedDeliveryDate,
                        deliveryDate__c = orderDeliveryDate,
                        billingDate__c = orderBillingDate,
                        billingNumber__c = orderBillingNumber,
                        deliveryNumber__c = orderDeliveryNumber
                    );
                    flagDifferenceEntreLesCouts=true;
                    compteur++;
                }
                else{
                    oi = new OrderItem(
                        estimatedProductCost__c=coutPrevParLine,
                        productCost__c=coutReelParLigne,
                        assetName__c=selectedAsset.Name,
                        Product2Id=selectedAsset.Product2Id,
                        asset__c = selectedAsset.Id,
                        location__c = selectedAsset.location__c,
                        Quantity = selectedAsset.Quantity,
                        leaf__c = selectedAsset.leaf__c,
                        height__c = selectedAsset.height__c,
                        width__c = selectedAsset.width__c,
                        invoiceNumber__c = dimensions, // champ tampon mais qui ne sera pas modifier
                        orderItemNumber__c= String.valueOf(compteur),
                        confirmationDate__c = orderConfirmationDate,
                        estimatedDeliveryDate__c = orderEstimatedDeliveryDate,
                        deliveryDate__c = orderDeliveryDate,
                        billingDate__c = orderBillingDate,
                        billingNumber__c = orderBillingNumber,
                        deliveryNumber__c = orderDeliveryNumber
                    );
                    compteur++;
                }
                result.add(oi);  
            }            
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderLegacyWizard.getOrderLines'); 
        return result;
    }

    /**
    * @description Suppression des anciennes lignes et création réelle des nouvelles des lignes de commandes en associant les lignes fictives à la commande fournisseur 
    * @param newOrderItems Liste des OrderItems à créer
    * @param selectedAssets Liste des assets sélectionnés
    * @param orderId Id de la commande fournisseur
    */
    @AuraEnabled
    public static String createOrderItems(List<OrderItem> newOrderItems, List<Asset> selectedAssets, String orderId, String providerReference, Date effectiveDate, List<OrderItem> unknownOrderItems){
        System.debug('### DEBUT LWC_CustomProviderOrderLegacyWizard.createOrderItems'); 
        System.debug('## newOrderItems: '+ newOrderItems);
        System.debug('## selectedAssets: '+ selectedAssets);
        System.debug('## orderId: '+ orderId);
        System.debug('## providerReference: '+ providerReference);
        System.debug('## providerReference: '+ effectiveDate);
        
        String result = null; 
        List<OrderItem> orderItemsToUp = new List<OrderItem>();
        List<String> productIdList = new List<String>();
        Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>();
        
        String unknownProductId = getUnknownProduct();

        Savepoint sp = Database.setSavepoint();

        try{
            if(String.isNotBlank(orderId)){
                result = orderId;
                List<OrderItem> currentOrderItems = SchemaUtils.executeQuery('OrderItem', 'OrderId', orderId);
                OrderItem currentOrderItem = currentOrderItems[0];                                   
                System.debug('## currentOrderItems: '+ currentOrderItems);                        
                System.debug('## currentOrderItem: '+ currentOrderItem);

                // Récupération des infos de la commande
                Order currentOrder = [SELECT Id, providerReference__c, EffectiveDate, transmissionDate__c, legacyReference__c,
                                            provider__r.interfaceStreamPrefix__c, provider__r.KparKReference__c FROM Order WHERE Id=:orderId LIMIT 1];

                // Récupération des "PricebookEntry" pour lier les nouveaux produits aux lignes
                for(OrderItem newOrderItem : newOrderItems) {
                    productIdList.add(newOrderItem.Product2Id);
                }
                productIdList.add(unknownProductId);
                for(PricebookEntry pbe : [SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Product2.productType__c FROM PricebookEntry WHERE Product2Id IN :productIdList]) {
                    pbeMap.put(pbe.Product2Id, pbe);
                }                    
                System.debug('## pbeMap: '+ pbeMap);

                // Pour chaque lignes actuellement présente dans la commande, on les clone pour créer un nouvel enregistrement puis on les supprime
                for(OrderItem ordLine : newOrderItems) {
                    System.debug('## MAJ de la ligne: '+ ordLine.providerLineNumber__c);
                    String deliveryNumber = '';
                    OrderItem newOrderItem = currentOrderItem.clone(false, false, false, false);
                    // Construction du numéro de BL
                    if(String.isNotBlank(ordLine.deliveryNumber__c)) {
                        if(String.isBlank(currentOrder.provider__r.interfaceStreamPrefix__c)) {
                            deliveryNumber += '';
                        } else {
                            deliveryNumber += currentOrder.provider__r.interfaceStreamPrefix__c + '/';
                        }
                        deliveryNumber += ordLine.deliveryNumber__c;
                        deliveryNumber += '/' + ordLine.deliveryLineNumber__c; 
                    }
                    
                    // MAJ de la ligne
                    newOrderItem.Id = null;
                    newOrderItem.providerLineNumber__c = ordLine.providerLineNumber__c;
                    newOrderItem.confirmationDate__c = ordLine.confirmationDate__c;
                    if(newOrderItem.confirmationDate__c == null) {
                        newOrderItem.confirmationNumber__c = null; //Supprime le numéro de confirmation si pas de date de confirmation
                    }
                    newOrderItem.estimatedDeliveryDate__c = ordLine.estimatedDeliveryDate__c;
                    newOrderItem.deliveryDate__c = ordLine.deliveryDate__c;
                    newOrderItem.billingDate__c = ordLine.billingDate__c;
                    newOrderItem.estimatedProductCost__c = ordLine.estimatedProductCost__c;
                    newOrderItem.productCost__c = ordLine.productCost__c;
                    newOrderItem.billingNumber__c = ordLine.billingNumber__c;
                    newOrderItem.deliveryNumberRef__c = deliveryNumber;
                    //newOrderItem.asset__c = ordLine.asset__c;
                    newOrderItem.Product2Id = ordLine.Product2Id;  
                    newOrderItem.PricebookEntryId = pbeMap.get(ordLine.Product2Id).Id;
                    newOrderItem.name__c = pbeMap.get(ordLine.Product2Id).Product2.Name;
                    newOrderItem.reference__c = pbeMap.get(ordLine.Product2Id).Product2.ProductCode;
                    newOrderItem.productType__c = pbeMap.get(ordLine.Product2Id).Product2.productType__c;
                    newOrderItem.legacyReference__c = newOrderItem.legacyReference__c+'/'+ordLine.orderItemNumber__c;  
                    newOrderItem.deliveryLineNumber__c = ordLine.deliveryLineNumber__c; // Utilisation de champ inutile pour stocker provisoirement la ligne BL
                    newOrderItem.Quantity = ordLine.Quantity;  
                    newOrderItem.leaf__c = ordLine.leaf__c;  
                    newOrderItem.height__c = ordLine.height__c;  
                    newOrderItem.width__c = ordLine.width__c;  
                    newOrderItem.assetName__c = ordLine.assetName__c;  
                    newOrderItem.location__c = ordLine.location__c;  
                    
                    System.debug('## New OrderItem: '+ newOrderItem);
                    orderItemsToUp.add(newOrderItem);
                }
                System.debug('## orderItemsToUp: '+ orderItemsToUp);
                
                if(!unknownOrderItems.isEmpty()) {
                    for(OrderItem ordLine : unknownOrderItems) {
                        System.debug('## MAJ de la ligne: '+ ordLine.providerLineNumber__c);
                        String deliveryNumber = '';
                        //OrderItem newOrderItem = currentOrderItem.clone(false, false, false, false);
                        OrderItem newOrderItem = new OrderItem();
                        // Construction du numéro de BL
                        if(String.isNotBlank(ordLine.deliveryNumber__c)) {
                            if(String.isBlank(currentOrder.provider__r.interfaceStreamPrefix__c)) {
                                deliveryNumber += '';
                            } else {
                                deliveryNumber += currentOrder.provider__r.interfaceStreamPrefix__c + '/';
                            }
                            deliveryNumber += ordLine.deliveryNumber__c;
                            deliveryNumber += '/' + ordLine.deliveryLineNumber__c; 
                        }
                        
                        // MAJ de la ligne
                        //newOrderItem.Id = null;
                        newOrderItem.OrderId = orderId;
                        newOrderItem.providerLineNumber__c = ordLine.providerLineNumber__c;
                        newOrderItem.confirmationDate__c = ordLine.confirmationDate__c;
                        if(newOrderItem.confirmationDate__c == null) {
                            newOrderItem.confirmationNumber__c = null; //Supprime le numéro de confirmation si pas de date de confirmation
                        }
                        //newOrderItem.Description = ordLine.Description;
                        newOrderItem.productDescription__c = ordLine.Description;
                        newOrderItem.estimatedDeliveryDate__c = ordLine.estimatedDeliveryDate__c;
                        newOrderItem.deliveryDate__c = ordLine.deliveryDate__c;
                        newOrderItem.billingDate__c = ordLine.billingDate__c;
                        newOrderItem.estimatedProductCost__c = ordLine.estimatedProductCost__c;
                        newOrderItem.productCost__c = ordLine.productCost__c;
                        newOrderItem.billingNumber__c = ordLine.billingNumber__c;
                        newOrderItem.deliveryNumberRef__c = deliveryNumber;
                        newOrderItem.asset__c = ordLine.asset__c;
                        newOrderItem.Product2Id = unknownProductId;  
                        newOrderItem.PricebookEntryId = pbeMap.get(unknownProductId).Id;
                        newOrderItem.name__c = pbeMap.get(unknownProductId).Product2.Name;
                        newOrderItem.reference__c = pbeMap.get(unknownProductId).Product2.ProductCode;
                        newOrderItem.productType__c = pbeMap.get(unknownProductId).Product2.productType__c;
                        newOrderItem.legacyReference__c = currentOrder.legacyReference__c+'/'+ordLine.orderItemNumber__c;  
                        newOrderItem.deliveryLineNumber__c = ordLine.deliveryLineNumber__c; // Utilisation de champ inutile pour stocker provisoirement la ligne BL
                        newOrderItem.Quantity = ordLine.Quantity;  
                        newOrderItem.leaf__c = ordLine.leaf__c;  
                        newOrderItem.height__c = ordLine.height__c;  
                        newOrderItem.width__c = ordLine.width__c;  
                        newOrderItem.assetName__c = ordLine.assetName__c;  
                        newOrderItem.location__c = ordLine.location__c;  
                        
                        System.debug('## New OrderItem: '+ newOrderItem);
                        orderItemsToUp.add(newOrderItem);
                    }
                }

                // Mise à jour de la commande pour modifier le statut et mettre au brouillon
                currentOrder.legacyInProgress__c = true;
                update currentOrder;

                // Mise à jour de la référence fournisseur de la commande
                Boolean orderChanged = false;
                if(currentOrder.providerReference__c != providerReference){
                    System.debug('## MAJ Référence fournisseur: '+ providerReference);
                    currentOrder.providerReference__c = providerReference;
                    orderChanged = true;
                }
                if(currentOrder.EffectiveDate != effectiveDate){
                    System.debug('## MAJ Date commande: '+ effectiveDate);
                    currentOrder.EffectiveDate = effectiveDate;
                    orderChanged = true;
                }
                if(currentOrder.transmissionDate__c == null) {
                    System.debug('## MAJ Date tranmission: '+ currentOrder.EffectiveDate);
                    currentOrder.transmissionDate__c = currentOrder.EffectiveDate;
                    currentOrder.transmissionChannel__c = 'Reprise d\'historique';
                    currentOrder.ActivatedDate = currentOrder.transmissionDate__c;
                    orderChanged = true;
                }

                // MAJ de la commande
                if(orderChanged) {
                    update currentOrder;
                }

                if(!orderItemsToUp.isEmpty()) {
                    upsert orderItemsToUp;
                }

                if(!currentOrderItems.isEmpty()) {
                    delete currentOrderItems;
                }

                // Mise à jour de la commande pour remettre le statut 
                currentOrder.legacyInProgress__c = false;
                update currentOrder;
            }
        }
        catch(Exception e) {
            Database.rollback(sp); // Rollback des modifications
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('### FIN LWC_CustomProviderOrderLegacyWizard.createOrderItems');
        return result;
         
    }

    /**
    * @description Création des nouvelles des lignes de commandes et suppression des anciennes
    * @param newValues Nouvelles valeurs issues de draftValues à mettre à jour dans les orderItems actuels
    * @param orderItemsData Liste des order items actuel
    */
    @AuraEnabled
    public static List<OrderItem> updateDatatableOrderItems(List<Map<String,String>> newValues, List<OrderItem> orderItemsData){
        System.debug('### DEBUT LWC_CustomProviderOrderLegacyWizard.updateDatatableOrderItems');
        List<OrderItem> result = new List<OrderItem>();
        List<OrderItem> arrangedResult = new List<OrderItem>();
        
        Map<Id,OrderItem> idToOrderItem = new Map<Id,OrderItem>();
        Map<String,OrderItem> orderItemNumber2OrderItem = new Map<String,OrderItem>();

        //List<String> IdDone = new List<String>();

        //Liste des numéros des orderItems déjà modifiés via les nouvelles valeurs
        List<String> orderItemNumberDone = new List<String>();
        for(OrderItem oi : orderItemsData){
            System.debug('###oi : '+oi);
            System.debug('###oi  id: '+oi.Id);
            System.debug('###oi  number: '+oi.orderItemNumber__c);
            orderItemNumber2OrderItem.put(String.valueOf(oi.orderItemNumber__c),oi);
        }

        //Mise à jour des données avec les nouvelles valeurs
        for(Map<String,String> newOrderItemValues : newValues){
            OrderItem orderItem = orderItemNumber2OrderItem.get(newOrderItemValues.get('orderItemNumber__c'));
            orderItemNumberDone.add(newOrderItemValues.get('orderItemNumber__c'));
			
            if(newOrderItemValues.containsKey('providerLineNumber__c')) {
                orderItem.providerLineNumber__c = String.isNotBlank(newOrderItemValues.get('providerLineNumber__c')) ? String.valueOf(newOrderItemValues.get('providerLineNumber__c')) : null;
                System.debug('## orderItem.providerLineNumber__c : '+orderItem.providerLineNumber__c);
            }               
            if(newOrderItemValues.containsKey('confirmationDate__c')) {
                orderItem.confirmationDate__c = String.isNotBlank(newOrderItemValues.get('confirmationDate__c')) ? Date.valueOf(newOrderItemValues.get('confirmationDate__c')) : null;
                System.debug('## orderItem.confirmationDate__c : '+orderItem.confirmationDate__c);
            }                
            if(newOrderItemValues.containsKey('Description')) {
                orderItem.Description = String.isNotBlank(newOrderItemValues.get('Description')) ? String.valueOf(newOrderItemValues.get('Description')) : null;
                System.debug('## orderItem.Description : '+orderItem.Description);
            }            
            if(newOrderItemValues.containsKey('estimatedDeliveryDate__c')) {
                orderItem.estimatedDeliveryDate__c = String.isNotBlank(newOrderItemValues.get('estimatedDeliveryDate__c')) ? Date.valueOf(newOrderItemValues.get('estimatedDeliveryDate__c')) : null;
                System.debug('## orderItem.estimatedDeliveryDate__c : '+orderItem.estimatedDeliveryDate__c);
            }              
            if(newOrderItemValues.containsKey('estimatedProductCost__c')) {
                orderItem.estimatedProductCost__c = String.isNotBlank(newOrderItemValues.get('estimatedProductCost__c')) ? Decimal.valueOf(newOrderItemValues.get('estimatedProductCost__c')) : null;
                System.debug('## orderItem.estimatedProductCost__c : '+orderItem.estimatedProductCost__c);
            }           
            if(newOrderItemValues.containsKey('deliveryDate__c')) {
                orderItem.deliveryDate__c = String.isNotBlank(newOrderItemValues.get('deliveryDate__c')) ? Date.valueOf(newOrderItemValues.get('deliveryDate__c')) : null;
                System.debug('## orderItem.deliveryDate__c : '+orderItem.deliveryDate__c);
            }     
            if(newOrderItemValues.containsKey('billingDate__c')) {
                orderItem.billingDate__c = String.isNotBlank(newOrderItemValues.get('billingDate__c')) ? Date.valueOf(newOrderItemValues.get('billingDate__c')) : null;
                System.debug('## orderItem.billingDate__c : '+orderItem.billingDate__c);
            }     
            if(newOrderItemValues.containsKey('billingNumber__c')) {
                orderItem.billingNumber__c = String.isNotBlank(newOrderItemValues.get('billingNumber__c')) ? String.valueOf(newOrderItemValues.get('billingNumber__c')) : null;
                System.debug('## orderItem.billingNumber__c : '+orderItem.billingNumber__c);
            } 
            if(newOrderItemValues.containsKey('deliveryNumber__c')) {
                orderItem.deliveryNumber__c = String.isNotBlank(newOrderItemValues.get('deliveryNumber__c')) ? String.valueOf(newOrderItemValues.get('deliveryNumber__c')) : null;
                System.debug('## orderItem.deliveryNumber__c : '+orderItem.deliveryNumber__c);
            }
            /*if(newOrderItemValues.containsKey('deliveryLineNumber__c')) {
                orderItem.deliveryLineNumber__c = String.isNotBlank(newOrderItemValues.get('deliveryLineNumber__c')) ? String.valueOf(newOrderItemValues.get('deliveryLineNumber__c')) : null;
                System.debug('## orderItem.deliveryLineNumber__c : '+orderItem.deliveryLineNumber__c);
            } */
            if(newOrderItemValues.containsKey('productCost__c')) {
                orderItem.productCost__c = String.isNotBlank(newOrderItemValues.get('productCost__c')) ? Decimal.valueOf(newOrderItemValues.get('productCost__c')) : null;
                System.debug('## orderItem.productCost__c : '+orderItem.productCost__c);
            }
            if(newOrderItemValues.containsKey('deliveryLineNumber__c')) {
                orderItem.deliveryLineNumber__c = String.isNotBlank(newOrderItemValues.get('deliveryLineNumber__c')) ? String.valueOf(newOrderItemValues.get('deliveryLineNumber__c')) : null;
                System.debug('## orderItem.deliveryLineNumber__c : '+newOrderItemValues.get('deliveryLineNumber__c'));
            }
            result.add(orderItem);
        }

        //Ajout des order item qui n'ont pas été modifié
        for(String orderItemNumber : orderItemNumber2OrderItem.keySet()){
            if(!orderItemNumberDone.contains(orderItemNumber)){
                result.add(orderItemNumber2OrderItem.get(orderItemNumber));
            }
        }

        //Réarranger l'ordre du résultat
        for(String orderItemNumber : orderItemNumber2OrderItem.keySet()){
            for(OrderItem oi : result){
                if(String.valueOf(oi.orderItemNumber__c) == orderItemNumber){
                    arrangedResult.add(oi);
                    break;
                }
            }
        }

        System.debug('### FIN LWC_CustomProviderOrderLegacyWizard.updateDatatableOrderItems');
        return arrangedResult;
    }
}