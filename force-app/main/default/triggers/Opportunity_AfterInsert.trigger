trigger Opportunity_AfterInsert on Opportunity (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules())
        TR020_Opportunity.applyValidationRules(context);

    if (context == null || !context.canByPassTrigger('TR021_Opportunity'))
        TR021_Opportunity.calculateIndicators(context);

    if (context == null || !context.canByPassTrigger('TR023_Opportunity'))
        TR023_Opportunity.associerALaCampagne(context);
        
    // Mise à jour de la date de dernier contact du compte
    if(!context.canByPassTrigger('TR022_Opportunity')){
        TR022_Opportunity.updateAccountStatus(context);
    }

    if (context == null || !context.canByPassTrigger('TR020_SharingRulesProcess')) {
        List <Opportunity> TR020_Opportunity= new List<Opportunity>{};

        for(Opportunity opp : Trigger.new) {
            if (opp.publicSharing__c == false)
                TR020_Opportunity.add(opp);
        }

        if(TR020_Opportunity.size()>0)
            TR020_SharingRulesProcess.OpportunityPublicSharingTrigger(TR020_Opportunity,Trigger.oldMap);
    }

    if (context == null || !context.canByPassTrigger('TR022_R040'))
        TR022_R040.fillR040FromOpportunities(context);
}