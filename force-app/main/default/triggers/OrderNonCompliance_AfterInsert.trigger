trigger OrderNonCompliance_AfterInsert on OrderNonCompliance__c (after insert) {
    UserContext context = UserContext.getContext();
        
    if(context == null || !context.canByPassTrigger('TR022_OrderNonCompliance')) {
        TR022_OrderNonCompliance.updateOrderGCStatus(context);
        TR022_OrderNonCompliance.updateCommissions(context);
    }
}