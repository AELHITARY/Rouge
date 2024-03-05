//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseCEEQuoteQLI
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 15/11/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseCEEQuoteQLI implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, eligibleCEE__c, montantCEE__c, QuoteId, PricebookEntryId, remise_enseigne__c,
            Quantity, PricebookEntry.Product2Id, Aconfigurer__c, dateDevis__c, Description__c, elligibleCreditImpot__c, Emplacement__c, Etage__c, Hauteur__c,
            Incompatibletechniquement__c, Largeur__c, Modele__c, PrixHTtarif__c,Prix_TVA__c, Nombredevantaux__c, NumerodeLigne__c, NumLigneText__c, PromotionDevise__c,
            PromotionPourcentage__c, PrixunitaireHTtarifoptions__c, PrixunitaireHTtarif__c, PrixTTCtarif__c, Remisevendeureuro__c,
            RemisevendeurPourcentage__c, Tarifhorsdimension__c, TotalTTCligne__c, TVA__c, TVApourcentage__c, Version__c, Visuel__c
                                            FROM QuoteLineItem WHERE eligibleCEE__c = TRUE]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise du calcul CEE des lignes de devis : Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<QuoteLineItem> scope) {
        system.debug('## Scope size: '+scope.size()); 
        try {
            system.debug('scope : '+scope);
            for(QuoteLineItem qli : scope){
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
                qli.montantCEE__c = 0;
            }
            update scope;
            //Database.SaveResult[] results = Database.update(scope, FALSE);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise du calcul CEE des lignes de devis : Erreur lors de la génération du mot de passe', e);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}