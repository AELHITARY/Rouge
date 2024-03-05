trigger InvoiceLine_AfterDelete on InvoiceLine__c (after delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_InvoiceLine')) {
        TR022_InvoiceLine.calculateVATAmount(context);
        TR022_InvoiceLine.updateLinesNumberDelete(context);
    }
}