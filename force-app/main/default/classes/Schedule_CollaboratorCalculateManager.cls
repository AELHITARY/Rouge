//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_CollaboratorCalculateManager
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/12/2020
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_CollaboratorCalculateManager implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        System.debug('### DEBUT Schedule_CollaboratorCalculateManager.execute');

        // Exécution du Batch 
        BA_CollaboratorCalculateManager ba = new BA_CollaboratorCalculateManager();
        Database.executebatch(ba, 2); //Limitation des lots à 2 pour empecher erreur de limite car récursivité 

        System.debug('### FIN Schedule_CollaboratorCalculateManager.execute');

    }
}