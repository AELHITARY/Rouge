//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Schedule_SObjectPurge
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 05/11/2018
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
global class Schedule_SObjectPurge implements Schedulable{
    
    // execute à 00:00:00 de tout les jours
    public static final String scheduleTime = '0 0 * * * ?';
    
    // à appeler depuis une fenêtre anonyme en utilisant Schedule_SObjectPurge.scheduleIt();
    global static String scheduleIt() {
        Schedule_SObjectPurge job = new Schedule_SObjectPurge();
        return System.schedule('Schedule of BA_SObjectPurge', scheduleTime, job);
    }
    
    global void execute(SchedulableContext ctx) {
        Map<String, Schema.SObjectType> objectsMap = Schema.getGlobalDescribe();
        List<String> objectsList = new List<String>();
        List<Schema.DescribeSObjectResult> metadata = new List<Schema.DescribeSObjectResult>();
        List<String> sObjectsToPurge = new List<String>();
        List<SObject> recordsToPurge = new List<SObject>();
        for(String obj : objectsMap.keySet()){
            if(!String.valueOf(objectsMap.get(obj)).containsIgnoreCase('__kav'))
                objectsList.add(String.valueOf(objectsMap.get(obj)));
        }
        metadata = Schema.describeSObjects(objectsList);
        for(Schema.DescribeSObjectResult met : metadata){
            if(met.isQueryable()){
                Map<String, Schema.SObjectField> fieldMap = met.fields.getMap();
                for(String fieldName : fieldMap.keySet()){
                    if(String.valueOf(fieldMap.get(fieldName)) == 'GDPR_dateExpiration__c'){
                        sObjectsToPurge.add(met.getName());
                    }
                }
            }
        }
        
        for(String objectName : sObjectsToPurge) {
            BA_SObjectPurge batch = new BA_SObjectPurge(objectName);
            database.executebatch(batch);
        }
        
        
    }
}