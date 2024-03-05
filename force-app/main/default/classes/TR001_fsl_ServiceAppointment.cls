//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_ServiceAppointment
//-- Modifié par : CGI
//-- Modifié le  : 30/01/2018
//-- Version     : 1.0
//-- Description : Contrôle du nombre de ressources attribuées si le rdv est confirmé et 
//                 déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- --------------------------------------------------------------------------------- --

public with sharing class TR001_fsl_ServiceAppointment {
    private static final String SA_OLDRECORDTYPE_ID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
    
    /**
    * @description Déclenche d'une erreur si un rdv confirmé ne possède aucune ressource attribuée
    * @param 
    * @return   
    */
    public static void  auMoinsUneRessourceAttribuee(UserContext context) {
        if (!Trigger.isExecuting)
            return;
        
        if (trigger.new.size() > 1) 
            return;
        
        ServiceAppointment appointment = null;
        
        for (ServiceAppointment servApp : (List<ServiceAppointment>)Trigger.new){       
            if (((servApp.status != null && servApp.status.equals('Confirmé')) || ( servApp.status != null && !servApp.status.equals('Annulé') && servApp.fsl_dateConfirmation__c != null ))) {  
                appointment = servApp ;
            }
        }    
        
        // Collecte des ressources active attribuées du rdv 
        if(appointment != null) {
            List <AssignedResource> ressourceList = new List<AssignedResource>();
            ressourceList = [SELECT Id
                            FROM AssignedResource
                            WHERE ServiceAppointmentId = :appointment.id and ServiceResource.IsActive = true];
            
            if (ressourceList.isEmpty() && context.canByPassValidationRules() == false){
                System.debug('############# DEBUG - RDV : '+appointment);
                appointment.addError ('Au moins une ressource active est obligatoire si le rendez-vous est confirmé !');
            }
        }
    }
    
    /**
    * @description Déclenche une erreur si la cohérence n'est pas respectée
    * @param 
    * @return   
    */
    public static void crlCoherenceDateValidite(UserContext context){
        
        if (!Trigger.isExecuting)
            return;   

        List<ServiceAppointment> saList = new List<ServiceAppointment>();      
            
        // Contrôle des ressources rattachées 
        for (ServiceAppointment sa : (List<ServiceAppointment>)Trigger.new){        
            // SOPRA : Ne pas prendre en compte les nouveaux record type
            if(sa.RecordTypeId == SA_OLDRECORDTYPE_ID && sa.SchedStartTime != null && sa.SchedEndTime != null){ 
                saList.add(sa);
            }
        }    
        
        if(!saList.isEmpty()) {
            //Construire le map de liste de ressources par RDV
            Map<Id,List<ID>> mapRdvIdToListOfRessource = new Map<Id,List<ID>>();  
            List<ID> listeUser = new List<ID>();      
            for(AssignedResource ar :[SELECT ServiceResource.RelatedRecordId,ServiceAppointmentId FROM AssignedResource WHERE ServiceAppointmentId IN:Trigger.newmap.keyset()]){
                listeUser.add(ar.ServiceResource.RelatedRecordId);
                if(mapRdvIdToListOfRessource.containsKey(ar.ServiceAppointmentId)){
                    List<ID> listeAR = mapRdvIdToListOfRessource.get(ar.ServiceAppointmentId);
                    listeAR.add(ar.ServiceResource.RelatedRecordId);                
                    mapRdvIdToListOfRessource.put(ar.ServiceAppointmentId, listeAR);
                }else {
                    mapRdvIdToListOfRessource.put(ar.ServiceAppointmentId, new List<ID> {ar.ServiceResource.RelatedRecordId});                            
                }       
            }
            
            Map<ID, User> mapUser = new Map<ID,User>([SELECT dateEntree__c,dateSortie__c FROM User where Id IN:listeUser]);
            
            // Contrôle des ressources rattachées 
            for (ServiceAppointment sa : saList){                   
                if (sa.SchedStartTime != null && sa.SchedEndTime != null && mapRdvIdToListOfRessource.containsKey(sa.Id)){ 
                    Date SchedStartTime = sa.SchedStartTime.Date();           
                    Date SchedEndTime = sa.SchedEndTime.Date();
                    for(ID userId: mapRdvIdToListOfRessource.get(sa.id)){
                        User u = mapUser.get(userId);
                        if (u != null) { 
                            System.debug('###### DEBUG : Debut parent : '+u.dateEntree__c+' Fin parent : '+u.dateSortie__c+' Debut fils : '+SchedStartTime+ ' Fin fils : '+SchedEndTime);
                            if (!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,SchedStartTime,SchedEndTime))
                                sa.addError (Label.fsl_errorDatesAssignedResourceServiceAppointment);
                        }                        
                    }
                }
            }    
        }
    }
}