trigger OrderNonCompliance_BeforeUpdate on OrderNonCompliance__c (before update) {
    UserContext context = UserContext.getContext();
        
    IF (context == null || !context.canByPassWorkflowRules())
        TR020_OrderNonCompliance.applyUpdateRules(context);
}