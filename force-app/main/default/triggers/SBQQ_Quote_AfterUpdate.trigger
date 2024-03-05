trigger SBQQ_Quote_AfterUpdate on SBQQ__Quote__c (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_SBQQ_Quote')){
        TR022_SBQQ_Quote.setMontantLignesDevisCEE(context);
        TR022_SBQQ_Quote.updatePrice(context);
    }
    
    if(context == null || !context.canByPassTrigger('TR023_SBQQ_Quote')){
        TR023_SBQQ_Quote.generateDocuments(context);
    }

    if(context == null || !context.canByPassTrigger('QA_UpdateAfterSalesServiceStatusGC')){
        TR022_SBQQ_Quote.updateAfterSalesServiceGCStatus(context);
    }
    
    /*if(context == null || !context.canByPassTrigger('TR020_SBQQ_Quote_Commission')){
        TR020_SBQQ_Quote_Commission.processCalculateCommissions(context);
    }*/
}