//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_EXP_desactiveUsers
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 06/02/2019
//-- Version     : 1.0
//-- * 1.0 : KPKCRM_RQM-87 : Optimisation 
//-- --------------------------------------------------------------------------------- --
global class Schedule_EXP_desactiveUsers implements Schedulable{

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        
      // Exécution du batch
      DisableInactiveUsersBatch ba = new DisableInactiveUsersBatch();
      Database.executeBatch(ba);      
    }
}