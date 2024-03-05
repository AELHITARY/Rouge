//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_SharingRulesBatch
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/11/2022
//-- Version     : 1.1
//-- * Optimisation
//-- --------------------------------------------------------------------------------- --
global class Schedule_SharingRulesBatch implements Schedulable {
    public Boolean JOB_EMAIL_FINISHED = null;

    /***** Constructor *****/
    global Schedule_SharingRulesBatch() {
        System.debug('## START Schedule_SharingRulesBatch.Schedule_SharingRulesBatch()');
        if (this.JOB_EMAIL_FINISHED == null) {
            this.JOB_EMAIL_FINISHED = false;
        }
        System.debug('## END Schedule_SharingRulesBatch.Schedule_SharingRulesBatch()');
    }

    /***** 01 - The execute method is called when schedule start. *****/
    global void execute(SchedulableContext sc) {
        System.debug('### START Schedule_SharingRulesBatch.execute()');

        // Exécution du Batch pour les Opportunités (Projets)
        BA002_OpportunitySharingRules batchOpportunity = new BA002_OpportunitySharingRules();
        batchOpportunity.JOB_EMAIL_FINISHED = JOB_EMAIL_FINISHED;
        System.debug('START BA002_OpportunitySharingRules');
        Id batchId_BA002Opp = Database.executeBatch(batchOpportunity, 100);
        System.debug('END BA002_OpportunitySharingRules');

        System.debug('### END Schedule_BA001Ressources.execute()');
    }
}