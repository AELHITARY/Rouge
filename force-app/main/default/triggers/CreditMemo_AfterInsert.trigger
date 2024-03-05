trigger CreditMemo_AfterInsert on CreditMemo__c (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_CreditMemo')) {
        TR022_CreditMemo.updateOrderAfterValidation(context);
    }
}