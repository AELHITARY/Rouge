trigger Option_AfterUpdate on Option__c (after update) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_Option')) {
        TR022_Option.updateQuoteExpirationDate(context);    
        TR022_Option.calculateCoefThermique(context);  
    }
}