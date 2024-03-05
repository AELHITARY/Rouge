//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_ContentVersion
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/04/2023
//-- Version     : 1.1
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_ContentVersion {
    private static final String RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);

    /**
    * @description Fonction pour créer des liens publique pour les fichiers
    * @param userContext Information de l'utilisateur courant
    */
    public static void createPublicLinkForFile(UserContext userContext) {
        System.debug('### DEBUT TR022_ContentVersion.createPublicLinkForFile');        
        List<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();
        List<ContentVersion> newContentVersions = new List<ContentVersion>();
        List<Id> contentDocIdList = new List<Id>();
        Map<Id,Id> contentDisListMap = new Map<Id,Id>();

        for(ContentVersion newCtVersion : (List<ContentVersion>)Trigger.new){
            System.debug('## FileType: '+newCtVersion.FileType.toLowerCase());
            System.debug('## Id: '+newCtVersion.Id);
            System.debug('## Content Document Id: ' + newCtVersion.ContentDocumentId);
            contentDocIdList.add(newCtVersion.ContentDocumentId);
        }

        List<ContentDistribution> contentDisList = [SELECT Id, ContentVersionId, ContentDocumentId
                                                                FROM ContentDistribution 
                                                                WHERE ContentDocumentId IN :contentDocIdList];
        System.debug('## contentDisList: ' + contentDisList.size());
        for(ContentDistribution ctLink : contentDisList) {
            contentDisListMap.put(ctLink.ContentDocumentId, ctLink.Id);
        }

        for(ContentVersion newCtVersion : (List<ContentVersion>)Trigger.new){
            String linkExistId = contentDisListMap.get(newCtVersion.ContentDocumentId);
            if(String.isBlank(linkExistId)) {
                // Création de l'objet
                System.debug('## No link for: '+newCtVersion.Id);
                distributionsToInsert.add(createContentDistribution(newCtVersion));
            }
        }
        
        // Insert des lignes
        System.debug('## distributionsToInsert: '+distributionsToInsert);
        if(!distributionsToInsert.isEmpty()) {
            insert distributionsToInsert;
        }
        System.debug('### FIN TR022_ContentVersion.createPublicLinkForFile');   
    }

    /**
    * @description Fonction pour les différents objets
    * @param userContext Information de l'utilisateur courant
    */
    public static void processLinkToObject(UserContext userContext) {
        System.debug('### DEBUT TR022_ContentVersion.processLinkToObject');        
        List<ContentDocumentLink> cdLinkQLI = new List<ContentDocumentLink>(); 
        List<ContentDocumentLink> cdLinkCase = new List<ContentDocumentLink>();
        List<ContentVersion> contVersionList = (List<ContentVersion>)Trigger.new;
        List<String> cdIdList = new List<String>();

        for(ContentVersion newCtVersion : contVersionList){
            System.debug('## Id: '+newCtVersion.Id);
            System.debug('## ContentDocumentId: '+newCtVersion.ContentDocumentId);

            // Récupération des ID des document pour récupérer les liens
            if(String.isNotBlank(newCtVersion.ContentDocumentId)) {
                cdIdList.add(newCtVersion.ContentDocumentId);
            }
        }

        // Récupération des liens pour vérifier l'objet
        if(!cdIdList.isEmpty()) {
            for(ContentDocumentLink cdLink : [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIdList]) {
                System.debug('## LinkedEntityId: '+cdLink.LinkedEntityId);
                // Vérification si lié a QLI
                if( (Trigger.isInsert || Trigger.isUpdate) && cdLink.LinkedEntityId.getSobjectType() == Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c')){
                    System.debug('## Modification QLI: '+cdLink.LinkedEntityId);
                    cdLinkQLI.add(cdLink);
                }
                // Vérification si lié a un Case
                if( (Trigger.isInsert) && cdLink.LinkedEntityId.getSobjectType() == Schema.getGlobalDescribe().get('Case')){
                    System.debug('## Case: '+cdLink.LinkedEntityId);
                    cdLinkCase.add(cdLink);
                }
            }
        }

        // Processus par objet
        if(!cdLinkQLI.isEmpty()) {
            updateQLIKBMaxFlag(cdLinkQLI);
        }
        if(!cdLinkCase.isEmpty()) {
            casePNCProviderNotification(cdLinkCase);
        }
        System.debug('### FIN TR022_ContentVersion.processLinkToObject');   
    }

    /**
    * @description Fonction pour modifier la catégorie du document si image KBMAX
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateCategoryKBMaxImage(UserContext userContext) {
        System.debug('### DEBUT TR022_ContentVersion.updateCategoryKBMaxImage');        
        List<String> cdIdList = new List<String>();
        
        for(ContentVersion newCtVersion : (List<ContentVersion>)Trigger.new){
            System.debug('## Id: '+newCtVersion.Id);
            System.debug('## ContentDocumentId: '+newCtVersion.ContentDocumentId);

            // Récupération des ID des document pour récupérer les liens si catégorie vide
            if(String.isNotBlank(newCtVersion.ContentDocumentId) && String.isBlank(newCtVersion.category__c)) {
                cdIdList.add(newCtVersion.ContentDocumentId);
            }
        }

        // Appel fonction asynchrone
        if(!cdIdList.isEmpty()) {
            updateCategoryKBMaxImageAsync(cdIdList);
        }
        System.debug('### FIN TR022_ContentVersion.updateCategoryKBMaxImage');   
    }

    /**
    * @description Fonction pour modifier la catégorie du document si image KBMAX
    * @param cdIdList Id des documents
    */
    public static void updateCategoryKBMaxImageAsync(List<String> cdIdList) {
        System.debug('### DEBUT TR022_ContentVersion.updateCategoryKBMaxImageAsync');        
        List<ContentVersion> ctVersionToUp = new List<ContentVersion>();
        List<String> contDocToCheck = new List<String>();

        // Récupération des liens pour vérifier si sur QLI
        if(!cdIdList.isEmpty()) {
            for(ContentDocumentLink cdLink : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIdList]) {
                // Vérification si lié a QLI
                if( cdLink.LinkedEntityId.getSobjectType() == Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c')){
                    System.debug('## Lien QLI: '+cdLink.LinkedEntityId);
                    contDocToCheck.add(cdLink.ContentDocumentId);
                }
            }
        }

        // Récupération ContentVersion
        if(!contDocToCheck.isEmpty()) {
            for(ContentVersion ctVersion : [SELECT Id, category__c, FileType FROM ContentVersion WHERE ContentDocumentId IN :contDocToCheck]) {
                // Vérification si image
                if(ctVersion.FileType.toLowerCase()=='jpg' || ctVersion.FileType.toLowerCase()=='png') {
                    System.debug('## Ajout catégorie KBMax: '+ctVersion.Id);
                    // Ajoute la catégorie KBMax
                    ContentVersion doc = new ContentVersion(Id = ctVersion.Id, category__c = 'KBMax');
                    ctVersionToUp.add(doc);
                }
            }
        }

        // Modification des lignes
        System.debug('## Doc to update: '+ctVersionToUp);
        if(!ctVersionToUp.isEmpty()) {
            update ctVersionToUp;
        }
        System.debug('### FIN TR022_ContentVersion.updateCategoryKBMaxImageAsync');   
    }
    
    /**
    * @description Fonction pour créer l'objet pour le lien public
    * @param contentVersionId Id de l'objet ContentVersion
    */
    private static ContentDistribution createContentDistribution(ContentVersion contentVersion){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersion.Id;
        newDist.Name = contentVersion.Title;
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        newDist.PreferencesLinkLatestVersion=true;
        System.debug('## newDist: '+newDist);
        return newDist;
    }

    /**
    * @description Fonction pour modifier le flag KBMAX aux lignes de devis CPQ
    * @param cdLinkQLI List des lines avec les QLI
    */
    private static void updateQLIKBMaxFlag(List<ContentDocumentLink> cdLinkQLI) {
        System.debug('### DEBUT TR022_ContentVersion.updateQLIKBMaxFlag');        
        List<SBQQ__QuoteLine__c> qliToUpdate = new List<SBQQ__QuoteLine__c>();

        // Récupération des liens pour vérifier si sur QLI
        for(ContentDocumentLink cdLink : cdLinkQLI) {
            System.debug('## Modification QLI: '+cdLink.LinkedEntityId);
            // Création de l'objet QLI
            SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(Id = cdLink.LinkedEntityId, kbmaxAPISent__c = false);
            qliToUpdate.add(qli);
        }

        // Insert des lignes
        System.debug('## QLI to update: '+qliToUpdate);
        if(!qliToUpdate.isEmpty()) {
            update qliToUpdate;
        }
        System.debug('### FIN TR022_ContentVersion.updateQLIKBMaxFlag');   
    }

    /**
    * @description Fonction pour envoyer une notification lors de l'ajout/suppression d'une piece jointe sur une NCP Fournisseur
    * @param cdLinkQLI List des lines avec les Cases
    */
    public static void casePNCProviderNotification(List<ContentDocumentLink> cdLinkCase) {
        System.debug('### DEBUT TR022_ContentVersion.emailForCaseAttachmentNotification');
        Set<id> caseIdList = new Set<id>();
        String caseKeyPrefix = Schema.getGlobalDescribe().get('Case').getDescribe().getKeyPrefix();
        System.debug('## Case Key Prefix: '+caseKeyPrefix);
        String casePNCRTId = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);

        // Récupération de la liste d'id des PNC
        for(ContentDocumentLink nl : cdLinkCase){
            System.debug('## Id: '+nl.Id);
            if((String.valueOf(nl.LinkedEntityid)).startsWith(caseKeyPrefix)){
                caseIdList.add(nl.LinkedEntityid);
            }
        }

        if(!caseIdList.isEmpty()) {
            // Récupération des PNC Provider
            List<Case> caseProviderPNC  = [SELECT Id, AccountId, stageName__c, entity__c, Status, ProductId, providerOrderItem__c, responsability__c, 
                                                    RecordTypeId, RecordType.Name, RecordType.DeveloperName, supplierEmail__c, entity__r.Name, Product.ProductCode
                                                FROM Case 
                                                WHERE Id IN :caseIdList AND RecordTypeId = :casePNCRTId];

            if(!caseProviderPNC.isEmpty()) {
                // Création du Template
                EmailTemplate template = DAL.getEmailTemplateByName('NCP_Notification_modif_NCP_et_element');        
                OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'relationclients@kpark.fr'];

                for(Case newCase : caseProviderPNC){
                    // Destinataires
                    List<String> destinataires = new List<String>();
                    destinataires.add(newCase.supplierEmail__c);

                    // Création de l'email
                    List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(template.Id, null, newCase.Id);
                    mail.setOrgWideEmailAddressId(fromAddress.Id);
                    mail.setToAddresses(destinataires);
                    emailsToSent.add(mail);
                    System.debug('## Email: '+mail);

                    // Pas d'envoi d'email si Test
                    if(!Test.isRunningTest()) {
                        List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent);
                        System.debug('## Email result: ' + result);
                    }
                }
            }
        }
        System.debug('### FIN TR022_ContentVersion.emailForCaseAttachmentNotification');
    }
}