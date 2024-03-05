trigger OrderItem_AfterInsert on OrderItem (after insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_OrderItem')) { 
        TR022_OrderItem.amendmentCancelOrAddAsset(context);
        TR022_OrderItem.linkWarrantiesToOLI(context);
        TR022_OrderItem.updateOrderItemConfirmedAsset(context);
    }
}