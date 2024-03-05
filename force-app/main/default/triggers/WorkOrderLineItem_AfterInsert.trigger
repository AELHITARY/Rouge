trigger WorkOrderLineItem_AfterInsert on WorkOrderLineItem (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_WorkOrderLineItem')) {
        TR022_WorkOrderLineItem.updateStatusCasePNC(context);
    }
}