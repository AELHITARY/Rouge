trigger Opportunity_BeforeDelete on Opportunity (before delete) {
  UserContext context = UserContext.getContext();

  IF (context == null || !context.canByPassTrigger('TR022_R040'))
    TR022_R040.countR040FromDeletedOpportunities(context);
    
  // Suppression du RDV sur le phone si le projet est supprimé  
  IF (context == null || !context.canByPassTrigger('TR020_Phones'))
    TR020_Phones.supprimerOpportunity(Trigger.old);
}