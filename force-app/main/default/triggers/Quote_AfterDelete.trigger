trigger Quote_AfterDelete on Quote (after delete) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_R040'))
        TR022_R040.fillR040FromQuotes(context);
}