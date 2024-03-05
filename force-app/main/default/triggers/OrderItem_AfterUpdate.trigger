trigger OrderItem_AfterUpdate on OrderItem (after update) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_OrderItem')) { 
        TR022_OrderItem.amendmentCancelOrAddAsset(context);
        TR022_OrderItem.updateOrderItemConfirmedAsset(context);
    }
}