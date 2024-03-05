trigger ReponseQuestionnaire_AfterUpdate on Reponse_questionnaire__c (after update) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassWorkflowRules()){
        TR022_ReponseQuestionnaire.setNPSContrat(Trigger.New);
    }
}