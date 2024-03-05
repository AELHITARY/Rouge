//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_CollaboratorCalculateManager
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 30/12/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class BA_CollaboratorCalculateManager implements Database.Batchable<sObject>, Database.Stateful {
    global String errorMessage;
    global Integer errorCount;
    global Integer successCount;
    global BatchHistory__c batchHistoryStored {get;set;}

    /***** Constructor *****/
    global BA_CollaboratorCalculateManager() {
        errorMessage = '';
        errorCount = 0;
        successCount = 0;

        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_CollaboratorCalculateManager');
        }
    }
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les collaborateurs actifs ou provisionnés
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
   global Database.QueryLocator start(Database.BatchableContext BC){
		System.debug('### DEBUT BA_CollaboratorCalculateManager : start');
		try {
			Database.QueryLocator results;

			// Récupération des collaborateurs actifs
			results = Database.getQueryLocator([SELECT Id, Name FROM Collaborator__c WHERE isActive__c = true OR stageName__c = 'Provisionné']);
			batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
			Database.QueryLocatorIterator it =  results.iterator();
			if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
			System.debug('### FIN BA_CollaboratorCalculateManager : start');     
			return results;
		} catch(Exception e) {
			System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
			EmailUtils.reportException('[KUBE] COLLABORATEURS : Erreur d\'initialisation du batch de calcul des responsables', e);
			Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
			return null;
		}
	}

	/**
	* @description Méthode exécutée pour chaque lot d'enregistrements
	* @param BC Context du batch
	* @param scope Liste des enregistrements
	*/
	global void execute(Database.BatchableContext BC, List<Collaborator__c> scope){
		System.debug('### DEBUT BA_CollaboratorCalculateManager : execute');
		batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
		System.debug('## scope (' + scope.size() +')');
		List<Collaborator__c> collabToUp = new List<Collaborator__c>();

		try {

			if(!scope.isEmpty()) {
				// Calcul des managers
				Map<String, Collaborator__c> managerMap = Utils_Collaborator.getManager(scope, Date.today());
				if(managerMap != null) {
					for(Collaborator__c collab : scope) {
						System.debug('## Collaborateur: '+collab.Id);
						collab.manager__c = (managerMap.get(collab.Id) != null) ? managerMap.get(collab.Id).Id : null;
						System.debug('## Manager: '+collab.manager__c);
						collabToUp.add(collab);
					}
				}
			}

			if (!collabToUp.isEmpty()) {
				Database.SaveResult[] results = Database.update(collabToUp, false);

				if(Test.isRunningTest())
					results = Utils_HistoriqueBatchs.changeSaveResult(results, collabToUp);
			
				for (Integer index = 0; index < results.size(); index++) {
					Database.SaveResult result = results[index];
					if (!result.isSuccess()) {
						// Traitement des erreurs
						errorCount++; 
						for(Database.Error error : result.getErrors()) {
							errorMessage += '* ' + collabToUp.get(index).Id + ' - ' + error.getStatusCode() + ' : ' + error.getMessage() + ' (' + error.getFields() + ')\n';
						}
						System.debug('## Error message : '+errorMessage);
					} else {
						successCount++;
					}
				}
				
				// MAJ Stats
				batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? successCount : batchHistoryStored.nombreTraite__c + successCount;
			} 
		} catch(Exception e) {
			System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
			EmailUtils.reportException('[KUBE] COLLABORATEURS : Erreur lors du calcul des responsables', e);
			Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
		}
		System.debug('### FIN BA_CollaboratorCalculateManager : execute');
	}


    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
   global void finish (Database.BatchableContext BC) {     
		System.debug('### DEBUT BA_CollaboratorCalculateManager : finish');

		try  {   
			// Envoi email de confirmation ou d'erreur
			if (String.isEmpty(errorMessage)) {
				// Mise à jour des stats
				Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
				EmailUtils.mailToITSupport('[KUBE] [OK] COLLABORATEURS : Calcul des responsables',
											'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' collaborateurs ont été traités.\n\nCordialement\n');
			} else {
				EmailUtils.mailToITSupport('[KUBE] [ERREUR] COLLABORATEURS : Calcul des responsables',
											'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' collaborateurs ont été traités.\nCependant, les erreurs suivantes ont été détectées:\n\n' + errorMessage + '\n\nCordialement\n');
				Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, errorMessage);
			}
		} catch(Exception e) {            
			Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, 'ERREUR : '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString()+ '\n');
			EmailUtils.reportException('[KUBE] [ERREUR] COLLABORATEURS : Calcul des responsables', e);
		}
		
		System.debug('### FIN BA_CollaboratorCalculateManager : finish');
	}
}