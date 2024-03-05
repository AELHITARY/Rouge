//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_CaseActions
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 18/09/2019
//-- Version     : 1.1
//-- * 1.1 - RQM-113 : Ajout des constantes pour les nouveaux rôles/profils
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_CaseActions {
    public Case actualCase { get; set; }
    private static final Integer MAX_NAME_LENGTH = 80;
    private static final Date TODAY = System.today();

    // ERRORS
    public Utils_logger log {get; set;}

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public Ctrl_CaseActions(ApexPages.StandardController controller) {
        actualCase = (case) controller.getRecord();
        Id actualCaseId = actualCase.Id;
        actualCase = [SELECT id, Account.Name, CaseNumber, OwnerId, Subject, Type, Description,chantier__c, ContactId, emailResponsableDepot__c FROM Case WHERE id = :actualCaseId];

        log = new Utils_logger();
    }

    /**
    * @description Affectation de la requête au vendeur du dernier projet créé
    */
    public void affectationDernierVendeur() {
        system.debug('### DEBUT affectationDernierVendeur');
        Opportunity lastOpp = new Opportunity();
        try {
            if(actualCase.chantier__c != null){
                List<Opportunity> opps = [SELECT Id, chantier__c, OwnerId, Owner.IsActive, Owner.ManagerId
                                            FROM Opportunity WHERE chantier__c = :actualCase.chantier__c ORDER BY CreatedDate DESC LIMIT 1];
                if(!opps.isEmpty()){
                    lastOpp = opps[0];
                    actualCase.OwnerId = getActiveOwner(lastOpp.Owner.IsActive,lastOpp.OwnerId,lastOpp.Owner.ManagerId);
                    system.debug('## OwnerId: '+actualCase.OwnerId);
                    update actualCase;
                }
            }
            system.debug('### FIN affectationDernierVendeur');
            log.clear();
        } catch (DmlException e) {
            String message = e.getDmlMessage(0);
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        } catch (Exception e) {
            String message = 'ERREUR # Ligne : ' + String.valueOf(e.getLineNumber()) +'. Veuillez contacter votre administrateur.';
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        }
    }

    /**
    * @description Affectation du dernier chantier créé à la requête
    */
    public void associationDernierChantier() {
        system.debug('### FIN associationDernierChantier');
        try {
            List<Chantier__c> cha = [SELECT Id FROM Chantier__c WHERE (proprietaire__c = :actualCase.AccountId OR autreProprietaire__c = :actualCase.AccountId OR locataire__c = :actualCase.AccountId OR
                                        autreLocataire__c = :actualCase.AccountId OR occupant__c = :actualCase.AccountId OR autreOccupant__c = :actualCase.AccountId)
                                        ORDER BY CreatedDate DESC LIMIT 1];
            if(!cha.isEmpty()){
                actualCase.chantier__c = cha[0].Id;
                update actualCase;
            }
            system.debug('### FIN associationDernierChantier');
            log.clear();
        } catch (DmlException e) {
            String message = e.getDmlMessage(0);
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        } catch (Exception e) {
            String message = 'ERREUR # Ligne : ' + String.valueOf(e.getLineNumber()) +'. Veuillez contacter votre administrateur.';
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        }
    }

    /**
    * @description Association du chantier à la requête ayant la même adresse, sinon création d'un chantier
    */
    public void associationChantierDuCompte() {
        system.debug('### DEBUT associationChantierDuCompte');
        Chantier__c newChantier = new Chantier__c();
        try {
            // Recherche info Compte et chantier
            Account acc = [SELECT Id, FirstName, LastName, OwnerId, Owner.ManagerId, rue__c, ville__c, codePostal__c, complementAdresse__c, 
                            departement__c, pays__c, Owner.IsActive FROM Account WHERE Id = :actualCase.AccountId];

            List<Chantier__c> cha = [SELECT Id FROM Chantier__c WHERE (proprietaire__c = :actualCase.AccountId OR autreProprietaire__c = :actualCase.AccountId OR locataire__c = :actualCase.AccountId OR
                                        autreLocataire__c = :actualCase.AccountId OR occupant__c = :actualCase.AccountId OR autreOccupant__c = :actualCase.AccountId) AND
                                        rue__c = :acc.rue__c AND ville__c = :acc.ville__c AND codePostal__c = :acc.codePostal__c];
            // Si pas de chantier, on en créé un
            if(cha.isEmpty()){
                Chantier__c chantier = new Chantier__c();
                chantier.OwnerId = getActiveOwner(acc.Owner.IsActive,acc.OwnerId,acc.Owner.ManagerId);
                chantier.Name    = ('CHA _ ' + TODAY.year() + (TODAY.month() < 10 ? '0' + TODAY.month() : TODAY.month().format())
                                         + ' _ ' + (acc.FirstName  == null ? '' : acc.FirstName.toLowerCase())
                                         + ' '   + (acc.LastName    == null ? '' : acc.LastName.toUpperCase())
                                         + ' _ ' + acc.ville__c
                                         + ' _ Propriétaire')
                                .left(MAX_NAME_LENGTH);

                chantier.proprietaire__c = acc.Id;
                chantier.rue__c = acc.rue__c;
                chantier.codePostal__c = acc.codePostal__c;
                chantier.ville__c = acc.ville__c;
                chantier.complementAdresse__c = acc.complementAdresse__c;
                chantier.departement__c = acc.departement__c;
                chantier.pays__c = acc.pays__c;
                newChantier = chantier;
                insert newChantier;
            } else {
                newChantier = cha[0];
            }
            system.debug('## Chantier Id: '+newChantier.Id);
            actualCase.chantier__c = newChantier.Id;
            update actualCase;
            system.debug('### FIN associationChantierDuCompte');
            log.clear();
        } catch (DmlException e) {
            String message = e.getDmlMessage(0);
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        } catch (Exception e) {
            String message = 'ERREUR # Ligne : ' + String.valueOf(e.getLineNumber()) +'. Veuillez contacter votre administrateur.';
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        }
    }

     public void affectationProximiteVendeur() {
        List<ObjectDetailUtils.Vendeur> vendeurDistanceList = new List<ObjectDetailUtils.Vendeur>();
        List<User> vendeursList = new List<User>();
        String idVendeurLPP = null;
        Decimal distanceLPP = 100000000;
        Decimal latitude = null;
        Decimal longitude = null;
        String codeMagasin = null;

        try {
            if(actualCase.chantier__c != null){
                Chantier__c objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s, codeMagasinTechnique__c, codeMagasinActuel__c FROM Chantier__c WHERE Id = :actualCase.chantier__c];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                codeMagasin = objectResult.codeMagasinActuel__c; 
            } else {
                Account objectResult = [SELECT Id, localisation__longitude__s, localisation__latitude__s, codeMagasinActuel__c FROM Account WHERE Id = :actualCase.AccountId];
                latitude = objectResult.localisation__latitude__s;
                longitude = objectResult.localisation__longitude__s;
                codeMagasin = objectResult.codeMagasinActuel__c;
            }
            system.debug('codeMagasin : '+codeMagasin);

            // Pour les autres profils, affectation aux vendeurs du magasin de la sectorisation actuelle
            if(codeMagasin != null) {
                String[] codeMagasins = CalendrierUtils.getMagasinsKStore(codeMagasin);
                
                vendeursList = [SELECT Id, Name, localisationLongitude__c, localisationLatitude__c, libelleMagasin__c, IsActive
                                    FROM User WHERE codeMagasin__c IN :codeMagasins AND IsActive = true];
            }

            // Pour tous les vendeurs , on calcul le distance
            for(User vendeur : vendeursList) {
                ObjectDetailUtils.Vendeur resultat = new ObjectDetailUtils.Vendeur();
                // Si l'adresse du vendeur est spécifiée, calcul
                if(vendeur.localisationLatitude__c != null && vendeur.localisationLongitude__c != null && latitude != null && longitude != null){
                    Decimal distanceUser = ObjectDetailUtils.CalculationByDistance(latitude, longitude, vendeur.localisationLatitude__c, vendeur.localisationLongitude__c);
                    resultat.distance = distanceUser;
                } else {
                    resultat.distance = null;
                }
                resultat.UserId = vendeur.Id;
                resultat.UserName = String.escapeSingleQuotes(vendeur.Name);
                resultat.LibelleMagasin = vendeur.libelleMagasin__c;
                vendeurDistanceList.add(resultat);
            }

            system.debug('vendeurDistanceList : '+vendeurDistanceList);
            for(ObjectDetailUtils.Vendeur v : vendeurDistanceList){
                if(idVendeurLPP == null){
                    idVendeurLPP = v.UserId;
                    distanceLPP = v.distance;
                } else {
                    if(v.distance != null && v.distance < distanceLPP){
                        idVendeurLPP = v.UserId;
                        distanceLPP = v.distance;
                    }
                }
            }

            if(idVendeurLPP != null){
                actualCase.OwnerId = idVendeurLPP;
                update actualCase;
            }
            log.clear();
        } catch (DmlException e) {
            String message = e.getDmlMessage(0);
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        } catch (Exception e) {
            String message = 'ERREUR # Ligne : ' + String.valueOf(e.getLineNumber()) +'. Veuillez contacter votre administrateur.';
            system.debug('ERREUR (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            log.addErrorMessage(message);
        }
    }

    /**
    * @description Affectation de la requête au manager du vendeur
    */
    public void affectationManager() {
        system.debug('### DEBUT affectationManager');
        try {
            User ownerUser = new User();
            User manager = new User();

            List<User> ownerUserList = [SELECT Id, managerId FROM User WHERE Id = :actualCase.OwnerId];
            ownerUser = ownerUserList[0];

            if(ownerUser.managerId != null){
                actualCase.OwnerId = ownerUser.managerId;
                system.debug('## Manager Id: '+actualCase.OwnerId);
                update actualCase;
            }           
            system.debug('### FIN affectationManager');
        } catch(Exception e) {
            system.debug('### ERROR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[Salesforce] ERREUR : Impossible d\'affecter la requête au manager', e);
            //throw e;
        }
    }

    /**
    * @description Renvoie une notification au réseau
    */
    public void renvoyerNotificationReseau() {
        /*List<String> destinatairesEmails = new List<String>();
        List<User> destinatairesUser = new List<User>();
        destinatairesEmails.add('julien.morineau@soprasteria.com');
        if(actualCase.Type == Constants.REQUETE_RECLAMATION_CENTRE){
            destinatairesUser = [SELECT Id, Email FROM User WHERE IsActive = TRUE AND Id = :actualCase.OwnerId];
            List<String> publicGroupNamesSupOrDC = new List<String> { Constants.ROLE_KPK_SUP , Constants.ROLE_KPK_DC};
            List<User> usersSupOrDC = UserContext.getPublicGroupMembers(publicGroupNamesSupOrDC);
            for(User us : usersSupOrDC){
                destinatairesUser.add(us);
            }
        } else if(actualCase.Type == Constants.REQUETE_RECLAMATION_INSTALLATION || actualCase.Type == Constants.REQUETE_RECLAMATION_METRAGE ||
                  actualCase.Type == Constants.REQUETE_RECLAMATION_SAV ){
            destinatairesUser = [SELECT Id, Email FROM User WHERE IsActive = TRUE AND (Id = :actualCase.OwnerId)];
            destinatairesEmails.add(actualCase.emailResponsableDepot__c);
            destinatairesEmails.add(actualCase.emailDepot__c);
        } else if(actualCase.Type == Constants.REQUETE_RECLAMATION_MARKETING){
            destinatairesUser = [SELECT Id, Email FROM User WHERE IsActive = TRUE AND (Id = :actualCase.OwnerId OR UserRole.Name = 'Marketing')];
        } else if(actualCase.Type == Constants.REQUETE_RECLAMATION_COMMERCIALE){
            destinatairesUser = [SELECT Id, Email, managerId FROM User WHERE IsActive = TRUE AND Id = :actualCase.OwnerId];
            Map<Id, User> users = new Map<Id, User>([SELECT Id, Name, ManagerId, UserRole.Name, codeMagasin__c, codeDV__c, codeDR__c, Email
                                                   FROM User
                                                   WHERE IsActive = TRUE
                                                     AND (Id = :actualCase.OwnerId OR UserRole.Name LIKE '% - DR - %' OR UserRole.Name LIKE '% - DV - %' 
                                                            OR UserRole.Name LIKE '% - REF - %' OR UserRole.Name LIKE '% - MAG - %')
                                                   ORDER BY CreatedDate]);
            User user = users.get(actualCase.ownerId);
            destinatairesUser.add(user);
            if (user != null && user.managerId != null) {
                User manager = users.get(user.managerId);              
                if (manager != null) {
                    destinatairesUser.add(manager);
                    manager = users.get(manager.managerId);
                    if (manager != null) {
                        destinatairesUser.add(manager);         
                        manager = users.get(manager.managerId);
                        if (manager != null) {
                            destinatairesUser.add(manager);
                        }
                    }
                }
            }
        }
 
        // Sélection de l'email d'expédition et du template
        OrgWideEmailAddress fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = 'support@kpark.fr'];
        EmailTemplate template = [Select id from EmailTemplate where name = '[Requête] Notification requête toujours ouverte'];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for(User user : destinatairesUser){
            destinatairesEmails.add(user.Email);
        }

        // Construction de l'email et envoi
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateID(template.Id); 
        email.setTargetObjectId(actualCase.ContactId);
        email.setTreatTargetObjectAsRecipient(false);
        email.setOrgWideEmailAddressId(fromAddress.Id);
        email.setWhatId(actualCase.Id);
        email.setToAddresses(destinatairesEmails);
        email.setSaveAsActivity(false);
        emailList.add(email);

        if (!Test.isRunningTest()) {   
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList,false);
            system.debug('EmailUtils results : ' + results);
        }*/
    }

    private static String getActiveOwner(Boolean isActive, String ownerId, String managerId) {
         return ((isActive) ? ownerId : (managerId!=null) ? managerId : UserInfo.getUserId());
    }
}