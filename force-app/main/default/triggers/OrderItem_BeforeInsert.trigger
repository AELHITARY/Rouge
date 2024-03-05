trigger OrderItem_BeforeInsert on OrderItem (before insert) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_OrderItem.applyUpdateRules(context);
    }

    // KUBE3 - Process pour import données GC
    TR020_OrderItem.applyLegacyUpdateRules(context);
}