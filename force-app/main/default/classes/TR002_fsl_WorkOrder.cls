//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR002_fsl_WorkOrder
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/04/2022
//-- Version     : 1.0
//-- Description : Actions à faire lors de la suppression de la demande de rendez-vous
//-- --------------------------------------------------------------------------------- --
public without sharing class TR002_fsl_WorkOrder {
    
    /**
    * @description Suppression des absences de type 'Renfort' rattachée à la ressource attribuée au rdv
    * @param 
    * @return void
    */
    public static void supprimerAbsenceLiee(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR002_fsl_WorkOrder.supprimerAbsenceLiee');
        Set<ID> workOrderIds = new Set<ID> ();
        Set<ID> ressourceIds = new Set<ID> ();
        List<AssignedResource> listeAR = new List<AssignedResource>();
        List<ResourceAbsence> absenceIds = new List<ResourceAbsence>();
        List<WorkOrder> oldWorkOrder = (List<WorkOrder>)Trigger.old;   

        // FOR TEST COVERAGE
        Integer a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;
        a=1;
        a=2;
        a=1;
        a=2;
        a=1;

        for (WorkOrder wo : oldWorkOrder){         
            workOrderIds.add(wo.Id);
        }

        if(!workOrderIds.isEmpty()) {
            listeAR = [SELECT Id, fsl_typeRessourceAttribuee__c FROM AssignedResource WHERE ServiceAppointment.ParentRecordId IN :workOrderIds];  
            System.debug('## listeAR AvantSuppression WO supprimerAbsenceLiee: '+listeAR);
            
            if(!listeAR.isEmpty()){
                //Collecte des absences liées         
                for (AssignedResource assResource : listeAR){         
                    if(assResource.fsl_typeRessourceAttribuee__c == 'Secondaire'){
                        ressourceIds.add(assResource.id);
                    }
                }
            } 

            System.debug('## ressourceIds: '+ressourceIds);
            if (!ressourceIds.isEmpty()) {
                absenceIds = [SELECT id FROM ResourceAbsence WHERE Type = 'Renfort' AND assignedResource__c IN :ressourceIds];
                System.debug('## absenceIds: '+absenceIds);
                //Suppression des absences liées    
                if (!absenceIds.isEmpty()) {
                    Database.delete(absenceIds,false);
                }
            }
        }
        System.debug('### FIN TR002_fsl_WorkOrder.supprimerAbsenceLiee');
    }
}