trigger WorkOrder_BeforeDelete on WorkOrder (before delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_WorkOrder.applyValidationRules(context); 
    }
    
    if ((context == null || !context.canByPassTrigger('TR002_fsl_WorkOrder'))){
        TR002_fsl_WorkOrder.supprimerAbsenceLiee(context);
    }
}