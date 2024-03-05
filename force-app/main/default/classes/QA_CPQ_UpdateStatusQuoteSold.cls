//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_CPQ_UpdateStatusQuoteSold
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 04/07/2023
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_CPQ_UpdateStatusQuoteSold implements Queueable, Database.AllowsCallouts {
    Set<Id> quotesIdList;

    /**
    * @description Constructeur
    * @param quoteIds Liste des IDs des devis
    * @return QA_CPQ_UpdateStatusQuoteSold Classe Queueable 
    */
    public QA_CPQ_UpdateStatusQuoteSold(Set<Id> quoteIds) {
        this.quotesIdList = quoteIds;
    }

    /**
    * @description Exécution des processus de contournement de clonage des projets pour les devis CPQ + exécution génération commande client
    * @param context Context classe Queueable 
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_CPQ_UpdateStatusQuoteSold');
        try {
            // Traitement
            List<SBQQ__Quote__c> updatedQuotes = new List<SBQQ__Quote__c>();
            
            /*for(String qId : quotesIdList) {
                updatedQuotes.add(new SBQQ__Quote__c(Id = qId, dateAcceptationClient__c = System.today()));

            }
            //disable CPQ internal triggers to prevent errors
            SBQQ.TriggerControl.disable();
            update updatedQuotes;
            SBQQ.TriggerControl.enable();
            */

            SBQQ.TriggerControl.disable();
            
            for(String qId : quotesIdList) {       
                Map<String, Object> params = new Map<String, Object>();
                params.put('recordId', qId);
                Flow.Interview.Devis_CPQ_Avenant_Vendu_Clonage_projet quoteFlow = new Flow.Interview.Devis_CPQ_Avenant_Vendu_Clonage_projet(params);
                quoteFlow.start();
            }
            
            SBQQ.TriggerControl.enable();
            
            for(String qId : quotesIdList) {
                updatedQuotes.add(new SBQQ__Quote__c(Id = qId, amendmentOpportunityCreated__c = true, dateAcceptationClient__c = System.today()));

            }
            update updatedQuotes;
            
            System.debug('### FIN QA_CPQ_UpdateStatusQuoteSold');
        } catch (Exception e) {
            System.debug('ERREUR # Signea : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            EmailUtils.reportException('[KUBE] Erreur exécution signature électronique contrat', e);
        }
    }
}