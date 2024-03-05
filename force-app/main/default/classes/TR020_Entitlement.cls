//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Entitlement
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/03/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Entitlement {
    /**
    * @description Méthode pour confirmer l'autorisation de la suppression de la garantie si l'actif ou la commande associé n'est pas verrouillé
    * @param userContext contexte utilisateur
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### START TR020_Entitlement.applyValidationRules');
        
        List<Entitlement> oldEntitlements = (List<Entitlement>)Trigger.old;
        for(Entitlement oldEntitlement : oldEntitlements){
            // Ne pas supprimer si l'asset ou la commande est verrouillé
            if((oldEntitlement.isAssetLocked__c || oldEntitlement.isOrderLocked__c) && Trigger.isDelete && Trigger.isBefore){
                oldEntitlement.addError(Label.asset_msg_cantDeleteEntitlement);
            } 
        }
        
        System.debug('### FIN TR020_Entitlement.applyValidationRules');
    }
}