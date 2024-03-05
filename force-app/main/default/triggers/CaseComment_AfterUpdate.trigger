trigger CaseComment_AfterUpdate on CaseComment (after update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_CaseComment')) {
        TR022_CaseComment.emailNotificationClient(context);
    }
    
    if (context == null || !context.canByPassTrigger('TR020_Milestone')) {
        TR020_Milestone.jalonPremierCommentaire(context);
    }
}