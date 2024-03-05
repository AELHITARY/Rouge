trigger Quote_BeforeInsert on Quote (before insert) {
    UserContext context = UserContext.getContext();
  
    IF (context == null || !context.canByPassWorkflowRules()) {
        TR020_Quote.applyUpdateRules(context);
    }
}