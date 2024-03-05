trigger CreditMemoLine_BeforeDelete on CreditMemoLine__c (before delete) {
    UserContext context = UserContext.getContext();

    TR020_CreditMemoLine.cannotDeleteCreditMemoLine(context); // Ne pas désactiver !
    if (context == null || !context.canByPassValidationRules()) {
        TR020_CreditMemoLine.applyValidationRules(context);
    }
}