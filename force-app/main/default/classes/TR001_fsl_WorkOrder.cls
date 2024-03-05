//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_WorkOrder
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- --------------------------------------------------------------------------------- --
public without sharing class TR001_fsl_WorkOrder {
    private static final String WO_OLDRECORDTYPE_ID = DAL.getRecordTypeIdByDevName('WorkOrder', 'FSL_workOrder');
    
    /**
    * @description Déclenche une erreur si la cohérence des dates de validation n'est pas respectée
    * @param Trigger.new
    * @return  Message d'erreur 
    */
    public static void crlCoherenceDateValidite(UserContext context){
        if (!Trigger.isExecuting) {
            return;             
        }
        
        // Construire le map de liste de rendez-vous par demande de rdv  
        Map<Id,List<ServiceAppointment>> mapWorkOrderIdToListOfSA = new Map<Id,List<ServiceAppointment>>(); 
        List<Id> woIdList = new List<Id>(); 
        Map<ID, User> mapUserPrefere = new Map<ID,User>();            
        List<ID> listeUserPrefere = new List<ID>();  
        Map<Id,List<ID>> mapWOIdToListOfRessource = new Map<Id,List<ID>>();   
        Map<Id, WorkOrder> oldWorkOrders = (Map<Id, WorkOrder>)Trigger.oldMap;

        for (WorkOrder newWorkOrder : (List<WorkOrder>)Trigger.new) {
            WorkOrder oldWorkOrder = oldWorkOrders == null ? null : oldWorkOrders.get(newWorkOrder.Id);
            if(newWorkOrder.RecordTypeId == WO_OLDRECORDTYPE_ID && Trigger.isUpdate && (oldWorkOrder.StartDate != newWorkOrder.StartDate || oldWorkOrder.EndDate != newWorkOrder.EndDate)) {
                woIdList.add(newWorkOrder.Id);
            }
        }
        
        if(!woIdList.isEmpty()) {
            for(ServiceAppointment sa: [SELECT EarliestStartTime,DueDate,ParentRecordId FROM ServiceAppointment WHERE ParentRecordId IN :woIdList]){
                if(mapWorkOrderIdToListOfSA.containsKey(sa.ParentRecordId)){
                    List<ServiceAppointment> listeSA = mapWorkOrderIdToListOfSA.get(sa.ParentRecordId);
                    listeSA.add(sa);
                    mapWorkOrderIdToListOfSA.put(sa.ParentRecordId, listeSA);
                } else {
                    mapWorkOrderIdToListOfSA.put(sa.ParentRecordId, new List<ServiceAppointment> {sa});                            
                }
            }            
            
            //Construire le map de liste de ressources préférées par demande de rdv
            for(ResourcePreference preference : [SELECT ServiceResource.RelatedRecordId,RelatedRecordId FROM ResourcePreference WHERE RelatedRecordId IN :woIdList]){
                listeUserPrefere.add(preference.ServiceResource.RelatedRecordId);
                if(mapWOIdToListOfRessource.containsKey(preference.RelatedRecordId)){
                    List<ID> listeRP = mapWOIdToListOfRessource.get(preference.RelatedRecordId);
                    listeRP.add(preference.ServiceResource.RelatedRecordId);                
                    mapWOIdToListOfRessource.put(preference.RelatedRecordId, listeRP);
                }else {
                    mapWOIdToListOfRessource.put(preference.RelatedRecordId, new List<ID> { preference.ServiceResource.RelatedRecordId}); 
                    System.debug('###DEBUG id wo'+ preference.RelatedRecordId);
                    System.debug('###DEBUG id user préféré'+ preference.ServiceResource.RelatedRecordId );
                }       
            }
            
            if(!listeUserPrefere.isEmpty()) {
                mapUserPrefere = new Map<ID,User>([SELECT dateEntree__c, dateSortie__c FROM User WHERE Id IN :listeUserPrefere]); 
            }
            
            for (WorkOrder wo : (List<WorkOrder>)Trigger.new){  
                // SOPRA : Ne pas prendre en compte les nouveaux record type
                if(wo.RecordTypeId == WO_OLDRECORDTYPE_ID) {
                    // Contrôle des rendez-vous rattachées  
                    if (mapWorkOrderIdToListOfSA.containsKey(wo.Id)){
                        for(ServiceAppointment sa: mapWorkOrderIdToListOfSA.get(wo.Id)) {
                            
                            if (!FieldServiceUtils.crlCoherenceDateTime(FieldServiceUtils.replaceIfNull(wo.StartDate, System.Now()),FieldServiceUtils.replaceIfNull(wo.EndDate, (FieldServiceUtils.replaceIfNull(wo.StartDate, System.Now()).addMonths(1))),sa.EarliestStartTime,sa.DueDate)) {
                                wo.addError (Label.fsl_errorDatesServiceAppointmentWorkOrder);
                            }
                        }          
                    }   
                    System.debug('**Debug** mapWOIdToListOfRessource'+mapWOIdToListOfRessource);
                    
                    // Contrôle des WorkOrder avec ressource préférée
                    if (context!= null){
                        if (!context.getProfile().name.contains('Ressource')){
                            if (mapWOIdToListOfRessource.containsKey(wo.Id)){                       
                                Date StartDate = (FieldServiceUtils.replaceIfNull(wo.StartDate, System.Now())).Date();
                                Date EndDate = (FieldServiceUtils.replaceIfNull(wo.EndDate, (FieldServiceUtils.replaceIfNull(wo.StartDate, System.Now()).addMonths(1)))).Date();
                                
                                for(ID userId: mapWOIdToListOfRessource.get(wo.id)){
                                    User u = mapUserPrefere.get(userId); 
                                    if (!FieldServiceUtils.crlCoherenceDate(u.dateEntree__c,u.dateSortie__c,StartDate,EndDate)){
                                        wo.addError (Label.fsl_errorDatesResourcePreferenceWorkOrder);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}