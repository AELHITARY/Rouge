//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR002_fsl_AssignedResource
//-- Modifié par : CGI
//-- Modifié le  : 05/03/2018
//-- Version     : 1.0
//-- Description : Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- --------------------------------------------------------------------------------- --

public with sharing class TR002_fsl_AssignedResource {

    /**
    * @description Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
    * @param Trigger.new
    * @return Message d'erreur
    */
    public static void crlCoherenceDateValidite(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;                                

        //Construire le map de ressource et de rendez-vous
         
        Set<ID> setSAId = new Set<ID>();
        Set<ID> setSRId = new Set<ID>();
        for(AssignedResource tmpAR : (List<AssignedResource>)Trigger.new) {
            if (Trigger.isInsert || (Trigger.isUpdate && !AlreadyUsed.isUsed('TR002_fsl_AssignedResource.crlCoherenceDateValidite', tmpAR.id))) {
                setSAId.add(tmpAR.ServiceAppointmentId);           
                setSRId.add(tmpAR.ServiceResourceId);                       
            }
        } 
        
        if(!setSAId.isEmpty()) {
            Map<ID, ServiceAppointment> saMapIds = new Map<ID, ServiceAppointment>([SELECT id, SchedStartTime, SchedEndTime
                                FROM ServiceAppointment 
                                WHERE id IN:setSAId]);
                                
            Map<ID, ServiceResource> srMapIds = new Map<ID, ServiceResource>([SELECT id, RelatedRecord.dateEntree__c, RelatedRecord.dateSortie__c
                                FROM ServiceResource 
                                WHERE id IN:setSRId]);      
            
            
            
            // Contrôle de la cohérence des dates de validité                
            for (AssignedResource ar : (List<AssignedResource>) Trigger.new ){ 
                System.debug('** Trigger SA dates '+ar.ServiceAppointment.SchedStartTime+' '+ar.ServiceAppointment.SchedEndTime);        
                if(saMapIds.containsKey(ar.ServiceAppointmentId) && saMapIds.get(ar.ServiceAppointmentId).SchedStartTime != null && saMapIds.get(ar.ServiceAppointmentId).SchedEndTime != null){ 
                    Date SchedStartTime = (saMapIds.get(ar.ServiceAppointmentId).SchedStartTime).Date();
                    Date SchedEndTime = (saMapIds.get(ar.ServiceAppointmentId).SchedEndTime).Date();                       
                
                    if(srMapIds.containsKey(ar.ServiceResourceId)){
                        if (!FieldServiceUtils.crlCoherenceDate(srMapIds.get(ar.ServiceResourceId).RelatedRecord.dateEntree__c,srMapIds.get(ar.ServiceResourceId).RelatedRecord.dateSortie__c,SchedStartTime,SchedEndTime)) {
                            ar.addError (Label.fsl_errorDatesAssignedResourceServiceAppointment);
                        }
                    }
                } 
            }   
        }    
    }    
}