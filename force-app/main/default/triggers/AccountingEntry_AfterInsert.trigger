trigger AccountingEntry_AfterInsert on AccountingEntry__c (after insert) {
    UserContext context = UserContext.getContext();

    TR020_AccountingEntry.checkUniqueEntity(context);
}