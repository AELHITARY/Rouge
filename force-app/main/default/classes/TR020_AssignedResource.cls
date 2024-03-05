//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_AssignedResource
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/03/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public with sharing class TR020_AssignedResource {

    /***** A - Validation rules *****/
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
    }

    /***** B - Update rules *****/
    public static void applyUpdateRules(UserContext userContext) {
        system.debug('### DEBUT TR020_AssignedResource.applyUpdateRules');
        if (!Trigger.isExecuting) {
            return;
        }
        
        /** 1 - Data Initialisation **/
        List<AssignedResource> newARs = (List<AssignedResource>)Trigger.new;   
        if(Trigger.isInsert){
			for (AssignedResource newAR : newARs) {
				/** Get the ServiceAppointment**/
                List<ServiceAppointment> SAList = [SELECT Id, ServiceAppointment.WorkType.Name, ServiceAppointment.ParentRecordId
                                                   FROM ServiceAppointment
                                                   WHERE Id=:newAR.ServiceAppointmentId];   
                ServiceAppointment sa;
                List<String> workOrderId = new List<String>();
                if(!SAList.isEmpty()){
                    sa=SAList.get(0);
                    workOrderId.add(sa.ParentRecordId);
                }
                /** Get the WO and WOLI**/
                /*Map<Id, WorkOrder> WorkOrderMap = new Map<Id, WorkOrder>([SELECT Id FROM WorkOrder 
                                                                          WHERE Id = :sa.ParentRecordId]);*/
            	//Set<Id> WorkOrderIdList = WorkOrderMap.keySet();
                List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>([SELECT Id, WorkOrderLineItem.Asset.Price
                                                                                FROM WorkOrderLineItem 
                                                                                WHERE WorkOrderLineItem.WorkOrderId = :workOrderId]);
                
                /** Get the ServiceResource**/
                List<ServiceResource> srList = [SELECT Id, ServiceResource.RelatedRecord.Profile.Name 
                                                FROM ServiceResource WHERE Id=:newAr.ServiceResourceId];
                ServiceResource sr;
                if(!srList.isEmpty()){
                    sr=srList.get(0);
                }
                
        		/** DEBUG
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ SA ID: '+newAr.ServiceAppointmentId);
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ WOLISTSIZE: '+woliList.size());
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ WORKTYPEId: '+newAR.ServiceAppointment.WorkTypeId);
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ WORKTYPEId SA: '+sa.WorkTypeId);
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ WORKTYPE: '+newAR.ServiceAppointment.WorkType.Name); 
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ WORKTYPE SA: '+sa.WorkType.Name); 
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ SR ID: '+newAr.ServiceResourceId);
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ PROFILE NAME: '+newAR.ServiceResource.RelatedRecord.Profile.Name);
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ PROFILE NAME SR: '+sr.RelatedRecord.Profile.Name); 
                system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@ RESSOURCE ATTRIB: '+newAR.fsl_typeRessourceAttribuee__c); 
               	**/
                
                /** CONDITION **/
                if(sa!=null && sa.WorkType.Name == 'Intervention' && 
                   sr!=null && sr.RelatedRecord.Profile.Name == 'K/K - FSL Ressource externe' &&
                   newAR.fsl_typeRessourceAttribuee__c == 'Principale'){
                       Decimal sum = 0.00;
                       if(!woliList.isEmpty()){
                   			for(WorkOrderLineItem woli : woliList){
                                /**DEBUG
                                system.debug('################## WoliId: '+woli.Id); 
                                system.debug('################## WoliId: '+woli.Asset.Price); 
								**/
                                if(woli.AssetId!=null && woli.Asset.Price!=null)
                           			sum+= woli.Asset.Price;  
                       		}
                       }    
                       
                       /**MATH FORMULA TO CORRECTLY ROUND THE PRICE**/
                       	Decimal estimatedStandardCost = (sum*0.09).setScale(2);
                       	Decimal estimatedAdditionalCost;
                       if(estimatedStandardCost == (sum*0.09).setScale(2,System.RoundingMode.UP)){
                           estimatedAdditionalCost = (sum*0.01).setScale(2,System.RoundingMode.DOWN);
                       }
                       else{
                           estimatedAdditionalCost = (sum*0.01).setScale(2,System.RoundingMode.UP);
                       }
                       
                  		newAR.estimatedStandardCost__c = estimatedStandardCost; 
                        newAR.estimatedAdditionalCost__c = estimatedAdditionalCost;
                   }
        	}
        }
    }
}