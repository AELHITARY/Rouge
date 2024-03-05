//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Asset_BeforeInsert
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/10/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
trigger Asset_BeforeInsert on Asset (before insert) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Asset.applyUpdateRules(context);
    }

    // KUBE3 - Process pour import données GC
    TR020_Asset.applyLegacyUpdateRules(context);
}