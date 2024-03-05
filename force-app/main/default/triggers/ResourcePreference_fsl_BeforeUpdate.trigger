//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : ResourcePreference_fsl_BeforeUpdate 
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger before update sur les Ressources préférées
//-- --------------------------------------------------------------------------------- --

trigger ResourcePreference_fsl_BeforeUpdate on ResourcePreference (before update) {
  UserContext context = UserContext.getContext();
  
  if (context == null || (!context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_ResourcePreference')))
   TR001_fsl_ResourcePreference.crlCoherenceDateValidite(context);
}