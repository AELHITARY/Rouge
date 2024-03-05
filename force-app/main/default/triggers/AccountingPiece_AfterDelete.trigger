trigger AccountingPiece_AfterDelete on AccountingPiece__c (after delete) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR022_AccountingPiece')) {
        TR022_AccountingPiece.updateParentAndCancelFieldsRollup(context);
    }
}