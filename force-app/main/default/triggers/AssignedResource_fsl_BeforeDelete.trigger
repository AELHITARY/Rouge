//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : AssignedResource_fsl_BeforeDelete 
//-- Modifié par : CGI
//-- Modifié le  : 04/04/2018
//-- Version     : 1.0
//-- Description : Trigger before delete sur les Ressources attribuées
//-- --------------------------------------------------------------------------------- --
trigger AssignedResource_fsl_BeforeDelete on AssignedResource (before delete) {
    System.debug('**AssignedResource_fsl_BeforeDelete** Nb de requêtes SOQL: '+ Limits.getAggregateQueries() + '  Limite: ' + Limits.getLimitAggregateQueries());
    System.debug('**AssignedResource_fsl_BeforeDelete** Nb de requêtes DML: '+ Limits.getDMLStatements() + '  Limite: ' + Limits.getLimitDMLStatements());
    
    UserContext context = UserContext.getContext();
  
    if (context != null && !context.canByPassTrigger('TR001_fsl_AssignedResource')) {
        TR001_fsl_AssignedResource.supprimerAbsenceLiee(context);
    }    
}