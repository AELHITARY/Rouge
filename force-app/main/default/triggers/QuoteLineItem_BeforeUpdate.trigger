trigger QuoteLineItem_BeforeUpdate on QuoteLineItem (before update) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassValidationRules()) {
        TR020_QuoteLineItem.applyValidationRules(context);
    }

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_QuoteLineItem.applyUpdateRules(context);
    }

    if(context == null || !context.canByPassTrigger('TR020_Garanties')) {
        TR020_Garanties.refreshGaranties(Trigger.new);
    }
}