//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Asset_BeforeUpdate
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/04/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
trigger Asset_BeforeUpdate on Asset (before update) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Asset.applyUpdateRules(context);
    }
}