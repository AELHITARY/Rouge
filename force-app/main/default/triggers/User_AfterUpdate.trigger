trigger User_AfterUpdate on User (after update) {
    UserContext context = UserContext.getContext();

    if (context==null || !context.canByPassValidationRules())
        TR020_User.applyValidationRules(context);

    if(context==null || !context.canByPassWorkflowRules()) {
        TR020_User.applyAsyncUpdateRules(context);
    }
    
    if(context==null || !context.canByPassTrigger('TR022_User')){
        //TR022_User.deleteUsersLinkedRecords();
    }
}