//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_TrustPilot_GetReactionsCreateCases
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 20/09/2021
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_TrustPilot_GetReactionsCreateCases implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global UserContext userCtx;
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_TrustPilot_GetReactionsCreateCases() {
        UserContext userCtx = UserContext.getContext(); // Aucun impacts sur les autres données ou les indicateurs ==> Désactiver pour ne pas consommer les Governor Limits
        userCtx.setByPassValidationRules(true);
        userCtx.setByPassWorkflowRules(true);
        userCtx.setByPassTriggers(true); 
        errorMessage = '';
        errorCount = 0;
        successCount = 0;

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_TrustPilot_GetReactionsCreateCases');
        }
    }

    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {    
        System.debug('### DEBUT BA_TrustPilot_GetReactionsCreateCases : start');     
        try {
            Database.QueryLocator results;
            results = Database.getQueryLocator([
                    SELECT Id, Name, numeroContrat__c, nbStarsTrustpilot__c
                    FROM KContrat__c 
                    WHERE DateEnvoiAvisTrustpilot__c != null 
                        AND nbStarsTrustpilot__c = null
                    LIMIT 2
            ]);
            System.debug('### FIN BA_TrustPilot_GetReactionsCreateCases : start');     
            return results;
        } 
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch : Récupération des avis Trustpilot : Erreur lors de l\'initialisation du batch', e);
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
        System.debug('### DEBUT BA_TrustPilot_GetReactionsCreateCases : execute');     
        System.debug('## scope (' + scope.size() +')');
        Map<String,String> result = new Map<String,String>();
        List<Utils_TrustPilot.Reviews> response = new List<Utils_TrustPilot.Reviews>();
        List<String> contratIdList = new List<String>();
        List<String> contratIdTestList = new List<String>();

        try {
            if (!scope.isEmpty()) {
                String caseQualifierRTId = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_AQUALIFIER_RT);
                
                Map<String, KContrat__c> contratMap = new Map<String, KContrat__c>(); 

                response = Utils_TrustPilot.getInvitationInfo();
                system.debug('response : '+response);

                for(KContrat__c kc : scope){
                    if (Test.isRunningTest()) {
                        for(Utils_TrustPilot.Reviews rev : response){
                            rev.referenceId = kc.Id;
                        }
                    }
                }
                if(response != null && !response.isEmpty()){
                    for(Utils_TrustPilot.Reviews rev : response){
                        if(rev.referenceId != null){
                            if(rev.referenceId.startsWith('0')){
                                rev.referenceId = 'a'+rev.referenceId;
                            }
                            contratIdList.add(rev.referenceId);
                        }
                    }
                    system.debug('contratIdList : '+contratIdList);
                    
                    for(KContrat__c conK : [SELECT Id, numeroContrat__c, compte__c, chantier__c, 
                                                compte__r.contactParDefaut__c, nbStarsTrustpilot__c 
                                            FROM KContrat__c WHERE Id IN :contratIdList AND nbStarsTrustpilot__c = null]){
                        contratMap.put(conK.Id, conK);
                        system.debug('conK.Id : '+conK.Id);
                    } 
                    
                    List<Case> alreadyExistingTPCases = new List<Case>();
                    List<String> TPReviewsIdList = new List<String>();
                    alreadyExistingTPCases = [SELECT Id, trustpilotReviewID__c 
                                                FROM Case 
                                                WHERE source__c = 'Trustpilot'];

                    for(Case tpc : alreadyExistingTPCases){
                        TPReviewsIdList.add(tpc.trustpilotReviewID__c);
                    }
                    
                    List<Case> caseList = new List<Case>();
                    List<KContrat__c> contratToUpdateList = new List<KContrat__c>();
                    for(Utils_TrustPilot.Reviews rev : response){
                        System.debug('ENTER rev.referenceId : '+rev.referenceId);
                        if(rev.referenceId != null && contratMap.get(rev.referenceId) != null && 
                            contratMap.get(rev.referenceId).nbStarsTrustpilot__c == null){
                                System.debug('OK rev.referenceId : '+rev.referenceId);
                            if(rev.referenceId.startsWith('0')){
                                rev.referenceId = 'a'+rev.referenceId;
                            }
                            Case newCase = new Case(
                                RecordTypeId = caseQualifierRTId,
                                AccountId = contratMap.get(rev.referenceId).compte__c,
                                ContactId = contratMap.get(rev.referenceId).compte__r.contactParDefaut__c,
                                Chantier__c = contratMap.get(rev.referenceId).chantier__c,
                                numeroContrat__c = contratMap.get(rev.referenceId).numeroContrat__c,
                                trustpilotReviewID__c = rev.id,
                                Subject = rev.title,
                                Origin = 'Web',
                                source__c = 'TrustPilot',
                                Status = 'Nouveau',
                                Description = rev.text,
                                nbStarsTrustpilot__c = rev.stars
                            );
                            if(Integer.valueOf(rev.stars) <= 3){
                                newCase.Priority = 'Elevé';
                            } else {
                                newCase.Priority = 'Moyen';
                            }
                            caseList.add(newCase);
                            contratMap.get(rev.referenceId).nbStarsTrustpilot__c = rev.stars;
                            contratToUpdateList.add(contratMap.get(rev.referenceId));
                        } else if(rev.referenceId == null && !TPReviewsIdList.contains(rev.Id)){
                            Case newCase = new Case(
                                RecordTypeId = caseQualifierRTId, trustpilotReviewID__c = rev.id, Subject = rev.title, Origin = 'Web', source__c = 'TrustPilot', Status = 'Nouveau', Description = rev.text, nbStarsTrustpilot__c = rev.stars, SuppliedEmail = rev.referralEmail
                            );
                            if(Integer.valueOf(rev.stars) <= 3){
                                newCase.Priority = 'Elevé';
                            } else {
                                newCase.Priority = 'Moyen';
                            }
                            caseList.add(newCase);
                        }
                    }
                    System.debug('caseList : '+caseList);
                    if(!contratToUpdateList.isEmpty())
                        update contratToUpdateList;

                    insert caseList;
                }
            } 
        }
        catch(Exception e) {
            EmailUtils.reportException('[KUBE] [ERREUR] Batch : Envoi des contrats soldés à TrustPilot ', e);
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
        }
        System.debug('### FIN BA_TrustPilot_GetReactionsCreateCases : execute');     
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {     
        System.debug('### DEBUT BA_TrustPilot_GetReactionsCreateCases : finish');

        try  {   
            // Envoi email de confirmation ou d'erreur
            if (String.isEmpty(errorMessage)) {
                // Mise à jour des stats
                Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
                EmailUtils.mailToITSupport('[KUBE] [OK] Batch : Envoi des contrats soldés à TrustPilot',
                                             'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' contrats(K) ont été envoyés.\n\nCordialement\n');
            } else {
                EmailUtils.mailToITSupport('[KUBE] [ERREUR] Batch : Envoi des contrats soldés à TrustPilot',
                                             'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' contrats(K) ont été envoyés.\nCependant, les erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
                Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage);
            }
        }
        catch(Exception e) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
            EmailUtils.reportException('[KUBE] [ERREUR] Batch : Envoi des contrats soldés à TrustPilot', e);
        }
        
        System.debug('### FIN BA_TrustPilot_GetReactionsCreateCases : finish');
    }
}