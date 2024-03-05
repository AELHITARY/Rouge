trigger AccountingPiece_AfterInsert on AccountingPiece__c (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_AccountingPiece.applyValidationRules(context);
    }
    if (context == null || !context.canByPassTrigger('TR022_AccountingPiece')) {
        TR022_AccountingPiece.updateEntryAmountbyAccPiece(context);
        TR022_AccountingPiece.updateParentAndCancelFieldsRollup(context);
        TR022_AccountingPiece.updateOrderAndAccountAmount(context);
        TR022_AccountingPiece.updateInvoiceAdvanceAmount(context);
        TR022_AccountingPiece.executeApprovalProcess(context);
    }
}