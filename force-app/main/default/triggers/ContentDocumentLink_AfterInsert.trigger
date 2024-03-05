trigger ContentDocumentLink_AfterInsert on ContentDocumentLink (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_ContentDocumentLink')){
        TR022_ContentDocumentLink.createPublicLinkForFile(context);
        TR022_ContentDocumentLink.processLinkToObject(context);
    }
}