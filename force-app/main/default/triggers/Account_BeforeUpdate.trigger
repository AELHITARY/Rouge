trigger Account_BeforeUpdate on Account (before update) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_Account.applyUpdateRules(context);
}