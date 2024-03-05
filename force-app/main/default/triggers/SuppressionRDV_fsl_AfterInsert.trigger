//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : SuppressionRDV_fsl_AfterInsert
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger after insert sur la suppression de rendez-vous
//-- --------------------------------------------------------------------------------- --

trigger SuppressionRDV_fsl_AfterInsert on SuppressionRDV__e (after insert) {
    
    
    UserContext context = UserContext.getContext();
    if (context == null || !context.canByPassTrigger('TR001_fsl_PlatformEvent'))
    //supprimer des WorkOrders    
    TR001_fsl_PlatformEvent.deleteWOs(Trigger.new);
    
    
    
}