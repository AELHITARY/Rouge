trigger Chantier_BeforeUpdate on Chantier__c (before update) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_Chantier.applyUpdateRules(context);
}