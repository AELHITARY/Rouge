trigger Option_BeforeUpdate on Option__c (before update) {
    UserContext context = UserContext.getContext();
    
    // Héritage de Kube v1
    IF (context == null || !context.canByPassTrigger('TR001 CALCULATE PRICE'))
        TR001_Options.calculatePrice (Trigger.new);
}