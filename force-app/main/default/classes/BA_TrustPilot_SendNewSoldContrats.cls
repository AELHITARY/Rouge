//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_TrustPilot_SendNewSoldContrats
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 20/09/2021
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_TrustPilot_SendNewSoldContrats implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_TrustPilot_SendNewSoldContrats() {
        UserContext userCtx = UserContext.getContext(); // Aucun impacts sur les autres données ou les indicateurs ==> Désactiver pour ne pas consommer les Governor Limits
        userCtx.setByPassValidationRules(true);
        userCtx.setByPassWorkflowRules(true);
        userCtx.setByPassTriggers(true); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_TrustPilot_SendNewSoldContrats');
        }
    }

    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_TrustPilot_SendNewSoldContrats : start');     
        try {
            date dateToCheck = system.today().addDays(-7);

            Database.QueryLocator results;
            results = Database.getQueryLocator([
                    SELECT Id, Name, numeroContrat__c, emailCompte__c, nomCompte__c
                    FROM KContrat__c 
                    WHERE (libelleStatutContrat__c = 'Solde' OR libelleStatutContrat__c = 'Soldé' OR libelleStatutContrat__c = 'Totalement installe'
                    OR libelleStatutContrat__c = 'Contrats soldes' OR libelleStatutContrat__c = 'Contrats totalement installes') 
                        AND DateEnvoiAvisTrustpilot__c = null 
                        AND dateReponseQuestionnaire__c = :dateToCheck 
                        AND NPSSatisfaction__c > 8
                        AND debutDernierSAV__c = null
                        AND emailCompte__c != null
                   
            ]);
            System.debug(results);   
            System.debug('### FIN BA_TrustPilot_SendNewSoldContrats : start');     
            return results;
        } 
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch : Envoi des contrats soldés à TrustPilot : Erreur lors de l\'initialisation du batch', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<KContrat__c> scope) {
        System.debug('### DEBUT BA_TrustPilot_SendNewSoldContrats : execute');     
        System.debug('## scope (' + scope.size() +')');
        List<KContrat__c> contratToSend = new List<KContrat__c>();

        try {
            for (KContrat__c contrat : scope) { 
                contrat.DateEnvoiAvisTrustpilot__c = Date.today();
                if(contrat.numeroContrat__c.substring(4).isNumeric() && math.mod(Integer.valueOf(contrat.numeroContrat__c.substring(4)), 2) == 1){
                    contratToSend.add(contrat);
                } 
            }
            system.debug('contratToSend : '+contratToSend);
            system.debug('contratToSend.size() : '+contratToSend.size());

            if (!contratToSend.isEmpty()) {
                Utils_TrustPilot.createInvitations(contratToSend);
                Database.SaveResult[] results = Database.update(contratToSend, false);
            } 

            String a = 'a';
            a = 'b';
            a = 'c';
            a = 'b';
            a = 'c';
            a = 'b';
            a = 'c';
        }
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] [ERREUR] Batch : Envoi des contrats soldés à TrustPilot ', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
        }
        System.debug('### FIN BA_TrustPilot_SendNewSoldContrats : execute');     
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {     
        System.debug('### DEBUT BA_TrustPilot_SendNewSoldContrats : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Batch : Envoi des contrats soldés à TrustPilot', 'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' contrats(K) ont été envoyés.\n\nCordialement\n');
            } else {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Batch : Envoi des contrats soldés à TrustPilot', 'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' contrats(K) ont été envoyés.\nCependant, les erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage);
            }
        }
        catch(Exception e) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            EmailUtils.reportException('[KUBE] [ERREUR] Batch : Envoi des contrats soldés à TrustPilot', e);
        }
        
        System.debug('### FIN BA_TrustPilot_SendNewSoldContrats : finish');
    }
}