trigger Contact_AfterInsert on Contact (after insert) {
  UserContext context = UserContext.getContext();

  if(context == null || !context.canByPassTrigger('TR022_Contact')) {
    TR022_Contact.setDefaultContact(context);
  }
}