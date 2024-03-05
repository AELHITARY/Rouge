trigger KIncontournable_AfterDelete on KIncontournable__c (after delete) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_KIncontournable'))
    TR021_KIncontournable.calculateIndicators(context);
}