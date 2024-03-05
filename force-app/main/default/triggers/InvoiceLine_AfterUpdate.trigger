trigger InvoiceLine_AfterUpdate on InvoiceLine__c (after update) {
    UserContext context = UserContext.getContext();
  
    if (context == null || !context.canByPassTrigger('TR022_InvoiceLine')) {
        TR022_InvoiceLine.calculateVATAmount(context);
        TR022_InvoiceLine.calculateAmounts(context);
    }
}