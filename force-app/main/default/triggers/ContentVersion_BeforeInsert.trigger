trigger ContentVersion_BeforeInsert on ContentVersion (before insert) {
  UserContext context = UserContext.getContext();
  
  if (context == null || !context.canByPassWorkflowRules()) {
    TR020_ContentVersion.applyUpdateRules(context);        
  }
}