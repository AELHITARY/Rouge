trigger AccountingEntry_BeforeUpdate on AccountingEntry__c (before update) {
    UserContext context = UserContext.getContext();

    TR020_AccountingEntry.checkUniqueEntity(context);
}