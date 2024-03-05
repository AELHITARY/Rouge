trigger Chantier_AfterDelete on Chantier__c (after delete) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR021_Chantier'))
        TR021_Chantier.calculateIndicators(context);

    // DQE Déduplication : Mise à jour de la base DQE
    if(context == null || !context.canByPassTrigger('TR001_Dedoublonnage'))
        TR001_Dedoublonnage.enqueueDedoublonnageJob(context, 'Chantier', 'Delete');
}