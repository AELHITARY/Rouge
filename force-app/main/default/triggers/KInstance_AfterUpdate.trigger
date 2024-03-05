trigger KInstance_AfterUpdate on KInstance__c (after update) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_KInstance'))
    TR021_KInstance.calculateIndicators(context);
}