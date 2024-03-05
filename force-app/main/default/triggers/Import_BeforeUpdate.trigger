trigger Import_BeforeUpdate on Import__c (before update) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR022_Import'))
    TR022_Import.import(context);
}