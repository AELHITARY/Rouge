trigger InvoiceLine_AfterInsert on InvoiceLine__c (after insert) {
    UserContext context = UserContext.getContext();
  
    if (context == null || !context.canByPassTrigger('TR022_InvoiceLine')) {
        TR022_InvoiceLine.calculateVATAmount(context);
        TR022_InvoiceLine.calculateAmounts(context);
    }
}