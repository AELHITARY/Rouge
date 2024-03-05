//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_Fusion
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/03/2017
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_Fusion implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        system.debug('#### START Schedule_Fusion.execute()');

        // Exécution du Batch 
        system.enqueueJob(new QA_Fusion());

        // A EXECUTER VIA UNE EXECUTE FENETRE APEX ANONYME (Exeuction toutes les heures)
        // system.schedule('Fusion des enregistrements', '0 0 * * * ?', new Schedule_Fusion() );

        system.debug('#### END Schedule_Fusion.execute()');

    }
}