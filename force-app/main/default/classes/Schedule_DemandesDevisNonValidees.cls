//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_DemandesDevisNonValidees
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/06/2017
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_DemandesDevisNonValidees implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Context du batch
    */
    global void execute(SchedulableContext sc) {
        system.debug('#### START Schedule_DemandesDevisNonValidees.execute()');

        // Exécution du Batch pour les demandes de devis non validées
        BA_DemandesDevisNonValidees batch = new BA_DemandesDevisNonValidees();
        system.debug('START BA_DemandesDevisNonValidees');
        Id batchId = Database.executeBatch(batch,2); // Limite les lots à 2 enregistrements pour éviter limite sur WS
        system.debug('END BA_DemandesDevisNonValidees');

        // A EXECUTER VIA UNE EXECUTE FENETRE APEX ANONYME (Exeuction toutes les heures)
        // system.schedule('Demandes de devis non validées', '0 0 * * * ?', new Schedule_DemandesDevisNonValidees() );

        system.debug('#### END Schedule_DemandesDevisNonValidees.execute()');

    }
}