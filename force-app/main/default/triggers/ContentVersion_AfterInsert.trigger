trigger ContentVersion_AfterInsert on ContentVersion (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_ContentVersion')){
        TR022_ContentVersion.createPublicLinkForFile(context);
        TR022_ContentVersion.processLinkToObject(context);
    }
}