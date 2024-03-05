trigger AccountingPiece_BeforeUpdate on AccountingPiece__c (before update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_AccountingPiece.applyValidationRules(context);
    }
    
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_AccountingPiece.applyUpdateRules(context);
    }
}