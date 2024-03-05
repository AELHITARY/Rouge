trigger Event_AfterDelete on Event (after delete) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_Event'))
    TR021_Event.calculateIndicators(context);

  IF (context == null || !context.canByPassTrigger('TR022_R040'))
    TR022_R040.fillR040FromEvents(context);   
  
  // Suppression du lien Phone-RDV si le RDV est supprimé  
  IF (context == null || !context.canByPassTrigger('TR020_Phones'))
    TR020_Phones.supprimerEventLink(Trigger.old); 
}