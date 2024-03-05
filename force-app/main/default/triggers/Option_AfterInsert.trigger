trigger Option_AfterInsert on Option__c (after insert) {
	UserContext context = UserContext.getContext();
	
	if (!context.canByPassTrigger('TR022_Option')) {
		TR022_Option.updateQuoteExpirationDate(context); 
		TR022_Option.calculateCoefThermique(context);     
	}
}