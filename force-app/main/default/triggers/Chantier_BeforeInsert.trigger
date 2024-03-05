trigger Chantier_BeforeInsert on Chantier__c (before insert) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassWorkflowRules())
    TR020_Chantier.applyUpdateRules(context);
}