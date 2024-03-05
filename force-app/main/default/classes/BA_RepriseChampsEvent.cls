//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsEvent  
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 19/09/2018
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsEvent implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id rtId = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        return Database.getQueryLocator([SELECT Id, StartDateTime, CreatedDate, RecordTypeId, GDPR_dateExpiration__c, IsRecurrence, IsDeleted FROM Event WHERE RecordTypeId= :rtId]);
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Event> scope) {
        if(!scope.isEmpty()) {
            system.debug('## Scope size: '+scope.size()); 
            List<Event> objToUp = new List<Event>();

            Id RT_RDVCommercial = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
            for(Event evt : scope){
                if(Test.IsRunningTest() || (evt.GDPR_dateExpiration__c == null && evt.IsRecurrence == false && evt.IsDeleted == false)) {
                    Date expiration = (evt.StartDateTime!=null) ? evt.StartDateTime.date() : evt.CreatedDate.date();
                    if(evt.RecordTypeId == RT_RDVCommercial)
                        evt.GDPR_dateExpiration__c = expiration.addDays(1050);
                    else
                        evt.GDPR_dateExpiration__c = expiration.addDays(365);
                    objToUp.add(evt);
                }
            }
            if(!objToUp.isEmpty())
                Database.SaveResult[] results = Database.update(objToUp, FALSE);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}