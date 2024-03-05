trigger AccountingPiece_BeforeInsert on AccountingPiece__c (before insert) {
    UserContext context = UserContext.getContext();

    TR020_AccountingPiece.cannotCreateAccountingPiece(context); // Ne pas désactiver !
    if (context == null || !context.canByPassValidationRules()) {
        TR020_AccountingPiece.applyValidationRules(context);
    }
    
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_AccountingPiece.applyUpdateRules(context);
    }
}