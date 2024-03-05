//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Signea_CPQ
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 03/03/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Signea_CPQ {
    private static Id RT_RDV_COMMERCIAL = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
    private static String DEFAULT_RECIPIENTTYPE = 'Distance'; // 'Face2face'; // 'Distance';
    private static String DEFAULT_SIGNATURETYPE = 'PAD';
    private static String DEFAULT_TARGET        = 'Contrat';
    private static Boolean WITHSTEP2            = true;
    
    public Exception error{get;private set;}
    public Profile userProfile {get;private set;}
    public SBQQ__Quote__c quote {get;private set;}
    public User user {get;private set;}
    public String DIPCSigner1 {get;private set;}
    public String DIPCSigner2 {get;private set;}
    public String DIPCVendeur {get;private set;}
    public String contratSigner1 {get;private set;}
    public String contratSigner2 {get;private set;}
    public String contratVendeur {get;private set;}
    public String documentType {get;set;}
    public String signButtonValue {get;private set;}
    public Boolean devisShowExpire {get;private set;}
    public Boolean contratShowExpire {get;private set;}
    public Boolean circuitAcces {get;private set;}
    public Boolean circuitDetailAcces {get;private set;}
    public Boolean circuitSignatureClientAcces {get;private set;}
    public Boolean autoLaunchField {get;set;}
    public Boolean isTestWithoutErrors {get;set;}
    public String typeContrat {get;private set;}
    public Boolean forbiddenAcces {get; set;}
    
    // ERRORS
    public Utils_logger log {get; set;}
    
    // Etapes
    public Signea__Step__c etapeDIPC {get;private set;}
    public Signea__Step__c etapeContrat {get;private set;}
    
    // Circuits
    public Signea__Circuit__c storedCircuitDIPC {get;private set;}
    public Signea__Circuit__c storedCircuitContrat {get; set;}
    
    // picklists
    public String signataire1SignType {get{
        if(signataire1SignType == null) {
            signataire1SignType = DEFAULT_SIGNATURETYPE + DEFAULT_RECIPIENTTYPE;
        }
        return signataire1SignType;
    }
    set;
    }
    public String signataire2SignType {get{
        if(signataire2SignType == null) {
            signataire2SignType = DEFAULT_SIGNATURETYPE + DEFAULT_RECIPIENTTYPE;
        }
        return signataire2SignType;
    }
    set;
    }
    public String vendeurSignType {get{
        if(vendeurSignType == null) {
            vendeurSignType = DEFAULT_SIGNATURETYPE + DEFAULT_RECIPIENTTYPE;
        }
        return vendeurSignType;
    }
    set;
    }

    public List<SelectOption> getmanuscriteList() {
        List<SelectOption> options = new List<SelectOption>();
        if(quote.autreCompte__c != null && signataire2SignType != 'Aucun') {
            options.add(new SelectOption('Aucun', 'Aucun'));
        }
        options.add(new SelectOption('PADFace2face', Label.signea_text_ManuscriteF2F));
        options.add(new SelectOption('OTPFace2face', Label.signea_text_SMSF2F));
        options.add(new SelectOption('PADDistance', Label.signea_text_ManuscriteDistance));
        options.add(new SelectOption('OTPDistance', Label.signea_text_SMSDistance));
        return options;
    }

    public List<SelectOption> getManuscriteList2() {
        List<SelectOption> options = new List<SelectOption>();
        if(quote.autreCompte__c != null && signataire1SignType != 'Aucun') {
            options.add(new SelectOption('Aucun', 'Aucun'));
        }
        options.add(new SelectOption('PADFace2face', Label.signea_text_ManuscriteF2F));
        options.add(new SelectOption('OTPFace2face', Label.signea_text_SMSF2F));
        options.add(new SelectOption('PADDistance', Label.signea_text_ManuscriteDistance));
        options.add(new SelectOption('OTPDistance', Label.signea_text_SMSDistance));
        return options;
    }

    public List<SelectOption> getManuscriteListVendeur() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('PADFace2face', Label.signea_text_ManuscriteF2F));
        options.add(new SelectOption('OTPFace2face', Label.signea_text_SMSF2F));
        options.add(new SelectOption('PADDistance', Label.signea_text_ManuscriteDistance));
        options.add(new SelectOption('OTPDistance', Label.signea_text_SMSDistance));
        return options;
    }
    
    public String quoteId;
    public String recipientType;
    public String recipientType1;
    public String recipientType2;
    public String recipientTypeVendeur;
    public String signatureType;
    public String signatureType1;
    public String signatureType2;
    public String signatureTypeVendeur;
    
    /**
    * @description Constructeur
    * @return Ctrl_Signea Controleur
    */
    public Ctrl_Signea_CPQ() {
        // Init
        refresh(false);
        circuitAcces = false;
        circuitDetailAcces = false;
        autoLaunchField = false;
        isTestWithoutErrors = false;
        log = new Utils_logger();
        forbiddenAcces = false;

        // CGV
        typeContrat = '';
        if(String.isNotBlank(quote.termsAndConditions__c)) {
            Referencial__c refCGV = [SELECT Id, Name FROM Referencial__c WHERE Id = :quote.termsAndConditions__c LIMIT 1];
            typeContrat = refCGV.Name;
        }
        
        // Initialisation du bouton de lancement de circuits
        signButtonValue = 'Contrat';
        signataire1SignType = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('signatureType'), DEFAULT_SIGNATURETYPE) + StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('recipientType'), DEFAULT_RECIPIENTTYPE);
        signataire2SignType = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('signatureType'), DEFAULT_SIGNATURETYPE) + StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('recipientType'), DEFAULT_RECIPIENTTYPE);
        vendeurSignType = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('signatureType'), DEFAULT_SIGNATURETYPE) + StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('recipientType'), DEFAULT_RECIPIENTTYPE);
        // Récupération infos profiles
        userProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        user = [SELECT Id, ProfileName__c, FirstName, LastName, Email, Phone, CodeMagasin__c, libelleMagasin__c, CodeDV__c, LibelleDV__c FROM User WHERE Id = :UserInfo.getUserId()];
        circuitAcces = PropertiesUtils.isUserAllowed('signea_circuit_acces__c');
        circuitDetailAcces = PropertiesUtils.isUserAllowed('signea_circuit_details_acces__c');
        circuitSignatureClientAcces = PropertiesUtils.isUserAllowed('signea_circuit_signature_client_acces__c');
        System.debug('## Accès à la création de circuit: ' + circuitAcces);
        System.debug('## Accès au détail de circuit: ' + circuitDetailAcces);
        if(!userProfile.Name.CONTAINS('Admin') && user.Id != quote.OwnerId){
            forbiddenAcces = true;
        }
    }
    
    /**
    * @description Création / Lancement des circuits du devis lors de l'appui sur le bouton de signature
    * @return PageReference Page Visualforce Signea
    */
    public PageReference execute() {
        System.debug('### DEBUT execute');
        Map<Account, Integer> signatairesMap = new Map<Account, Integer>();
        
        log.clear();
        
        // Init informations page
        PageReference pageRF = Page.VF_Signea_CPQ;
        pageRF.setRedirect(true);
        pageRF.getParameters().put('quoteId', quoteId);
        
        // A - Récupération des paramètres
        recipientType = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('recipientType'), DEFAULT_RECIPIENTTYPE);
        recipientType1 = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('recipientType1'), recipientType);
        recipientType2 = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('recipientType2'), recipientType);
        signatureType = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('signatureType'), DEFAULT_SIGNATURETYPE);
        signatureType1 = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('signatureType1'), signatureType);
        signatureType2 = StringUtils.defaultIfEmpty(Apexpages.currentPage().getParameters().get('signatureType2'), signatureType);

        // A1 - Récupération des choix de l'utilisateur
        if(signataire1SignType.startsWith('PAD') || signataire1SignType.startsWith('OTP')) {
            signatureType1 = signataire1SignType.substring(0, 3);
            if(signataire1SignType.endsWith('Distance') || signataire1SignType.endsWith('Face2face')) {
                recipientType1 = signataire1SignType.substring(3);
            }
        }
        if(signataire2SignType.startsWith('PAD') || signataire2SignType.startsWith('OTP')) {
            signatureType2 = signataire2SignType.substring(0, 3);
            if(signataire2SignType.endsWith('Distance') || signataire2SignType.endsWith('Face2face')) {
                recipientType2 = signataire2SignType.substring(3);
            }
        }
        if(vendeurSignType.startsWith('PAD') || vendeurSignType.startsWith('OTP')) {
            signatureTypeVendeur = vendeurSignType.substring(0, 3);
            if(vendeurSignType.endsWith('Distance') || vendeurSignType.endsWith('Face2face')) {
                recipientTypeVendeur = vendeurSignType.substring(3);
            }
        }
        
        // Cas spécial d'une non-signature pour un des 2 signataire
        if(signataire1SignType.startsWith('Aucun')) {
            signatureType1 = signataire1SignType.substring(0, 5);
            if(signataire1SignType.endsWith('Distance') || signataire1SignType.endsWith('Face2face')) {
                recipientType1 = signataire1SignType.substring(5);
            }
        }
        if(signataire2SignType.startsWith('Aucun')) {
            signatureType2 = signataire2SignType.substring(0, 5);
            if(signataire2SignType.endsWith('Distance') || signataire2SignType.endsWith('Face2face')) {
                recipientType2 = signataire2SignType.substring(5);
            }
        }
        System.debug('## signatureType : ' + signatureType);
        System.debug('## signatureType1 : ' + signatureType1);
        System.debug('## signatureType2 : ' + signatureType2);
        System.debug('## signatureTypeVendeur : ' + signatureTypeVendeur);
        System.debug('## recipientType1 : ' + recipientType1);
        System.debug('## recipientType2 : ' + recipientType2);
        System.debug('## recipientTypeVendeur : ' + recipientTypeVendeur);
        
        try {
            // B - Rafraichissement, traitement et contrôle du contexte
            refresh(true);                  // Fonction de rafraichissement de la page
            if (documentType == null) {
                return pageRF;
            }
            if(!isTestWithoutErrors) {
                checkContext();                   // Fonction de contrôle et affichage des erreurs
            }
            
            // Génération des documents ou récupération si déjà générés
            Blob blobTVA = null;
            String fileTVA = null;
            // C1 - Création et enregistrement du PDF (DIPC)
            String dateOfDayFormat = Datetime.now().format('dd/MM/YYYY');
            Blob blobDIPC = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(quote.Id, 'DIP '+quote.NDevis__c+' - '+dateOfDayFormat, 'DIP');
            System.debug('## DIPC: '+blobDIPC);
            
            // C2 - Création et enregistrement du PDF (Contrat)
            Blob blobContrat = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(quote.Id, 'Contrat ' + quote.NDevis__c+' - '+dateOfDayFormat, 'Contrat');
            System.debug('## Contrat: '+blobContrat);
            
            // C3 - Création et enregistrement du PDF (Attestation TVA)
            if(quote.SBQQ__Type__c != 'SAV' && (quote.MontantTVAIntermediaire__c != 0 || quote.MontantTVAReduite__c != 0)) {
                blobTVA = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(quote.Id, 'Attestation TVA ' + quote.NDevis__c+' - '+dateOfDayFormat, 'TVA');
                System.debug('## TVA: '+blobTVA);
            }

            // Lien des documents au devis et vérification des documents par catégorie
            String fileDIPC = LWC_QuoteCPQGeneratePDF.linkDocumentToRecordForSignea(quote.Id, 'DIP '+quote.NDevis__c+' - '+dateOfDayFormat, blobDIPC, 'DIP');
            deleteCtDocumentByCategory(quote.Id, fileDIPC, 'DIP');            
            System.debug('## SIGNEA - Id DIPC: '+fileDIPC);
            String fileContrat = LWC_QuoteCPQGeneratePDF.linkDocumentToRecordForSignea(quote.Id, 'Contrat '+quote.NDevis__c+' - '+dateOfDayFormat, blobContrat, 'Contrat');
            deleteCtDocumentByCategory(quote.Id, fileContrat, 'Contrat');
            System.debug('## SIGNEA - Id Contrat: '+fileContrat);
            if(blobTVA != null){
                fileTVA = LWC_QuoteCPQGeneratePDF.linkDocumentToRecordForSignea(quote.Id, 'Attestation TVA '+quote.NDevis__c+' - '+dateOfDayFormat, blobTVA, 'TVA');
                deleteCtDocumentByCategory(quote.Id, fileTVA, 'TVA');
                System.debug('## SIGNEA - Id TVA: '+fileTVA);
            }

            // D0 - Création de la liste des signataires "client" avec leur position (La position 1 est le vendeur)
            if (quote.autreCompte__c != null) {
                if(signatureType1 != 'Aucun' && signatureType2 != 'Aucun') {
                    signatairesMap.put(quote.SBQQ__Account__r, 2);
                    signatairesMap.put(quote.autreCompte__r, 3);
                } else if(signatureType1 == 'Aucun'){
                    signatairesMap.put(quote.autreCompte__r, 2);
                } else if(signatureType2 == 'Aucun'){
                    signatairesMap.put(quote.SBQQ__Account__r, 2);
                }
            } else {
                signatairesMap.put(quote.SBQQ__Account__r, 2);
            }
            System.debug('## Nb signataires client: ' + signatairesMap.size());
            
            // D1 - Création des 2 circuits (DIPC et Contrat/TVA)
            System.debug( '\n\n\n     ===> création du circuit...\n\n\n' );
            Signea.Signea_Entities_v2.SigneaCircuit circuitDIPC = createCircuitDIPC(signatairesMap.size(), fileDIPC, null);
            Signea.Signea_Entities_v2.SigneaCircuit circuitContrat = createCircuitContrat(signatairesMap.size(), fileContrat, fileTVA, null, null);
            
            // D2 - Création de l'étape unique pour chaque circuit
            Signea.Signea_Entities_v2.SigneaStep stepDIPC = createStep1('DIPC');
            circuitDIPC.stepList.add(stepDIPC);
            System.debug( '\n\n\n     ===> création de l\'étape...\n\n\n' );
            Signea.Signea_Entities_v2.SigneaStep stepContrat = createStep1('Contrat');
            circuitContrat.stepList.add(stepContrat);    
            
            // D3 - Création des signataires principaux et secondaires pour étape 1 (DIPC)
            System.debug( '\n\n\n     ===> création des signataires principaux DIPC...\n\n\n' );
            for(Account acc : signatairesMap.keySet()) {
                stepDIPC.signerList.add(createSignataire(signatairesMap.get(acc), acc, 'devis'));
            }
            stepDIPC.signerList.add(createVendeur());

            // D4 - Création des signataires principaux et secondaires pour étape 2 (Contrat)
            System.debug( '\n\n\n     ===> création des signataires principaux Contrat...\n\n\n' );
            for(Account acc : signatairesMap.keySet()) {
                stepContrat.signerList.add(createSignataire(signatairesMap.get(acc), acc, 'contrat'));
            }
            stepContrat.signerList.add(createVendeur());
            
            // E - Lancement du circuit DIPC
            System.debug('## Circuit DIPC : ' + circuitDIPC);
            System.debug('## Circuit Contrat : ' + circuitContrat);
            Signea.Signea_Entities_V2.SigneaServicesResult launchResult = Signea.Signea_API_V2.createNlaunchCircuit(circuitDIPC);
            System.debug('## DIPC Result : ' + launchResult);
            if ('000'.equalsIgnoreCase(launchResult.errorCode) && launchResult.result != null) {
                if (!'Contrat'.equalsIgnoreCase(documentType)){
                    if(quote.dateTransmissionClient__c == null) quote.dateTransmissionClient__c = System.today();
                    if(quote.moyenTransmissionClient__c == null) quote.moyenTransmissionClient__c = Constants.QUOTE_TRANSMISSION_SIGN_ELECTRONIQUE;
                    quote.circuitSignatureDevis__c = launchResult.result;
                    System.debug('## launchResult.result : ' + launchResult.result);
                }
            } else {
                List<String> params = new String[]{'DIPC',launchResult.errorCode};
                    String message = String.format(Label.signea_msg_ErrorCreationCircuit, params);
                System.debug(message);
                log.addErrorMessage(message);
                return null;
            }
            Signea.Signea_Entities_V2.SigneaServicesResult createResult1 = Signea.Signea_API_V2.createCircuit(circuitContrat);
            System.debug('## Contrat Result : ' + createResult1);
            if ('000'.equalsIgnoreCase(createResult1.errorCode) && createResult1.result != null) {
                quote.circuitSignatureContrat__c = createResult1.result;
            } else {
                List<String> params = new String[]{'Contrat',createResult1.errorCode};
                    String message = String.format(Label.signea_msg_ErrorCreationCircuit, params);
                System.debug(message);
                log.addErrorMessage(message);
                return null;
            }
            // 05/04/19 Modification JMU - RQM-96 pour alimenter les champs de Dérogation SIGNEA
            if(signataire1SignType.endsWith('Face2face')) {
                quote.derogationSigneaPrincipal__c = true;
            }
            if(signataire2SignType.endsWith('Face2face')) {
                quote.derogationSigneaSecondaire__c = true;
            }

            if(user.Id != null) {
                quote.companySigned__c = user.Id;
            }
            update quote;
            
            // Gestion d'une éventuelle erreur d'assignation des circuits sur les champs du devis
            if(quote.circuitSignatureDevis__c == null || quote.circuitSignatureContrat__c == null){
                String circuitErreur = '';
                if(quote.circuitSignatureDevis__c == null) {
                    circuitErreur = 'DIPC';
                } else if(quote.circuitSignatureContrat__c == null) {
                    circuitErreur = 'Contrat';
                }
                List<String> params = new String[]{circuitErreur, String.valueOf(launchResult), String.valueOf(createResult1)};
                String message = String.format(Label.signea_msg_ErrorChampCircuitNull, params);
                System.debug(message);
                log.addErrorMessage(message);
                EmailUtils.reportException('[KUBE] : Erreur de création de circuit de signature électronique', message);
                return null;
            }
        } catch(Exception e) {
            System.debug('ERREUR # Signea : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            log.addErrorMessage(e.getMessage());
            return null;
        }
        refresh(true);
        System.debug('### FIN execute');
        return pageRF;
    }
    
    /**
    * @description Méthode pour rafraichir les informations de la page Visualforce
    * @param isExecuting True si la signature a été exécutée
    */
    private void refresh(Boolean isExecuting) {
        System.debug('### DEBUT refresh');
        System.debug('## isExecuting : ' + isExecuting);
        quoteId = Apexpages.currentPage().getParameters().get('quoteId');
        List<Signea__Circuit__c> circuits = new List<Signea__Circuit__c>();
        
        // Refresh du devis, chantier, comptes et circuits de signatures
        quote = [SELECT id, NDevis__c, NomDevis__c, name, CreatedDate__c, dateTransmissionClient__c, moyenTransmissionClient__c, dateAcceptationClient__c, SBQQ__ExpirationDate__c, totalAmount__c, financingMethod__c,
                financingMethod__r.Name, SBQQ__LineItemCount__c, minCommercialDelay__c , maxCommercialDelay__c , MontantTotalTTC__c, AdditionalDiscountAmountTTC__c,
                 MontantTVAIntermediaire__c, MontantTVAReduite__c, MontantAcompteAttendu__c, natureLocaux__c, autreNatureLocaux__c, montantPrimeCEE__c,
                 localisationTravaux__c, milliemesLocalisationTravaux__c, natureTravaux__c, elementsTravaux__c, typeAdresse__c, termsAndConditions__c,
                 derogationSigneaPrincipal__c, derogationSigneaSecondaire__c, NombrePersonnes__c, revenusFiscaux__c, zone__c, OwnerId, SBQQ__Type__c,
                 
                 companySigned__c, companySigned__r.name, companySigned__r.Username, companySigned__r.ProfileName__c, companySigned__r.FirstName, companySigned__r.LastName,
                 companySigned__r.Email, companySigned__r.Phone, companySigned__r.CodeMagasin__c, companySigned__r.libelleMagasin__c, companySigned__r.CodeDV__c, companySigned__r.LibelleDV__c,
                 
                 SBQQ__Opportunity2__r.chantier__r.nbPortesEtFenetres__c, SBQQ__Opportunity2__r.chantier__r.rue__c, SBQQ__Opportunity2__r.chantier__r.complementAdresse__c,
                 SBQQ__Opportunity2__r.chantier__r.codePostal__c, SBQQ__Opportunity2__r.chantier__r.ville__c, SBQQ__Opportunity2__r.chantier__r.typeResidence__c,
                 SBQQ__Opportunity2__r.chantier__r.numeroChantier__c, SBQQ__Opportunity2__r.chantier__r.Name, SBQQ__Opportunity2__r.chantier__r.Id,
                 
                 SBQQ__Account__c, SBQQ__Account__r.rue__c, SBQQ__Account__r.complementAdresse__c, SBQQ__Account__r.codePostal__c, SBQQ__Account__r.ville__c, SBQQ__Account__r.pays__c,
                 SBQQ__Account__r.Salutation, SBQQ__Account__r.email__c, SBQQ__Account__r.telephoneDomicile__c, SBQQ__Account__r.telephoneMobile__c, SBQQ__Account__r.autreTelephone__c,
                 SBQQ__Account__r.isPersonAccount, SBQQ__Account__r.personContactId, SBQQ__Account__r.personEmail, SBQQ__Account__r.contactParDefaut__c, SBQQ__Account__r.contactParDefaut__r.email,
                 SBQQ__Account__r.Id, SBQQ__Account__r.nom__c, SBQQ__Account__r.prenom__c, SBQQ__Account__r.AccountNumber,
                 
                 autreCompte__c, autreCompte__r.rue__c, autreCompte__r.complementAdresse__c, autreCompte__r.codePostal__c, autreCompte__r.ville__c, autreCompte__r.pays__c,
                 autreCompte__r.Salutation, autreCompte__r.email__c, autreCompte__r.telephoneDomicile__c, autreCompte__r.telephoneMobile__c, autreCompte__r.autreTelephone__c,
                 autreCompte__r.isPersonAccount, autreCompte__r.personContactId, autreCompte__r.personEmail, autreCompte__r.contactParDefaut__c, autreCompte__r.contactParDefaut__r.email,
                 autreCompte__r.Id, autreCompte__r.nom__c, autreCompte__r.prenom__c, autreCompte__r.AccountNumber,
                 circuitSignatureDevis__c, circuitSignatureDevis__r.createdDate, circuitSignatureDevis__r.Signea__LaunchDate__c, circuitSignatureDevis__r.Signea__Expiration_Date__c, circuitSignatureDevis__r.Signea__CompletedDate__c, circuitSignatureDevis__r.Signea__Status__c, circuitSignatureDevis__r.Signea__Document_URL__c,
                 circuitSignatureContrat__c, circuitSignatureContrat__r.createdDate, circuitSignatureContrat__r.Signea__LaunchDate__c, circuitSignatureContrat__r.Signea__Expiration_Date__c, circuitSignatureContrat__r.Signea__CompletedDate__c,  circuitSignatureContrat__r.Signea__Status__c, circuitSignatureContrat__r.Signea__Document_URL__c
                 
                 FROM SBQQ__Quote__c WHERE id = :quoteId];
        
        String statusDIPC = quote.circuitSignatureDevis__r.Signea__Status__c;
        String statusContrat = quote.circuitSignatureContrat__r.Signea__Status__c;
        String compteContactId = (quote.SBQQ__Account__r.isPersonAccount) ? quote.SBQQ__Account__r.PersonContactId : quote.SBQQ__Account__r.contactParDefaut__c;
        String autreCompteContactId = (quote.autreCompte__r.isPersonAccount) ? quote.autreCompte__r.PersonContactId : quote.autreCompte__r.contactParDefaut__c;
        
        // Récupération des étapes du circuit (devis, contrat, TVA)
        circuits = [SELECT Id, createdDate, Signea__LaunchDate__c, Signea__Expiration_Date__c, Signea__Status__c, Signea__test_list__c, Signea__CompletedDate__c, 
                    lancementAutomatique__c, hasBeenLaunched__c
                    FROM Signea__Circuit__c
                    WHERE Id = :quote.circuitSignatureDevis__c OR Id = :quote.circuitSignatureContrat__c]; //  OR Id = :quote.circuitSignatureTVA__c
        for(Signea__Circuit__c circuit : circuits){
            System.debug('## circuit.Id : ' + circuit.Id);
            System.debug('## quote.circuitSignatureDevis__c : ' + quote.circuitSignatureDevis__c);
            System.debug('## quote.circuitSignatureContrat__c : ' + quote.circuitSignatureContrat__c);
            if(circuit.Id == quote.circuitSignatureDevis__c){
                storedCircuitDIPC = circuit;
            } else if(circuit.Id == quote.circuitSignatureContrat__c){
                storedCircuitContrat = circuit;
            }
        }
        if (quote.circuitSignatureContrat__c != null) { // Devis/DIPC envoyé --> Etape suivante = contrat
            documentType = 'Contrat';
        } else if (quote.circuitSignatureDevis__c != null) { // Devis/DIPC envoyé --> Etape suivante = contrat
            documentType = 'DIPC';
        } else {
            documentType = 'null'; // Sinon DIPC
        }
        System.debug('## Document Type : ' + documentType);
        
        // Initialisation des variables
        if(statusDIPC != null) {
            devisShowExpire = (checkIsCompleted(statusDIPC) || statusDIPC == 'Cancelled' || statusDIPC == 'Expired' || statusDIPC == 'Refused') ? false : true;
        } else {
            devisShowExpire = true;
        }
        if(statusContrat != null) {
            contratShowExpire = (checkIsCompleted(statusContrat) || statusContrat == 'Cancelled' || statusContrat == 'Expired' || statusContrat == 'Refused') ? false : true;
        } else {
            contratShowExpire = true;
        }

        if (quote.dateAcceptationClient__c != null   ||                                  // Devis vendu
            //etapeContrat != null ||                                                      // Circuit de signature du contrat en cours ou terminé
            (quote.circuitSignatureDevis__c != null && (!checkIsCompleted(statusDIPC) && statusDIPC != 'Refused'))) { // Circuit de signature du devis --> Ne pas proposer de signature électronique, juste de la consultation
            documentType = null;
        } else if (quote.dateTransmissionClient__c != null && quote.circuitSignatureDevis__c != null) { // Devis/DIPC envoyé --> Etape suivante = contrat
            documentType = 'Contrat';
        } else {
            documentType = 'DIPC'; // Sinon DIPC
        }
        System.debug('## Document Type : ' + documentType);
        
        //ID circuitID = (documentType == null || 'Contrat'.equalsIgnoreCase(documentType)) ? quote.circuitSignatureContrat__c : quote.circuitSignatureDevis__c
        
        if (!isExecuting) {
            if (quote.circuitSignatureDevis__c != null) {
                List<Signea__Signer__c> signers = [SELECT Id, Signea__FirstName__c, Signea__LastName__c, Signea__Position__c, 
                                                   Signea__Status__c, Signea__URL__c, Signea__Contact__c, Signea__User__c
                                                   FROM Signea__Signer__c
                                                   WHERE Signea__Circuit__c = :quote.circuitSignatureDevis__c AND Signea__Signea_Step__r.Signea__Step_Number__c = 1
                                                   ORDER BY Signea__Position__c];                 
                // Récupération des signataires
                for(Signea__Signer__c sign : signers) {                 
                    if (sign.Signea__Contact__c == compteContactId) {
                        DIPCSigner1 = JSON.serialize(sign);         
                    }
                    if (String.isNotBlank(autreCompteContactId) && sign.Signea__Contact__c == autreCompteContactId) {
                        DIPCSigner2 = JSON.serialize(sign);
                    } 
                    if (String.isNotBlank(sign.Signea__User__c) && sign.Signea__User__c == quote.companySigned__c) {
                        DIPCVendeur = JSON.serialize(sign);
                    }
                }
            }
            if (quote.circuitSignatureContrat__c != null) {
                List<Signea__Signer__c> signers = [SELECT Id, Signea__FirstName__c, Signea__LastName__c, Signea__Position__c, 
                                                   Signea__Status__c, Signea__URL__c, Signea__Contact__c, Signea__User__c
                                                   FROM Signea__Signer__c
                                                   WHERE Signea__Circuit__c = :quote.circuitSignatureContrat__c AND Signea__Signea_Step__r.Signea__Step_Number__c = 1 // STABILISATION
                                                   ORDER BY Signea__Position__c];
                // Récupération des signataires
                for(Signea__Signer__c sign : signers) {                 
                    if (sign.Signea__Contact__c == compteContactId) {
                        contratSigner1 = JSON.serialize(sign);          
                    }
                    if (String.isNotBlank(autreCompteContactId) && sign.Signea__Contact__c == autreCompteContactId) {
                        contratSigner2 = JSON.serialize(sign);
                    }
                    if (String.isNotBlank(sign.Signea__User__c) && sign.Signea__User__c == quote.companySigned__c) {
                        contratVendeur = JSON.serialize(sign);
                    }  
                }
            }
            
            // Type de signature par défaut, manuscrite si 1 RDV en cours
            List<Event> events = [SELECT Id FROM Event
                                  WHERE RecordTypeId = :RT_RDV_COMMERCIAL
                                  AND Type = :Constants.EVENT_TYPE_R1
                                  AND OwnerId = :userInfo.getUserId()
                                  AND DAY_ONLY(StartDateTime) >= :date.today()
                                  AND DAY_ONLY(EndDateTime) <= :date.today()
                                  AND WhatId = :quote.SBQQ__Opportunity2__c];
            DEFAULT_SIGNATURETYPE = (!events.isEmpty()) ? 'PAD' : 'OTP';
            System.debug('## DEFAULT_SIGNATURETYPE : ' + DEFAULT_SIGNATURETYPE);            
        } else {
            for(Signea__Circuit__c circuit : circuits){
                if(circuit.Id == quote.circuitSignatureDevis__c){
                    circuit.lancementAutomatique__c = true;
                } else if(circuit.Id == quote.circuitSignatureContrat__c){
                    circuit.lancementAutomatique__c = autoLaunchField;
                }
            }
            
            update circuits;
        }
        System.debug('### FIN refresh');
    }
    
    /**
    * @description Lancement du circuit de contrat (manuellement par l'utilisateur)
    * @return PageReference Page Visualforce Signea
    */
    public PageReference launchManualCircuit() {
        System.debug('### DEBUT launchManualCircuit');
        log.clear();
        
        // Init informations page
        PageReference pageRF = Page.VF_Signea_CPQ;
        pageRF.setRedirect(true);
        pageRF.getParameters().put('quoteId', quoteId);
        try {
            storedCircuitContrat.hasBeenLaunched__c = true;
            update storedCircuitContrat;
        } catch(Exception e) {
            System.debug('ERREUR # Signea : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            log.addErrorMessage(e.getMessage());
            return null;
        }
        refresh(true);
        System.debug('### FIN launchManualCircuit');
        return pageRF;
    }
    
    /**
    * @description Fonction de vérification du contexte pour création du circuit
    * Affichage des messages d'erreur
    */
    public void checkContext() {
        // Erreurs génériques
        // 01 - Pour un signataire principal B2B, il faut un contact par défaut
        Boolean errorContactParDefaut1 = !quote.SBQQ__Account__r.isPersonAccount && quote.SBQQ__Account__r.contactParDefaut__c == null;
        // 02 - Pour un signataire secondaire B2B, il faut un contact par défaut
        Boolean errorContactParDefaut2 = quote.autreCompte__c != null && !quote.autreCompte__r.isPersonAccount && quote.autreCompte__r.contactparDefaut__c == null;
        // 03 - Il faut l'email du signataire principal pour l'envoi de la signataure
        Boolean errorSansEmail1 = String.isBlank(quote.SBQQ__Account__r.isPersonAccount ? quote.SBQQ__Account__r.personEmail : quote.SBQQ__Account__r.contactParDefaut__r.email);
        // 04 - Il faut l'email du signataire secondaire pour l'envoi de la signataure
        Boolean errorSansEmail2 = quote.autreCompte__c != null && String.isBlank(quote.autreCompte__r.isPersonAccount ? quote.autreCompte__r.personEmail : quote.autreCompte__r.contactParDefaut__r.email);
        // 05 - Devis expiré
        Boolean errorExpire = quote.SBQQ__ExpirationDate__c != null && System.today() > quote.SBQQ__ExpirationDate__c;
        // 06 - Montant du projet non renseigné
        Boolean errorMontant = quote.totalAmount__c == null || quote.totalAmount__c <= 0;
        // 07 - Mode de financement non renseigné
        Boolean errorModeFinancement = String.isBlank(quote.financingMethod__c);
        // 08 - Devis non configuré
        Boolean errorConfiguration = quote.SBQQ__LineItemCount__c == null || quote.SBQQ__LineItemCount__c < 0 ;
        
        // Erreurs liées au contrat
        // 24 - Contrat déjà signé --> Lecture seule
        Boolean errorReadOnly = (documentType == null);
        
        // Erreurs liées au devis
        // 30 - Délai d'installation non renseigné
        Boolean errorDelaiInstallation = quote.minCommercialDelay__c  == null || quote.maxCommercialDelay__c  == null;
        // 31 - Pris de vente au-dessus du tarif
        Decimal totalTTCDevis = 0; Decimal totalTTCDevisHorsRemise = 0; Decimal remise = 0;
        if(quote.totalAmount__c !=null) totalTTCDevis = Math.round(quote.totalAmount__c);
        if(quote.MontantTotalTTC__c!=null) totalTTCDevisHorsRemise = Math.round(quote.MontantTotalTTC__c);
        if(quote.AdditionalDiscountAmountTTC__c!=null) remise = Math.round(quote.AdditionalDiscountAmountTTC__c);
        Boolean errorTarif = ((totalTTCDevis-1) <= (totalTTCDevisHorsRemise+remise)) ? false : true;
        // 32 - Le devis ne doit pas avoir de date de signature 
        Boolean errorDateSignRenseigne = quote.dateAcceptationClient__c != null;
        // 33 - Le devis ne doit pas avoir de date de transmission si le devis a été signé électroniquement
        Boolean errorTransmisElectroniqueRenseigne = quote.dateTransmissionClient__c != null && (quote.circuitSignatureDevis__c != null || quote.circuitSignatureContrat__c != null);
        // 34 - Délais d’installation min inférieur au max
        Boolean errorDelaiInstallationMaxSupMin = quote.minCommercialDelay__c  > quote.maxCommercialDelay__c ;
        // 35 - Montant de l’acompte attendu non vide et obligatoirement compris entre 0 (inclus) et montant TTC du projet (inclus)
        Boolean errorAccountAttendu = quote.MontantAcompteAttendu__c == null || quote.MontantAcompteAttendu__c < 0 || quote.MontantAcompteAttendu__c > quote.totalAmount__c;
        
        // Erreurs liées à l'attestation TVA
        Boolean errorNatureLocaux = false;
        Boolean errorLocalisationTravaux = false;
        if(quote.MontantTVAIntermediaire__c != 0 || quote.MontantTVAReduite__c != 0) {
            // 40 - Nature des locaux obligatoire. Si nature des locaux = « Autre », alors autre nature des locaux obligatoire
            errorNatureLocaux = (String.isBlank(quote.natureLocaux__c) || (quote.natureLocaux__c == Constants.QUOTE_NATURELOCAUX_AUTRE && String.isBlank(quote.autreNatureLocaux__c)));
            // 41 - Localisation des travaux obligatoires. Si localisation = « Partie commune », alors millièmes obligatoires
            errorLocalisationTravaux = (String.isBlank(quote.localisationTravaux__c) || (quote.localisationTravaux__c == Constants.QUOTE_LOCALISATIONTRAVAUX_PARTIES_COMMUNES && quote.milliemesLocalisationTravaux__c == null));
        }
        
        // 42 - Nature des travaux obligatoire. Si nature des travaux contient « Sans impact sur > 5/6 éléments suivants », alors Elements des travaux obligatoires
        Boolean errorNatureTravaux = (String.isBlank(quote.natureTravaux__c) || (quote.natureTravaux__c == Constants.QUOTE_NATURETRAVAUX_ELEMENTS && String.isBlank(quote.elementsTravaux__c)));
        // 43 - Type d’adresse obligatoire
        Boolean errorTypeAdresse = String.isBlank(quote.typeAdresse__c);
        
        // Si pas d'attestation TVA ou si SAV, ignorer ces erreurs
        if(quote.SBQQ__Type__c == 'SAV' || (quote.MontantTVAIntermediaire__c == 0 && quote.MontantTVAReduite__c == 0)) {
            errorNatureLocaux = errorLocalisationTravaux = errorNatureTravaux = errorTypeAdresse = false;
        }
        if(quote.SBQQ__Type__c == 'SAV') {
            errorDelaiInstallationMaxSupMin = false;
        }

        
        // Erreurs liées au chantier
        // 50 - Nombre de fenêtres et portes-fenêtres non renseigné
        Boolean errorFenetres = quote.SBQQ__Opportunity2__r.chantier__r.nbPortesEtFenetres__c == null && (typeContrat.containsIgnoreCase('MENUISERIE') );
        // 51 - Le type de résidence doit être renseigné
        Boolean errorResid = String.isBlank(quote.SBQQ__Opportunity2__r.chantier__r.typeResidence__c);
        
        Boolean found = errorContactParDefaut1 || errorContactParDefaut2 ||
            errorSansEmail1 || errorSansEmail2 ||
            errorExpire ||
            errorMontant || errorModeFinancement || errorConfiguration ||
            errorReadOnly ||
            errorDelaiInstallation || errorTarif || errorDateSignRenseigne || errorTransmisElectroniqueRenseigne || errorDelaiInstallationMaxSupMin ||
            errorAccountAttendu ||
            errorNatureLocaux || errorLocalisationTravaux || errorNatureTravaux || errorTypeAdresse ||
            errorFenetres || errorResid;
        
        if (found) {
            String errDetails = '';
            // Erreurs génériques
            if (errorContactParDefaut1)
                errDetails += '<br/>- Signataire principal sans contact par défaut';
            if (errorContactParDefaut2)
                errDetails += '<br/>- Signataire secondaire sans contact par défaut';
            if (errorSansEmail1)
                errDetails += '<br/>- Signataire principal sans email';
            if (errorSansEmail2)
                errDetails += '<br/>- Signataire secondaire sans email';
            if (errorExpire )
                errDetails += '<br/>- Devis expiré';
            if (errorMontant)
                errDetails += '<br/>- Montant TTC du projet invalide';
            if (errorModeFinancement)
                errDetails += '<br/>- Mode de financement non renseigné';
            if (errorConfiguration)
                errDetails += '<br/>- Devis non configuré';
            
            // Erreur liées au contrat
            if (errorReadOnly)
                errDetails += '<br/>- Contrat déjà signé ! Mode lecture seule.';
            
            // Erreurs liées au devis
            if (errorDelaiInstallation)
                errDetails += '<br/>- Délai d\'installation non renseigné';
            if (errorTarif)
                errDetails += '<br/>- Prix de vente du devis au dessus du tarif';
            if (errorDateSignRenseigne)
                errDetails += '<br/>- Le devis ne doit pas avoir de date de signature';
            if (errorTransmisElectroniqueRenseigne) 
                errDetails += '<br/>- Le devis ne doit pas avoir de date de transmission si ce dernier fait parti d\'un circuit de signature électronique';
            if (errorDelaiInstallationMaxSupMin)
                errDetails += '<br/>- Le délai d\'installation minimum doit être inférieur au délai maximum d\'installation';
            if (errorAccountAttendu)
                errDetails += '<br/>- Montant de l’acompte attendu non vide et obligatoirement compris entre 0 (inclus) et montant TTC du projet (inclus)';
            
            // Erreurs liées à l'attestation TVA
            if (errorNatureLocaux)
                errDetails += '<br/>- Nature des locaux obligatoire. Si nature des locaux = « Autre », alors autre nature des locaux obligatoire';
            if (errorLocalisationTravaux)
                errDetails += '<br/>- Localisation des travaux obligatoires. Si localisation = « Partie commune », alors millièmes obligatoires';
            if (errorNatureTravaux)
                errDetails += '<br/>- Nature des travaux obligatoire. Si nature des travaux contient « Sans impact sur > 5/6 éléments suivants, alors Elements des travaux obligatoires';
            if (errorTypeAdresse)
                errDetails += '<br/>- Type d’adresse obligatoire';
            
            // Erreurs liées au chantier
            if (errorFenetres)
                errDetails += '<br/>- Nombre de fenêtres et portes-fenêtres non renseigné sur le chantier';
            if(errorResid)
                errDetails += '<br/>- Sur le chantier, le type de résidence doit être renseigné';
            
            String message = Label.signea_msg_ErrorCheckContext + errDetails;
            throw new KubeException(message);
        }
    }
    
    /**
    * @description Fonction de création de signataire pour étape du circuit de type client
    * @param participantNumber Numéro du partipant (obsolète)
    * @param account Information du signataire
    * @param typeDoc Type de document à fournir obligatoirement si contrat
    * @return Signea.Signea_Entities_v2.SigneaSigner Objet de signatire Signea
    */
    public Signea.Signea_Entities_v2.SigneaSigner createSignataire(Integer participantNumber, Account account, String typeDoc) {    
        Signea.Signea_Entities_v2.SigneaSigner signataire = new Signea.Signea_Entities_v2.SigneaSigner();
        signataire.signerType = 'C';                                                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
        signataire.signerId = account.isPersonAccount ? account.PersonContactId : account.contactParDefaut__c;      // Id du signataire
        
        signataire.participantNumber = participantNumber; 
        signataire.position = participantNumber;
        signataire.recipientType = (participantNumber == 2 && signatureType1 != 'Aucun')? recipientType1 : recipientType2;
        signataire.signatureType = (participantNumber == 2 && signatureType1 != 'Aucun')? signatureType1 : signatureType2;

        /* >>> F.G., le 01/12/2016 - Décision Rodolphe suite réunion validation contrat SIGNEA
        if (typeDoc == 'contrat')
            signataire.documentaryEvidenceList = createEvidences(account);
           <<< F.G., le 01/12/2016 - Décision Rodolphe suite réunion validation contrat SIGNEA */
        return signataire;
    }
    
    /**
    * @description Fonction de création de signataire pour étape du circuit de type vendeur
    * @return Signea.Signea_Entities_v2.SigneaSigner Objet de signatire Signea
    */
    public Signea.Signea_Entities_v2.SigneaSigner createVendeur() {
        Signea.Signea_Entities_v2.SigneaSigner vendeur = new Signea.Signea_Entities_v2.SigneaSigner();
        vendeur.signerType = 'U';                      // Signataire de type 'Contact'. 'U' pour 'Utilisateur' et 'L' pour 'Prospect' ('Lead' en anglais)
        vendeur.signerId = user.Id;  // Id du signataire
        vendeur.recipientType = recipientTypeVendeur;
        vendeur.signatureType = signatureTypeVendeur;
        
        vendeur.participantNumber = 1; // Premier participant obligatoirement
        vendeur.position = 1;
        return vendeur;
    }
    
    /**
    * @description Fonction de création du circuit de signature DIPC
    * @param fileId Id du document en PDF (DIPC) 
    * @return Signea.Signea_Entities_v2.SigneaCircuit Objet de circuit Signea
    */
    private Signea.Signea_Entities_v2.SigneaCircuit createCircuitDIPC(Integer nbSignataires, Id fileId, Id attachmentId) {
        Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();

        // Circuit
        circuit.name = 'DIPC (' + quote.NDevis__c + ')';
        circuit.description = 'Circuit de signature du ' + circuit.name;
        circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();
        circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
        circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
        if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true)) {
            circuit.keywords = 'NumDevis=' + quote.NDevis__c + ', RaisonSociale=K par K';
        }
        circuit.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
        
        // Récupération des paramètres de position des signatures        
        String sign1Pos = PropertiesUtils.getStringValue('signea.cpq.dipc.sign1.position', 'width="100" height="50" x="350" y="83"');
        String sign2Pos = PropertiesUtils.getStringValue('signea.cpq.dipc.sign2.position', 'width="100" height="50" x="461" y="83"');
        String vendeurPos = PropertiesUtils.getStringValue('signea.cpq.dipc.vendeur.position', 'width="100" height="50" x="70" y="83"');

        // Document à signer
        Signea.Signea_Entities_v2.SigneaDocument doc = new Signea.Signea_Entities_v2.SigneaDocument();
        doc.id = fileId;
        /** */
        doc.metadata = '<?xml version="1.0" encoding="UTF-8"?><metadata xmlns="http://www.contralia.fr/metadata">';
        doc.metadata += '<participants>';
        doc.metadata += '<participant number="1" name="Participant1" clientRef=""/>';
        doc.metadata += '<participant number="2" name="Participant2" clientRef=""/>';
        doc.metadata += '<participant number="3" name="Participant3" clientRef=""/>';
        doc.metadata += '<participant number="4" name="Participant4" clientRef=""/>';
        doc.metadata += '<participant number="5" name="Participant5" clientRef=""/>';
        doc.metadata += '<participant number="6" name="Participant6" clientRef=""/>';
        doc.metadata += '<participant number="7" name="Participant7" clientRef=""/>';
        doc.metadata += '<participant number="8" name="Participant8" clientRef=""/>';
        doc.metadata += '<participant number="9" name="Participant9" clientRef=""/>';
        doc.metadata += '<participant number="10" name="Participant10" clientRef=""/>';
        doc.metadata += '</participants>';
        doc.metadata += '<fields>';
        doc.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="1" imported="" name="vendeur" ' + vendeurPos +' fontSize="12.0" page="4" value="" group="" font="" />';
        doc.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="2" imported="" name="client1" ' + sign1Pos +' fontSize="12.0" page="4" value="" group="" font="" />';
        if (nbSignataires > 1) {
            doc.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="3" imported="" name="client2" ' + sign2Pos +' fontSize="12.0" page="4" value="" group="" font="" />';
        }
        doc.metadata += '</fields>';
        doc.metadata += '<values>';
        doc.metadata += '<value fieldName="vendeur" value=""/>';
        doc.metadata += '<value fieldName="client1" value=""/>';
        if (nbSignataires > 1) {
            doc.metadata += '<value fieldName="client2" value=""/>';
        }
        doc.metadata += '</values>';
        doc.metadata += '</metadata>';
        /* */ 
        circuit.documentList.add(doc);

        // ATTACHMENT
        /*Signea.Signea_Entities_v2.SigneaDocument doc2 = new Signea.Signea_Entities_v2.SigneaDocument();
        doc2.id = attachmentId;
        doc2.metadata = '<?xml version="1.0" encoding="UTF-8"?><metadata xmlns="http://www.contralia.fr/metadata">';
        doc2.metadata += '<participants>';
        doc2.metadata += '<participant number="1" name="Participant1" clientRef=""/>';
        doc2.metadata += '<participant number="2" name="Participant2" clientRef=""/>';
        doc2.metadata += '<participant number="3" name="Participant3" clientRef=""/>';
        doc2.metadata += '<participant number="4" name="Participant4" clientRef=""/>';
        doc2.metadata += '<participant number="5" name="Participant5" clientRef=""/>';
        doc2.metadata += '<participant number="6" name="Participant6" clientRef=""/>';
        doc2.metadata += '<participant number="7" name="Participant7" clientRef=""/>';
        doc2.metadata += '<participant number="8" name="Participant8" clientRef=""/>';
        doc2.metadata += '<participant number="9" name="Participant9" clientRef=""/>';
        doc2.metadata += '<participant number="10" name="Participant10" clientRef=""/>';
        doc2.metadata += '</participants>';
        doc2.metadata += '<fields>';
        doc2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="1" imported="" name="vendeur" ' + vendeurPos +' fontSize="12.0" page="1" value="" group="" font="" />';
        doc2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="2" imported="" name="client1" ' + sign1Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
        if (nbSignataires > 1) {
            doc2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="3" imported="" name="client2" ' + sign2Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
        }
        doc2.metadata += '</fields>';
        doc2.metadata += '<values>';
        doc2.metadata += '<value fieldName="vendeur" value=""/>';
        doc2.metadata += '<value fieldName="client1" value=""/>';
        if (nbSignataires > 1) {
            doc2.metadata += '<value fieldName="client2" value=""/>';
        }
        doc2.metadata += '</values>';
        doc2.metadata += '</metadata>';
        circuit.documentList.add(doc2);*/

        System.debug('doc metadata : '+doc.metadata);
        return circuit;
    }
    
    /**
    * @description Fonction de création du circuit de signature CONTRAT
    * @param nbSignataires Nombre de clients à signer 
    * @param contratFileId Id du document en PDF (Contrat) 
    * @param tvaFileId Id du document en PDF (TVA) 
    * @return Signea.Signea_Entities_v2.SigneaCircuit Objet de circuit Signea
    */
    private Signea.Signea_Entities_v2.SigneaCircuit createCircuitContrat(Integer nbSignataires, Id contratFileId, Id tvaFileId, Id contratAttachmentId, Id tvaAttachmentId) {
        Signea.Signea_Entities_v2.SigneaCircuit circuit = new Signea.Signea_Entities_v2.SigneaCircuit();

        // Circuit
        circuit.name = 'Contrat (' + quote.NDevis__c + ')';
        circuit.description = 'Circuit de signature du ' + circuit.name;
        circuit.stepList = new List<Signea.Signea_Entities_v2.SigneaStep>();

        circuit.documentList = new List<Signea.Signea_Entities_v2.SigneaDocument>();
        circuit.notifyCreator = PropertiesUtils.getBooleanValue('signea.circuit.notifyCreator', true) ? 'true' : 'false';
        if (PropertiesUtils.getBooleanValue('signea.circuit.enabledKeywords', true)) {
            circuit.keywords = 'NumDevis=' + quote.NDevis__c + ', RaisonSociale=K par K';
        }
        circuit.referenceFournisseur = PropertiesUtils.getStringValue('signea.circuit.referenceFournisseur', 'K par K');
        
        // Récupération des paramètres de position des signatures        
        String sign1Pos = PropertiesUtils.getStringValue('signea.cpq.contrat.sign1.position', 'width="100" height="50" x="350" y="85"');
        String sign2Pos = PropertiesUtils.getStringValue('signea.cpq.contrat.sign2.position', 'width="100" height="50" x="461" y="85"');
        String vendeurPos = PropertiesUtils.getStringValue('signea.cpq.contrat.vendeur.position', 'width="100" height="50" x="461" y="85"');

        // Création du document à signer "Contrat"
        Signea.Signea_Entities_v2.SigneaDocument doc = new Signea.Signea_Entities_v2.SigneaDocument();
        doc.id = contratFileId;
        doc.rank = 1;
        /* */
        doc.metadata = '<?xml version="1.0" encoding="UTF-8"?><metadata xmlns="http://www.contralia.fr/metadata">';
        doc.metadata += '<participants>';
        doc.metadata += '<participant number="1" name="Participant1" clientRef=""/>';
        doc.metadata += '<participant number="2" name="Participant2" clientRef=""/>';
        doc.metadata += '<participant number="3" name="Participant3" clientRef=""/>';
        doc.metadata += '<participant number="4" name="Participant4" clientRef=""/>';
        doc.metadata += '<participant number="5" name="Participant5" clientRef=""/>';
        doc.metadata += '<participant number="6" name="Participant6" clientRef=""/>';
        doc.metadata += '<participant number="7" name="Participant7" clientRef=""/>';
        doc.metadata += '<participant number="8" name="Participant8" clientRef=""/>';
        doc.metadata += '<participant number="9" name="Participant9" clientRef=""/>';
        doc.metadata += '<participant number="10" name="Participant10" clientRef=""/>';
        doc.metadata += '</participants>';
        doc.metadata += '<fields>';
        doc.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="1" imported="" name="vendeur" ' + vendeurPos +' fontSize="12.0" page="4" value="" group="" font="" />';
        doc.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="2" imported="" name="client1" ' + sign1Pos +' fontSize="12.0" page="4" value="" group="" font="" />';
        if (nbSignataires > 1) {
            doc.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="3" imported="" name="client2" ' + sign2Pos +' fontSize="12.0" page="4" value="" group="" font="" />';
        }
        doc.metadata += '</fields>';
        doc.metadata += '<values>';
        doc.metadata += '<value fieldName="vendeur" value=""/>';
        doc.metadata += '<value fieldName="client1" value=""/>';
        if (nbSignataires > 1) {
            doc.metadata += '<value fieldName="client2" value=""/>';
        }
        doc.metadata += '</values>';
        doc.metadata += '</metadata>';
        /* */
        circuit.documentList.add(doc);

         // Création du document à signer "Contrat"
        /*Signea.Signea_Entities_v2.SigneaDocument doc2 = new Signea.Signea_Entities_v2.SigneaDocument();
        doc2.id = contratAttachmentId;
        doc2.rank = 1;
        doc2.metadata = '<?xml version="1.0" encoding="UTF-8"?><metadata xmlns="http://www.contralia.fr/metadata">';
        doc2.metadata += '<participants>';
        doc2.metadata += '<participant number="1" name="Participant1" clientRef=""/>';
        doc2.metadata += '<participant number="2" name="Participant2" clientRef=""/>';
        doc2.metadata += '<participant number="3" name="Participant3" clientRef=""/>';
        doc2.metadata += '<participant number="4" name="Participant4" clientRef=""/>';
        doc2.metadata += '<participant number="5" name="Participant5" clientRef=""/>';
        doc2.metadata += '<participant number="6" name="Participant6" clientRef=""/>';
        doc2.metadata += '<participant number="7" name="Participant7" clientRef=""/>';
        doc2.metadata += '<participant number="8" name="Participant8" clientRef=""/>';
        doc2.metadata += '<participant number="9" name="Participant9" clientRef=""/>';
        doc2.metadata += '<participant number="10" name="Participant10" clientRef=""/>';
        doc2.metadata += '</participants>';
        doc2.metadata += '<fields>';
        doc2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="1" imported="" name="vendeur" ' + vendeurPos +' fontSize="12.0" page="1" value="" group="" font="" />';
        doc2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="2" imported="" name="client1" ' + sign1Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
        if (nbSignataires > 1) {
            doc2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="3" imported="" name="client2" ' + sign2Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
        }
        doc2.metadata += '</fields>';
        doc2.metadata += '<values>';
        doc2.metadata += '<value fieldName="vendeur" value=""/>';
        doc2.metadata += '<value fieldName="client1" value=""/>';
        if (nbSignataires > 1) {
            doc2.metadata += '<value fieldName="client2" value=""/>';
        }
        doc2.metadata += '</values>';
        doc2.metadata += '</metadata>';
        circuit.documentList.add(doc2);
 
        System.debug('doc metadata : '+doc2.metadata);*/
         
        // Récupération des paramètres de position des signatures        
        String attSign1Pos = PropertiesUtils.getStringValue('signea.attestationTVA.sign1.position', 'width="150" height="50" x="173" y="70"');
        String attSign2Pos = PropertiesUtils.getStringValue('signea.attestationTVA.sign2.position', 'width="150" height="50" x="332" y="70"');
 
         // Création du document à signer "Attestation TVA"
         if(tvaFileId != null) {
             Signea.Signea_Entities_v2.SigneaDocument documentTVA = new Signea.Signea_Entities_v2.SigneaDocument();
             documentTVA.id = tvaFileId;
             documentTVA.rank = 2;
             documentTVA.metadata = '<?xml version="1.0" encoding="UTF-8"?><metadata xmlns="http://www.contralia.fr/metadata">';
             documentTVA.metadata += '<participants>';
             documentTVA.metadata += '<participant number="1" name="Participant1" clientRef=""/>';
             documentTVA.metadata += '<participant number="2" name="Participant2" clientRef=""/>';
             documentTVA.metadata += '<participant number="3" name="Participant3" clientRef=""/>';
             documentTVA.metadata += '<participant number="4" name="Participant4" clientRef=""/>';
             documentTVA.metadata += '<participant number="5" name="Participant5" clientRef=""/>';
             documentTVA.metadata += '<participant number="6" name="Participant6" clientRef=""/>';
             documentTVA.metadata += '<participant number="7" name="Participant7" clientRef=""/>';
             documentTVA.metadata += '<participant number="8" name="Participant8" clientRef=""/>';
             documentTVA.metadata += '<participant number="9" name="Participant9" clientRef=""/>';
             documentTVA.metadata += '<participant number="10" name="Participant10" clientRef=""/>';
             documentTVA.metadata += '</participants>';
             documentTVA.metadata += '<fields>';
             documentTVA.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="2" imported="" name="client1" ' + attSign1Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
             if (nbSignataires > 1) {
                 documentTVA.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="3" imported="" name="client2" ' + attSign2Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
             }
             documentTVA.metadata += '</fields>';
             documentTVA.metadata += '<values>';
             documentTVA.metadata += '<value fieldName="client1" value=""/>';
             if (nbSignataires > 1) {
                 documentTVA.metadata += '<value fieldName="client2" value=""/>';
             }
             documentTVA.metadata += '</values>';
             documentTVA.metadata += '</metadata>';
             circuit.documentList.add(documentTVA);
        }

        System.debug('doc metadata : '+doc.metadata);
        
        // Création du document à signer "Attestation TVA"
        /*if(tvaFileId != null) {
            Signea.Signea_Entities_v2.SigneaDocument documentTVA2 = new Signea.Signea_Entities_v2.SigneaDocument();
            documentTVA2.id = tvaAttachmentId;
            documentTVA2.rank = 2;

            documentTVA2.metadata = '<?xml version="1.0" encoding="UTF-8"?><metadata xmlns="http://www.contralia.fr/metadata">';
            documentTVA2.metadata += '<participants>';
            documentTVA2.metadata += '<participant number="1" name="Participant1" clientRef=""/>';
            documentTVA2.metadata += '<participant number="2" name="Participant2" clientRef=""/>';
            documentTVA2.metadata += '<participant number="3" name="Participant3" clientRef=""/>';
            documentTVA2.metadata += '<participant number="4" name="Participant4" clientRef=""/>';
            documentTVA2.metadata += '<participant number="5" name="Participant5" clientRef=""/>';
            documentTVA2.metadata += '<participant number="6" name="Participant6" clientRef=""/>';
            documentTVA2.metadata += '<participant number="7" name="Participant7" clientRef=""/>';
            documentTVA2.metadata += '<participant number="8" name="Participant8" clientRef=""/>';
            documentTVA2.metadata += '<participant number="9" name="Participant9" clientRef=""/>';
            documentTVA2.metadata += '<participant number="10" name="Participant10" clientRef=""/>';
            documentTVA2.metadata += '</participants>';
            documentTVA2.metadata += '<fields>';
            documentTVA2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="2" imported="" name="client1" ' + attSign1Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
            if (nbSignataires > 1) {
                documentTVA2.metadata += '<field values="" description="" type="SIGNATURE" required="false" regEx="" regExTip="" participantNumber="3" imported="" name="client2" ' + attSign2Pos +' fontSize="12.0" page="1" value="" group="" font="" />';
            }
            documentTVA2.metadata += '</fields>';
            documentTVA2.metadata += '<values>';
            documentTVA2.metadata += '<value fieldName="client1" value=""/>';
            if (nbSignataires > 1) {
                documentTVA2.metadata += '<value fieldName="client2" value=""/>';
            }
            documentTVA2.metadata += '</values>';
            documentTVA2.metadata += '</metadata>';

            circuit.documentList.add(documentTVA2);

            System.debug('documentTVA metadata : '+documentTVA2.metadata);
        }*/
        return circuit;
    }
    
    /**
    * @description Fonction de création de l'étape DIPC ou Contrat
    * @return Signea.Signea_Entities_v2.SigneaStep Step du circuit Signea (DIPC ou Contrat)
    */
    private Signea.Signea_Entities_v2.SigneaStep createStep1(String stepName) {
        Integer delai = System.today().daysBetween(quote.SBQQ__ExpirationDate__c) + 1;
        if (delai <= 0){
            Integer daysDelaiExpiration = 14;
            if(typeContrat.containsIgnoreCase('ISOLATION')) {
                delai = PropertiesUtils.getIntegerValue('signea.circuit.defaultDelay.isolation', 30);
            } else {
                delai = PropertiesUtils.getIntegerValue('signea.circuit.defaultDelay.menuiserie', 14);
            }
        }
        Signea.Signea_Entities_v2.SigneaStep step = new Signea.Signea_Entities_v2.SigneaStep();
        step.name = stepName;                                                     // Nom de l'étape
        step.stepNumber = 1;                                                  // Première étape
        step.maxDuration = delai;  // Durée de l'étape = nombre de jours restant avant expiration du devis
        step.reminderType = PropertiesUtils.getStringValue('signea.circuit.reminderType', 'Before');
        Integer reminderDays = PropertiesUtils.getIntegerValue('signea.circuit.reminderDays', 3);
        reminderDays = (reminderDays >= delai) ? delai-1 : reminderDays;
        if (reminderDays > 0) {
            step.reminderDays = reminderDays;
        }
        step.signerList = new List<Signea.Signea_Entities_v2.SigneaSigner>();
        
        System.debug('#SIGNEA 239# ' + delai + ' - ' + step.maxDuration + ' - ' + reminderDays + ' - ' + step.reminderDays);
        return step;
    }

    /**
    * @description Fonction pour vérifier si le statut est "Completed"
    * @param status Statut
    * @return Boolean Vrai si Completed, sinon false
    */
    private Boolean checkIsCompleted(String status) {
        return (status=='Completed' || status == 'Completed Signea' || status=='Completed Contralia') ? true : false;
    }

    /**
    * @description Fonctions de suppression si un fichier avec la même catégorie existe déjà lié au record
    * @param quoteId Id du devis
    * @param docId Id du document
    * @param docType Type de document à générer
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static void deleteCtDocumentByCategory(String quoteId, String docId, String docType){
        //Define the document type
        String documentCategory;
        if(docType.equalsIgnoreCase('TVA')) {
            documentCategory = 'Attestation TVA';
        } else {
            documentCategory = docType;
        }

        // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
        Utils_APIMerkure.deleteCtDocumentByCategory(quoteId, docId, documentCategory);
    }
}