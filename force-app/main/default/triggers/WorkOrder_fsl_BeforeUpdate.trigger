//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : WorkOrder_fsl_BeforeUpdate
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger before update sur la demande de rendez-vous
//-- --------------------------------------------------------------------------------- --

trigger WorkOrder_fsl_BeforeUpdate on WorkOrder(before update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_WorkOrder.applyValidationRules(context); 
    }  
    
    if (context == null || !context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_WorkOrder')) {
        TR001_fsl_WorkOrder.crlCoherenceDateValidite(context); 
    }  
}