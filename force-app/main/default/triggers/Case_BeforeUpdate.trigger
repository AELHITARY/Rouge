trigger Case_BeforeUpdate on Case (before update) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassValidationRules()) {
        TR020_Case.applyValidationRules(context);
    }

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_Case.applyUpdateRules(context);
    }
}