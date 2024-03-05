//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsProduit 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 03/11/2020
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsProduit implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, Reference__c,ProductCode, ExternalId, Famille__c,Family, unit__c FROM Product2]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise de l\'objet Product2 : Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Product2> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<Product2> prodList = new List<Product2>(); 

        for(Product2 obj : scope){
            Boolean isChanged = false;
            if(String.isNotBlank(obj.Reference__c) && String.isBlank(obj.ProductCode)) {
                obj.ProductCode = obj.Reference__c;
                obj.ExternalId = obj.Reference__c;
                isChanged = true;
            }/*
            if(String.isNotBlank(obj.CPQId__c) && String.isBlank(obj.ExternalId)) {
                obj.ExternalId = obj.CPQId__c;
                obj.ProductCode = obj.CPQId__c;
                isChanged = true;
            }*/
            if(String.isNotBlank(obj.Famille__c) && String.isBlank(obj.Family)) {
                obj.Family = obj.Famille__c;
                isChanged = true;
            }
            if(String.isBlank(obj.unit__c)) {
                obj.unit__c = 'UNIT';
                isChanged = true;
            }
            if(isChanged) {                
                prodList.add(obj);
            }
        }

        Database.update(prodList, false);
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}