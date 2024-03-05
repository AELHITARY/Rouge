//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_EinsteinPipelineCSV
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/11/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_EinsteinPipelineCSV implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        System.debug('### DEBUT Schedule_EinsteinPipelineCSV.execute');

        // Exécution du Batch 
        BA_EinsteinPipelineCSV ba = new BA_EinsteinPipelineCSV();
        Database.executebatch(ba); 

        System.debug('### FIN Schedule_EinsteinPipelineCSV.execute');

    }
}