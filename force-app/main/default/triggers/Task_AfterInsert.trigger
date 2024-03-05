trigger Task_AfterInsert on Task (after insert) {
    UserContext context = UserContext.getContext();    
        
    IF (context == null || !context.canByPassTrigger('TR021_Task'))
        TR021_Task.calculateIndicators(context);  
         
    // Mise à jour de la date de dernier contact du compte
    if(context == null || !context.canByPassTrigger('TR022_Task')){
        TR022_Task.updateAccountStatus(context);
    } 
}