trigger Collaborator_BeforeUpdate on Collaborator__c (before update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Collaborator.applyUpdateRules(context);
    }
}