trigger Task_BeforeInsert on Task (before insert) {
    UserContext context = UserContext.getContext(); 
    
    if(context == null || !context.canByPassWorkflowRules())
      TR020_Task.applyUpdateRules(context);
}