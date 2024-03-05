//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_Ctrl_Site_Questionnaire
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 06/03/2022
//-- Version     : 1.0
//-- * 1.0 Init
//-- --------------------------------------------------------------------------------- --
@isTest
private class Test_Ctrl_Site_Questionnaire {
    
    @testSetup 
    static void setup() {
        Utils_Test.createGlobalProperties(true, 17, true, true, true, 30, 10, true);
        Utils_Test.createSectorisation();
                
        // Récupération des types d'enregistrement
        Id accRecordType = DAL.getRecordTypeIdByDevName(Constants.ACCOUNT_PERSO_RT);
        
        // Création d'un compte
        Account account = Utils_Test.createAccount('Test', 'test', 'testespaceclient@salesforce.com', accRecordType, 'Client', 'FAX', true);
        
        // Création d'un chantier        
        Chantier__c chantier = Utils_Test.createChantier('Chantier 1', account.Id, true);

        // Création d'un projet
        Opportunity opp = Utils_Test.createOpportunity(account, chantier, true);

        // Création du template du questionnaire
        Questionnaire__c questionnaire = new Questionnaire__c(actif__c = true);
        insert questionnaire;

        // Création des questions
        List<Question_questionnaire__c> listQuestions = new List<Question_questionnaire__c>();
        Question_questionnaire__c question11 = Utils_Test.createQuestionQuestionnaire(questionnaire.Id, Constants.QUESTIONNAIRE_QUESTION_TYPE_TITRE, 'Test?', 1, 1, false, '(test)', false);
        listQuestions.add(question11);
        Question_questionnaire__c question12 = Utils_Test.createQuestionQuestionnaire(questionnaire.Id, Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO, 'Test?', 1, 2, true, '(test)', false);
        listQuestions.add(question12);
        Question_questionnaire__c question13 = Utils_Test.createQuestionQuestionnaire(questionnaire.Id, Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE, 'Test?', 1, 3, false, '(test)', false);
        listQuestions.add(question13);
        Question_questionnaire__c question21 = Utils_Test.createQuestionQuestionnaire(questionnaire.Id, Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO, 'Test?', 2, 1, false, '(test)', false);
        listQuestions.add(question21);
        insert listQuestions;

        // Création des réponses
        List<Option_de_reponse__c> listOptionsDeReponses =  new List<Option_de_reponse__c>();
        Option_de_reponse__c option111 = Utils_Test.createOptionDeReponse(question11.Id, '1', 1, 1, false);
        listOptionsDeReponses.add(option111);
        Option_de_reponse__c option112 = Utils_Test.createOptionDeReponse(question11.Id, '2', 2, 2, false);
        listOptionsDeReponses.add(option112);
        Option_de_reponse__c option113 = Utils_Test.createOptionDeReponse(question11.Id, '3', 3, 3, false);
        listOptionsDeReponses.add(option113);
        insert listOptionsDeReponses;
        
        // Création d'un contrat
        KContrat__c contratMetrage = Utils_Test.createContrat('Contrat Metrage', chantier.Id, account.Id, '0002', true);
    }

