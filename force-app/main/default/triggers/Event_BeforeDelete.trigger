trigger Event_BeforeDelete on Event (before delete) {
  UserContext context = UserContext.getContext();
  
  IF (context == null || !context.canByPassTrigger('TR021_Event'))
    TR020_Event.applyValidationRules(context);
}