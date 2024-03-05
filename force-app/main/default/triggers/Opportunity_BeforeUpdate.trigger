trigger Opportunity_BeforeUpdate on Opportunity (before update) {
  UserContext context = UserContext.getContext();

  IF (context == null || !context.canByPassWorkflowRules())
    TR020_Opportunity.applyUpdateRules(context);
}