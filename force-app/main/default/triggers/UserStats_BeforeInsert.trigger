trigger UserStats_BeforeInsert on UserStats__c (before insert) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_UserStats.applyUpdateRules(context);        
}