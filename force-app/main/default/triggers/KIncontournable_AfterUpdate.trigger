trigger KIncontournable_AfterUpdate on KIncontournable__c (after update) {
    UserContext context = UserContext.getContext();
  
    if (context == null || !context.canByPassTrigger('TR021_KIncontournable'))
        TR021_KIncontournable.calculateIndicators(context);
    
    if (context == null || !context.canByPassTrigger('TR022_Quote'))  
        TR022_Quote.setQuoteRecordType(Trigger.new, Constants.RT_QUOTE_RO);       
}