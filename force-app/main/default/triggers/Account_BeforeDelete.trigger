trigger Account_BeforeDelete on Account (before delete)  { 
    UserContext context = UserContext.getContext();

    // Suppression des autorisations des comptes (Jalons)
    if (context == null || !context.canByPassTrigger('TR022_Account'))
        TR022_Account.deleteAutorisation(context);
}