//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_InvoiceSendToCustomer
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/02/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_InvoiceSendToCustomer {
    public static final String TEMPLATE_NAME = PropertiesUtils.getStringValue('invoice.emailtemplate.name', 'Facture_Email_de_la_facture_au_client');

    /**
    * @description Fonction pour envoyer le dernier dodcument PDF au client
    * @param recordId Id de la facture
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String sendInvoiceToCustomer(Id recordId, String docType) {
        System.debug('### DEBUT LWC_InvoiceSendToCustomer.sendInvoiceToCustomer');
        System.debug('## recordId : '+recordId);
        System.debug('## docType : '+docType);
        ContentVersion doc;
        String documentTitle;
        List<String> cdocIdList = new List<String>();

        try {
            // Get type of object (AccountingPiece__c or Invoice__c), if AccountingPiece__c then get the invoice linked to this piece
            if(recordId.getSObjectType().getDescribe().getName() == 'AccountingPiece__c') {
                Invoice__c invAcc = [SELECT Id FROM Invoice__c WHERE advancePayment__c = :recordId LIMIT 1];
                recordId = invAcc.Id;
            }

            // Get invoice information
            Invoice__c inv = [SELECT Id, billingAccount__c, billingAccount__r.IsPersonAccount, billingAccount__r.PersonContactId, publishedDate__c,
                            billingAccount__r.contactParDefaut__c, billingAccount__r.contactParDefaut__r.Salutation, billingAccount__r.contactParDefaut__r.LastName,
                            billingAccount__r.contactParDefaut__r.FirstName, billingAccount__r.Salutation, billingAccount__r.LastName, billingAccount__r.FirstName, 
                            invoiceDate__c, Name 
                            FROM Invoice__c WHERE Id = :recordId];
            
            // Search existing document
            for(ContentDocumentLink cdLink :  [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                cdocIdList.add(cdLink.ContentDocumentId);
            }
            
            // If no document, generate PDF
            if(cdocIdList.isEmpty()) {
                DateTime invoiceDate = (inv.invoiceDate__c == null) ? Date.today() : inv.invoiceDate__c;
                String invoiceDateStr = invoiceDate.format('yyyy/MM/dd');
                if(docType == 'Facture') {
                    documentTitle = 'Facture ' + inv.Name + ' ' + invoiceDateStr;
                } else if(docType == 'Facture acquittée') {
                    documentTitle = 'Facture acquittée ' + inv.Name + ' ' + invoiceDateStr;
                } else {
                    documentTitle = 'Acompte ' + inv.Name + ' ' + invoiceDateStr;
                }
                String newDocId = LWC_InvoiceGeneratePDF.renderDocumentPDF(recordID, documentTitle, docType);
                cdocIdList.add(newDocId);

                if(inv.invoiceDate__c == null) {
                    inv.invoiceDate__c = Date.today();
                }
            }

            // Search existing document
            List<ContentVersion> docList = [SELECT Title, ContentDocumentId, VersionData 
                                            FROM ContentVersion 
                                            WHERE ContentDocumentId IN :cdocIdList AND category__c = :docType AND IsLatest = true];
            if(!docList.isEmpty()) {
                doc = docList[0];
                // Construct and send the email
                constructAndSendEmail(inv, doc);
    
                // Update the invoice if publishedDate is not set
                if(inv.publishedDate__c == null) {
                    inv.publishedDate__c = Date.today();
                    inv.publishedChannel__c = 'Par email';
                    update inv;
                }
            }
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_InvoiceSendToCustomer.sendInvoiceToCustomer');
        return 'OK';
    }

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF à l'email et l'envoyer au client
    * @param invoice Objet lié à la facture
    */
    public static void constructAndSendEmail(Invoice__c invoice, ContentVersion doc) {
        System.debug('### DEBUT LWC_InvoiceSendToCustomer.constructAndSendEmail');
        System.debug('## invoice : '+invoice);
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
            String targetObjectId = (invoice.billingAccount__r.IsPersonAccount) ? invoice.billingAccount__r.PersonContactId : invoice.billingAccount__r.contactParDefaut__c;
            
            // Genération du body
            Map<String, String> mapBodyParams = new Map<String, String> {
                '{!Account.civilite__c}' => (invoice.billingAccount__r.isPersonAccount) ? invoice.billingAccount__r.Salutation : invoice.billingAccount__r.contactParDefaut__r.Salutation,
                '{!Account.nom__c}' => (invoice.billingAccount__r.isPersonAccount) ? invoice.billingAccount__r.LastName : invoice.billingAccount__r.contactParDefaut__r.LastName,
                '{!Account.prenom__c}' => (invoice.billingAccount__r.isPersonAccount) ? invoice.billingAccount__r.FirstName : invoice.billingAccount__r.contactParDefaut__r.FirstName
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
            
            System.debug('### FIN LWC_InvoiceSendToCustomer.constructAndSendEmail');
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }

    /**
    * @description Fonction pour récupérer le détail d'une facture d'acompte depuis une piece comptable
    * @param accPieceId Id de la pièce comptable
    * @return Facture (Invoice__c)
    */
    @AuraEnabled(Cacheable = true)
    public static Invoice__c getAdvanceInvoice(String accPieceId){
        System.debug('### DEBUT LWC_InvoiceSendToCustomer.getAdvanceInvoice'); 
        Invoice__c result = null;

        // Récupération des infos de la facture
        if(String.isNotBlank(accPieceId)) {
            result = [SELECT Id, billingAccount__r.email__c FROM Invoice__c WHERE advancePayment__c = :accPieceId LIMIT 1];
        }  

        System.debug('## result: '+result); 
        System.debug('### FIN LWC_InvoiceSendToCustomer.getAdvanceInvoice'); 
        return result;
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