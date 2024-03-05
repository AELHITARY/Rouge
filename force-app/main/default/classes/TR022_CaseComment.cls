//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_CaseComment 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/09/2021
//-- Version     : 1.2
//-- * 1.2 : RQM-278 : Trustpilot
//-- * 1.0 : CRM-956 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_CaseComment {
    
    private static final String RT_PNC_INTERNALID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final String RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);
    
    /**
    * @description Envoi d'un email au client lors de la création d'un commentaire publique sur une requête
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void emailNotificationClient(UserContext userContext) {
        system.debug('### DEBUT TR022_CaseComment.emailNotificationClient');

        List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
        Map<String, String> emailAddressMap = new Map<String, String>();
        List<String> parentIdList = new List<String>();
        Set<Id> owwnerId = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();

        try {
            // Reserve message
            Messaging.reserveSingleEmailCapacity(Trigger.new.size()+1);

            // Récupération du propriétaire des commentaires pour vérifier leur type (provenant du site ou du réseau KPK)
            for (CaseComment cc : (List<CaseComment>)Trigger.new){
                if(cc.IsPublished) 
                    owwnerId.add(cc.CreatedById);
            }
            if (!owwnerId.isEmpty()){
                // Vérification du type d'utilisateur et exécution du processus seulement si c'est un utilisateur non invité
                Map<Id,User> usersMap = new Map<Id,User>([SELECT Id, UserType FROM User WHERE Id IN :owwnerId]);
                for (CaseComment cc : (List<CaseComment>)Trigger.new){
                    if(cc.IsPublished && usersMap.get(cc.CreatedById).UserType != 'Guest') {
                        caseIds.add(cc.ParentId);
                    }
                }
                // Boucle sur les requêtes pour MAJ champ
                if (!caseIds.isEmpty()){
                    List<Case> caseList = new List<Case>([SELECT Id, AccountId, Account.contactParDefaut__c, Account.IsPersonAccount, Account.civilite__c, motif__c, Status,
                                                            Account.nom__c, Account.prenom__c, CaseNumber, Type, typeDeRendezVous__c, CHNumero__c, CHRue__c, CHCodePostal__c, CHVille__c, Description,
                                                            Account.AccountNumber, Account.PersonContactId, Account.email__c, RecordTypeId FROM Case WHERE Id IN :caseIds AND AccountId!=null]);
                    // Recupère les adresses d'envoi
                    for(OrgWideEmailAddress email : [SELECT Id, Address FROM OrgWideEmailAddress])
                        emailAddressMap.put(email.Address, email.Id);
                        
                    // Récupère le template            
                    String templateName = PropertiesUtils.getStringValue('case.emailtemplate.commentPublique', '');
                    EmailTemplate emailTemplate = [SELECT Id, DeveloperName, Name, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];

                    // Pour toutes les requêtes, envoi de l'email
                    for (Case cases : caseList) {
                        if(cases.RecordTypeId != RT_PNC_INTERNALID && cases.RecordTypeId != RT_PNC_PROVIDERID) {
                            String orgEmailAddressName = '';
                            String orgEmailAddressId = null;
                            
                            // Define from address name and Id
                            orgEmailAddressName = 'relationclients@kpark.fr';
                            orgEmailAddressId = emailAddressMap.get(orgEmailAddressName);
                            
                            // Récupère les informations du compte
                            Account acc = cases.Account;
                            if(String.isNotBlank(acc.email__c)) {                           
                                
                                // Création du mail
                                List<Messaging.SingleEmailmessage> listSingleEmailMessages = new List<Messaging.SingleEmailmessage> ();
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                // Expéditeur
                                mail.setOrgWideEmailAddressId(orgEmailAddressId);
                                // Destinataire
                                if(acc.IsPersonAccount)
                                    mail.setTargetObjectId(acc.PersonContactId);
                                else
                                    mail.setTargetObjectId(acc.contactParDefaut__c);
                                
                                mail.setWhatId(cases.Id);
                                mail.setSaveAsActivity(false);
                                //mail.setTreatBodiesAsTemplate(true);
                                mail.setTemplateId(emailTemplate.Id);
                                emailsToSent.add(mail);
                            }
                        }
                    }
                }
            }
            // Envoi de l'email (pas en mode TEST)
            if(!emailsToSent.isEmpty() && !Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent, false);
                system.debug('## result: ' + result);
            }
            system.debug('### FIN TR022_CaseComment.emailNotificationClient');

        } catch(HandledException e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        } catch (EmailException e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Email de notification de création de commentaire non envoyé', e);
            //throw e;
        }
    }

    /**
    * @description Envoi d'un email au client lors de la création d'un commentaire publique sur une requête
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void envoiCommentaireTrustpilot(UserContext userContext) {
        system.debug('### DEBUT TR022_CaseComment.envoiCommentaireTrustpilot');

        List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
        Map<String, String> emailAddressMap = new Map<String, String>();
        Map<String,Case> caseMap = new Map<String,Case>();
        List<String> parentIdList = new List<String>();
        Set<Id> owwnerId = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        List<CaseComment> newCC = (List<CaseComment>)Trigger.new;  
        
        System.debug('newCC : '+newCC);

        try {

            // Récupération du propriétaire des commentaires pour vérifier leur type (provenant du site ou du réseau KPK)
            for (CaseComment cc : newCC){
                owwnerId.add(cc.CreatedById);
            }
            System.debug('owwnerId : '+owwnerId);
            if (!owwnerId.isEmpty()){
                // Vérification du type d'utilisateur et exécution du processus seulement si c'est un utilisateur non invité
                Map<Id,User> usersMap = new Map<Id,User>([SELECT Id, UserType FROM User WHERE Id IN :owwnerId]);
                for (CaseComment cc : (List<CaseComment>)Trigger.new){
                    if(usersMap.get(cc.CreatedById).UserType != 'Guest') {
                        caseIds.add(cc.ParentId);
                    }
                }
                System.debug('caseIds : '+caseIds);
                // Boucle sur les requêtes pour MAJ champ
                if (!caseIds.isEmpty()){
                    List<Case> caseList = new List<Case>([SELECT Id, source__c, trustpilotReviewID__c
                                                        FROM Case 
                                                        WHERE Id IN :caseIds]);
                    
                    for(Case cas : caseList){
                        caseMap.put(cas.Id, cas);
                    }
                    System.debug('caseMap : '+caseMap);
                    
                    for (CaseComment cc : (List<CaseComment>)Trigger.new){
                        System.debug('cc : '+cc);
                        System.debug('cc.ParentId : '+cc.ParentId);
                        System.debug('caseMap.get(cc.ParentId) : '+caseMap.get(cc.ParentId));
                        System.debug('caseMap.get(cc.ParentId).source__c : '+caseMap.get(cc.ParentId).source__c);
                        System.debug('cc : '+cc);
                        if(Trigger.isInsert && caseMap.get(cc.ParentId).source__c == 'Trustpilot') {
                            Utils_TrustPilot.replyToReview(caseMap.get(cc.ParentId).trustpilotReviewID__c, cc.CommentBody);
                        }
                    }
                }
            }
            system.debug('### FIN TR022_CaseComment.envoiCommentaireTrustpilot');
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Commentaire de requête non envoyé à Trustpilot', e);
            //throw e;
        }
    }
}