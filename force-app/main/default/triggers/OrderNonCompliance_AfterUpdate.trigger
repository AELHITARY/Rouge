trigger OrderNonCompliance_AfterUpdate on OrderNonCompliance__c (after update) {
    UserContext context = UserContext.getContext();
        
    if(context == null || !context.canByPassTrigger('TR022_OrderNonCompliance')) {
        TR022_OrderNonCompliance.updateOrderGCStatus(context);
        TR022_OrderNonCompliance.updateCommissions(context);
        TR022_OrderNonCompliance.updateAsset(context);
    }
}