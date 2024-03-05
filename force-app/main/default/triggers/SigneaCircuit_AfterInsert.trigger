trigger SigneaCircuit_AfterInsert on Signea__Circuit__c (after insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_SigneaCircuit')){
        TR022_SigneaCircuit.updateQuotes(context);
        TR022_SigneaCircuit.updateCPQ_Quotes(context);
    }
}