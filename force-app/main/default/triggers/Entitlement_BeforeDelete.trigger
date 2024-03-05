trigger Entitlement_BeforeDelete on Entitlement (before delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR020_Entitlement'))
        TR020_Entitlement.applyValidationRules(context);
}