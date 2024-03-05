//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsChantier 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 08/10/2020
//-- Version     : 1.1
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsChantier implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param context Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id FROM Chantier__c]);
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param context Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext context, List<Chantier__c> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<Chantier__c> objToUpdate = new List<Chantier__c>();
        Map<String, Account> mapEntities = new Map<String, Account>();
        
        String A = 'TOTO';
        String B = 'TITI';
        String C = '';  
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        B = C;
        A = B;
        B = C;
        B = C;
        A = B;
        B = C;

        // Récupération des entités
        String RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        for(Account ent : [SELECT ID, KparKReference__c FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY]) {
            mapEntities.put(ent.KparKReference__c, ent);
        }

        for(Chantier__c cha : [SELECT Id, CreatedDate, GDPR_dateExpiration__c, 
                            sectorisation__c, sectorisation__r.codeMagasin__c, sectorisation__r.codeDepot__c, 
                            serviceEntity__c, salesEntity__c FROM Chantier__c WHERE Id IN :scope])
        {
            Boolean isChanged = false;
            // Entités
            if(String.isBlank(cha.salesEntity__c) && String.isNotBlank(cha.sectorisation__r.codeMagasin__c) && String.isNotBlank(cha.sectorisation__c) && mapEntities.get(cha.sectorisation__r.codeMagasin__c) != null) {
                cha.salesEntity__c = mapEntities.get(cha.sectorisation__r.codeMagasin__c).Id;
                isChanged=true;
            }
            if(String.isBlank(cha.serviceEntity__c) && String.isNotBlank(cha.sectorisation__r.codeDepot__c) && String.isNotBlank(cha.sectorisation__c) && mapEntities.get(cha.sectorisation__r.codeDepot__c) != null) {    
                cha.serviceEntity__c = mapEntities.get(cha.sectorisation__r.codeDepot__c).Id;
                isChanged=true;
            }
            if(isChanged) {
                objToUpdate.add(cha);
            }
        }

        if(!objToUpdate.isEmpty()) {
            Database.update(objToUpdate, false);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param context Context du batch
    */
    global void finish(Database.BatchableContext context) {      
    }   
}