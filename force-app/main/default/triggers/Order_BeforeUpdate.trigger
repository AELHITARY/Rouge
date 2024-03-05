trigger Order_BeforeUpdate on Order (before update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {
        TR020_Order.applyValidationRules(context);
    }
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Order.applyUpdateRules(context);
    }
}