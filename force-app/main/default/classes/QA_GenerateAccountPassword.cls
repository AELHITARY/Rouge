//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_GenerateAccountPassword
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 04/10/2017
//-- Version     : 1.8
//-- * 1.7 - CRM-942 : Evolution pour mot de passe
//-- * 1.8 - Correction pour envoi d'email lors d'une erreur + Ajout de reprise de génération
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_GenerateAccountPassword implements Queueable {
    public List<Account> accounts;
    private String MAJ = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    private String MIN = 'abcdefghijklmnopqrstuvwxyz';
    private String NUM = '1234567890';
    private String SPE = '!@#$%^&*_=+-/';
    private OrgWideEmailAddress orgWideEmailAddress = null;
    private Boolean isEmail;
    private Boolean isClient;
    private Boolean isBatch;

    /**
    * @description Constructeur
    * @param accountsList Liste des comptes dont le mot de passe doit être généré
    * @param isEmailable Vrai si l'email doit être envoyé
    * @param isNewCustomer Vrai si c'est un nouveau compte dans Salesforce (pas client)
    * @param isBatchValue Vrai si ecécution par le batch de reprise de génération de mot de passe
    * @return QA_GenerateAccountPassword Classe QA_GenerateAccountPassword
    */
    public QA_GenerateAccountPassword(List<Account> accountsList, Boolean isEmailable, Boolean isNewCustomer, Boolean isBatchValue){
        accounts = accountsList;
        isEmail = isEmailable;
        isClient = isNewCustomer; 
        isBatch = isBatchValue; // true si batch de reprise de génération
    }

    /**
    * @description Fonction principal d'exécution du batch Queueable
    * @param context Context du batch
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_GenerateAccountPassword');
        Map<String,Account> mapAccount = new Map<String,Account>();
        List<Account> accountsUpdate = new List<Account>();
        List<Account> errorList = new List<Account>();
        Set<String> errorSet = new Set<String>();
        String errorMsg = '';
        List<EmailMessageWrapper> listEmailMessageWrapper = new List<EmailMessageWrapper>();
        Map<String,EmailMessageWrapper> mapAccountEmail = new Map<String,EmailMessageWrapper>();
        // Règles de gestion des mot de passe
        Integer nbChiffre=PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.nbChiffres',1);
        Integer nbMajuscule=PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.nbMaj',1);
        Integer longueurMin=PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.longueurMin',1);
        Decimal REPRISEMAX = PropertiesUtils.getIntegerValue('espaceclient.mdp.nbTentatives', 3);

        try {
            // Récupération du modèle d'email et de l'adresse expéditeur
            String emailTemplateName = '';
            if(isClient)
                emailTemplateName ='Site_EspaceClient_CreatePassword';
            else
                emailTemplateName ='Site_EspaceClient_GeneratePassword';
            EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = :emailTemplateName];
            orgWideEmailAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'relationclients@kpark.fr' LIMIT 1]; 

            // Boucle sur les compte
            mapAccount = new Map<String,Account>([SELECT Id, email__c, dateMotDePasseClient__c, motDePasseClient__c, aGenererMDP__c, erreurGenerationMDP__c,
                                    civilite__c, nom__c, prenom__c, AccountNumber FROM Account WHERE Id IN :accounts]);
            if(!mapAccount.isEmpty()) {
                for(Account acc : mapAccount.values()) {
                    System.debug('## Id : ' + acc.Id);
                    // Génération du mot de passe
                    String newPassword = '';
                    for (Integer i = 0; i < longueurMin; i++) {
                        Double index = Math.random() * 25;
                        newPassword += MIN.substring((Integer) index, (Integer) index +1);
                    }
                    for (Integer i = 0; i < nbChiffre; i++) {
                        Double index = Math.random() * 9;
                        newPassword += NUM.substring((Integer) index, (Integer) index +1);
                    }
                    for (Integer i = 0; i < 1; i++) {
                        Double index = Math.random() * 12;
                        newPassword += SPE.substring((Integer) index, (Integer) index +1);
                    }
                    for (Integer i = 0; i < nbMajuscule; i++) {
                        Double index = Math.random() * 25;
                        newPassword += MAJ.substring((Integer) index, (Integer) index +1);
                    }

                    Blob blobPassword = Blob.valueOf(newPassword);
                    acc.motDePasseClient__c = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-512', blobPassword)); 
                    accountsUpdate.add(acc);

                    // Si le compte possède pas d'email, mise à jour du champ de demande de mot de passe
                    if(acc.email__c == null)
                        acc.dateMotDePasseClient__c  = System.today();
                    // Sinon envoie de l'email
                    else {
                        acc.dateMotDePasseClient__c  = null;                    
                        if(isEmail){
                            // Génération email au client
                            acc.autorisationCourrierEspaceClient__c = true;
                            acc.dateCourrierEspaceClient__c = System.now();
                            Map<String, String> mapBodyParams = new Map<String, String> {
                                '{!Account.civilite__c}' => acc.civilite__c,
                                '{!Account.nom__c}' => acc.nom__c,
                                '{!Account.prenom__c}' => acc.prenom__c,
                                '{!Account.numeroCompte__c}' => acc.AccountNumber,
                                '{!Account.motDePasseClient__c}' => newPassword
                            };
                            // Ajout email dans liste des email à envoyer
                            mapAccountEmail.put(acc.Id,new EmailMessageWrapper(orgWideEmailAddress.Address,
                                                                                acc.email__c,
                                                                                acc.Id,
                                                                                null,
                                                                                emailTemplate.Subject,
                                                                                null,
                                                                                emailTemplate.Body,
                                                                                emailTemplate.HtmlValue,
                                                                                mapBodyParams));      
                            System.debug('## Destination : ' + acc.email__c);                  
                        }
                    }
                }
                // Mise à jour des comptes
                Database.SaveResult[] srList = Database.update(accountsUpdate, false);
                Boolean authLogs = PropertiesUtils.getBooleanValue('espaceclient.auth.logs', true);

                // Logs
                if(!mapAccount.isEmpty()) {
                    for(Account acc : mapAccount.values()) {
                        if(authLogs && acc.motDePasseClient__c != null){
                            Utils_Logger.insertNewConnexionClient(acc.AccountNumber, 'Génération MDP', 'OK', '', acc.motDePasseClient__c);
                        } else if(authLogs){
                            Utils_Logger.insertNewConnexionClient(acc.AccountNumber, 'Génération MDP', 'Erreur', '', acc.motDePasseClient__c);
                        }
                    }
                }

                for (Integer i = 0; i < mapAccount.size(); i++) {
                    Database.SaveResult sr = srList[i];
                    Account acc = mapAccount.values()[i];     
                    System.debug('## Result : ' + sr);        
                    System.debug('## Compte : ' + acc);                        
                    if (sr.isSuccess()) {
                        // Ajout de l'email du compte dans la liste des emails à envoyer
                        if(mapAccountEmail.get(acc.Id) != null) {
                            listEmailMessageWrapper.add(mapAccountEmail.get(acc.Id));
                        }
                        // Suppression erreur génération
                        if(acc.aGenererMDP__c != null && acc.aGenererMDP__c != 0){
                            acc.aGenererMDP__c = null;
                            acc.erreurGenerationMDP__c = null;
                            if(errorSet.contains(acc.Id) == false) {
                                errorSet.add(acc.Id);
                                errorList.add(acc);
                            }
                        }
                    } else {
                        // Erreur à la modification, log
                        for(Database.Error err : sr.getErrors()) {
                            errorMsg = err.getStatusCode() + ' : ' + err.getMessage();
                            errorMsg += '\nChamps en erreur : ' + err.getFields();
                            /*
                            errorMsg = 'Impossible de modifier le compte ' + acc.Id;
                            errorMsg += '\nErreur : '+err.getStatusCode() + ' : ' + err.getMessage();
                            errorMsg += '\nChamps en erreur : ' + err.getFields();
                            errorMsg += '\n--------------------------------------------------------------------------------';
                            */
                        }
                        // Mise à jour champ erreur du compte
                        if(acc.aGenererMDP__c == null && !isBatch) {
                            acc.aGenererMDP__c = REPRISEMAX;
                        } else if(acc.aGenererMDP__c != 0 && isBatch) {
                            acc.aGenererMDP__c = (acc.aGenererMDP__c==null) ? REPRISEMAX-1 : acc.aGenererMDP__c - 1;
                        }
                        acc.erreurGenerationMDP__c = errorMsg;
                        if(errorSet.contains(acc.Id) == false) {
                            errorSet.add(acc.Id);
                            errorList.add(acc);
                        }
                        System.debug('## Error : ' + errorMsg );
                    }
                }

                // Mise à jour des comptes (erreur)
                if(!errorList.isEmpty()) {
                    update errorList; 
                }
                // Envoi des email aux clients
                if(!listEmailMessageWrapper.isEmpty()) {
                  System.debug('## Envoie : ' + orgWideEmailAddress.Address);
                  doSendEmail(listEmailMessageWrapper);
                }
                /*
                // Envoi email d'erreur aux administrateurs
                if(String.isNotBlank(errorMsg))
                    EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de l\'enregistrement du mot de passe client', errorMsg);
                */
            }
            System.debug('### FIN QA_GenerateAccountPassword');
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de la génération du mot de passe client', e);
        }
    }

    /**
    * @description Construction et envoi de l'email avec mot de passe
    * @param listEmailMessageWrapper Liste des informations pour générer les emails
    */
    private void doSendEmail(List<EmailMessageWrapper> listEmailMessageWrapper) {
        try {
            List<Messaging.SingleEmailmessage> listSingleEmailMessages = new List<Messaging.SingleEmailmessage>();

            for (EmailMessageWrapper emailMessageWrapper : listEmailMessageWrapper) {
                // Création du mail
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                // Expéditeur
                mail.setOrgWideEmailAddressId(orgWideEmailAddress.Id);
                // Destinataire
                if(emailMessageWrapper.ToAddress != null && emailMessageWrapper.ToAddress.length() > 0)
                    mail.setToAddresses(new String[] { emailMessageWrapper.ToAddress });
                else
                    mail.setTargetObjectId(emailMessageWrapper.ToAddressId);
                // BCC
                if(String.isNotBlank(emailMessageWrapper.BccAddress))
                    mail.setBccAddresses(new String[] {emailMessageWrapper.BccAddress });
                // Sujet
                String subject = '';
                if(String.isNotBlank(emailMessageWrapper.Subject)) {
                    subject = emailMessageWrapper.Subject;
                }
                mail.setSubject(subject);
                // BODY
                String htmlBody = emailMessageWrapper.HtmlValue;
                String plainBody = emailMessageWrapper.Body;
                for (String key : emailMessageWrapper.ParameterBodyMap.keySet()) {
                    htmlBody = htmlBody.replace(key, (emailMessageWrapper.ParameterBodyMap.get(key) == null) ? '' : emailMessageWrapper.ParameterBodyMap.get(key));
                    htmlBody = htmlBody.replace(']]>', '');
                    htmlBody = htmlBody.replace('<![CDATA[', '');
                    plainBody = plainBody.replace(key, (emailMessageWrapper.ParameterBodyMap.get(key) == null) ? '' : emailMessageWrapper.ParameterBodyMap.get(key));
                }
                mail.setHtmlBody(htmlBody);
                mail.setPlainTextBody(plainBody);
                mail.setSaveAsActivity(false);
                listSingleEmailMessages.add(mail);
            }
            // Send all emails in the master list
            if(!Test.isRunningTest()) {
                List<Messaging.SendEmailResult>  result = Messaging.sendEmail(listSingleEmailMessages);
                System.debug('## Email result : ' + result);
            }
        } catch (Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Maintenance support : Erreur lors de l\'envoi du mot de passe client', e);
        }
    }
}