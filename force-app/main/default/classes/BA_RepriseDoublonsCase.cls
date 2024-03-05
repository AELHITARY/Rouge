//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseDoublonsCase  
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 13/06/2019
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseDoublonsCase implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Subject, CaseNumber, Description, AccountId FROM Case WHERE Subject LIKE '%REQ/%']);
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Case> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<CaseComment> ccList = new List<CaseComment>();
        List<Case> caseToDelete = new List<Case>();
        List<Case> caseRefList = new List<Case>();
        List<String> accIdList = new List<String>();
        Map<String,Case> caseRefMap = new Map<String,Case>();
        List<String> requestNumberList = new List<String>();

        // Récupération des case number dans l'objet
        for(Case cas : scope){
            List<String> res = cas.Subject.split('REQ/', 2);
            if(res.size() > 1) {
                String caseNumber = 'REQ/' + res[1].substring(0, 12);
                requestNumberList.add(caseNumber);
            }
        }

        // Récupération des case parents avec les case number
        caseRefList = [SELECT Id, Subject, CaseNumber, Description FROM Case WHERE CaseNumber IN :requestNumberList];
        for(Case cas : caseRefList){
            caseRefMap.put(cas.CaseNumber, cas);
        }

        // Insertion du case comment, tag du case à supprimer
        for(Case cas : scope){
            List<String> res = cas.Subject.split('REQ/', 2);
            if(res.size() > 1) {
                system.debug('## Case Id : '+cas.Id);
                String caseNumber = 'REQ/' + res[1].substring(0, 12);
                
                Case caseRef = new Case();
                caseRef = caseRefMap.get(caseNumber);
                if(caseRef != null && caseRef.Id != null) {
                    system.debug('## Case REF Id : '+caseRef.Id);
        
                    String commentDesc = '';
                    if(String.isNotBlank(cas.Description)) {
                        system.debug('## Description.length : ' + cas.Description.length());
                        if(cas.Description.length() > 3000){
                            commentDesc = cas.Description.substring(0, 3000);
                        } else {
                            commentDesc = cas.Description;
                        }
                        system.debug('## commentDesc.length : ' +  commentDesc.length());
                        List<String> commentList = commentDesc.split('De : ');
                        commentDesc = commentList[0];
                    }
                    
                    // Création commentaire
                    CaseComment cc = new CaseComment(ParentId = caseRef.Id, 
                                                     IsPublished = false,
                                                     CommentBody = commentDesc);
                    ccList.add(cc);
        
                    cas.toDelete__c = true;
                    caseToDelete.add(cas);
                    accIdList.add(cas.AccountId);
                }
            }
        }
        // Insert / Update
        if(!ccList.isEmpty())
            Database.SaveResult[] resultsCC = Database.insert(ccList);
        if (!caseToDelete.isEmpty()) {
            Database.SaveResult[] resultsCase = Database.update(caseToDelete, FALSE);       
        }
        if(!accIdList.isEmpty()){
            List<Account> accList = [SELECT Id, toDelete__c FROM Account WHERE Id IN :accIdList];
            for(Account acc : accList){
                acc.toDelete__c = true;
            }
            system.debug('accList : '+accList);
            Database.SaveResult[] resultsAcc = Database.update(accList);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}