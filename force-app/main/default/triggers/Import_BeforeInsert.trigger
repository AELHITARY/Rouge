trigger Import_BeforeInsert on Import__c (before insert) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR022_Import'))
    TR022_Import.import(context);
}