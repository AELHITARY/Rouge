trigger OrderItem_BeforeDelete on OrderItem (before delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules())
        TR020_OrderItem.applyValidationRules(context);

    if (context == null || !context.canByPassTrigger('TR022_OrderItem')) {
        TR022_OrderItem.deleteChildrenOrderItems(context);
    }
}