trigger AccountingPiece_BeforeDelete on AccountingPiece__c (before delete) {
    UserContext context = UserContext.getContext();

    TR020_AccountingPiece.cannotDeleteAccountingPiece(context); // Ne pas désactiver !
    if (context == null || !context.canByPassValidationRules()) {
        TR020_AccountingPiece.applyValidationRules(context);
    }
}