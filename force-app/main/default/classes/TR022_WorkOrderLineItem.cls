//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_WorkOrderLineItem
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/10/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_WorkOrderLineItem {
  
    /**
    * @description Méthode appelée par les trigger pour modifier le statut des cases PNC
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateStatusCasePNC(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_WorkOrderLineItem.updateStatusCasePNC');

        List<WorkOrderLineItem> newWOLIs = (List<WorkOrderLineItem>)Trigger.new;  
        List<Case> npcList = new List<Case>();
        List<String> npcIdList = new List<String>();
        Map<Id, WorkOrderLineItem> oldWOLIs = (Map<Id, WorkOrderLineItem>)Trigger.oldMap;     
        List<Case> casesToUpdate = new List<Case>();
        String interventionId;
      
        // Recherche des npc associées 
        for (WorkOrderLineItem newWOLI : newWOLIs) {
            WorkOrderLineItem oldWOLI = oldWOLIs == null ? null : oldWOLIs.get(newWOLI.Id);

            if ((Trigger.isInsert && String.isNotBlank(newWOLI.productNonCompliance__c)) 
                || (Trigger.isUpdate && oldWOLI != null && oldWOLI.productNonCompliance__c != newWOLI.productNonCompliance__c 
                    && String.isNotBlank(newWOLI.productNonCompliance__c))) 
            {
                npcIdList.add(newWOLI.productNonCompliance__c);
            }
        }

        // Récupération des informations des npc et du worktype
        if(!npcIdList.isEmpty()) {
            // Récupération des informations des npc
            npcList = [SELECT Id, Status, diagnosticDate__c, aCloturer__c FROM Case 
                        WHERE Id IN :npcIdList AND diagnosticDate__c != null
                        AND Status != :Constants.REQUETE_STATUS_INPROGRESS AND isClosed = false];
                        
            // Récupération du worktype Intervention
            Worktype inter = [SELECT Id, Name FROM WorkType WHERE Name = :Constants.ACTIVITY_TYPE_INTERVENTION LIMIT 1];
            interventionId = inter.Id;
                           
            // B - Application des règles de mise à jour 
            for(WorkOrderLineItem woli : newWOLIs) {
                if(woli.WorkTypeId == interventionId){
                    System.debug('woli.WorkOrderId : '+woli.WorkOrderId);
                    for(Case npc : npcList){
                        if(npc.Id == woli.productNonCompliance__c && npc.diagnosticDate__c != null && npc.aCloturer__c == false){
                            System.debug('woli.productNonCompliance__c : '+woli.productNonCompliance__c);
                            npc.Status = Constants.REQUETE_STATUS_INPROGRESS;
                            casesToUpdate.add(npc);
                        }
                    }
                }
            }
        }

        // C - MAJ Cases
        if(!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
        System.debug('### FIN TR022_WorkOrderLineItem.updateStatusCasePNC');
    }

    /**
    * @description Méthode appelée par les trigger pour modifier le statut des assets
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateStatusAsset(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_WorkOrderLineItem.updateStatusAsset');

        List<WorkOrderLineItem> newWOLIs = (List<WorkOrderLineItem>)Trigger.new;  
        Map<Id, WorkOrderLineItem> oldWOLIs = (Map<Id, WorkOrderLineItem>)Trigger.oldMap;    
        List<String> assetsControlList = new List<String>(); 
        List<String> assetsCancelList = new List<String>(); 
        List<Asset> assetsToUpdate = new List<Asset>();
        Set<Id> assetIdListToUpdate = new Set<Id>();
      
        // Recherche des asset associés 
        for (WorkOrderLineItem newWOLI : newWOLIs) {
            WorkOrderLineItem oldWOLI = oldWOLIs == null ? null : oldWOLIs.get(newWOLI.Id);
            system.debug('### newWOLI.assetControlDate__c' + newWOLI.assetControlDate__c);
            if (Trigger.isUpdate && String.isNotBlank(newWOLI.AssetId) && oldWOLI != null && oldWOLI.Status != newWOLI.Status 
                && newWOLI.Status == 'Terminé' && newWOLI.workOrderRecordType__c == 'workOrderService' && newWOLI.assetControlDate__c == null 
                && newWOLI.workTypeName__c == Constants.ACTIVITY_TYPE_CONTROL)

            {
                Boolean duplicateValue = false;
                if(!assetIdListToUpdate.isEmpty()){
                    for(String assetId : assetIdListToUpdate){
                        if(newWOLI.AssetId == assetId){
                            duplicateValue = true;
                        }
                    }
                }
                if(!duplicateValue){
                    system.debug('### newWOLI.AssetId' + newWOLI.AssetId);
                    assetIdListToUpdate.add(newWOLI.AssetId);
                    assetsControlList.add(newWOLI.AssetId);
                }
            }
            if (Trigger.isUpdate && String.isNotBlank(newWOLI.AssetId) && oldWOLI != null && oldWOLI.Status != newWOLI.Status 
                && newWOLI.Status == 'Annulé' && newWOLI.workOrderRecordType__c == 'workOrderService') 
            {
                Boolean duplicateValue = false;
                if(!assetIdListToUpdate.isEmpty()){
                    for(String assetId : assetIdListToUpdate){
                        if(newWOLI.AssetId == assetId){
                            duplicateValue = true;
                        }
                    }
                }
                if(!duplicateValue){
                    assetIdListToUpdate.add(newWOLI.AssetId);
                    assetsCancelList.add(newWOLI.AssetId);
                }
            }
        }

        // MAJ actifs au statut "Controlé"
        for (String astId : assetsControlList) {
            System.debug('## Update Asset: '+ astId + ' - Status : '+Constants.ASSET_STATUS_CONTROLE);
            Asset newAsset = new Asset(Id = astId, controlDate__c = Date.today());
            assetsToUpdate.add(newAsset);
        }

        // MAJ actifs au statut "Validé"        
        for (String astId : assetsCancelList) {
            System.debug('## Update Asset: '+ astId + ' - Status : '+Constants.ASSET_STATUS_VALIDE);
            Asset newAsset = new Asset(Id = astId, controlDate__c = null);
            assetsToUpdate.add(newAsset);
        }

        // MAJ Assets
        if(!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
        System.debug('### FIN TR022_WorkOrderLineItem.updateStatusAsset');
    }
}