trigger Collaborator_BeforeInsert on Collaborator__c (before insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Collaborator.applyUpdateRules(context);
    }
}