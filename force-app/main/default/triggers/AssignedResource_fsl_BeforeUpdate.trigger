//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : AssignedResource_fsl_BeforeUpdate 
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger before update sur les Ressources attribuées
//-- --------------------------------------------------------------------------------- --

trigger AssignedResource_fsl_BeforeUpdate on AssignedResource (before update) {
  UserContext context = UserContext.getContext();
  
  if (context == null || !context.canByPassTrigger('TR001_fsl_AssignedResource') )
   TR001_fsl_AssignedResource.modifierAbsenceLiee(context);
  
  if (context == null || (!context.canByPassValidationRules() && !context.canByPassTrigger('TR002_fsl_AssignedResource')))
   TR002_fsl_AssignedResource.crlCoherenceDateValidite(context);
}