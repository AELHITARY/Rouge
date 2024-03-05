trigger OrderNonCompliance_BeforeInsert on OrderNonCompliance__c (before insert) {
    UserContext context = UserContext.getContext();
        
    IF (context == null || !context.canByPassWorkflowRules())
        TR020_OrderNonCompliance.applyUpdateRules(context);
}