//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RetryGeneratePassword
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 05/10/2017
//-- Version     : 1.0
//-- * 
//-- --------------------------------------------------------------------------------- --
global class BA_RetryGeneratePassword implements Database.Batchable<sObject> {
    
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Integer dayDelayMin = PropertiesUtils.getIntegerValue('espaceclient.mdp.delai.reprise', 7);
        Datetime dateDelayMin = Datetime.now().addDays(-dayDelayMin); // Traite pas les enregistrements vieux de plus de X jours
        
        try {
            return Database.getQueryLocator([SELECT Id, aGenererMDP__c FROM Account 
                                             WHERE SystemModstamp >= :dateDelayMin
                                               AND aGenererMDP__c != null
                                               AND aGenererMDP__c > 0
                                               AND IsDeleted = false]);
        } 
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] Batch reprise mot de passe : Erreur lors de l\'initialisation du batch', e);
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
        try {
            if(scope!=null)
                ID jobID = system.enqueueJob(new QA_GenerateAccountPassword(scope, true, true, true));
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch reprise mot de passe : Erreur lors de la génération du mot de passe', e);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {     
    }
}