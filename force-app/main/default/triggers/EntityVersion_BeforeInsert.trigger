trigger EntityVersion_BeforeInsert on EntityVersion__c (before insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {
        TR020_EntityVersion.applyValidationRules(context);
    }
}