trigger SBQQ_QuoteLine_AfterUpdate on SBQQ__QuoteLine__c (after update) {
	UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_SBQQ_QuoteLine')) {
        TR022_SBQQ_QuoteLine.sendGetKBMaxImages(context);
        TR022_SBQQ_QuoteLine.updateSortOrder(context);
        TR022_SBQQ_QuoteLine.updateAcousticCoefficients(context);
    }
}