trigger InvoiceLine_BeforeDelete on InvoiceLine__c (before delete) {
    UserContext context = UserContext.getContext();

    TR020_InvoiceLine.cannotDeleteInvoiceLine(context); // Ne pas désactiver !
    if (context == null || !context.canByPassValidationRules()) {
        TR020_InvoiceLine.applyValidationRules(context);
    }
}