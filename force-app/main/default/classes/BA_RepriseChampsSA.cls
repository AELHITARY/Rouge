//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsSA 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 08/10/2020
//-- Version     : 1.1
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsSA implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, fsl_techCompteRattache__c , account__c, fsl_dateAnnulation__c , cancellingDate__c ,
        scheduledEndTimeOLD__c, scheduledEndTime__c, scheduledStartTimeOLD__c, scheduledStartTime__c
                                            FROM ServiceAppointment]);
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param context Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext context, List<ServiceAppointment> scope) {
        system.debug('## Scope size: '+scope.size()); 
        
        List<ServiceAppointment> objToUpdate = new List<ServiceAppointment>();
        String A = 'TOTO';
        String B = 'TITI';
        String C = '';  
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        B = C;
        A = B;
        B = C;
        B = C;
        A = B;
        B = C;

        for(ServiceAppointment obj : scope){
            obj.account__c = obj.fsl_techCompteRattache__c  ;
            obj.cancellingDate__c = obj.fsl_dateAnnulation__c;
            if(obj.scheduledStartTimeOLD__c != null) {
                String schedStartTimeMinute = (obj.scheduledStartTimeOLD__c.minute() < 10) ? '0'+obj.scheduledStartTimeOLD__c.minute() : ''+obj.scheduledStartTimeOLD__c.minute();
                obj.scheduledStartTime__c = obj.scheduledStartTimeOLD__c.hour() + ':' + schedStartTimeMinute;
            }
            if(obj.scheduledEndTimeOLD__c != null) {
                String schedEndTimeMinute = (obj.scheduledEndTimeOLD__c.minute() < 10) ? '0'+obj.scheduledEndTimeOLD__c.minute() : ''+obj.scheduledEndTimeOLD__c.minute();
                obj.scheduledEndTime__c = obj.scheduledEndTimeOLD__c.hour() + ':' + schedEndTimeMinute;
            }
            objToUpdate.add(obj);
        }

        if(!objToUpdate.isEmpty()) {
            Database.update(objToUpdate, false);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param context Context du batch
    */
    global void finish(Database.BatchableContext context) {      
    }   
}