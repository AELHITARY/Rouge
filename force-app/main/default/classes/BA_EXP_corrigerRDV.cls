//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_EXP_corrigerRDV
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 23/07/2020
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-13 : Optimisation et historique des batchs
//-- --------------------------------------------------------------------------------- --
global class BA_EXP_corrigerRDV implements Database.Batchable<sObject>, Database.Stateful {
    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_EXP_corrigerRDV() {
        UserContext userCtx = UserContext.getContext(); // Aucun impacts sur les autres données ou les indicateurs ==> Désactiver pour ne pas consommer les Governor Limits
        userCtx.setByPassValidationRules(true);
        userCtx.setByPassWorkflowRules(true);
        userCtx.setByPassTriggers(true); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_EXP_corrigerRDV');
        }
    }

    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_EXP_corrigerRDV : start');     
        try {
            if (!PropertiesUtils.getBooleanValue('maintenance.RDVACorriger', Test.isRunningTest())){
                batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);
                return Database.getQueryLocator([SELECT id FROM KContrat__c WHERE cartoMetrageDuJour__c != null AND cartoMetrageDuJour__c != TODAY LIMIT 0]);
            }
            EmailUtils.mailToITSupport('[KUBE] Exploitation : Correction des RDV', 'Début des traitements.\n\nCordialement\n');
            Database.QueryLocator results;
            results = Database.getQueryLocator([SELECT id,
                                                cartoMetrageDuJour__c, cartoMetrageDeDemain__c,  prochainMetrage__c,
                                                cartoInstallationDuJour__c, cartoInstallationDeDemain__c, prochaineInstallation__c,
                                                cartoInterventionSAVDuJour__c, cartoInterventionSAVDeDemain__c, prochainSAV__c
                                            FROM KContrat__c
                                            WHERE (cartoMetrageDuJour__c           != null AND cartoMetrageDuJour__c           != TODAY)
                                               OR (cartoMetrageDeDemain__c         != null AND cartoMetrageDeDemain__c         != TOMORROW)
                                               OR (prochainMetrage__c              != null AND prochainMetrage__c               = TOMORROW)
                                               OR (cartoInstallationDuJour__c      != null AND cartoInstallationDuJour__c      != TODAY)
                                               OR (cartoInstallationDeDemain__c    != null AND cartoInstallationDeDemain__c    != TOMORROW)
                                               OR (prochaineInstallation__c        != null AND prochaineInstallation__c         = TOMORROW)
                                               OR (cartoInterventionSAVDuJour__c   != null AND cartoInterventionSAVDuJour__c   != TODAY)
                                               OR (cartoInterventionSAVDeDemain__c != null AND cartoInterventionSAVDeDemain__c != TOMORROW)
                                               OR (prochainSAV__c                  != null AND prochainSAV__c                   = TOMORROW)]);
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            System.debug('### FIN BA_EXP_corrigerRDV : start');     
            return results;
        } 
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Exploitation : Correction des RDV : Erreur lors de l\'initialisation du batch', e);
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
        System.debug('### DEBUT BA_EXP_corrigerRDV : execute');     
        batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
        System.debug('## scope (' + scope.size() +')');
        List<KContrat__c> contratToUp = new List<KContrat__c>();

        try {
            Date yesterday = Date.today().addDays(-1);
            Date today     = Date.today();
            Date tomorrow  = Date.today().addDays(1);
            System.debug('## Yesterday : '+yesterday);     
            System.debug('## Today : '+today);    
            System.debug('## Tomorrow : '+tomorrow);    

            for (KContrat__c contrat : scope) { 
                if (contrat.cartoMetrageDuJour__c != null && !today.isSameDay(contrat.cartoMetrageDuJour__c))
                    contrat.cartoMetrageDuJour__c = null;
                if (contrat.cartoInstallationDuJour__c != null && !today.isSameDay(contrat.cartoInstallationDuJour__c))
                    contrat.cartoInstallationDuJour__c = null;
                if (contrat.cartoInterventionSAVDuJour__c != null && !today.isSameDay(contrat.cartoInterventionSAVDuJour__c))
                    contrat.cartoInterventionSAVDuJour__c = null;
    
                if (contrat.cartoMetrageDeDemain__c != null && !tomorrow.isSameDay(contrat.cartoMetrageDeDemain__c)) {
                    if (today.isSameDay(contrat.cartoMetrageDeDemain__c))
                        contrat.cartoMetrageDuJour__c = contrat.cartoMetrageDeDemain__c;
                    contrat.cartoMetrageDeDemain__c = null;
                }
                if (contrat.cartoInstallationDeDemain__c != null && !tomorrow.isSameDay(contrat.cartoInstallationDeDemain__c)) {
                    if (today.isSameDay(contrat.cartoInstallationDeDemain__c))
                        contrat.cartoInstallationDuJour__c = contrat.cartoInstallationDeDemain__c;
                    contrat.cartoInstallationDeDemain__c = null;
                }
                if (contrat.cartoInterventionSAVDeDemain__c != null && !tomorrow.isSameDay(contrat.cartoInterventionSAVDeDemain__c)) {
                    if (today.isSameDay(contrat.cartoInterventionSAVDeDemain__c))
                        contrat.cartoInterventionSAVDuJour__c = contrat.cartoInterventionSAVDeDemain__c;
                    contrat.cartoInterventionSAVDeDemain__c = null;
                }
                if (contrat.prochainMetrage__c != null && tomorrow.isSameDay(contrat.prochainMetrage__c.date()))
                    contrat.cartoMetrageDeDemain__c = contrat.prochainMetrage__c.date();
                    if (contrat.prochaineInstallation__c != null && tomorrow.isSameDay(contrat.prochaineInstallation__c.date()))
                        contrat.cartoInstallationDeDemain__c = contrat.prochaineInstallation__c.date();
                if (contrat.prochainSAV__c != null && tomorrow.isSameDay(contrat.prochainSAV__c.date()))
                    contrat.cartoInterventionSAVDeDemain__c = contrat.prochainSAV__c.date();
                contratToUp.add(contrat);
            }

            if (!contratToUp.isEmpty()) {
                Database.SaveResult[] results = Database.update(contratToUp, false);

                if(Test.isRunningTest())
                    results = Utils_HistoriqueBatchs.changeSaveResult(results, contratToUp);
              
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult result = results[index];
                    if (!result.isSuccess()) {
                        // Traitement des erreurs
                        errorCount++; 
                        for(Database.Error error : result.getErrors()) {
                            errorMessage += '* ' + contratToUp.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
                        }
                        System.debug('## Error message : '+errorMessage);
                    } else {
                        successCount++;
                    }
                }

                batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
            } 
        }
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : correction des RDV', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
        }
        System.debug('### FIN BA_EXP_corrigerRDV : execute');     
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {     
        System.debug('### DEBUT BA_EXP_corrigerRDV : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Exploitation : correction des RDV',
                                             'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' contrats(K) ont été corrigés.\n\nCordialement\n');
            } else {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Exploitation : correction des RDV',
                                             'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' contrats(K) ont été corrigés.\nCependant, les erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage);
            }
        }
        catch(Exception e) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : correction des RDV', e);
        }
        
        System.debug('### FIN BA_EXP_corrigerRDV : finish');
    }
}