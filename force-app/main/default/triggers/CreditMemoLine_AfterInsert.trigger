trigger CreditMemoLine_AfterInsert on CreditMemoLine__c (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_CreditMemoLine')) {
        TR022_CreditMemoLine.calculateVATAmount(context);
        TR022_CreditMemoLine.calculateAmounts(context);
    }
}