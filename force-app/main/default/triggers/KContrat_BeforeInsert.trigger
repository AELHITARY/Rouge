trigger KContrat_BeforeInsert on KContrat__c (before insert) {
    UserContext context = UserContext.getContext();
    
    if(!context.canByPassWorkflowRules())
        TR020_KContrat.applyUpdateRules(context); 
}