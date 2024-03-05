//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_FinancialCharge
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/11/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_FinancialCharge {

	/**
    * @description Méthode exécutant les différentes règles de validation pour les charges financière
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_FinancialCharge.applyValidationRules');
        
        List<FinancialCharge__c> oldFinancialCharges = (List<FinancialCharge__c>)Trigger.old;
        for(FinancialCharge__c oldFinancialCharge : oldFinancialCharges){
            // Ne pas supprimer si la charge est verrouillée
            if(oldFinancialCharge.isLocked__c && Trigger.isDelete && Trigger.isBefore){
                oldFinancialCharge.addError(Label.financialCharge_msg_cantDelete);
            }
        }
        
        System.debug('### FIN TR020_FinancialCharge.applyValidationRules');
    }
}