trigger Option_BeforeInsert on Option__c (before insert) {
    UserContext context = UserContext.getContext();

    // Héritage de Kube v1
    IF (context == null || !context.canByPassTrigger('TR001 CALCULATE PRICE'))
        TR001_Options.calculatePrice (Trigger.new);
}