//-- --------------------------------------------------------------------------------- ------------------------------------
//-- * 
//-- Fichier     : Test_fsl_PlatformEvent
//-- Modifié par : CGI
//-- Modifié le  : 29/05/2019
//-- Version     : 1.0
//-- Description : Batch Mise à jour des renforts sur les ressources secondaires pour pallier au bug visuel, toutes les 5 minutes. 
//-- --------------------------------------------------------------------------------- -----------------------------------/
public class BA_fsl_ArUpdateRenfort implements Database.batchable<sObject>{
   
    //Requêtre globale
    public String queryGlobal = null;
    
    
    //Premier constructeur permettant de créer la requête
    public BA_fsl_ArUpdateRenfort(String request){
        queryGlobal = request;
    }
    
    
    //Second constructeur  permettant la construction de la requête
    public BA_fsl_ArUpdateRenfort(){

        //Date dateToday = Date.today();
        String sec = 'Secondaire';
        String query = 'SELECT Id, fsl_typeRessourceAttribuee__c, ServiceAppointment.SchedStartTime '+
                        'FROM AssignedResource WHERE fsl_typeRessourceAttribuee__c = \''+ 
                        String.escapeSingleQuotes(sec) + '\' AND ServiceAppointment.SchedStartTime >= :dateToday'+(Test.isRunningTest()?' LIMIT 200':'');
        queryGlobal = query; 
    }
    
    //Début du Batch qui renvoit le scope 
    public Iterable<sobject> start(Database.BatchableContext info){
        Date dateToday = Date.today();
        List<AssignedResource> queryResult = Database.query(queryGlobal);
        return queryResult;
    }
    
    
    //Execution, update du scope
    public void execute(Database.BatchableContext info, List<AssignedResource> scope){
        
        if(scope != null && !scope.isEmpty()){
            Database.update(scope, false);
            //update scope;
        }
    }
    
    //Fin
    public void finish(Database.BatchableContext info){
        System.debug('End of Batch');
    }   
}