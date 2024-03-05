trigger AssignedResource_BeforeInsert on AssignedResource (before insert) {
    UserContext context = UserContext.getContext();
    
    IF (context == null || !context.canByPassWorkflowRules())
    TR020_AssignedResource.applyUpdateRules(context);
}