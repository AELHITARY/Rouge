trigger Contact_AfterDelete on Contact (after delete) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR022_Contact')) {
        TR022_Contact.setDefaultContact(context);
    }
}