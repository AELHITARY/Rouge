//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Order_BeforeInsert 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 02/10/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
trigger Order_BeforeInsert on Order (before insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {        
        TR020_Order.applyValidationRules(context);
    }
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Order.applyUpdateRules(context);
    }
}