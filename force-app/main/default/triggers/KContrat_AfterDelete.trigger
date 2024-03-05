trigger KContrat_AfterDelete on KContrat__c (after delete) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_KContrat'))
    TR021_KContrat.calculateIndicators(context);
}