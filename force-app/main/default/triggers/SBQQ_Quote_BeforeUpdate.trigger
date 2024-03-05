/**
 * Created by 4C on 22/10/2020.
 */
trigger SBQQ_Quote_BeforeUpdate on SBQQ__Quote__c (before update) {
    UserContext context = UserContext.getContext();
  
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_SBQQ_Quote.applyUpdateRules(context);
    }
}