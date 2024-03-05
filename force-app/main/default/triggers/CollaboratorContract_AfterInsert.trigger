trigger CollaboratorContract_AfterInsert on CollaboratorContract__c (after insert) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_CollaboratorContract')){
        TR022_CollaboratorContract.updateCollaboratorsRecords(context);
    }
}