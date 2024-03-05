trigger AccountingEntry_BeforeDelete on AccountingEntry__c (before delete) {
    UserContext context = UserContext.getContext();

    TR020_AccountingEntry.cannotDeleteAccountingEntry(context); // Ne pas désactiver !
}