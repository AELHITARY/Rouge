//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_ReponseQuestionnaire
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/01/2019
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR022_ReponseQuestionnaire {

    /**
    * @description Mise à jour des NPS recommendation et satisfaction des contrats associés
    * @param resumeQuestionnaireList Liste des résumés de questionnaires
    */
    public static void setNPSContrat(List<Reponse_questionnaire__c> reponseQuestionnaireList) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### START TR022_ReponseQuestionnaire.setNPSContrat');
        List<Resume_questionnaire__c> resumeList = new List<Resume_questionnaire__c>();
        List<Reponse_questionnaire__c> reponseQuestionnaireListFiltree = new List<Reponse_questionnaire__c>();
        List<KContrat__c> contratList = new List<KContrat__c>();
        List<String> resumeIds = new List<String>();
        List<String> contratIds = new List<String>();
        String idQuestionRecommendation = PropertiesUtils.getStringValue('satcli.nps.question.recommendation',null);
        String idQuestionSatisfaction = PropertiesUtils.getStringValue('satcli.nps.question.satisfaction',null);
        
        // récupération des devis associés et de toutes leur lignes
        if(reponseQuestionnaireList != null){
            for(Reponse_questionnaire__c rq : reponseQuestionnaireList){
                if(rq.question__c == idQuestionRecommendation || rq.question__c == idQuestionSatisfaction){
                    reponseQuestionnaireListFiltree.add(rq);
                    resumeIds.add(rq.resume__c);
                }
            }
            resumeList = [SELECT Id, contrat__c FROM Resume_questionnaire__c WHERE Id IN :resumeIds];
            for(Resume_questionnaire__c res : resumeList){
                contratIds.add(res.contrat__c);
            }
            contratList = [SELECT Id, NPSRecommandation__c, NPSSatisfaction__c FROM KContrat__c WHERE Id IN :contratIds];
            Map<String,KContrat__c> contratMap = new Map<String,KContrat__c>();
            for(KContrat__c con : contratList){
                contratMap.put(con.Id, con);
            }
            Set<String> contratIdToUpdate = new Set<String>();
            if(!resumeList.isEmpty()){
                for(Resume_questionnaire__c res : resumeList){
                    for(Reponse_questionnaire__c rq : reponseQuestionnaireListFiltree){
                        KContrat__c contrat = contratMap.get(res.contrat__c);
                        if(contrat != null && rq.question__c == idQuestionRecommendation && rq.resume__c == res.Id){
                            contrat.NPSRecommandation__c = rq.reponseNumero__c;
                            contratIdToUpdate.add(contrat.Id);
                        }
                        if(contrat != null && rq.question__c == idQuestionSatisfaction && rq.resume__c == res.Id){
                            contrat.NPSSatisfaction__c = rq.reponseNumero__c;
                            contratIdToUpdate.add(contrat.Id);
                        }
                    }
                }

                List<KContrat__c> contratToUpdate = new List<KContrat__c>();
                for(String conId : contratIdToUpdate){
                    contratToUpdate.add(contratMap.get(conId));
                }
                update contratToUpdate;
            }
        }
        system.debug('### END TR022_ReponseQuestionnaire.setNPSContrat');
    }
}