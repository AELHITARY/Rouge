trigger Invoice_AfterInsert on Invoice__c (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {
        //TR020_Invoice.applyValidationRules(context);
    }
}