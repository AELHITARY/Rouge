trigger Quote_AfterUpdate on Quote (after update) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassTrigger('TR021_Quote')) {
        TR021_Quote.calculateIndicators(context);
    }

    if(context == null || !context.canByPassTrigger('TR022_Quote')){
        TR022_Quote.changeQuoteLineItemConfigurer(context);
        TR022_Quote.setMontantLignesDevisCEE(context);
        TR022_Quote.updateAccountStatus(context);
    }

    // R040 - Héritage de Kube v1
    /*
    IF (!context.canByPassTrigger('TR001_Quote_Stat'))
        TR001_Quote_Stat.execute();
    */
    if(context == null || !context.canByPassTrigger('TR022_R040')) {
        TR022_R040.fillR040FromQuotes(context);
    }
    
    if(context == null || !context.canByPassValidationRules()) {
        TR020_Quote.applyValidationRules(context);
    }
}