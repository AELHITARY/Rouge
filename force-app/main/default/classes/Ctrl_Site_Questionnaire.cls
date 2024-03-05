//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Site_Questionnaire
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 02/03/2021
//-- Version     : 1.2
//-- * 1.1 - Gestion pour Kube3
//-- * 1.1 - KPKCRM_RQM-84 : Nouveau questionnaire SATContact
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Site_Questionnaire {
    // Parametres
    public String questionnaireId {get; set;}
    public String objectId {get; set;}
    public String newQues {get; set;}
    public String accountId {get; set;}
    public String resumeId {get; set;}
    public Boolean questionnaireExistant {get; set;}
    public Boolean satisfactionSuperieurA7 {get; set;}
    public Questionnaire__c template {get; set;}
    public List<Question_questionnaire__c> questions {get; set;}
    public List<Option_de_reponse__c> options {get; set;}
    public List<Reponse_questionnaire__c> reponseList {get; set;}
    public Question_questionnaire__c questionSatisfaction {get; set;}
    public Reponse_questionnaire__c reponseSatisfaction {get; set;}
    public String questionsJSONMap {get; set;}
    public String optionsJSONMap {get; set;}
    public String reponsesJSONMap {get; set;}
    public String titreCustplace {get; set;}
    public String avisCustplace {get; set;}
    public String questionSatisfactionId {get; set;}

    // ERRORS
    public Utils_logger log {get; set;}

    /**
    * @description Constructeur
    * @return Ctrl_Site_Questionnaire_NPS 
    */
    public Ctrl_Site_Questionnaire() {
        log = new Utils_logger();

        questionnaireId = ApexPages.currentPage().getParameters().get('qId');
        objectId = ApexPages.currentPage().getParameters().get('oId');
        newQues = ApexPages.currentPage().getParameters().get('newQues');
        questionnaireExistant = false;
        if(newQues != null){
            template = initQuestionnaireSAV();
        } else if(objectId != null && (objectId.startsWith('a02') || objectId.startsWith('801'))){
            template = initQuestionnaireSATCLI();
        } else if(objectId != null && objectId.startsWith('006')){
            template = initQuestionnaireSATcontact();
        } 
        System.debug('resumeId : '+resumeId);

        if(questionnaireExistant && template == null){
            questions = [SELECT Id, commentaire__c, obligatoire__c, ordre__c, page__c, question__c, questionnaire__c, questionParent__c, typeReponse__c
                                FROM Question_questionnaire__c 
                                WHERE questionnaire__c = :questionnaireId AND actif__c = true];

            reponseList = [SELECT Id, question__c, reponseBoolean__c, reponseDate__c, reponseNumero__c, reponseTexte__c, Resume__c, type__c 
                                FROM Reponse_questionnaire__c 
                                WHERE Resume__c = :resumeId];
            
            questionSatisfaction = [SELECT Id, commentaire__c, obligatoire__c, ordre__c, page__c, question__c, questionnaire__c, questionParent__c, typeReponse__c
                                    FROM Question_questionnaire__c 
                                    WHERE questionnaire__c = :questionnaireId AND page__c = 1 AND ordre__c = 3];
            
            reponseSatisfaction = [SELECT Id, question__c, reponseBoolean__c, reponseDate__c, reponseNumero__c, reponseTexte__c, Resume__c, type__c 
                                FROM Reponse_questionnaire__c 
                                WHERE question__c = :questionSatisfaction.Id AND Resume__c = :resumeId];
            
            Resume_questionnaire__c resume = [SELECT Id, clientEstSatisfait__c FROM Resume_questionnaire__c WHERE Id=:resumeId];
            
            if(resume.clientEstSatisfait__c == true) {
                satisfactionSuperieurA7 = true;
            } else {
                satisfactionSuperieurA7 = false;
            }
            System.debug('reponseList : '+reponseList);
        } else if(template != null){
            questions = [SELECT Id, commentaire__c, obligatoire__c, ordre__c, page__c, question__c, questionnaire__c, questionParent__c, typeReponse__c,
            familleChampEnfant__c, familleChampParent__c, reponseAffichage__c
                                FROM Question_questionnaire__c 
                                WHERE questionnaire__c = :questionnaireId AND actif__c = true];
            System.debug('### Questions obtenues. Chargement des options de réponse.');
            List<String> questionsId = new List<String>();
            for(Question_questionnaire__c qq : questions){
                questionsId.add(qq.Id);
            }
            options = [SELECT Id, poids__c, position__c, questionQuestionnaire__c, valeur__c, questionQuestionnaire__r.familleChampParent__c
                                FROM Option_de_reponse__c 
                                WHERE questionQuestionnaire__c IN :questionsId];
        }

        questionsJSONMap = JSON.serialize(questions); 
        optionsJSONMap = JSON.serialize(options); 
        reponsesJSONMap = JSON.serialize(reponseList); 
    }

    /**
    * @description Méthode d'initialisation du questionnaire SATCLI
    * @return Questionnaire__c Template de questionnaire
    */
    public Questionnaire__c initQuestionnaireSATCLI() {
        System.debug('### DEBUT initQuestionnaireSATCLI');
        List<KContrat__c> contrat = new List<KContrat__c>();
        List<Order> order = new List<Order>();

        // Erreur si ID contrat non défini dans l'URL
        if(String.isBlank(objectId)){
            String message = Label.questionnaire_erreur_contratErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } 
        // Erreur si ID questionnaire non défini dans l'URL
        if(String.isBlank(questionnaireId)){
            String message = Label.questionnaire_erreur_questionnaireErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } 

        // Vérification
        List<Resume_questionnaire__c> resume = [SELECT Id, contrat__c FROM Resume_questionnaire__c WHERE contrat__c = :objectId AND questionnaire__c = :questionnaireId LIMIT 1];
        if(objectId.startsWith('a02')) {
            contrat = [SELECT Id, compte__c FROM KContrat__c WHERE id = :objectId LIMIT 1];
        } else if(objectId.startsWith('801')) {
            order = [SELECT Id, AccountId FROM Order WHERE id = :objectId LIMIT 1];
        }

        List<Question_questionnaire__c> questionSatisfaction = [SELECT Id, commentaire__c, obligatoire__c, ordre__c, page__c, question__c, questionnaire__c, questionParent__c, typeReponse__c
                                FROM Question_questionnaire__c 
                                WHERE questionnaire__c = :questionnaireId AND page__c = 1 AND ordre__c = 3];
        
        for(Question_questionnaire__c qa : questionSatisfaction){
            if(qa.page__c == 1 && qa.ordre__c == 3){
                questionSatisfactionId = qa.Id;
            }
        }

        if(!resume.isEmpty()) {
            // Si questionnaire déjà rempli pour ce contrat, interdire l'accès
            resumeId = resume[0].Id;
            questionnaireExistant = true;
            System.debug('questionnaireExistant : '+questionnaireExistant);
            System.debug('## Un résumé de questionnaire existe déjà pour ce contrat/questionnaire. Message de remerciement affiché.');
            return null;
        } else if(contrat.isEmpty() && order.isEmpty()){
            // Si contrat inexistant dans Salesforce
            String message = Label.questionnaire_erreur_contratErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } else {           
            // Recherche template questionnaire
            List<Questionnaire__c> templateQuestionnaire = [SELECT Id, actif__c FROM Questionnaire__c WHERE Id = :questionnaireId LIMIT 1];
            if(templateQuestionnaire.isEmpty() || templateQuestionnaire[0] == null || !templateQuestionnaire[0].actif__c){
                // Si template questionnaire existant dans Salesforce
                String message = Label.questionnaire_erreur_questionnaireErrone;
                System.debug('## '+message);
                log.addErrorMessage(message);
                return null;
            } else {
                // OK
                if(objectId.startsWith('a02')) {
                    accountId = contrat[0].compte__c;
                } else if(objectId.startsWith('801')) {
                    accountId = order[0].AccountId;
                }
                System.debug('## Template actif trouvé. Chargement des questions.');
                return templateQuestionnaire[0];
            }
        }
    }

    /**
    * @description Méthode d'initialisation du questionnaire
    * @return Questionnaire__c Template de questionnaire
    */
    public Questionnaire__c initQuestionnaireSATcontact() {
        System.debug('### DEBUT initQuestionnaireSATcontact');

        // Erreur si ID projet non défini dans l'URL
        if(String.isBlank(objectId)){
            String message = Label.questionnaire_erreur_contratErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } 
        // Erreur si ID questionnaire non défini dans l'URL
        if(String.isBlank(questionnaireId)){
            String message = Label.questionnaire_erreur_questionnaireErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } 

        // Vérification
        List<Resume_questionnaire__c> resume = [SELECT Id, projet__c FROM Resume_questionnaire__c WHERE projet__c = :objectId AND questionnaire__c = :questionnaireId LIMIT 1];
        List<Opportunity> projet = [SELECT Id, AccountId FROM Opportunity WHERE id = :objectId LIMIT 1];
        if(!resume.isEmpty()) {
            // Si questionnaire déjà rempli pour ce projet, interdire l'accès
            resumeId = resume[0].Id;
            questionnaireExistant = true;
            System.debug('## Un résumé de questionnaire existe déjà pour ce projet/questionnaire. Message de remerciement affiché.');
            return null;
        } else if(projet.isEmpty()){
            // Si projet inexistant dans Salesforce
            String message = Label.questionnaire_erreur_contratErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } else {           
            // Recherche template questionnaire
            List<Questionnaire__c> templateQuestionnaire = [SELECT Id, actif__c FROM Questionnaire__c WHERE Id = :questionnaireId LIMIT 1];
            if(templateQuestionnaire.isEmpty() || templateQuestionnaire[0] == null || !templateQuestionnaire[0].actif__c){
                // Si template questionnaire existant dans Salesforce
                String message = Label.questionnaire_erreur_questionnaireErrone;
                System.debug('## '+message);
                log.addErrorMessage(message);
                return null;
            } else {
                // OK
                accountId = projet[0].AccountId;
                System.debug('## Template actif trouvé. Chargement des questions.');
                return templateQuestionnaire[0];
            }
        }
    }

    /**
    * @description Méthode d'initialisation du questionnaire
    * @return Questionnaire__c Template de questionnaire
    */
    public Questionnaire__c initQuestionnaireSAV() {
        System.debug('### DEBUT initQuestionnaireSAV');

        // Erreur si ID contrat non défini dans l'URL
        if(String.isBlank(objectId)){
            String message = Label.questionnaire_erreur_contratErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } 
        // Erreur si ID questionnaire non défini dans l'URL
        if(String.isBlank(questionnaireId)){
            String message = Label.questionnaire_erreur_questionnaireErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } 

        // Vérification
        List<Resume_questionnaire__c> resume = [SELECT Id, contrat__c FROM Resume_questionnaire__c WHERE contrat__c = :objectId AND questionnaire__c = :questionnaireId LIMIT 1];
        List<KContrat__c> contrat = [SELECT Id, compte__c FROM KContrat__c WHERE id = :objectId LIMIT 1];
        if(contrat.isEmpty()){
            // Si contrat inexistant dans Salesforce
            String message = Label.questionnaire_erreur_contratErrone;
            System.debug('## '+message);
            log.addErrorMessage(message);
            return null;
        } else {           
            // Recherche template questionnaire
            List<Questionnaire__c> templateQuestionnaire = [SELECT Id, actif__c FROM Questionnaire__c WHERE Id = :questionnaireId LIMIT 1];
            if(templateQuestionnaire.isEmpty() || templateQuestionnaire[0] == null || !templateQuestionnaire[0].actif__c){
                // Si template questionnaire existant dans Salesforce
                String message = Label.questionnaire_erreur_questionnaireErrone;
                System.debug('## '+message);
                log.addErrorMessage(message);
                return null;
            } else {
                // OK
                accountId = contrat[0].compte__c;
                System.debug('## Template actif trouvé. Chargement des questions.');
                return templateQuestionnaire[0];
            }
        }
    }

    @RemoteAction
    public static void saveQuestionnaire(List<Map<String,String>> answerObject, String questionnaireId, String objectId, String accountId, String newQues) {
        try {
            System.debug('### DEBUT saveQuestionnaire');
            Resume_questionnaire__c nouveauFormulaire = new Resume_questionnaire__c();
            List<Reponse_questionnaire__c> reponsesList = new List<Reponse_questionnaire__c>();
            // Sauvegarde questionnaire
            nouveauFormulaire.questionnaire__c = questionnaireId;
            if(objectId.startsWith('a02')){
                nouveauFormulaire.contrat__c = objectId;
            } else if(objectId.startsWith('006')){
                nouveauFormulaire.projet__c = objectId;
            } else if(objectId.startsWith('801')){
                nouveauFormulaire.order__c = objectId;
            }
            nouveauFormulaire.compte__c = accountId;
            nouveauFormulaire.dateQuestionnaire__c = System.today();
            insert nouveauFormulaire;

            // Sauvegarde réponse
            for(Map<String,String> mapAnswers : answerObject) {
                // Construction de l'objet avec les valeurs
                Reponse_questionnaire__c reponseDetails = new Reponse_questionnaire__c();
                String typeAnswer = String.valueOf(mapAnswers.get('type'));
                reponseDetails.put('Resume__c', nouveauFormulaire.Id);
                reponseDetails.put('question__c', mapAnswers.get('questionId'));
                reponseDetails.put('type__c', typeAnswer);
                if(mapAnswers.get('poids') != null)
                    reponseDetails.put('reponseNumero__c', Decimal.valueOf(mapAnswers.get('poids')));
                if(typeAnswer == Constants.QUESTIONNAIRE_QUESTION_TYPE_CASE || typeAnswer == Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO || typeAnswer == Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE)
                    reponseDetails.put('reponseTexte__c', String.valueOf(mapAnswers.get('reponse')));
                else if(typeAnswer == Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO) {
                    System.debug('mapAnswers : '+mapAnswers.get('reponse'));                    
                    Decimal repNum = mapAnswers.get('reponse') == ''? null : Decimal.valueOf(mapAnswers.get('reponse'));
                    if (repNum >= 0 && repNum <= 10) {
                        reponseDetails.put('reponseNumero__c', repNum);
                    } else if(newQues != null) {
                        reponseDetails.put('reponseNumero__c', null);
                    } else {
                        throw new KubeException('$Label.questionnaire_erreur_numeroErrone');
                    }
                }

                reponsesList.add(reponseDetails);
            }
            insert reponsesList;
            
            // MAJ clientEstSatisfait__c
            Question_questionnaire__c questionSatisfaction = [SELECT Id, commentaire__c, obligatoire__c, ordre__c, page__c, question__c, questionnaire__c, questionParent__c, typeReponse__c
                                    FROM Question_questionnaire__c 
                                    WHERE questionnaire__c = :questionnaireId AND page__c = 1 AND ordre__c = 3];

            Reponse_questionnaire__c reponseSatisfaction = [SELECT Id, question__c, reponseBoolean__c, reponseDate__c, reponseNumero__c, reponseTexte__c, Resume__c, type__c 
                                FROM Reponse_questionnaire__c
                                WHERE question__c = :questionSatisfaction.Id AND Resume__c = :nouveauFormulaire.Id];
            if(reponseSatisfaction.reponseNumero__c >= 7) {
                nouveauFormulaire.clientEstSatisfait__c = true;
            } else {
                nouveauFormulaire.clientEstSatisfait__c = false;
            }
            update nouveauFormulaire;
            
            // Mise à jour contrat
            System.debug('newQues : '+newQues);
            if(objectId.startsWith('a02') && (newQues == null || newQues == '')){
                KContrat__c contrat = new KContrat__c(Id=objectId, dateReponseQuestionnaire__c=Date.today());
                //update contrat;
            } else if(objectId.startsWith('801') && (newQues == null || newQues == '')){
                // Order
            }
            
            System.debug('### FIN saveQuestionnaire');
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    @RemoteAction
    public static void displayAnswer(String resumeId) {
        Resume_questionnaire__c resume = [SELECT Id, clientEstSatisfait__c FROM Resume_questionnaire__c WHERE Id=:resumeId];
        resume.clientEstSatisfait__c = false;
        update resume;
    }

    /**
    * @description Ouverture de la Review box Custplace
    * @return PageReference Page de référence
    */
    public PageReference reviewBoxCustplace() {

        List<Question_questionnaire__c> questionSatisfaction = [SELECT Id, commentaire__c, obligatoire__c, ordre__c, page__c, question__c, questionnaire__c, questionParent__c, typeReponse__c
                                    FROM Question_questionnaire__c 
                                    WHERE questionnaire__c = :questionnaireId AND (page__c = 1 AND (ordre__c = 2 OR ordre__c = 3 OR ordre__c = 5))];
            
        String satisfactionId;
        String titreId;
        String avisId;
        for(Question_questionnaire__c qs : questionSatisfaction){
            if(qs.page__c == 1 && qs.ordre__c == 3){
                satisfactionId = qs.Id;
            } else if(qs.page__c == 1 && qs.ordre__c == 2){
                titreId = qs.Id;
            } else if(qs.page__c == 1 && qs.ordre__c == 5){
                avisId = qs.Id;
            }
        }

        String titreCustplace;
        String avisCustplace;
        List<Resume_questionnaire__c> resumeSatisfaction = [SELECT Id
                                    FROM Resume_questionnaire__c 
                                    WHERE contrat__c = :objectId OR order__c = :objectId];

        List<Reponse_questionnaire__c> reponsesSatisfaction = [SELECT Id, reponseTexte__c, question__c
                                    FROM Reponse_questionnaire__c 
                                    WHERE resume__c = :resumeSatisfaction[0].Id];

        system.debug('titreId : '+titreId);
        system.debug('avisId : '+avisId);
        system.debug('reponsesSatisfaction : '+reponsesSatisfaction);
        for(Reponse_questionnaire__c repQues : reponsesSatisfaction){
                                    system.debug('repQues : '+repQues);
                                    if(repQues.question__c == titreId){
                                        titreCustplace = repQues.reponseTexte__c;
                                    }
                                    if(repQues.question__c == avisId){
                                        avisCustplace = repQues.reponseTexte__c;
                                    }
        }
        system.debug('titreCustplace : '+titreCustplace);
        system.debug('avisCustplace : '+avisCustplace);
        system.debug('resumeSatisfaction[0] : '+resumeSatisfaction[0]);
        
                                    
        PageReference reviewBoxCustplace = Page.VF_Site_ReviewBoxCustplace;
        reviewBoxCustplace.getParameters().put('oId', objectId);
        reviewBoxCustplace.getParameters().put('titre', titreCustplace);
        reviewBoxCustplace.getParameters().put('avis', avisCustplace);
        system.debug(reviewBoxCustplace);
        reviewBoxCustplace.setRedirect(true);
        return reviewBoxCustplace;
    }
}