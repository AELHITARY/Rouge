trigger Case_BeforeDelete on Case (before delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_Case.applyValidationRules(context);
    }
}