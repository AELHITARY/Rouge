trigger SBQQ_Quote_AfterInsert on SBQQ__Quote__c (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_SBQQ_Quote.applyUpdateRules(context);
    }

    if(context == null || !context.canByPassTrigger('QA_UpdateAfterSalesServiceStatusGC')){
        TR022_SBQQ_Quote.updateAfterSalesServiceGCStatus(context);
    }
}