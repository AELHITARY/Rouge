//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_PipelineGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/01/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
global class Schedule_PipelineGeneratePDF implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        System.debug('### DEBUT Schedule_PipelineGeneratePDF.execute');

        // Récupération de la date du dimanche précédent la date du jour
        Datetime dateLastSunday = Date.today().toStartOfWeek().addDays(-1);
        Date generationDate = dateLastSunday.date();
        System.debug('## generationDate: '+generationDate);

        // Exécution du Batch (Lot de 1 car appel API)
        BA_GeneratePipeline ba = new BA_GeneratePipeline(null, generationDate, 'pdf', false);
        Database.executebatch(ba, 1); 

        System.debug('### FIN Schedule_PipelineGeneratePDF.execute');

    }
}