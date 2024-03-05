//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Site_Demande_de_Devis
//-- Modifié par : SOPRA STERIA - William DE GAËTANO
//-- Modifié le  : 19/07/2017
//-- Version     : 1.5
//-- * 1.5 - Ajout des paramètres entrant + Modification IdEulerian
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Site_Demande_de_Devis {
    private static final Boolean GEOENABLED   = PropertiesUtils.getBooleanValue('google.geocoder.enabled', false);
    private static final Boolean GEO_SITE_ENABLED   = PropertiesUtils.getBooleanValue('geoconcept.geocoder.site.enabled', true);
    public String TELSUPPORT {get{ return PropertiesUtils.getStringValue('site.tel.support', '0 811 133 008');} set;}
    public String EMAILSUPPORT {get{ return PropertiesUtils.getStringValue('espaceclient.erreur.mail.destinataire', 'reclamationclient@kpark.fr');} set;}

    // Etape 1
    public String civilite {get; set;}
    public String nom {get; set;}
    public String prenom {get; set;}
    public String IdEul {get; set;}
    public String autocomplete {get; set;}
    public String rue{get; set;}
    public String adresseComplete{get; set;}
    public String cp{get; set;}
    public String ville{get; set;}
    public String departement{get; set;}
    public String pays{get; set;}
    public String isAutocomplete{get; set;}
    public String email{get; set;}
    public String tel{get; set;}
    public String radioPersonne{get; set;}
    public String stringPlusInfo{get; set;}
    public String stringRecevoirOffre{get; set;}
    public Boolean boolPlusInfo{get; set;}
    public Boolean boolRecevoirOffre{get; set;}
    public String typeHabitation{get; set;}
    public String CurrentUrl{get; set;}
    public String emailHash {get; set;}

    public Boolean boolProjetFenetre{get; set;}
    public Boolean boolProjetVolet{get; set;}
    public Boolean boolProjetGarage{get; set;}
    public Boolean boolProjetPortail{get; set;}
    public Boolean boolProjetPorte{get; set;}
    public Boolean boolProjetStore{get; set;}

    // Parametres
    public String idUtilisateur {get; set;}
    public String projet {get; set;}
    public String idImport {get; set;}
    public Boolean boolValideEtape3{get; set;}

    // Google
    public String googleKeyAPI {get; set;}
    public Double adresse_latitude {get; set;}
    public Double adresse_longitude {get; set;}
    public String googleSource {get; Set;}

    //etape 2
    public String quantiteFenetre{get; set;}
    public String typeFenetre{get; set;}
    public String materiauFenetre{get; set;}
    public String quantiteVolet{get; set;}
    public String typeVolet{get; set;}
    public String materiauVolet{get; set;}
    public String quantitePortail{get; set;}
    public String materiauPortail{get; set;}
    public String quantiteGarage{get; set;}
    public String typeGarage{get; set;}
    public String quantitePorte{get; set;}
    public String typePorte{get; set;}
    public String quantiteStore{get; set;}
    public String typeStore{get; set;}

    // ERRORS
    public Utils_logger log {get; set;}

    /**
    * @description Constructeur
    * @return Ctrl_Site_Demande_de_Devis 
    */
    public Ctrl_Site_Demande_de_Devis(){
        googleKeyAPI = PropertiesUtils.getStringValue('google.api.key', '');
        // Initialisation
        quantiteFenetre = '0';
        quantiteVolet = '0';
        quantiteGarage = '0';
        quantitePortail = '0';
        quantitePorte = '0';
        quantiteStore = '0';
        boolProjetFenetre = false;
        boolProjetVolet = false;
        boolProjetGarage = false;
        boolProjetPortail = false;
        boolProjetPorte = false;
        boolProjetStore = false;
        boolPlusInfo = false;
        boolRecevoirOffre = false;
        boolValideEtape3 = false;
        civilite = 'M'; // Monsieur par défaut
        radioPersonne = 'p'; // Propriétaire par défaut
        typeHabitation = 'Pavillon'; // Pavillon par défaut
        idImport = null;
        isAutocomplete = 'false';

        log = new Utils_logger();

        // Lecture des paramètres entrant (GET)
        nom = getParamValue('nom');
        prenom = getParamValue('prenom');
        tel = getParamValue('telephone');
        system.debug('rue : '+ rue );
        system.debug('getParamValue(adresse) : '+ getParamValue('adresse'));
        cp = getParamValue('cp');
        rue = getParamValue('adresse');
        ville = getParamValue('ville');
        email = getParamValue('email');
    }

    public String getParamValue(String paramName) {     
        String value='';
        String valueParam = ApexPages.currentPage().getParameters().get(paramName);
        if(String.isNotBlank(valueParam)) value = valueParam;
        return value;
    }

    /**
    * @description Méthode de vérification des paramètres URL ("check étape 2")
    * @return PageReference Page Visualforce
    */
    public PageReference initVerifParameters() {
        system.debug('#### START initVerifParameters');
        projet = ApexPages.currentPage().getParameters().get('p');
        idUtilisateur = ApexPages.currentPage().getParameters().get('id');        
        system.debug('## Parametre projet : ' + projet);
        system.debug('## Parametre id : ' + idUtilisateur);

        // Si pas d'ID et de projets, retour étape 1
        if(projet == null && idUtilisateur == null) {
            Pagereference etape1 = Page.VF_Site_Demande_de_Devis;
            etape1.setRedirect(false);
            system.debug('#### return etape1');
            return etape1;
        } else {
            system.debug('#### return null');
            return null;
        }
    }

    /**
    * @description Méthode de retour à l'étape 1
    * @return PageReference Page Visualforce
    */
    public PageReference index(){
        Pagereference etape1 = Page.VF_Site_Demande_de_Devis;
        etape1.getParameters().put('id', idImport);
        etape1.setRedirect(false);
        return etape1;
    }

    /**
    * @description Méthode validation de l'étape 1
    * @return PageReference Page Visualforce
    */
    public PageReference validationEtape1(){
        system.debug('#### START validationEtape1');

        try {
            String message = '';
            if (civilite != null) civilite = civilite.trim();
            if (nom != null) nom = nom.trim();
            if (prenom != null) prenom = prenom.trim();
            if (rue != null) rue = rue.trim();
            if (cp != null) cp = cp.trim();
            if (ville != null) ville = ville.trim();
            if (departement != null) departement = departement .trim();
            if (pays != null) pays = pays.trim();
            if (email != null) email = email.trim();
            if (tel != null) tel = tel.trim(); tel = tel.replaceAll('\\s+','');

            log.clear();

            if (String.isBlank(civilite) || String.isBlank(nom) || String.isBlank(prenom) || String.isBlank(cp) || cp == 'NaN' || 
            !Pattern.matches(Constants.REG_CP, cp) || String.isBlank(ville) || ville == 'NaN' || String.isBlank(tel) || String.isBlank(email) ||
            !Pattern.matches(Constants.REG_EMAIL, email) || String.isBlank(radioPersonne) || String.isBlank(typeHabitation) ||
            (!boolProjetFenetre && !boolProjetVolet && !boolProjetGarage && !boolProjetPortail && !boolProjetPorte && !boolProjetStore) ||
            (String.isNotBlank(prenom) && nom.containsAny(Constants.CHECK_OTHER)) || (String.isNotBlank(prenom) && nom.containsAny(Constants.CHECK_OTHER)))
                adresseComplete = rue;

            if (String.isBlank(civilite)) {
                system.debug('## Civilite vide');
                message = Label.erreur_civilite_non_remplis;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(nom)) {
                system.debug('## Nom vide');
                message = Label.erreur_civilite_non_remplis;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(prenom)) {
                system.debug('## Prénom vide');
                message = Label.erreur_civilite_non_remplis;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(cp) || cp == 'NaN') {
                system.debug('## Code postal vide');
                message = Label.site_msg_AddressNotValid;
                log.addErrorMessage(message);
                return null;
            }
            if(!Pattern.matches(Constants.REG_CP, cp)) {
                system.debug('## Code postal non valide');
                message = Label.site_msg_AddressNotValid;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(ville) || ville == 'NaN') {          ///// JMU 14/12/2015 /////
                system.debug('## Ville vide');
                message = Label.site_msg_VilleRequired;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(tel)) {
                system.debug('## Téléphone vide');
                message = Label.site_msg_TelNotValid;
                log.addErrorMessage(message);
                return null;
            }
            if(!Pattern.matches(Constants.REG_TEL, tel)) {
                system.debug('## Téléphone non valide');
                message = Label.site_msg_TelNotValid;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(email)) {
                system.debug('## Email vide');
                message = Label.site_email_vide;
                log.addErrorMessage(message);
                return null;
            }
            if(!Pattern.matches(Constants.REG_EMAIL, email)) {
                system.debug('## Email non valide');
                message = Label.site_msg_EmailNotValid;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(radioPersonne)) {
                system.debug('## Type personne vide');
                message = Label.site_type_personne_vide;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isBlank(typeHabitation)) {
                system.debug('## Type habitation vide');
                message = Label.site_type_habitation_vide;
                log.addErrorMessage(message);
                return null;
            }
            if (!boolProjetFenetre && !boolProjetVolet && !boolProjetGarage && !boolProjetPortail && !boolProjetPorte && !boolProjetStore) {
                system.debug('## Liste projets vide');
                message = Label.site_projet_vide;
                log.addErrorMessage(message);
                return null;
            }
            //si le nom et prenom sont remplis
            if (String.isNotBlank(prenom) && prenom.containsAny(Constants.CHECK_OTHER)) {
                system.debug('## Prénom non valide');
                message = Label.erreur_prenom_invalide;
                log.addErrorMessage(message);
                return null;
            }
            if (String.isNotBlank(nom) && nom.containsAny(Constants.CHECK_OTHER)) {
                system.debug('## Nom non valide');
                message = Label.erreur_nom_invalide;
                log.addErrorMessage(message);
                return null;
            }

            system.debug('#### END validationEtape1');
            return creerCompte();
        } catch(Exception e){
            String message = Label.msg_InternalError + ' Ligne erreur : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone :</strong> ' + TELSUPPORT + '<br/><strong>E-mail :</strong> ' + EMAILSUPPORT;
            log.addErrorMessage(message);
            system.debug('ERREUR # Site Demande de devis : Validation Etape1 (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            return null;
        }
    }

    /**
    * @description Méthode validation de l'étape 2
    * @return PageReference Page Visualforce
    */
    public PageReference validationEtape2() {
        system.debug('#### START validationEtape2');
        try{
            String message = '';
            log.clear();
            if(String.isBlank(idUtilisateur) || String.isBlank(projet)){
                return null;
            }
            if(projet.contains('1')){
                if(typeFenetre == null) {
                    system.debug('## Type fenetre non valide');
                    message = Label.site_type_fenetre_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(materiauFenetre == null) {
                    system.debug('# Materiau fenetre non valide');
                    message = Label.site_materiau_fenetre_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(quantiteFenetre.equalsIgnoreCase('0')) {
                    system.debug('## Quantite fenetre non valide');
                    message = Label.site_quantite_fenetre_vide;
                    log.addErrorMessage(message);
                    return null;
                }
            }
            if(projet.contains('2')){
                if(typeVolet == null) {
                    system.debug('## Type volet non valide');
                    message = Label.site_type_volet_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(materiauVolet == null) {
                    system.debug('## Materiau volet non valide');
                    message = Label.site_materiau_volet_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(quantiteVolet.equalsIgnoreCase('0')) {
                    system.debug('## Quantite volet non valide');
                    message = Label.site_quantite_volet_vide;
                    log.addErrorMessage(message);
                    return null;
                }
            }
            if(projet.contains('3')){
                if(typeGarage == null) {
                    system.debug('## Type garage non valide');
                    message = Label.site_type_garage_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(quantiteGarage.equalsIgnoreCase('0')) {
                    system.debug('## Quantite garage non valide');
                    message = Label.site_quantite_garage_vide;
                    log.addErrorMessage(message);
                    return null;
                }
            }
            if(projet.contains('4')){
                if(materiauPortail == null) {
                    system.debug('## Materiau portail non valide');
                    message = Label.site_materiau_portail_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(quantitePortail.equalsIgnoreCase('0')) {
                    system.debug('## Quantite portail non valide');
                    message = Label.site_quantite_portail_vide;
                    log.addErrorMessage(message);
                    return null;
                }
            }
            if(projet.contains('5')){
                if(typePorte == null) {
                    system.debug('## Type porte non valide');
                    message = Label.site_type_porte_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(quantitePorte.equalsIgnoreCase('0')) {
                    system.debug('## Quantite porte non valide');
                    message = Label.site_quantite_porte_vide;
                    log.addErrorMessage(message);
                    return null;
                }
            }
            if(projet.contains('6')){
                if(typeStore == null) {
                    system.debug('## Type store non valide');
                    message = Label.site_type_store_vide;
                    log.addErrorMessage(message);
                    return null;
                }
                if(quantiteStore.equalsIgnoreCase('0')) {
                    system.debug('## Quantite store non valide');
                    message = Label.site_quantite_store_vide;
                    log.addErrorMessage(message);
                    return null;
                }
            }
            
            // Vérification de la présence de l'enregistrement import
            List<Import__c> compteModifieList = [SELECT Id FROM Import__c WHERE id =:idUtilisateur];
            if(compteModifieList.isEmpty()) {
                log.addErrorMessage(Label.erreur_inscription_non_present);
                return null;
            } else {
                // Redirection vers la page de confirmation "Etape 3"
                Pagereference etape3 = Page.VF_Site_Demande_de_Devis_Etape3;                
                etape3.getParameters().put('p', projet);
                etape3.getParameters().put('id', idImport);
                etape3.setRedirect(false);
                system.debug('#### END validationEtape2');
                return etape3;
            }
        } catch(Exception e){
            String message = Label.msg_InternalError + ' Ligne erreur : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone :</strong> ' + TELSUPPORT + '<br/><strong>E-mail :</strong> ' + EMAILSUPPORT;
            log.addErrorMessage(message);
            system.debug('ERREUR # Site Demande de devis : Validation Etape 2 (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            return null;
        }
    }

    /**
    * @description Méthode validation de l'étape 3
    */
    public void validationEtape3(){
        system.debug('#### START validationEtape3');

        try{            
            boolValideEtape3 = true;
            if(idUtilisateur != null && idUtilisateur != ''){
                // Mise à jour de l'enregistrement
                system.debug('## Mise à jour de l\'enregistrement fin étape 2');
                processEtape2();
                system.debug('#### END validationEtape3');
            } else {
                throw new KubeException('Mauvais traitement des étapes');
            }
        } catch(Exception e){
            system.debug('ERREUR # Site Demande de devis : Validation étape 3 (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
        }
    }

    /**
    * @description Méthode pour créer le compte dans import__c une fois l'étape 1 OK
    * @return PageReference Page Visualforce
    */
    private PageReference creerCompte(){
        system.debug('#### START creerCompte');

        try{
            String message = '';
            Import__c nouveau_compte = null;

            log.clear();

            // Vérification du bon ID
            if(idImport != null) {
                system.debug('## Modification import');
                system.debug('## Id Import : '+ idImport);
                nouveau_compte = [SELECT id, nomCompte__c, prenomCompte__c, civiliteCompte__c, rueCompte__c, rueChantier__c, codePostalCompte__c, codePostalChantier__c,
                                        villeCompte__c, villeChantier__c, departementCompte__c, departementChantier__c, paysCompte__c, paysChantier__c, emailCompte__c,
                                        telephoneDomicileCompte__c, Locataire__c, typeHabitation__c, optinAdresseEmailKparK__c, optinAdresseEmailPartenaire__c,
                                        optinSMSKparK__c, optinTelephoneMobileKparK__c, optinTelephoneDomicileKparK__c, optinSMSPartenaire__c, optinTelephoneMobilePartenaire__c,
                                        optinTelephoneDomicilePartenaire__c, nomFichierSource__c, idEulerian__c, integrable__c, Source__c, Localisation__Latitude__s, Localisation__Longitude__s,
                                        hasError__c, classeException__c, messageException__c, sourceWeb__c
                                    FROM Import__c WHERE Id = :idImport LIMIT 1];
            }
            // Création de l'import si non existant
            if(nouveau_compte == null) {
                system.debug('## Création import');
                RecordType rtImport = [SELECT id FROM RecordType WHERE developerName = 'importExterne' LIMIT 1];
                nouveau_compte = new Import__c(recordTypeId = rtImport.id);
            }
            system.debug('## CHECK TIME Création debut : '+ System.now());
            //recuperation de la date et heure actuelle
            Datetime d = system.now();
            //mise en forme de la date au bon format
            String longDate = d.format('YYYYMMdd,HH,mm,ss');
            
            system.debug('rue : '+ rue);
            system.debug('nouveau_compte.rueCompte__c : '+ nouveau_compte.rueCompte__c);

            nouveau_compte.nomCompte__c = nom;
            nouveau_compte.prenomCompte__c = prenom;
            nouveau_compte.civiliteCompte__c = civilite;
            nouveau_compte.rueCompte__c=rue;
            nouveau_compte.rueChantier__c = rue;
            nouveau_compte.codePostalCompte__c=cp;
            nouveau_compte.codePostalChantier__c=cp;
            nouveau_compte.villeCompte__c=ville;
            nouveau_compte.villeChantier__c=ville;
            nouveau_compte.departementCompte__c=departement;
            nouveau_compte.departementChantier__c=departement;
            nouveau_compte.paysCompte__c=pays;
            nouveau_compte.paysChantier__c=pays;
            nouveau_compte.emailCompte__c=email;
            nouveau_compte.telephoneDomicileCompte__c=tel;

            if (radioPersonne == 'l') nouveau_compte.Locataire__c= true;
            nouveau_compte.typeHabitation__c=typeHabitation;

            system.debug('## boolPlusInfo : '+ boolPlusInfo);
            system.debug('## boolRecevoirOffre : '+ boolRecevoirOffre);

            if(email != null){
                nouveau_compte.optinAdresseEmailKparK__c= boolPlusInfo;
                nouveau_compte.optinAdresseEmailPartenaire__c= boolRecevoirOffre;
                emailHash = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(email))); // Email crypté MD5
            }

            if(tel != null){
                nouveau_compte.optinSMSKparK__c=boolPlusInfo;
                nouveau_compte.optinTelephoneMobileKparK__c=boolPlusInfo;
                nouveau_compte.optinTelephoneDomicileKparK__c=boolPlusInfo;
                nouveau_compte.optinSMSPartenaire__c=boolRecevoirOffre;
                nouveau_compte.optinTelephoneMobilePartenaire__c=boolRecevoirOffre;
                nouveau_compte.optinTelephoneDomicilePartenaire__c=boolRecevoirOffre;
            }

            nouveau_compte.nomFichierSource__c= 'formulaire_site_kpark.fr';
            nouveau_compte.integrable__c = false;
            nouveau_compte.Source__c='WEB';
            nouveau_compte.classeException__c = null;
            nouveau_compte.messageException__c = null;
            // Définition d'un ID Eulerian provisoire (pour recherche)
            if(nouveau_compte.idEulerian__c == null) 
                nouveau_compte.idEulerian__c= longDate.remove(',') + '' + math.round(math.random()*99);
            IdEul = nouveau_compte.idEulerian__c;
            // Géocodage
            if(GEOENABLED) {
                system.debug('## geocoder google = true');
                nouveau_compte.Localisation__Latitude__s = adresse_latitude;
                nouveau_compte.Localisation__Longitude__s = adresse_longitude;
            }
            nouveau_compte.sourceWeb__c = googleSource;
            // WDO - Gestion du hors secteur, geolocation
            if (GEO_SITE_ENABLED)
                GeoUtils.geolocationImportRecord(nouveau_compte);           
            // Insertion ou mise à jour de l'import
            upsert nouveau_compte;
            nouveau_compte = [SELECT Id, idEulerian__c, messageException__c FROM Import__c WHERE nomCompte__c = :nom 
                                AND prenomCompte__c = :prenom AND idEulerian__c =:IdEul LIMIT 1];
            idImport = nouveau_compte.id;
            // Définition d'un ID Eulerian définitif (ID fiche import)
            nouveau_compte.idEulerian__c=nouveau_compte.id;
            IdEul = nouveau_compte.idEulerian__c;
            update nouveau_compte;            
            system.debug('## CHECK TIME Création fin : '+ System.now());
            // Vérification erreur de hors secteur
            if(nouveau_compte.messageException__c != null && nouveau_compte.messageException__c == Label.import_erreur_horssecteur_messageexception) {
                system.debug('## Erreur hors secteur');
                message = Label.import_erreur_horssecteur_message;
                log.addErrorMessage(message);
                return null;
            }

            // Construction liste des projets
            projet ='';
            if(boolProjetFenetre) projet = projet + '1';
            if(boolProjetVolet) projet = projet + '2';
            if(boolProjetGarage) projet = projet + '3';
            if(boolProjetPortail) projet = projet + '4';
            if(boolProjetPorte) projet = projet + '5';
            if(boolProjetStore) projet = projet + '6';
            system.debug('## Liste des projets ' + projet);

            Pagereference etape2 = Page.VF_Site_Demande_de_Devis_Etape2;
            etape2.getParameters().put('p', projet);
            etape2.getParameters().put('id', idImport);
            etape2.setRedirect(false);
            
            system.debug('#### END creerCompte');
            return etape2;
        } catch(Exception e){
            String message = Label.msg_InternalError + ' Ligne erreur : ' + String.valueOf(e.getLineNumber());
            message += '<br/><strong>Numéro de téléphone :</strong> ' + TELSUPPORT + '<br/><strong>E-mail :</strong> ' + EMAILSUPPORT;
            log.addErrorMessage(message);
            system.debug('ERREUR # Site Demande de devis : Creer Compte (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
            return null;
        }
    }

    /**
    * @description Méthode pour mettre à jour le compte dans import__c une fois l'étape 2 OK
    */
    private void processEtape2() {
        system.debug('#### START processEtape2');

        try{
            // Mise à jour des champs de la section "Projet"
            List<Import__c> compteModifieList = [SELECT id, quantiteFenetre__c, materiauxFenetre__c, quantiteCoulissant__c, materiauxCoulissant__c,
                                                        quantitePorteFenetre__c, materiauxPorteFenetre__c, quantiteVoletBattant__c, materiauxVoletBattant__c,
                                                        quantiteVoletRoulant__c, materiauxVoletRoulant__c, quantitePersienne__c, materiauxPersienne__c,
                                                        materiauxPorteGarage__c, materiauxPortail__c, quantitePortail__c,
                                                        quantitePorteEntree__c, quantitePorteBlindee__c, quantitePorteInterieur__c, quantitePorteService__c,
                                                        quantiteStoreBanne__c, quantiteMoustiquaire__c FROM Import__c WHERE id = :Idimport];
            Import__c compteModifie = compteModifieList[0];

            // Initialisation des valeurs à zéro ou vide
            compteModifie.quantiteFenetre__c = 0;
            compteModifie.materiauxFenetre__c = '';
            compteModifie.quantiteCoulissant__c = 0;
            compteModifie.materiauxCoulissant__c = '';
            compteModifie.quantitePorteFenetre__c = 0;
            compteModifie.materiauxPorteFenetre__c = '';
            compteModifie.quantiteVoletBattant__c = 0;
            compteModifie.materiauxVoletBattant__c = '';
            compteModifie.quantiteVoletRoulant__c = 0;
            compteModifie.materiauxVoletRoulant__c = '';
            compteModifie.quantitePersienne__c = 0;
            compteModifie.materiauxPersienne__c = '';
            compteModifie.materiauxPorteGarage__c = '';
            compteModifie.materiauxPortail__c = '';
            compteModifie.quantitePorteEntree__c = 0;
            compteModifie.quantitePorteBlindee__c = 0;
            compteModifie.quantitePorteInterieur__c = 0;
            compteModifie.quantitePorteService__c = 0;
            compteModifie.quantiteStoreBanne__c = 0;
            compteModifie.quantiteMoustiquaire__c = 0;
            compteModifie.quantitePorteGarage__c = 0;
            compteModifie.quantitePortail__c = 0;

            // Fenetre
            if (typeFenetre == '1') { // Fenetre
                compteModifie.quantiteFenetre__c = Decimal.valueOf(quantiteFenetre);
                if (materiauFenetre == '1') compteModifie.materiauxFenetre__c = 'Bois';
                if (materiauFenetre == '2') compteModifie.materiauxFenetre__c = 'PVC';
                if (materiauFenetre == '3') compteModifie.materiauxFenetre__c = 'Aluminium';
                if (materiauFenetre == '4') compteModifie.materiauxFenetre__c = 'Bois/Alu';
            } else if (typeFenetre == '2') { // Vitre
                compteModifie.quantiteCoulissant__c = Decimal.valueOf(quantiteFenetre);
                if (materiauFenetre == '1') compteModifie.materiauxCoulissant__c = 'Bois';
                if (materiauFenetre == '2') compteModifie.materiauxCoulissant__c = 'PVC';
                if (materiauFenetre == '3') compteModifie.materiauxCoulissant__c = 'Aluminium';
                if (materiauFenetre == '4') compteModifie.materiauxCoulissant__c = 'Bois/Alu';
            } else if (typeFenetre == '3') { // Porte-fenetre
                compteModifie.quantitePorteFenetre__c = Decimal.valueOf(quantiteFenetre);
                if (materiauFenetre == '1') compteModifie.materiauxPorteFenetre__c = 'Bois';
                if (materiauFenetre == '2') compteModifie.materiauxPorteFenetre__c = 'PVC';
                if (materiauFenetre == '3') compteModifie.materiauxPorteFenetre__c = 'Aluminium';
                if (materiauFenetre == '4') compteModifie.materiauxPorteFenetre__c = 'Bois/Alu';
            }

            // Volet
            if (typeVolet == '1') { // Battants
                compteModifie.quantiteVoletBattant__c = Decimal.valueOf(quantiteVolet);
                if (materiauVolet == '1') compteModifie.materiauxVoletBattant__c = 'Bois';
                if (materiauVolet == '2') compteModifie.materiauxVoletBattant__c = 'PVC';
                if (materiauVolet == '3') compteModifie.materiauxVoletBattant__c = 'Aluminium';
            } else if (typeVolet == '2') { // Roulants
                compteModifie.quantiteVoletRoulant__c = Decimal.valueOf(quantiteVolet);
                if (materiauVolet == '1') compteModifie.materiauxVoletRoulant__c = 'Bois';
                if (materiauVolet == '2') compteModifie.materiauxVoletRoulant__c = 'PVC';
                if (materiauVolet == '3') compteModifie.materiauxVoletRoulant__c = 'Aluminium';
            } else if (typeVolet == '3') { // Persiennes
                compteModifie.quantitePersienne__c = Decimal.valueOf(quantiteVolet);
                if (materiauVolet == '1') compteModifie.materiauxPersienne__c = 'Bois';
                if (materiauVolet == '2') compteModifie.materiauxPersienne__c = 'PVC';
                if (materiauVolet == '3') compteModifie.materiauxPersienne__c = 'Aluminium';
            }

            // Garage
            if (typeGarage == '1') { // Sectionnelles
                compteModifie.materiauxPorteGarage__c = 'Sectionnelles';
            } else if (typeGarage == '2') {
                compteModifie.materiauxPorteGarage__c = 'Enroulables';
            } else if (typeGarage == '3') {
                compteModifie.materiauxPorteGarage__c = 'Battantes';
            }

            // Portail et Clotures
            if(materiauPortail == '1') { // PVC
                compteModifie.materiauxPortail__c = 'PVC';
            } else if(materiauPortail == '2') {
                compteModifie.materiauxPortail__c = 'Aluminium';
            }

            // Porte
            if (typePorte == '1') { // Entrée
                compteModifie.quantitePorteEntree__c = Decimal.valueOf(quantitePorte);
            } else if (typePorte == '2') { // Blindées
                compteModifie.quantitePorteBlindee__c = Decimal.valueOf(quantitePorte);
            } else if (typePorte == '3') { // Intérieures
                compteModifie.quantitePorteInterieur__c = Decimal.valueOf(quantitePorte);
            } else if (typePorte == '4') { // De service
                compteModifie.quantitePorteService__c = Decimal.valueOf(quantitePorte);
            }

            // Store
            if (typeStore == '1') { // Banne
                compteModifie.quantiteStoreBanne__c = Decimal.valueOf(quantiteStore);
            } else if (typeStore == '2') {
                compteModifie.quantiteMoustiquaire__c = Decimal.valueOf(quantiteStore);
            }

            if (quantiteGarage != '0') compteModifie.quantitePorteGarage__c = Decimal.valueOf(quantiteGarage);
            if (quantitePortail != '0') compteModifie.quantitePortail__c = Decimal.valueOf(quantitePortail);
            compteModifie.integrable__c=true;

            // Update du compte import
            update compteModifie;
            system.debug('#### END processEtape2');
        } catch(Exception e){
            system.debug('ERREUR # Site Demande de devis : Mise à jour import Etape 2 (' + e + ') Ligne : ' + String.valueOf(e.getLineNumber()) + ' !');
        }
    }
}