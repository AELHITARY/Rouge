trigger Contact_AfterUpdate on Contact (after update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassTrigger('TR021_Account'))
        TR021_Contact.UR001_K2_Chantier_setProprietairesLocatairesOccupants(context);
}