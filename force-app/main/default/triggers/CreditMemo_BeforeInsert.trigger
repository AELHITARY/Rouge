trigger CreditMemo_BeforeInsert on CreditMemo__c (before insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_CreditMemo.applyUpdateRules(context);
    }
}