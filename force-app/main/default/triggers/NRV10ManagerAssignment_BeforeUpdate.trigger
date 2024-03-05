/**
* @author 4C
* @date 2020-07-27
* @description check concurency assignment for the manager before saving.
*/
trigger NRV10ManagerAssignment_BeforeUpdate on NRV10ManagerAssignment__c (before update) {
    UserContext context = UserContext.getContext();
    
    // check concurent team or manager assignments
    if (context == null || !context.canByPassValidationRules() || !context.canByPassTrigger('TR020_AffectationManager'))
        TR020_NRV10ManagerAssignment.applyValidationRules();
}