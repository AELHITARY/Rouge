trigger SBQQ_Quote_BeforeInsert on SBQQ__Quote__c (before insert) {
    UserContext context = UserContext.getContext();
  
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_SBQQ_Quote.applyUpdateRules(context);
    }
}