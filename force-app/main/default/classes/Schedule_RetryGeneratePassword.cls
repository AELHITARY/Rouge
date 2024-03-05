//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_RetryGeneratePassword 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/10/2017
//-- Version     : 1.0
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_RetryGeneratePassword implements Schedulable {
    
    /**
    * @description Méthode exécutant le process du batch
    * @param sc Contexte
    */
    global void execute(SchedulableContext sc) {
        system.debug('### START Schedule_RetryGeneratePassword ');

        // Exécution du batch
        BA_RetryGeneratePassword batch = new BA_RetryGeneratePassword();
        Database.executebatch(batch);

        system.debug('### END Schedule_RetryGeneratePassword ');
    }
}