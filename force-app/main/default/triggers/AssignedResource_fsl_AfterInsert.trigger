//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : AssignedResource_fsl_AfterInsert
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger after insert sur les Ressources attribuées
//-- --------------------------------------------------------------------------------- --

trigger AssignedResource_fsl_AfterInsert on AssignedResource (after insert) {
    
    system.debug('**AssignedResource_fsl_AfterInsert** Nb de requêtes SOQL: '+ Limits.getAggregateQueries() + '  Limite: ' + Limits.getLimitAggregateQueries());
    system.debug('**AssignedResource_fsl_AfterInsert** Nb de requêtes DML: '+ Limits.getDMLStatements() + '  Limite: ' + Limits.getLimitDMLStatements());
    
    UserContext context = UserContext.getContext();   
    
    if (context == null ||(!context.canByPassValidationRules() && !context.canByPassTrigger('TR002_fsl_AssignedResource')))
        TR002_fsl_AssignedResource.crlCoherenceDateValidite(context); 
      
}