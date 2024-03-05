trigger AccountingEntry_BeforeInsert on AccountingEntry__c (before insert) {
    UserContext context = UserContext.getContext();
}