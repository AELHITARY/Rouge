//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_FeuillederoutePDF
//-- Modifié par : SOPRA - William DE GAËTANO
//-- Modifié le  : 27/05/2016
//-- Version     : 1.2
//-- * Ajout propriété globale pour copie caché
//-- --------------------------------------------------------------------------------- --
global class BA_FeuillederoutePDF implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global EmailTemplate emailTemplateRV = null;
    global EmailTemplate emailTemplateVendeur = null;
    global OrgWideEmailAddress fromAddress = null;

    /**
    *
    *   Méthode de début du batch. Récupération des utilisateurs pour l'envoi des PDF
    *
    **/
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('#### START BA_FeuillederoutePDF.start()');
        try {
            // Sélection de l'email d'expédition
            fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'support@kpark.fr'];
            emailTemplateRV = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='FeuilleDeRoute_Resonsable'];
            emailTemplateVendeur = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='FeuilleDeRoute_Vendeur'];
            
            // Vérification si utilisateurs pilote 
            Set<String> userId = new Set<String>();
            Set<String> userRoleId = new Set<String>();
            List<User> userList = [SELECT Id, UserRoleId FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'K/K - RV - Mobile' OR Name = 'K/K - RVJ - Mobile')
                                        AND CodeMagasin__c != null AND IsActive = true];
            for(User userPDF : userList) userRoleId.add(userPDF.UserRoleId);
            List<Group> userGroupList = [SELECT Id, Type, DeveloperName, RelatedId FROM Group WHERE RelatedId IN :userList OR RelatedId IN :userRoleId];
            List<GroupMember> membersPilote = [SELECT Id, UserOrGroupId FROM GroupMember WHERE GroupId IN (SELECT id FROM Group WHERE DeveloperName = 'Utilisateurs_pilote')];
            for(User userPDF : userList) {
                for(Group userGroup : userGroupList) {
                    if(userGroup.RelatedId == userPDF.Id || userGroup.RelatedId == userPDF.UserRoleId) {
                        for(GroupMember userGroupMember : membersPilote) {
                            if(userPDF.Id == userGroupMember.UserOrGroupId || userGroup.Id == userGroupMember.UserOrGroupId)
                                userId.add(userPDF.Id);
                        }
                    }
                }
            } 
            system.debug('Nombre utilisateurs : ' + userId.size());
            // Limite à 100 pour les tests pour éviter erreur de limites Salesforce
            if(Test.isRunningTest()) {
                return Database.getQueryLocator([SELECT Id, Name, CodeMagasin__c, FirstName, LastName, Email, Profile.Name FROM User WHERE Id IN :userId LIMIT 100]);
            } else {
                return Database.getQueryLocator([SELECT Id, Name, CodeMagasin__c, FirstName, LastName, Email, Profile.Name FROM User WHERE Id IN :userId]);
            }
        } catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Feuille de route PDF : Erreur d\'initialisation d\'envoi des feuilles de route PDF', e);
            throw e;
        }
    }

    /**
    *
    *   Méthode exécutant le process du batch
    *
    **/
    global void execute(Database.BatchableContext BC, List<User> scope){
        system.debug('#### START BA_FeuillederoutePDF.execute()');
        try {
            List<Messaging.SingleEmailMessage> emailsToSent = new List<Messaging.SingleEmailMessage>();
            Date dateToday = Date.today();          
            
            for (User vendeur : scope) {
                if(vendeur != null && vendeur.Email != null) {
                    Blob feuillederoutePDF = null;
                    
                    // Récupération des poses, métrages et intervention du secteurs pour la journée
                    List<User> vendeurForPDF = DAL_Cartographie.getVendeursList(null, vendeur.Id);
                    Integer nbContrats = DAL_Feuillederoute.getContratsRDVSizeUsers(vendeurForPDF, vendeur.codeMagasin__c, dateToday);
                    system.debug('Taille totale : ' + nbContrats);
    
                    // Envoi du PDF si des données existent
                    if(nbContrats > 0) {
                        // Selection du modèle d'email
                        EmailTemplate emailTemplate = (vendeur.Profile.Name.startsWith('K/K - RV')) ? emailTemplateRV : emailTemplateVendeur;
    
                        // Génération du PDF de l'utilisateur
                        PageReference feuillederoutePage = Page.VF_Feuilldederoute_PDF;
                        feuillederoutePage.getParameters().put('userId', vendeur.Id);
                        // Pas de transformation PDF si Test
                        if(!Test.isRunningTest()) {
                            feuillederoutePDF = feuillederoutePage.getContentAsPDF();
                        }
    
                        String dateOfDayString = Date.today().format();
                        String dateOfDayFormat = Datetime.now().format('ddMMYYYY');
                        String emailSubject = 'Votre feuille de route du ' + dateOfDayString;
                        String attachmentFileName = vendeur.FirstName + '_' + vendeur.LastName + '_' + dateOfDayFormat + '_feuille_de_route.pdf';
                        system.debug('Email sujet : ' + emailSubject);
                        system.debug('Pièce jointe : ' + attachmentFileName);
    
                        // Piece jointe
                        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                        emailAttachment.setFileName(attachmentFileName);
                        emailAttachment.setBody(feuillederoutePDF);
                        // Construction de l'email et envoi
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setSubject(emailSubject);
                        email.setOrgWideEmailAddressId(fromAddress.Id);
                        email.setTargetObjectId(vendeur.Id);
                        email.setSaveAsActivity(false);
                        
                        // Definit les destinataires en copie caché
                        String bccAddressesString = PropertiesUtils.getStringValue('feuillederoute.pdf.bccAddresses', 'tma.development.team.kpark@soprasteria.com');
                        email.setBccAddresses(bccAddressesString.split(','));
                        
                        // Genération du body
                        Map<String, String> mapBodyParams = new Map<String, String> {
                            '{!User.Name}' => vendeur.Name,
                            '{!Date}' => dateOfDayString
                        };
                        String htmlBody = emailTemplate.HtmlValue;
                        String plainBody = emailTemplate.Body;
                        for (String key : mapBodyParams.keySet()) {
                            htmlBody = htmlBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
                            htmlBody = htmlBody.replace(']]>', '');
                            htmlBody = htmlBody.replace('<![CDATA[', '');
                            plainBody = plainBody.replace(key, (mapBodyParams.get(key) == null) ? '' : mapBodyParams.get(key));
                        }
                        email.setHtmlBody(htmlBody);
                        email.setPlainTextBody(plainBody);
                        email.setFileAttachments(new List<Messaging.EmailFileAttachment> { emailAttachment });
                        // Ajout de l'email dans la liste d'envoi
                        emailsToSent.add(email);
                    }
                }
            }   
            
            
            // Pas d'envoie d'email si Test
            if(!Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(emailsToSent);
                system.debug('result : ' + result);
            }       
        }
        catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Feuille de route PDF : Erreur lors de l\'envoi des feuilles de route PDF', e);
            throw e;
        }
        system.debug('#### END BA_FeuillederoutePDF.execute()');
    }

    /**
    *
    *   Méthode de fin du batch
    *
    **/
    global void finish(Database.BatchableContext BC){
        system.debug('#### START BA_FeuillederoutePDF.finish()');

        system.debug('#### END BA_FeuillederoutePDF.finish()');
    }
}