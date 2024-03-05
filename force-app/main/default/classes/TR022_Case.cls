//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Case
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 08/02/2023
//-- Version     : 1.2
//-- * 1.2 : Réclamation siège, envoi email avec PJ
//-- * 1.1 : Ajout de la fonction pour les NCP
//-- * 1.0 : CRM-956 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_Case {
    private static final String RT_PNC_INTERNALID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_INTERNAL_RT);
    private static final String RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);
    private static final String RT_REQ_A_QUALIFIER = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_AQUALIFIER_RT);
    private static final String RT_REQ_RECLAMATION = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
 
    /**
    * @description Création d'un commentaire publique lors de la modification de la date prévisionnelle de résolution
    * @param userContext Information de l'utilisateur courant
    */
    public static void createCommentPrevi(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
            
        System.debug('### DEBUT TR022_Case.createCommentPrevi');
        // Création d'un commentaire de requéte public si la date prévisionelle de résolution est alimentée ou modifiée
        List<Case> newCases = new List<Case>();
        Map<Id, Case> oldCases = (Map<Id, Case>)Trigger.oldMap;
        List<CaseComment> ccList = new List<CaseComment>();    
        List<FeedItem> feedItemList = New List<FeedItem>();

        // Récupération données Account
        Set<ID> accountIds = new Set<ID>();
        for (Case newCase : (List<Case>)Trigger.new) {
            Case oldCase = oldCases == null ? null : oldCases.get(newCase.Id);

            if (newCase.RecordTypeId != RT_PNC_INTERNALID && newCase.RecordTypeId != RT_PNC_PROVIDERID && newCase.RecordTypeId != RT_REQ_A_QUALIFIER 
                && String.isNotBlank(newCase.AccountId) && newCase.datePrevisionnelleResolution__c != null 
                && (Trigger.isInsert || (Trigger.isUpdate && oldCase != null && newCase.datePrevisionnelleResolution__c != oldCase.datePrevisionnelleResolution__c))) 
            {
                accountIds.add(newCase.AccountId);
                newCases.add(newCase);
            }
        }

        // Traitement
        if(!newCases.isEmpty()) {
            Map<Id, Account> accounts  = new Map<Id, Account>([SELECT Id,Salutation,FirstName,LastName FROM Account WHERE Id IN :accountIds]);
            for(Case newCase : newCases){
                Date datePre=null;
                // En maj, on récupére l'ancienne date
                if(Trigger.isUpdate) {
                    Case oldCase = oldCases.get(newCase.id); 
                    datePre=oldCase.datePrevisionnelleResolution__c;
                }
                // Vérification et création commentaire
                if(newCase.AccountId!=null  && newCase.datePrevisionnelleResolution__c != datePre && newCase.datePrevisionnelleResolution__c != null) {
                    System.debug('## Case Id: '+newCase.Id);
                    Account acc = accounts.get(newCase.AccountId);
                    System.debug('## Acc Id: '+acc.Id);
                    // Construction message du commentaire
                    String comment = String.format(Label.case_msg_commentairePublicPresionnelle, 
                            new List<String>{(String.isBlank(acc.Salutation)?'':acc.Salutation),(String.isBlank(acc.FirstName)?'':acc.FirstName),
                                            (String.isBlank(acc.LastName)?'':acc.LastName),newCase.Type,
                                            newCase.datePrevisionnelleResolution__c.format(),UserInfo.getName()});
                    System.debug('## Comment: '+comment);
                    // Création commentaire
                    CaseComment cc = new CaseComment(ParentId = newCase.Id, 
                                                    IsPublished = true,
                                                    CommentBody = comment);
                    ccList.add(cc);
                }
            }
        }

        // Insertion commentaires
        if(!ccList.isEmpty()) {
            insert ccList;
        }

        System.debug('### FIN TR022_Case.createCommentPrevi');
    }

    /**
    * @description Méthode pour envoyer les notification sur des NCP Fournisseur
    * @param userContext Information de l'utilisateur courant
    */
    public static void sendNotificationsPNC(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
            
        System.debug('### DEBUT TR022_Case.sendNotificationsPNC');
        List<Case> newCases = (List<Case>)Trigger.new;   
        Map<Id, Case> oldCases = (Map<Id, Case>)Trigger.oldMap;
        List<Case> listCaseChildToInsert = new List<Case>();
        
        // Traitement
        for(Case newCase : newCases) {
            //Flux envoi de notification du NPCF Créée
            if(Trigger.isInsert && Trigger.isAfter && newCase.isLegacy__c == false && newCase.RecordTypeId == RT_PNC_PROVIDERID && newCase.createdNCPIExpedition__c==true){
                System.debug('## Case Notification PNC: '+newCase.Id); 
                Map<String, Object> params = new Map<String, Object>();
                params.put('recordId', newCase.Id);
                Flow.Interview.Case_NCP_Notification_NCP_interne_responsabilite_expedition caseFlow = new Flow.Interview.Case_NCP_Notification_NCP_interne_responsabilite_expedition(params);
                caseFlow.start();
            }
        
            // Exécuter le flux d'envoi de notification
            if(Trigger.isInsert && Trigger.isAfter && newCase.isLegacy__c == false && newCase.RecordTypeId == RT_PNC_PROVIDERID) {
                System.debug('## Case Notification PNC: '+newCase.Id); 
                Map<String, Object> params = new Map<String, Object>();
                params.put('recordId', newCase.Id);
                Flow.Interview.Case_PNC_Envoi_Notification caseFlow = new Flow.Interview.Case_PNC_Envoi_Notification(params);
                caseFlow.start();
            }
        }
        
        System.debug('### FIN TR022_Case.sendNotificationsPNC');
    }
    
    public static void updateAccountStatus(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        try{
            Utils_CalculateStatus.refreshAccountStatusFromCase(Trigger.new);        
        } catch(exception e) {
            System.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Méthode pour envoyer un mail au responsables lors d'une réclamation
    * @param userContext Information de l'utilisateur courant
    */
    public static void sendReclaEmail(UserContext userContext){
        if (!Trigger.isExecuting) {
            return;
        }
        
        System.debug('### DEBUT TR022_Case.sendReclaEmail');
        List<Case> newCases = (List<Case>)Trigger.new;
        Map<Id, Case> oldCases = (Map<Id, Case>)Trigger.oldMap;
        List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
        Map<String, String> emailAddressMap = new Map<String, String>();
        List<Case> casesToProcess = new List<Case>();
        List<String> recIdForDoc = new List<String>();
        
        // Vérification si respect du critère d'envoi
        for(Case newCase : newCases) {
            Case oldCase = oldCases == null ? null : oldCases.get(newCase.Id);
            if(Trigger.isAfter && newCase.Origin == 'Courrier' && newCase.IsClosed == false && newCase.aCloturer__c == false
                && newCase.RecordTypeId == RT_REQ_RECLAMATION && oldCase != null && newCase.RecordTypeId != oldCase.RecordTypeId
            ) {
                casesToProcess.add(newCase);
                recIdForDoc.add(newCase.Id);
            }
        }

        if(!casesToProcess.isEmpty()) {
            // Recupère les adresses d'envoi
            for(OrgWideEmailAddress email : [SELECT Id, Address FROM OrgWideEmailAddress]) {
                emailAddressMap.put(email.Address, email.Id);
            }

            // Récupération des contacts depuis le groupe
            List<Group> requestGroup = [SELECT Id FROM Group WHERE Name= 'Réclamation courrier' and Type = 'Regular' LIMIT 1];
            List<String> reclaSiegeGroup = new List<String>();
            if(requestGroup != null && !requestGroup.isEmpty()){
                for(GroupMember objMember : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :requestGroup[0].Id]){
                    if(String.valueOf(objMember.UserOrGroupId).startsWith('005')){
                        reclaSiegeGroup.add(objMember.UserOrGroupId);
                    }
                }
            }

            // Récupération du template pour l'email
            String templateName = PropertiesUtils.getStringValue('case.emailtemplate.reclaSiege', '');
            EmailTemplate emailTemplate = [SELECT Id, DeveloperName, Name, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];

            // Define from address name and Id
            String orgEmailAddressName = 'relationclients@kpark.fr';
            String orgEmailAddressId = emailAddressMap.get(orgEmailAddressName);

            // Récupération des emails
            Map<String, List<String>> emlCaseMap = new Map<String, List<String>>();
            List<String> emlList = new List<String>();
            for(EmailMessage eml : [SELECT Id, ParentId FROM EmailMessage WHERE ParentId IN :recIdForDoc AND Incoming = true]) {
                if(emlCaseMap.get(eml.ParentId) == null) {
                    emlList = new List<String>();
                } else {
                    emlList = emlCaseMap.get(eml.ParentId);
                }
                emlList.add(eml.Id);
                recIdForDoc.add(eml.Id);
                emlCaseMap.put(eml.ParentId, emlList);
            }
            System.debug('## emlCaseMap: '+emlCaseMap);

            // Récupération des pièces jointe
            Map<String, List<String>> docLinkMap = new Map<String, List<String>>();
            Set<String> documentsIdList = new Set<String>();
            List<String> docLinkList = new List<String>();
            for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :recIdForDoc]) {
                if(docLinkMap.get(cdLink.LinkedEntityId) == null) {
                    docLinkList = new List<String>();
                } else {
                    docLinkList = docLinkMap.get(cdLink.LinkedEntityId);
                }
                docLinkList.add(cdLink.ContentDocumentId);
                documentsIdList.add(cdLink.ContentDocumentId);
                docLinkMap.put(cdLink.LinkedEntityId, docLinkList);
            }
            System.debug('## docLinkMap: '+docLinkMap);
            System.debug('## documentsIdList: '+documentsIdList);
            // Execute SOQL ContentVersion
            List<ContentVersion> ctVersionList = new List<ContentVersion>();
            if(!documentsIdList.isEmpty()) {
                ctVersionList = [SELECT Id, Title, VersionData, FileExtension, FileType, ContentDocumentId 
                                    FROM ContentVersion WHERE ContentDocumentId IN :documentsIdList AND IsLatest = true];
            }
            System.debug('## ctVersionList: '+ctVersionList);

            // Process sur les requêtes
            for(Case newCase : casesToProcess) {
                System.debug('## Envoi email: ' + newCase.Id);
                // Création de la liste des contacts
                List<String> contactsIds = new List<String>();
                contactsIds.addAll(reclaSiegeGroup);
                if(String.valueOf(newCase.OwnerId).startsWith('005')){
                    contactsIds.add(newCase.OwnerId);
                }
                if(String.isNotBlank(newCase.UtilisateurN1__c)){
                    contactsIds.add(newCase.UtilisateurN1__c);
                }
                System.debug('## Destinataires: ' + contactsIds);

                List<Messaging.EmailFileAttachment> emailFilesList = new List<Messaging.EmailFileAttachment>();
                // Récupération des pièces jointe liées à la requête
                if(docLinkMap.get(newCase.Id) != null) {
                    System.debug('## Récupération des PJ lié à la requête');
                    // Loop on documentId
                    for(String docId : docLinkMap.get(newCase.Id)) {
                        // Loop on document version                            
                        for(ContentVersion ctVersion : ctVersionList) {
                            if(ctVersion.ContentDocumentId == docId) {
                                System.debug('## ContentDocumentId: '+docId);
                                Messaging.EmailFileAttachment mailFile = new Messaging.EmailFileAttachment();
                                mailFile.setBody(ctVersion.VersionData);
                                mailFile.setFileName(ctVersion.Title + '.' + ctVersion.FileExtension);
                                emailFilesList.add(mailFile);
                            }
                        }
                    }
                }
                // Récupération des pièces jointe liées aux email de la requête
                if(emlCaseMap.get(newCase.Id) != null) {
                    for(String emlId : emlCaseMap.get(newCase.Id)) {
                        System.debug('## Récupération des PJ - email: '+emlId);
                        for(String docId : docLinkMap.get(emlId)) {
                            // Loop on document version                            
                            for(ContentVersion ctVersion : ctVersionList) {
                                if(ctVersion.ContentDocumentId == docId) {
                                    System.debug('## ContentDocumentId: '+docId);
                                    Messaging.EmailFileAttachment mailFile = new Messaging.EmailFileAttachment();
                                    mailFile.setBody(ctVersion.VersionData);
                                    mailFile.setFileName(ctVersion.Title + '.' + ctVersion.FileExtension);
                                    emailFilesList.add(mailFile);
                                }
                            }
                        }
                    }
                }

                // Création du mail
                //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, newCase.OwnerId, newCase.id);
                // Expéditeur
                mail.setOrgWideEmailAddressId(orgEmailAddressId);            
                // Sujet du Mail (Target => Destinataire ; What => Sujet)
                //mail.setTargetObjectId(newCase.OwnerId);
                //mail.setWhatId(newCase.id);
                // Destinataire
                mail.setToAddresses(contactsIds);
                // Ajout du Template
                //mail.setTemplateId(emailTemplate.Id);
                // Ajout de la pièce jointe
                mail.setFileAttachments(emailFilesList);
                mail.setSaveAsActivity(false);
                // Ajout du mail a la liste des mails a envoyer
                emailsToSent.add(mail);
            }

            // Envoi de l'email (pas en mode TEST)
            if(!emailsToSent.isEmpty() && !Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent, false);
                System.debug('## result: ' + result);
            }
        }
        System.debug('### FIN TR022_Case.sendReclaEmail');
    }

    /**
    * @description Mise à jour du statut GC du dossier SAV 
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateAfterSalesServiceGCStatus(UserContext userContext){
        System.debug('### DEBUT TR022_Case.updateAfterSalesServiceGCStatus');
        if (!Trigger.isExecuting)
            return;
        
        Map<Id, Case> oldCases = (Map<Id, Case>)Trigger.oldMap;
        Set<Id> savIdsList = new Set<Id>();
        
        try {
            // A - Initialisation et alimentation des données intermédiaires
            for(Case ncp : (List<Case>)Trigger.new){
                Case oldCase = oldCases == null ? null : oldCases.get(ncp.Id);

                //Se déclenche uniquement pour les ncp interne rattachés à un dossier SAV
                //A la modif des champs impactant le statut GC : aftersalesservice__c, detectedWarranty__c, closedDate, requiredOrder__c, diagnosticDate__c
                if(ncp.afterSalesService__c !=null && ncp.RecordTypeId == RT_PNC_INTERNALID){
                    String savId =  ncp.afterSalesService__c;
                    if(Trigger.isInsert || 
                        (Trigger.isUpdate && 
                        (ncp.aftersalesservice__c != oldCase.aftersalesservice__c ||
                        ncp.detectedWarranty__c != oldCase.detectedWarranty__c ||
                        ncp.closedDate != oldCase.closedDate ||
                        ncp.requiredOrder__c != oldCase.requiredOrder__c ||
                        ncp.diagnosticDate__c != oldCase.diagnosticDate__c))){
                            if(!savIdsList.contains(savId)){
                                savIdsList.Add(savId);
                                System.debug('### savIdList add sav : '+savId);
                            }
                        }
                }
            }
            
            System.debug('savIdsList : '+savIdsList);

            // B - MAJ
            // LEGACY KUBE 2 : Calcul ancien statut GC
            if(!savIdsList.isEmpty() && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                System.debug('## Exec queueable update old status GC: ' + savIdsList);
                System.enqueueJob(new QA_UpdateAfterSalesServiceStatusGC(savIdsList));
            }
        } catch (Exception e) {
            throw e;
        }
        System.debug('### FIN TR022_Case.updateAfterSalesServiceGCStatus');
    }
}