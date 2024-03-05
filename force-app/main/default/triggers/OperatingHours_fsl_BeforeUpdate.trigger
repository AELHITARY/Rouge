//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : OperatingHours_fsl_BeforeUpdate
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger before update sur l'heure de fonctionnement
//-- --------------------------------------------------------------------------------- --

trigger OperatingHours_fsl_BeforeUpdate on OperatingHours(before update) {
    UserContext context = UserContext.getContext();
    
   if (context == null || (!context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_OperatingHours')))
        TR001_fsl_OperatingHours.crlCoherenceDateValidite(context);

}