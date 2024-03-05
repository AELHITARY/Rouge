//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_WorkOrderLineItem
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/12/2022
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_WorkOrderLineItem {

    /**
    * @description Méthode pour confirmer l'autorisation de la suppression des WOLI si l'actif associé n'est pas verrouillé
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### START TR020_WorkOrderLineItem.applyValidationRules');
        
        List<WorkOrderLineItem> oldWOLIs = (List<WorkOrderLineItem>)Trigger.old;
        for(WorkOrderLineItem oldWOLI : oldWOLIs){
            // Ne pas supprimer si l'asset est verrouillé
            if(oldWOLI.isAssetLocked__c && Trigger.isDelete && Trigger.isBefore){
                oldWOLI.addError(Label.asset_msg_cantDeleteWOLI);
            }
        }
        
        System.debug('### FIN TR020_WorkOrderLineItem.applyValidationRules');
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les lignes de demande de RDV
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
          
        System.debug('### DEBUT TR020_WorkOrderLineItem.applyUpdateRules');
        List<WorkOrderLineItem> newWOLIs = (List<WorkOrderLineItem>)Trigger.new;   
        Map<Id, WorkOrderLineItem> oldWOLIs = (Map<Id, WorkOrderLineItem>)Trigger.oldMap;     
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(); 
        Map<Id, Asset> assetMap = new Map<Id, Asset>(); 
        Map<Id, Case> caseMap = new Map<Id, Case>(); 
        List<String> woIdsList = new List<String>();
        List<String> assetIdsList = new List<String>();
        List<String> caseIdsList = new List<String>();
      
        // A - Initialisation des données intermédiaires 
        for (WorkOrderLineItem newWOLI : newWOLIs) {
            WorkOrderLineItem oldWOLI = oldWOLIs == null ? null : oldWOLIs.get(newWOLI.id); 

            if(Trigger.isInsert && String.isNotBlank(newWOLI.WorkOrderId)) {
                woIdsList.add(newWOLI.WorkOrderId);
            }
            if((Trigger.isInsert || (Trigger.isUpdate && oldWOLI != null && oldWOLI.productNonCompliance__c != newWOLI.productNonCompliance__c)) && String.isNotBlank(newWOLI.productNonCompliance__c)) {
                caseIdsList.add(newWOLI.productNonCompliance__c);
            }
            if((Trigger.isInsert || (Trigger.isUpdate && oldWOLI != null && oldWOLI.AssetId != newWOLI.AssetId)) && String.isNotBlank(newWOLI.AssetId)) {
                assetIdsList.add(newWOLI.AssetId);
            }
        }

        // SOQL - Récupération des demandes de rendez-vous
        for(WorkOrder wo : [SELECT Id, Street, City, PostalCode, State, Country, Duration, DurationType, FSL__VisitingHours__c,
                                    MinimumCrewSize, RecommendedCrewSize, Priority, ServiceTerritoryId, WorkTypeId
                            FROM WorkOrder WHERE Id IN :woIdsList]) {
            workOrderMap.put(wo.Id, wo);
        }

        if(!assetIdsList.isEmpty()) {
            for(Asset asset : [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Asset WHERE Id IN : assetIdsList]){
                assetMap.put(asset.Id, asset);
            }
        }

        if(!caseIdsList.isEmpty()) {
            for(Case ncp : [SELECT Id, Type, RecordTypeId, RecordType.DeveloperName FROM Case WHERE Id IN : caseIdsList]){
                caseMap.put(ncp.Id, ncp);
            }
        }
           
        // B - Application des règles de mise à jour 
        for(WorkOrderLineItem newWOLI : newWOLIs){
            System.debug('## newWOLI.Id: '+newWOLI.Id); 
            System.debug('## newWOLI.WorkOrderId: '+newWOLI.WorkOrderId); 
            
            WorkOrderLineItem oldWOLI = oldWOLIs == null ? null : oldWOLIs.get(newWOLI.id);
            //Mise à jour via la demande de rendez-vous
            if(Trigger.isInsert && String.IsNotBlank(newWOLI.WorkOrderId)) {
                WorkOrder parentWO = workOrderMap.get(newWOLI.WorkOrderId);
                Case presentNCP = caseMap.get(newWOLI.productNonCompliance__c);
                Asset presentAsset = assetMap.get(newWOLI.AssetId);
                System.debug('## Parent WO: '+parentWO); 
                System.debug('## NCP: '+presentNCP); 
                System.debug('## Asset: '+presentAsset); 

                if(parentWO != null){
                    newWOLI.City = (newWOLI.City == null) ? parentWO.City : newWOLI.City;
                    newWOLI.Street = (newWOLI.Street == null) ? parentWO.Street : newWOLI.Street;
                    newWOLI.PostalCode = (newWOLI.PostalCode == null) ? parentWO.PostalCode : newWOLI.PostalCode;
                    newWOLI.State = (newWOLI.State == null) ? parentWO.State : newWOLI.State;
                    newWOLI.Country = (newWOLI.Country == null) ? parentWO.Country : newWOLI.Country;
                    newWOLI.Duration = (newWOLI.Duration == null) ? parentWO.Duration : newWOLI.Duration;
                    newWOLI.DurationType = (newWOLI.DurationType == null) ? parentWO.DurationType : newWOLI.DurationType;
                    newWOLI.FSL__VisitingHours__c = (newWOLI.FSL__VisitingHours__c == null) ? parentWO.FSL__VisitingHours__c : newWOLI.FSL__VisitingHours__c;
                    newWOLI.MinimumCrewSize = (newWOLI.MinimumCrewSize == null) ? parentWO.MinimumCrewSize : newWOLI.MinimumCrewSize;
                    newWOLI.RecommendedCrewSize = (newWOLI.RecommendedCrewSize == null) ? parentWO.RecommendedCrewSize : newWOLI.RecommendedCrewSize;
                    newWOLI.Priority = (newWOLI.Priority == null) ? parentWO.Priority : newWOLI.Priority;
                    newWOLI.ServiceTerritoryId = (newWOLI.ServiceTerritoryId == null) ? parentWO.ServiceTerritoryId : newWOLI.ServiceTerritoryId;
                    newWOLI.WorkTypeId = (newWOLI.WorkTypeId == null) ? parentWO.WorkTypeId : newWOLI.WorkTypeId;
                }

                if(presentNCP != null){
                    String casePNCIntRTId = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
                    if(presentNCP.RecordTypeId == casePNCIntRTId){
                        newWOLI.WOLIType__c = presentNCP.Type;
                    } else {
                        newWOLI.WOLIType__c = null;
                    }
                } else if(presentAsset != null) {
                    newWOLI.WOLIType__c = presentAsset.RecordType.DeveloperName;
                }

                System.debug('## WOLIType: '+newWOLI.WOLIType__c); 
                System.debug('## Update WOLI: '+newWOLI); 
            } 
        }

        System.debug('### FIN TR020_WorkOrderLineItem.applyUpdateRules');
    }
}