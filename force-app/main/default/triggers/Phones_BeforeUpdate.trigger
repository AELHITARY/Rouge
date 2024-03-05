trigger Phones_BeforeUpdate on PhoningVendeur__c (before update) {
    UserContext context = UserContext.getContext();
    
    if (context == null || !context.canByPassTrigger('TR020_Phones')) { 
        TR020_Phones.phoneAvecRDVConfirme(context);     
    }
}