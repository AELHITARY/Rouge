trigger EmailMessage_AfterInsert on EmailMessage (after insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR020_EmailMessage')) {
        TR020_EmailMessage.processEmailToCase(context);
    }

    if (context == null || !context.canByPassTrigger('TR020_Milestone')) {
        TR020_Milestone.jalonPremierEmail(context);
    }
}