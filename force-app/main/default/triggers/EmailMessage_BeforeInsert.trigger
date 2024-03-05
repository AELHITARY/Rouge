trigger EmailMessage_BeforeInsert on EmailMessage (before insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR020_EmailMessage')) {
        TR020_EmailMessage.EmailToCaseDiscardAutoResponse(context);
        TR020_EmailMessage.DetectMassCreationFromSpam(context);
    }
}