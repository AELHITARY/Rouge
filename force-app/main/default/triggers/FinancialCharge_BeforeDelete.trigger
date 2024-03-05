//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : FinancialCharge_BeforeDelete
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/11/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
trigger FinancialCharge_BeforeDelete on FinancialCharge__c (before delete) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassValidationRules()) { 
        TR020_FinancialCharge.applyValidationRules(context);
    }
}