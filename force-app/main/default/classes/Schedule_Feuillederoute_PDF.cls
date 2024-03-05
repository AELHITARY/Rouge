//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_Feuillederoute_PDF
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 19/10/2015
//-- Version     : 1.1
//-- * Initialisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_Feuillederoute_PDF implements Schedulable {

	/**
	*
	*   Méthode exécutant le process du batch
	*
	**/
	global void execute(SchedulableContext sc) {
		system.debug('#### START Schedule_Feuillederoute_PDF.execute()');

		// Exécution du Batch pour les feuille de route en PDF par lot de 100 utilisateurs
		BA_FeuillederoutePDF batch = new BA_FeuillederoutePDF();
		system.debug('START BA_FeuillederoutePDF');
		Id batchId = Database.executeBatch(batch, 100);
		system.debug('END BA_FeuillederoutePDF');

		system.debug('#### END Schedule_Feuillederoute_PDF.execute()');
	}
}