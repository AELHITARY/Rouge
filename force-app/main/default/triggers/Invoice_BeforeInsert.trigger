trigger Invoice_BeforeInsert on Invoice__c (before insert) {
    UserContext context = UserContext.getContext();
  
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Invoice.applyUpdateRules(context);
    }
}