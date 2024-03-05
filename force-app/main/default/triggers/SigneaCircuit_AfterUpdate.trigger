trigger SigneaCircuit_AfterUpdate on Signea__Circuit__c (after update) {
    UserContext context = UserContext.getContext();
    System.debug('tracker');
    
    if (context == null || !context.canByPassTrigger('TR022_SigneaCircuit')){
        TR022_SigneaCircuit.updateQuotes(context);
        TR022_SigneaCircuit.updateCPQ_Quotes(context);
    }
}