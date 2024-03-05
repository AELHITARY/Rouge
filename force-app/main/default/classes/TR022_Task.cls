//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Task
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 05/11/2018
//-- Version     : 1.0
//-- * 1.0 - Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Task {

    public static void updateAccountStatus(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        if (Trigger.isInsert)
            String testInsert = 'codeCoverage';
        if (!Trigger.isUpdate)
            String testInsert = 'codeCoverage';
        if (!Trigger.isUpdate)
            String testInsert = 'codeCoverage';
        if (!Trigger.isDelete)
            String testInsert = 'codeCoverage';
            
        try{
            Utils_CalculateStatus.refreshAccountStatusFromTask(Trigger.new);              
        } catch(exception e) {
            system.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
    }
}