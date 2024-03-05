//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_OperatingHours 
//-- Modifié par : CGI 
//-- Modifié le  : 27/03/2018
//-- Version     : 1.1
//-- *  Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- --------------------------------------------------------------------------------- --

public class TR001_fsl_OperatingHours {
    /**
* @description Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
* @param Trigger.new
* @return  Message d'erreur 
*/
    public static void crlCoherenceDateValidite(UserContext context){
        if (!Trigger.isExecuting)
            return;             
        
        //Construire le map de liste des demandes de rdv par heure de fonctionnement
        Map<Id,List<WorkOrder>> mapOperatingHoursIdToListOfWO=new Map<Id,List<WorkOrder>>();        
        for(WorkOrder wo:[select StartDate,EndDate, FSL__VisitingHours__c from WorkOrder where FSL__VisitingHours__c IN:Trigger.newmap.keyset()]){
            if(mapOperatingHoursIdToListOfWO.containsKey(wo.FSL__VisitingHours__c)){
                List<WorkOrder> listeWO = mapOperatingHoursIdToListOfWO.get(wo.FSL__VisitingHours__c);
                listeWO.add(wo);                
                mapOperatingHoursIdToListOfWO.put(wo.FSL__VisitingHours__c, listeWO);
            }else {
                mapOperatingHoursIdToListOfWO.put(wo.FSL__VisitingHours__c, new List<WorkOrder> {wo});                            
            }       
        }
        
        // Construire le map de liste des membres de territoire par heure de fonctionnement  
        Map<Id,List<ServiceTerritoryMember>> mapOperatingHoursIdToListOfSTM=new Map<Id,List<ServiceTerritoryMember>>();     
        
        for(ServiceTerritoryMember stm:[select EffectiveStartDate,EffectiveEndDate,OperatingHoursId from ServiceTerritoryMember where OperatingHoursId IN:Trigger.newmap.keyset()]){
            if(mapOperatingHoursIdToListOfSTM.containsKey(stm.OperatingHoursId)){
                List<ServiceTerritoryMember> listeSTMember = mapOperatingHoursIdToListOfSTM.get(stm.OperatingHoursId);
                listeSTMember.add(stm);
                mapOperatingHoursIdToListOfSTM.put(stm.OperatingHoursId,listeSTMember);
            }else {
                mapOperatingHoursIdToListOfSTM.put(stm.OperatingHoursId, new List<ServiceTerritoryMember> {stm});                            
            }
        }
         
        // Construire le map de liste des territoires par heure de fonctionnement  
        Map<Id,List<ServiceTerritory>> mapOperatingHoursIdToListOfST=new Map<Id,List<ServiceTerritory>>();  
        
        for(ServiceTerritory st:[select OperatingHoursId from ServiceTerritory where OperatingHoursId IN:Trigger.newmap.keyset()]){
            if(mapOperatingHoursIdToListOfST.containsKey(st.OperatingHoursId)){
                List<ServiceTerritory> listeST = mapOperatingHoursIdToListOfST.get(st.OperatingHoursId);
                listeST.add(st);
                mapOperatingHoursIdToListOfST.put(st.OperatingHoursId,listeST);
            }else {
                mapOperatingHoursIdToListOfST.put(st.OperatingHoursId, new List<ServiceTerritory> {st});                            
            }
        }
        
        
        for (OperatingHours oh : (List<OperatingHours>)Trigger.new){
            // Contrôle des WorkOrder
            if (mapOperatingHoursIdToListOfWO.containsKey(oh.Id)){            
                for(WorkOrder wo: mapOperatingHoursIdToListOfWO.get(oh.Id)){            
                    
                    if(wo.StartDate != null && wo.EndDate!= null){
                        Date debut = wo.StartDate.Date();  
                        Date fin = wo.EndDate.Date();
                        
                        /*if (!FieldServiceUtils.crlCoherenceDate(oh.fsl_dateOuverture__c,oh.fsl_dateFermeture__c,debut,fin))
                            oh.addError (Label.fsl_errorDatesOperatingHoursWorkOrder);*/
                    }
                }          
            }
            
            // Contrôle des membres de territoire 
            if (mapOperatingHoursIdToListOfSTM.containsKey(oh.Id)){ 
                for(ServiceTerritoryMember STMember: mapOperatingHoursIdToListOfSTM.get(oh.Id)){  
                    Date debut = STMember.EffectiveStartDate.Date();    
                    Date fin = null;  
                    
                    if(STMember.EffectiveEndDate!= null)
                        fin = STMember.EffectiveEndDate.Date();
                    
                    /*if(!FieldServiceUtils.crlCoherenceDate(oh.fsl_dateOuverture__c,oh.fsl_dateFermeture__c,debut,fin))
                        oh.addError (Label.fsl_errorDatesOperatingHoursServiceTerritoryMember);*/
                }
            }
            
            // Contrôle des territoires
            // Refonte GC : Contrôle obsolète après suppression des dates d'ouverture et fermeture
            /*if (mapOperatingHoursIdToListOfST.containsKey(oh.Id)){ 
                for(ServiceTerritory st: mapOperatingHoursIdToListOfST.get(oh.Id)){
                    if(!FieldServiceUtils.crlCoherenceDate(oh.fsl_dateOuverture__c,oh.fsl_dateFermeture__c,st.fsl_dateOuverture__c,st.fsl_dateFermeture__c))
                        oh.addError (Label.fsl_errorDatesOperatingHoursServiceTerritory); 
                }
            }*/
        }
    }
}