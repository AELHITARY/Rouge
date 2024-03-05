trigger KContrat_AfterUpdate on KContrat__c (after update) {
    UserContext context = UserContext.getContext();
  
    if (context == null || !context.canByPassTrigger('TR021_KContrat'))
      TR021_KContrat.calculateIndicators(context);
        
    if (context == null || !context.canByPassTrigger('TR022_Quote'))  
      TR022_Quote.setQuoteRecordType(Trigger.new, Constants.RT_QUOTE_RO);   
    
    /* R040 - Statistiques utilisateurs */
    if (context == null || !context.canByPassTrigger('TR022_R040'))
      TR022_R040.fillR040FromKContrats(context);        
}