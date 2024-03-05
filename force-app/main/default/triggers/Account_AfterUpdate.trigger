trigger Account_AfterUpdate on Account (after update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassValidationRules()) {
        TR020_Account.applyValidationRules(context);
    }

    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_Account.applyAsyncUpdateRules(context);
    }
    
    if (context == null || !context.canByPassWorkflowRules()) {
        TR020_Account.applyEntitiesRules(context);
    }

    // Modification du propriétaire
    /*if (context != null && !context.canByPassTrigger('TR023_ChangeOwner')) {
        List<Account> TR023 = new List<Account>{};
        for(Integer i = (Trigger.new.size()-1); i >=0 ; i--) {
            if(context.isCallUser() && Trigger.new[i].OwnerId != Trigger.old[i].OwnerId) {
                TR023.add(Trigger.new[i]);
                /** >>> F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface
                } else if(!context.isCallUser()) {
                --- F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface **/
            /*} else if(context.isSaleUser()) {
                /** <<< F.G., le 03/09/2013 - Erreur lors de la mise à jour en masse par administreurs ou interface **/
                /*TR023.add(Trigger.new[i]);
            }
        }
        if(TR023.size()>0) {
            TR023_ChangeOwner.changerOwnerAccount(TR023);
        }
    }*/

    // DQE Déduplication : Mise à jour de la base DQE
    if (context == null || context == null || !context.canByPassTrigger('TR001_Dedoublonnage'))
        TR001_Dedoublonnage.enqueueDedoublonnageJob(context, 'Account', 'Update');

    if (context == null || !context.canByPassTrigger('TR021_Account'))
        TR021_Account.UR001_K2_Chantier_setProprietairesLocatairesOccupants(context);

    if (context == null || !context.canByPassTrigger('TR022_Account'))
        TR022_Account.setEmailParrain(context);

    /* >>> F.G., le 06/10/2015 - Portage vers Odigo Prosodie 3.6 */
    if (context == null || !context.canByPassTrigger('TR024_Account')) {
        TR024_Account.notifyCallBack(context);
    }
    /* <<< F.G., le 06/10/2015 - Portage vers Odigo Prosodie 3.6 */
}