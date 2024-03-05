//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_CalculateOrderStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 29/06/2023
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_CalculateOrderStatusGC implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        System.debug('### DEBUT Schedule_CalculateOrderStatusGC.execute');

        // Exécution du Batch 
        BA_CalculateOrderStatusGC ba = new BA_CalculateOrderStatusGC();
        Database.executebatch(ba); 

        // A EXECUTER VIA UNE EXECUTE FENETRE APEX ANONYME (Exeuction toutes les heures)
        // system.schedule('Recalcul statut GC', '0 0 * * * ?', new Schedule_CalculateOrderStatusGC() );

        System.debug('### FIN Schedule_CalculateOrderStatusGC.execute');

    }
}