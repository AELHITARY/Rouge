trigger UserStats_BeforeUpdate on UserStats__c (before update) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_UserStats.applyUpdateRules(context);        
}