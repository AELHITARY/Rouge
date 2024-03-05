trigger CollaboratorContract_AfterDelete on CollaboratorContract__c (after delete) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_CollaboratorContract')){
        TR022_CollaboratorContract.updateCollaboratorsRecords(context);
    }
}