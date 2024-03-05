trigger Option_BeforeDelete on Option__c (before delete) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassValidationRules()) {
        TR020_Option.applyValidationRules(context);
    }
}