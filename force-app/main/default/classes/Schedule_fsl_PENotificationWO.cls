//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_fsl_PENotificationWO
//-- Modifié par : CGI
//-- Modifié le  : 27/03/2018
//-- Version     : 1.0
//-- Description : Planning d'envoies des notifications sur WorkOrder via Platform Event
//-- --------------------------------------------------------------------------------- --
global class Schedule_fsl_PENotificationWO implements Schedulable {
    
    global void execute(SchedulableContext sc){
        
        BA_fsl_NotificationWO notificationWO = new BA_fsl_NotificationWO();
        Id BatchWO = Database.ExecuteBatch(notificationWO);
        
        
        
    }
}