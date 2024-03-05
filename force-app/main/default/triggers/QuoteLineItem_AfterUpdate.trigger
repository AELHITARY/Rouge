trigger QuoteLineItem_AfterUpdate on QuoteLineItem (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_QuoteLineItem')){
        TR022_QuoteLineItem.changeProductInQuote(context);
        TR022_QuoteLineItem.setMontantTotalCEE(Trigger.New);
    }
}