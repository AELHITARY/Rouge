trigger AfterSalesService_BeforeInsert on AfterSalesService__c (before insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_AfterSalesService.applyUpdateRules(context);
    }
}