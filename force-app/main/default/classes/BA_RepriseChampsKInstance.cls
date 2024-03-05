//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsKInstance  
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/09/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsKInstance implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, dateEntree__c, GDPR_dateExpiration__c FROM KInstance__c]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise de l\'objet KInstance: Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<KInstance__c> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<KInstance__c> objToUpdate = new List<KInstance__c>();

        for(KInstance__c obj : scope){
            if(obj.dateEntree__c != null ) {
                obj.GDPR_dateExpiration__c = obj.dateEntree__c.addDays(365);
                objToUpdate.add(obj);
            }
        }

        if(!objToUpdate.isEmpty())
            Database.SaveResult[] results = Database.update(objToUpdate, FALSE);
        
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}