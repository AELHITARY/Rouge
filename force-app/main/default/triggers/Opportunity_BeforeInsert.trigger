trigger Opportunity_BeforeInsert on Opportunity (before insert) {
  UserContext context = UserContext.getContext();

  IF (context == null || !context.canByPassWorkflowRules())
    TR020_Opportunity.applyUpdateRules(context);
}