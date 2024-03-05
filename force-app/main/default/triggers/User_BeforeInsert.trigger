trigger User_BeforeInsert on User (before insert) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_User.applyUpdateRules(context);
}