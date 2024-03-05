//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_HistoriqueBatchs
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 27/10/2022
//-- Version     : 1.1
//-- * Classe utilitaire pour la gestion d'historique des batchs
//-- * 1.1 : Amélioration en ajoutant l'ID des record en erreur
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_HistoriqueBatchs {
    private static final Integer MAX_ERRORFIELD_SIZE = 131070;
    
    public static BatchHistory__c createNewBatchHistory(String batchName) {
        // Création de l'historique de batch
        BatchHistory__c batchHistory = new BatchHistory__c(
                        nomDuBatch__c = batchName,
                        dateLancementStart__c = System.now(),
                        GDPR_dateExpiration__c = Date.today().addDays(61),
                        statut__c = Constants.BATCHHISTORY_STATUS_DEMARRE
                    );
        insert batchHistory;
        return batchHistory;
    }

    public static BatchHistory__c finishStartBatchHistory(BatchHistory__c batchHistory) {
        batchHistory.dateFinStart__c = System.now();
        batchHistory.nombreATraiter__c = 0;
        batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_ENATTENTE;
        update batchHistory;
        return batchHistory;
    }

    public static BatchHistory__c beginExecuteBatchHistory(BatchHistory__c batchHistory, Integer scopeSize) {
        if(batchHistory.dateLancementExecute__c == null) {
            batchHistory.dateLancementExecute__c = System.now();
        }
        batchHistory.nombreATraiter__c = (batchHistory.nombreATraiter__c == null) ? scopeSize : batchHistory.nombreATraiter__c + scopeSize;
        if(scopeSize == 0){
            batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_TERMINE;
        } else 
            batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_ENCOURS;
        update batchHistory;
        return batchHistory;
    }

    public static BatchHistory__c finishExecuteBatchHistory(BatchHistory__c batchHistory) {
        if(batchHistory.dateLancementExecute__c == null) {
            batchHistory.dateLancementExecute__c = System.now();
        }
        batchHistory.dateFinExecute__c = System.now();
        // Ne change pas le statut en "Terminé" si le batch a rencontré des erreurs
        if(batchHistory.statut__c != Constants.BATCHHISTORY_STATUS_ERREUR) {
            batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_TERMINE;
        }
        update batchHistory;
        return batchHistory;
    } 

    public static BatchHistory__c updateTraceError(BatchHistory__c batchHistory, String error) {
        // Concatene l'erreur
        if(String.isNotBlank(error)) {
            if(String.isBlank(batchHistory.traceErreurs__c)) {
                batchHistory.traceErreurs__c = error;
            } else {
                batchHistory.traceErreurs__c += ' '+error;
            }
        }
        // Limite la taille du champ s'il dépasse la taille max
        if(batchHistory.traceErreurs__c.length() > MAX_ERRORFIELD_SIZE){
            batchHistory.traceErreurs__c = batchHistory.traceErreurs__c.substring(0, MAX_ERRORFIELD_SIZE);
        }
        return batchHistory;
    } 

    public static BatchHistory__c updateIdsError(BatchHistory__c batchHistory, List<String> idsError) {
        // Concatene l'erreur
        String idsErrorStr='';
        if(!idsError.isEmpty()) {
            idsErrorStr = String.join(idsError,',');
        }
        batchHistory.IdEnregistrementsErreur__c = idsErrorStr;
        // Statut
        batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_ERREUR;
        // Limite la taille du champ s'il dépasse la taille max
        if(batchHistory.IdEnregistrementsErreur__c.length() > MAX_ERRORFIELD_SIZE) {
            batchHistory.IdEnregistrementsErreur__c = batchHistory.IdEnregistrementsErreur__c.substring(0, MAX_ERRORFIELD_SIZE);
        }
        return batchHistory;
    } 

    public static BatchHistory__c traceErrorBatchHistory(BatchHistory__c batchHistory, String tracedError) {
        // Concatene l'erreur
        if(String.isNotBlank(tracedError)) {
            if(String.isBlank(batchHistory.traceErreurs__c)) {
                batchHistory.traceErreurs__c = tracedError;
            } else {
                batchHistory.traceErreurs__c += ' '+tracedError;
            }
        }
        // Limite la taille du champ s'il dépasse la taille max
        if(batchHistory.traceErreurs__c.length() > MAX_ERRORFIELD_SIZE) {
            batchHistory.traceErreurs__c = batchHistory.traceErreurs__c.substring(0, MAX_ERRORFIELD_SIZE);
        }
        // Statut
        batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_ERREUR;
        // Mise à jour date         
        if(batchHistory.dateLancementStart__c != null && batchHistory.dateFinStart__c == null) {
            batchHistory.dateFinStart__c = System.now();
        }
        if(batchHistory.dateLancementStart__c != null && batchHistory.dateFinExecute__c == null) {
            batchHistory.dateFinExecute__c = System.now();
        }
        update batchHistory;
        return batchHistory;
    }     

    public static BatchHistory__c inactiveBatchHistory(BatchHistory__c batchHistory) {
        batchHistory.nombreATraiter__c = 0;
        batchHistory.nombreTraite__c = 0;
        batchHistory.dateFinStart__c = System.now();
        batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_ERREUR;
        if(String.isBlank(batchHistory.traceErreurs__c)) {
            batchHistory.traceErreurs__c = 'La propriété globale pour assurer la maintenance est désactivée. ';
        } else {
            batchHistory.traceErreurs__c += ' La propriété globale pour assurer la maintenance est désactivée. ';
        }
        update batchHistory;
        return batchHistory;
    }   

    // Terminé avant la fin avec aucun traitement
    public static BatchHistory__c quickEndBatchHistory(BatchHistory__c batchHistory) {
        batchHistory.nombreTraite__c = 0;
        batchHistory.dateFinStart__c = System.now();
        batchHistory.statut__c = Constants.BATCHHISTORY_STATUS_TERMINE;
        update batchHistory;
        return batchHistory;
    }   

    public static Database.DeleteResult[] changeDeleteResult(Database.DeleteResult[] deleteResult, List<SObject> objList){
        Boolean oneError = false;
        deleteResult.clear();
        for(SObject sObj : objList){
            if(!oneError){
                Database.DeleteResult newDR = (Database.DeleteResult)JSON.deserialize('{"id":"'+sObj.Id+'","success":false,"errors":[]}', Database.DeleteResult.class);
                oneError = true;
                deleteResult.add(newDR);
            } else {
                Database.DeleteResult newDR = (Database.DeleteResult)JSON.deserialize('{"id":"'+sObj.Id+'","success":true,"errors":[]}', Database.DeleteResult.class);
                deleteResult.add(newDR);
            }
        }
        return deleteResult;
    }

    public static Database.SaveResult[] changeSaveResult(Database.SaveResult[] saveResult, List<SObject> objList){
        Boolean oneError = false;
        saveResult.clear();
        for(SObject sObj : objList){
            if(!oneError){
                Database.SaveResult newDR = (Database.SaveResult)JSON.deserialize('{"id":"'+sObj.Id+'","success":false,"errors":[]}', Database.SaveResult.class);
                oneError = true;
                saveResult.add(newDR);
            } else {
                Database.SaveResult newDR = (Database.SaveResult)JSON.deserialize('{"id":"'+sObj.Id+'","success":true,"errors":[]}', Database.SaveResult.class);
                saveResult.add(newDR);
            }
        }
        return saveResult;
    }
}