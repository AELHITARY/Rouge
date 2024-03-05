//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_ApprovalProcess 
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 29/11/2021
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_ApprovalProcess {

    /**
    * @description Méthode pour envoyer un Plateform Event pour valider/refuser/désactiver un processus d'approbation
    * @param inputList Liste des paramètres d'entrée
    */
    @InvocableMethod(label='Evenement processus approbation' description='Exécute un événement pour un processus d\'approbation')
    public static void eventApproval(List<FlowInputParameters> inputList) {     
        System.debug('### DEBUT IV_ApprovalProcess.eventApproval'); 
        System.debug('## inputList: '+inputList);
        List<ApprovalEvent__e> approvalEvents = new List<ApprovalEvent__e>();
        
        try {
            // Récupération des paramètres d'entrée
            FlowInputParameters param = inputList[0];
            
            List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId 
                                                        FROM ProcessInstanceWorkitem 
                                                        WHERE ProcessInstance.Status = 'Pending' 
                                                        AND ProcessInstance.TargetObjectId = :param.recordId];    
            System.debug('## workItems: '+workItems);    
            
            for(ProcessInstanceWorkitem workItem : workItems) {
                approvalEvents.add(new ApprovalEvent__e(
                    processInstanceWorkitemId__c = workItem.Id,
                    recordId__c = workItem.ProcessInstance.TargetObjectId,
                    action__c = param.action,
                    comment__c = param.comment,
                    otherId__c = param.otherRecordId
                ));
            }  
            System.debug('## approvalEvents: '+approvalEvents);
            
            // Publication des events pour exécution trigger
            if(!approvalEvents.isEmpty()) {
                EventBus.publish(approvalEvents);    
            }
            System.debug('### FIN IV_ApprovalProcess.eventApproval');
        } catch(Exception e){
            throw e;
        }
    }
    
    // Input parameters for the Apex action 
    public class FlowInputParameters{
        @InvocableVariable(label='ID' required = true )
        public Id recordId;
        @InvocableVariable(label='Action' required = true)
        public String action;
        @InvocableVariable(label='Commentaire' required = false)
        public String comment;        
        @InvocableVariable(label='Autre ID' required = false)
        public Id otherRecordId;
    }
    public class FlowActionException extends Exception {}
}