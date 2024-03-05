trigger QuoteLineItem_AfterDelete on QuoteLineItem (after delete) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_QuoteLineItem')){
        TR022_QuoteLineItem.changeProductInQuote(context);
        TR022_QuoteLineItem.setMontantTotalCEE(Trigger.old);
    }
    
}