trigger Collaborator_AfterUpdate on Collaborator__c (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Collaborator.applyUpdateRules(context);
    }
}