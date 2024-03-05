//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_GDPRChantierExpDate
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 01/11/2018
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class Schedule_GDPRChantierExpDate implements Schedulable {

    /**
    * @description Méthode exécutant le process du batch
    * @param sc Context du batch
    */
    global void execute(SchedulableContext sc) {
        system.debug('#### START Schedule_GDPRChantierExpDate.execute()');

        // Exécution du Batch 
        BA_GDPRChantierExpDate batch = new BA_GDPRChantierExpDate();
        system.debug('START BA_GDPRChantierExpDate');
        Id batchId = Database.executeBatch(batch, 100);
        system.debug('END BA_GDPRChantierExpDate');

        system.debug('#### END Schedule_GDPRChantierExpDate.execute()');

    }
}