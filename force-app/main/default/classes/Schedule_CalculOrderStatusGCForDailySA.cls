//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_CalculOrderStatusGCForDailySA
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 11/07/2023
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_CalculOrderStatusGCForDailySA implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        System.debug('### DEBUT Schedule_CalculOrderStatusGCForDailySA.execute');

        // Exécution du Batch 
        BA_CalculateOrderStatusGCForDailySA ba = new BA_CalculateOrderStatusGCForDailySA();
        Database.executebatch(ba); 

        // A EXECUTER VIA UNE EXECUTE FENETRE APEX ANONYME (Exeuction toutes les heures)
        // system.schedule('Recalcul statut GC', '0 0 * * * ?', new Schedule_CalculOrderStatusGCForDailySA() );

        System.debug('### FIN Schedule_CalculOrderStatusGCForDailySA.execute');

    }
}