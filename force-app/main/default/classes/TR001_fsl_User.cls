//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_User 
//-- Modifié par : CGI 
//-- Modifié le  : 27/03/2018
//-- Version     : 1.1
//-- *  Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- --------------------------------------------------------------------------------- --

public class TR001_fsl_User {
    /**
* @description Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
* @param Trigger.new
* @return  Message d'erreur 
*/
    public static void crlCoherenceDateValidite(UserContext context){
        if (!Trigger.isExecuting)
            return;             
        
        //Construire le map de liste de capacités de ressource par ressource(user)
        Map<Id,List<ServiceResourceCapacity>> mapRessourceIdToListOfSRC=new Map<Id,List<ServiceResourceCapacity>>();        
        for(ServiceResourceCapacity src:[select StartDate,EndDate, ServiceResource.RelatedRecordId from ServiceResourceCapacity where ServiceResource.RelatedRecordId IN:Trigger.newmap.keyset()]){
            if(mapRessourceIdToListOfSRC.containsKey(src.ServiceResource.RelatedRecordId)){
                List<ServiceResourceCapacity> listeSRC = mapRessourceIdToListOfSRC.get(src.ServiceResource.RelatedRecordId);
                listeSRC.add(src);                
                mapRessourceIdToListOfSRC.put(src.ServiceResource.RelatedRecordId, listeSRC);
            }else {
                mapRessourceIdToListOfSRC.put(src.ServiceResource.RelatedRecordId, new List<ServiceResourceCapacity> {src});                            
            }       
        }
        system.debug('$mapRessourceIdToListOfSRC$'+mapRessourceIdToListOfSRC);
        // Construire le map de liste de compétences de ressource par ressource(user)  
        Map<Id,List<ServiceResourceSkill>> mapRessourceIdToListOfSRS=new Map<Id,List<ServiceResourceSkill>>(); 	
        
        for(ServiceResourceSkill srs:[select EffectiveStartDate,EffectiveEndDate,ServiceResource.RelatedRecordId from ServiceResourceSkill where ServiceResource.RelatedRecordId IN:Trigger.newmap.keyset()]){
            if(mapRessourceIdToListOfSRS.containsKey(srs.ServiceResource.RelatedRecordId)){
                List<ServiceResourceSkill> listeSkill = mapRessourceIdToListOfSRS.get(srs.ServiceResource.RelatedRecordId);
                listeSkill.add(srs);
                mapRessourceIdToListOfSRS.put(srs.ServiceResource.RelatedRecordId,listeSkill);
            }else {
                mapRessourceIdToListOfSRS.put(srs.ServiceResource.RelatedRecordId, new List<ServiceResourceSkill> {srs});                            
            }
        }        
        system.debug('$mapRessourceIdToListOfSRS$'+mapRessourceIdToListOfSRS);
        // Construire le map de liste des membres de territoire  par ressource(user)  
        Map<Id,List<ServiceTerritoryMember>> mapRessourceIdToListOfSTM=new Map<Id,List<ServiceTerritoryMember>>(); 	
        
        for(ServiceTerritoryMember stm:[select EffectiveStartDate,EffectiveEndDate,ServiceResource.RelatedRecordId from ServiceTerritoryMember where ServiceResource.RelatedRecordId IN:Trigger.newmap.keyset()]){
            if(mapRessourceIdToListOfSTM.containsKey(stm.ServiceResource.RelatedRecordId)){
                List<ServiceTerritoryMember> listeSTMember = mapRessourceIdToListOfSTM.get(stm.ServiceResource.RelatedRecordId);
                listeSTMember.add(stm);
                mapRessourceIdToListOfSTM.put(stm.ServiceResource.RelatedRecordId,listeSTMember);
            }else {
                mapRessourceIdToListOfSTM.put(stm.ServiceResource.RelatedRecordId, new List<ServiceTerritoryMember> {stm});                            
            }
        }        
        system.debug('$mapRessourceIdToListOfSTM$'+mapRessourceIdToListOfSTM);
        // Construire le map de liste des absences par ressource(user) 
        Map<Id,List<ResourceAbsence>> mapRessourceIdToListOfAbsence=new Map<Id,List<ResourceAbsence>>(); 
        
        for(ResourceAbsence absence:[select Start,End,Resource.RelatedRecordId from ResourceAbsence where Resource.RelatedRecordId  IN:Trigger.newmap.keyset()]){
            if(mapRessourceIdToListOfAbsence.containsKey(absence.Resource.RelatedRecordId)){
                List<ResourceAbsence> listeAbsence = mapRessourceIdToListOfAbsence.get(absence.Resource.RelatedRecordId);
                listeAbsence.add(absence);
                mapRessourceIdToListOfAbsence.put(absence.Resource.RelatedRecordId, listeAbsence);
            }else {
                mapRessourceIdToListOfAbsence.put(absence.Resource.RelatedRecordId, new List<ResourceAbsence> {absence});                            
            }
        }           
        system.debug('$mapRessourceIdToListOfAbsence$'+mapRessourceIdToListOfAbsence);
        //Construire le map de liste de ressources préférées par WorkOrder
        Map<Id,Set<ID>> mapWOIdToListOfRessource = new Map<Id,Set<ID>>();          
        Set<ID> setWorkOrderId = new Set<ID>();
        for(ResourcePreference preference : [Select RelatedRecordId from ResourcePreference where ServiceResource.RelatedRecordId IN:Trigger.newmap.keyset() and RelatedRecord.type='WorkOrder']){
            setWorkOrderId.add(preference.RelatedRecordId);            
        }      
        system.debug('##DEBUG## setWorkOrder '+setWorkOrderId);
        if(setWorkOrderId.size()!=0){
            for(ResourcePreference preference :[select ServiceResource.RelatedRecordId,RelatedRecordId from ResourcePreference where RelatedRecordId IN: setWorkOrderId]){
                if(mapWOIdToListOfRessource.containsKey(preference.RelatedRecordId)){
                    Set<ID> setPreferenceUserId = mapWOIdToListOfRessource.get(preference.RelatedRecordId);
                    setPreferenceUserId.add(preference.ServiceResource.RelatedRecordId);                
                    mapWOIdToListOfRessource.put(preference.RelatedRecordId, setPreferenceUserId);
                }else {
                    mapWOIdToListOfRessource.put(preference.RelatedRecordId, new Set<ID> {preference.ServiceResource.RelatedRecordId});                            
                }       
            }
        }       
        system.debug('$mapWOIdToListOfRessource$'+mapWOIdToListOfRessource);
        //Construire le map de liste de ressources attrubué par rendez-vous
        Map<Id,Set<ID>> mapSAIdToListOfRessource = new Map<Id,Set<ID>>();  
        Set<String> setServiceAppointmentId = new Set<String>();
        for(AssignedResource ar : [select ServiceAppointmentId from AssignedResource where ServiceResource.RelatedRecordId IN:Trigger.newmap.keyset() ]){
            setServiceAppointmentId.add(ar.ServiceAppointmentId);                  
        }       
        system.debug('##DEBUG## setServiceAppointment '+setServiceAppointmentId);
        for(AssignedResource ar :[select ServiceResource.RelatedRecordId,ServiceAppointmentId from AssignedResource where ServiceAppointmentId IN: setServiceAppointmentId]){
            if(mapSAIdToListOfRessource.containsKey(ar.ServiceAppointmentId)){
                Set<ID> setAssignedUserId = mapSAIdToListOfRessource.get(ar.ServiceAppointmentId);
                setAssignedUserId.add(ar.ServiceResource.RelatedRecordId);                
                mapSAIdToListOfRessource.put(ar.ServiceAppointmentId, setAssignedUserId);
            }else {
                mapSAIdToListOfRessource.put(ar.ServiceAppointmentId, new Set<ID> {ar.ServiceResource.RelatedRecordId});                            
            }       
        }
        system.debug('$mapSAIdToListOfRessource$'+mapSAIdToListOfRessource);
        
       //Contrôle la cohérence des dates 
        for (User u : (List<user>)Trigger.new){ 
            if(u.IsActive){
                
                // Contrôle des capacités de ressource
                if (mapRessourceIdToListOfSRC.containsKey(u.Id)){            
                    for(ServiceResourceCapacity src: mapRessourceIdToListOfSRC.get(u.Id)){              
                        
                        if (!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,src.StartDate,src.EndDate))
                            u.addError (Label.fsl_errorDatesUserServiceResourceCapacity);
                    }          
                }
               
                // Contrôle des compétences de ressource
                if (mapRessourceIdToListOfSRS.containsKey(u.Id)){ 
                    for(ServiceResourceSkill srs: mapRessourceIdToListOfSRS.get(u.Id)){
                        Date debut = srs.EffectiveStartDate.Date();  
                        Date fin = null;   
                        
                        if(srs.EffectiveEndDate!= null)
                            fin = srs.EffectiveEndDate.Date();
                        
                        if(!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,debut,fin))
                            u.addError (Label.fsl_errorDatesUserServiceResourceSkill); 
                    }
                }  
                
                // Contrôle des membres de territoire 
                if (mapRessourceIdToListOfSTM.containsKey(u.Id)){ 
                    for(ServiceTerritoryMember STMember: mapRessourceIdToListOfSTM.get(u.Id)){  
                        Date debut = STMember.EffectiveStartDate.Date();    
                        Date fin = null;  
                        
                        if(STMember.EffectiveEndDate!= null)
                            fin = STMember.EffectiveEndDate.Date();
                        
                        if(!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,debut,fin))
                            u.addError (Label.fsl_errorDatesUserServiceTerritoryMember);
                    }
                }
                
