/**
 * Created by 4C on 16/11/2020.
 */
trigger CollaboratorContract_AfterUpdate on CollaboratorContract__c (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_CollaboratorContract.applyUpdateRules();
    }
    if(context == null || !context.canByPassTrigger('TR022_CollaboratorContract')){
        TR022_CollaboratorContract.updateCollaboratorsRecords(context);
    }
}