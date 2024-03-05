trigger QuoteLineItem_BeforeInsert on QuoteLineItem (before insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_QuoteLineItem.applyUpdateRules(context);
    }

    if(context == null || !context.canByPassTrigger('TR022_QuoteLineItem')) {
        TR022_QuoteLineItem.changeLinesNumber(Trigger.new);
    }
        
    if(context == null || !context.canByPassTrigger('TR020_Garanties')) {
        TR020_Garanties.refreshGaranties(Trigger.new);
    }
}