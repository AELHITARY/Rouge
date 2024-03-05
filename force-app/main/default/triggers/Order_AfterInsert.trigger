trigger Order_AfterInsert on Order (after insert) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassTrigger('TR022_Order')) {
        TR022_Order.executeManagementFlow(context);
        TR022_Order.getDocumentsFromQuote(context);
    }

    if (context == null || !context.canByPassTrigger('QA_UpdateOrderStatusGC')) {
        TR022_Order.updateOrderGCStatus(context);  
    }

    if(context == null || !context.canByPassTrigger('QA_UpdateAfterSalesServiceStatusGC')){
        TR022_Order.updateAfterSalesServiceGCStatus(context);
    }
}