trigger Chantier_AfterUpdate on Chantier__c (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassValidationRules())
        TR020_Chantier.applyValidationRules(context);

    if(context == null || !context.canByPassWorkflowRules())
        TR020_Chantier.applyAsyncUpdateRules(context);

    // Modification du propriétaire
    /*if(context != null && !context.canByPassTrigger('TR023_Chantier')) {
        List<Chantier__c> TR023 = new List<Chantier__c>{};
        for(Integer i = (Trigger.new.size()-1); i >=0 ; i--) {
            if(context.isCallUser() && Trigger.new[i].OwnerId != Trigger.old[i].OwnerId) {
                TR023.add(Trigger.new[i]);
                /** >>> F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface
                } else if(!context.isCallUser()) {
                --- F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface **/
            /*} else if(context.isSaleUser()) {
                /** >>> F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface **/
                /*TR023.add(Trigger.new[i]);
            }
        }

        if(TR023.size()>0) {
            TR023_ChangeOwner.changerOwnerChantier(TR023);
        }
    }*/

    // DQE Déduplication : Mise à jour de la base DQE
    if(context == null || !context.canByPassTrigger('TR001_Dedoublonnage'))
        TR001_Dedoublonnage.enqueueDedoublonnageJob(context, 'Chantier', 'Update');

    if(context == null || !context.canByPassTrigger('TR021_Chantier'))
        TR021_Chantier.calculateIndicators(context);

    if(context == null || !context.canByPassTrigger('TR022_Chantier')){
        TR022_Chantier.updateLocalisations(context);
        TR022_Chantier.updateAccountAddress(context);
        TR022_Chantier.updateAsset();
    }
}