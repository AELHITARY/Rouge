trigger Account_AfterInsert on Account (after insert) {
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
        for (Integer i = (Trigger.new.size()-1); i >=0 ; i--) {
            if (context.isCallUser() && Trigger.new[i].OwnerId != context.getUser().Id)
                TR023.add(Trigger.new[i]);
            else if(context.isSaleUser())
                TR023.add(Trigger.new[i]);
        }
        if (TR023.size()>0)
            TR023_ChangeOwner.changerOwnerAccount(TR023);
    }*/

    // DQE Déduplication : Mise à jour de la base DQE
    if (context == null || !context.canByPassTrigger('TR001_Dedoublonnage')) {
        TR001_Dedoublonnage.enqueueDedoublonnageJob(context, 'Account', 'Add');
    }

    // Création des autorisations du compte (Jalons)
    if (context == null || !context.canByPassTrigger('TR022_Account')) {
        TR022_Account.createAutorisation(context);
    }
    
    /* >>> F.G., le 06/10/2015 - Portage vers Odigo Prosodie 3.6
    if (!context.canByPassTrigger('TR023_Account'))
        TR023_Account.notifyCallBack(context);
       --- F.G., le 06/10/2015 - Portage vers Odigo Prosodie 3.6 */
    if (context == null || !context.canByPassTrigger('TR024_Account')) {
        TR024_Account.notifyCallBack(context);
    }
    /* <<< F.G., le 06/10/2015 - Portage vers Odigo Prosodie 3.6 */
}