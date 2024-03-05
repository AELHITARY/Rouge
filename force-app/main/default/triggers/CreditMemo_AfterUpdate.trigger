trigger CreditMemo_AfterUpdate on CreditMemo__c (after update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_CreditMemo.applyValidationRules(context);
    }
    
    if(context == null || !context.canByPassTrigger('TR022_CreditMemo')) {
        TR022_CreditMemo.updateOrderAfterValidation(context);
        TR022_CreditMemo.updateAccountAfterValidation(context);
    }

    if (context == null || !context.canByPassTrigger('QA_KMDCEinstein')) {
        TR022_CreditMemo.scheduleKMDCEinstein(context);
    }
}