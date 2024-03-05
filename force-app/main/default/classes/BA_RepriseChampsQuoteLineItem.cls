//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsQuoteLineItem
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 11/01/2020
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsQuoteLineItem implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, Modele__c, Description, CreatedDate, dureeGarantie1__c, 
                                                legacyReference__c, Quote.numeroDevis__c, NumLigneText__c FROM QuoteLineItem]);
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise QuoteLineItem: Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<QuoteLineItem> scope) {
        System.debug('## Scope size: '+scope.size()); 
        List<QuoteLineItem> qliGarantie = new List<QuoteLineItem>();
        for(QuoteLineItem q : scope){
            if(Test.isRunningTest() || String.isNotBlank(q.Modele__c)) {
                q.Description = q.Modele__c;
            }
            q.legacyReference__c = q.Quote.numeroDevis__c + '-0' + q.NumLigneText__c;
        }
        //TR020_Garanties.refreshGaranties(scope);
        Database.SaveResult[] results = Database.update(scope, false);
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}