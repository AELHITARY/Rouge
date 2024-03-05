trigger EntityVersion_AfterUpdate on EntityVersion__c (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_EntityVersion.applyUpdateRules(context);
        TR020_EntityVersion.applyAsyncUpdateRules(context);
    }
}