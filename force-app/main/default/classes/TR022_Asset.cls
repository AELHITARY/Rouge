//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Asset
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/06/2023
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Asset {
    private static final String RT_ENTITLEMENT_GARANTIE = DAL.getRecordTypeIdByDevName('Entitlement', 'AssetWarranty');

    /**
    * @description Méthode pour supprimer les assets enfant
    * @param userContext contexte utilisateur
    */
    public static void deleteChildrenAssets(UserContext userContext) {
        System.debug('### DEBUT TR022_Asset.deleteChildrenAssets');
        List<Asset> childAssetsList = new List<Asset>();
        List<String> childAssetsIdList = new List<String>();
        List<Asset> oldAssets = (List<Asset>)Trigger.old;

        for(Asset deletedAssets : oldAssets){
            System.debug('## deletedAssets.Id : ' + deletedAssets.Id);
            childAssetsIdList.add(deletedAssets.Id);
        }
        childAssetsList = [SELECT Id, ParentId FROM Asset WHERE ParentId IN :childAssetsIdList AND Id NOT IN :oldAssets];
        System.debug('## childAssetsList : ' + childAssetsList); 

        if(!childAssetsList.isEmpty()) {
            delete childAssetsList;
        }
        System.debug('### FIN TR022_Asset.deleteChildrenAssets');
    }

    /**
    * @description Méthode pour mettre à jour le statut des assets enfant
    * @param userContext contexte utilisateur
    */
    public static void updateChildrenAssetsStatus(UserContext userContext) {
        System.debug('### DEBUT TR022_Asset : updateChildAssetsStatus');
        Map<Id, Asset> oldAssets = (Map<Id, Asset>)Trigger.oldMap;
        List<Asset> assetParentList = new List<Asset>();
        List<Asset> assetToUp = new List<Asset>();
        
        for (Asset newAsset : (List<Asset>)Trigger.new) {
            Asset oldAsset = oldAssets == null ? null : oldAssets.get(newAsset.Id);
            
            // Changement des status pour les asset enfants
            if (Trigger.isAfter && Trigger.isUpdate && String.isBlank(newAsset.ParentId) && oldAsset != null && oldAsset.Status != newAsset.Status) {  
                System.debug('## Asset parent: ' + newAsset); 
                assetParentList.add(newAsset);
            }
        }

        // Récupération des informations assets enfant
        if(!assetParentList.isEmpty()) {
            for (Asset assetChild : [SELECT Id, Parent.Status, Parent.stageName__c, Status, stageName__c FROM Asset WHERE ParentId IN :assetParentList]) {
                System.debug('## Asset child: ' + assetChild);
                // Mise à jour des enfants seulement si le statut est différent
                if(assetChild.Status != assetChild.Parent.Status) {
                    assetChild.Status = assetChild.Parent.Status;
                    assetChild.stageName__c = assetChild.Parent.stageName__c;
                    assetToUp.add(assetChild);
                }
                System.debug('## Asset child Status: ' + assetChild.Status);
                System.debug('## Asset child stageName__c: ' + assetChild.stageName__c);
            }
        }

        System.debug('## Asset to update : ' + assetToUp.size());
        if(!assetToUp.isEmpty()) {
            update assetToUp;
        }
        System.debug('### FIN TR022_Asset : updateChildAssetsStatus');
    }
    
    /**
    * @description Méthode pour créer les garanties par rapport aux lignes de devis seulement pour les actifs parent
    * @param userContext contexte utilisateur
    */
    public static void createWarranties(UserContext userContext) {
        // A - Initialisation et alimentation des données intermédiaires
        List<Asset> newAssetsList = new List<Asset>();
        List<String> orderItemsId = new List<String>();
        Map<String, OrderItem> orderItemsMap = new Map<String, OrderItem>();
        List<Entitlement> warrantiesListToIns = new List<Entitlement>();
        
        // On récupère les ids des asset parent seulement
        for (Asset newAsset : (List<Asset>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR022_Asset.createWarranties', newAsset.id)) {
                if(Trigger.isInsert && newAsset.ParentId == null) {
                    newAssetsList.add(newAsset);
                    if(String.isNotBlank(newAsset.orderItem__c)) {
                        orderItemsId.add(newAsset.orderItem__c);
                    }
                }
            }
        }

        if(!orderItemsId.isEmpty()) {            
            // Récupération "Garantie commande" liés aux lignes
            List<Entitlement> orderWarraList = [SELECT Id, Name, KparKReference__c, category__c, categoryReference__c, duration__c, 
                                                    orderItem__c, orderItem__r.OrderId, orderItem__r.Order.AccountId 
                                                    FROM Entitlement WHERE orderItem__c IN :orderItemsId];

            // Boucle sur les assets parent pour créer les garanties
            for (Asset newAsset : newAssetsList) {
                System.debug('## Création garantie pour: '+newAsset.Id);
                // Récupération de l'information de la ligne de commande
                for(Entitlement warranty : orderWarraList) {
                    if(newAsset.orderItem__c == warranty.orderItem__c) {
                        // Création des garanties
                        warrantiesListToIns.add(constructEntitlmentObject(newAsset, warranty.orderItem__r, warranty.Name, warranty.KparKReference__c,
                                                                            warranty.category__c, warranty.categoryReference__c, warranty.duration__c));
                    }
                }
            }
        }

        System.debug('## warrantiesListToIns: '+warrantiesListToIns);
        // Commit des garanties
        if(!warrantiesListToIns.isEmpty()) {
            insert warrantiesListToIns;
        }

        System.debug('### FIN TR022_Asset.createWarranties');
    }

    /**
    * @description Méthode interne pour créer l'objet Entitlement
    * @param newAsset Objet contenant les informations de l'actif
    * @param orderItemAsset Objet de la ligne de commande contenant les informations de la commande
    * @param libelleGarantie Libellé de la garantie
    * @param codeGarantie Code de la garantie
    * @param libelleCategorieGarantie Libellé de la catégorie de la garantie
    * @param codeCategorieGarantie Code de la catégorie de la garantie
    * @param dureeGarantie Durée de la garantie
    * @return Entitlement Objet Garantie
    */
    private static Entitlement constructEntitlmentObject(Asset newAsset, OrderItem orderItemAsset, String libelleGarantie, String codeGarantie,
                                                        String libelleCategorieGarantie, String codeCategorieGarantie, Decimal dureeGarantie) {
        // Création objet
        Entitlement result = new Entitlement(
            customerOrder__c = orderItemAsset.OrderId,
            AccountId = orderItemAsset.Order.AccountId,
            Type = 'Garantie',
            Name = libelleGarantie,
            KparKReference__c = codeGarantie,
            category__c = libelleCategorieGarantie,
            categoryReference__c = codeCategorieGarantie,
            duration__c = dureeGarantie,
            RecordTypeId = RT_ENTITLEMENT_GARANTIE,
            AssetId = newAsset.Id
        );
        System.debug('## Garantie : '+result);
		return result;
	}
}