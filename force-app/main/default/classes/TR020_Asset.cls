//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Asset
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 16/06/2023
//-- Version     : 1.1
//-- * 1.1 - Optimisation
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Asset { 
    private static final String NCC_IMPOSSIBILITY_RTID = DAL.getRecordTypeIdByDevName('OrderNonCompliance__c', 'Impossibility');
    
    /**
    * @description Méthode exécutant les différentes règles de validation pour les actifs
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Asset.applyValidationRules');
        
        System.debug('Userinfo.getUserId() : ' + UserInfo.getUserId());
        
        List<PermissionSetAssignment> psa = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'delete_asset'];
        Profile usrProfile = [SELECT Id,Name FROM Profile WHERE Id=:UserInfo.getProfileId() LIMIT 1];

        if(Trigger.isDelete && Trigger.isBefore && psa.isEmpty() && usrProfile.Name != 'Administrateur système'){
            List<Asset> oldAssets = (List<Asset>)Trigger.old;
            List<String> firstLevelAssetIds = new List<String>();
            for(Asset oldAsset : oldAssets){
                // Ne pas supprimer si l'actif est verrouillé
                if((oldAsset.isParentLock__c || oldAsset.isLocked__c)){
                    oldAsset.addError(Label.asset_msg_cantDeleteAsset);
                }

                if(oldAsset.parent == null && !firstLevelAssetIds.contains(oldAsset.Id)){
                    firstLevelAssetIds.add(oldAsset.Id);
                }
            }

            Map<String,Asset> allAssetParentsData = new Map<String,Asset>([SELECT id, customerOrder__c, (SELECT id FROM Cases),
            (SELECT id FROM InvoiceLines__r),
            (SELECT id FROM CreditMemoLines__r),
            (SELECT id FROM orderedProducts__r),
            (SELECT id FROM WorkOrderLineItems),
            (SELECT id FROM Entitlements)
            FROM Asset
            WHERE id IN :firstLevelAssetIds]);
            
            for(Asset ast : (List<Asset>)Trigger.old){
                Asset astData = allAssetParentsData.get(ast.Id);
                if(astdata.customerOrder__c != null ||
                    !astData.Cases.isEmpty() ||
                    !astData.InvoiceLines__r.isEmpty() ||
                    !astData.CreditMemoLines__r.isEmpty() ||
                    !astData.orderedProducts__r.isEmpty() ||
                    !astData.WorkOrderLineItems.isEmpty() ||
                    !astData.Entitlements.isEmpty()){
                        ast.addError(Label.asset_msg_cantDeleteAssetWithRessource);	
                    }
            }
        }
        System.debug('### FIN TR020_Asset.applyValidationRules');
    }
    
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les actifs
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        applyDataUpdateRules(userContext);
        //applyStatusUpdateRules(userContext);
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les actifs
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Asset.applyUpdateRules');
        
        if (!Trigger.isExecuting) {
            return;
        }
        
        Map<Id, Asset> oldAssets = (Map<Id, Asset>)Trigger.oldMap;
        List<String> chantiersId = new List<String>();     
        List<String> orderItemsId = new List<String>();
        List<String> orderId = new List<String>();      
        List<String> nccOrderId = new List<String>();      
        List<String> accountsId = new List<String>();    
        Map<Id, Chantier__c> chantiersMap = new Map<Id, Chantier__c>();
        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>();
        Map<Id, Order> orderMap = new Map<Id, Order>();
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        Map<Id,List<OrderNonCompliance__c>> idOrderToNccMap = new Map<Id,List<OrderNonCompliance__c>>();
        
        // A - Initialisation des données intermédiaires 
        for (Asset newAsset : (List<Asset>)Trigger.new) {
            //if (!AlreadyUsed.isUsed('TR020_Asset.applyUpdateRules', newAsset.id)) {                
                Asset oldAsset = oldAssets == null ? null : oldAssets.get(newAsset.Id);

                // Alimentation des champs par rapport aux commandes clients
                if(Trigger.isBefore && String.isNotBlank(newAsset.customerOrder__c) && String.isBlank(newAsset.chantier__c)
                    && (Trigger.isInsert || (Trigger.isUpdate && oldAsset != null /*&& oldAsset.customerOrder__c != newAsset.customerOrder__c*/)) ) 
                {
                    orderId.add(newAsset.customerOrder__c);
                }
                
                if(Trigger.isBefore && Trigger.isUpdate && String.isNotBlank(newAsset.customerOrder__c))
                {
                    nccOrderId.add(newAsset.customerOrder__c);
                }

                // Alimentation des champs par rapport aux lignes de commandes clients
                if(Trigger.isBefore && String.isNotBlank(newAsset.orderItem__c ) 
                    && (Trigger.isInsert || (Trigger.isUpdate && oldAsset != null && oldAsset.orderItem__c != newAsset.orderItem__c)) ) 
                {
                    orderItemsId.add(newAsset.orderItem__c);
                }
                // Alimentation du compte par rapport au chantier si pas de commande client 
                if(Trigger.isBefore && String.isBlank(newAsset.customerOrder__c) && String.isBlank(newAsset.AccountId) && String.isNotBlank(newAsset.chantier__c) 
                    && (Trigger.isInsert || (Trigger.isUpdate && oldAsset != null && oldAsset.chantier__c != newAsset.chantier__c)) ) 
                {
                    chantiersId.add(newAsset.chantier__c);
                }
                // Alimentation du compte par rapport au contact si pas de commande client et de chantier
                if(Trigger.isBefore && String.isBlank(newAsset.customerOrder__c) && String.isNotBlank(newAsset.AccountId) && String.isBlank(newAsset.chantier__c) 
                    && String.isBlank(newAsset.ContactId) && (Trigger.isInsert || (Trigger.isUpdate && oldAsset != null && oldAsset.AccountId != newAsset.AccountId)) ) 
                {
                    accountsId.add(newAsset.AccountId);
                }
            //}
        }

        if(!orderId.isEmpty()) {
            orderMap = new Map<Id, Order>([SELECT Id, AccountId,
                                                    chantier__r.proprietaire__c, chantier__r.proprietaire__r.PersonContactId,
                                                    chantier__r.proprietaire__r.contactParDefaut__c, 
                                                    chantier__r.proprietaire__r.IsPersonAccount
                                                    FROM Order WHERE Id IN :orderId]);
        }
        
        if(!nccOrderId.isEmpty()) {
            List<OrderNonCompliance__c> allNCC = [SELECT Id, customerOrder__c, closeDate__c, duration__c, RecordTypeId 
                                                FROM OrderNonCompliance__c WHERE customerOrder__c IN :nccOrderId];
            if(!allNCC.isEmpty()){
                for(OrderNonCompliance__c ncc : allNCC){
                    List<OrderNonCompliance__c> nccOrderList = new List<OrderNonCompliance__c>();
                    if(idOrderToNccMap.get(ncc.customerOrder__c) != null){
                        nccOrderList = idOrderToNccMap.get(ncc.customerOrder__c);
                    } 
                    nccOrderList.add(ncc);
                    idOrderToNccMap.put(ncc.customerOrder__c, nccOrderList);
                }
            }
            
        } 
        
        if(!orderItemsId.isEmpty()) {
            orderItemsMap = new Map<Id, OrderItem>([SELECT Id, Order.AccountId, Order.BillToContactId, Order.serviceEntity__c, Order.EffectiveDate, 
                                                    Order.chantier__c, height__c, leaf__c, location__c, locationPrecision__c, width__c, Quantity,
                                                    Order.chantier__r.proprietaire__c, Order.chantier__r.proprietaire__r.PersonContactId, unit__c,
                                                    Order.chantier__r.proprietaire__r.contactParDefaut__c, Order.chantier__r.proprietaire__r.IsPersonAccount,
                                                    UnitPrice, thermalCoefficients__c
                                                    FROM OrderItem WHERE Id IN :orderItemsId]);
        }
        if(!chantiersId.isEmpty()) {
            chantiersMap = new Map<Id, Chantier__c>([SELECT Id, proprietaire__c, proprietaire__r.PersonContactId, proprietaire__r.contactParDefaut__c, 
                                                     proprietaire__r.IsPersonAccount FROM Chantier__c WHERE Id IN :chantiersId]);
        }
        if(!accountsId.isEmpty()) {
            accountsMap = new Map<Id, Account>([SELECT Id, IsPersonAccount, PersonContactId, contactParDefaut__c FROM Account WHERE Id IN :accountsId]);
        }
        System.debug('## orderMap: ' + orderMap);
        System.debug('## orderItemsMap: ' + orderItemsMap);
        System.debug('## chantiersMap: ' + chantiersMap);
        System.debug('## accountsMap: ' + accountsMap);
        System.debug('## idOrderToNccMap: ' + idOrderToNccMap);

        // B - Application des règles de mise à jour 
        for (Asset newAsset : (List<Asset>)Trigger.new) {   
            Asset oldAsset = oldAssets == null ? null : oldAssets.get(newAsset.Id);
            
            // Alimentation des champs par rapport à la commandes client
            if((Trigger.isInsert || (Trigger.isUpdate && oldAsset != null && oldAsset.orderItem__c != newAsset.orderItem__c)) && 
                String.isNotBlank(newAsset.orderItem__c) && orderItemsMap != null && orderItemsMap.get(newAsset.orderItem__c) != null) 
            {      
                System.debug('## MAJ actif par rapport à la commande: ' + newAsset.Id + ' / ' +newAsset.orderItem__c);
                OrderItem assetOrderItem = orderItemsMap.get(newAsset.orderItem__c);
                System.debug('## OrderItem: ' + assetOrderItem);
                newAsset.AccountId = assetOrderItem.Order.AccountId;
                newAsset.ContactId = assetOrderItem.Order.BillToContactId;
                newAsset.AssetServicedById = assetOrderItem.Order.serviceEntity__c;
                newAsset.PurchaseDate = assetOrderItem.Order.EffectiveDate;
                newAsset.chantier__c = assetOrderItem.Order.chantier__c;
                newAsset.height__c = assetOrderItem.height__c;
                newAsset.width__c = assetOrderItem.width__c;
                newAsset.leaf__c = assetOrderItem.leaf__c;
                newAsset.location__c = assetOrderItem.location__c;
                newAsset.locationPrecision__c = assetOrderItem.locationPrecision__c;
                newAsset.Quantity = (assetOrderItem.unit__c == 'UNIT') ? 1 : assetOrderItem.Quantity;
                newAsset.IsInternal = true;
                newAsset.unit__c = assetOrderItem.unit__c;
                newAsset.thermalCoefficients__c = assetOrderItem.thermalCoefficients__c;
                System.debug('## Actif: ' + newAsset);
            }

            System.debug('## MAJ compte -> Commande: ' + String.isBlank(newAsset.chantier__c));
            System.debug('## MAJ compte -> Commande: ' + String.isNotBlank(newAsset.customerOrder__c));
            System.debug('## MAJ compte -> Commande: ' + String.isNotBlank(newAsset.orderItem__c));
            System.debug('## MAJ compte -> Commande: ' + orderItemsMap.get(newAsset.customerOrder__c));
                  
            // Alimentation du compte si pas de commande client par rapport au chantier
            if(/*String.isBlank(newAsset.AccountId) &&*/ String.isBlank(newAsset.chantier__c) && String.isNotBlank(newAsset.customerOrder__c) &&
                orderMap != null && orderMap.get(newAsset.customerOrder__c) != null) 
            {      
                System.debug('## MAJ compte -> Commande: ' + newAsset.Id);
                Order assetOrder = orderMap.get(newAsset.customerOrder__c);
                newAsset.chantier__c=assetOrder.chantier__c;
                if(String.isBlank(newAsset.AccountId)) {
                    newAsset.AccountId = assetOrder.chantier__r.proprietaire__c;
                    newAsset.ContactId = (assetOrder.chantier__r.proprietaire__r.IsPersonAccount) ? assetOrder.chantier__r.proprietaire__r.PersonContactId : assetOrder.chantier__r.proprietaire__r.contactParDefaut__c;
                }
            }

            if(String.isBlank(newAsset.AccountId) && String.isNotBlank(newAsset.chantier__c) 
                /*&& String.isBlank(newAsset.orderItem__c)*/ && chantiersMap != null && chantiersMap.get(newAsset.chantier__c) != null) 
            {      
                System.debug('## MAJ compte -> Chantier: ' + newAsset.Id);
                Chantier__c chantier = chantiersMap.get(newAsset.chantier__c);
                newAsset.AccountId = chantier.proprietaire__c;
                newAsset.ContactId = (chantier.proprietaire__r.IsPersonAccount) ? chantier.proprietaire__r.PersonContactId : chantier.proprietaire__r.contactParDefaut__c;
            }

            if(String.isNotBlank(newAsset.AccountId) && String.isBlank(newAsset.ContactId) 
                /*&& String.isBlank(newAsset.orderItem__c)*/ && accountsMap != null && accountsMap.get(newAsset.AccountId) != null) 
            {      
                System.debug('## MAJ contact -> Compte: ' + newAsset.Id);
                Account acc = accountsMap.get(newAsset.AccountId);
                newAsset.ContactId = (acc.IsPersonAccount) ? acc.PersonContactId : acc.contactParDefaut__c;
            }
            
            // Calcul des durées non-commandables/non-métrables des commandes clients
            if(Trigger.isUpdate)
            {
                List<OrderNonCompliance__c> orderNCC = idOrderToNccMap.get(newAsset.customerOrder__c);               
                if(orderNCC != null) {
                    Decimal notControlableDuration = 0;
                    Decimal notOrderableDuration = 0;
                    for(OrderNonCompliance__c ncc : orderNCC){
                        if(ncc.RecordTypeId == NCC_IMPOSSIBILITY_RTID && ncc.duration__c != null && newAsset.controlDate__c != null &&
                           ncc.closeDate__c != null){
                            if(ncc.closeDate__c <= newAsset.controlDate__c)
                            {
                                notControlableDuration += ncc.duration__c;
                            }
                            if(ncc.closeDate__c > newAsset.controlDate__c && newAsset.transmissionDate__c != null 
                                    && ncc.closeDate__c <= newAsset.transmissionDate__c)
                            {       
                                notOrderableDuration += ncc.duration__c;
                            }
                    	}
                    }
                    newAsset.notControlableDuration__c = notControlableDuration;
                    newAsset.notOrderableDuration__c = notOrderableDuration;
                }
            }

            // * CALCUL DU STATUT
            applyStatusUpdateRules(newAsset);
        }

        System.debug('### FIN TR020_Asset.applyUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les actifs
    * @param newAsset Actif à mettre à jour
    */
    //private static void applyStatusUpdateRules(UserContext userContext) {
    private static void applyStatusUpdateRules(Asset newAsset) {
        System.debug('### DEBUT TR020_Asset : applyStatusUpdateRules');
        
        //for (Asset newAsset : (List<Asset>)Trigger.new) {
            // Changement des status pour les asset parents
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {  
                if(String.isBlank(newAsset.ParentId)) {
                    System.debug('## Change status for asset parent: ' + newAsset.Id);
                    if(newAsset.IsCompetitorProduct == false) {
                        if(String.isNotBlank(newAsset.cancellingReason__c)) {
                            System.debug('## Asset status 1');
                            newAsset.Status = 'Annulé';
                            newAsset.stageName__c = 'Clôture';
                        } else if(newAsset.caseNCPNotCloseCount__c > 0) {
                            System.debug('## Asset status 2');
                            newAsset.Status = 'SAV';
                            newAsset.stageName__c = 'Garantie';
                        } else if(Date.today() > newAsset.UsageEndDate && String.isBlank(newAsset.cancellingReason__c)) {
                            System.debug('## Asset status 3');
                            newAsset.Status = 'Terminé';
                            newAsset.stageName__c = 'Clôture';
                        } else if(Date.today() >= newAsset.InstallDate) {
                            System.debug('## Asset status 4');
                            newAsset.Status = Constants.ASSET_STATUS_ENSERVICE;
                            newAsset.stageName__c = 'Garantie';
                        } else if (newAsset.providerOLINotCancelledDeliveredCount__c == newAsset.providerOLINotCancelledCount__c 
                            && newAsset.providerOLINotCancelledDeliveredCount__c > 0) 
                        {
                            System.debug('## Asset status 5');
                            newAsset.Status = Constants.ASSET_STATUS_LIVRE;
                            newAsset.stageName__c = 'Commande';
                        } else if (newAsset.providerOLINotCancelledTransmitedCount__c == newAsset.providerOLINotCancelledCount__c 
                            && newAsset.providerOLINotCancelledTransmitedCount__c > 0) 
                        {
                            System.debug('## Asset status 6');
                            newAsset.Status = Constants.ASSET_STATUS_COMMANDE;
                            newAsset.stageName__c = 'Commande';
                        } else if (Date.today() >= newAsset.controlDate__c) {
                            System.debug('## Asset status 7');
                            newAsset.Status = Constants.ASSET_STATUS_CONTROLE;
                            newAsset.stageName__c = 'Contrôle';
                        } else {
                            System.debug('## Asset status 8');
                            newAsset.Status = Constants.ASSET_STATUS_VALIDE;
                            newAsset.stageName__c = 'Enregistrement';
                        }
                        System.debug('## Asset Status: '+newAsset.Status);
                    } else if(newAsset.IsCompetitorProduct == true){
                        if(String.isNotBlank(newAsset.cancellingReason__c)) {
                            System.debug('## Asset status 1');
                            newAsset.Status = 'Annulé';
                            newAsset.stageName__c = 'Clôture';
                        } else if(newAsset.caseNCPNotCloseCount__c > 0) {
                            System.debug('## Asset status 2');
                            newAsset.Status = 'SAV';
                            newAsset.stageName__c = 'Garantie';
                        } else {
                            System.debug('## Asset status 3');
                            newAsset.Status = 'Terminé';
                            newAsset.stageName__c = 'Clôture';
                        }
                    }
                } else {
                    System.debug('## Change status for asset child: ' + newAsset.Id);
                    if(String.isNotBlank(newAsset.cancellingReason__c)) {
                        System.debug('## Asset status 1');
                        newAsset.Status = 'Annulé';
                        newAsset.stageName__c = 'Clôture';
                    } 
                }
                System.debug('## Asset Status: '+newAsset.Status);
            }
        //}
        System.debug('### FIN TR020_Asset : applyStatusUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour de données pour les requêtes legacy (GC)
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyLegacyUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Asset : applyLegacyUpdateRules');
        
        List<Asset> newAssets = new List<Asset>();
        List<String> assetAccountIds = new List<String>();
        
        // A - Initialisation des données intermédiaires 
        for (Asset newAsset : (List<Asset>)Trigger.new) {
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newAsset.legacyReference__c) && String.isNotBlank(newAsset.AccountId)) 
            {
                newAssets.add(newAsset);
                assetAccountIds.add(newAsset.AccountId);
            }
        }       

        // B - Récupération des enregistrements
        if(!newAssets.isEmpty()) {
            Map<String, Account> accountsMap = new Map<String, Account>();

            if(!assetAccountIds.isEmpty()) {
                for (Account acc : [SELECT Id, contactParDefaut__c FROM Account WHERE Id IN :assetAccountIds]) {
                    accountsMap.put(acc.Id, acc);
                }
                System.debug('## accountsMap: ' + accountsMap);
            }
            System.debug('## newAssets: ' + newAssets);

            for (Asset newAsset : newAssets) {
                // LEGACY - Alimentation ContactId            
                if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newAsset.legacyReference__c) && accountsMap.get(newAsset.AccountId) != null) {
                    newAsset.ContactId = accountsMap.get(newAsset.AccountId).contactParDefaut__c;
                }
            }
        }
        System.debug('### FIN TR020_Asset : applyLegacyUpdateRules');
    }  
}