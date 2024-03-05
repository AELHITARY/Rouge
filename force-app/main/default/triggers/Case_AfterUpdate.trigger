trigger Case_AfterUpdate on Case (after update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_Case')) {
        TR022_Case.createCommentPrevi(context);
        TR022_Case.sendNotificationsPNC(context);
        TR022_Case.sendReclaEmail(context);
    }

    if(context == null || !context.canByPassTrigger('QA_UpdateAfterSalesServiceStatusGC')){
        TR022_Case.updateAfterSalesServiceGCStatus(context);
    }
}