trigger WorkOrderLineItem_BeforeInsert on WorkOrderLineItem (before insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_WorkOrderLineItem.applyUpdateRules(context);
    }
}