                // Contrôle des absences de ressource
                if (mapRessourceIdToListOfAbsence.containsKey(u.Id)){ 
                    for(ResourceAbsence absence: mapRessourceIdToListOfAbsence.get(u.Id)){  
                        Date debut = absence.Start.Date();    
                        Date fin = null;  
                        
                        if(absence.End!= null)
                            fin = absence.End.Date();
                        
                        if(!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,debut,fin))
                            u.addError (Label.fsl_errorDatesUserResourceAbsence);
                    }
                }                
                
                // Contrôle des WorkOrder avec ressource préférée                 
                for (WorkOrder wo : [select StartDate,EndDate from WorkOrder where Id IN : setWorkOrderId]){ 
                    if(mapWOIdToListOfRessource.get(wo.id).contains(u.Id) && mapWOIdToListOfRessource.containsKey(wo.Id)){ 
                       if( wo.StartDate != null && wo.EndDate != null){  
                        Date StartDate = wo.StartDate.Date();
                        Date EndDate = wo.EndDate.Date();      
                        if (!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,StartDate,EndDate))
                            u.addError (Label.fsl_errorDatesResourcePreferenceWorkOrder);
                       }
                    }  
                } 
                
                // Contrôle des ServiceAppointment avec ressource attribué                 
                for (ServiceAppointment sa : [select SchedStartTime,SchedEndTime from ServiceAppointment where Id IN : setServiceAppointmentId]){ 
                    if(mapSAIdToListOfRessource.get(sa.id).contains(u.Id) && mapSAIdToListOfRessource.containsKey(sa.Id)){ 
                        if( sa.SchedStartTime != null && sa.SchedEndTime != null){  
                        Date SchedStartTime = sa.SchedStartTime.Date();
                        Date SchedEndTime = sa.SchedEndTime.Date();                       
                        
                        system.debug('**'+u.dateEntree__c+'-'+u.dateSortie__c+'-'+SchedStartTime+'-'+SchedEndTime);
                        if (!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,SchedStartTime,SchedEndTime))
                            u.addError (Label.fsl_errorDatesAssignedResourceServiceAppointment);
                        }
                    } 
                }                
            }
        }         
    }
}