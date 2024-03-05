trigger Task_AfterUpdate on Task (after update) {
    UserContext context = UserContext.getContext();

    IF (context == null || !context.canByPassTrigger('TR021_Task'))
        TR021_Task.calculateIndicators(context);    
}