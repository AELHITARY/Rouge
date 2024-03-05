//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_ServiceTerritory
//-- Modifié par : CGI
//-- Modifié le  : 26/02/2018
//-- Version     : 1.0
//-- Description : Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- --------------------------------------------------------------------------------- --

public with sharing class TR001_fsl_ServiceTerritory{
    
    /**
* @description Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
* @param Trigger.new
* @return  Message d'erreur 
*/
    public static void crlCoherenceDateValidite(UserContext context){
        if (!Trigger.isExecuting)
            return;             
        
        //Construire le map de liste de demandes de rendez-vous par territoire
        Map<Id,List<WorkOrder>> mapTerritoryIdToListOfWO=new Map<Id,List<WorkOrder>>();        
        for(WorkOrder wo:[select StartDate,EndDate, ServiceTerritoryId from WorkOrder where ServiceTerritoryId IN:Trigger.newmap.keyset()]){
            if(mapTerritoryIdToListOfWO.containsKey(wo.ServiceTerritoryId)){
                List<WorkOrder> listeWO = mapTerritoryIdToListOfWO.get(wo.ServiceTerritoryId);
                listeWO.add(wo);                
                mapTerritoryIdToListOfWO.put(wo.ServiceTerritoryId, listeWO);
            }else {
                mapTerritoryIdToListOfWO.put(wo.ServiceTerritoryId, new List<WorkOrder> {wo});                            
            }       
        }
        
        // Construire le map de liste de territoire membres par territoire  
        Map<Id,List<ServiceTerritoryMember>> mapTerritoryIdToListOfSTM=new Map<Id,List<ServiceTerritoryMember>>();  
        
        for(ServiceTerritoryMember stm:[select EffectiveStartDate,EffectiveEndDate,ServiceTerritoryId from ServiceTerritoryMember where ServiceTerritoryId IN:Trigger.newmap.keyset()]){
            if(mapTerritoryIdToListOfSTM.containsKey(stm.ServiceTerritoryId)){
                List<ServiceTerritoryMember> listeSTMember = mapTerritoryIdToListOfSTM.get(stm.ServiceTerritoryId);
                listeSTMember.add(stm);
                mapTerritoryIdToListOfSTM.put(stm.ServiceTerritoryId,listeSTMember);
            }else {
                mapTerritoryIdToListOfSTM.put(stm.ServiceTerritoryId, new List<ServiceTerritoryMember> {stm});                            
            }
        }
        
        // Construire le map de liste de rendez-vous par territoire  
        Map<Id,List<ServiceAppointment>> mapTerritoryIdToListOfSA=new Map<Id,List<ServiceAppointment>>(); 
        
        for(ServiceAppointment sa:[select EarliestStartTime,DueDate,ServiceTerritoryId from ServiceAppointment where ServiceTerritoryId IN:Trigger.newmap.keyset()]){
            if(mapTerritoryIdToListOfSA.containsKey(sa.ServiceTerritoryId)){
                List<ServiceAppointment> listeSA = mapTerritoryIdToListOfSA.get(sa.ServiceTerritoryId);
                listeSA.add(sa);
                mapTerritoryIdToListOfSA.put(sa.ServiceTerritoryId, listeSA);
            }else {
                mapTerritoryIdToListOfSA.put(sa.ServiceTerritoryId, new List<ServiceAppointment> {sa});                            
            }
        }     
        
        
        For (ServiceTerritory territory : (List<ServiceTerritory>)Trigger.new){  
            
            // Contrôle des demandes de rendez-vous rattachées  
            if (mapTerritoryIdToListOfWO.containsKey(territory.Id)){ 
                for(WorkOrder wo: mapTerritoryIdToListOfWO.get(territory.Id)){
                    if(wo.StartDate != null && wo.EndDate != null){
                        Date debut= wo.StartDate.Date();  
                        Date fin = wo.EndDate.Date();
                    // Refonte GC : Contrôle obsolète après suppression des dates d'ouverture et fermeture
                    /*if (!FieldServiceUtils.crlCoherenceDate(territory.fsl_dateOuverture__c,territory.fsl_dateFermeture__c,debut,fin))
                        territory.addError (Label.fsl_errorDatesWorkOrderServiceTerritory);*/
                    }
                }          
            }
            
            // Contrôle des rendez-vous rattachés
            if (mapTerritoryIdToListOfSA.containsKey(territory.Id)){ 
                for(ServiceAppointment sa: mapTerritoryIdToListOfSA.get(territory.Id)){

                    if(sa.EarliestStartTime!= null && sa.DueDate!=null){
                        Date debut=sa.EarliestStartTime.Date();
                        Date fin = sa.DueDate.Date();
                    // Refonte GC : Contrôle obsolète après suppression des dates d'ouverture et fermeture
                    /*if(!FieldServiceUtils.crlCoherenceDate(territory.fsl_dateOuverture__c,territory.fsl_dateFermeture__c,debut,fin))
                        territory.AddError (Label.fsl_errorDatesServiceAppointmentServiceTerritory); */
                    }
                }
            }
            // Contrôle des membres rattachés
            if (mapTerritoryIdToListOfSTM.containsKey(territory.Id)){ 
                for(ServiceTerritoryMember STMember: mapTerritoryIdToListOfSTM.get(territory.Id)){  
                    Date debut=STMember.EffectiveStartDate.Date();    
                    Date fin=null;  
                    
                    if(STMember.EffectiveEndDate!=null)
                        fin = STMember.EffectiveEndDate.Date();
                    // Refonte GC : Contrôle obsolète après suppression des dates d'ouverture et fermeture
                    /* if(!FieldServiceUtils.crlCoherenceDate(territory.fsl_dateOuverture__c,territory.fsl_dateFermeture__c,debut,fin))
                        territory.addError (Label.fsl_errorDatesServiceTerritoryServiceTerritoryMember);*/
                }
            }
         }
    }
}