trigger Option_AfterDelete on Option__c (after delete) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_Option')) {
        TR022_Option.updateQuoteExpirationDate(context);
    }
}