trigger Collaborator_AfterInsert on Collaborator__c (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Collaborator.applyUpdateRules(context);
    }
}