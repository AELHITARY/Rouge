trigger Task_BeforeUpdate on Task (before update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules())
      TR020_Task.applyUpdateRules(context);
}