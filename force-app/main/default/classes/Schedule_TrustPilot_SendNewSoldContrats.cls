//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_TrustPilot_SendNewSoldContrats
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 17/09/2021
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_TrustPilot_SendNewSoldContrats implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        system.debug('#### START Schedule_TrustPilot_SendNewSoldContrats.execute()');

        // Exécution du Batch 
        BA_TrustPilot_SendNewSoldContrats batchAcc = new BA_TrustPilot_SendNewSoldContrats();
        database.executebatch(batchAcc,3); // Limite les lots à 100 (Limite Callout)

        // A EXECUTER VIA UNE EXECUTE FENETRE APEX ANONYME (Exection tous les jours à 7h)
        // system.schedule('Génération du fichier CSV de base SATCLI', '0 0 7 * * ? *', new Schedule_TrustPilot_SendNewSoldContrats() );

        system.debug('#### END Schedule_TrustPilot_SendNewSoldContrats.execute()');

    }
}