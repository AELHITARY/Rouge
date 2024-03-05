trigger Case_AfterInsert on Case (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_Case')) {
        TR022_Case.createCommentPrevi(context);
        TR022_Case.sendNotificationsPNC(context);
        TR022_Case.updateAccountStatus(context);
    }

    if(context == null || !context.canByPassTrigger('QA_UpdateAfterSalesServiceStatusGC')){
        TR022_Case.updateAfterSalesServiceGCStatus(context);
    }
}