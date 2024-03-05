//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_fsl_CalendrierService
//-- Modifié par : CGI 
//-- Modifié le  : 27/03/2018
//-- Version     : 1.1 
//-- * Calculer le debut et fin de période calendrier service dans laquelle se situe la date du jour
//-- --------------------------------------------------------------------------------- --
global class BA_fsl_CalendrierService implements Database.Batchable<sObject>, Database.Stateful{
    
    global Database.QueryLocator start(Database.BatchableContext bc)  {
        String query= 'select Id ,dateValue__c, Name from GlobalProperties__c where name = \'fsl.calculCA.calendrierService.debut\'' ;   
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<GlobalProperties__c> liste){
        list<GlobalProperties__c> listeCalendrier =  new list<GlobalProperties__c>();
        Date debut = FieldServiceUtils.calculDebutCalendarService();                 
        Date finProfondeurUnePeriode = FieldServiceUtils.calculFinCalendarService(1);   
        Date finProfondeurTroisPeriodes = FieldServiceUtils.calculFinCalendarService(3); 
    
        GlobalProperties__c calendrierServiceDebut = GlobalProperties__c.getInstance('fsl.calculCA.calendrierService.debut');  
        GlobalProperties__c calendrierServiceFin1 = GlobalProperties__c.getInstance('fsl.calculCA.calendrierService.fin1');    
        GlobalProperties__c calendrierServiceFin3 = GlobalProperties__c.getInstance('fsl.calculCA.calendrierService.fin3');    
        calendrierServiceDebut.dateValue__c = debut;    
        calendrierServiceFin1.dateValue__c = finProfondeurUnePeriode;   
        calendrierServiceFin3.dateValue__c = finProfondeurTroisPeriodes; 
        listeCalendrier.add(calendrierServiceDebut);
        listeCalendrier.add(calendrierServiceFin1);
        listeCalendrier.add(calendrierServiceFin3);
        Database.update(listeCalendrier, false);
        
        
    }
    global void finish(Database.BatchableContext bc){
        
    }    
    
}