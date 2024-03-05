//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseFilleulDotation
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 17/01/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseFilleulDotation implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, typeDotation__c FROM Account WHERE parrain__c != null AND typeDotation__c=null]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise filleul dotation : Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        system.debug('## Scope size: '+scope.size()); 
        for(Account pr : scope){
            pr.typeDotation__c = Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_PAPIER;
        }
        try {
            Database.SaveResult[] results = Database.update(scope, FALSE);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise filleul dotation : Erreur lors de la génération du mot de passe', e);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}