trigger ContentVersion_BeforeUpdate on ContentVersion (before update) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_ContentVersion.applyUpdateRules(context);        
}