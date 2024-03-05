trigger ServiceAppointment_AfterUpdate on ServiceAppointment (after update) {
    UserContext context = UserContext.getContext();
    
    if(context == null || !context.canByPassValidationRules()) {
        TR022_ServiceAppointment.applyValidationRules(context);
    }
    
    if(context == null || !context.canByPassWorkflowRules()) {
        TR022_ServiceAppointment.applyUpdateRules(context);
    }
    
    /*
    if(context == null || !context.canByPassTrigger('TR022_ServiceAppointment')) {
        TR022_ServiceAppointment.createTaskOnStatus(context);
    }
    */
    
    if(context == null || !context.canByPassTrigger('TR022_ServiceAppointment')) {
        TR022_ServiceAppointment.createServiceReport(context);
    }
    
    if(context == null || !context.canByPassTrigger('TR022_ServiceAppointment')) {
        TR022_ServiceAppointment.updateMinInsallationDate(context);
    } 
}