trigger Opportunity_AfterDelete on Opportunity (after delete) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_Opportunity'))
    TR021_Opportunity.calculateIndicators(context);
    
  IF (context == null || !context.canByPassTrigger('TR022_R040'))
    TR022_R040.fillR040FromOpportunities(context);
}