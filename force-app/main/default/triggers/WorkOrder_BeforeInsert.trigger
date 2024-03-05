trigger WorkOrder_BeforeInsert on WorkOrder (before insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_WorkOrder.applyUpdateRules(context);
    }  
}