trigger SBQQ_ProductOption_AfterUpdate on SBQQ__ProductOption__c (after update) {
    UserContext context = UserContext.getContext();
        if(context == null || !context.canByPassTrigger('TR022_SBQQ_ProductOption')){
        TR022_SBQQ_ProductOption.updateCaseItemInterventionDuration(context);
    }

}