/**
 * Created by 4C on 14/09/2020.
 */

trigger NRV10ManagerAssignment_AfeterInsert on NRV10ManagerAssignment__c (after insert) {
    UserContext context = UserContext.getContext();

    // update concurrent manager assignments
    if (context == null || !context.canByPassTrigger('TR020_AffectationManager'))
        TR020_NRV10ManagerAssignment.applyUpdateRules();

}