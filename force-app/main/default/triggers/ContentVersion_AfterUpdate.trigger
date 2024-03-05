trigger ContentVersion_AfterUpdate on ContentVersion (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_ContentVersion')){
        TR022_ContentVersion.processLinkToObject(context);
        TR022_ContentVersion.updateCategoryKBMaxImage(context);
    }
}