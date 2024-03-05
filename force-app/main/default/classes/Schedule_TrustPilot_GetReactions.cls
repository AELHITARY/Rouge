//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_TrustPilot_GetReactions
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 05/03/2019
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_TrustPilot_GetReactions implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        system.debug('#### START Schedule_TrustPilot_GetReactions.execute()');

        // Exécution du Batch 
        BA_TrustPilot_GetReactionsCreateCases batchAcc = new BA_TrustPilot_GetReactionsCreateCases();
        database.executebatch(batchAcc); // Limite les lots à 100 (Limite Callout)

        // A EXECUTER VIA UNE EXECUTE FENETRE APEX ANONYME (Exeuction toutes les heures)
        // system.schedule('Génération du fichier CSV de base SATCLI', '0 0 0 1 * ? *', new Schedule_TrustPilot_GetReactions() );

        system.debug('#### END Schedule_TrustPilot_GetReactions.execute()');

    }
}