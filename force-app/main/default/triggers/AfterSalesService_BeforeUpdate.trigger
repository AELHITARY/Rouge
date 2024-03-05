trigger AfterSalesService_BeforeUpdate on AfterSalesService__c (before update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_AfterSalesService.applyUpdateRules(context);
    }
}