    @isTest 
    static void generationQuestionnairesMultiples() {

        List<KContrat__c> contratsList = [SELECT Id, compte__c FROM KContrat__c];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
        List<Questionnaire__c> questionnaires = [SELECT Id FROM Questionnaire__c];
        List<Question_questionnaire__c> questionnairesList = [SELECT Id, typeReponse__c FROM Question_questionnaire__c 
                                                                WHERE typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE 
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO 
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO  
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_CASE ];
        // Test avec contrat nul
        Test.startTest();
        PageReference pageVF = Page.VF_Site_Questionnaire;
        pageVF.getParameters().put('oId', null);
        pageVF.getParameters().put('qId', questionnaires[0].Id);
        Test.setCurrentPage(pageVF);
        Ctrl_Site_Questionnaire ctrl = new Ctrl_Site_Questionnaire();

        // Test avec questionnaire nul
        PageReference pageVF2 = Page.VF_Site_Questionnaire;
        pageVF2.getParameters().put('oId', contratsList[0].Id);
        pageVF2.getParameters().put('qId', null);
        Test.setCurrentPage(pageVF2);
        Ctrl_Site_Questionnaire ctrl2 = new Ctrl_Site_Questionnaire();

        // Test avec contrat incorrect
        PageReference pageVF3 = Page.VF_Site_Questionnaire;
        pageVF3.getParameters().put('oId', (String.valueOf(contratsList[0].Id)).toLowerCase());
        pageVF3.getParameters().put('qId', questionnaires[0].Id);
        Test.setCurrentPage(pageVF3);
        Ctrl_Site_Questionnaire ctrl3 = new Ctrl_Site_Questionnaire();

        // Test avec questionnaire incorrect
        PageReference pageVF4 = Page.VF_Site_Questionnaire;
        pageVF4.getParameters().put('oId', contratsList[0].Id);
        pageVF4.getParameters().put('qId', (String.valueOf(questionnaires[0].Id)).toLowerCase());
        Test.setCurrentPage(pageVF4);
        Ctrl_Site_Questionnaire ctrl4 = new Ctrl_Site_Questionnaire();

        // Test avec ID corrects
        PageReference pageVF5 = Page.VF_Site_Questionnaire;
        pageVF5.getParameters().put('oId', contratsList[0].Id);
        pageVF5.getParameters().put('qId', questionnaires[0].Id);
        Test.setCurrentPage(pageVF5);
        Ctrl_Site_Questionnaire ctrl5 = new Ctrl_Site_Questionnaire();

        // Préparation de la liste des réponses à rentrer en base (comportement de l'utilisateur ayant répondu à toutes les questions)
        List<Map<String, String>> reponsesList = new List<Map<String, String>>();
        for(Question_questionnaire__c qq : questionnairesList){
            Map<String, String> reponseMap = new Map<String, String>();
            reponseMap.put('questionId', qq.Id);
            reponseMap.put('type', qq.typeReponse__c);
            if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE || qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_CASE){
                reponseMap.put('reponse', 'Test123');
                reponseMap.put('poids', null);
            } else if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO){
                reponseMap.put('reponse', '1');
                reponseMap.put('poids', null);
            } else if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO){
                reponseMap.put('reponse', 'Test123');
                reponseMap.put('poids', '1');
            }
            reponsesList.add(reponseMap);
        }

        // Sauvegarde du questionnaire
        Ctrl_Site_Questionnaire.saveQuestionnaire(reponsesList, questionnaires[0].Id, contratsList[0].Id, contratsList[0].compte__c, null);

        // Vérification : un nouvel enregistrement "Résumé questionnaire" doit être inséré.
        List<Resume_questionnaire__c> questionnairesRempliList = [SELECT Id FROM Resume_questionnaire__c];
        System.assertEquals(1, questionnairesRempliList.size(), 'saveQuestionnaire failed');

        // Vérification : les réponses donnéees par l'utilisateur à chaque question doivent être individuellement insérées.
        List<Reponse_questionnaire__c> reponsesQuestionnaireList = [SELECT Id FROM Reponse_questionnaire__c];
        System.assertEquals(3, reponsesQuestionnaireList.size(), 'saveQuestionnaire failed');

        // Test avec ID corrects et questionnaire déjà existant
        PageReference pageVF6 = Page.VF_Site_Questionnaire;
        pageVF6.getParameters().put('oId'  , contratsList[0].Id);
        pageVF6.getParameters().put('qId' , questionnaires[0].Id);
        Test.setCurrentPage(pageVF6);
        Ctrl_Site_Questionnaire ctrl6 = new Ctrl_Site_Questionnaire();

        //Reviewbox Custplace
        PageReference pageVFCP1 = ctrl6.reviewBoxCustplace();
        PageReference pageVFCP = Page.VF_Site_ReviewBoxCustplace;
        pageVFCP.getParameters().put('oId', contratsList[0].Id);
        Test.setCurrentPage(pageVFCP);
        Ctrl_Site_ReviewBoxCustplace ctrlCP = new Ctrl_Site_ReviewBoxCustplace();

        // Update
        Reponse_questionnaire__c rep = reponsesQuestionnaireList[0];
        rep.reponseNumero__c = 2;
        update rep;

        Test.stopTest();
    }

    @isTest 
    static void generationSATcontact() {

        List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity];
        List<Questionnaire__c> questionnaires = [SELECT Id FROM Questionnaire__c];
        List<Question_questionnaire__c> questionnairesList = [SELECT Id, typeReponse__c FROM Question_questionnaire__c 
                                                                WHERE typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE 
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO 
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO  
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_CASE ];

        // Test avec contrat nul
        Test.startTest();
        PageReference pageVF1 = Page.VF_Site_Questionnaire;
        pageVF1.getParameters().put('oId', null);
        pageVF1.getParameters().put('qId', questionnaires[0].Id);
        Test.setCurrentPage(pageVF1);
        Ctrl_Site_Questionnaire ctrl1 = new Ctrl_Site_Questionnaire();

        // Test avec questionnaire nul
        PageReference pageVF2 = Page.VF_Site_Questionnaire;
        pageVF2.getParameters().put('oId', oppList[0].Id);
        pageVF2.getParameters().put('qId', null);
        Test.setCurrentPage(pageVF2);
        Ctrl_Site_Questionnaire ctrl2 = new Ctrl_Site_Questionnaire();

        // Test avec contrat incorrect
        PageReference pageVF3 = Page.VF_Site_Questionnaire;
        pageVF3.getParameters().put('oId', (String.valueOf(oppList[0].Id)).toLowerCase());
        pageVF3.getParameters().put('qId', questionnaires[0].Id);
        Test.setCurrentPage(pageVF3);
        Ctrl_Site_Questionnaire ctrl3 = new Ctrl_Site_Questionnaire();

        // Test avec questionnaire incorrect
        PageReference pageVF4 = Page.VF_Site_Questionnaire;
        pageVF4.getParameters().put('oId', oppList[0].Id);
        pageVF4.getParameters().put('qId', (String.valueOf(questionnaires[0].Id)).toLowerCase());
        Test.setCurrentPage(pageVF4);
        Ctrl_Site_Questionnaire ctrl4 = new Ctrl_Site_Questionnaire();

        // Test avec ID corrects
        PageReference pageVF = Page.VF_Site_Questionnaire;
        pageVF.getParameters().put('oId', oppList[0].Id);
        pageVF.getParameters().put('qId', questionnaires[0].Id);
        Test.setCurrentPage(pageVF);
        Ctrl_Site_Questionnaire ctrl = new Ctrl_Site_Questionnaire();

        // Préparation de la liste des réponses à rentrer en base (comportement de l'utilisateur ayant répondu à toutes les questions)
        List<Map<String, String>> reponsesList = new List<Map<String, String>>();
        for(Question_questionnaire__c qq : questionnairesList){
            Map<String, String> reponseMap = new Map<String, String>();
            reponseMap.put('questionId', qq.Id);
            reponseMap.put('type', qq.typeReponse__c);
            if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE || qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_CASE){
                reponseMap.put('reponse', 'Test123');
                reponseMap.put('poids', null);
            } else if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO){
                reponseMap.put('reponse', '1');
                reponseMap.put('poids', null);
            } else if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO){
                reponseMap.put('reponse', 'Test123');
                reponseMap.put('poids', '1');
            }
            reponsesList.add(reponseMap);
        }

        // Sauvegarde du questionnaire
        Ctrl_Site_Questionnaire.saveQuestionnaire(reponsesList, questionnaires[0].Id, oppList[0].Id, oppList[0].AccountId, null);

        // Vérification : un nouvel enregistrement "Résumé questionnaire" doit être inséré.
        List<Resume_questionnaire__c> questionnairesRempliList = [SELECT Id FROM Resume_questionnaire__c];
        System.assertEquals(1, questionnairesRempliList.size(), 'saveQuestionnaire failed');

        // Vérification : les réponses donnéees par l'utilisateur à chaque question doivent être individuellement insérées.
        List<Reponse_questionnaire__c> reponsesQuestionnaireList = [SELECT Id FROM Reponse_questionnaire__c];
        System.assertEquals(3, reponsesQuestionnaireList.size(), 'saveQuestionnaire failed');

        // Update
        Reponse_questionnaire__c rep = reponsesQuestionnaireList[0];
        rep.reponseNumero__c = 2;
        update rep;
    }

    @isTest 
    static void generationQuestionnaireSAV() {

        List<KContrat__c> contratsList = [SELECT Id, compte__c FROM KContrat__c];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
        List<Questionnaire__c> questionnaires = [SELECT Id FROM Questionnaire__c];
        List<Question_questionnaire__c> questionnairesList = [SELECT Id, typeReponse__c FROM Question_questionnaire__c 
                                                                WHERE typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE 
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO 
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO  
                                                                    OR typeReponse__c = :Constants.QUESTIONNAIRE_QUESTION_TYPE_CASE ];
        // Test avec ID corrects
        Test.startTest();
        PageReference pageVF5 = Page.VF_Site_Questionnaire;
        pageVF5.getParameters().put('oId', contratsList[0].Id);
        pageVF5.getParameters().put('qId', questionnaires[0].Id);
        pageVF5.getParameters().put('newQues', 'yes');
        Test.setCurrentPage(pageVF5);
        Ctrl_Site_Questionnaire ctrl5 = new Ctrl_Site_Questionnaire();

        // Préparation de la liste des réponses à rentrer en base (comportement de l'utilisateur ayant répondu à toutes les questions)
        List<Map<String, String>> reponsesList = new List<Map<String, String>>();
        for(Question_questionnaire__c qq : questionnairesList){
            Map<String, String> reponseMap = new Map<String, String>();
            reponseMap.put('questionId', qq.Id);
            reponseMap.put('type', qq.typeReponse__c);
            if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_TEXTE || qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_CASE){
                reponseMap.put('reponse', 'Test123');
                reponseMap.put('poids', null);
            } else if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_NUMERO){
                reponseMap.put('reponse', '1');
                reponseMap.put('poids', null);
            } else if(qq.typeReponse__c == Constants.QUESTIONNAIRE_QUESTION_TYPE_RADIO){
                reponseMap.put('reponse', 'Test123');
                reponseMap.put('poids', '1');
            }
            reponsesList.add(reponseMap);
        }

        // Sauvegarde du questionnaire
        Ctrl_Site_Questionnaire.saveQuestionnaire(reponsesList, questionnaires[0].Id, contratsList[0].Id, contratsList[0].compte__c, 'yes');

        // Vérification : un nouvel enregistrement "Résumé questionnaire" doit être inséré.
        List<Resume_questionnaire__c> questionnairesRempliList = [SELECT Id FROM Resume_questionnaire__c];
        System.assertEquals(1, questionnairesRempliList.size(), 'saveQuestionnaire failed');

        // Vérification : les réponses donnéees par l'utilisateur à chaque question doivent être individuellement insérées.
        List<Reponse_questionnaire__c> reponsesQuestionnaireList = [SELECT Id FROM Reponse_questionnaire__c];
        System.assertEquals(3, reponsesQuestionnaireList.size(), 'saveQuestionnaire failed');

        // Update
        Reponse_questionnaire__c rep = reponsesQuestionnaireList[0];
        rep.reponseNumero__c = 2;
        update rep;

        // Test avec ID corrects et questionnaire déjà existant
        PageReference pageVF6 = Page.VF_Site_Questionnaire;
        pageVF6.getParameters().put('oId'  , contratsList[0].Id);
        pageVF6.getParameters().put('qId' , questionnaires[0].Id);
        pageVF6.getParameters().put('newQues', 'yes');
        Test.setCurrentPage(pageVF6);
        Ctrl_Site_Questionnaire ctrl6 = new Ctrl_Site_Questionnaire();
        Test.stopTest();
    }
}