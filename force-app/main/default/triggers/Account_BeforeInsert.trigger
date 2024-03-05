trigger Account_BeforeInsert on Account (before insert) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_Account.applyUpdateRules(context);
}