trigger WorkOrder_BeforeUpdate on WorkOrder (before update) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassValidationRules() && !context.canByPassTrigger('TR001_fsl_WorkOrder')) {
        TR001_fsl_WorkOrder.crlCoherenceDateValidite(context); 
    }

    if (context == null || !context.canByPassValidationRules()) {
        TR020_WorkOrder.applyValidationRules(context); 
    }   

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_WorkOrder.applyUpdateRules(context);
    }  
}