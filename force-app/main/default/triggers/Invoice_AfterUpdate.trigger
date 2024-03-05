trigger Invoice_AfterUpdate on Invoice__c (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {
        TR020_Invoice.applyValidationRules(context);
    }
    
    if(context == null || !context.canByPassTrigger('TR022_Invoice')) {
        TR022_Invoice.updateOrderAfterValidation(context);
        TR022_Invoice.updateAccountAfterValidation(context);
    }

    if (context == null || !context.canByPassTrigger('QA_KMDCEinstein')) {
        TR022_Invoice.scheduleKMDCEinstein(context);
    }
}