trigger ServiceAppointment_AfterDelete on ServiceAppointment (after delete) {
UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR022_ServiceAppointment.updateMinInsallationDate(context);
    }

}