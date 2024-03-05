trigger FeedItem_AfterInsert on FeedItem (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR020_FeedItem')) {
        TR020_FeedItem.savePicture(context);
    }
}