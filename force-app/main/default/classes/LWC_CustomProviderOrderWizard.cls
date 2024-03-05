//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomProviderOrderWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 14/06/2023
//-- Version     : 1.1
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_CustomProviderOrderWizard {

    /**
    * @description Récupération de la liste des actifs d'une commande client
    * @param recordId Id de la commande
    * @return Liste des actifs de la commande
    */
    @AuraEnabled(Cacheable = true)
    public static List<Asset> getProducts(String recordId){
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.getProducts'); 
        List<Asset> result = new List<Asset>();
        System.debug('## customerOrderId: '+recordId); 

        // Récupération des produits (ASSET)
        if(String.isNotBlank(recordId)) {            
            String assetCRTId = DAL.getRecordTypeIdByDevName('Asset', Constants.ASSET_CARPENTRY_RT); 
            String assetSRTId = DAL.getRecordTypeIdByDevName('Asset', 'Service'); // TODO
            // Récupère seulement les assets qui sont commandable et associés à l'enregistrement
            // Customer Order 
            if(recordId.startsWith('801')){
                // Commande SAV
                Order ord = [SELECT Id, Type FROM Order WHERE Id = :recordId LIMIT 1];
                if (ord.Type == 'Commande SAV') {
                    for(Asset ast : [SELECT  Id, customerOrder__c, controlDate__c, InstallDate, Product2Id, 
                                    ProductCode, Name, isOrderable__c FROM Asset 
                                    WHERE customerOrder__c = :recordId 
                                        AND (RecordTypeId = :assetCRTId OR RecordTypeId = :assetSRTId)
                                        AND ParentId = null])
                    {
                        System.debug('## Récupération des produits "ast" via order: '+ast); 
                        result.add(ast);
                    }
                // Commande Client
                }else {                
                    for(Asset ast : [SELECT  Id, customerOrder__c, controlDate__c, InstallDate, Product2Id, 
                                    ProductCode, Name, isOrderable__c FROM Asset 
                                    WHERE customerOrder__c = :recordId 
                                        AND (RecordTypeId = :assetCRTId OR RecordTypeId = :assetSRTId)
                                        AND isOrderable__c = true
                                        AND ParentId = null]) 
                    {
                        System.debug('## Récupération des produits "ast" via order: '+ast); 
                        result.add(ast);
                    }
                }  
            // NCP Interne
            } else {
                Case recordCase = new Case();
                recordCase = [SELECT Id, AssetId, responsability__c FROM Case WHERE Id = :recordId LIMIT 1];

                for(Asset ast : [SELECT  Id, customerOrder__c, controlDate__c, InstallDate, Product2Id, 
                                    ProductCode, Name, isOrderable__c FROM Asset 
                                    WHERE id = :recordCase.AssetId]) {
                    System.debug('## Récupération des produits "ast" via NCP Interne: '+ast); 
                    result.add(ast);
                }
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderWizard.getProducts'); 
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
        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderWizard.getUnknownProduct'); 
        return result;
    }
    
    /**
    * @description Récupération du RecordType ProviderOrder
    * @return Id du RT
    */
    @AuraEnabled(Cacheable = true)
    public static String getProviderOrderRecordType() {
        return DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
    }
    
    /**
    * @description Récupération de la liste des fournisseurs
    * @param assetsId Liste des Id des assets
    * @return Liste des fournisseurs
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAllProviders(List<String> assetsId, String objectApiName){
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.getAllProviders'); 
        System.debug('## assetsId: '+assetsId); 
        Map<String, Product_Provider__c> providersMap = new Map<String, Product_Provider__c>();
        List<Product_Provider__c> providerProductList = new List<Product_Provider__c>();
        List<OptionWrapper> allProviderList = new List<OptionWrapper>();

        // Récupération des fournisseurs de tous les actifs
        providerProductList = queryProductProviders(assetsId, objectApiName);
        for(Product_Provider__c prodSup : providerProductList) {
            providersMap.put(prodSup.provider__c, prodSup); // Unique provider
        }
        // Affichage unique des fournisseurs
        for(Product_Provider__c prodSup : providersMap.values()) {
            allProviderList.add(new OptionWrapper(prodSup.provider__r.Name, prodSup.provider__c));
        }
        
        System.debug('## allProviderList: '+allProviderList); 
        System.debug('### END LWC_CustomProviderOrderWizard.getAllProviders'); 
        return allProviderList;
    }
    
    /**
    * @description Récupération de la liste des fournisseurs pour le produit inconnu
    * @return Liste des fournisseurs
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAllProvidersUnknown(){
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.getAllProvidersUnknown'); 
        Map<String, Account> providersMap = new Map<String, Account>();
        List<Account> providerProductList = new List<Account>();
        List<OptionWrapper> allProviderList = new List<OptionWrapper>();

        // Récupération des fournisseurs
        providerProductList = queryProductProvidersUnknown();
        for(Account prodSup : providerProductList) {
            providersMap.put(prodSup.Id, prodSup); // Unique provider
        }
        // Affichage unique des fournisseurs
        for(Account prodSup : providersMap.values()) {
            allProviderList.add(new OptionWrapper(prodSup.Name, prodSup.Id));
        }
        
        System.debug('## allProviderList: '+allProviderList); 
        System.debug('### END LWC_CustomProviderOrderWizard.getAllProvidersUnknown'); 
        return allProviderList;
    }

    /**
    * @description Récupération de la liste des fournisseurs d'un produit ou toute la liste des fournisseurs du dépot si c'est une commande SAV
    * @param assetsId Liste des Id des assets
    * @param isAfterSalesService True si concerne une commande SAV
    * @return Liste des actifs avec les fournisseurs
    */
    @AuraEnabled(Cacheable = true)
    public static List<ProductProvider> getProviders(List<String> assetsId, Boolean isAfterSalesService){
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.getProviders'); 
        System.debug('## assetsId: '+assetsId); 
        System.debug('## isAfterSalesService: '+isAfterSalesService); 
        List<ProductProvider> result = new List<ProductProvider>();
        List<Product_Provider__c> providerProductList = new List<Product_Provider__c>();
        List<Account> providersList = new List<Account>();

        // Récupération des fournisseurs 
        if(isAfterSalesService) {
            providersList = queryProductProvidersUnknown();
        } else {
            providerProductList = queryProductProviders(assetsId, 'Order');
        }
        System.debug('## providersList: '+providersList); 
        System.debug('## providerProductList: '+providerProductList); 

        // Création objet unique par fournisseur
        List<Asset> assetList = [SELECT Id, Name, Product2Id, ProductCode, Quantity, unit__c, orderItem__r.providerReferenceOrder__c, dimensions__c,
                                        orderItem__r.estimatedProductCost__c, orderItem__r.estimatedDeliveryDate__c, orderItem__r.providerLineNumber__c
                                    FROM Asset WHERE Id IN :assetsId];
        for(Asset asset : assetList){
            List<Map<String,String>> relatedProviders = new List<Map<String,String>>();
            Map<String,String> picklistDefaultAttribute = new Map<String,String>();
            Decimal estimatedProductCost = (asset.orderItem__r.estimatedProductCost__c != null) ? asset.orderItem__r.estimatedProductCost__c : 0.0;
            String lineNumber = (asset.orderItem__r.providerLineNumber__c != null) ? asset.orderItem__r.providerLineNumber__c : null;  
            String providerReferenceOrder = (asset.orderItem__r.providerReferenceOrder__c != null) ? asset.orderItem__r.providerReferenceOrder__c : null;  
            Date estimatedDeliveryDate = (asset.orderItem__r.estimatedDeliveryDate__c != null) ? asset.orderItem__r.estimatedDeliveryDate__c : Date.today();
            picklistDefaultAttribute.put('label','-- Aucun fournisseur sélectionné --');
            picklistDefaultAttribute.put('value','');
            picklistDefaultAttribute.put('provId','');
            picklistDefaultAttribute.put('cout',String.valueOf(estimatedProductCost));
            picklistDefaultAttribute.put('dateL',String.valueOf(estimatedDeliveryDate));
            picklistDefaultAttribute.put('lineNumber',String.valueOf(lineNumber));
            picklistDefaultAttribute.put('providerReferenceOrder',String.valueOf(providerReferenceOrder));
            System.debug('## picklistDefaultAttribute: '+picklistDefaultAttribute);
            relatedProviders.add(picklistDefaultAttribute);            
            // Création de la liste des fournisseurs pour l'actifs
            // Si SAV on récupère tous les fournisseurs, sinon on récupère ceux du produit
            if(isAfterSalesService){
                for(Account providerAcc : providersList){
                    Map<String,String> picklistAttributes = new Map<String,String>();
                    picklistAttributes.put('label',providerAcc.Name);
                    picklistAttributes.put('value',providerAcc.Id);
                    picklistAttributes.put('provId',providerAcc.Id);
                    picklistAttributes.put('cout',String.valueOf(estimatedProductCost));
                    picklistAttributes.put('dateL',String.valueOf(estimatedDeliveryDate));
                    picklistAttributes.put('lineNumber',String.valueOf(lineNumber));
                    picklistAttributes.put('providerReferenceOrder',String.valueOf(providerReferenceOrder));
                    System.debug('## picklistAttributes: '+picklistAttributes);
                    relatedProviders.add(picklistAttributes);
                }    
            } else {     
                for(Product_Provider__c prodSup : providerProductList){
                    if(prodSup.product__c == asset.Product2Id){
                        Map<String,String> picklistAttributes = new Map<String,String>();
                        picklistAttributes.put('label',prodSup.provider__r.Name);
                        picklistAttributes.put('value',prodSup.Id);
                        picklistAttributes.put('provId',prodSup.provider__c);
                        picklistAttributes.put('cout',String.valueOf(estimatedProductCost));
                        picklistAttributes.put('dateL',String.valueOf(estimatedDeliveryDate));
                        picklistAttributes.put('lineNumber',String.valueOf(lineNumber));
                        picklistAttributes.put('providerReferenceOrder',String.valueOf(providerReferenceOrder));
                        System.debug('## picklistAttributes: '+picklistAttributes);
                        relatedProviders.add(picklistAttributes);
                    }
                }
            }
            System.debug('## estimatedProductCost : ' + estimatedProductCost);
            System.debug('## estimatedDeliveryDate : ' + estimatedProductCost);
            result.add(new ProductProvider(asset, asset.dimensions__c, asset.Id, asset.Name, asset.ProductCode, estimatedProductCost, 
                                            estimatedDeliveryDate, lineNumber, '',providerReferenceOrder, relatedProviders));
        }
   
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderWizard.getProviders'); 
        return result;
    }

    /**
    * @description Récupération de la liste des fournisseurs d'un produit
    * @param selectedSupList Liste des Id des ProductProvider
    * @param isAfterSalesService True si concerne une commande SAV
    * @return Liste des fournisseurs
    */
    @AuraEnabled(Cacheable = true)
    public static List<ProductProvider> getSelectedProductProviders(List<Map<String,String>> selectedSupList, Boolean isAfterSalesService){
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.getSelectedProviders'); 
        System.debug('## selectedSupList: '+selectedSupList); 
        System.debug('## isAfterSalesService: '+isAfterSalesService); 
        List<ProductProvider> result = new List<ProductProvider>();
        List<String> assetsIdList = new List<String>();
        List<String> accProvidersIdList = new List<String>();
        System.debug('## assetsIdList: '+assetsIdList);
        List<String> productProvidersIdList = new List<String>();
        List<String> providersIdList = new List<String>();
        Map<String, Asset> assetsMap;
        Map<String, Product_Provider__c> productProviderMap;
        Map<String, Account> accProviderMap;
        
        // Récupération des valeurs saisies par l'utilsateur (Id Fournisseur + Id Asset)
        for(Map<String,String> mapValue : selectedSupList){
            productProvidersIdList.add(mapValue.get('value'));
            assetsIdList.add(mapValue.get('id'));
            accProvidersIdList.add(mapValue.get('provId'));
        }  
        System.debug('## assetsIdList: '+assetsIdList);      
        if(!assetsIdList.isEmpty()) {
            assetsMap = new Map<String, Asset>([SELECT Id, Name, ProductCode, Product2Id, Quantity, unit__c, dimensions__c FROM Asset WHERE Id IN :assetsIdList]);
            System.debug('## assetsIdList: '+assetsIdList);
            System.debug('## assetsMap: '+assetsMap);
        }
         
        // Récupération infos fournisseurs des produits
        if(!productProvidersIdList.isEmpty()) {
            if(isAfterSalesService) {            
                accProviderMap = new Map<String, Account>([SELECT Id, Name FROM Account WHERE Id IN :productProvidersIdList OR Id IN :accProvidersIdList]);
                System.debug('## accProviderMap: '+accProviderMap);       
            } else {
                productProviderMap = new Map<String, Product_Provider__c>([SELECT Id, provider__c, provider__r.Name, product__c 
                                                                            FROM Product_Provider__c WHERE Id IN :productProvidersIdList]);
                System.debug('## productProviderMap: '+productProviderMap);       
            }
        }
        
        // Construction liste de résultat        
        for(Map<String,String> mapValue : selectedSupList){
            System.debug('## mapValue: '+ mapValue);      
            // Init
            String providerName = null;
            String providerId = null;
            // Valeurs
            Asset ast = assetsMap.get(mapValue.get('id')); 
            System.debug('## ast: '+ ast);          
            Decimal cout = (String.isNotBlank(mapValue.get('cout'))) ? Integer.valueOf(mapValue.get('cout')) : null;
            String lineNumber = (String.isNotBlank(mapValue.get('lineNumber'))) ? String.valueOf(mapValue.get('lineNumber')) : null;
            String provId = (String.isNotBlank(mapValue.get('provId'))) ? String.valueOf(mapValue.get('provId')) : null;
            String providerReferenceOrder = (String.isNotBlank(mapValue.get('providerReferenceOrder'))) ? String.valueOf(mapValue.get('providerReferenceOrder')) : null;
            Date dateL = (String.isNotBlank(mapValue.get('dateL'))) ? Date.valueOf(mapValue.get('dateL')) : null;
            if(isAfterSalesService) {
                Account accProvider = (String.isNotBlank(mapValue.get('provId'))) ? accProviderMap.get(mapValue.get('provId')) : null;
                if(accProvider != null) {
                    providerName = accProvider.Name;
                    providerId = accProvider.Id;
                }
            } else {
                Product_Provider__c prodProvider = (String.isNotBlank(mapValue.get('value'))) ? productProviderMap.get(mapValue.get('value')) : null;
                if(prodProvider != null) {
                    providerName = prodProvider.provider__r.Name;
                    providerId = prodProvider.provider__c;
                }
            }
            // Ajout dans la liste
            result.add(new ProductProvider(ast, ast.dimensions__c, ast.Id, ast.Name, ast.ProductCode, providerId,
                                            providerName, cout, dateL, lineNumber, provId, providerReferenceOrder, ast.Product2Id));
        }
    
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderWizard.getSelectedProviders'); 
        return result;
    }
    
    /**
    * @description Création des enregistrements "Commande fournisseur" et "Produit Commandé"
    * @param selectedSupList Liste des ProductProvider
    * @param customerOrderId Id de la commande client
    * @return Liste des Id des commandes fournisseurs
    */
    @AuraEnabled
    public static List<String> createOrders(List<Map<String,String>> selectedSupList, String recordId, Date transmissionDate, 
                                                String transmissionReason, String orderType, Date confirmationDate, List<Map<String,String>> unknownProducts,
                                                Boolean isAfterSalesService, String objectApiName, String responsability){
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.createOrders');
        System.debug('### selectedSupList :' + selectedSupList);        
        Map <String, String> mapOrderProvider = new Map<String, String>();
        Map <String, String> mapProductCodePBE = new Map<String, String>();
        Map <String, String> mapOrderIdRefProvider = new Map<String, String>();
        List<Order> ordersToInsert = new List<Order>();
        List<Order> ordersToUpdate = new List<Order>();
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        Set<String> providersIdList = new Set<String>();
        List<String> productCodeList = new List<String>();
        List<String> resultTotal = new List<String>();
        Order customerOrder = new Order();
        Case ncp = new Case();
        String approverId = null;
        String customerOrderId = null;
        String ncpId = null;
        System.debug('## selectedSupList : ' + selectedSupList);
        System.debug('## unknownProducts : ' + unknownProducts);
        
        // Sauvegarde transaction
        Savepoint sp = Database.setSavepoint();  

        try {       
            // Calcul date min en transmission et confirmation
            Date orderDate = Date.today();
            if (confirmationDate != null && transmissionDate != null) orderDate = (confirmationDate < transmissionDate) ? confirmationDate : transmissionDate;
            else if (confirmationDate != null) orderDate = confirmationDate;
            else if (transmissionDate != null) orderDate = transmissionDate;

            

            if(objectApiName == 'Order'){
                // Récupération des infos de la commande client
                customerOrderId = recordId;
                customerOrder = [SELECT Id, Pricebook2Id, AccountId, QuoteId, serviceEntity__c, serviceEntity__r.enabledProviderOrderApprovalProcess__c, 
                provider__c, serviceEntity__r.queueId__c, entityServiceQueueId__c, afterSalesService__c
                FROM Order WHERE Id = :customerOrderId LIMIT 1];

                System.debug('## customerOrder : ' + customerOrder);
            } else if(objectApiName == 'Case'){
                // Récupération des infos de la non conformité produit
                ncpId = recordId;
                system.debug('recordId : '+recordId);
                ncp = [SELECT Id, entity__c, entity__r.queueId__c, entity__r.enabledProviderOrderApprovalProcess__c, 
                                customerOrder__c, customerOrder__r.Pricebook2Id, Chantier__c, Chantier__r.serviceEntity__c, Type, RecordTypeId, responsability__c
                FROM Case WHERE Id = :ncpId LIMIT 1]; 
            }          
            
            // Récupération du RT
            String providerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);
            
            // Récupération des produits et fournisseurs
            List<ProductProvider> productProviders = getSelectedProductProviders(selectedSupList, isAfterSalesService);
            System.debug('## productProviders : ' + productProviders);
            for(ProductProvider pProvider : productProviders){
                providersIdList.add(pProvider.supId);
                productCodeList.add(pProvider.productCode);
            }
            productCodeList.add('INCONNU');
            // Récupération du catalogue de prix par code produit et 
            List<PriceBookEntry> priceBookEntryList = [SELECT Id, ProductCode FROM PriceBookEntry WHERE ProductCode IN :productCodeList];        
            List<Pricebook2> priceBook2Standard = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            for(PriceBookEntry pBookEntry : priceBookEntryList) {
                mapProductCodePBE.put(pBookEntry.ProductCode, pBookEntry.Id);
            }
            // Récupération fournisseur pour produit inconnu            
            if(!unknownProducts.isEmpty()) {
                for(Map<String, String> unknownProduct : unknownProducts){
                    providersIdList.add(unknownProduct.get('supId'));
                }
            }
            System.debug('## Providers Id: ' + providersIdList);
            
            // Création de commande pour chaque fournisseurs
            for(String provider : providersIdList){
                Order newOrder = new Order();
                System.debug('## Create order for provider: ' + provider);

                System.debug('## objectApiName: ' + objectApiName);
                System.debug('## customerOrder: ' + customerOrder);
                System.debug('## customerOrder.serviceEntity__c: ' + customerOrder.serviceEntity__c);

                if(objectApiName == 'Order'){
                    newOrder.parentOrder__c = customerOrder.Id;
                    newOrder.QuoteId = customerOrder.QuoteId;
                    newOrder.AccountId = customerOrder.serviceEntity__c; 
                    newOrder.Pricebook2Id = customerOrder.Pricebook2Id;
                    newOrder.isValid__c = true;
                    if (responsability != null && orderType == 'Recommande marchandise') {
                        newOrder.responsability__c = responsability;
                    }
                    if (customerOrder.afterSalesService__c != null) {
                        newOrder.afterSalesService__c = customerOrder.afterSalesService__c;
                        System.debug('Dossier SAV : '+newOrder.afterSalesService__c);
                    }
                } else if(objectApiName == 'Case'){
                    newOrder.AccountId = ncp.entity__c;
                    newOrder.productNonCompliance__c = ncp.Id;
                    if(Test.isRunningTest() && newOrder.AccountId == null){
                        newOrder.AccountId = ncp.chantier__r.serviceEntity__c;
                    }
                    //Si NCP de type ECI renseigne la commande client en tant que commande parent sur la nouvelle commande fournisseur
                    if(String.isNotBlank(ncp.customerOrder__c)) {
                        if(ncp.Type=='ECI') {
                            newOrder.parentOrder__c = ncp.customerOrder__c;
                        }
                    }
                    if(String.isNotBlank(ncp.customerOrder__c) && String.isNotBlank(ncp.customerOrder__r.Pricebook2Id)){
                        newOrder.Pricebook2Id = ncp.customerOrder__r.Pricebook2Id;
                    } else {
                        newOrder.Pricebook2Id = priceBook2Standard[0].Id;
                    }
                    // alimentation de la responsabilité à partir de la ncp
                    newOrder.responsability__c = responsability;                   
                }
                newOrder.provider__c = provider;            
                newOrder.EffectiveDate = orderDate;
                newOrder.RecordTypeId = providerOrderRTId;
                newOrder.Status = 'Registered';
                newOrder.stageName__c = 'Enregistrement';
                newOrder.Type = orderType;
                System.debug('## newOrder: ' + newOrder);
                ordersToInsert.add(newOrder);
            }
            
            if(!ordersToInsert.isEmpty()) {
                System.debug('## Orders to insert: ' + ordersToInsert);
                insert ordersToInsert;
                for(Order newOrder : ordersToInsert) {
                    System.debug('## newOrder Id: ' + newOrder.Id);
                    resultTotal.add(newOrder.Id);
                }
            }
            
            // Création de Produit Commandé pour chaque ProductProvider(Asset)            
            for(Order newOrder : ordersToInsert) {
                mapOrderProvider.put(newOrder.provider__c, newOrder.Id);
            }
            for(ProductProvider pProvider : productProviders){
                String orderId = mapOrderProvider.get(pProvider.supId);
                System.debug('## Create order item for order: ' + orderId);
                System.debug('## AssetId: ' + pProvider.assetId);
                System.debug('## ProductId: ' + pProvider.productId);
                System.debug('## ProductCode: ' + pProvider.productCode);
                System.debug('## Quantity: ' + pProvider.asset.Quantity);
                OrderItem newOrderItem = new OrderItem();
                newOrderItem.name__c = pProvider.productCode;
                newOrderItem.asset__c = pProvider.assetId;
                newOrderItem.Product2Id = pProvider.productId;
                newOrderItem.OrderId = orderId;
                newOrderItem.UnitPrice = 0;
                newOrderItem.Quantity = pProvider.asset.Quantity;
                newOrderItem.unit__c = pProvider.asset.unit__c;
                newOrderItem.providerLineNumber__c = pProvider.lineNumber;
                newOrderItem.providerReferenceOrder__c = pProvider.providerReferenceOrder;
                newOrderItem.PricebookEntryId = mapProductCodePBE.get(pProvider.productCode);
                if(!mapOrderIdRefProvider.containsKey(orderId)) {
                    mapOrderIdRefProvider.put(orderId, pProvider.providerReferenceOrder);
                }
                if(objectApiName == 'Case'){
                    newOrderItem.productDescription__c = pProvider.productCode;
                }
                System.debug('## newOrderItem: ' + newOrderItem);
                orderItemsToInsert.add(newOrderItem);
            }
            
            if(!unknownProducts.isEmpty()) {
                for(Map<String, String> unknownProduct : unknownProducts){
                    String orderId = mapOrderProvider.get(unknownProduct.get('supId'));
                    System.debug('## Create order item for order: ' + orderId);
                    System.debug('## AssetId: ' + unknownProduct.get('assetId'));
                    System.debug('## ProductId: ' + unknownProduct.get('productId'));
                    OrderItem newOrderItem = new OrderItem();
                    newOrderItem.name__c = 'INCONNU';
                    newOrderItem.Description = unknownProduct.get('description');
                    newOrderItem.productDescription__c = unknownProduct.get('description');
                    newOrderItem.asset__c = null;
                    newOrderItem.Product2Id = unknownProduct.get('productId');
                    newOrderItem.OrderId = orderId;
                    newOrderItem.UnitPrice = 0;
                    newOrderItem.Quantity = (String.isNotBlank(unknownProduct.get('quantity'))) ? Decimal.valueOf(unknownProduct.get('quantity')) : null;
                    newOrderItem.unit__c = 'UNIT';
                    newOrderItem.productType__c = 'Accessory';
                    newOrderItem.providerLineNumber__c = unknownProduct.get('lineNumber');
                    newOrderItem.providerReferenceOrder__c = unknownProduct.get('providerReferenceOrder');
                    newOrderItem.PricebookEntryId = mapProductCodePBE.get('INCONNU');
                    //newOrderItem.estimatedProductCost__c = (String.isNotBlank(unknownProduct.get('productCostPrev'))) ? Decimal.valueOf(unknownProduct.get('productCostPrev')) : null;
                    //newOrderItem.estimatedDeliveryDate__c = (String.isNotBlank(unknownProduct.get('deliveryDatePrev'))) ? Date.valueOf(unknownProduct.get('deliveryDatePrev')) : null;
                    if(!mapOrderIdRefProvider.containsKey(orderId)) {
                        mapOrderIdRefProvider.put(orderId, unknownProduct.get('providerReferenceOrder'));
                    }
                    System.debug('## newOrderItem: ' + newOrderItem);
                    orderItemsToInsert.add(newOrderItem);
                }
            }
            
            for(Order newOrder : ordersToInsert) {
                newOrder.transmissionDate__c = transmissionDate;
                newOrder.transmissionChannel__c = transmissionReason;
                if(mapOrderIdRefProvider.get(newOrder.id) != null) {
                    newOrder.providerReference__c = mapOrderIdRefProvider.get(newOrder.id);
                    System.debug('## Order ProviderReference: ' + newOrder.providerReference__c);
                }
                if(orderDate != Date.today()) {
                    newOrder.ActivatedDate = orderDate;
                    newOrder.firstActivatedDate__c = orderDate;
                    System.debug('## Order ActivatedDate: ' + orderDate);
                }
                System.debug('## Order changed: '+newOrder);
                ordersToUpdate.add(newOrder);
            }
            
            if(!orderItemsToInsert.isEmpty()) {
                System.debug('## OrderItems to insert: ' + orderItemsToInsert);
                insert orderItemsToInsert;
            }
            
            if(!ordersToUpdate.isEmpty()) {
                System.debug('## Orders to update: ' + ordersToUpdate);
                update ordersToUpdate;
            }
                               
            // Alimentation données de la ligne
            for(OrderItem newOrderItem : orderItemsToInsert) {
                for(ProductProvider pProvider : productProviders){
                    if(newOrderItem.asset__c == pProvider.assetId) {
                        System.debug('transmissionDate : '+newOrderItem.transmissionDate__c);
                        newOrderItem.estimatedProductCost__c = pProvider.productCostPrev;
                        newOrderItem.estimatedDeliveryDate__c = pProvider.deliveryDatePrev;
                        newOrderItem.confirmationDate__c = confirmationDate;
                        System.debug('## newOrderItem: ' + newOrderItem);
                        orderItemsToUpdate.add(newOrderItem);
                    }
                }
                if(!unknownProducts.isEmpty()) {
                    for(Map<String, String> unknownProduct : unknownProducts){
                        if(newOrderItem.Description == unknownProduct.get('description') && newOrderItem.providerLineNumber__c == unknownProduct.get('lineNumber')) {
                            if(unknownProduct.get('deliveryDatePrev') != null) {
                                newOrderItem.estimatedDeliveryDate__c = date.valueOf(unknownProduct.get('deliveryDatePrev'));
                            }
                            if(unknownProduct.get('productCostPrev') != null) {
                                newOrderItem.estimatedProductCost__c = Decimal.valueOf(unknownProduct.get('productCostPrev'));
                            }
                            newOrderItem.confirmationDate__c = confirmationDate;   
                            System.debug('## newOrderItem: ' + newOrderItem);       
                            orderItemsToUpdate.add(newOrderItem);
                        }
                    }
                }
            }
            
            if(!orderItemsToUpdate.isEmpty()) {
                System.debug('## OrderItems to update: ' + orderItemsToUpdate);
                update orderItemsToUpdate;
            }
            
            // Lancement des processus d'approbation
            ordersToUpdate.clear();
            approverId = ncp.entity__r.queueId__c;
            if(ncp.entity__r.enabledProviderOrderApprovalProcess__c == true) {
                for(Order newOrder : ordersToInsert) {
                    System.debug('## Execute ApprovalProcess : PA_ProviderOrder_Validation');
                    System.debug('## Approver: ' + newOrder.entityServiceQueueId__c);
                    List<Id> approverIds = new List<Id>();
                    approverIds.add(approverId);
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setObjectId(newOrder.id);
                    req1.setProcessDefinitionNameOrId('PA_ProviderOrder_Validation');
                    req1.setSkipEntryCriteria(true);
                    req1.setNextApproverIds(approverIds);
                    Approval.ProcessResult result = Approval.process(req1);
                }
            } else {
                for(Order newOrder : ordersToInsert) {
                    System.debug('## No Approval process : Validation');
                    newOrder.isValid__c = true;
                    ordersToUpdate.add(newOrder);
                }
            }
            
            if(!ordersToUpdate.isEmpty()) {
                System.debug('## Orders to update: ' + ordersToUpdate);
                update ordersToUpdate;
            }
            
            System.debug('### FIN LWC_CustomProviderOrderWizard.createOrders');
            return resultTotal;
        }
        catch(Exception e) {
            Database.rollback( sp ); // Rollback des modifications
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }

    /**
    * @description Récupération de la liste des fournisseurs par actifs pour les produits
    * @param assetsId Liste des Id des assets
    * @return Liste des fournisseurs
    */
    private static List<Product_Provider__c> queryProductProviders(List<String> assetsId, String objectApiName) {
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.queryProductProviders'); 
        System.debug('## assetsId: '+assetsId); 
        List<Product_Provider__c> result = new List<Product_Provider__c>();
        List<String> assetProductList = new List<String>();

        List<Asset> assetList = [SELECT Id, Product2Id, customerOrder__r.serviceEntity__c FROM Asset WHERE Id IN :assetsId];
        String serviceEntityId = assetList[0].customerOrder__r.serviceEntity__c;
        System.debug('## serviceEntityId: '+serviceEntityId); 

        // Récupération des fournisseurs pour chaque produit sélectionné
        for(Asset a : assetList){
            System.debug('## a.Product2Id: '+a.Product2Id);
            assetProductList.add(a.Product2Id);
        }
        if(!assetProductList.isEmpty()) {
            if(objectApiName == 'Order'){
                List<Product2> prodList = [SELECT Id FROM Product2 WHERE Id IN :assetProductList];
                for(Product_Provider__c prodSup : [SELECT Id, provider__c, provider__r.Name, product__c, product__r.Id, startDate__c, endDate__c
                                                FROM Product_Provider__c
                                                WHERE product__c IN :prodList 
                                                AND (startDate__c <= TODAY AND (endDate__c > TODAY OR endDate__c = null))
                                                AND (serviceEntity__c = null OR serviceEntity__c = '' OR serviceEntity__c =: serviceEntityId)
                                                ORDER BY provider__r.Name]) {
                    System.debug('## prodSup: '+prodSup);
                    result.add(prodSup);
                } 
            } else if(objectApiName == 'Case'){
                for(Product_Provider__c prodSup : [SELECT Id, provider__c, provider__r.Name, product__c, product__r.Id, startDate__c, endDate__c
                                                FROM Product_Provider__c
                                                WHERE (startDate__c <= TODAY AND (endDate__c > TODAY OR endDate__c = null))
                                                AND (serviceEntity__c = null OR serviceEntity__c = '' OR serviceEntity__c =: serviceEntityId)
                                                ORDER BY provider__r.Name]) {
                    System.debug('## prodSup: '+prodSup);
                    result.add(prodSup);
                } 
            }
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderWizard.queryProductProviders'); 
        return result;
    }
    
    /**
    * @description Récupération de la liste de tous les fournisseurs pour le produit inconnu
    * @return Liste des fournisseurs
    */
    private static List<Account> queryProductProvidersUnknown() {
        System.debug('### DEBUT LWC_CustomProviderOrderWizard.queryProductProvidersUnknown'); 
        List<Account> result = new List<Account>();
        String providerRT = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);

        // Récupération des fournisseurs 
        for(Account prodSup : [SELECT Id, Name, startDate__c, endDate__c
                                FROM Account WHERE RecordTypeId = :providerRT ORDER BY Name]) {
            System.debug('## prodSup: '+prodSup);
            result.add(prodSup);
        } 
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomProviderOrderWizard.queryProductProvidersUnknown'); 
        return result;
    }

    public class ProductProvider {
        private Asset asset;
        private String dimensions;
        private String assetId;
        private String assetName;
        private String productCode;
        private String productId;
        private String supName;
        private String supId;
        private String provId;
        private String lineNumber;
        private String providerReferenceOrder;
        private Decimal productCostPrev;
        private Date deliveryDatePrev;
        private Product_Provider__c productProvider;
        private List<Map<String,String>> providers;

        public ProductProvider(
            Asset asset,
            String dimensions,
            String assetId,
            String assetName,
            String productCode,
            String providerId,
            String providerName,
            Decimal productCostPrev,
            Date deliveryDatePrev,
            String lineNumber,
            String provId,
            String providerReferenceOrder,
            String productId
        ) {
            this.asset = asset;
            this.dimensions = dimensions;
            this.assetId = assetId;
            this.assetName = assetName;
            this.productCode = productCode;
            this.supName = providerName;
            this.supId = providerId;
            this.productProvider = productProvider;
            this.productCostPrev = productCostPrev;
            this.deliveryDatePrev = deliveryDatePrev;
            this.lineNumber = lineNumber;
            this.provId = provId;
            this.providerReferenceOrder = providerReferenceOrder;
            this.productId = productId;
        }
        
        public ProductProvider(
            Asset asset,
            String dimensions,
            String assetId,
            String assetName,
            String productCode,
            Decimal productCostPrev,
            Date deliveryDatePrev,
            String lineNumber,
            String provId,
            String providerReferenceOrder,
            List<Map<String,String>> providers
        ) {
            this.asset = asset;
            this.dimensions = dimensions;
            this.assetId = assetId;
            this.assetName = assetName;
            this.productCode = productCode;
            this.productCostPrev = productCostPrev;
            this.deliveryDatePrev = deliveryDatePrev;
            this.lineNumber = lineNumber;
            this.provId = String.valueOf(providers[0].get('provId'));
            this.providerReferenceOrder = providerReferenceOrder;
            this.supName = providers[0].get('label');
            this.supId = providers[0].get('value');
            if(providers.size() == 2){
                this.supName = providers[1].get('label');
                this.supId = providers[1].get('value');
                this.provId = String.valueOf(providers[1].get('provId'));
            }
            this.providers = providers;
        }

        @AuraEnabled
        public String getAssetId() {
            return assetId;
        }
        
        @AuraEnabled
        public String getDimensions() {
            return dimensions;
        }

        @AuraEnabled
        public String getAssetName() {
            return assetName;
        }

        @AuraEnabled
        public String getProductCode() {
            return productCode;
        }

        @AuraEnabled
        public String getSupName() {
            return supName;
        }

        @AuraEnabled
        public String getSupId() {
            return supId;
        }
        
        @AuraEnabled
        public Decimal getProductCostPrev() {
            return productCostPrev;
        }
        
        @AuraEnabled
        public Date getDeliveryDatePrev() {
            return deliveryDatePrev;
        }
        
        @AuraEnabled
        public String getLineNumber() {
            return lineNumber;
        }
        
        @AuraEnabled
        public String getProvId() {
            return provId;
        }
        
        @AuraEnabled
        public String getProviderReferenceOrder() {
            return providerReferenceOrder;
        }

        @AuraEnabled
        public List<Map<String,String>> getProviders() {
            return providers;
        }
    }
    
    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }

    @AuraEnabled
    public static string getNcpResponsability(String recordId, String objectApiName){
        String result;
        try {
            if (objectApiName == 'Case') {
                Case ncp = [SELECT Id, responsability__c FROM Case WHERE Id = :recordId LIMIT 1];
                result = ncp.responsability__c;
            }  
            return result;          
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}