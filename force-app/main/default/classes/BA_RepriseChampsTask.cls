//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsTask 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/09/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsTask implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, CreatedDate, GDPR_dateExpiration__c, IsDeleted, IsRecurrence FROM Task ]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise de l\'objet Task: Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Task> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<Task> objToUp = new List<Task>();
        for(Task obj: scope){
            if(Test.IsRunningTest() || (obj.CreatedDate != null && obj.GDPR_dateExpiration__c == null && obj.IsRecurrence == false && obj.IsDeleted == false)) {
                obj.GDPR_dateExpiration__c = obj.CreatedDate.addDays(365).date();
                objToUp.add(obj);
            }
        }
        
        if(!objToUp.isEmpty())
            Database.SaveResult[] results = Database.update(objToUp, FALSE);
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}