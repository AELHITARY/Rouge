trigger InvoiceLine_BeforeInsert on InvoiceLine__c (before insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_InvoiceLine.applyUpdateRules(context);
    }

    if (context == null || !context.canByPassTrigger('TR022_InvoiceLine')) {
        TR022_InvoiceLine.updateLinesNumber(context);
    }
}