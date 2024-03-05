trigger InvoiceLine_BeforeUpdate on InvoiceLine__c (before update) {
    UserContext context = UserContext.getContext();
  
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_InvoiceLine.applyUpdateRules(context);
    }
}