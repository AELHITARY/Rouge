//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_PipelineGenerateExcel
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/01/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
global class Schedule_PipelineGenerateExcel implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        System.debug('### DEBUT Schedule_PipelineGenerateExcel.execute');

        // Exécution du Batch (Lot de 1 car appel API)
        BA_GeneratePipeline ba = new BA_GeneratePipeline(null, Date.today(), 'xlsx', false);
        Database.executebatch(ba, 1); 

        System.debug('### FIN Schedule_PipelineGenerateExcel.execute');

    }
}