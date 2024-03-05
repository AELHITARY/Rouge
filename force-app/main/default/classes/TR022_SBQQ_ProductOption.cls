//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_SBQQ_ProductOption
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 21/12/2020
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public with sharing class TR022_SBQQ_ProductOption {
    /**
    * @description Mise à jour des durées d'interventions des casesItems
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateCaseItemInterventionDuration(UserContext userContext){
        System.debug('### DEBUT TR022_SBQQ_ProductOption.updateCaseItemInterventionDuration');
        if (Trigger.isUpdate) {
            // 1 - DATA INIT
            List<SBQQ__ProductOption__c> newProductsOptions = (List<SBQQ__ProductOption__c>)Trigger.new;
            Map<Id, SBQQ__ProductOption__c> oldProductsOptions = (Map<Id,SBQQ__ProductOption__c>)Trigger.oldMap;
            Map<Id, SBQQ__ProductOption__c> updatedProductsOptions = new Map<Id,SBQQ__ProductOption__c>();

            for(SBQQ__ProductOption__c newProductOption : newProductsOptions){
                SBQQ__ProductOption__c oldProductOption = oldProductsOptions.get(newProductOption.Id);
                if(newProductOption.interventionDuration__c != oldProductOption.interventionDuration__c){
                    updatedProductsOptions.put(newProductOption.Id,newProductOption);
                }
            }

            //2 - UPDATE
            List<CaseItem__c> updatedCaseItem= new List<CaseItem__c>();

            if(!updatedProductsOptions.isEmpty()){
                for (CaseItem__c caseItem : [SELECT Id, interventionDuration__c, productOption__c FROM CaseItem__c WHERE productOption__c IN:updatedProductsOptions.keySet()]){
                    SBQQ__ProductOption__c updatedProductOption = updatedProductsOptions.get(caseItem.productOption__c);
                    caseItem.interventionDuration__c= updatedProductOption.interventionDuration__c;
                    updatedCaseItem.add(caseItem);
                }
                if(!updatedCaseItem.isEmpty()){
                    update updatedCaseItem;
                }
            }
        }
        System.debug('### FIN TR022_SBQQ_ProductOption.updateCaseItemInterventionDuration');
    }
}