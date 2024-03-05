//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : DemandeRDV_fsl_AfterInsert
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger after insert sur la demande de rendez-vous
//-- --------------------------------------------------------------------------------- --

trigger DemandeRDV_fsl_AfterInsert on DemandeRDV__e (after insert) {
    
    UserContext context = UserContext.getContext();
    if (context == null || !context.canByPassTrigger('TR001_fsl_PlatformEvent'))
    //Créer des WorkOrders
    TR001_fsl_PlatformEvent.addOrUpdateWOs(Trigger.new);    
     
    
}