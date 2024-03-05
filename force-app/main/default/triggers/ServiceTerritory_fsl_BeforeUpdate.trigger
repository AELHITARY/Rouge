//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : ServiceTerritory_fsl_BeforeUpdate
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger before update sur le territoire de service
//-- --------------------------------------------------------------------------------- --

trigger ServiceTerritory_fsl_BeforeUpdate on ServiceTerritory (before update) {
    UserContext context = UserContext.getContext();
    
   if (context == null || (!context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_ServiceTerritory')))
        TR001_fsl_ServiceTerritory.crlCoherenceDateValidite(context);

}