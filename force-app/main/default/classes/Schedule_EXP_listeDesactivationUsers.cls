//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_EXP_listeDesactivationUsers
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 06/02/2019
//-- Version     : 1.0
//-- * 1.0 : KPKCRM_RQM-87 : Optimisation 
//-- --------------------------------------------------------------------------------- --
global class Schedule_EXP_listeDesactivationUsers implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext context)  {
        // Exécution du batch
        BA_EXP_listeDesactivationUsers ba = new BA_EXP_listeDesactivationUsers();
        Database.executeBatch(ba);   
    }
}