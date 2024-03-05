trigger Event_AfterInsert on Event (after insert) {
	UserContext context = UserContext.getContext();

  	if(context == null || !context.canByPassValidationRules()) {
		TR020_Event.applyValidationRules(context);
	}
    
  	if(context == null || !context.canByPassWorkflowRules()) {
		TR020_Event.applyAsyncUpdateRules(context);
	}

  	if(context == null || !context.canByPassTrigger('TR021_Event')) {
		TR021_Event.calculateIndicators(context);
	}
    
    // Mise à jour de la date de dernier contact du compte
    if(context == null || !context.canByPassTrigger('TR022_Event')){
        TR022_Event.updateAccountStatus(context);
    }

  	if(context == null || !context.canByPassTrigger('TR022_R040')) {
		TR022_R040.fillR040FromEvents(context); 
	}

  	// Héritage de Kube v1
  	if(context == null || !context.canByPassTrigger('TR007 Dernier RDV')) {
		TR007_SetLastMeeting.execute(context);
	}
}