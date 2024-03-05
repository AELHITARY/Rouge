trigger KInstance_AfterDelete on KInstance__c (after delete) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_KInstance'))
    TR021_KInstance.calculateIndicators(context);
}