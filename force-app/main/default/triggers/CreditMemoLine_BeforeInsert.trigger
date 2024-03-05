trigger CreditMemoLine_BeforeInsert on CreditMemoLine__c (before insert) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_CreditMemoLine.applyUpdateRules(context);
    }

    if (context == null || !context.canByPassTrigger('TR022_CreditMemoLine')) {
        TR022_CreditMemoLine.updateLinesNumber(context);
    }
}