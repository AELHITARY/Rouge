trigger ReponseQuestionnaire_AfterInsert on Reponse_questionnaire__c (after insert) {
    UserContext context = UserContext.getContext();

    if (context == null || !context.canByPassWorkflowRules()) {
        TR022_ReponseQuestionnaire.setNPSContrat(Trigger.New);
    }
}