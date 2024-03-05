trigger Account_AfterDelete on Account (after delete) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR021_Account')) {
        TR021_Account.UR001_K2_Chantier_setProprietairesLocatairesOccupants(context);
    }
        
    if(context == null || !context.canByPassTrigger('TR022_Account')) {
        TR022_Account.processDeleteEntity(Trigger.old);
    }
    
    // DQE Déduplication : Mise à jour de la base DQE
    if(context == null || !context.canByPassTrigger('TR001_Dedoublonnage')) {
        TR001_Dedoublonnage.enqueueDedoublonnageJob(context, 'Account', 'Delete');
    }
}