trigger SBQQ_QuoteLine_AfterInsert on SBQQ__QuoteLine__c (after insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_SBQQ_QuoteLine')) {
        TR022_SBQQ_QuoteLine.getOriginalImageClonedLine(context);
        //TR022_SBQQ_QuoteLine.sendGetKBMaxImages(context);
        TR022_SBQQ_QuoteLine.createWarrantiesRecords(context);
        TR022_SBQQ_QuoteLine.updateParentQuoteLine(context);
        TR022_SBQQ_QuoteLine.updateAcousticCoefficients(context);
    }
}