//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Site_EspaceClient
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 21/03/2022
//-- Version     : 2.5
//-- * 2.5 - MAJ pour Kube3 (ajout devis CPQ et Order)
//-- * 2.4 - Modification Odigo (PinkSoda)
//-- * 2.3 : RQM-76 : GDPR
//-- * 2.2 - RQM-86 : Connexion ADMIN
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Site_EspaceClient {
    public static OrgWideEmailAddress orgWideEmailAddress { get { return[SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Relation Clients' LIMIT 1]; } set; }
    public static String TELSUPPORT { get { return PropertiesUtils.getStringValue('site.tel.support', '0 811 133 008'); } set; }
    public static String EMAILSUPPORT { get { return PropertiesUtils.getStringValue('espaceclient.erreur.mail.destinataire', 'reclamationclient@kpark.fr'); } set; }
    public static final String COOKIE_NAME = 'sessionKPK';
    //public static final Integer    COOKIE_MAXAGE    = 604800; // 7 jours (60 * 60 * 24 * 7)
    public static final Integer COOKIE_MAXAGE = - 1;

    // Règles de gestion des mot de passe
    public static Integer LONGUEURMIN { get { return PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.longueurMin',0); } set; }
    public static Integer LONGUEURMAX { get { return PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.longueurMax',0); } set; }
    public static Integer NOMBRECHIFFRES { get { return PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.nbChiffres',0); } set; }
    public static Integer NOMBREMAJUSCULES { get { return PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.nbMaj',0); } set; }
    public static Integer NOMBREMINUSCULES { get { return PropertiesUtils.getIntegerValue('espaceclient.securiteMDP.nbMin',0); } set; }

    // Général
    public GoogleMapsSettings__c googleMapsSettings { get; private set; }
    public Boolean activeParrainage { get; set; }
    public Compte account { get; set; }
    public Boolean isClient { get ; set; }
    public Account accountInitial { get; set; }
    public String messageError { get; set; }
    public String messagePasswordRequirement { get; set; }
    public Boolean passwordChanged { get; set; }
    public String passwordResetMsg { get; set; }

    // PAGE CONNEXION
    public String user { get; set; }
    public String mail { get; set; }
    public String password { get; set; }
    public String encodedPassword { get; set; }
    public Boolean loginCorrect { get; set; }
    public Boolean alreadySaved { get; set; }
    public Boolean forcedLogin {get; set;}

    // ONGLET CONTRATS
    public List<Contrat> contratsClient { get; set; }
    public List<Contrat> contratsClientEnCours { get; set; }
    public List<Contrat> contratsClientTermine { get; set; }
    public String premierContratId { get; set; }
    
    // ONGLET PARRAINAGE
    public List<Filleul> filleuls { get; set; }
    public List<Filleul> filleulsClient { get; set; }

    // ONGLET DOCUMENTS
    public String noticeVoletsSolairesURL { get; set; }

    // COMPOSANT NOTIFICATION
    public List<Notification> notificationsClient { get; set; }

    //ONGLET GESTION DES DEMANDES
    public String selectedTypeDemande { get; set; }
    public String selectedMotif { get; set; }
    public String selectedTypeDeRDV { get; set; }
    public String selectedDescriptionDemande { get; set; }
    public String selectedChantier { get; set; }
    public String typeRDVListDemandeRDV { get; set; }
    public String typeRDVListmodifRDV { get; set; }
    public String typeRDVListannulationRDV { get; set; }
    public String typeRDVListDemandeInfo { get; set; }
    public Map<Id,Demande> demandesClient {get{ return getDemandesClient(); } set; }
    public Demande demandeToDisplay { get {        
        Id caseId = Apexpages.currentPage().getParameters().get('caseId');
        if(caseId!=null)
            return demandesClient.get(caseId);
        else
            return null;
        } set; }
    public List<Commentaire> commentairesToDisplay { get {        
        if(demandeToDisplay!=null)
            return retrieveComments(demandeToDisplay.id);
        else
            return new List<Commentaire>();
        } set; }
    public List<PieceJointe> caseAttachmentToDisplay { get {
        if(demandeToDisplay!=null)
            return retrieveCaseAttachments(demandeToDisplay.id);
        else
            return new List<PieceJointe>();
        } set; }
    public List<SelectOption> chantiersClient { get; set; }
    public List<SelectOption> getTypeDemande() {
        List<SelectOption> options = new List<SelectOption> ();

        Schema.DescribeFieldResult typePickList = Case.Type.getDescribe();
        List<Schema.PicklistEntry> plv = typePickList.getPicklistValues();

        // Valeurs à exclure
        List<String> exList = new List<String>{'ECI', 'SAV garantie', 'SAV hors garantie', 'Menuiserie', 'ECI/SAV'};

        for (Schema.PicklistEntry types : plv) {
            if(exList.contains(types.getLabel()) == false) {
                options.add(new SelectOption(types.getLabel(), types.getValue()));
            }
        }
        return options;
    }

    public List<SelectOption> getMotifOptions() {
        List<SelectOption> options = new List<SelectOption> ();
        // Construction de la liste dépendante Type/Type de rendez-vous
        Map<String, List<String>> motifs = PicklistUtils.GetDependentOptions('Case', 'Type', 'motif__c');
        for (String motif : motifs.get(selectedTypeDemande)) {
            options.add(new SelectOption(motif, motif));
        }
        return options;
    }

    public List<SelectOption> getTypeDeRDV() {
        List<SelectOption> options = new List<SelectOption> ();

        // Construction de la liste dépendante Type/Type de rendez-vous
        Map<String, List<String>> typeRDV = PicklistUtils.GetDependentOptions('Case', 'Type', 'typeDeRendezVous__c');

        //Initialisation des listes utilisées par js pour mettre à jour la picklist onchange
        List<String> typeRDVdemandeRDV = typeRDV.get('Nouveau rendez-vous');
        List<String> typeRDVmodifRDV = typeRDV.get('Modification de rendez-vous');
        List<String> typeRDVannulationRDV = typeRDV.get('Annulation de rendez-vous');
        List<String> typeRDVdemandeInfo = typeRDV.get('Demande d\'information');

        typeRDVListDemandeRDV = JSON.serialize(typeRDVdemandeRDV);
        typeRDVListmodifRDV = JSON.serialize(typeRDVmodifRDV);
        typeRDVListannulationRDV = JSON.serialize(typeRDVannulationRDV);
        typeRDVListDemandeInfo = JSON.serialize(typeRDVdemandeInfo);

        List<String> valuesList = typeRDV.get(selectedTypeDemande);
        if(String.isNotBlank(selectedTypeDemande) && valuesList!=null) {
            for (String typeRDVvalue : valuesList) 
                options.add(new SelectOption(typeRDVvalue, typeRDVvalue));
        }
        return options;
    }

    // COMPOSANT INFORMATION VENDEUR
    public String contactVendeurName { get; set; }
    public String contactVendeurJoignabilite { get; set; }

    // ERRORS
    public Utils_logger log {get; set;}
     
    /**
    * @description Constructeur
    * @return Ctrl_Site_EspaceClient
    */ 
    public Ctrl_Site_EspaceClient() 
    {
        // Récupération des paramètres de la carte
        googleMapsSettings = GoogleMapsSettings__c.getValues('cartographie');

        log = new Utils_logger();

        // Initialisation
        loginCorrect = false;
        forcedLogin = false;
        demandesClient = new Map<Id,Demande>();
        demandeToDisplay = null;
        commentairesToDisplay = new List<Commentaire>();
        caseAttachmentToDisplay = new List<PieceJointe>();
        contratsClient = new List<Contrat>();
        contratsClientEnCours = new List<Contrat>();
        contratsClientTermine = new List<Contrat>();
        filleuls = new List<Filleul>();
        filleulsClient = new List<Filleul>();
        notificationsClient = new List<Notification>();
        activeParrainage = true;
        passwordChanged = false;
        messageError = '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
        + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
        // Construction message pour format mot de passe
        messagePasswordRequirement = String.format(Label.espaceclient_text_ReglesMotDePasse, 
                                        new List<String>{String.valueOf(LONGUEURMIN),String.valueOf(LONGUEURMAX),
                                                        String.valueOf(NOMBREMAJUSCULES),((NOMBREMAJUSCULES != 1)?'s':''),
                                                        String.valueOf(NOMBREMINUSCULES),((NOMBREMINUSCULES != 1)?'s':''),
                                                        String.valueOf(NOMBRECHIFFRES),((NOMBRECHIFFRES != 1)?'s':'')});

        // Picklist des types dans "BESOIN D'AIDE"
        if (selectedTypeDemande == '' || selectedTypeDemande == null) selectedTypeDemande = 'Nouveau rendez-vous';
        getTypeDeRDV();
        if(ApexPages.currentPage().getParameters().get('passwordChange') == 'success'){
            passwordChanged = true;
        }
        String accIdVF = ApexPages.currentPage().getParameters().get('accId');
        if(String.isNotBlank(accIdVF))
            forceVisualforceLogin();

        // Get documents
        Map<String, Mapping__c> mappings = Mapping__c.getAll();
        for (Mapping__c mapping : mappings.values()){
            if (mapping.repository__c.equalsIgnoreCase('contentDocument') && mapping.pickValue__c.equalsIgnoreCase('noticeVoletsSolaires')){
                noticeVoletsSolairesURL = mapping.convertedValue__c+'';
            }
        }
    }

    /**
    * @description Méthode de vérification des droits d'accès (déjà connecté)
    * @return PageReference Page Visualforce
    */ 
    public PageReference checkAllowedAccess() {
        System.debug('### DEBUT checkAllowedAccess');
        String currentPageName = String.valueOf(ApexPages.currentPage());
        String connexionPageName = String.valueOf(Page.VF_Site_EspaceClient);
        String editPageName = String.valueOf(Page.VF_Site_EspaceClient_Edit);

        log.clear();

        if (loginCorrect == true || forcedLogin == true) {
            return null;
        }
        // Pas de cookie, redirection vers connexion
        Cookie cookieSite = ApexPages.currentPage().getCookies().get(COOKIE_NAME);
        if (cookieSite == null || String.isBlank(cookieSite.getValue())) {
            System.debug('## Access not granted');
            // Si l'utilisateur est sur la page d'édition
            if (currentPageName.containsIgnoreCase(editPageName)) {
                System.debug('## Edit');
                PageReference connexion = Page.VF_Site_EspaceClient;
                connexion.setRedirect(false);
                String message = Label.msg_accessNotAllowed;
                log.addErrorMessage(message);
                return connexion;
            } else {
                // Si l'utilisateur est sur la page de connexion
                System.debug('## Connexion');
                return null;
            }
        } 
        else {
            System.debug('## Cookie found');
            String base64blob = cookieSite.getValue();
            String cookieKey = PropertiesUtils.getStringValue('espaceclient.cookie.key', '');
            if (cookieKey == null) {
                throw new KubeException('Déchiffrage impossible sans clé !');
            }
            Blob key = EncodingUtil.base64Decode(cookieKey);
            String cookieData = Crypto.decryptWithManagedIV('AES256', key, EncodingUtil.base64Decode(base64blob)).toString();
            List<String> parts = cookieData.split(' ');
            user = parts[0];
            encodedPassword = parts[1];
            // Reconnexion de l'utilisateur
            if (currentPageName.containsIgnoreCase(editPageName)) {
                System.debug('## Edit');
                if (accountInitial == null) checkAccountLogin(user, encodedPassword, false);
                return null;
            } else {
                System.debug('## Connexion');
                return checkAccountLogin(user, encodedPassword, false);
            }
        }
    }

    /**
    * @description Méthode de création de cookie pour session de navigation
    */ 
    public void createSessionCookie() {
        System.debug('### DEBUT createSessionCookie');
        // Donnée du cookie
        String cookieData = accountInitial.AccountNumber + ' ' + accountInitial.motDePasseClient__c;
        // Encodage de la clé SHA AES256 en Base64 pour le cryptage du cookie
        String cookieKey = PropertiesUtils.getStringValue('espaceclient.cookie.key', null);
        Blob key = null;
        if (cookieKey == null) {
            // Pas de clés, on en génère une
            key = Crypto.generateAesKey(256);
            PropertiesUtils.setStringValue('espaceclient.cookie.key', EncodingUtil.base64Encode(key));
        } else {
            key = EncodingUtil.base64Decode(cookieKey);
        }
        // Création du cookie
        String base64blob = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', key, Blob.valueOf(cookieData)));
        ApexPages.currentPage().setCookies(new Cookie[] { new Cookie(COOKIE_NAME, base64blob, null, COOKIE_MAXAGE, true) });
        System.debug('### FIN createSessionCookie');
    }

    /**
    * @description Méthode de suppression de cookie pour session de navigation
    */ 
    public void clearSessionCookie() {
        System.debug('### DEBUT clearSessionCookie');
        // Suppression du cookie
        ApexPages.currentPage().setCookies(new Cookie[] { new Cookie(COOKIE_NAME, null, null, 0, true) });
        System.debug('### FIN clearSessionCookie');
    }
    
    /**
    * @description Méthode de vérification des informations de connexion de l'utilisateur en tant qu'administrateur
    * @return PageReference Page Visualforce
    */ 
    public PageReference forceVisualforceLogin() {
        System.debug('### DEBUT forceVisualforceLogin');
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        System.debug('userProfile : '+userProfile);
        log.clear();
        try {
            if(userProfile != null && userProfile.Name == 'Administrateur système'){
                String userLogin = ApexPages.currentPage().getParameters().get('accId');
                String message = '';
                loginCorrect = true;
                // Trim
                if (String.isNotBlank(userLogin)) userLogin = userLogin.trim();
                accountInitial = getAccountDatas(userLogin);
                // Si aucun compte n'est retourné
                if (accountInitial==null) {
                    System.debug('## Aucun compte trouvé (userLogin = ' + userLogin + ')');
                    loginCorrect = false;
                    message = Label.msg_AccountDoesntExist;
                    log.addErrorMessage(message);
                    return null;
                } else {
                    alreadySaved = false;
                    forcedLogin = true;
                    // Initialisation de la classe de substitution
                    account = new Compte(accountInitial);
                    // Vérification de l'authentification
                    // Traitement des informations du compte (récupération des informations)
                    processAccountLogin(accountInitial, account);
                    // Affichage
                    Pagereference edit = Page.VF_Site_EspaceClient_Edit;
                    edit.setRedirect(false);
                    System.debug('### FIN forceVisualforceLogin');
                    return edit;
                }
            } else {
                Pagereference stay = Page.VF_Site_EspaceClient_Edit;
                stay.setRedirect(false);
                return Page.VF_Site_EspaceClient;
            }
        } catch(Exception e) {
            String message = Label.msg_InternalError + ' Ligne erreur : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : <a href="tel:' + TELSUPPORT + '"><strong class="text-red">' + TELSUPPORT + '</strong></a><br/><strong>E-mail : </strong> ' + EMAILSUPPORT;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Connexion (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            return null;
        }
    }

    /**
    * @description Méthode de déconnexion (Suppression du cookie)
    * @return PageReference Page Visualforce
    */ 
    public PageReference deconnexion() {
        System.debug('### DEBUT deconnexion');
        clearSessionCookie(); // Suppression du cookie
        password = null;
        encodedPassword = null;
        loginCorrect = false;
        System.debug('### FIN deconnexion');
        return backLoginForm();
    }
    
    /**
    * @description Méthode pour retourner sur la page de connexion
    * @return PageReference Page Visualforce
    */ 
    public PageReference backLoginForm() {
        System.debug('### DEBUT backLoginForm');
        // Redirection
        PageReference connexion = Page.VF_Site_EspaceClient;
        connexion.setRedirect(true);
        System.debug('### FIN backLoginForm');
        return connexion;
    }

    /**
    * @description Méthode appelée lors de la connexion
    * @return PageReference Page Visualforce
    */ 
    public PageReference login() {
        encodedPassword = encodePassword(password);
        return checkAccountLogin(user, encodedPassword, true);
    }

    /**
    * @description Méthode de vérification des informations de connexion de l'utilisateur
    * @param userLogin Identifiant de l'utilisateur
    * @param userEncodedPwd Mot de passe hashé de l'utilisateur
    * @param displayWrongPasswdErr True si affichage de l'erreur que le mot de passe est incorrect
    * @return PageReference Page Visualforce
    */ 
    public PageReference checkAccountLogin(String userLogin, String userEncodedPwd, Boolean displayWrongPasswdErr) {
        System.debug('### DEBUT checkAccountLogin');
        log.clear();
        try {
            String message = '';
            loginCorrect = true;

            // Trim
            if (String.isNotBlank(userLogin)) userLogin = userLogin.trim();

            // Si l'utilisateur n'a pas saisi de numéro de compte
            if (String.isBlank(userLogin)) {
                System.debug('## user null');
                message = Label.msg_LoginRequired;
                loginCorrect = false;
                log.addWarnMessage(message);
                return null;
            }
            // Si l'utilisateur n'a pas saisi de mot de passe
            else if (String.isBlank(userEncodedPwd)) {
                System.debug('## password null');
                loginCorrect = false;
                message = Label.msg_PasswordRequired;
                log.addWarnMessage(message);
                return null;
            } else {
                System.debug('## Pas de champ vide');
                String searchFilter = '"'+userLogin+'"';
                System.debug('## searchFilter: '+searchFilter);
                List<List<SObject>> searchList = [FIND :searchFilter IN ALL FIELDS RETURNING Account(Id WHERE Type IN ('Client', 'Ex-client'))];
                // Si aucun compte n'est retourné
                if (searchList==null || searchList.isEmpty() || searchList[0].isEmpty()) {
                    System.debug('## Aucun compte trouvé (userLogin = ' + userLogin + ')');
                    loginCorrect = false;
                    message = Label.msg_AccountDoesntExist;
                    log.addErrorMessage(message);
                    return null;
                } else if (searchList[0].size() > 1) {
                    System.debug('## Plusieurs comptes trouvés (userLogin = ' + userLogin + ')');
                    loginCorrect = false;
                    message = Label.espaceclient_msg_MultiAccounts;
                    log.addWarnMessage(message);
                    return null;
                }
                // Sinon
                else {
                    List<Account> accounts = ((List<Account>)searchList[0]);
                    accountInitial = getAccountDatas(accounts[0].Id);
                    alreadySaved = false;
                    // Initialisation de la classe de substitution
                    account = new Compte(accountInitial);
                    // Si le mot de passe du compte n'est pas défini
                    if (accountInitial.motDePasseClient__c == null) {
                        loginCorrect = false;
                        message = Label.msg_NoPasswordSet;
                        log.addErrorMessage(message);
                        return null;
                    }
                    // Sinon
                    else {
                        // Vérification de l'authentification
                        // Si le résultat de l'authentification est incorrect OU qu'il est correct mais qu'il n'est pas crypté en base
                        loginCorrect = (accountInitial.motDePasseClient__c.equals(userEncodedPwd) || password==accountInitial.motDePasseClient__c);
                        if (!loginCorrect) {
                            System.debug('## login incorrect');
                            if(displayWrongPasswdErr) {
                                message = Label.msg_WrongLoginPassword;
                                log.addErrorMessage(message);
                            }
                            return null;
                        }
                        // Sinon
                        else {
                            // Si le mot de passe est correct mais n'est pas crypté en base
                            String userBaseEncodedPwd = encodePassword(accountInitial.motDePasseClient__c);
                            if(userEncodedPwd == userBaseEncodedPwd){
                                // Mise à jour du mot de passe pour le crypter en base
                                Account accTmp = new Account(Id=accountInitial.Id, motDePasseClient__c = userEncodedPwd);
                                update accTmp;
                            }
                            System.debug('## login correct');
                            // Traitement des informations du compte (récupération des informations)
                            processAccountLogin(accountInitial, account);
                            // Affichage
                            Pagereference edit = Page.VF_Site_EspaceClient_Edit;
                            edit.setRedirect(false);
                            System.debug('### FIN checkAccountLogin');
                            return edit;
                        }
                    }
                }
            }
        } catch(Exception e) {
            String message = Label.msg_InternalError + ' Ligne erreur : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : <a href="tel:' + TELSUPPORT + '"><strong class="text-red">' + TELSUPPORT + '</strong></a><br/><strong>E-mail : </strong> ' + EMAILSUPPORT;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Connexion (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            return null;
        }
    }

    /**
    * @description Chiffre un mot de passe pour qu'il soit comparable avec la base de données
    * @param pwdToEncode String contenant le mot de passe à chiffrer
    * @return String Retourne la signature SHA-512 du mot de passe
    */ 
    @TestVisible
    private static String encodePassword(String pwdToEncode)
    {
        String encodedPwd;
        if(String.isNotBlank(pwdToEncode)) {
            pwdToEncode = pwdToEncode.trim();
            Blob targetBlob = Blob.valueOf(pwdToEncode);
            encodedPwd = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-512', targetBlob));
        }
        return encodedPwd;
    }
    
    /**
    * @description Récupère les données du compte
    * @param accId Id du compte
    * @return Account Retourne l'objet Account
    */ 
    private static Account getAccountDatas(String accId) {
        List<Account> accounts = [SELECT Id, contactParDefaut__c, civilite__c, nom__c, prenom__c, rue__c, complementAdresse__c, etage__c, typeDotation__c,
                        interphone__c, codePostal__c, ville__c, departement__c, pays__c, telephoneDomicile__c, Fax, canalPrefere__c, telephoneMobile__c, Phone, AccountNumber, email__c, 
                        contactParDefaut__r.account.etage__c, contactParDefaut__r.account.interphone__c, contactParDefaut__r.Email, contactParDefaut__r.MobilePhone, contactParDefaut__r.OtherPhone, 
                        dateConnexionEspaceClient__c, dateMotDePasseClient__c, motDePasseClient__c, Type, autreTelephone__c, optinAdresseEmailKparK__c, optinAdresseEmailPartenaire__c, optinSMSKparK__c, 
                        optinSMSPartenaire__c, optinTelephoneDomicileKparK__c, optinTelephoneDomicilePartenaire__c, optinTelephoneMobileKparK__c, optinTelephoneMobilePartenaire__c, IsPersonAccount, 
                        Localisation__latitude__s, Localisation__longitude__s, Owner.Name, Owner.Phone, Owner.Email, Sectorisation__r.libelleDepot__c, Sectorisation__r.rueDepot__c, 
                        Sectorisation__r.codePostalDepot__c, Sectorisation__r.villeDepot__c, Sectorisation__r.emailDepot__c, Sectorisation__r.telephoneDepot__c, 
                        Sectorisation__r.localisationDepot__latitude__s, Sectorisation__r.localisationDepot__longitude__s FROM Account WHERE Id=:accId LIMIT 1];
        if(accounts.size() > 0)
            return accounts[0];
        else return null;
    }

    /**
    * @description Méthode de traitement des informations du compte (récupération projets, contrats etc...)
    * @param accountInitial Objet Salesforce du client
    * @param account Objet custom du client
    */ 
    private void processAccountLogin(Account accountInitial, Compte account) {
        System.debug('### DEBUT processAccountLogin');
        String adresseIP = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        log.clear();

        try {
            // Modification de la dernière date de connexion et adresse IP
            if(!forcedLogin) {
                setDateConnexionAndIP(accountInitial.Id, adresseIP);
            }
            // Création du cookie
            createSessionCookie();
            // Vérification parrainage
            refreshFilleuls();
            // Récupération des contrats, projets et requêtes liés au compte
            contratsClient = getContratsClientKube2();
            contratsClient.addAll(getOrderClientKube3());
            demandesClient = getDemandesClient();
            // Récupération des chantiers du client
            chantiersClient = getChantiersClient();
            //Récupération des notifications
            notificationsClient = getNotificationsClient();
            // Récupération du vendeur du client
            contactVendeurName = accountInitial.Owner.Name;
            if (accountInitial.Owner.Email != null && accountInitial.Owner.Phone != null)
            contactVendeurJoignabilite = ' au ' + accountInitial.Owner.Phone + ' ou par e-mail <strong><a href="mailto:' + accountInitial.Owner.Email + '">' + accountInitial.Owner.Email + '</a></strong>';
            else if (accountInitial.Owner.Phone != null)
            contactVendeurJoignabilite = ' au ' + accountInitial.Owner.Phone;
            else if (accountInitial.Owner.Email != null)
            contactVendeurJoignabilite = ' par e-mail <strong><a href="mailto:' + accountInitial.Owner.Email + '">' + accountInitial.Owner.Email + '</a></strong>';
            else
            contactVendeurJoignabilite = ' en appelant notre service client au <a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a> '
            + 'ou par e-mail <strong><a href="mailto:' + EMAILSUPPORT + '">' + EMAILSUPPORT + '</a></strong>';
            // Vérifie si le compte est un client
            isClient = (accountInitial.Type == Constants.ACCOUNT_TYPE_CLIENT || accountInitial.Type == Constants.ACCOUNT_TYPE_EXCLIENT);
            System.debug('### FIN processAccountLogin');
        } catch(Exception e) {
            String message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Traitement du compte (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }

    /**
    * @description Méthode appelée lors du clic sur le bouton "Export de données"
    * @param accId Id du compte client
    * @return String JSON contenant les données du client
    */ 
    @RemoteAction
    public static String jsonExportDonnees(string accId) {
        System.debug('### DEBUT jsonExportDonnees');
        String query ='';
        String result = null;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        List<referentielExportDonnesGDPR__c> metadatas = [SELECT Id, nomObjet__c, actif__c, champDeJointure__c, champsExclus__c, objetDeJointure__c, priorite__c 
                                                            FROM referentielExportDonnesGDPR__c WHERE actif__c = true ORDER BY priorite__c ASC];
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField> ();
        List<SObject> Sobjects = new List<SObject> ();
        Set<String> sObjectsId = new Set<String>();
        List<SObject> sObjectsToExport = new List<SObject>();

        // Parcours de toutes les règles pour récupérer seulement l'Account primaire
        sObjectsId.add(accId);
        for (referentielExportDonnesGDPR__c meta: metadatas) {
            // Construction requête SOQL pour l'Account primaire
            if (meta.nomObjet__c == 'Account' && String.isBlank(meta.objetDeJointure__c)) {
                System.debug('### Account Primaire: ' + meta.nomObjet__c + ' - ' + meta.champsExclus__c);
                fieldMap = schemaMap.get(meta.nomObjet__c).getDescribe().fields.getMap();
                String strFields = '';            
                // Récupération des champs à exclure
                String splitChampExclus = '';
                List<String> splitChampsExclus = new List<String>();
                if(String.isNotBlank(meta.champsExclus__c)) {
                    splitChampExclus = meta.champsExclus__c;
                    splitChampExclus = splitChampExclus.toLowerCase();
                    splitChampExclus = splitChampExclus.deleteWhitespace();
                    splitChampsExclus = splitChampExclus.split(',');
                }
                System.debug('## splitChampsExclus: ' + splitChampsExclus);
                for(String fieldName : fieldMap.keyset()) {
                    if((strFields == null || strFields == '') && !splitChampsExclus.contains(fieldName)) {
                        strFields = fieldName;
                    } else if(!splitChampsExclus.contains(fieldName)){
                        strFields = strFields + ' , ' + fieldName;
                    }
                }
                query = 'SELECT ' + strFields + ' FROM ' + meta.nomObjet__c + ' where Id= :accId';
                System.debug('## query: ' + query);  
                sObjectsToExport.add(database.query(query));
            }
        }

        // Serialize JSON
        if(!sObjectsToExport.isEmpty()) {
            String jsonSerializeObject = JSON.SerializePretty(sObjectsToExport);
            jsonSerializeObject = jsonSerializeObject.unescapeHtml4();
            result = jsonSerializeObject.removeEnd(']');
        }

        // Parcours de toutes les règles d'export
        for (referentielExportDonnesGDPR__c meta: metadatas) {  
            // Construction requête SOQL pour les objets enfants
            if (meta.nomObjet__c != 'Account' && String.isNotBlank(meta.objetDeJointure__c)) {
                System.debug('## Metadata: ' + meta.nomObjet__c + ' - ' + meta.objetDeJointure__c);                
                System.debug('## sObjectsId: ' + sObjectsId);  
                fieldMap = schemaMap.get(meta.nomObjet__c).getDescribe().fields.getMap();
                String strFields = '';            
                // Récupération des champs à exclure
                String splitChampExclus = '';
                List<String> splitChampsExclus = new List<String>();
                if(String.isNotBlank(meta.champsExclus__c)) {
                    splitChampExclus = meta.champsExclus__c;
                    splitChampExclus = splitChampExclus.toLowerCase();
                    splitChampExclus = splitChampExclus.deleteWhitespace();
                    splitChampsExclus = splitChampExclus.split(',');
                }
                System.debug('## splitChampsExclus: ' + splitChampsExclus);
                
                // Récupération des champs de jointure
                String splitChampDeJointure = '';
                List<String> splitChampsDeJointure = new List<String>();
                if(String.isNotBlank(meta.champDeJointure__c)) {
                    splitChampDeJointure = meta.champDeJointure__c;
                    splitChampDeJointure = splitChampDeJointure.toLowerCase();
                    splitChampDeJointure = splitChampDeJointure.deleteWhitespace();
                    splitChampsDeJointure = splitChampDeJointure.split(',');
                }
                System.debug('## splitChampsDeJointure: ' + splitChampsDeJointure);  
                // Ne prend pas les champs à exclure
                for(String fieldName : fieldMap.keyset() ) {
                    if((strFields == null || strFields == '') && !splitChampsExclus.contains(fieldName) ) {
                        strFields = fieldName;
                    } else if(!splitChampsExclus.contains(fieldName)){
                        strFields = strFields + ' , ' + fieldName;
                    }
                }
                for (String chpJointure : splitChampsDeJointure) {
                    query = 'SELECT ' + strFields + ' FROM ' + meta.nomObjet__c + ' where '+ chpJointure +' IN :sObjectsId';
                    System.debug('## query:  '+query);
                    for(SObject q : database.query(query)) {
                        // Récupère l'Id des enfant (sauf compte enfant pour éviter les boucles)
                        if(meta.nomObjet__c != 'Account') {
                            sObjectsId.add(q.Id);
                        }
                        // Serialize JSON
                        result += ',';
                        String jsonSerialize = JSON.SerializePretty(q);
                        jsonSerialize = jsonSerialize.unescapeHtml4();
                        result += jsonSerialize;
                    }
                }
            }
        }

        // Concatenate value
        if(String.isNotBlank(result)) {
            result += ']';
        }
        System.debug('## result: ' + result);
        System.debug('### FIN jsonExportDonnees');
        return result;
    }

    /**
    * @description Rafraichi la liste des filleuls et vérifie si parrainage disponible
    * Parrainage non autorisé si le parrain n'est pas un client
    */
    public void refreshFilleuls(){
        System.debug('### DEBUT refreshFilleuls');
        filleuls = getFilleulsClient();
        if (accountInitial.Type!='Client') {
            activeParrainage = false;
        }
        System.debug('### FIN refreshFilleuls');
    }

    /**
    * @description REMOTEACTION - Méthode d'enregistrement des modifcations du compte client
    * @param accId Id Salesforce du compte
    * @param numeroCompte Numéro Salesforce du compte
    * @param mapValue Objet des valeurs du client
    */ 
    @RemoteAction
    public static void updateAccount(String accId, String numeroCompte, Map<String, String> mapValue) {
        System.debug('### DEBUT updateAccount');
        System.debug('## Valeur : ' + mapValue);
        String message = '';
        Account newAccount = new Account();
        String nom; String prenom; String codePostal; String ville; String email; String phone;
        String telephoneDomicile; String telephoneMobile; String telephoneProfessionnel; String fax; String etage;

        if (mapValue.get('nom') != null) nom = mapValue.get('nom').trim();
        if (mapValue.get('prenom') != null) prenom = mapValue.get('prenom').trim();
        if (mapValue.get('codePostal') != null) codePostal = mapValue.get('codePostal').trim();
        if (mapValue.get('ville') != null) ville = mapValue.get('ville').trim();
        if (mapValue.get('email') != null) email = mapValue.get('email').trim();
        if (mapValue.get('telephoneDomicile') != null) telephoneDomicile = mapValue.get('telephoneDomicile').trim();
        if (mapValue.get('telephoneMobile') != null) telephoneMobile = mapValue.get('telephoneMobile').trim();
        if (mapValue.get('autreTelephone') != null) telephoneProfessionnel = mapValue.get('autreTelephone').trim();
        if (mapValue.get('phone') != null) phone = mapValue.get('phone').trim();
        if (mapValue.get('fax') != null) fax = mapValue.get('fax').trim();
        if (mapValue.get('etage') != null) etage = mapValue.get('etage').trim();
        
        if (accId != null) {
            Account acc = [SELECT Id, IsPersonAccount, contactParDefaut__c, Type FROM Account WHERE Id=:accId LIMIT 1]; 
            
            //vérification des champs obligatoires
            if (String.isBlank(nom)) {
                System.debug('## Nom vide');
                throw new KubeException(Label.erreur_nom_obligatoire);
            }
            if (String.isBlank(codePostal) || codePostal == null) {
                System.debug('## Code Postal vide');
                throw new KubeException(Label.site_msg_CodePostalRequired);
            }
            if (String.isBlank(ville) || ville == null) {
                System.debug('## Ville vide');
                throw new KubeException(Label.site_msg_VilleRequired);
            }
            // Vérifier la cohérence des champs
            if (String.isNotBlank(nom) && nom.containsAny(Constants.CHECK_OTHER)) {
                System.debug('## Nom invalide');
                throw new KubeException(Label.erreur_nom_invalide);
            }
            if (!Pattern.matches(Constants.REG_CP, codePostal)) {
                System.debug('## Code postal invalide');
                throw new KubeException(Label.site_msg_AddressNotValid);
            }
            if (String.isNotBlank(email) && !Pattern.matches(Constants.REG_EMAIL, email)) {
                System.debug('## Email invalide');
                throw new KubeException(Label.site_msg_EmailNotValid);
            }
            if (String.isNotBlank(fax) && !Pattern.matches(Constants.REG_TEL, fax)) {
                System.debug('## Fax invalide');
                throw new KubeException(Label.site_msg_FaxNotValid);
            }
            if (String.isNotBlank(telephoneMobile) && !Pattern.matches(Constants.REG_TEL, telephoneMobile)) {
                System.debug('## Téléphone Mobile invalide');
                throw new KubeException(Label.site_msg_TelNotValid);
            }
            if (String.isNotBlank(telephoneProfessionnel) && !Pattern.matches(Constants.REG_TEL, telephoneProfessionnel)) {
                System.debug('## Téléphone Pro invalide');
                throw new KubeException(Label.site_msg_TelNotValid);
            }

            // Pour compte Perso
            if(acc.IsPersonAccount){    
                if (String.isNotBlank(prenom) && prenom.containsAny(Constants.CHECK_OTHER)) {
                    System.debug('## Prénom invalide');
                    throw new KubeException(Label.erreur_prenom_invalide);
                }       
                if (String.isNotBlank(telephoneDomicile) && !Pattern.matches(Constants.REG_TEL, telephoneDomicile)) {
                    System.debug('## Téléphone Domicile invalide');
                    throw new KubeException(Label.site_msg_TelNotValid);
                }
                if(String.isNotBlank(etage) && !etage.isNumeric()) {
                    System.debug('## Etage invalide');
                    throw new KubeException(Label.site_msg_EtageNotValid);
                }
            }
            // Pour compte Pro
            else {
                if (String.isNotBlank(phone) && !Pattern.matches(Constants.REG_TEL, phone)) {
                    System.debug('## Téléphone Pro invalide');
                    throw new KubeException(Label.site_msg_TelNotValid);
                }
            }

            // Mise à jour des champs
            try {
                System.debug('## Mise à jour du compte : ' + accId);          
                // Mise à jour des champs pour compte perso
                if(acc.IsPersonAccount){                  
                    acc.Salutation = mapValue.get('civilite');
                    acc.FirstName = prenom;
                    acc.LastName = nom;
                    acc.PersonMailingStreet = mapValue.get('rue');
                    acc.PersonMailingPostalCode = codePostal;
                    acc.PersonMailingCity = ville;
                    acc.etage__c = String.isBlank(etage) ? null : Integer.valueOf(etage);
                    acc.interphone__c = mapValue.get('interphone');
                    acc.PersonHomePhone = telephoneDomicile;
                    acc.PersonMobilePhone = telephoneMobile;
                    acc.PersonOtherPhone = telephoneProfessionnel;
                    acc.PersonEmail = email;
                }
                // Mise à jour du compte pro
                else{
                  acc.Name = nom;
                  acc.BillingStreet = mapValue.get('rue');
                  acc.BillingPostalCode = codePostal;
                  acc.BillingCity = ville;
                  acc.Phone = phone;
                  List<Contact> contacts = new List<Contact>();
                  contacts = [SELECT Id, Email FROM Contact WHERE Id =:acc.contactParDefaut__c LIMIT 1];
                  if(!contacts.isEmpty()){
                      Contact contact = contacts.get(0);
                      System.debug('## Mise à jour du contact : ' + contact.Id);
                      contact.MobilePhone = telephoneMobile;
                      contact.OtherPhone = telephoneProfessionnel;
                      contact.Email = email;
                      update contact;
                    }
                }
                // Champs commun
                acc.complementAdresse__c = mapValue.get('complementAdresse');
                acc.Fax = fax;
                acc.canalPrefere__c = mapValue.get('canalPrefere');
                acc.localisation__Latitude__s = Decimal.valueOf(mapValue.get('localisationLatitude'));
                acc.localisation__Longitude__s = Decimal.valueOf(mapValue.get('localisationLongitude'));
                // Optin (Seulement pour non client)
                if(!(acc.Type == Constants.ACCOUNT_TYPE_CLIENT || acc.Type == Constants.ACCOUNT_TYPE_EXCLIENT)) {
                    acc.optinAdresseEmailKparK__c = Boolean.valueOf(mapValue.get('optinAdresseEmailKparK'));
                    acc.optinAdresseEmailPartenaire__c = Boolean.valueOf(mapValue.get('optinAdresseEmailPartenaire'));
                    acc.optinSMSKparK__c = Boolean.valueOf(mapValue.get('optinSMSKparK'));
                    acc.optinSMSPartenaire__c = Boolean.valueOf(mapValue.get('optinSMSPartenaire'));
                    acc.optinTelephoneDomicileKparK__c = Boolean.valueOf(mapValue.get('optinTelephoneDomicileKparK'));
                    acc.optinTelephoneDomicilePartenaire__c = Boolean.valueOf(mapValue.get('optinTelephoneDomicilePartenaire'));
                    acc.optinTelephoneMobileKparK__c = Boolean.valueOf(mapValue.get('optinTelephoneMobileKparK'));
                    acc.optinTelephoneMobilePartenaire__c = Boolean.valueOf(mapValue.get('optinTelephoneMobilePartenaire'));
                }

                // Mise à jour
                update acc;
                System.debug('### FIN updateAccount');
            } catch(KubeException e) {
                throw e;
            } catch(Exception e) {
                // Envoie de l'email au support client pour erreur
                sendEmailErreurModificationAccount(mapValue, numeroCompte, e);
                message = Label.msg_NotConfirmModificationAccount;
                System.debug('ERREUR # Site Espace Client : Mise à jour de compte (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
                throw new KubeException(message);
            }
        } else {
            message = 'Soumission de la demande impossible';
            throw new KubeException(message);
        }
    }

    /**
    * @description Construction de l'email lors d'une erreur de modification du compte
    * @param mapValue Map des valeurs du formulaire d'édition
    * @param numeroCompte Numéro Salesforce du compte
    * @param ex Exception
    */ 
    public static void sendEmailErreurModificationAccount(Map<String, String> mapValue, String numeroCompte, Exception ex) {
        System.debug('### DEBUT sendEmailErreurModificationAccount');
        try {
            EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Site_EspaceClient_ErreurModificationAccountPerso'];

            // Initialisation des paramètres de remplacement du template de mail
            Map<String, String> mapBodyParams = new Map<String, String> {
                '{!Account.civilite__c}' => mapValue.get('civilite'),
                '{!Account.nom__c}' => mapValue.get('nom'),
                '{!Account.prenom__c}' => mapValue.get('prenom'),
                '{!Account.numeroCompte__c}' => numeroCompte,
                '{!Account.rue__c}' => mapValue.get('rue'),
                '{!Account.codePostal__c}' => mapValue.get('codePostal'),
                '{!Account.ville__c}' => mapValue.get('ville'),
                '{!Account.complementAdresse__c}' => mapValue.get('complementAdresse'),
                '{!Account.etage__c}' => mapValue.get('etage'),
                '{!Account.interphone__c}' => mapValue.get('interphone'),
                '{!Account.email__c}' => mapValue.get('email'),
                '{!Account.telephoneDomicile__c}' => mapValue.get('telephoneDomicile'),
                '{!Account.telephoneMobile__c}' => mapValue.get('telephoneMobile'),
                '{!Account.autreTelephone__c}' => mapValue.get('telephoneProfessionnel'),
                '{!Account.Fax}' => mapValue.get('fax'),
                '{!Account.canalPrefere__c}' => mapValue.get('canalPrefere'),
                '{!Account.optinAdresseEmailKparK__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinAdresseEmailKparK'))),
                '{!Account.optinAdresseEmailPartenaire__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinAdresseEmailPartenaire'))),
                '{!Account.optinSMSKparK__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinSMSKparK'))),
                '{!Account.optinSMSPartenaire__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinSMSPartenaire'))),
                '{!Account.optinTelephoneDomicileKparK__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinTelephoneDomicileKparK'))),
                '{!Account.optinTelephoneDomicilePartenaire__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinTelephoneDomicilePartenaire'))),
                '{!Account.optinTelephoneMobileKparK__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinTelephoneMobileKparK'))),
                '{!Account.optinTelephoneMobilePartenaire__c}' => booleanToString(Boolean.valueOf(mapValue.get('optinTelephoneMobilePartenaire'))),
                '{!Account.Localisation__latitude__s}' => mapValue.get('localisationLatitude'),
                '{!Account.Localisation__longitude__s}' => mapValue.get('localisationLongitude'),
                '{!ExceptionMessage}' => ex.getMessage(),
                '{!ExceptionLigne}' => String.valueOf(ex.getLineNumber())
            };

            EmailMessageWrapper emailWrapper = new EmailMessageWrapper(null, EMAILSUPPORT, null, null, emailTemplate.Subject, null, emailTemplate.Body, emailTemplate.HtmlValue, mapBodyParams);

            // Création du mail
            List<Messaging.SingleEmailmessage> listSingleEmailMessages = new List<Messaging.SingleEmailmessage> ();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Expéditeur
            mail.setOrgWideEmailAddressId(orgWideEmailAddress.Id);
            // Destinataire
            if (emailWrapper.ToAddress != null && emailWrapper.ToAddress.length() > 0)
            mail.setToAddresses(new String[] { emailWrapper.ToAddress });
            else
            mail.setTargetObjectId(emailWrapper.ToAddressId);
            // BCC
            if (emailWrapper.BccAddress != null && emailWrapper.BccAddress.length() > 0)
            mail.setBccAddresses(new String[] { emailWrapper.BccAddress });
            // Sujet
            String subject = null;
            if (emailWrapper.Subject != null && emailWrapper.Subject.length() > 0) {
                mail.setSubject(emailWrapper.Subject);
                subject = emailWrapper.Subject;
            }
            else
            subject = '';
            mail.setSubject(subject);
            // BODY
            String htmlBody = emailWrapper.HtmlValue;
            String plainBody = emailWrapper.Body;
            for (String key : emailWrapper.ParameterBodyMap.keySet()) {
                htmlBody = htmlBody.replace(key, (emailWrapper.ParameterBodyMap.get(key) == null) ? '' : emailWrapper.ParameterBodyMap.get(key));
                htmlBody = htmlBody.replace(']]>', '');
                htmlBody = htmlBody.replace('<![CDATA[', '');
                plainBody = plainBody.replace(key, (emailWrapper.ParameterBodyMap.get(key) == null) ? '' : emailWrapper.ParameterBodyMap.get(key));
            }
            mail.setHtmlBody(htmlBody);
            mail.setPlainTextBody(plainBody);
            mail.setSaveAsActivity(false);
            System.debug('HTML : ' + htmlBody);
            System.debug('TEXT : ' + plainBody);

            // Envoie de l'email (sauf si test)
            listSingleEmailMessages.add(mail);
            if (!Test.isRunningTest()) {
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(listSingleEmailMessages);
                System.debug(result);
            }
            System.debug('### FIN sendEmailErreurModificationAccount');
        } catch(Exception e) {
            System.debug(e);
        }
    }

    /**
    * @description Méthode d'affichage de la page mot de passe perdu ou génération du mot de passe client
    * @return PageReference Page Visualforce
    */ 
    public PageReference displayGeneratePasswordPage() {
        PageReference newPasswordPage = Page.VF_Site_EspaceClient_ForgotPassword;
        newPasswordPage.setRedirect(true);
        return newPasswordPage;
    }

    /**
    * @description Méthode de génération du mot de passe client
    * @return PageReference Page Visualforce
    */ 
    public PageReference generateNewPassword() {
        System.debug('### DEBUT generateNewPassword');
        log.clear();

        Boolean enablePasswordEmail = (PropertiesUtils.getBooleanValue('espaceclient.email.password', false)) ? true : false;
        String message = '';
        passwordResetMsg = '';

        // Si l'utilisateur n'a saisi aucun email ou numéro de compte
        if (String.isBlank(user)) {
            log.addErrorMessage(Label.msg_LoginRequiredForEmail);
        } 
        /*else if (String.isNotBlank(mail) && !Pattern.matches(Constants.REG_EMAIL, mail)) {
            log.addErrorMessage(Label.site_msg_EmailNotValid);
        }*/

        // Sinon
        else {
            String searchFilter = '"'+user+'"';
            System.debug('## searchFilter: '+searchFilter);
            List<List<SObject>> searchList = [FIND :searchFilter IN ALL FIELDS RETURNING Account(Id, email__c, AccountNumber WHERE Type IN ('Client', 'Ex-client'))];
            // Si aucun compte n'est retourné
            if (searchList==null || searchList.isEmpty() || searchList[0].isEmpty()) {
                log.addErrorMessage(Label.espaceclient_msg_NoAccounts);
            }
            // Si plusieurs comptes sont retournés
            else if (searchList[0].size() > 1) {
                log.addWarnMessage(Label.espaceclient_msg_MultiAccounts);
            }
            // Sinon
            else {
                List<Account> accounts = ((List<Account>)searchList[0]);
                // Si aucune adresse email n'est configuré sur ce compte
                if (String.isBlank(accounts.get(0).email__c)) {
                    System.debug('## MDP');
                    message = Label.msg_lostPasswordEmailError + '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
                    + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
                    log.addErrorMessage(message);
                    enablePasswordEmail=false;
                }
                // Sinon
                else {
                    System.debug('## MDP et Email');
                    passwordResetMsg = String.format(Label.msg_lostPasswordGenerated, new List<String>{accounts.get(0).email__c});
                    passwordChanged=true;
                }
                ID jobID = System.enqueueJob(new QA_GenerateAccountPassword(accounts, enablePasswordEmail, false, false));
                System.debug('## Job Id: '+jobID );
                PageReference passwordSuccess = Page.VF_Site_EspaceClient_ForgotPassword;
                passwordSuccess.getParameters().put('passwordChange', 'success');
                passwordSuccess.getParameters().put('message',passwordResetMsg);
                clearSessionCookie(); // Suppression du cookie
                return passwordSuccess;
            }
        }
        System.debug('### FIN generateNewPassword');
        return null;
    }
    
    /**
    * @description ONGLET CONTRATS : Récupération des contrats du client
    * @return List<Contrat> Liste des contrats du client
    */
    public List<Contrat> getContratsClientKube2() {
        System.debug('### DEBUT getContratsClientKube2');
        String message = '';
        log.clear();

        try {
            contratsClientEnCours.clear();
            contratsClientTermine.clear();
            // Récupération des contrats/devis/projets du client
            List<Contrat> contratsObjectClient = new List<Contrat> ();
            for (KContrat__c Kcontrat :[SELECT Id, Name, nomVendeur__c, numeroContrat__c, dateResiliation__c, motifResiliation__c, produits__c, devis__c, depot__c, chantier__r.Id,
                 chantier__r.rue__c, chantier__r.codePostal__c, chantier__r.ville__c, chantier__r.pays__c, compte__r.rue__c, compte__r.codePostal__c, compte__r.ville__c, compte__r.pays__c,
                 devis__r.Status, devis__r.Total_TTC_devis__c, nombreInstallations__c, nombreInterventionsSAV__c, nombreMetrages__c, nbSAVTotal__c,
                 devis__r.modeFinancement__c, libelleStatutContrat__c, dateSignature__c, montantTTC__c, intervDerniereInstallation__c, intervDernierMetrage__c, intervDerniereInterventionSAV__c,
                 premierMetrage__c, premiereInstallation__c, prochainMetrage__c, prochaineInstallation__c, derniereInstallation__c, dernierMetrage__c, prochainSAV__c, derniereInterventionSAV__c,
                 debutDernierSAV__c, devis__r.tvaReduite__c, devis__r.tvaIntermediaire__c, devis__r.tvaNormal__c, etape__c, prochaineEtape__c, compte__r.Sectorisation__r.libelleDepot__c
                 FROM KContrat__c WHERE compte__c = :accountInitial.Id ORDER BY dateSignature__c DESC LIMIT 10]) {

                Contrat contrat = new Contrat();
                contrat.Id = Kcontrat.Id;
                contrat.numeroContrat = (Kcontrat.numeroContrat__c == null) ? '' : Kcontrat.numeroContrat__c;
                contrat.nomContrat = (Kcontrat.Name == null) ? '' : Kcontrat.Name;
                contrat.nomVendeur = (Kcontrat.nomVendeur__c == null) ? '' : Kcontrat.nomVendeur__c;
                contrat.statut = (Kcontrat.libelleStatutContrat__c == null) ? '' : Kcontrat.libelleStatutContrat__c;
                contrat.dateDeSignature = (Kcontrat.dateSignature__c == null) ? null : Kcontrat.dateSignature__c;
                contrat.dateDeResiliation = (Kcontrat.dateResiliation__c == null) ? null : Kcontrat.dateResiliation__c;
                contrat.motifDeResiliation = (Kcontrat.motifResiliation__c == null) ? '' : Kcontrat.motifResiliation__c;
                contrat.modeDeFinancement = (Kcontrat.devis__r.modeFinancement__c == null) ? '' : Kcontrat.devis__r.modeFinancement__c;
                contrat.montantDevisTTC = (Kcontrat.devis__r.Total_TTC_devis__c == null) ? '0' : Kcontrat.devis__r.Total_TTC_devis__c.setScale(2).format();
                contrat.statutDevis = (Kcontrat.devis__r.Status == null) ? '' : Kcontrat.devis__r.Status;
                contrat.montantTTC = (Kcontrat.montantTTC__c == null) ? 0 : Kcontrat.montantTTC__c;
                contrat.produits = (Kcontrat.produits__c == null) ? '' : Kcontrat.produits__c;
                contrat.chantier = (Kcontrat.chantier__r == null) ? null : Kcontrat.chantier__r;
                contrat.compte = (Kcontrat.compte__r == null) ? null : Kcontrat.compte__r;
                contrat.devis = (Kcontrat.devis__r == null) ? null : Kcontrat.devis__r;
                contrat.nomDepot = (Kcontrat.compte__r.Sectorisation__r.libelleDepot__c == null) ? '' : Kcontrat.compte__r.Sectorisation__r.libelleDepot__c;
                contrat.etapeActuelle = (Kcontrat.etape__c == null) ? '' : Kcontrat.etape__c;
                contrat.prochaineEtape = (Kcontrat.prochaineEtape__c == null) ? '' : Kcontrat.prochaineEtape__c;
                contrat.intervDernierMetrage = (Kcontrat.intervDernierMetrage__c == null) ? '' : ((Kcontrat.intervDernierMetrage__c.split(' ').size() == 1) ? Kcontrat.intervDernierMetrage__c.split(' ') [0] : Kcontrat.intervDernierMetrage__c.split(' ') [1]);
                contrat.intervDerniereInterventionSAV = (Kcontrat.intervDerniereInterventionSAV__c == null) ? '' : ((Kcontrat.intervDerniereInterventionSAV__c.split(' ').size() == 1) ? Kcontrat.intervDerniereInterventionSAV__c.split(' ') [0] : Kcontrat.intervDerniereInterventionSAV__c.split(' ') [1]);
                contrat.dateDernierMetrage = Kcontrat.dernierMetrage__c;
                contrat.nombreMetrages = Kcontrat.nombreMetrages__c;
                contrat.dateProchainMetrage = Kcontrat.prochainMetrage__c;
                contrat.dateDernierInstallation = Kcontrat.derniereInstallation__c;
                contrat.nombreInstallations = Kcontrat.nombreInstallations__c;
                contrat.dateProchainInstallation = Kcontrat.prochaineInstallation__c;
                contrat.dateDebutDernierSAV = Kcontrat.debutDernierSAV__c;
                contrat.nbSAVTotal = Kcontrat.nbSAVTotal__c;
                contrat.dateDerniereInterventionSAV = Kcontrat.derniereInterventionSAV__c;
                contrat.nombreInterventionsSAV = Kcontrat.nombreInterventionsSAV__c;
                contrat.dateProchainSAV = Kcontrat.prochainSAV__c;
                contrat.tvaReduite = (Kcontrat.devis__r.tvaReduite__c == null) ? 0 : Kcontrat.devis__r.tvaReduite__c;
                contrat.tvaIntermediaire = (Kcontrat.devis__r.tvaIntermediaire__c == null) ? 0 : Kcontrat.devis__r.tvaIntermediaire__c;
                contrat.tvaNormal = (Kcontrat.devis__r.tvaNormal__c == null) ? 0 : Kcontrat.devis__r.tvaNormal__c;
                contrat.contratInfos = Kcontrat;

                // Application du style des panels dans l'onglet "Mes projets"
                Integer numEtape = 0;
                // Style par défaut
                for (Integer i = 0; i < 6; i++)
                contrat.panelsType.add('panel-state-default');
                if (contrat.etapeActuelle == 'Signature du contrat') numEtape = 0;
                if (contrat.etapeActuelle == 'Métrage') numEtape = 1;
                if (contrat.etapeActuelle == 'Commande usine') numEtape = 2;
                if (contrat.etapeActuelle == 'Livraison au dépôt') numEtape = 3;
                if (contrat.etapeActuelle == 'Installation') numEtape = 4;
                if (contrat.etapeActuelle == 'Service après vente' || contrat.etapeActuelle == 'Terminé') numEtape = 5;
                // Application des styles en cours et terminés
                for (Integer i = 0; i < numEtape; i++)
                contrat.panelsType[i] = 'panel-state-success';
                contrat.panelsType[numEtape] = 'panel-state-current';

                // Produits du contract (si devis)
                if (Kcontrat.devis__c != null) {
                    List<QuoteLineItem> qliList = DAL.getQuoteLineItemList(Kcontrat.devis__c, 'SortOrder, PricebookEntry.Product2.Name, NumLigneText__c');
                    contrat.produitsContrat = qliList;
                }
                // Vérifie si projet en cours ou terminé
                if (contrat.prochaineEtape != '') contratsClientEnCours.add(contrat);
                else contratsClientTermine.add(contrat);
                contratsObjectClient.add(contrat);
            }
            if (!contratsObjectClient.isEmpty()) {
                premierContratId = contratsObjectClient[0].Id;
            }
            System.debug('### FIN getContratsClientKube2');
            return contratsObjectClient;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération contrats (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }
    
    /**
    * @description ONGLET CONTRATS : Récupération des commandes du client
    * @return List<Contrat> Liste des commandes du client
    */
    public List<Contrat> getOrderClientKube3() {
        System.debug('### DEBUT getOrderClientKube3');
        String message = '';
        log.clear();

        try {
            contratsClientEnCours.clear();
            contratsClientTermine.clear();
            // Récupération des commandes/devis/projets du client
            String customerOrderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
            List<Contrat> contratsObjectClient = new List<Contrat> ();
            for (Order commande : [SELECT Id, Name, Owner.Name, OrderNumber, cancellingDate__c, cancellingReason__c, cancellingReason__r.Name, QuoteId, serviceEntity__c, 
                chantier__c, chantier__r.Id, chantier__r.rue__c, chantier__r.codePostal__c, chantier__r.ville__c, chantier__r.pays__c,
                AccountId, Account.rue__c, Account.codePostal__c, Account.ville__c, Account.pays__c,
                Quote.Status, Quote.Total_TTC_devis__c, Quote.tvaReduite__c, Quote.tvaIntermediaire__c, Quote.tvaNormal__c,
                SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.totalAmount__c, 
                SBQQ__Quote__r.MontantTVAReduite__c, SBQQ__Quote__r.MontantTVAIntermediaire__c, SBQQ__Quote__r.MontantTVAFort__c,
                financingMethod__c, financingMethod__r.Name, toLabel(Status), EffectiveDate, amount__c, stageName__c, serviceEntity__r.Name
                FROM Order WHERE AccountId = :accountInitial.Id AND RecordTypeId = :customerOrderRTId ORDER BY EffectiveDate DESC LIMIT 10]) {

                Contrat contrat = new Contrat();
                contrat.Id = commande.Id;
                contrat.numeroContrat = (String.isBlank(commande.OrderNumber)) ? '' : commande.OrderNumber;
                contrat.nomContrat = (String.isBlank(commande.Name)) ? '' : commande.Name;
                contrat.nomVendeur = (String.isBlank(commande.Owner.Name)) ? '' : commande.Owner.Name;
                contrat.statut = (String.isBlank(commande.Status)) ? '' : commande.Status;
                contrat.dateDeSignature = commande.EffectiveDate;
                contrat.dateDeResiliation = commande.cancellingDate__c;
                contrat.motifDeResiliation = (String.isBlank(commande.cancellingReason__c)) ? '' : commande.cancellingReason__r.Name;
                contrat.modeDeFinancement = (String.isBlank(commande.financingMethod__c)) ? '' : commande.financingMethod__r.Name;
                contrat.montantTTC = (commande.amount__c == null) ? 0 : commande.amount__c;
                contrat.chantier = (String.isBlank(commande.chantier__c)) ? null : commande.chantier__r;
                contrat.compte = (String.isBlank(commande.AccountId)) ? null : commande.Account;
                contrat.devis = (String.isBlank(commande.QuoteId)) ? null : commande.Quote;
                contrat.devisCPQ = (String.isBlank(commande.SBQQ__Quote__c)) ? null : commande.SBQQ__Quote__r;
                contrat.nomDepot = (String.isBlank(commande.serviceEntity__c)) ? '' : commande.serviceEntity__r.Name;
                contrat.commmandeInfos = commande;

                // Rendez vous de service
                for(ServiceAppointment sa : [SELECT Id, workTypeName__c, SchedStartTime, ActualStartTime, Status, 
                                                firstPrincipalResource__r.ServiceResource.user__r.Name FROM ServiceAppointment 
                                            WHERE customerOrder__c = :contrat.Id AND Status != :Constants.RDV_FSL_DEMANDE AND Status != :Constants.RDV_FSL_ANNULE ORDER BY SchedStartTime]) {
                    // Contrôle
                    if(sa.workTypeName__c == Constants.ACTIVITY_TYPE_CONTROL) {
                        contrat.nombreMetrages = (contrat.nombreMetrages == null) ? 1 : contrat.nombreMetrages+1;
                        if(sa.Status == Constants.RDV_FSL_TERMINE || sa.Status == Constants.RDV_FSL_DEBRIEFE) {
                            contrat.dateDernierMetrage = sa.ActualStartTime.date();
                            contrat.intervDernierMetrage = sa.firstPrincipalResource__r.ServiceResource.user__r.Name;
                        }
                        if(sa.Status != Constants.RDV_FSL_TERMINE || sa.Status != Constants.RDV_FSL_DEBRIEFE) {
                            contrat.dateProchainMetrage = sa.SchedStartTime;
                        }
                    }
                    // Intervention Pose
                    if(sa.workTypeName__c == Constants.ACTIVITY_TYPE_INTERVENTION) {
                        contrat.nombreInstallations = (contrat.nombreInstallations == null) ? 1 : contrat.nombreInstallations+1;
                        if(sa.Status == Constants.RDV_FSL_TERMINE || sa.Status == Constants.RDV_FSL_DEBRIEFE) {
                            contrat.dateDernierInstallation = sa.ActualStartTime.date();
                        }
                        if(sa.Status != Constants.RDV_FSL_TERMINE || sa.Status != Constants.RDV_FSL_DEBRIEFE) {
                            contrat.dateProchainInstallation = sa.SchedStartTime;
                        }
                    }
                    // Diagnostic
                    if(sa.workTypeName__c == Constants.ACTIVITY_TYPE_INTERVENTION) {
                        contrat.nombreInterventionsSAV = (contrat.nombreInterventionsSAV == null) ? 1 : contrat.nombreInterventionsSAV+1;
                        if(sa.Status == Constants.RDV_FSL_TERMINE || sa.Status == Constants.RDV_FSL_DEBRIEFE) {
                            contrat.dateDerniereInterventionSAV = sa.ActualStartTime.date();
                            contrat.intervDerniereInterventionSAV = sa.firstPrincipalResource__r.ServiceResource.user__r.Name;
                        }
                        if(sa.Status != Constants.RDV_FSL_TERMINE || sa.Status != Constants.RDV_FSL_DEBRIEFE) {
                            contrat.dateProchainSAV = sa.SchedStartTime;
                        }
                    }
                }

                // SAV
                for(Case reqCase : [SELECT Id, CreatedDate FROM Case WHERE customerOrder__c = :contrat.Id ORDER BY CreatedDate]) {
                    contrat.nbSAVTotal = (contrat.nbSAVTotal == null) ? 1 : contrat.nbSAVTotal+1;
                    contrat.dateDebutDernierSAV = reqCase.CreatedDate.date();
                }

                // Devis
                if(String.isNotBlank(commande.SBQQ__Quote__c)) {
                    contrat.statutDevis = (String.isBlank(commande.SBQQ__Quote__r.SBQQ__Status__c)) ? '' : commande.SBQQ__Quote__r.SBQQ__Status__c;
                    contrat.montantDevisTTC = (commande.SBQQ__Quote__r.totalAmount__c == null) ? '0' : commande.SBQQ__Quote__r.totalAmount__c.setScale(2).format();
                    contrat.tvaReduite = (commande.SBQQ__Quote__r.MontantTVAReduite__c == null) ? 0 : commande.SBQQ__Quote__r.MontantTVAReduite__c;
                    contrat.tvaIntermediaire = (commande.SBQQ__Quote__r.MontantTVAIntermediaire__c == null) ? 0 : commande.SBQQ__Quote__r.MontantTVAIntermediaire__c;
                    contrat.tvaNormal = (commande.SBQQ__Quote__r.MontantTVAFort__c == null) ? 0 : commande.SBQQ__Quote__r.MontantTVAFort__c;
                } else if(String.isNotBlank(commande.QuoteId)) {            
                    contrat.statutDevis = (String.isBlank(commande.Quote.Status)) ? '' : commande.Quote.Status;
                    contrat.montantDevisTTC = (commande.Quote.Total_TTC_devis__c == null) ? '0' : commande.Quote.Total_TTC_devis__c.setScale(2).format();       
                    contrat.tvaReduite = (commande.Quote.tvaReduite__c == null) ? 0 : commande.Quote.tvaReduite__c;
                    contrat.tvaIntermediaire = (commande.Quote.tvaIntermediaire__c == null) ? 0 : commande.Quote.tvaIntermediaire__c;
                    contrat.tvaNormal = (commande.Quote.tvaNormal__c == null) ? 0 : commande.Quote.tvaNormal__c;
                }
                
                // Gestion des étapes et prochaines étapes
                if(commande.Status == 'Annulé') {
                    contrat.etapeActuelle = 'Résilié';
                    contrat.prochaineEtape = '';
                }if(commande.stageName__c == 'Enregistrement') {
                    contrat.etapeActuelle = 'Signature du contrat';
                    contrat.prochaineEtape = 'Métrage';
                } else if(commande.stageName__c == 'Contrôle') {
                    contrat.etapeActuelle = 'Métrage';
                    contrat.prochaineEtape = 'Commande';
                } else if(commande.stageName__c == 'Commande' && commande.Status != 'Expédié') {
                    contrat.etapeActuelle = 'Commande usine';
                    contrat.prochaineEtape = 'Livraison au dépôt';
                } else if(commande.stageName__c == 'Commande' && commande.Status == 'Expédié') {
                    contrat.etapeActuelle = 'Livraison au dépôt';
                    contrat.prochaineEtape = 'Installation';
                } else if(commande.stageName__c == 'Installation') {
                    contrat.etapeActuelle = 'Installation';
                    contrat.prochaineEtape = 'Terminé';
                } if(commande.stageName__c == 'SAV') {
                    contrat.etapeActuelle = 'Service après vente';
                    contrat.prochaineEtape = 'Terminé';
                } else if(commande.Status == 'Clôturé') {
                    contrat.etapeActuelle = 'Terminé';
                    contrat.prochaineEtape = '';
                }

                // Application du style des panels dans l'onglet "Mes projets"
                Integer numEtape = 0;
                // Style par défaut
                for (Integer i = 0; i < 6; i++) {
                    contrat.panelsType.add('panel-state-default');
                }
                if (contrat.etapeActuelle == 'Signature du contrat') numEtape = 0;
                if (contrat.etapeActuelle == 'Métrage') numEtape = 1;
                if (contrat.etapeActuelle == 'Commande usine') numEtape = 2;
                if (contrat.etapeActuelle == 'Livraison au dépôt') numEtape = 3;
                if (contrat.etapeActuelle == 'Installation') numEtape = 4;
                if (contrat.etapeActuelle == 'Service après vente' || contrat.etapeActuelle == 'Terminé') numEtape = 5;
                // Application des styles en cours et terminés
                for (Integer i = 0; i < numEtape; i++) {
                    contrat.panelsType[i] = 'panel-state-success';
                }
                contrat.panelsType[numEtape] = 'panel-state-current';

                // Produits de la commande
                List<OrderItem> orderItemList = [SELECT Id, Quantity, UnitPrice, TotalPrice, name__c, reference__c, Product2.Idvisuel__c
                                                    FROM OrderItem WHERE OrderId = :commande.Id AND status__c != 'Annulé' AND parentOrderItem__c = null
                                                    ORDER BY name__c];
                contrat.produitsCommande = orderItemList;
                
                // Vérifie si projet en cours ou terminé
                if (contrat.prochaineEtape != '') {
                    contratsClientEnCours.add(contrat);
                } else {
                    contratsClientTermine.add(contrat);
                }
                contratsObjectClient.add(contrat);
            }
            if (!contratsObjectClient.isEmpty()) {
                premierContratId = contratsObjectClient[0].Id;
            }
            System.debug('### FIN getOrderClientKube3');
            return contratsObjectClient;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération commandes (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }

    /**
    * @description ONGLET BESOIN D'AIDE : Récupération des chantiers du client
    * @return List<SelectOption> Liste des noms des chantier du client
    */
    public List<SelectOption> getChantiersClient() {
        System.debug('### DEBUT getChantiersClient');
        String message = '';
        log.clear();

        try {
            List<SelectOption> options = new List<SelectOption> ();
            // Construction de la liste des chantiers
            for (Chantier__c chantier :[SELECT Id, numeroChantier__c, rue__c, codePostal__c, ville__c
                                        FROM Chantier__c WHERE proprietaire__c = :accountInitial.Id OR locataire__c = :accountInitial.Id OR occupant__c = :accountInitial.Id
                                        OR autreProprietaire__c = :accountInitial.Id OR autreOccupant__c = :accountInitial.Id OR autreLocataire__c = :accountInitial.Id
                                        ORDER BY CreatedDate DESC]) {
                String label = chantier.numeroChantier__c + ' (' + chantier.rue__c + ', ' + chantier.codePostal__c + ' ' + chantier.ville__c + ')';
                options.add(new SelectOption(chantier.Id, label));
            }
            System.debug('### FIN getChantiersClient');
            return options;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération chantiers (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }
        
    /**
    * @description ONGLET PARRAINAGE : Récupération des filleuls du client
    * @return List<Filleul> Liste des filleuls du client
    */
    public List<Filleul> getFilleulsClient() {
        System.debug('### DEBUT getFilleulsClient');
        String message = '';
        log.clear();

        try {
            filleulsClient.clear();
            List<Filleul> filleulsList = new List<Filleul>();
            for(Account accFi : [SELECT Id, nom__c, prenom__c, AccountNumber, Type, dateAssociationParrain__c, typeDotation__c, 
                                    CreatedDate, dateEnvoiDotationParrain__c FROM Account WHERE  parrain__c = :accountInitial.Id]) {
                Filleul fill=new Filleul(accFi);
                filleulsList.add(fill);
                if(fill.Type == 'Client') filleulsClient.add(fill);
            }   
            System.debug('### FIN getFilleulsClient');
            return filleulsList;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération filleuls (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }

    /**
    * @description ONGLET BESOIN D'AIDE : Récupération des requêtes du client
    * @return Map<Id, Demande> Liste des demandes du client
    */
    public Map<Id,Demande> getDemandesClient() {
        System.debug('### DEBUT getDemandesClient');
        String message = '';
        log.clear();

        try {            
            List<String> rtIdList = new List<String>();
            rtIdList.add(DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT));
            rtIdList.add(DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RELATIONCLIENT_RT));
            rtIdList.add(DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_AUTRE_RT));

            // Récupération des requêtes clients
            Map<Id,Demande> requetesObjectClient = new Map<Id,Demande>();
            for(Case requete : 
                [SELECT Id, CaseNumber, AccountId, Chantier__c, Type, Description, CreatedDate, ClosedDate,
                        Status, typeDeRendezVous__c, motif__c, Subject, typeResolution__c, datePrevisionnelleResolution__c,
                        Chantier__r.numeroChantier__c, Chantier__r.rue__c, Chantier__r.ville__c, Chantier__r.codePostal__c
                        FROM Case
                        WHERE AccountId = :accountInitial.Id AND RecordTypeId IN :rtIdList]
            ){
                Demande dmd = new Demande(requete);
                requetesObjectClient.put(dmd.id, dmd);
            }
            System.debug('## Case: '+requetesObjectClient);
            System.debug('### FIN getDemandesClient');
            return requetesObjectClient;
        }
        catch (Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération demandes (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - ONGLET BESOIN D'AIDE : Création d'une requête
    * @param accId Id Salesforce du compte
    * @param chantierId Id Salesforce du chantier
    * @param selectedTypeDemande Type de la demande
    * @param selectedTypeDeRDV Type du RDV
    * @param selectedDescriptionDemande Description de la demande
    */
    @RemoteAction
    public static String creationDemande(String accId, String chantierId, String selectedTypeDemande, String selectedMotif, String selectedTypeDeRDV, String selectedDescriptionDemande) {
        System.debug('### DEBUT creationDemande');
        String message = '';

        try {
            // Vérification chantier
            if (String.isBlank(chantierId)) {
                System.debug('## Chantier vide');
                throw new KubeException(Label.espaceclient_msg_CaseChantierRequired);
            }
            // Vérification description
            if (String.isBlank(selectedDescriptionDemande)) {
                System.debug('## Description vide');
                throw new KubeException(Label.espaceclient_msg_CaseDescriptionRequired);
            }

            //Détermination du RecordTypeId à partir du Type
            System.debug('## Type: ' + selectedTypeDemande);
            String recordType = MappingUtils.getCaseRecordTypeFromType(selectedTypeDemande);
            if(String.isBlank(recordType)) {
                System.debug('## RecordType introuvable à partir du Type de demande (' + selectedTypeDemande + ')');
                throw new KubeException(Label.espaceclient_msg_CaseTypeUnknown);
            }
            String recordType_Id = DAL.getRecordTypeIdByDevName('Case', recordType);
            if(String.isBlank(recordType)) {
                System.debug('## RecordTypeId introuvable à partir du RecordType ' + recordType);
                throw new KubeException(Label.espaceclient_msg_CaseTypeUnknown);
            }

            // Insertion requête
            System.debug('## Add case - Account : ' + accId);
            Account acc = [SELECT Id, Name, contactParDefaut__c, PersonEmail, PersonContactId FROM Account WHERE Id = :accId];
            Case newCase = new Case(AccountId = accId,
                                    chantier__c = chantierId,
                                    RecordTypeId = recordType_Id,
                                    Type = selectedTypeDemande,
                                    motif__c = selectedMotif,
                                    typeDeRendezVous__c = selectedTypeDeRDV,
                                    Description = selectedDescriptionDemande,
                                    Origin = 'Espace Client');
            newCase.ContactId = (acc.contactParDefaut__c == null) ? acc.PersonContactId : acc.contactParDefaut__c;
            // Récupération des règles d'assignement des requêtes
            AssignmentRule AR = [SELECT id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            if(AR !=null) {
                // Création de DMLOptions pour la règle
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
                newCase.setOptions(dmlOpts);
            }
            insert newCase;
            // Retour
            System.debug('### FIN creationDemande');
            return newCase.Id;
        } catch(KubeException e) {
            System.debug('ERREUR # Site Espace Client : Création demande (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
            + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
            System.debug('ERREUR # Site Espace Client : Création demande (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw new KubeException(message);
        }
    }

    /**
    * @description ONGLET GESTION DES DEMANDES : Récupération des commentaires de requêtes
    * @param caseId Id de la requête
    * @return List<Commentaire> Liste des commentaires de la requête
    */
    @TestVisible
    private List<Commentaire> retrieveComments(Id caseId) {
        List<Commentaire> commentaires = new List<Commentaire>();
        log.clear();
        try {
            for(CaseComment comment : [SELECT Id, CreatedById, CreatedDate, CommentBody 
                                           FROM CaseComment WHERE ParentId = :caseId AND IsPublished = true ORDER BY CreatedDate ASC] ){
                Commentaire com = new Commentaire(comment);
                commentaires.add(com);
            }
        }
        catch(Exception e) {
            String message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération commentaires (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
        return commentaires;
    }

    /**
    * @description ONGLET GESTION DES DEMANDES : Récupération des pièces jointes de requêtes
    * @param caseId Id de la requête
    * @return List<PieceJointe> Liste des pièces jointes de la requête
    */
    @TestVisible
    private List<PieceJointe> retrieveCaseAttachments(Id caseId) {
        List<PieceJointe> atts = new List<PieceJointe>();
        log.clear();
        try {
            for(Attachment attachment : [SELECT Body,ContentType,CreatedDate,Id,Name 
                                            FROM Attachment WHERE ParentId = :caseId AND IsPrivate=false ORDER BY CreatedDate DESC] ) {
                PieceJointe att = new PieceJointe(attachment);
                atts.add(att);
            }
        }
        catch(Exception e) {
            String message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération pièces jointes (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
        return atts;
    }

    /**
    * @description REMOTEACTION - ONGLET GESTION DES DEMANDES : Insère un nouveau commentaire à la requête 
    * @param caseId Id de la requête 
    * @param newComment Contenu du commentaire du client
    */
    @RemoteAction
    public static void postComment(String caseId, String newComment) {
        String message = '';
        if(String.isBlank(newComment)) {
            throw new KubeException(Label.espaceclient_msg_NoCaseComment);
        }

        try {
            CaseComment comment = new CaseComment();
            comment.CommentBody = newComment;
            comment.ParentId = caseId;
            comment.IsPublished = true; //pour le rendre visible au client
            insert comment;
        }
        catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
            + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
            System.debug('ERREUR # Site Espace Client : Ajout commentaire (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw new KubeException(message);
        }
    }

    /**
    * @description REMOTEACTION - ONGLET GESTION DES DEMANDES : Clotûre la demande "demandetoDisplay"
    * Peut également poster un commentaire associé à la requête pour accompagner le changement de statut. 
    * Le commentaire "statusChangeComment" est facultatif.
    * @param caseId Id de la requête à cloturer
    * @param statusChangeComment Contenu du commentaire du client
    */
    @RemoteAction
    public static void cloreDemande(String caseId, String statusChangeComment) {
        String message = '';
        try {
            // Ajout du commentaire
            if(String.isNotBlank(statusChangeComment)) {
                Ctrl_Site_EspaceClient.postComment(caseId,statusChangeComment); 
            }
            // Modification du statut
            Case caseToClose = [SELECT Id, Status FROM Case WHERE Id = :caseId];
            caseToClose.Status = Constants.REQUETE_STATUS_CLOSED;
            update caseToClose;
        }
        catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
            + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
            System.debug('ERREUR # Site Espace Client : Post commentaire (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw new KubeException(message);
        }
    }

    /**
    * @description REMOTEACTION - ONGLET GESTION DES DEMANDES : Rouvre la demande "demandetoDisplay"
    * Poste également un commentaire associé à la requête pour accompagner le changement de statut. 
    * Un commentaire est obligatoire (statusChangeComment) sinon la réouverture est annulée.
    * @param caseId Id de la requête à rouvrir
    * @param statusChangeComment Contenu du commentaire du client
    */
    @RemoteAction
    public static void rouvrirDemande(String caseId, String statusChangeComment) {
        String message = '';
        if(String.isBlank(statusChangeComment)) {
            throw new KubeException(Label.espaceclient_msg_CommentRequiredForCaseOpening);
        }

        try {
            Ctrl_Site_EspaceClient.postComment(caseId,statusChangeComment); // Ajout du commentaire
            // Modification du statut
            Case caseToClose = [SELECT Id, Status FROM Case WHERE Id = :caseId];
            caseToClose.Status = Constants.REQUETE_STATUS_INPROGRESS;
            update caseToClose;
        }
        catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
            + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
            System.debug('ERREUR # Site Espace Client : Post commentaire (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw new KubeException(message);
        }
    }   

    /**
     *
     *   COMPOSANT NOTIFICATION : Récupération des notifications du client
     *   Type de notification :
     *   - Nouveau RDV (métrage, installation, etc.)
     *   - Modification ou annulation de RDV (métrage, installation, etc.)
     *   - Changement de dépôt
     *   - Changement de statut (contrat)
     *
     **/
    public List<Notification> getNotificationsClient() {
        System.debug('### DEBUT getNotificationsClient');
        String message = '';
        log.clear();

        try {
            // Récupération des contrats/devis/projets du client
            List<Notification> notificationObjetClient = new List<Notification> ();
            /*
              // Id de tous les contrats du clients
              List<String> contratsId = new List<String>();
              for(Contrat contratClient : contratsClient) {
              contratsId.add(contratClient.Id);
              }

              // Liste des modifications du contrat
              Integer index = 0;
              System.debug('### Date de connexion : ' + account.dateConnexion);
              for(KContrat__History contratHistory : [SELECT CreatedDate, Field, Id, NewValue, OldValue, ParentId, Parent.numeroContrat__c
              FROM KContrat__History WHERE ParentId IN :contratsId]) {
              // Initialiation
              Notification notif = new Notification();
              String value = '';
              String text = '';
              String fieldName = '';
              // Nom du champ
              if(contratHistory.Field == 'created')
              fieldName = 'createddate';
              else
              fieldName = contratHistory.Field;
              // Texte de la notification
              if(contratHistory.Field == 'depot__c') text = 'Centre technique';
              if(contratHistory.Field == 'libelleStatutContrat__c') text = 'Statut';
              if(contratHistory.Field == 'prochaineInstallation__c') text = 'RDV pose';
              if(contratHistory.Field == 'prochainMetrage__c') text = 'RDV métrage';
              if(contratHistory.Field == 'prochainSAV__c') text = 'RDV SAV';
              if(contratHistory.Field == 'created') text = 'Création';
              // Valeur de la notification
              if(contratHistory.NewValue == null && contratHistory.OldValue != null && text.contains('RDV'))
              value = 'Annulation';
              else {
              // Récupération du type du champ
              Map<String, Schema.SObjectField> allFields = KContrat__c.sObjectType.getDescribe().fields.getMap();
              Schema.SOAPType fieldType = allFields.get(fieldName).getDescribe().getSOAPType();
              // Traitement selon type
              if(fieldType == Schema.SOAPType.DATE || fieldType == Schema.SOAPType.DATETIME) {    // DATE et DATETIME et TIME
              if(contratHistory.Field == 'created')
              value = Datetime.valueOf(contratHistory.CreatedDate).format('dd/MM/YYYY');
              else
              value = Datetime.valueOf(contratHistory.NewValue).format('dd/MM/YYYY');
              } else if(fieldType == Schema.SOAPType.STRING) {                                // STRING
              value = String.valueOf(contratHistory.NewValue);
              }
              }
            */
            /*
              // Liste des notifications
              for(NotificationEspaceClient__c notification : [SELECT Id, compte__c, etiquette__c, valeur__c, numeroContrat__c FROM NotificationEspaceClient__c
              WHERE compte__c = :accountInitial.Id AND visible__c = true ORDER BY CreatedDate DESC]) {
              // Initialiation
              Notification notif = new Notification();
              // Définit l'objet notification
              notif.Id = notification.Id;
              notif.numeroContrat = (notification.numeroContrat__c != null) ? notification.numeroContrat__c : 'Coordonnées';
              notif.texte = notification.etiquette__c;
              notif.valeur = notification.valeur__c;
              notificationObjetClient.add(notif);
              }
              System.debug('#### FIN getNotificationsClient');
            */
            return notificationObjetClient;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber()) + messageError;
            log.addErrorMessage(message);
            System.debug('ERREUR # Site Espace Client : Récupération notifications (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - ONGLET PARRAIGNAGE : Permet d'enregistrer un nouveau filleul
    * @param nom Nom du filleul
    * @param prenom Prénom du filleul
    * @param rue Rue du filleul
    * @param cp Code postal du filleul
    * @param ville Ville du filleul
    * @param departement Departement du filleul
    * @param pays Pays du filleul
    * @param email Email du filleul
    * @param tel Téléphone du filleul
    * @param typeDotation Type de dotation du filleul
    * @param latitude Latitude de la localisation du filleul
    * @param longitude Longitude de la localisation du filleul
    * @param numeroCompteParrain Numéro de compte Salesforce du parain
    * @return List<Filleul> Liste des filleuls
    */
    @RemoteAction
    public static String creationFilleul(String nom, String prenom, String rue, String cp, String ville, String departement, String pays, 
                                            String email, String tel, String typeDotation, String latitude, String longitude, String numeroCompteParrain) {
        System.debug('### DEBUT creationFilleul');
        String message = '';
        String returnValue=null;
        try{
            String searchString = '';
            //vérification des champs obligatoires
            if (nom != null) nom = nom.trim();
            if (prenom != null) prenom = prenom.trim();
            if (rue != null) rue = rue.trim();
            if (cp != null) cp = cp.trim();
            if (ville != null) ville = ville.trim();
            if (departement != null) departement = departement.trim();
            if (pays != null) pays = pays.trim();
            if (email != null) email = email.trim();
            if (tel != null) {
                tel = tel.trim();
                tel = tel.replaceAll('\\s+','');
            }

            if(String.isBlank(nom)){
                System.debug('## Nom vide');
                throw new KubeException(Label.erreur_nom_obligatoire);
            }
            if (String.isNotBlank(nom) && nom.containsAny(Constants.CHECK_OTHER)) {
                System.debug('## Nom invalide');
                throw new KubeException(Label.erreur_nom_invalide);
            }
            if(String.isBlank(prenom)){
                System.debug('## Prénom vide');
                throw new KubeException(Label.erreur_prenom_obligatoire);
            }
            if (String.isNotBlank(prenom) && prenom.containsAny(Constants.CHECK_OTHER)) {
                System.debug('## Prénom invalide');
                throw new KubeException(Label.erreur_prenom_invalide);
            }
            if(String.isBlank(cp)){
                System.debug('## Code postal vide');
                throw new KubeException(Label.Ville_obligatoire);
            }
            if(String.isBlank(ville)){
                System.debug('## Ville vide');
                throw new KubeException(Label.Ville_obligatoire);
            }
            if(String.isNotBlank(tel) && !Pattern.matches(Constants.REG_TEL, tel))  {
                System.debug('## Erreur tel');
                throw new KubeException(Label.site_telephone_erreur);
            }
            if(String.isNotBlank(email) && !Pattern.matches(Constants.REG_EMAIL, email)) {
                System.debug('## Erreur email');
                throw new KubeException(Label.site_email_erreur);
            }
            // Verifie que les champs obligatoires sont bien remplis
            if(String.isBlank(email)){
                if(typeDotation != Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_PAPIER) {
                    System.debug('## Email obligatoire si type != '+Constants.ACCOUNT_DOTATION_TYPE_CHEQUE_PAPIER);
                    throw new KubeException(Label.espaceclient_msg_FilleulTypeDotationRequired);
                }
                if(String.isBlank(tel)){
                    System.debug('## Email ou telephone vide');
                    throw new KubeException(Label.erreur_email_ou_telephone_vide);
                } else{
                    // Verifie le futur filleul selon le téléphone
                    searchString = nom+' AND '+prenom+' AND '+tel;
                }
            } else {
                // Vérifie le future filleul selon l'email
                searchString = nom+' AND '+prenom+' AND '+email;
            }

            // Si le compte existe déja on renvoie un message d erreur
            List<List<SObject>> listFilleul = [FIND :searchString IN ALL FIELDS RETURNING Account(Id, Name WHERE IsPersonAccount = true)];
            if(listFilleul!=null && !listFilleul.isEmpty() && !listFilleul[0].isEmpty()){
                System.debug('## Compte deja existant');
                throw new KubeException(Label.erreur_compte_deja_existant);
            } else{
                // creation du futur filleul
                Import__c filleul = new Import__c(recordTypeId = DAL.getRecordTypeIdByDevName('Import__c', Constants.RT_IMPORT_EXTERNE));
                
                // mise en forme de la date au bon format
                String longDate = System.now().format('YYYYMMdd,HH,mm,ss');

                // alimentation des champs du filleul
                filleul.civiliteCompte__c = 'M.';
                filleul.nomCompte__c = nom;
                filleul.prenomCompte__c = prenom;
                filleul.telephoneDomicileCompte__c = tel;
                filleul.emailCompte__c = email;
                filleul.rueCompte__c=rue;
                filleul.rueChantier__c = rue;
                filleul.codePostalCompte__c=cp;
                filleul.codePostalChantier__c=cp;
                filleul.villeCompte__c=ville;
                filleul.villeChantier__c=ville;
                filleul.departementCompte__c=departement;
                filleul.departementChantier__c=departement;
                filleul.paysCompte__c=pays;
                filleul.paysChantier__c=pays;
                filleul.nomFichierSource__c = 'formulaire_site_parrainage';
                filleul.typeDotation__c = typeDotation;
                filleul.numeroParrain__c = numeroCompteParrain;
                filleul.idEulerian__c = 'P' + longDate + '' + math.round(math.random()*99);
                filleul.integrable__c = true;
                filleul.Source__c = Constants.CONTACT_SOURCE_PARRAINAGE;
                filleul.Localisation__Latitude__s = (String.isBlank(latitude)) ? 0 : Decimal.valueOf(latitude);
                filleul.Localisation__Longitude__s = (String.isBlank(longitude)) ? 0 : Decimal.valueOf(longitude);

                // Gestion du hors secteur, geolocation
                /*GeoUtils.geolocationImportRecord(filleul);
                insert filleul;
                if(filleul.messageException__c != null && filleul.messageException__c == Label.import_erreur_horssecteur_messageexception) {
                }*/
                List<Sectorisation__c> secteurList = ([SELECT Id FROM Sectorisation__c WHERE codeMagasin__c != null 
                                                        AND ((codePostalAdm__c = :cp AND nomCommuneAdm__c = :ville.toUpperCase()) 
                                                        OR nomCommuneAdm__c = :ville.toUpperCase()) LIMIT 1]);
                if(secteurList.isEmpty()) {
                    System.debug('## Hors secteur');
                    throw new KubeException(Label.import_erreur_horssecteur_message);
                }
                insert filleul;
                returnValue=filleul.Id;
            }
            System.debug('### FIN creationFilleul');
            return returnValue;
        } catch(KubeException e) {
            System.debug('ERREUR # Site Espace Client : Création filleul (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
            + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
            System.debug('ERREUR # Site Espace Client : Création filleul (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw new KubeException(message);
        }
    }

    /**
    * @description REMOTEACTION - ONGLET BESOIN D'AIDE : Transfert d'un fichier pour une requête
    * @param caseId Id Salesforce de la requête
    * @param attachmentId Id Salesforce de la pièce jointe
    * @param attachmentName Nom de la pièce jointe
    * @param attachmentContentType Type de la pièce jointe
    */
    @RemoteAction
    public static String transfertFichier(String caseId, String attachmentId, String attachmentBody, String attachmentName, String attachmentContentType) {
        System.debug('### DEBUT transfertFichier');
        String message = '';
        Attachment att = null;

        try {
            if (caseId != null) {
                if (attachmentBody != null) {
                    System.debug('## attachmentBody : ' + attachmentBody);
                    // Vérification type pièce jointe
                    String contentType = attachmentContentType;
                    System.debug('## Type pièce jointe : ' + contentType);
                    if (!(contentType == 'image/jpeg' || contentType == 'image/png' || contentType == 'image/gif'
                          || contentType == 'image/jpg' || contentType == 'image/bmp')) {
                        System.debug('## Pièce jointe invalide');
                        message = Label.espaceclient_msg_CaseWrongAttachmentType;
                        throw new KubeException(message);
                    }
                    // Vérification de la présence de la pièce jointe
                    List<Attachment> attachments = [SELECT Id, Body FROM Attachment WHERE Id = :attachmentId];
                    if (attachments.isEmpty()) {
                        att = new Attachment();
                    } else {
                        att = attachments[0];
                    }
                    // Concatenation du corps à la pièce jointe existante (transfert de fichier volumineux)
                    String newBody = '';
                    if (att.Body != null) {
                        newBody = EncodingUtil.base64Encode(att.Body);
                    }
                    newBody += attachmentBody;
                    // Mise à jour ou création de l'enregistrement
                    System.debug('## Add attachment - ParentId : ' + caseId);
                    System.debug('## Add attachment - Name : ' + attachmentName);
                    System.debug('## Add attachment - ContentType : ' + attachmentContentType);
                    att.Body = EncodingUtil.base64Decode(newBody);
                    if (attachmentId == null) {
                        att.Name = attachmentName;
                        att.parentId = caseId;
                        att.ContentType = attachmentContentType;
                    }
                    upsert att;
                    // Retour
                    System.debug('### FIN transfertFichier');
                    return att.Id;
                }
            }
            return null;
        } catch(KubeException e) {
            System.debug('ERREUR # Site Espace Client : Transfert fichier (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw e;
        } catch(Exception e) {
            message = Label.msg_InternalError + ' Ligne : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone : </strong><a href="tel:' + TELSUPPORT + '" class="text-red number-phone">' + TELSUPPORT + '</a><br/>'
            + '<strong>E-mail : <a href="mailto:' + EMAILSUPPORT + '" class="text-red">' + EMAILSUPPORT + '</a></strong>';
            System.debug('ERREUR # Site Espace Client : Transfert fichier (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw new KubeException(message);
        }
    }

    /**
    * @description REMOTEACTION - COMPOSANT FAITES VOUS RAPPELLER : Appel du webservice Prosodie Odigo
    * @param numTel Numéro de téléphone
    * @param accId Id Salesforce du compte
    */
    @RemoteAction
    public static void sendNotifyTelCallBack(String numTel, String accId) {
        System.debug('### DEBUT sendNotifyTelCallBack');
        String message = '';

        // S'assure que les 2 appels WS seront traités
        if ((Limits.getCallouts() + 2) > Limits.getLimitCallouts()) {
            System.debug('ERREUR # Site Espace Client : Demande de rappel téléphonique non transmise (Limite(s) atteinte(s): ' + Limits.getCallouts() + ' / ' + Limits.getLimitCallouts() + ') !');
            message = Label.espaceclient_msg_CallUnavailable + ' ' + TELSUPPORT;
            throw new KubeException(message);
        }
        // Vérification du numéro de téléphone
        if (String.isEmpty(numTel) || !Pattern.matches(Constants.REG_TEL, numTel)) {
            System.debug('ERREUR # Site Espace Client : Demande de rappel téléphonique non transmise (téléphone incorrect ' + numTel + ') !');
            message = Label.site_msg_TelNotValid;
            throw new KubeException(message);
        }

        try {
            System.debug('## Téléphone : ' + numTel);
            System.debug('## Début de l\'envoi demande Prosodie Odigo');

            /* DEPRECATED            
            wsOdigoProsodie36WebcallbackBeanModel.CallBackBean callBack = new wsOdigoProsodie36WebcallbackBeanModel.CallBackBean();
            callBack.phoneNumber = numTel;
            callBack.skillKeyWord = Utils_Odigo.ODIGO_SKILL;
            callBack.priority = Utils_Odigo.ODIGO_PRIORITY;
            callBack.date_x = 0;
            callBack.data = accId;
            callBack.data2 = null;
            callBack.newPhoneNumber = null;
            callBack.agentId = null;
            wsOdigoProsodie36Webcallback.WebCallBackHttpsSoap11Endpoint endPoint = new wsOdigoProsodie36Webcallback.WebCallBackHttpsSoap11Endpoint();
            endPoint.timeout_x = Utils_Odigo.ODIGO_TIMEOUT;
            System.debug('## WebCallBack : ' + callBack);
            // Envoi de la demande
            Utils_Odigo.checkCallback(endPoint.saveCallBack(callBack, Utils_Odigo.getUser()), callBack.phoneNumber);
            */

            // Récupération de l'ID de la campagne d'appels sortants 
            String odigoCampaignName = PropertiesUtils.getStringValue('prosodie.odigo.espaceclient', '');
            Integer odigoPriority = PropertiesUtils.getIntegerValue('prosodie.odigo.espaceclient.priority', 1);
            Integer odigoCampaignId;
            if(!Test.isRunningTest()) {
                Integer campaignId = Utils_Odigo.getCampaignIdByLabel(odigoCampaignName);
                if(campaignId == null) {
                    System.debug('ERREUR # Problème lors de la récupération de l\'ID de la campagne Odigo');
                    message = Label.espaceclient_msg_CallUnavailable + ' ' + TELSUPPORT;
                    throw new KubeException(message);
                }
                odigoCampaignId = campaignId;
            } 
            System.debug('## ID: '+odigoCampaignId);  

            // Configuration du callback    
            List<Utils_Odigo.WebCallBackContactList> callbackList = new List<Utils_Odigo.WebCallBackContactList>();
            Utils_Odigo.WebCallBackContactList callBack = new Utils_Odigo.WebCallBackContactList();                
            List<Utils_Odigo.WebCallBackContact> contactsInfoList = new List<Utils_Odigo.WebCallBackContact>();
            contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PHONENUMBER1', numTel));
            contactsInfoList.add(new Utils_Odigo.WebCallBackContact('CUSTOMERIDENTITY', accId));
            contactsInfoList.add(new Utils_Odigo.WebCallBackContact('PRIORITY', String.valueOf(odigoPriority)));
            callBack.contactFields = contactsInfoList;
            System.debug('## callBack: '+callBack);  
            callbackList.add(callBack);

            // Envoi de la campagne dans odigo
            if(!callbackList.isEmpty()){
                if(!Test.isRunningTest() && Utils_Odigo.ODIGO_ACTIVE) {                     
                    System.debug('## Envoi à ODIGO');  
                    String retWS = Utils_Odigo.uploadCallback(odigoCampaignId, callbackList);
                    if(retWS != 'OK') {
                        System.debug('ERREUR # Problème lors de l\'envoi des callbacks dans la campagne: '+retWS);
                        message = Label.espaceclient_msg_CallUnavailable + ' ' + TELSUPPORT;
                        throw new KubeException(message);
                    }
                } 
            }

            System.debug('### FIN sendNotifyTelCallBack');
        } catch(Exception e) {
            message = Label.espaceclient_msg_CallInternalError + ' ' + TELSUPPORT;
            System.debug('ERREUR # Site Espace Client : Demande de rappel téléphonique non transmise (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            throw new KubeException(message);
        }
    }

    /**
    * @description REMOTEACTION - Validation du changement de mot de passe
    * @param accId Id Salesforce du compte
    * @param ancienMotDePasse Ancien mot de passe
    * @param nouveauMotDePasse Nouveau mot de passe
    * @param confirmNouveauMotDePasse Confirmation du nouveau mot de passe
    * @return Message d'erreur sinon null 
    */
    @RemoteAction
    public static String requestNewPassword(String accId, String ancienMotDePasse, String nouveauMotDePasse, String confirmNouveauMotDePasse) {
        System.debug('### DEBUT requestNewPassword');
        String message = '';
        String newEncodedPassword = encodePassword(nouveauMotDePasse);
        try {
            Account acc = [SELECT Id, motDePasseClient__c FROM Account WHERE Id = :accId];
            // Vérification champs obligatoire
            if(String.isBlank(ancienMotDePasse) || String.isBlank(nouveauMotDePasse) || String.isBlank(confirmNouveauMotDePasse)) {
                System.debug('ERREUR # Site Espace Client : '+Label.espaceclient_msg_ChangePasswordRequired);
                return Label.espaceclient_msg_ChangePasswordRequired;
            // Vérification de l'ancien mot de passe
            } else if (acc.motDePasseClient__c != encodePassword(ancienMotDePasse)) {
                System.debug('ERREUR # Site Espace Client : '+Label.espaceclient_msg_InvalidPassword);
                return Label.espaceclient_msg_InvalidPassword;
            // Vérification ancien != nouveau
            } else if (acc.motDePasseClient__c == newEncodedPassword) {
                System.debug('ERREUR # Site Espace Client : '+Label.espaceclient_msg_OldIdenticalPassword);
                return Label.espaceclient_msg_OldIdenticalPassword;
            // Vérification de la double saisie du mot de passe
            } else if (nouveauMotDePasse!=confirmNouveauMotDePasse) {
                System.debug('ERREUR # Site Espace Client : '+Label.espaceclient_msg_NewMDPDoesNotMatch);
                return Label.espaceclient_msg_NewMDPDoesNotMatch;
            // Vérification des règles de mise en forme
            } else if((nouveauMotDePasse.replaceAll('[^A-Z]+', '').length() < NOMBREMAJUSCULES) 
                        || (nouveauMotDePasse.replaceAll('[^a-z]+', '').length() < NOMBREMINUSCULES)
                        || (nouveauMotDePasse.replaceAll('[^0-9]+', '').length() < NOMBRECHIFFRES)){
                System.debug('## Règles de sécurité check');
                // Construction erreur de format mot de passe
                message = String.format(Label.espaceclient_msg_ErreurReglesMotDePasse, 
                        new List<String>{String.valueOf(NOMBREMAJUSCULES),((NOMBREMAJUSCULES != 1)?'s':''),
                                        String.valueOf(NOMBREMINUSCULES),((NOMBREMINUSCULES != 1)?'s':''),
                                        String.valueOf(NOMBRECHIFFRES),((NOMBRECHIFFRES != 1)?'s':'')});
                return message;
            }
            else if(nouveauMotDePasse.length() < LONGUEURMIN || nouveauMotDePasse.length() > LONGUEURMAX){
                System.debug('## Taille incorrecte');
                message = String.format(Label.espaceclient_msg_PasswordSizeError, new List<String>{ String.valueOf(LONGUEURMIN),String.valueOf(LONGUEURMAX) });
                return message;
            }
            else {
                // OK
                acc.motDePasseClient__c = newEncodedPassword;
                System.debug('## MDP modifié');
                update acc;
            }
            
            System.debug('### FIN requestNewPassword');
            return null;
        } catch(Exception e) {
            message = Label.espaceclient_msg_CallInternalError + ' ' + TELSUPPORT;
            System.debug('ERREUR # Site Espace Client : Un problème est survenu pendant la modification du mot de passe client (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            return message;
        }
    }

    /**
    * @description Méthode d'actualisation de la date de connexion du client à son espace client => méthode asynchrone
    * @param accountId Id Salesforce du compte
    * @param ipAddress Adresse IP du client
    */
    @future
    public static void setDateConnexionAndIP(String accountId, String ipAddress) {
        List<Account> accounts = [SELECT Id, dateConnexionEspaceClient__c, adresseIPClient__c FROM Account WHERE Id = :accountId LIMIT 1];
        if (!accounts.isEmpty()) {
            Account account = accounts.get(0);
            account.dateConnexionEspaceClient__c = System.now();
            account.adresseIPClient__c = ipAddress;
            update account;
        }
    }

    /**
    * @description Méthode de conversion d'un boolean en string
    * @param bool Valeur booléane à convertir
    * @return String Valeur "Oui" ou "Non"
    */ 
    public static String booleanToString(Boolean bool) {
        return(bool) ? 'Oui' : 'Non';
    }

    // Informations Espace Client
    public class Compte {
        // Informations Account (Mes coordonnées)
        public Boolean IsPersonAccount { get; set; }
        public String Id { get; set; }
        public String contactParDefautId { get; set; }
        public String numeroCompte { get; set; }
        public String civilite { get; set; }
        public String nom { get; set; }
        public String prenom { get; set; }
        public Date dateMotDePasseClient { get; set; }
        public Datetime dateConnexion { get; set; }
        public String dateConnexionFormat { get; set; }
        public String rue { get; set; }
        public String ville { get; set; }
        public String codePostal { get; set; }
        public String complementAdresse { get; set; }
        public String departement { get; set; }
        public String pays { get; set; }
        public Decimal etage { get; set; }
        public String interphone { get; set; }
        public String telephoneDomicile { get; set; }
        public String telephoneMobile { get; set; }
        public String autreTelephone { get; set; }
        public String Phone { get; set; }
        public String telephoneMobilePro { get; set; }
        public String autreTelephonePro { get; set; }
        public String Fax { get; set; }
        public String canalPrefere { get; set; }
        public String email { get; set; }
        public String emailPro { get; set; }
        public Boolean optinAdresseEmailKparK { get; set; }
        public Boolean optinAdresseEmailPartenaire { get; set; }
        public Boolean optinSMSKparK { get; set; }
        public Boolean optinSMSPartenaire { get; set; }
        public Boolean optinTelephoneDomicileKparK { get; set; }
        public Boolean optinTelephoneDomicilePartenaire { get; set; }
        public Boolean optinTelephoneMobileKparK { get; set; }
        public Boolean optinTelephoneMobilePartenaire { get; set; }
        public Decimal LocalisationLatitude { get; set; }
        public Decimal LocalisationLongitude { get; set; }
        // Informations dépôt
        public String libelleDepot { get; set; }
        public String rueDepot { get; set; }
        public String codePostalDepot { get; set; }
        public String villeDepot { get; set; }
        public String emailDepot { get; set; }
        public String telephoneDepot { get; set; }
        public Decimal locDepotLatitude { get; set; }
        public Decimal locDepotLongitude { get; set; }
        public String locDepotAdr { get; set; }

        public Compte(Account account) {
            // Informations Account (Mes coordonnées)
            this.IsPersonAccount = account.IsPersonAccount;
            this.Id = account.Id;
            this.contactParDefautId = account.contactParDefaut__c;
            this.numeroCompte = account.AccountNumber;
            this.civilite = account.civilite__c;
            this.nom = account.nom__c;
            this.prenom = account.prenom__c;
            this.dateMotDePasseClient = account.dateMotDePasseClient__c;
            this.dateConnexion = account.dateConnexionEspaceClient__c;
            if (account.dateConnexionEspaceClient__c != null)
                this.dateConnexionFormat = account.dateConnexionEspaceClient__c.format('dd/MM/YYYY HH:mm:ss');
            this.rue = account.rue__c;
            this.ville = account.ville__c;
            this.codePostal = account.codePostal__c;
            this.complementAdresse = account.complementAdresse__c;
            this.departement = account.departement__c;
            this.pays = account.pays__c;
            this.etage = account.etage__c;
            this.interphone = account.interphone__c;
            this.telephoneDomicile = account.telephoneDomicile__c;
            this.telephoneMobile = account.telephoneMobile__c;
            this.autreTelephone = account.autreTelephone__c;
            this.Phone = account.Phone;
            this.telephoneMobilePro = account.contactParDefaut__r.MobilePhone;
            this.autreTelephonePro = account.contactParDefaut__r.OtherPhone;
            this.Fax = account.Fax;
            this.canalPrefere = account.canalPrefere__c;
            this.email = account.email__c;
            this.emailPro = account.contactParDefaut__r.Email;
            this.optinAdresseEmailKparK = account.optinAdresseEmailKparK__c;
            this.optinAdresseEmailPartenaire = account.optinAdresseEmailPartenaire__c;
            this.optinSMSKparK = account.optinSMSKparK__c;
            this.optinSMSPartenaire = account.optinSMSPartenaire__c;
            this.optinTelephoneDomicileKparK = account.optinTelephoneDomicileKparK__c;
            this.optinTelephoneDomicilePartenaire = account.optinTelephoneDomicilePartenaire__c;
            this.optinTelephoneMobileKparK = account.optinTelephoneMobileKparK__c;
            this.optinTelephoneMobilePartenaire = account.optinTelephoneMobilePartenaire__c;
            this.LocalisationLatitude = account.Localisation__latitude__s;
            this.LocalisationLongitude = account.Localisation__longitude__s;
            // Informations dépôt
            this.libelleDepot = account.Sectorisation__r.libelleDepot__c;
            this.rueDepot = account.Sectorisation__r.rueDepot__c;
            this.codePostalDepot = account.Sectorisation__r.codePostalDepot__c;
            this.villeDepot = account.Sectorisation__r.villeDepot__c;
            this.emailDepot = account.Sectorisation__r.emailDepot__c;
            if (account.Sectorisation__r.telephoneDepot__c != null)
                this.telephoneDepot = account.Sectorisation__r.telephoneDepot__c.replaceAll('\\.', ' ');
            this.locDepotLatitude = account.Sectorisation__r.localisationDepot__latitude__s;
            this.locDepotLongitude = account.Sectorisation__r.localisationDepot__longitude__s;
            this.locDepotAdr = account.Sectorisation__r.rueDepot__c+' '+account.Sectorisation__r.codePostalDepot__c+' '+account.Sectorisation__r.villeDepot__c;
        }
    }

    // COMPOSANT CONTRATS: Informations d'un contrat du client
    public class Contrat {
        public String Id { get; set; }
        public Account compte { get; set; }
        public Chantier__c chantier { get; set; }
        public Opportunity projet { get; set; }
        public Quote devis { get; set; }
        public SBQQ__Quote__c devisCPQ { get; set; }
        public List<QuoteLineItem> produitsContrat { get; set; }
        public List<OrderItem> produitsCommande { get; set; }
        public KContrat__c contratInfos { get; set; }
        public Order commmandeInfos { get; set; }
        public String numeroContrat { get; set; }
        public String nomContrat { get; set; }
        public String nomVendeur { get; set; }
        public String statut { get; set; }
        public Date dateDeSignature { get; set; }
        public Date dateDeResiliation { get; set; }
        public String motifDeResiliation { get; set; }
        public String modeDeFinancement { get; set; }
        public String statutDevis { get; set; }     
        public Decimal montantTTC { get; set; }
        public String montantDevisTTC { get; set; }
        public String produits { get; set; }
        public String etapeActuelle { get; set; }
        public String prochaineEtape { get; set; }
        public String intervDernierMetrage { get; set; }
        public String intervDerniereInstallation { get; set; }
        public String intervDerniereInterventionSAV { get; set; }
        public String nomDepot { get; set; }
        public Date dateDernierMetrage { get; set; }
        public Decimal nombreMetrages { get; set; }
        public Datetime dateProchainMetrage { get; set; }
        public Date dateDernierInstallation { get; set; }
        public Decimal nombreInstallations { get; set; }
        public Datetime dateProchainInstallation { get; set; }
        public Date dateDebutDernierSAV { get; set; }
        public Decimal nbSAVTotal { get; set; }
        public Date dateDerniereInterventionSAV { get; set; }
        public Decimal nombreInterventionsSAV { get; set; }
        public Datetime dateProchainSAV { get; set; }
        public Decimal tvaReduite { get; set; }
        public Decimal tvaIntermediaire { get; set; }
        public Decimal tvaNormal { get; set; }
        public List<String> panelsType { get; set; }

        public Contrat() {
            panelsType = new List<String> ();
            produitsContrat = new List<QuoteLineItem> ();
        }
    }

    // ONGLET BESOIN D'AIDE : Informations d'une demande en cours
    public class Demande {
        public Id id { get; set; }
        public String accId { get; set; }
        public String chantier { get; set; }
        public String numero { get; set; }
        public String typeDemande { get; set; }
        public String typeRDV { get; set; }
        public String motif { get; set; }
        public String objet { get; set; }
        public String typeResolution { get; set; }
        public Date datePrevueResolution { get; set; }
        public String description { get; set; }
        public Date dateDemande { get; set; }
        public Datetime dateFermeture { get; set; }
        public String statut { get; set; }
        public Boolean isClosed { get; set; }
        public Demande() {}
        public Demande(Case requete)
        {
            this.id = requete.Id;
            this.numero = (requete.CaseNumber == null) ? '' : requete.CaseNumber; 
            this.accId = (requete.AccountId == null) ? '' : requete.AccountId;
            this.chantier = (requete.Chantier__c == null) ? '' : requete.Chantier__r.rue__c + ', ' + requete.Chantier__r.codePostal__c +' '+ requete.Chantier__r.ville__c;
            this.typeDemande = (requete.Type == null) ? '' : requete.Type;
            this.typeRDV = (requete.typeDeRendezVous__c == null) ? '' : requete.typeDeRendezVous__c;
            this.motif = (requete.motif__c == null) ? '' : requete.motif__c;
            this.objet = (requete.Subject == null) ? '' : requete.Subject;
            this.typeResolution = (requete.typeResolution__c == null) ? '' : requete.typeResolution__c;
            this.datePrevueResolution = requete.datePrevisionnelleResolution__c;
            this.description = (requete.Description == null) ? '' : requete.Description;
            this.dateDemande = (requete.CreatedDate == null) ? null : requete.CreatedDate.Date();
            this.dateFermeture = (requete.ClosedDate == null) ? null : requete.ClosedDate;
            this.isClosed = (requete.Status == Constants.REQUETE_STATUS_CLOSED);
            if(String.isBlank(requete.Status)) 
                this.statut = '';
            else if(requete.Status==Constants.REQUETE_STATUS_CLOSED || requete.Status==Constants.REQUETE_STATUS_TO_CLOSE 
                    || requete.Status==Constants.REQUETE_STATUS_INPROGRESS)
                this.statut = requete.Status;
            else
                this.statut = Constants.REQUETE_STATUS_NEW;
        }
    }

    public class Commentaire {
        public Id id { get; set; }
        public String texte { get; set; }
        public String dateCreation { get; set; }
        public Boolean isFromClient { get; set; }

        public Commentaire() {}
        public Commentaire(CaseComment caseCom)
        {
            this.id = caseCom.Id;
            this.texte = (caseCom.CommentBody == null) ? '' : caseCom.CommentBody;
            this.isFromClient = (caseCom.CreatedById == UserInfo.getUserId()) ? true : false;
            this.dateCreation = (caseCom.createdDate == null) ? null : caseCom.CreatedDate.format('dd/MM/yyyy - HH:mm');
        }
    }

    public class PieceJointe {
        public Id id { get; set; }
        public String body { get; set; }
        public String nom { get; set; }
        public String dateCreation { get; set; }
        public String contentType { get; set; }

        public PieceJointe() {}
        public PieceJointe(Attachment att)
        {
            this.id = att.Id;
            this.body = (att.Body == null) ? '' : EncodingUtil.base64Encode(att.Body);
            this.nom = (att.Name == null) ? '' : att.Name;
            this.contentType = (att.ContentType == null) ? '' : att.ContentType;
            this.dateCreation = (att.CreatedDate == null) ? null : att.CreatedDate.format('dd/MM/yyyy - HH:mm');
        }
    }

    // COMPOSANT PARRAINAGE : Informations sur les filleuls
    public class Filleul {
        public String Id { get; set; }
        public String nom { get; set; }
        public String prenom { get; set; }
        public String numeroCompte { get; set; }
        public String type { get; set; }
        public Date dateAssociationParrain { get; set; }
        public Date dateEnvoiDotationParrain { get; set; }
        public Filleul(Account filleul) {
            this.Id = filleul.Id;
            this.nom = filleul.nom__c;
            this.prenom = filleul.prenom__c;
            this.numeroCompte = filleul.AccountNumber;
            this.type = filleul.Type;
            this.dateAssociationParrain = (filleul.dateAssociationParrain__c==null) ? filleul.CreatedDate.date() : filleul.dateAssociationParrain__c;
            this.dateEnvoiDotationParrain = filleul.dateEnvoiDotationParrain__c;
        }
    }

    // COMPOSANT NOTIFICATION : Informations sur les notifications
    public class Notification {
        public String Id { get; set; }
        public String numeroContrat { get; set; }
        public String texte { get; set; }
        public String valeur { get; set; }
        public Notification() {}
    }
}