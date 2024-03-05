//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : ServiceAppointment_BeforeUpdate
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/09/2018
//-- Version     : 1.1
//-- Description : Trigger before update sur le rendez-vous de service
//-- v1.1 - RQM-137 : Alimentation de ContratK__c lorsque celui-ci est vide dans les ServiceAppointment
//-- --------------------------------------------------------------------------------- --

trigger ServiceAppointment_BeforeUpdate on ServiceAppointment (before update) {
    
    system.debug('**ServiceAppointment_fsl_BeforeUpdate** Nb de requêtes SOQL: '+ Limits.getAggregateQueries() + '  Limite: ' + Limits.getLimitAggregateQueries());
    system.debug('**ServiceAppointment_fsl_BeforeUpdate** Nb de requêtes DML: '+ Limits.getDMLStatements() + '  Limite: ' + Limits.getLimitDMLStatements());
    
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_ServiceAppointment.applyUpdateRules(context);
    }
    
    if (context == null || (!context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_ServiceAppointment'))){
        TR001_fsl_ServiceAppointment.auMoinsUneRessourceAttribuee(context);
        TR001_fsl_ServiceAppointment.crlCoherenceDateValidite(context);
    }

    if (context == null || !context.canByPassTrigger('TR020_fsl_ServiceAppointment')) {
        TR020_fsl_ServiceAppointment.alimentationContratK(context);
    }
    
    if (context == null || !context.canByPassTrigger('TR002_fsl_ServiceAppointment')) {
        TR002_fsl_ServiceAppointment.calculFenetreArrivee(context);
    }
}