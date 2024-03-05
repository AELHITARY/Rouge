trigger WorkOrderLineItem_AfterUpdate on WorkOrderLineItem (after update) {
	UserContext context = UserContext.getContext();
	
    if (context == null || !context.canByPassTrigger('TR022_WorkOrderLineItem')) {
		TR022_WorkOrderLineItem.updateStatusCasePNC(context);
	}
	
    if (context == null || !context.canByPassTrigger('TR022_WorkOrderLineItem')) {
		TR022_WorkOrderLineItem.updateStatusAsset(context);
    }    
}