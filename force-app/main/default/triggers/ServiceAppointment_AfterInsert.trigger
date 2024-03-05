trigger ServiceAppointment_AfterInsert on ServiceAppointment (after insert) {
    UserContext context = UserContext.getContext();
  
    if(context == null || !context.canByPassValidationRules()) {
        TR022_ServiceAppointment.applyValidationRules(context);
    }
        
    if(context == null || !context.canByPassWorkflowRules()) {
        TR022_ServiceAppointment.applyUpdateRules(context);
    }

    if (context == null || !context.canByPassValidationRules()) {
        TR022_ServiceAppointment.updateMinInsallationDate(context);
    } 

}