//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_fsl_CalendrierService
//-- Modifié par : CGI
//-- Modifié le  : 27/03/2018
//-- Version     : 1.0
//-- Description : Planning d'envoies des notifications sur WorkOrder via Platform Event
//-- --------------------------------------------------------------------------------- --

global class Schedule_fsl_CalendrierService implements Schedulable {
    
    global void execute(SchedulableContext sc){
        
        BA_fsl_CalendrierService batch = new BA_fsl_CalendrierService();
        Id BatchID = Database.ExecuteBatch(batch);
        
        
        
    }
}