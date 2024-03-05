//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_ResourcePreference
//-- Modifié par : CGI
//-- Modifié le  : 05/03/2018
//-- Version     : 1.0
//-- Description : Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- --------------------------------------------------------------------------------- --
public with sharing class TR001_fsl_ResourcePreference  {

    /**
    * @description Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
    * @param 
    * @return void
    */
    public static void crlCoherenceDateValidite(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        
        //Construire le map de liste de demandes de rdv par préférence de ressource
        Map<Id,Set<WorkOrder>> mapWOIdToListOfResourcePreference = new Map<ID,Set<WorkOrder>>();  
        Set<ID> setWOId = new Set<ID>();
        Set<ID> setSRId = new Set<ID>();
        for(ResourcePreference rp : (List<ResourcePreference>)Trigger.new){
            setWOId.add(rp.relatedRecordId);  
            setSRId.add(rp.ServiceResourceId);                  
            
        } 
        
        Map<ID, WorkOrder> woMapIds = new Map<ID, WorkOrder>([SELECT id, StartDate, EndDate
                            FROM WorkOrder 
                            WHERE id IN:setWOId]);
                            
        Map<ID, ServiceResource> srMapIds = new Map<ID, ServiceResource>([SELECT id, RelatedRecord.dateEntree__c, RelatedRecord.dateSortie__c
                            FROM ServiceResource 
                            WHERE id IN:setSRId]);      
        
        for(ResourcePreference rp :[select RelatedRecordId  from ResourcePreference where id IN:Trigger.newmap.keyset()]){
            if(mapWOIdToListOfResourcePreference.containsKey(rp.id)){
                if (woMapIds.containsKey(rp.relatedrecordId)){
                    Set<WorkOrder> setWorkOrder = mapWOIdToListOfResourcePreference.get(rp.id);
                    setWorkOrder.add(woMapIds.get(rp.relatedRecordId));                
                    mapWOIdToListOfResourcePreference.put(rp.id, setWorkOrder);
                }
            }else {
                if (woMapIds.containsKey(rp.relatedrecordId))
                    mapWOIdToListOfResourcePreference.put(rp.id, new Set<WorkOrder> {woMapIds.get(rp.relatedRecordId)});                            
            }       
        }       

        // Contrôle de la cohérence des dates de validité  
        for (ResourcePreference rp : (List<ResourcePreference>)Trigger.new){                
            // Contrôle des capacités de ressource
            if (mapWOIdToListOfResourcePreference.containsKey(rp.Id)){            
                for(WorkOrder wo : mapWOIdToListOfResourcePreference.get(rp.Id)){ 
                    
                    if( wo.StartDate != null && wo.EndDate != null){
                        Date tmpStartDate = (wo.StartDate).Date();
                        Date tmpEndDate = (wo.EndDate).Date(); 
                              
                        if (!FieldServiceUtils.crlCoherenceDate(srMapIds.get(rp.ServiceResourceId).RelatedRecord.dateEntree__c,srMapIds.get(rp.ServiceResourceId).RelatedRecord.dateSortie__c,tmpStartDate ,tmpEndDate ))
                            rp.addError(Label.fsl_errorDatesResourcePreferenceWorkOrder);
                    }
                }          
            }         
        }
    } 
}