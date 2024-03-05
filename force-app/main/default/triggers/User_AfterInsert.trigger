trigger User_AfterInsert on User (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules())
        TR020_User.applyAsyncUpdateRules(context);
}