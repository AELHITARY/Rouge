trigger KInstance_AfterInsert on KInstance__c (after insert) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_KInstance'))
    TR021_KInstance.calculateIndicators(context);
}