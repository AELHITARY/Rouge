trigger ServiceAppointment_BeforeDelete on ServiceAppointment (before delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_ServiceAppointment.applyValidationRules(context);
    }
}