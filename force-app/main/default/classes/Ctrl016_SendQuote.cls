//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl016_SendQuote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 12/03/2019
//-- Version     : 1.3
//-- * 1.3 : Correction pour devis expiré
//-- * 1.2 : Correction pour compte PRO
//-- --------------------------------------------------------------------------------- --
public with sharing class Ctrl016_SendQuote {
    public String msgSuccess {get; private set;}
    public Quote devis {get; private set;}

    /**
    * @description Constructeur
    * @return Ctrl016_SendQuote 
    */
    public Ctrl016_SendQuote() {
        String quoteId = Apexpages.currentPage().getParameters().get('qId');
        devis = [SELECT Id, Status, compte__r.PersonContactId, compte__r.isPersonAccount, devisTMC__c, QuoteNumber, ExpirationDate,
                    compte__r.Salutation, compte__r.LastName, compte__r.FirstName, compte__r.email__c, delaiInstallationMin__c , delaiInstallationMax__c ,
                    compte__r.contactParDefaut__r.Salutation, compte__r.contactParDefaut__r.LastName , compte__r.contactParDefaut__r.FirstName,
                    autreCompte__c
                    FROM Quote WHERE Id = :quoteId];
    }

    /**
    * @description Fonction de création du devis en PDF
    * @return blob Devis PDF
    */
    private blob getBlobPDF(){
        blob b;
        Pagereference p = Page.VF_DevisContrat_PDF;
        p.getParameters().put('qId',devis.Id);
        p.getParameters().put('doc','sansnum');
        if(Test.isRunningTest())
           b =  Blob.valueof('test');
        else
           b = p.getContentAsPDF();
        return b;
    }

    /**
    * @description Envoi l'email avec le devis en pièce jointe
    * @return PageReference Page Visualforce
    */
    public PageReference sendEmail(){
        system.debug('### DEBUT sendEmail');
        try{
            // Pas d'envoi si devis TMC
            if (devis.devisTMC__c){
                msgSuccess = Label.quote_error_emaildevisTMC;
                return null;
            }
            // Pas d'envoi si devis en cours de configuration
            if(devis.Status == Constants.StatutDevisAConfigurer) {
                msgSuccess = Label.quote_error_toConfigure;
                return null;
            }
            // Pas d'envoi si pas d'email pour le compte
            if(devis.compte__r.email__c == null){
                msgSuccess = Constants.msgErrorNoEmail;
                return null;
            }
            // Pas d'envoi si devis expiré
            if(devis.ExpirationDate < Date.today()) {
                msgSuccess = Label.quote_error_emailDateExpiration;
                return null;
            }
            // Pas d'envoi si date d'installation min et max non renseignées
            if(devis.delaiInstallationMin__c == null || devis.delaiInstallationMax__c == null) {
                msgSuccess = 'Les dates d\'installation minimum et maximum doivent être renseignées';
                return null;
            }
            
            // Génération Devis PDF
            Blob devisPDF = getBlobPDF();
            // Création de la pièce jointe
            Messaging.EmailFileAttachment mailFile = new Messaging.EmailFileAttachment();
            mailFile.setBody(devisPDF);
            mailFile.setFileName(Constants.QUOTE_PDF_FILENAME + '.pdf');

            // Création du Template
            EmailTemplate template = DAL.getEmailTemplateByName(Constants.QUOTE_EMAIL_SENDPDF);         
            OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'devis@kpark.fr'];
            String emailSubject = template.Subject ;
            String targetObjectId = (devis.compte__r.IsPersonAccount) ? devis.compte__r.PersonContactId : devis.compte__r.contactParDefaut__c;

            // Genération du body
            Map<String, String> mapBodyParams = new Map<String, String> {
                '{!Account.civilite__c}' => (devis.compte__r.isPersonAccount) ? devis.compte__r.Salutation : devis.compte__r.contactParDefaut__r.Salutation,
                '{!Account.nom__c}' => (devis.compte__r.isPersonAccount) ? devis.compte__r.LastName : devis.compte__r.contactParDefaut__r.LastName,
                '{!Account.prenom__c}' => (devis.compte__r.isPersonAccount) ? devis.compte__r.FirstName : devis.compte__r.contactParDefaut__r.FirstName
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
            system.debug('## Email : '+mail);

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
                system.debug('## mailAutreCpt : '+mailAutreCpt);
            }

            // Pas d'envoie d'email si Test
            if(!Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent);
                system.debug('## Email result : ' + result);
            }
            msgSuccess = Constants.msgSuccessDevis;
            devis.Status = Constants.StatutDevisTransmis;
            devis.Datetransmissionclient__c = Date.today();
            devis.Moyentransmissionclient__c = Constants.devisTransmisMail;
            update devis;
            system.debug('### FIN sendEmail');
            return null;
        }catch(Exception e){
            system.debug('## ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            if(String.isBlank(msgSuccess))
                msgSuccess = Constants.msgErrorDevis;
            msgSuccess += '\n' + e;
            EmailUtils.reportException('[KUBE] Devis - Erreur lors de l\'envoi du devis '+devis.QuoteNumber+' par email', e);
            return null;
        }
    }
}