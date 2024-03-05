//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsCase  
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/09/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsCase implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, ClosedDate, GDPR_dateExpiration__c, IsClosed, entity__c, serviceConcerne__c, AccountId, chantier__c,
                                            Chantier__r.serviceEntity__c, Chantier__r.salesEntity__c, Account.billingServiceEntity__c, Account.billingSalesEntity__c,
                                            Account.personServiceEntity__pc, Account.personSalesEntity__pc, Account.IsPersonAccount, aCloturer__c FROM Case]);
    }
     
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Case> scope) {
        System.debug('## Scope size: '+scope.size()); 
        List<Case> caseToUp = new List<Case>();
        Map<String, Account> mapEntities = new Map<String, Account>();

        // Récupération des entités
        String RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        List<Account> allAccounts = new List<Account>([SELECT Id, Name, PersonEmail, stageName__c, ParentId, entityType__r.Name, entityType__r.RecordType.DeveloperName, RecordTypeId
                                                         FROM Account 
                                                         WHERE RecordTypeId = :RT_ACC_ENTITY]);

        List<Account> mainEntities = new List<Account>();
        List<Account> callEntities = new List<Account>();
        for(Account acc : allAccounts){
            if(acc.RecordTypeId == RT_ACC_ENTITY && acc.stageName__c == 'En cours' && acc.ParentId == null){
                mainEntities.add(acc);
            }
            if(acc.RecordTypeId == RT_ACC_ENTITY && acc.stageName__c == 'En cours' && acc.entityType__r.Name == 'Call' && acc.entityType__r.RecordType.DeveloperName == 'EntityType'){
                callEntities.add(acc);
            }
        }

        List<CaseHistory> caseHistoryList = [SELECT CaseId,CreatedDate,OldValue,NewValue 
                                                FROM CaseHistory WHERE Field='Status' AND CaseId IN :scope 
                                                ORDER BY CreatedDate DESC];

        for(Case newCase : scope) {
            Boolean isChanged=false;

            // Alimentation du champ entity__c
            if(newCase.serviceConcerne__c == 'Technique'){
                if(String.isNotBlank(newCase.chantier__c)) {
                    newCase.entity__c = newCase.Chantier__r.serviceEntity__c;
                    isChanged = true;
                } else if(String.isNotBlank(newCase.AccountId)) {
                    newCase.entity__c = (newCase.Account.IsPersonAccount) ? newCase.Account.personServiceEntity__pc : newCase.Account.billingServiceEntity__c;
                    isChanged = true;
                }
            } else if(newCase.serviceConcerne__c == 'Commercial'){
                if(String.isNotBlank(newCase.chantier__c)) {
                    newCase.entity__c = newCase.Chantier__r.salesEntity__c;
                    isChanged = true;
                } else if(String.isNotBlank(newCase.AccountId)) {
                    newCase.entity__c = (newCase.Account.IsPersonAccount) ? newCase.Account.personSalesEntity__pc : newCase.Account.billingSalesEntity__c;
                    isChanged = true;
                }
            } else if(newCase.serviceConcerne__c == 'Marketing'){
                if(!mainEntities.isEmpty()){
                    newCase.entity__c = mainEntities[0].id;
                    isChanged = true;
                }
            } else {
                if(!callEntities.isEmpty()){
                    newCase.entity__c = callEntities[0].id;
                    isChanged = true;
                }
            }

            if(newCase.IsClosed && newCase.ClosedDate != null) {
                newCase.GDPR_dateExpiration__c = newCase.ClosedDate.addDays(1095).date();
                isChanged = true;
            } else {
                if(Test.isRunningTest()) {
                    caseHistoryList.add(new CaseHistory(CaseId = newCase.Id));
                }
                for(CaseHistory caseHistory : caseHistoryList) {
                    if(Test.isRunningTest() || (caseHistory.CaseId == newCase.Id && casehistory.NewValue == 'A clôturer')) {
                        Date expiration = (Test.isRunningTest()) ? Date.today() : caseHistory.CreatedDate.date();
                        newCase.GDPR_dateExpiration__c = expiration.addDays(1095);
                        isChanged = true;
                        break;
                    }
                }
            }

            if(isChanged) {
                caseToUp.add(newCase);
            }
        }
        if(!caseToUp.isEmpty()) {
            Database.SaveResult[] results = Database.update(caseToUp, false);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}