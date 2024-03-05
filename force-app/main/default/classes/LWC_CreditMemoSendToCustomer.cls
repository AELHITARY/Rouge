//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CreditMemoSendToCustomer
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/02/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CreditMemoSendToCustomer {
    public static final String TEMPLATE_NAME = PropertiesUtils.getStringValue('creditMemo.emailtemplate.name', 'Avoir_E_mail_de_l_avoir_au_client');

    /**
    * @description Fonction pour envoyer le dernier dodcument PDF au client
    * @param recordId Id de la facture
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String sendCreditMemoToCustomer(Id recordId) {
        System.debug('### DEBUT LWC_CreditMemoSendToCustomer.sendCreditMemoToCustomer');
        System.debug('## recordId : '+recordId);

        try {
            // Get creditMemo information
            CreditMemo__c credMemo = [SELECT Id, billingAccount__c, billingAccount__r.IsPersonAccount, billingAccount__r.PersonContactId, publishedDate__c,
                                        billingAccount__r.contactParDefaut__c, billingAccount__r.contactParDefaut__r.Salutation, billingAccount__r.contactParDefaut__r.LastName,
                                        billingAccount__r.contactParDefaut__r.FirstName, billingAccount__r.Salutation, billingAccount__r.LastName, billingAccount__r.FirstName 
                                        FROM CreditMemo__c WHERE Id = :recordId];

            // Get last document
            ContentDocumentLink cdLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId ORDER BY ContentDocument.CreatedDate DESC];
            ContentVersion doc = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :cdLink.ContentDocumentId AND IsLatest = true];

            // Construct and send the email
            constructAndSendEmail(credMemo, doc);

            // Update the creditMemo if publishedDate is not set
            if(credMemo.publishedDate__c == null) {
                credMemo.publishedDate__c = Date.today();
                credMemo.publishedChannel__c = 'Par email';
                update credMemo;
            }
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_CreditMemoSendToCustomer.sendCreditMemoToCustomer');
        return 'OK';
    }

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF à l'email et l'envoyer au client
    * @param creditMemo Objet lié à la facture
    */
    public static void constructAndSendEmail(CreditMemo__c creditMemo, ContentVersion doc) {
        System.debug('### DEBUT LWC_CreditMemoSendToCustomer.constructAndSendEmail');
        System.debug('## creditMemo : '+creditMemo);
        System.debug('## doc : '+doc);

        try {
            // Création de la pièce jointe
            Messaging.EmailFileAttachment mailFile = new Messaging.EmailFileAttachment();
            mailFile.setBody(doc.VersionData);
            mailFile.setFileName(doc.Title);
            
            // Création du Template
            EmailTemplate template = DAL.getEmailTemplateByName(TEMPLATE_NAME);         
            OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Relation Clients' LIMIT 1];
            String emailSubject = template.Subject ;
            String targetObjectId = (creditMemo.billingAccount__r.IsPersonAccount) ? creditMemo.billingAccount__r.PersonContactId : creditMemo.billingAccount__r.contactParDefaut__c;
            
            // Genération du body
            Map<String, String> mapBodyParams = new Map<String, String> {
                '{!Account.civilite__c}' => (creditMemo.billingAccount__r.isPersonAccount) ? creditMemo.billingAccount__r.Salutation : creditMemo.billingAccount__r.contactParDefaut__r.Salutation,
                '{!Account.nom__c}' => (creditMemo.billingAccount__r.isPersonAccount) ? creditMemo.billingAccount__r.LastName : creditMemo.billingAccount__r.contactParDefaut__r.LastName,
                '{!Account.prenom__c}' => (creditMemo.billingAccount__r.isPersonAccount) ? creditMemo.billingAccount__r.FirstName : creditMemo.billingAccount__r.contactParDefaut__r.FirstName
            };
            String htmlBody = template.HtmlValue;
            String plainBody = template.Body;
            for (String key : mapBodyParams.keySet()) {
                htmlBody = htmlBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
                htmlBody = htmlBody.replace(']]>', '');
                htmlBody = htmlBody.replace('<![CDATA[', '');
                plainBody = plainBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
            }
            
            // Création de l'email
            List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setHtmlBody(htmlBody);
            mail.setPlainTextBody(plainBody);
            mail.setUseSignature(false);
            mail.setSaveAsActivity(true);
            mail.setSubject(emailSubject);
            mail.setTargetObjectId(targetObjectId);
            mail.setOrgWideEmailAddressId(fromAddress.Id);
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{mailFile});
            emailsToSent.add(mail);
            System.debug('## Email toaddresses : '+mail.getToAddresses());
            System.debug('## Email subject : '+mail.getSubject());
            
            // Pas d'envoie d'email si Test
            if(!Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent);
                System.debug('## Email result : ' + result);
            }
            
            System.debug('### FIN LWC_CreditMemoSendToCustomer.constructAndSendEmail');
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }
    
    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}