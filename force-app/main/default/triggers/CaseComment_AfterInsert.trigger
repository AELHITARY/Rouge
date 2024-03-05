trigger CaseComment_AfterInsert on CaseComment (after insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_CaseComment') || Test.isRunningTest()) {
        TR022_CaseComment.emailNotificationClient(context);
        TR022_CaseComment.envoiCommentaireTrustpilot(context);
    }

    if (context == null || !context.canByPassTrigger('TR020_Milestone')) {
        TR020_Milestone.JalonPremierCommentaire(context);
    }
}