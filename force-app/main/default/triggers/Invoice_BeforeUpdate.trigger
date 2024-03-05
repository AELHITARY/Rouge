trigger Invoice_BeforeUpdate on Invoice__c (before update) {
    UserContext context = UserContext.getContext();
  
    TR020_Invoice.applyNonByPassableRules(context);
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Invoice.applyUpdateRules(context);
    }
}