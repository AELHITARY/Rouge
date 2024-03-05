trigger QuoteLineItem_AfterInsert on QuoteLineItem (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_QuoteLineItem')){
        TR022_QuoteLineItem.changeProductInQuote(context);
        TR022_QuoteLineItem.setMontantTotalCEE(Trigger.new);
    }
}