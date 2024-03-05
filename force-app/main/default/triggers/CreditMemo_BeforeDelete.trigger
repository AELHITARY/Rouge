trigger CreditMemo_BeforeDelete on CreditMemo__c (before delete) {
    UserContext context = UserContext.getContext();

    TR020_CreditMemo.cannotDeleteCreditMemo(context); // Ne pas désactiver !
    if(context == null || !context.canByPassValidationRules()) {
        TR020_CreditMemo.applyValidationRules(context);
    }
}