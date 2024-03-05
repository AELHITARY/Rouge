global class BA_RepriseLigneDevis implements Database.Batchable<SObject>, Database.Stateful {
    
    /**
     * @description gets invoked when the batch job starts
     * @param context contains the job ID
     * @returns the record set as a QueryLocator object that will be batched for execution
     */ 
    global Database.QueryLocator start(Database.BatchableContext context) {
        try {
            // Limite à 100 pour les tests pour éviter erreur de limites Salesforce
            if(Test.isRunningTest()) {
                return Database.getQueryLocator([SELECT Id, ligneDevis__c, codeOption__c, codeOptionUnique__c
                                FROM Option__c WHERE codeOptionUnique__c='' AND IsDeleted=false LIMIT 100]);
            } else {
                return Database.getQueryLocator([SELECT Id, ligneDevis__c, codeOption__c, codeOptionUnique__c
                                FROM Option__c WHERE codeOptionUnique__c='' AND IsDeleted=false LIMIT 5000]);
            }
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Reprise de données sur Ligne Devis : Erreur d\'initialisation du batch', e);
            throw e;
        }
    }

    /**
     * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
     * @param context contains the job ID
     * @param scope contains the batch of records to process.
     */ 
    global void execute(Database.BatchableContext context, List<Option__c> scope) {
        system.debug('#### START BA_RepriseLigneDevis.execute()');
        system.debug('Scope sise:'+scope.size());   
        try {
            Set<Option__c> filteredOptionToUpdate = new Set<Option__c>();
            for (Option__c opt : scope) {
                if(opt.ligneDevis__c != null && opt.codeOption__c != null) {
                    opt.codeOptionUnique__c=opt.ligneDevis__c+opt.codeOption__c;
                    filteredOptionToUpdate.add(opt);
                }
            }
            List<Option__c> optionToUpdate = new List<Option__c>();
            optionToUpdate.addAll(filteredOptionToUpdate);
            
            if(!optionToUpdate.isEmpty())
                database.update(optionToUpdate, false);

        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new KubeException('ERREUR !');
        }
        system.debug('#### END BA_RepriseLigneDevis.execute()');
    }
    
    /**
     * @description gets invoked when the batch job finishes. Place any clean up code in this method.
     * @param context contains the job ID
     */ 
    global void finish(Database.BatchableContext context) {
        system.debug('#### START BA_RepriseLigneDevis.finish()');
        system.debug('#### END BA_RepriseLigneDevis.finish()');
    }
}