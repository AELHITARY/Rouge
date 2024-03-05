//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_ServiceResource 
//-- Modifié par : CGI 
//-- Modifié le  : 16/05/2018
//-- Version     : 1.1
//-- *  Déclenche une erreur si la cohérence de validation n'est pas respectée lors de la désactivation de ressource
//-- --------------------------------------------------------------------------------- --

public class TR001_fsl_ServiceResource {
    /**
* @description Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
* @param Trigger.new
* @return  Message d'erreur 
*/
    public static void crlCoherenceValidite(UserContext context){
        if (!Trigger.isExecuting)
            return;             
       
        //Construire le map de liste de ressources attrubué par rendez-vous
        Map<Id,Set<ID>> mapSAIdToListOfRessource = new Map<Id,Set<ID>>();  
        Set<String> setServiceAppointmentId = new Set<String>();
        for(AssignedResource ar : [select ServiceAppointmentId from AssignedResource where ServiceResourceId IN:Trigger.newmap.keyset() ]){
            setServiceAppointmentId.add(ar.ServiceAppointmentId);                  
        }       
        system.debug('##DEBUG## setServiceAppointment '+setServiceAppointmentId);
        for(AssignedResource ar :[select ServiceResourceId,ServiceAppointmentId from AssignedResource where ServiceAppointmentId IN: setServiceAppointmentId]){
            if(mapSAIdToListOfRessource.containsKey(ar.ServiceAppointmentId)){
                Set<ID> setAssignedResourceId = mapSAIdToListOfRessource.get(ar.ServiceAppointmentId);
                setAssignedResourceId.add(ar.ServiceResourceId);                
                mapSAIdToListOfRessource.put(ar.ServiceAppointmentId, setAssignedResourceId);
            }else {
                mapSAIdToListOfRessource.put(ar.ServiceAppointmentId, new Set<ID> {ar.ServiceResourceId});                            
            }       
        }
        system.debug('$mapSAIdToListOfRessource$'+mapSAIdToListOfRessource);
        
       //Contrôle la cohérence des dates 
        for (ServiceResource newSR : (List<ServiceResource>)Trigger.new){            
            ServiceResource oldSR = (ServiceResource)Trigger.oldMap.get(newSR.ID); 
            if(oldSR.IsActive && !newSR.IsActive){                
               
                // Contrôle des ServiceAppointment avec ressource attribué                 
                for (ServiceAppointment sa : [select SchedStartTime,SchedEndTime from ServiceAppointment where Id IN : setServiceAppointmentId]){                    
                    if(mapSAIdToListOfRessource.get(sa.id).contains(newSR.Id) && mapSAIdToListOfRessource.containsKey(sa.Id) && sa.SchedStartTime > system.now () )
                       
                            newSR.addError (Label.fsl_errorDesactivationResourceAttribuee);
                      
                }                
            }
        }         
    }
}