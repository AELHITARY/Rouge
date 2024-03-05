//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_EXP_listeInactiviteUsers
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 06/02/2019
//-- Version     : 1.0
//-- * 1.0 : KPKCRM_RQM-87 : Optimisation 
//-- --------------------------------------------------------------------------------- --
global class Schedule_EXP_listeInactiviteUsers implements Schedulable{

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
      // Exécution du batch
      BA_EXP_listeInactiviteUsers ba = new BA_EXP_listeInactiviteUsers();
      Database.executeBatch(ba);      
    }
}