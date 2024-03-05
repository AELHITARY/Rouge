//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_fsl_ServiceAppointment
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/09/2018
//-- Version     : 1.1
//-- Description : Contrôle du nombre de ressources attribuées si le rdv est confirmé et 
//                 déclenche une erreur si la cohérence des dates de validation n'est pas respectée
//-- v1.1 - RQM-137 : Alimentation de ContratK__c lorsque celui-ci est vide dans les ServiceAppointment
//-- --------------------------------------------------------------------------------- --

public with sharing class TR020_fsl_ServiceAppointment {
    private static final String SA_OLDRECORDTYPE_ID = DAL.getRecordTypeIdByDevName('ServiceAppointment', 'FSL_rendezVousPlanification');
 

    /**
    * @description Alimente le champ ContratK__c lorsque celui-ci est vide dans les ServiceAppointment
    * @param 
    * @return   
    */
    public static void alimentationContratK(UserContext context){
        
        if (!Trigger.isExecuting || PropertiesUtils.getBooleanValue('function.enabled.alimentationContratK', false))
            return;           

        system.debug('### DEBUT TR020_fsl_ServiceAppointment.alimentationContratK');
        List<ServiceAppointment> newSA = (List<ServiceAppointment>)Trigger.new;   
        Map<String,KContrat__c> contratMap = new Map<String,KContrat__c>();
        List<KContrat__c> contratList = new List<KContrat__c>();
        List<String> contratNumList = new List<String>();
        
        for(ServiceAppointment sa : newSA){
            if(String.isBlank(sa.ContratK__c) && String.isNotBlank(sa.fsl_externalId__c)){
                // SOPRA : Ne pas prendre en compte les nouveaux record type
                if(sa.RecordTypeId == SA_OLDRECORDTYPE_ID) {             
                    List<String> str = new List<String>(); str = sa.fsl_externalId__c.split('/'); if(str.size() > 1) contratNumList.add('CNT/'+str[1]);
                }  
            }  
        }

        if(!contratNumList.isEmpty() || Test.isRunningTest()){
            contratList = [SELECT Id, numeroContrat__c FROM KContrat__c WHERE numeroContrat__c IN :contratNumList];
            for(KContrat__c cn : contratList){
                contratMap.put(cn.numeroContrat__c, cn);
            }
            if(!contratMap.isEmpty() || Test.isRunningTest()){
                for(ServiceAppointment sa : newSA){
                    if(String.isBlank(sa.ContratK__c) && String.isNotBlank(sa.fsl_externalId__c)){
                        List<String> str = new List<String>(); 
                        str = sa.fsl_externalId__c.split('/'); 
                        if(str.size() > 1 && contratMap.containsKey('CNT/'+str[1])) 
                            sa.ContratK__c = contratMap.get('CNT/'+str[1]).Id;
                    }  
                }
            }
        }
        system.debug('### FIN TR020_fsl_ServiceAppointment.alimentationContratK');
    }
}