//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Asset_AfterUpdate
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/10/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
trigger Asset_AfterUpdate on Asset (after update) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_Asset')) {
        TR022_Asset.updateChildrenAssetsStatus(context);
    }
}