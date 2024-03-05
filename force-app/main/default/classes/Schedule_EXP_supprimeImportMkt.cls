//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_EXP_expireDevis 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/07/2018
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
global class Schedule_EXP_supprimeImportMkt implements Schedulable{

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
      // Exécution du batch
      BA_EXP_supprimeImportMkt ba = new BA_EXP_supprimeImportMkt();
      Database.executeBatch(ba);      
    }
}