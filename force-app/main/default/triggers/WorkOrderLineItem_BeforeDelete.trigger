trigger WorkOrderLineItem_BeforeDelete on WorkOrderLineItem (before delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_WorkOrderLineItem.applyValidationRules(context);
    }
}