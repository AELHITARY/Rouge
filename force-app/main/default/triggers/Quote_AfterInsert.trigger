trigger Quote_AfterInsert on Quote (after insert) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR021_Quote'))
        TR021_Quote.calculateIndicators(context);

    // R040 - Héritage de Kube v1
    /*
    IF (!context.canByPassTrigger('TR001_Quote_Stat'))
        TR001_Quote_Stat.execute();
    */
    if (context == null || !context.canByPassTrigger('TR022_R040'))
        TR022_R040.fillR040FromQuotes(context);

    // 15/03/2018 - JMU - RQM-47 - Calcul des informations CEE (montant total et montant des lignes de devis)
    /*if(context == null || !context.canByPassTrigger('TR022_Quote'))
        TR022_Quote.setMontantLignesDevisCEE(context);*/
        
    if (context == null || !context.canByPassValidationRules())
        TR020_Quote.applyValidationRules(context);
    
    // Mise à jour de la date de dernier contact du compte
    if(context == null || !context.canByPassTrigger('TR022_Quote')){
        TR022_Quote.updateAccountStatus(context);
    }
}