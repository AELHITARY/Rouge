trigger CreditMemoLine_BeforeUpdate on CreditMemoLine__c (before update) {
    UserContext context = UserContext.getContext();
  
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_CreditMemoLine.applyUpdateRules(context);
    }
}