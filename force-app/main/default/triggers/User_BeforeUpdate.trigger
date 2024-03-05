trigger User_BeforeUpdate on User (before update) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_User.applyUpdateRules(context);
    }
}