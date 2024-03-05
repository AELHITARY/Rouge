trigger Invoice_BeforeDelete on Invoice__c (before delete) {
    UserContext context = UserContext.getContext();

    TR020_Invoice.cannotDeleteInvoice(context); // Ne pas désactiver !
    if (context == null || !context.canByPassValidationRules()) {
        TR020_Invoice.applyValidationRules(context);
    }
}