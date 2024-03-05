trigger EntityVersion_AfterInsert on EntityVersion__c (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_EntityVersion.applyUpdateRules(context);
        TR020_EntityVersion.applyAsyncUpdateRules(context);
    }
}