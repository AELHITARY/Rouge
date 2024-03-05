trigger Case_BeforeInsert on Case (before insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules()) {
        TR020_Case.applyValidationRules(context);
    }

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_Case.applyUpdateRules(context);
    }

    // KUBE3 - Process pour import données GC
    TR020_Case.applyLegacyUpdateRules(context);
}