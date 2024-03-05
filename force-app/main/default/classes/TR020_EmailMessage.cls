//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_EmailMessage
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/11/2019
//-- Version     : 1.1
//-- * 1.1 : RQM-146 : Maj pour assignation a la queue et réouverture
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR020_EmailMessage {

    /**
    * @description Pour chaque email entrant, on définit la source et le type de la requête et on vérifie le compte
    * @param userContext Information de l'utilisateur courant
    */
    public static void processEmailToCase(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        system.debug('### DEBUT TR020_EmailMessage.processEmailToCase');
        List<EmailMessage> newEmails = (List<EmailMessage>)Trigger.new; 
        List<Case> caseToUpdate = new List<Case>();  
        Map<ID,EmailMessage> emailsList = new Map<ID,EmailMessage>();

        try {
            // Vérification si email entrant
            for(EmailMessage email : newEmails) {
                if(email.Incoming) {
                    emailsList.put(email.ParentId, email);
                }
            }

            if(!emailsList.isEmpty()) {
                Map<String,Account> emailToAccountMap = new Map<String,Account>();

                // Récupère la liste des requêtes des emails
                Map<ID,Case> casesList = new Map<ID, Case>([SELECT Id, AccountId, ContactId, Origin, SuppliedName, SuppliedEmail, Status FROM Case WHERE Id IN :emailsList.keySet()]);
                // Récupère l'Id de la file d'attente
                List<Group> groupList = [SELECT Id, DeveloperName, Type FROM Group WHERE Type = 'Queue' 
                                            AND DeveloperName = :PropertiesUtils.getStringValue('case.queue.name','Agents_Call_Center') LIMIT 1];

                // Pour tous les emails, processus
                for (EmailMessage email : emailsList.values()) {
                    String source = null;
                    Case newCase = casesList.get(email.ParentId);
                    system.debug('## Email Id: '+email.Id);
                    system.debug('## Case Id: '+newCase.Id);

                    if(Test.isRunningTest() || newCase.AccountId == null) {
                        system.debug('## Email From: '+email.FromAddress);
                        system.debug('## Email To: '+email.ToAddress);
                        system.debug('## Email Cc: '+email.CcAddress);
                        system.debug('## Email Bcc: '+email.BccAddress);
                        system.debug('## Email Subject: '+email.Subject);

                        // Mise à jour de la source et du type selon l'email entrant
                        if(email.ToAddress != null && email.ToAddress.containsIgnoreCase('kpark.fr')) 
                            source = email.ToAddress;
                        else if(email.CcAddress != null && email.CcAddress.containsIgnoreCase('kpark.fr')) 
                            source = email.CcAddress;
                        else if(email.BccAddress != null && email.BccAddress.containsIgnoreCase('kpark.fr')) 
                            source = email.BccAddress;
                        newCase.source__c = source;
                        if(checkRecipientEmail(email, 'client@kpark.fr')) {
                            newCase.Type = 'Inscription CNIL';
                        }

                        // Vérifie la présence d'un client ou le créé sinon
                        String accRecordTypeId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
                        if(String.isNotBlank(accRecordTypeId)) {
                            // Récupération compte existant
                            List<List<SObject>> searchList = [FIND :email.FromAddress IN EMAIL FIELDS RETURNING Account(Id, PersonContactId, IsPersonAccount, contactParDefaut__c)];
                            if (searchList!=null && searchList.size() > 0) {
                                List<Account> acc = ((List<Account>)searchList[0]);
                                if(!acc.isEmpty()) {
                                    // Lie la requête à un compte existant
                                    newCase.AccountId = acc[0].Id;
                                    if(acc[0].IsPersonAccount)
                                        newCase.ContactId = acc[0].PersonContactId;
                                    else 
                                        newCase.ContactId = acc[0].contactParDefaut__c;
                                } else {
                                    // Création d'un compte
                                    Account newAcc = createAccount(newCase, email, accRecordTypeId);
                                    newCase.AccountId = null;
                                    newCase.ContactId = null;
                                    emailToAccountMap.put(newCase.Id, newAcc);
                                }
                            } else {
                                // Création d'un compte
                                Account newAcc = createAccount(newCase, email, accRecordTypeId);
                                newCase.AccountId = null;
                                newCase.ContactId = null;
                                emailToAccountMap.put(newCase.Id, newAcc);
                            }
                        }
                    }
                    
                    // Assignation à la file d'attente
                    if(!groupList.isEmpty()) {
                        newCase.OwnerId = groupList[0].Id;
                    }
                    
                    // Dans le cas d'une requête fermée, on la réouvre pour analyser le mail
                    if(newCase.Id != null && newCase.Status == Constants.REQUETE_STATUS_CLOSED){
                        newCase.Status = Constants.REQUETE_STATUS_INPROGRESS;
                    }

                    caseToUpdate.add(newCase);
                }

                // Insert new account and assign account to case
                if (!emailToAccountMap.values().isEmpty()) {
                    system.debug('## Insertion nouveaux comptes');
                    List<Account> newAccounts = emailToAccountMap.values();
                    insert newAccounts;
                    for (Case caseObj : caseToUpdate) {
                        system.debug('## Vérification compte: '+caseObj.Id+' / '+caseObj.AccountId);
                        if(caseObj.AccountId == null) {
                            system.debug('## Assignation de compte pour: ' + caseObj.Id);
                            Account newAccount = emailToAccountMap.get(caseObj.Id);
                            caseObj.AccountId = newAccount.Id;
                            caseObj.ContactId = newAccount.PersonContactId;
                            system.debug('## Account Id: ' + newAccount.Id);
                        }
                    }
                }
            }

            // Mise à jour des requêtes
            if(!caseToUpdate.isEmpty()) {
                update caseToUpdate;
            }
            system.debug('### FIN TR020_EmailMessage.processEmailToCase');
        } catch(HandledException e) {
            system.debug('### ERROR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        } catch (EmailException e) {
            system.debug('### ERROR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        } catch(Exception e) {
            system.debug('### ERROR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[Salesforce] ERROR : Inbound Email error', e);
            //throw e;
        }
    }

    /**
    * @description Création d'un compte si l'adresse email est inexistante
    * @param newCase Requête de l'email
    * @param email Email reçu par le client
    * @param accRecordType Type d'enregistrement du compte
    */
    private static Account createAccount(Case newCase, EmailMessage email, String accRecordType) {
        system.debug('### DEBUT TR020_EmailMessage.createAccount');

        // Création d'un compte
        Account acc = new Account(PersonEmail = email.FromAddress,
                                    RecordTypeId = accRecordType);
        // Nom
        if (newCase.SuppliedName != null) {
            acc.LastName = newCase.SuppliedName;
        } else
            acc.LastName = 'Client inconnu';
        system.debug('## Account Name: ' + acc.LastName);
        system.debug('## Account: ' + acc);
        system.debug('### FIN TR020_EmailMessage.createAccount');
        
        return acc;
    }

    /**
    * @description Permet de vérifier si le destinataire correspond à la valeur
    * @param emailToCheck Objet Email
    * @param value Valeur à vérifier
    * @return Boolean Vrai si l'email est destiné à la valeur
    */
    private static Boolean checkRecipientEmail(EmailMessage emailToCheck, String value) {    
        return ((emailToCheck.ToAddress != null && emailToCheck.ToAddress.containsIgnoreCase(value))
                || (emailToCheck.CcAddress != null && emailToCheck.CcAddress.containsIgnoreCase(value))
                || (emailToCheck.BccAddress != null && emailToCheck.BccAddress.containsIgnoreCase(value)));
    }
    
    /**
    * @description Process to detect OOT (Out of Office) email and Auto-response and discard email
    * @param emailsList List of email
    */
    public static void EmailToCaseDiscardAutoResponse(UserContext userContext) {
        system.debug('### START TR020_EmailMessage : EmailToCaseDiscardAutoResponse');
        List<EmailMessage> newEmails = (List<EmailMessage>)Trigger.new; 
        Map<ID,EmailMessage> emailsList = new Map<ID,EmailMessage>();
        List<String> autoResponseTexts = new List<String>{'Automatic reply','Autosvar','Automatisk svar','Automatisch antwoord','Abwesenheitsnotiz', 
                                                            'Risposta Non al computer','Automatisch antwoord','Auto Response','Respuesta automática', 
                                                            'Fuori sede','Out of Office','Frånvaro','Réponse automatique','AUTOREPLY'};
        try {       
            // Vérification si email entrant
            for(EmailMessage email : newEmails) {
                if(email.Incoming) {
                    emailsList.put(email.ParentId, email);
                }
            }

            if(!emailsList.isEmpty()) {
                // For all emails in list, get the subjects and email
                for (EmailMessage email : emailsList.values()) {

                    // Auto Response Whitelist
                    //Simon temp comment
                    //String emailsWhitelist = GlobalPropertiesUtils.getStringValue('autoresponse.email.whitelist', '');  
                    //if(emailsWhitelist.containsIgnoreCase(email.FromAddress) == false) {
                        String header = email.Headers;             
                        // For each email, we check the header and discard if that an auto response email
                        /*if(header != null && (header.containsIgnoreCase('x-autorespond') || header.containsIgnoreCase('x-auto-response-suppress') || header.containsIgnoreCase('auto-submitted: auto-replied')
                            || header.containsIgnoreCase('precedence: auto_reply') || header.containsIgnoreCase('precedence: bulk') || header.containsIgnoreCase('precedence: junk'))) {
                            system.debug('## Auto response header: ' + header);
                            system.debug('## Email FROM: ' + email.FromAddress);
                            system.debug('## Email TO: ' + email.ToAddress);
                            system.debug('## Email Subject: ' + email.Subject);
                            system.debug('## Email Body: ' + email.TextBody);
                            email.addError('## ERROR : Auto Responses Email :\n '+email);
                        } else {
                            // Check text in email subject
                            for(String autoResponseText : autoResponseTexts) {
                                if(email.Subject != null && email.Subject.containsIgnoreCase(autoResponseText)) {               
                                    system.debug('## Auto response text: ' + autoResponseText);             
                                    system.debug('## Email FROM: ' + email.FromAddress);
                                    system.debug('## Email TO: ' + email.ToAddress);
                                    system.debug('## Email Subject: ' + email.Subject);
                                    system.debug('## Email Body: ' + email.TextBody);
                                    email.addError('## ERROR : Auto Response Email :\n '+email);
                                }
                            }
                        }*/
                    //}
                }
            }
            system.debug('### END TR020_EmailMessage : EmailToCaseDiscardAutoResponse');
        } catch (Exception e) {
            system.debug('ERROR # Detect Email Auto-Response (' + e + ') Line : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }

    /**
    * @description Process to detect if there is a spam from a custom, creating loads and loads of cases. Allow only 5.
    * @param emailsList List of email
    */
    public static void DetectMassCreationFromSpam (UserContext userContext) {
        system.debug('### START TR020_EmailMessage : DetectMassCreationFromSpam');
        List<String> emailFromList = new List<String>();
        List<String> subjectList = new List<String>();
        List<EmailMessage> newEmails = (List<EmailMessage>)Trigger.new; 
        Map<ID,EmailMessage> emailsList = new Map<ID,EmailMessage>();
           
        try {       
            // Vérification si email entrant
            for(EmailMessage email : newEmails) {
                if(email.Incoming) {
                    emailsList.put(email.ParentId, email);
                }
            }

            if(!emailsList.isEmpty()) {
                // Enable spam detection            
                Boolean spamEnabled = PropertiesUtils.getBooleanValue('spam.email.enabled', true);   
                if(spamEnabled) {
                    // Email Whitelist
                    String emailsWhitelist = PropertiesUtils.getStringValue('spam.email.whitelist', ''); 
                    String emailsBlacklist = PropertiesUtils.getStringValue('spam.email.blacklist', '');  
                    // For all emails in list, get the subjects and email
                    for (EmailMessage newEmail : emailsList.values()) {
                        if(String.isNotBlank(newEmail.FromAddress) && String.isNotBlank(newEmail.Subject)) {
                            if(emailsWhitelist != null && emailsWhitelist.containsIgnoreCase(newEmail.FromAddress) == false) {
                                emailFromList.add(newEmail.FromAddress);
                                string sSubjectSearch = newEmail.Subject;
                                if(sSubjectSearch.length()>20)
                                {
                                    sSubjectSearch = sSubjectSearch.substring(0,20) + '%';
                                }
                                subjectList.add(sSubjectSearch);
                            }
                        }
                    }
                    system.debug('## Email from Spam: '+emailFromList);
                    system.debug('## Subjects Spam: '+subjectList);
                
                    //Construct Map of potential spammed cases
                    Map<ID, Case> casesSpam = new Map<ID, Case>([SELECT Id,SuppliedEmail,Subject FROM Case 
                                                                    WHERE Origin='Email' AND Status=:Constants.REQUETE_STATUS_NEW
                                                                    AND Subject IN :subjectList AND SuppliedEmail IN :emailFromList]);
                    system.debug('## Cases Spam: '+casesSpam);
                    if(!emailsList.isEmpty() ){
                        // For all emails in list, compare new cases and spams
                        for (EmailMessage newEmail : emailsList.values()) {            
                            system.debug('## Email FROM: ' + newEmail.FromAddress);
                            system.debug('## Case ID: '+newEmail.ParentId);
                            Integer spamCount = 0;
                            for (Case casesToCompare : casesSpam.values()) {
                                if(newEmail.Subject==casesToCompare.Subject && newEmail.FromAddress==casesToCompare.SuppliedEmail){
                                    spamCount++;
                                }
                            }
                            
                            if(spamCount > 5 || (emailsBlacklist != null && emailsBlacklist.containsIgnoreCase(newEmail.FromAddress))){
                                newEmail.addError('## ERROR : Spam Email :\n '+newEmail);
                            }
                        }
                    }
                }
            }
            system.debug('### END TR020_EmailMessage : DetectMassCreationFromSpam');
        } catch (Exception e) {
            system.debug('ERROR # Detect Email Spam (' + e + ') Line : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }
}