//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Option
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 27/01/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public with sharing class TR020_Option {
    
    /**
    * @description Méthode exécutant les différentes règles de validation pour les options de lignes de devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_Option.applyValidationRules');        
        List<Option__c> oldOpts = (List<Option__c>)Trigger.old;
                
        for(Option__c oldOpt : oldOpts){
            if(oldOpt.optionDeletable__c == false && Trigger.isDelete && Trigger.isBefore) {
                System.debug('## Cannot delete Option: ' + oldOpt.Id);
                oldOpt.addError(Label.quote_error_cantDeleteQuoteLine);
            }  
        }
        
        System.debug('### FIN TR020_Option.applyValidationRules');
    }
}