//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : ServiceAppointment_BeforeInsert
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/09/2018
//-- Version     : 1.0
//-- Description : Trigger before update sur le rendez-vous de service
//-- --------------------------------------------------------------------------------- --

trigger ServiceAppointment_BeforeInsert on ServiceAppointment (before insert) {
    
    system.debug('**ServiceAppointment_fsl_BeforeUpdate** Nb de requêtes SOQL: '+ Limits.getAggregateQueries() + '  Limite: ' + Limits.getLimitAggregateQueries());
    system.debug('**ServiceAppointment_fsl_BeforeUpdate** Nb de requêtes DML: '+ Limits.getDMLStatements() + '  Limite: ' + Limits.getLimitDMLStatements());
    
    UserContext context = UserContext.getContext();
    
    IF (context == null || !context.canByPassWorkflowRules())
        TR020_ServiceAppointment.applyUpdateRules(context);

    if (context == null || !context.canByPassTrigger('TR020_fsl_ServiceAppointment'))
        TR020_fsl_ServiceAppointment.alimentationContratK(context);
}