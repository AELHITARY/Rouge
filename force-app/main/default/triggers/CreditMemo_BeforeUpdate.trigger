trigger CreditMemo_BeforeUpdate on CreditMemo__c (before update) {
    UserContext context = UserContext.getContext();
  
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_CreditMemo.applyUpdateRules(context);
    }
}