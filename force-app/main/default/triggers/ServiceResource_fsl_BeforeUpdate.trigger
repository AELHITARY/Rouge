//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : ServiceResource_fsl_BeforeUpdate
//-- Modifié par : CGI
//-- Modifié le  : 16/05/2018
//-- Version     : 1.0
//-- Description : Trigger before update sur la ressource
//-- --------------------------------------------------------------------------------- --

trigger ServiceResource_fsl_BeforeUpdate on ServiceResource (before update) {
    UserContext context = UserContext.getContext();
    
   if (context == null || (!context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_ServiceResource')))
        TR001_fsl_ServiceResource.crlCoherenceValidite(context);

}