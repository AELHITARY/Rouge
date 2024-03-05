//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_SendCPQQuote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/09/2023
//-- Version     : 1.1
//-- * 1.1 - #1174 : Changement du type de document envoyé par mail pour les devis non SAV -> Devis à la place de DIP
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_SendCPQQuote {
    
    /**
    * @description Envoi l'email avec le devis en pièce jointe
    * @param recordId Id du devis
    */
    @AuraEnabled
    public static String sendPDF(Id recordId) {
        System.debug('### DEBUT LWC_SendCPQQuote.sendPDF');
        System.debug('## recordId : '+recordId);
        String errorMsg;
        String result;
        List<String> cdocIdList = new List<String>();
        Blob devisPDF = null;

        try{
            SBQQ__Quote__c  devis = [SELECT Id, SBQQ__Status__c , SBQQ__Account__r.PersonContactId, SBQQ__Account__r.isPersonAccount, Ndevis__c, SBQQ__ExpirationDate__c,
                                        SBQQ__Account__r.Salutation, SBQQ__Account__r.LastName, SBQQ__Account__r.FirstName, SBQQ__Account__r.email__c,
                                        SBQQ__Account__r.contactParDefaut__r.Salutation, SBQQ__Account__r.contactParDefaut__r.LastName , SBQQ__Account__r.contactParDefaut__r.FirstName,
                                        autreCompte__c, SBQQ__Type__c
                                        FROM SBQQ__Quote__c WHERE Id = :recordId];

            // Pas d'envoi si devis en cours de configuration
            if(devis.SBQQ__Status__c == Constants.StatutDevisAConfigurer) {
                errorMsg = System.Label.quote_error_toConfigure;
                throw generateAuraException(errorMsg);
            }
            // Pas d'envoi si pas d'email pour le compte
            if(devis.SBQQ__Account__r.email__c == null){
                errorMsg = Constants.msgErrorNoEmail;
                throw generateAuraException(errorMsg);
            }
            // Pas d'envoi si devis expiré
            if(devis.SBQQ__ExpirationDate__c < Date.today()) {
                errorMsg = System.Label.quote_error_emailDateExpiration;
                throw generateAuraException(errorMsg);
            }

            // Recherche document existant
            for(ContentDocumentLink cdLink :  [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                cdocIdList.add(cdLink.ContentDocumentId);
            }

            if(devis.SBQQ__Type__c == 'SAV'){
                devisPDF = generateDocument(devis, cdocIdList, 'Devis SAV');
            } else {
                devisPDF = generateDocument(devis, cdocIdList, 'Devis');
            }     

            // Création de la pièce jointe
            Messaging.EmailFileAttachment mailFile = new Messaging.EmailFileAttachment();
            mailFile.setBody(devisPDF);
            mailFile.setFileName(Constants.QUOTE_PDF_FILENAME + '.pdf');
            
            // Création du Template
            EmailTemplate template = DAL.getEmailTemplateByName(Constants.QUOTE_EMAIL_SENDPDF);         
            OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'devis@kpark.fr'];
            String emailSubject = template.Subject ;
            String targetObjectId = (devis.SBQQ__Account__r.IsPersonAccount) ? devis.SBQQ__Account__r.PersonContactId : devis.SBQQ__Account__r.contactParDefaut__c;
            
            // Genération du body
            Map<String, String> mapBodyParams = new Map<String, String> {
                '{!Account.civilite__c}' => (devis.SBQQ__Account__r.isPersonAccount) ? devis.SBQQ__Account__r.Salutation : devis.SBQQ__Account__r.contactParDefaut__r.Salutation,
                '{!Account.nom__c}' => (devis.SBQQ__Account__r.isPersonAccount) ? devis.SBQQ__Account__r.LastName : devis.SBQQ__Account__r.contactParDefaut__r.LastName,
                '{!Account.prenom__c}' => (devis.SBQQ__Account__r.isPersonAccount) ? devis.SBQQ__Account__r.FirstName : devis.SBQQ__Account__r.contactParDefaut__r.FirstName
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
            mail.setSaveAsActivity(false);
            mail.setSubject(emailSubject);
            mail.setTargetObjectId(targetObjectId);
            mail.setOrgWideEmailAddressId(fromAddress.Id);
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{mailFile});
            emailsToSent.add(mail);
            System.debug('## Email: '+mail);
            
            // Gestion si autre compte
            if(devis.autreCompte__c != null){
                Account autreCompte = new Account();
                autreCompte = [SELECT Id, email__c, PersonContactId, Salutation, FirstName, LastName, IsPersonAccount,
                                contactParDefaut__r.Salutation, contactParDefaut__r.FirstName, contactParDefaut__r.LastName
                               FROM Account WHERE Id = :devis.autreCompte__c];
                
                // Création du Template
                String autreTargetObjectId = (autreCompte.IsPersonAccount) ? autreCompte.PersonContactId : autreCompte.contactParDefaut__c;
                // Genération du body
                Map<String, String> mapBodyParamsAutreCpt = new Map<String, String> {
                    '{!Account.civilite__c}' => (autreCompte.isPersonAccount) ? autreCompte.Salutation : autreCompte.contactParDefaut__r.Salutation,
                    '{!Account.nom__c}' => (autreCompte.isPersonAccount) ? autreCompte.LastName : autreCompte.contactParDefaut__r.LastName,
                    '{!Account.prenom__c}' => (autreCompte.isPersonAccount) ? autreCompte.FirstName : autreCompte.contactParDefaut__r.FirstName
                };
                String htmlBodyAutreCpt = template.HtmlValue;
                String plainBodyAutreCpt = template.Body;
                for (String key : mapBodyParamsAutreCpt.keySet()) {
                    htmlBodyAutreCpt = htmlBodyAutreCpt.replace(key, (mapBodyParamsAutreCpt.get(key) == null) ? '' : mapBodyParamsAutreCpt.get(key));
                    htmlBodyAutreCpt = htmlBodyAutreCpt.replace(']]>', '');
                    htmlBodyAutreCpt = htmlBodyAutreCpt.replace('<![CDATA[', '');
                    plainBodyAutreCpt = plainBodyAutreCpt.replace(key, (mapBodyParamsAutreCpt.get(key) == null) ? '' : mapBodyParamsAutreCpt.get(key));
                }
                
                // Création de l'email
                Messaging.SingleEmailMessage mailAutreCpt = new Messaging.SingleEmailMessage();
                mailAutreCpt.setHtmlBody(htmlBodyAutreCpt);
                mailAutreCpt.setPlainTextBody(plainBodyAutreCpt);
                mailAutreCpt.setUseSignature(false);
                mailAutreCpt.setSaveAsActivity(false);
                mailAutreCpt.setSubject(emailSubject);
                mailAutreCpt.setTargetObjectId(autreTargetObjectId);
                mailAutreCpt.setOrgWideEmailAddressId(fromAddress.Id);
                mailAutreCpt.setFileAttachments(new List<Messaging.EmailFileAttachment>{mailFile});
                emailsToSent.add(mailAutreCpt);
                System.debug('## mailAutreCpt: '+mailAutreCpt);
            }
            
            // Pas d'envoie d'email si Test
            if(!Test.isRunningTest()) {
                List<Messaging.SendEmailResult> emailResult = Messaging.sendEmail(emailsToSent);
                System.debug('## Email result: ' + emailResult);
            }   

            // MAJ Devis
            devis.Datetransmissionclient__c = Date.today();
            devis.Moyentransmissionclient__c = Constants.devisTransmisMail;
            update devis;                    
            result = 'OK';

            System.debug('### FIN LWC_SendCPQQuote.sendPDF');
        }catch(Exception e){
            System.debug('## ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        return result;
    }

    public static Blob generateDocument(SBQQ__Quote__c devis, List<String> cdocIdList, String category){
        Blob devisPDF = null;
        Boolean docExist = false;
        if(!cdocIdList.isEmpty()) {
            List<ContentVersion> docList = [SELECT Title, ContentDocumentId, VersionData FROM ContentVersion 
                                                WHERE category__c = :category AND ContentDocumentId IN :cdocIdList AND IsLatest = true];
            if(!docList.isEmpty()) {
                System.debug('## Document existant: '+docList[0]);
                devisPDF = docList[0].VersionData;
                docExist = true;
            }
        }
            
        // Création et enregistrement du PDF (Devis/SAV) si pas de document
        if(!docExist) {
            System.debug('## Création du PDF :'+category);
            String dateOfDayFormat = Datetime.now().format('dd/MM/YYYY');
            String file = createContentDocument(devis.Id, category+' '+devis.NDevis__c+' - '+dateOfDayFormat, devis.SBQQ__Type__c);
            System.debug('## File: '+file);
            if(String.isBlank(file)) {
                throw generateAuraException('Erreur lors de la génération du PDF');
            }

            // Récupération Devis PDF
            List<ContentVersion> cdVersionList = [SELECT Id, VersionData FROM ContentVersion 
                                                    WHERE category__c = :category AND ContentDocumentId = :file AND IsLatest = true];
            if(!cdVersionList.isEmpty()) {
                devisPDF = cdVersionList[0].VersionData;
            } else {
                throw generateAuraException('Pas de document PDF lié au devis');
            }
        }
        return devisPDF;
    }
    
    /**
    * @description Fonctions de création du ContentDocument/ContentDocumentLink
    * @param quoteId Id du devis
    * @param fileName Nom du fichier
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String createContentDocument(String quoteId, String fileName, String type){
        System.debug('### typeDocSend : '+type);
        // Call Merkure to generate PDF
        String docId = '';
        if(type == 'SAV'){
            docId = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(quoteId, fileName, 'Devis SAV');
            // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
            Utils_APIMerkure.deleteCtDocumentByCategory(quoteId, docId, 'Devis SAV');
        } else {
            docId = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(quoteId, fileName, 'Devis');
            // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
            Utils_APIMerkure.deleteCtDocumentByCategory(quoteId, docId, 'Devis');
        }
        return docId;
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