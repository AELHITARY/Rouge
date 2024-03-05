//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_TimeSheetCreation 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 29/07/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class Schedule_TimeSheetCreation implements Schedulable{

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BA_TimeSheetCreation(Date.today()), 5); // Mois courant
        Database.executeBatch(new BA_TimeSheetCreation(Date.today().addMonths(1)), 5); // Mois prochain
    }
}