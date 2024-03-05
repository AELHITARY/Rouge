trigger Quote_BeforeUpdate on Quote (before update) {
    UserContext context = UserContext.getContext();
        
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Quote.applyUpdateRules(context);
    }

    // Héritage de Kube v1 
    if(context == null || !context.canByPassTrigger('TR022_Quote')){
        TR022_Quote.setRemises(context);
    }
}