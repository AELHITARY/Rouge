trigger QuoteLineItem_BeforeDelete on QuoteLineItem (before delete) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {
        TR020_QuoteLineItem.applyValidationRules(context);
    }

    if(context == null || !context.canByPassTrigger('TR022_QuoteLineItem')) {
        TR022_QuoteLineItem.changeLinesNumberDelete(Trigger.old);
        TR022_QuoteLineItem.deleteOptionsDeLigneDevis(Trigger.old);
    }
}