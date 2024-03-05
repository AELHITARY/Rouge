trigger SBQQ_QuoteLine_BeforeUpdate on SBQQ__QuoteLine__c (before update) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_SBQQ_QuoteLine.applyUpdateRules(context);
    }
    if (context == null || !context.canByPassTrigger('TR022_SBQQ_QuoteLine')) {
        TR022_SBQQ_QuoteLine.sendGetKBMaxImages(context);
    }
}