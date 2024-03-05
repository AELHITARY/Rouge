trigger SBQQ_QuoteLine_BeforeDelete on SBQQ__QuoteLine__c (before delete) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassValidationRules()) {
        TR020_SBQQ_QuoteLine.applyValidationRules(context);
    }
    if (context == null || !context.canByPassTrigger('TR022_SBQQ_QuoteLine')) {
        TR022_SBQQ_QuoteLine.deleteWarrantiesRecords(context);
        TR022_SBQQ_QuoteLine.deleteChildrenQuoteLines(context);
        TR022_SBQQ_QuoteLine.deleteCommissionsPrev(context);
    }
}