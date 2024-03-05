trigger OrderItem_BeforeUpdate on OrderItem (before update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {        
        TR020_OrderItem.applyValidationRules(context);
    }
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_OrderItem.applyUpdateRules(context);
    }
}