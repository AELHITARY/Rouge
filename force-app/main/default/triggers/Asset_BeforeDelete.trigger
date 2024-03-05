//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Asset_BeforeDelete
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/04/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
trigger Asset_BeforeDelete on Asset (before delete) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassValidationRules()) {
        TR020_Asset.applyValidationRules(context);
    }
    
    if (context == null || !context.canByPassTrigger('TR022_Asset')) {
        TR022_Asset.deleteChildrenAssets(context);
    }
}