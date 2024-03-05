//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsOpportunity 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/09/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsOpportunity implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([SELECT Id, Amount,GDPR_dateExpiration__c,CloseDate FROM Opportunity]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise de l\'objet Opportunity : Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<String> oppIdList = new List<String>(); 
        Map<String,Opportunity> oppMap = new Map<String,Opportunity>(); 
        List<Quote> quoteList = new List<Quote>();
        for(Opportunity opp : scope){

          if (opp.CloseDate != null)
            opp.GDPR_dateExpiration__c = opp.CloseDate + 1095;
            oppIdList.add(opp.Id);
            oppMap.put(opp.Id,opp);

            /*if(opp.mntDernierPrixLaisse__c != null)
                opp.ExpectedRevenue = opp.mntDernierPrixLaisse__c;*/
        }
        quoteList = [SELECT Id, Status, Total_TTC_devis__c, Opportunity.Id FROM Quote WHERE Opportunity.Id IN :oppIdList];
        for(Quote q : quoteList){
            if(q.Status == null)
                oppMap.get(q.Opportunity.Id).Amount = null;
            else if(q.Status.contains('Vendu'))
                oppMap.get(q.Opportunity.Id).Amount = q.Total_TTC_devis__c;
            else
                oppMap.get(q.Opportunity.Id).Amount = null;
        }
        Database.SaveResult[] results = Database.update(scope, FALSE);
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}