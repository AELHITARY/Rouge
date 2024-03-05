//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA002_OpportunitySharingRules
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/11/2022
//-- Version     : 1.1
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
global class BA002_OpportunitySharingRules implements Database.Batchable<sObject> {
	public Boolean JOB_EMAIL_FINISHED = false;
	global UserContext userCtx;

	/***** Constructor *****/
	global BA002_OpportunitySharingRules() {
		System.debug('### DEBUT BA002_OpportunitySharingRules.BA002_OpportunitySharingRules()');
		// Mise a jour des bypass de l'utilisateur
		userCtx = UserContext.getContext();
		userCtx.setByPassWorkflowRules(true);
		userCtx.setByPassTriggers(true);
		System.debug('### FIN BA002_OpportunitySharingRules.BA002_OpportunitySharingRules()');
	}

	global Database.querylocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Id, publicSharing__c FROM Opportunity WHERE publicSharing__c = false');
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		System.debug('### DEBUT BA002_OpportunitySharingRules.execute()');
		System.debug('## BA002_OpportunitySharingRules >>> scope (' + scope.size() + ')');
		try {
			TR020_SharingRulesProcess.OpportunityPublicSharingBatch((List<Opportunity>) scope, new Map<Id, Opportunity> ());
		}
		catch(Exception e) {
			EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de l\'initialisation du batch pour les règles de partage des projets', e);
			throw e;
		}
		System.debug('### FIN BA002_OpportunitySharingRules.execute()');
	}

	global void finish(Database.BatchableContext BC) {
		System.debug('### DEBUT BA002_OpportunitySharingRules.finish()');
		// Envoie d'un email a la fin du job si le flag JOB_EMAIL_FINISHED est à true
		if (JOB_EMAIL_FINISHED) {
			String destinatairesEmails = PropertiesUtils.getStringValue('email.exception', 'franck.gourdeaux@kpark.fr');
			String emailSubject = 'KparK - Batch Opportunity Sharing Rules finished';
			String emailMessage = 'Le batch Apex de calcul de partage sur l\'objet Opportunity (Projet) à fini son traitement';
			EmailUtils.mailTo(emailSubject, emailMessage, new String[] { destinatairesEmails });
		}
		System.debug('### FIN BA002_OpportunitySharingRules.finish()');
	}
}