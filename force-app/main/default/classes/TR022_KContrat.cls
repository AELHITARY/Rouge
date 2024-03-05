//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_KContrat
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/11/2018
//-- Version     : 1.1
//-- * 1.1 - Ajout de la fonction calcul des dates
//-- * 1.0 - Ajout de la fonction pour les notifications
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_KContrat {

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
            Utils_CalculateStatus.refreshAccountStatusFromContrat(Trigger.new);              
        } catch(exception e) {
            system.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
    }
}