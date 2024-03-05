//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_SynchroDQE
//-- Modifié par : SOPRA STERIA - Julien Morineau
//-- Modifié le  : 12/05/2017
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_SynchroDQE implements Schedulable {
    
    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        system.debug('### START Schedule_SynchroDQE');

        // Exécution du Batch des comptes
        BA_SynchroAccountDQE batchAcc = new BA_SynchroAccountDQE();
        database.executebatch(batchAcc,100); // Limite les lots à 100 (Limite Callout)

        // Exécution du Batch des chantiers
        BA_SynchroChantierDQE batchCha = new BA_SynchroChantierDQE();
        database.executebatch(batchCha,100); // Limite les lots à 100 (Limite Callout)

        system.debug('### END Schedule_SynchroDQE');
    }
}