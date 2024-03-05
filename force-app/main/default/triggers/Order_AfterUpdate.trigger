trigger Order_AfterUpdate on Order (after update) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassTrigger('TR022_Order')) {
        TR022_Order.executeManagementFlow(context);
        TR022_Order.updateRelatedOrderItems(context);
        TR022_Order.updateCasesSAV(context);        
        TR022_Order.updateAmendmentOrder(context);
        TR022_Order.updateNCC(context);
	}

    if(context == null || !context.canByPassTrigger('TR023_Order')) {
		TR023_Order.amendmentCreateCPQQuoteLines(context);
        TR023_Order.amendmentUpdateCPQOrderItem(context);
		TR023_Order.amendmentSalesQuoteValidated(context);
    }

    //Rem VRP calculate commission after order is validated
    if(context == null || !context.canByPassTrigger('TR023_Order_Commission')) {
        TR023_Order_Commission.processCommission(context);
    }

    if (context == null || !context.canByPassTrigger('QA_UpdateOrderStatusGC')) {
        TR022_Order.updateOrderGCStatus(context);  
    }

    if (context == null || !context.canByPassTrigger('QA_KMDCEinstein')) {
        TR022_Order.scheduleKMDCEinstein(context);
    }

    if(context == null || !context.canByPassTrigger('QA_UpdateAfterSalesServiceStatusGC')){
        TR022_Order.updateAfterSalesServiceGCStatus(context);
    }
}