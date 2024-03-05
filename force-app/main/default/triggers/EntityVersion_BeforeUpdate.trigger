trigger EntityVersion_BeforeUpdate on EntityVersion__c (before update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {
        TR020_EntityVersion.applyValidationRules(context);
    }
}