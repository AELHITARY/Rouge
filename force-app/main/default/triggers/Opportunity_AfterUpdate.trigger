trigger Opportunity_AfterUpdate on Opportunity (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules())
        TR020_Opportunity.applyValidationRules(context);

    // Modification du propriétaire
    /*if(context == null || !context.canByPassTrigger('TR023_ChangeOwner')) {
        List<Opportunity> TR023 = new List<Opportunity>{};
        for(Integer i = (Trigger.new.size()-1); i >=0 ; i--) {
            if(context != null && context.isCallUser() && Trigger.new[i].OwnerId != Trigger.old[i].OwnerId) {
                TR023.add(Trigger.new[i]);
                /** >>> F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface
                } else if(context != null && !context.isCallUser()) {
                >>> F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface **/
            /*} else if(context != null && context.isSaleUser()) {
                /** >>> F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface **/
                /*TR023.add(Trigger.new[i]);
            }
        }

        if(TR023.size()>0) {
            TR023_ChangeOwner.changerOwnerOpportunity(TR023);
        }
    }*/

    if(context == null || !context.canByPassTrigger('TR021_Opportunity'))
        TR021_Opportunity.calculateIndicators(context);

    if(context == null || !context.canByPassTrigger('TR022_Opportunity'))
        TR022_Opportunity.changeQuoteLineItemConfigurer(context);

    if(context == null || !context.canByPassTrigger('TR023_Opportunity'))
        TR023_Opportunity.associerALaCampagne(context);

    if(context == null || !context.canByPassTrigger('TR020_SharingRulesProcess')) {
        List <Opportunity> TR020_Opportunity= new List<Opportunity>{};

        for(Opportunity opp : Trigger.new) {
            if (opp.publicSharing__c == false)
                TR020_Opportunity.add(opp);
        }

        if(TR020_Opportunity.size()>0)
            TR020_SharingRulesProcess.OpportunityPublicSharingTrigger(TR020_Opportunity,Trigger.oldMap);
    }

    /* R040 - Héritage de Kube 1 */
    /**
    IF (!context.canByPassTrigger('TR001_Opportunity_Stat'))
        TR001_Opportunity_Stat.execute();
    **/
    if(context == null || !context.canByPassTrigger('TR022_R040'))
        TR022_R040.fillR040FromOpportunities(context);
}