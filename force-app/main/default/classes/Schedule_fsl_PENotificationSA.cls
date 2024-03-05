//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_fsl_PENotificationSA
//-- Modifié par : CGI
//-- Modifié le  : 27/03/2018
//-- Version     : 1.0
//-- Description : Planning d'envoies des notifications sur ServiceAppointment via Platform Event
//-- --------------------------------------------------------------------------------- --
global class Schedule_fsl_PENotificationSA implements Schedulable {
    
    global void execute(SchedulableContext sc){
        
        BA_fsl_NotificationSA notificationSA = new BA_fsl_NotificationSA();
        Id BatchSA = Database.ExecuteBatch(notificationSA);
        
    }
}