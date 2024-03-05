//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_CalculateOrderStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/10/2022
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_RecalculHistoOrderStatusGC implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        System.debug('### DEBUT Schedule_RecalculHistoOrderStatusGC.execute');

        // Exécution du Batch 
        BA_RecalculHistoOrderStatusGC ba = new BA_RecalculHistoOrderStatusGC();
        Database.executebatch(ba); 

        System.debug('### FIN Schedule_RecalculHistoOrderStatusGC.execute');

    }
}