//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_fsl_Desactivation
//-- Modifié par : CGI
//-- Modifié le  : 05/04/2018
//-- Version     : 1.0
//-- Description : Planning de la activation/désactivation référentielle par rapportaux dates de validité
//-- --------------------------------------------------------------------------------- --
global class Schedule_fsl_Desactivation implements Schedulable {
    
    global void execute(SchedulableContext sc){
        BA_fsl_Desactivation ba = new BA_fsl_Desactivation();
        Id batchID = Database.ExecuteBatch(ba);              
    }
}