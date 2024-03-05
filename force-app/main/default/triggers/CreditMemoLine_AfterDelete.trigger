trigger CreditMemoLine_AfterDelete on CreditMemoLine__c (after delete) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassTrigger('TR022_CreditMemoLine')) {
        TR022_CreditMemoLine.calculateVATAmount(context);
        TR022_CreditMemoLine.updateLinesNumberDelete(context);
    }
}