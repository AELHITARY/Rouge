//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_OrderItem
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/06/2023
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_OrderItem {

    /**
    * @description Méthode appelée par les trigger pour ajouter/annuler les actifs lors d'un avenant
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void amendmentCancelOrAddAsset(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR022_OrderItem.amendmentCancelOrAddAsset');
        try {
            // A - Initialisation et alimentation des données intermédiaires
            List<OrderItem> newOrderItemsList = new List<OrderItem>();
            Map<Id, OrderItem> oldOrderItems = (Map<Id, OrderItem>)Trigger.oldMap;
            Map<String, List<Asset>> mapOrderItemAssets = new Map<String, List<Asset>>();
            List<OrderItem> orderItemsQtyUpList = new List<OrderItem>();
            List<OrderItem> orderItemsQtyDownList = new List<OrderItem>();
            List<OrderItem> assetsUpOrderItem = new List<OrderItem>();
            List<OrderItem> newAssetsOrderItem = new List<OrderItem>();
            List<Asset> assetsList = new List<Asset>();
            List<Asset> assetsToUpsert = new List<Asset>();
            List<Referencial__c> refList = new List<Referencial__c>();
            Set<String> orderItemUpIds = new Set<String>();
            Set<String> orderItemCancelIds = new Set<String>();
            
            // A - On récupère les ids de chaque OrderItem qui ont été révisé et modifié
            for (OrderItem newOrderItem : (List<OrderItem>)Trigger.new) {
                if(newOrderItem.orderRecordType__c == Constants.ORDER_RT_CUSTOMER && newOrderItem.StatutDeRevision__c == Constants.ORDERITEM_STATUTREVISION_UPDATED) {
                    OrderItem oldOrderItem = oldOrderItems == null ? null : oldOrderItems.get(newOrderItem.Id);
                    if(Trigger.isAfter && (Trigger.isInsert || (Trigger.isUpdate && oldOrderItem != null && oldOrderItem.StatutDeRevision__c != newOrderItem.StatutDeRevision__c )))
                    {
                        System.debug('## OrderItem : ' +newOrderItem.Id + ' - ' + newOrderItem.name__c);
                        System.debug('## parentOrderItem__c : ' +newOrderItem.parentOrderItem__c);
                        System.debug('## Quantité: ' +newOrderItem.Quantity+' / '+newOrderItem.assetAmendableCount__c+' / '+newOrderItem.assetQuantity__c);
                        newOrderItemsList.add(newOrderItem);
                        // Si nouveau produit, création actif
                        if(newOrderItem.Quantity != 0 && (newOrderItem.assetAmendableCount__c == 0 || newOrderItem.assetAmendableCount__c == null)) {
                            newAssetsOrderItem.add(newOrderItem);
                        } else if(newOrderItem.Quantity > newOrderItem.assetAmendableCount__c) {
                            // Si une la quantité a été augmenté, cloner l'actif associé
                            orderItemsQtyUpList.add(newOrderItem);
                        } else if(newOrderItem.Quantity < newOrderItem.assetAmendableCount__c) {
                            // Si une la quantité a été diminué, annulation
                            orderItemsQtyDownList.add(newOrderItem);
                        } else {
                            // Si pas de changement de quantité, modification paramètre
                            assetsUpOrderItem.add(newOrderItem);
                        } 
                    }
                }
            }
            
            System.debug('## orderItemsQtyUpList : ' +orderItemsQtyUpList.size());
            System.debug('## orderItemsQtyDownList : ' +orderItemsQtyDownList.size());
            System.debug('## assetsUpOrderItem : ' +assetsUpOrderItem.size());
            System.debug('## newAssetsOrderItem : ' +newAssetsOrderItem.size());

            // Pour les actifs à modifier
            if(!newOrderItemsList.isEmpty()) {
                // B - Récupération des actifs et référentiel
                assetsList = [SELECT Id, Status, UsageEndDate, cancellingReason__c, stageName__c, orderItem__c, Name, RecordTypeId,
                                customerOrder__c, AccountId, ContactId, chantier__c, Product2Id, IsInternal, location__c, RootAssetId,
                                AssetProvidedById, Price, IsCompetitorProduct, locationPrecision__c, ParentId, AssetLevel, AssetServicedById,
                                height__c, width__c, leaf__c, PurchaseDate, thermalCoefficients__c FROM Asset 
                                WHERE orderItem__c IN :newOrderItemsList AND Status != :Constants.ASSET_STATUS_ANNULE];
                for (Asset newAsset : assetsList) {
                    List<Asset> newAssetlist = mapOrderItemAssets.get(newAsset.orderItem__c);
                    if(newAssetlist == null) {
                        newAssetlist = new List<Asset>();
                    } 
                    newAssetlist.add(newAsset);
                    mapOrderItemAssets.put(newAsset.orderItem__c, newAssetlist);
                }

                if(!orderItemsQtyDownList.isEmpty()) {
                    String codeRef = PropertiesUtils.getStringValue('ref.motifAnnulationClient.code', 'RSL-0014');
                    refList = [SELECT Id FROM Referencial__c WHERE KparKReference__c = :codeRef LIMIT 1];
                }
            
                // C - Si la quantité a été augmenté, cloner l'actif associé
                for (OrderItem newOrderItem : orderItemsQtyUpList) {
                    if(newOrderItem.productConvertibleAsset__c) {
                        System.debug('## Clonage d\'actif pour la ligne : ' +newOrderItem.Id);
                        newAssetsOrderItem.add(newOrderItem);
                        // Ajout de l'OrderItem pour update ASYNC
                        orderItemUpIds.add(newOrderItem.Id);
                    }
                }

                // D - Si la quantité a été diminué, annulation des actifs Validé ou Contrôlé
                for (OrderItem newOrderItem : orderItemsQtyDownList) {
                    System.debug('## Annulation d\'actif pour la ligne : ' +newOrderItem.Id+ ' - ' + newOrderItem.name__c);
                    // Boucle par rapport à la quantité
                    Decimal index = 0;
                    Decimal nbLoop = Math.abs(newOrderItem.Quantity - newOrderItem.assetAmendableCount__c);
                    System.debug('## Nombre à annuler : ' +nbLoop);
                    List<Asset> newAssetlist = mapOrderItemAssets.get(newOrderItem.Id);
                    if(newAssetlist != null) {
                        for(Asset newAsset : newAssetlist) {
                            if(index < nbLoop) { 
                                System.debug('## Actif à annuler : ' +newAsset);
                                newAsset.UsageEndDate = Date.today();
                                newAsset.cancellingReason__c = (!refList.isEmpty()) ? refList[0].Id : null;
                                assetsToUpsert.add(newAsset);
                                index++;
                            }
                        }
                    }
                    // Ajout de l'OrderItem pour update ASYNC
                    orderItemUpIds.add(newOrderItem.Id);
                    // Annulation de la ligne de commande si plus d'actif (quantité = 0)
                    if(newOrderItem.Quantity == 0) {   
                        System.debug('## OrderItem à annuler : ' +newOrderItem);     
                        // Ajout de l'OrderItem pour update ASYNC                
                        orderItemCancelIds.add(newOrderItem.Id);
                    }
                }

                // E - Si modification simple de l'actif (hauteur/largeur)
                for (OrderItem newOrderItem : assetsUpOrderItem) {
                    System.debug('## Changement caractéristiques actif pour la ligne : ' +newOrderItem.Id+ ' - ' + newOrderItem.name__c);
                    List<Asset> newAssetlist = mapOrderItemAssets.get(newOrderItem.Id);
                    if(newAssetlist != null) {
                        for(Asset newAsset : newAssetlist) {
                            System.debug('## Actif à modifier : ' +newAsset);
                            newAsset.leaf__c = newOrderItem.leaf__c;
                            newAsset.height__c = newOrderItem.height__c;
                            newAsset.width__c = newOrderItem.width__c;
                            newAsset.location__c = newOrderItem.location__c;
                            newAsset.locationPrecision__c = newOrderItem.locationPrecision__c;
                            newAsset.thermalCoefficients__c = newOrderItem.thermalCoefficients__c;
                            assetsToUpsert.add(newAsset);
                        }
                    }
                    // Ajout de l'OrderItem pour update ASYNC
                    orderItemUpIds.add(newOrderItem.Id);
                }

                // Commit des actifs
                if(!assetsToUpsert.isEmpty()) {
                    upsert assetsToUpsert;
                }
                // Pour les nouveaux actifs
                if(!newAssetsOrderItem.isEmpty()) {
                    TR022_Order.createAssets(newAssetsOrderItem, true);
                }      

                // MAJ des lignes
                if(!orderItemUpIds.isEmpty()) {
                    amendmentUpdateOrderItem(orderItemUpIds, orderItemCancelIds);
                }
            }
            
            System.debug('### FIN TR022_OrderItem.amendmentCancelOrAddAsset');
        } catch (Exception e) {
            System.debug('ERREUR # TR022_OrderItem.amendmentCancelOrAddAsset (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            throw e;
        }
    }

    /**
    * @description Méthode appelée par les trigger pour lié les garanties des lignes de devis CPQ à la ligne de commande
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void linkWarrantiesToOLI(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR022_OrderItem.linkWarrantiesToOLI');
        try {
            // A - Initialisation et alimentation des données intermédiaires
            Map<String, OrderItem> oliQLIMap = new Map<String, OrderItem>();
            List<Entitlement> entitlementToUp = new List<Entitlement>();
            
            // A - On récupère les ids de chaque OrderItem qui ont été révisé et modifié
            for (OrderItem newOrderItem : (List<OrderItem>)Trigger.new) {
                if(Trigger.isInsert && Trigger.isAfter 
                    && String.isNotBlank(newOrderItem.SBQQ__QuoteLine__c) 
                    && String.isBlank(newOrderItem.parentOrderItem__c)) 
                {
                    System.debug('## OrderItem : ' +newOrderItem.Id + ' - ' + newOrderItem.name__c);
                    oliQLIMap.put(newOrderItem.SBQQ__QuoteLine__c, newOrderItem);
                }
            }
            System.debug('## oliQLIMap : ' +oliQLIMap.size());

            if(!oliQLIMap.isEmpty()) {
                // B - Récupération des garanties des lignes de devis CPQ
                for (Entitlement ent : [SELECT Id, quoteLineCPQ__c, orderItem__c, customerOrder__c FROM Entitlement 
                                            WHERE quoteLineCPQ__c IN :oliQLIMap.keySet()]) {
                    System.debug('## Entitlement : ' +ent);
                    // Mise à jour du lien
                    OrderItem ordItem = null;
                    ordItem = oliQLIMap.get(ent.quoteLineCPQ__c);
                    if(ordItem != null) {
                        System.debug('## Assign to OrderItem : ' +ordItem.Id + ' - ' + ordItem.name__c);
                        ent.orderItem__c = ordItem.Id;
                        ent.customerOrder__c = ordItem.OrderId;
                        entitlementToUp.add(ent);
                    }
                }
            }

            // E - Commit des garanties
            System.debug('## entitlementToUp: '+entitlementToUp.size());
            if(!entitlementToUp.isEmpty()) {
                Database.update(entitlementToUp, false);
            }
            
            System.debug('### FIN TR022_OrderItem.linkWarrantiesToOLI');
        } catch (Exception e) {
            System.debug('ERREUR # TR022_OrderItem.linkWarrantiesToOLI (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            throw e;
        }
    }

    /**
    * @description Méthode pour supprimer les lignes de commande enfant
    * @param userContext contexte utilisateur
    */
    public static void deleteChildrenOrderItems(UserContext userContext) {
        System.debug('### DEBUT TR022_OrderItem.deleteChildrenOrderItems');
        Set<String> childOrderItemsIdList = new Set<String>();
        List<OrderItem> oldOrderItems = (List<OrderItem>)Trigger.old;

        for(OrderItem deletedOrderItems : oldOrderItems){
            childOrderItemsIdList.add(deletedOrderItems.Id);
        }
        
        if(!childOrderItemsIdList.isEmpty()) {
            System.debug('## Child OrderItem to delete: ' + childOrderItemsIdList.size()); 
            delete [SELECT Id, parentOrderItem__c FROM OrderItem 
                        WHERE parentOrderItem__c IN :childOrderItemsIdList 
                        AND Id NOT IN :oldOrderItems];
        }
        System.debug('### FIN TR022_OrderItem.deleteChildrenOrderItems');
    }

    /**
    * @description Méthode pour mettre à jour le fournisseur sur l'actif si la ligne passe au statut "Confirmé"
    * @param userContext contexte utilisateur
    */
    public static void updateOrderItemConfirmedAsset(UserContext userContext) {
        System.debug('### DEBUT TR022_OrderItem.updateOrderItemConfirmedAsset');
        List<OrderItem> newOrderItemsList = new List<OrderItem>();
        Map<Id, OrderItem> oldOrderItems = (Map<Id, OrderItem>)Trigger.oldMap;
        Map<String, List<Asset>> mapOrderItemAssets = new Map<String, List<Asset>>();
        List<Asset> assetsToUpdate = new List<Asset>();

        // On récupère les ids de chaque OrderItem ProviderOrder qui ont été confirmés
        for (OrderItem newOrderItem : (List<OrderItem>)Trigger.new) {
            if(newOrderItem.orderRecordType__c == Constants.ORDER_RT_PROVIDER) {
                OrderItem oldOrderItem = oldOrderItems == null ? null : oldOrderItems.get(newOrderItem.Id);
                if(Trigger.isAfter && newOrderItem.status__c == Constants.ORDERITEM_STATUS_CONFIRMED 
                    && String.isNotBlank(newOrderItem.asset__c) 
                    && (Trigger.isInsert || (Trigger.isUpdate && oldOrderItem.status__c != newOrderItem.status__c))) 
                {
                    // Construction objet Asset
                    assetsToUpdate.add(new Asset(Id = newOrderItem.asset__c, 
                                                AssetProvidedById = newOrderItem.orderProviderId__c));
                }
            }
        }
        System.debug('## assetsToUpdate: ' +assetsToUpdate.size());

        if(!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
        System.debug('### FIN TR022_OrderItem.updateOrderItemConfirmedAsset');
    }

    /**
    * @description Méthode asynchrone pour mise à jour du statut de révision des actifs d'un OrderItem
    * @param newOrderItemIds Liste des Id des OrderItem à mettre à jour
    * @param orderItemCancelIds Liste des Id des OrderItem à annuler
    */
    @future
    public static void amendmentUpdateOrderItem(Set<String> newOrderItemIds, Set<String> orderItemCancelIds) {
        List<OrderItem> orderItemToUp = new List<OrderItem>();

        for(String ordItemId : newOrderItemIds) {
            OrderItem ordItem = new OrderItem(Id = ordItemId, 
                                            StatutDeRevision__c = Constants.ORDERITEM_STATUTREVISION_ASSETUPDATED);
            if(orderItemCancelIds.contains(ordItemId)) {
                ordItem.cancellationDate__c = Date.today();
            }
            orderItemToUp.add(ordItem);
        }

        // F - MAJ des lignes
        System.debug('## orderItemToUp: '+orderItemToUp);
        if(!orderItemToUp.isEmpty()) {
            Database.update(orderItemToUp, false);
        }

    }
}