//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : ResourcePreference_fsl_AfterInsert 
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger after insert sur les Ressources préférées
//-- --------------------------------------------------------------------------------- --

trigger ResourcePreference_fsl_AfterInsert on ResourcePreference (after insert) {
UserContext context = UserContext.getContext();
  
  if (context == null || (!context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_ResourcePreference')))
   TR001_fsl_ResourcePreference.crlCoherenceDateValidite(context);
}