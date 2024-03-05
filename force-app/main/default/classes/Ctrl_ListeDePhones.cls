//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_ListeDePhones
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 24/03/2020
//-- Version     : 2.7
//-- * 2.7 : KPKCRM_RQM-177 : Mise en place des nouveaux types d'enregistrement des comptes
//-- * 2.6 : RQM-175 : RDV FSL affichés aux vendeurs
//-- * 2.5 - RQM-113 : Ajout des constantes pour les nouveaux rôles/profils
//-- * 2.4 : RQM-70 : Evolution pour utilisation de leaflet
//-- * 2.3 : CRM-988 : Evolution de la cartographie pour secteur sans polygones
//-- * 2.2 : CRM-948 : Tri des exports
//-- * 2.1 : CRM-893 : Refonte Liste de Phones lot n°2
//-- * 2.0 : CRM-886 : Refonte Liste de Phones lot n°1
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_ListeDePhones {
    public Date dateImport {get;set;}
    public Date dateImportToUpdate {get;set;}
    public Option__c codeO {get;set;}
    public String productCode {get;set;}
    public String dataExport {get; set;}
    public String selectedRecordType {get; set;}
    public Boolean unlockMagasin { get; set; }
    public Decimal perimetre{get; set;}
    public String rue2 {get; set;}
    public String rue3 {get; set;}
    public String codeRegion {get; set;}
    public String codeDV {get; set;}
    public String codeMag {get; set;}
    public Boolean lockSearch { get; set; }
    public String codeDernierAppel {get; set;}
    public String paramMag {get; set;}
    public Map<String,String> magasinsMap {get; set;}
    public String paramMagasin {get; set;}
    public User actualUser {get; set;}
    
    public Account unFoyer {get { return unFoyer;}set;}{
        // Définition d'un compte virtuel pour les filtres
        String proprietaire = ApexPages.currentPage().getParameters().get('proprietaire');
        if(proprietaire != '' && proprietaire != null) 
            unFoyer = new Account(Type='', OwnerId = ApexPages.currentPage().getParameters().get('proprietaire'));
        else 
            unFoyer = new Account(Type='', OwnerId = UserInfo.getUserId());
    } 

    public Boolean isInPeriode {get; set;}{
         if(PropertiesUtils.getDateValue('ldp.periode.debut') <= date.today() && PropertiesUtils.getDateValue('ldp.periode.fin') >= date.today()) 
            isInPeriode = true;
         else 
            isInPeriode = false;
    }

    // ERRORS
    public Utils_logger log {get; set;}

    // EXPORT CSV & PDF
    public List<Account> listAccountsExport1 { get; set; }
    public List<Account> listAccountsExport2 { get; set; }
    public List<Account> listAccountsExport3 { get; set; }
    public List<Account> listAccountsFilters{ get; private set; }   // recup comptes filtrés
    public String bom {get {return EncodingUtil.base64decode('77u/').tostring();}}  //Encoding export EXCEL
    public String fileName {get;set;}
    public Boolean isExportPdf {get; set;}{isExportPdf = PropertiesUtils.getBooleanValue('ldp.export.pdf', true);}
    public Boolean isExportExcel {get; set;}{isExportExcel = PropertiesUtils.getBooleanValue('ldp.export.excel', true);}
        
    // FICHIER IMPORTE
    public String fileNameSelected { get; set; }
    public List<SelectOption> getfilesName(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '-- Aucun --'));
        Map<String, ImportFiles__c> filesInfo = ImportFiles__c.getAll();

        for(ImportFiles__c fi : filesInfo.values()) {
            options.add(new SelectOption(fi.nomFichierSource__c, fi.nomFichierSource__c + ' (' + fi.dateImportation__c.format() + ')'));
        }
        return options;
    }

    // CODE PRODUIT
    public List<Product2> product {get; set;}
    public String displayProductId {get; set;}
    public String displayProductName {get; set;}
    public Product2 productSample {get{
        if(displayProductId != null){
            List<Product2> productList = new List<Product2>();
            system.debug('productSample : '+ productSample);
            productList = [SELECT Id, Name FROM Product2 WHERE Id = :displayProductId LIMIT 10];
            if(!productList.isEmpty()) productSample = productList[0];
        }
        return productSample;
    } set;} {
        productSample = new Product2();
        product = [SELECT Id, Name FROM Product2 LIMIT 10];
        system.debug('productSample : '+ productSample);
        if(productSample == null && !product.isEmpty() && displayProductId == null) productSample = product[0];
        else {
            product = [SELECT Id, Name FROM Product2 WHERE Id = :displayProductId LIMIT 10];
            if(!product.isEmpty()) productSample = product[0];
        }
    }

    // CODE OPTION
    public List<ReferentielOptions__c> option {get; set;}
    public List<ReferentielOptions__c> baseOptions {get; set;} {
        baseOptions = [SELECT Id, Name FROM ReferentielOptions__c LIMIT 10];
    }
    public String optionCode {get;set;}
    public String displayOptionId {get; set;}
    public String displayOptionName {get; set;}
    public ReferentielOptions__c optionSample {get{
        if(displayOptionId != null){
            List<ReferentielOptions__c> optionList = new List<ReferentielOptions__c>();
            optionList = [SELECT Id, Name FROM ReferentielOptions__c WHERE Id = :displayOptionId LIMIT 1];
            if(!optionList.isEmpty()) optionSample = optionList[0];
        }
        return optionSample;
    } set;}
    
    // RECHERCHE GEOGRAPHIQUE
    // DQE  
    public String licenceDQE {get; set;}
    transient public GoogleMapsSettings__c googleMapsSettings { get; private set; }
    public Integer futurEventDays { get; set; }
    public String walkMeURL { get; set; }
    public static final Integer futurEventDaysFinal = PropertiesUtils.getIntegerValue('listeDePhones.map.futurEvents.days', 3);
    static Set<String> codeMagWithAtt;
    public List<String> sectorNamesList { get; private set; }
    public String sectorName { get; private set; }
    public String sectorCode { get; private set; }
    public static final integer mapDotLimits = Constants.MAP_DOT_LIMITS;
    
    /**
    * @description Initialisation des Record Type
    */
    public List<SelectOption> optionsRecordType {get; set;} {
        optionsRecordType = new List<SelectOption>();
        List<RecordType> ListRT = [SELECT Id, Name FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' ORDER By Name ASC];
        for( RecordType rt : ListRT){
            optionsRecordType.add(new SelectOption(rt.Id, rt.Name));
        }
        if(!optionsRecordType.isEmpty())
            selectedRecordType = optionsRecordType[0].getValue();
    }
    
    /**
    * @description Initialisation des options Dernier appel
    */
    public List<SelectOption> optionsDernierAppel {get; set;} {
        optionsDernierAppel = new List<SelectOption>();
        Schema.Describefieldresult fieldDesc = Schema.sObjectType.ListePhoningVendeur__c.fields.dernierAppel_Filter__c.getSObjectField().getDescribe();
        for( Schema.PicklistEntry f : fieldDesc.getPicklistValues()){
            optionsDernierAppel.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        if(!optionsDernierAppel.isEmpty())
            codeDernierAppel = optionsDernierAppel[0].getValue();
    }
    /**
    * @description Initialisation des options DR
    */
    public List<SelectOption> optionsRegion {get; set;} {
        optionsRegion = new List<SelectOption>();
        for(AggregateResult ar : [select libelleRegion__c, codeRegion__c from Sectorisation__c GROUP BY libelleRegion__c, codeRegion__c ORDER BY libelleRegion__c]){
            if (ar.get('codeRegion__c') != null && ar.get('libelleRegion__c') != null)
                optionsRegion.add(new SelectOption(String.valueOf(ar.get('codeRegion__c')), String.valueOf(ar.get('libelleRegion__c'))));
        }
        if(!optionsRegion.isEmpty())
            codeRegion = optionsRegion[0].getValue();
    }
    /**
    * @description Initialisation des options DV
    */
    public List<SelectOption> optionsDV {get{
        List<SelectOption> options = new List<SelectOption>();
        if(codeRegion!=null && codeRegion != '*'){
            for(AggregateResult ar : [select libelleDV__c, codeDV__c from Sectorisation__c WHERE codeRegion__c=:codeRegion GROUP BY libelleDV__c, codeDV__c ORDER BY libelleDV__c]){
                if (ar.get('codeDV__c') != null && ar.get('libelleDV__c') != null)
                    options.add(new SelectOption(String.valueOf(ar.get('codeDV__c')), String.valueOf(ar.get('libelleDV__c'))));
            }
        } else {
            for(AggregateResult ar : [select libelleDV__c, codeDV__c from Sectorisation__c GROUP BY libelleDV__c, codeDV__c ORDER BY libelleDV__c]){
                if (ar.get('codeDV__c') != null && ar.get('libelleDV__c') != null)
                    options.add(new SelectOption(String.valueOf(ar.get('codeDV__c')), String.valueOf(ar.get('libelleDV__c'))));
            }
        }
        return options;
    } set; }
    /**
    * @description Initialisation des options Magasin
    */
    public List<SelectOption> optionsMag {get{
        List<SelectOption> options = new List<SelectOption>();
        Map<String,String> magasinsMap = new Map<String,String>();
        unlockMagasin = false;        
        if(magasinsMap.size() > 1) unlockMagasin = true;    
        if(codeDV !=null && codeDV != '') {
            for(AggregateResult ar : [SELECT libelleMagasin__c, codeMagasin__c FROM Sectorisation__c WHERE codeDV__c=:codeDV GROUP BY libelleMagasin__c, codeMagasin__c ORDER BY libelleMagasin__c]){
                if (ar.get('codeMagasin__c') != null && ar.get('libelleMagasin__c') != null)
                    options.add(new SelectOption(String.valueOf(ar.get('codeMagasin__c')), String.valueOf(ar.get('libelleMagasin__c'))));
            }
        } else {
            for(String magMapCode : magasinsMap.keySet()){
                options.add(new SelectOption(String.valueOf(magMapCode), String.valueOf(magasinsMap.get(magMapCode))));
            }
        }
        return options;
    } set; }

    /**
    * @description Récupération des magasins relatifs à la DV selectionnée, et des DV en fonction de la région
    * @return List<SelectOption> Liste des magasins
    */
    public void getMag(){
        List<SelectOption> options = new List<SelectOption>();
        for(AggregateResult ar : [select libelleMagasin__c, codeMagasin__c from Sectorisation__c WHERE codeDV__c=:codeDV GROUP BY libelleMagasin__c, codeMagasin__c ORDER BY libelleMagasin__c]){
            if (ar.get('codeMagasin__c') != null && ar.get('libelleMagasin__c') != null)
                options.add(new SelectOption(String.valueOf(ar.get('codeMagasin__c')), String.valueOf(ar.get('libelleMagasin__c'))));
        }
        optionsMag = options;
    }
    
    /**
    * @description Récupération des DV relatifs en fonction de la région
    * @return List<SelectOption> Liste des DV
    */
    public void getDV() {
        List<SelectOption> options = new List<SelectOption>();
        for(AggregateResult ar : [select libelleDV__c, codeDV__c from Sectorisation__c WHERE codeRegion__c=:codeRegion GROUP BY libelleDV__c, codeDV__c ORDER BY libelleDV__c]){
            if (ar.get('codeDV__c') != null && ar.get('libelleDV__c') != null)
                options.add(new SelectOption(String.valueOf(ar.get('codeDV__c')), String.valueOf(ar.get('libelleDV__c'))));
        }
        optionsDV = options;
        if(!options.isEmpty())
            codeDV = options[0].getValue();
    }  

    /**
    * @description Constructeur
    * @return Ctrl_ListeDePhones 
    */
    public Ctrl_ListeDePhones() {
        listAccountsFilters = new List<Account>();
        List<Account> listAccountsExport1 = new List<Account>();
        List<Account> listAccountsExport2 = new List<Account>();
        List<Account> listAccountsExport3 = new List<Account>();

        log = new Utils_logger();
        
        lockSearch = false;
        paramMagasin = ApexPages.currentPage().getParameters().get('magasin'); //inutilisé ??

        Map<String, ImportFiles__c> mcs = ImportFiles__c.getAll();
        system.debug('mcs : ' + mcs);
        initSecto();
        
        //////////////////////////////////////
        // INITIALISATIONS POUR GOOGLE MAPS //
        //////////////////////////////////////
        
        futurEventDays = (futurEventDaysFinal == null) ? 0 : futurEventDaysFinal;
        //walkMeURL = PropertiesUtils.getStringValue('walkme.snippet.url', '');

        // Récupération des paramètres de la carte
        googleMapsSettings = GoogleMapsSettings__c.getValues('cartographie');
        // Récupération paramètre global DQE
        licenceDQE = PropertiesUtils.getStringValue('dqe.adresse.licence', '');
        // Récupération liste des magasins de l'utilisateur
        UserContext context = UserContext.getContext(UserInfo.getUserId());
        magasinsMap = context.getMagasins();
        actualUser = [SELECT Id, Name, Profile.Name, UserRole.Name, codeDR__c, codeDV__c, codeMagasin__c
                        FROM User
                        WHERE Id = :UserInfo.getUserId()
                        LIMIT 1];

        // Initialisation secteurs disponible pour l'utilisateur
        codeMagWithAtt = DAL_Cartographie.attsParentIds(magasinsMap.keySet());
        sectorNamesList = new List<String>();
        for (String code : magasinsMap.keySet()) {
            //if (codeMagWithAtt.contains(code))
                sectorNamesList.add (magasinsMap.get(code));
        }
        sectorNamesList.sort();

        // Initialisation sur le premier secteur de la liste si disponible
        if (!sectorNamesList.isEmpty() && sectorNamesList != null) {
            System.debug('DEBUG # Ctrl_ListeDePhones < paramMag = ' + paramMag + ', codeMag = ' + codeMag);
            if(String.isNotBlank(paramMag)) sectorName = magasinsMap.get(paramMag);
            //sectorName = magasinsMap.get(ApexPages.currentPage().getParameters().get('magasin'));
            else sectorName = sectorNamesList[0];
        } 
    }

    /**
    * @description Rafraichissement du champ date d'importation du fichier lors du changement de nom
    */
    public void refreshImportDate() {
        Map<String, ImportFiles__c> filesInfo = ImportFiles__c.getAll();
        dateImportToUpdate = null;
        for(ImportFiles__c fi : filesInfo.values()){
            if(fi.nomFichierSource__c == fileNameSelected){
                dateImportToUpdate = fi.dateImportation__c;
                system.debug('dateImport : ' +dateImport);
            }
        }
    }

    /**
    * @description Initialise les valeurs selectionnées pour Region, DV et Magasin et vérifie si elles existent
    */
    /**
    * @description 
    */
    public void initSecto() {
        String userId = UserInfo.getUserId();
        User userinfos = [SELECT CodeDR__c, CodeDV__c, CodeMagasin__c, ProfileId FROM User WHERE Id=:userId LIMIT 1];
        Profile actualUserProfile = [SELECT id, name FROM Profile WHERE Id = :userinfos.ProfileId];
        system.debug('verif user : ' + userinfos);
        paramMag = '';

        List<SelectOption> optR = optionsRegion;

        String verifSecto = 'init';

        for (AggregateResult ar : [select libelleRegion__c, codeRegion__c from Sectorisation__c GROUP BY libelleRegion__c, codeRegion__c]){
            if(ar.get('codeRegion__c') == userinfos.CodeDR__c){
                verifSecto = 'DR_OK';
            }
        }

        if(verifSecto == 'DR_OK'){
            for (AggregateResult ar : [select libelleDV__c, codeDV__c from Sectorisation__c GROUP BY libelleDV__c, codeDV__c]){
                if(ar.get('codeDV__c') == userinfos.CodeDV__c){
                    verifSecto = 'DV_OK';
                }
            }
            if(verifSecto == 'DV_OK'){
                for (AggregateResult ar : [select libelleMagasin__c, codeMagasin__c from Sectorisation__c GROUP BY libelleMagasin__c, codeMagasin__c]){
                    if(ar.get('codeMagasin__c') == userinfos.CodeMagasin__c){
                        verifSecto = 'DMag_OK';
                    }
                }
                if(verifSecto == 'DMag_OK'){

                } else { verifSecto = 'DMag_KO'; }
            } else { verifSecto = 'DV_KO'; }
        } else { verifSecto = 'DR_KO'; }

        // Si la secto est mal renseignée, bloque les picklists et la recherche
        if(
            (actualUserProfile.Name.containsIgnoreCase('K/K - Vendeur') && (verifSecto == 'DR_KO' || verifSecto == 'DV_KO' || verifSecto == 'DMag_KO')) ||
            (actualUserProfile.Name.containsIgnoreCase('K/K - RV') && (verifSecto == 'DR_KO' || verifSecto == 'DV_KO' || verifSecto == 'DMag_KO')) ||
            (actualUserProfile.Name.containsIgnoreCase('K/K - DV') && (verifSecto == 'DR_KO' || verifSecto == 'DV_KO')) ||
            (actualUserProfile.Name.containsIgnoreCase('K/K - DR') && verifSecto == 'DR_KO'))
        {
            lockSearch = true;
            //optionsRegion.add(new SelectOption('', ''));
            codeRegion =  '';
            codeDV =  '';
            codeMag =  '';
            if(verifSecto == 'DR_KO')
            userinfos.codeDR__c.addError(System.Label.ldp_erreur_sectoRegion);
            if(verifSecto == 'DV_KO')
            userinfos.codeDV__c.addError(System.Label.ldp_erreur_sectoDV);
            if(verifSecto == 'DMag_KO')
            userinfos.codeMagasin__c.addError(System.Label.ldp_erreur_sectoMagasin);
        // Sinon, exécute le rendu des picklists
        } else {
            String paramDR = ApexPages.currentPage().getParameters().get('DR');
            String paramDV = ApexPages.currentPage().getParameters().get('DV');
            paramMag = ApexPages.currentPage().getParameters().get('magasin');
            
            if(userinfos.CodeDR__c!=null && userinfos.CodeDR__c != '*')
                codeRegion =  userinfos.CodeDR__c;
            if(paramDR!=null && paramDR != '*')                                     
                codeRegion =  paramDR;
            getDV();
            if(userinfos.CodeDV__c!=null && userinfos.CodeDV__c != '*')
                codeDV =  userinfos.CodeDV__c;
            if(paramDV!=null && paramDV != '*')                                     
                codeDV =  paramDV;
            getMag();

            if(!String.isBlank(paramMag) && paramMag != '*') {                                 
                codeMag =  paramMag;
            }

            else {
                if(userinfos.CodeMagasin__c!=null && userinfos.CodeMagasin__c != '*') {
                    codeMag =  userinfos.CodeMagasin__c;
                }

                if(!optionsMag.isEmpty()) paramMag = optionsMag[0].getValue();
                else paramMag = codeMag;
            }

            /*else if ( (String.isBlank(paramMag) || paramMag == '*') && !optionsMag.isEmpty()) {
                paramMag = optionsMag[0].getValue();
            }

            
            else if(userinfos.CodeMagasin__c!=null && userinfos.CodeMagasin__c != '*') {
                codeMag =  userinfos.CodeMagasin__c;
                paramMag = codeMag;
            }*/
            

            // Bloque la sélection du magasin pour les vendeurs
            if(actualUserProfile.Name.containsIgnoreCase('K/K - Vendeur')) lockSearch = true;
        }
    }

    /**
    * @description Fonction appelé lors l'ouverture de la page
    */
    public void insertUserStats() {
        Utils_UserStats.insertUserStats(Userinfo.getUserId(), 'compteurListePhones__c');
    }

    /**
    * @description Asynchrone - Incrémentation statistique utilisateur des exports
    * @param nbAccount Nombre de compte de la recherche
    */
    @future
    public static void ajouteStatsExport(Integer nbAccount) {
        try{
            UserStats__c stats;
            List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, nbComptesExportes__c, nbExportsEffectues__c
                                                FROM UserStats__c
                                                WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

            if (statsList.isEmpty()) {
                stats = new UserStats__c(name                   = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
                                        user__c                 = UserInfo.getUserId(),
                                        date__c                 = System.today(),
                                        nbComptesExportes__c    = 0,
                                        nbExportsEffectues__c   = 0);
            } else{
                stats = statsList[0];
            }

            stats.nbComptesExportes__c = stats.nbComptesExportes__c + nbAccount;
            stats.nbExportsEffectues__c = stats.nbExportsEffectues__c + 1;

            upsert stats;
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Incrémentation statistique utilisateur des recherches
    * @param historiAccount Critère de la recherche
    * @param nbAccount Nombre de compte de la recherche
    */
    public static void ajouteStatsRecherche(String historiqueParametres, Integer nbAccount) {
        try{
            UserStats__c stats;
            List<UserStats__c> statsList = [SELECT id, name, user__c, date__c, nbComptesRetournes__c, nbRecherchesEffectuees__c, historiqueRequetes__c
                                                FROM UserStats__c
                                                WHERE user__c = :UserInfo.getUserId() AND date__c = TODAY] ;

            if (statsList.isEmpty()) {
                stats = new UserStats__c(name                   = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' / ' + System.today(),
                                        user__c                 = UserInfo.getUserId(),
                                        date__c                 = System.today(),
                                        nbComptesRetournes__c   = 0,
                                        nbRecherchesEffectuees__c = 0,
                                        historiqueRequetes__c   = null);
            } else{
                stats = statsList[0];
            }
            stats.nbComptesRetournes__c = stats.nbComptesRetournes__c + nbAccount;
            stats.nbRecherchesEffectuees__c = stats.nbRecherchesEffectuees__c + 1;
            if (stats.historiqueRequetes__c == null)
                stats.historiqueRequetes__c = historiqueParametres;
            else
                stats.historiqueRequetes__c = stats.historiqueRequetes__c + '|' + historiqueParametres;
            upsert stats;
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Récupération des coordonnées d'une adresse via DQE
    * @param idVoie Id de la rue renvoyée par DQE Adresse
    * @param numero Numéro de la rue renvoyé par DQE Adresse
    * @param codePays Trigramme du pays renvoyé par DQE Adresse
    * @return Utils_DQE.GeocodeResultType Objet GeocodeResultType contenant les informations de l'adresse et sa géolocalisation
    */
    @RemoteAction
    public static Utils_DQE.GeocodeResultType DQELongLat(String idVoie, String numero, String codePays) {
        try {
            return Utils_DQE.DQELongLat(idVoie, numero, codePays);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description REMOTEACTION - Récupération des statistiques utilisateur
    * @return UserStats__c Statistique de l'utilisateur
    */
    @RemoteAction
    public static UserStats__c getTodayStats(){
        List<UserStats__c> allStats = new List<UserStats__c>();
        UserStats__c myStats = new UserStats__c();

        try {
            allStats = [SELECT nbComptesRetournes__c, nbRecherchesEffectuees__c, nbExportsEffectues__c, nbComptesExportes__c
                            FROM UserStats__c WHERE date__c = TODAY AND user__c = :UserInfo.getUserId()];

            if(!allStats.isEmpty())
                myStats = allStats[0];
            else {
                myStats = new UserStats__c(nbComptesRetournes__c =0, nbRecherchesEffectuees__c=0,
                                            nbExportsEffectues__c=0, nbComptesExportes__c = 0);
            }
            return myStats;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
        
    /**
    * @description REMOTEACTION - Recherche des comptes (en cours d'optimisation)
    * @param argument Objet des différents critères
    * @param rues Liste des rues
    * @return List<Utils_InnerClasses.CustomCompte> Liste des comptes trouvés
    */
    @RemoteAction
    public static List<Utils_InnerClasses.CustomCompte> recupereCompte(Map<String,String> argument, List<String> rues) {
        system.debug('### DEBUT recupereCompte');
        try{
            List<Utils_InnerClasses.CustomCompte> listAccountsAll = new List<Utils_InnerClasses.CustomCompte>();
            String soqlQuery = ' ';
            String historiqueParametres = ' ';
            String conditions = ' ';
            Integer nbAccount = 0;
            List<String> addressError = new List<String>();
            Decimal searchLimit = PropertiesUtils.getIntegerValue('ldp.search.accountmax', 100);
            Decimal accountAvecProduitLimit = PropertiesUtils.getIntegerValue('ldp.search.accountavecproduit', 1000);
            String[] codeMagasins;

            // Init
            Set<String> optionListLigneDevis = new Set<String>();
            Set<Id> quoteLineId = new Set<Id>();
            String magasin = argument.get('magasin');
            String produit = argument.get('codeP');
            String option = argument.get('codeO');
            String typeE = argument.get('typeEnregistrement');
            RecordType recType = [SELECT Id, Name, IsPersonType FROM RecordType WHERE sobjectType='Account' AND Id=:argument.get('typeEnregistrement') LIMIT 1];
            Id RT_AccEntity = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
            Id RT_AccProvider = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);

            // Si pas de produit mais option - Erreur
            if(String.isBlank(produit) && String.isNotBlank(option)){
                return listAccountsAll;
            }

            // Construction requête sur compte
            soqlQuery = 'SELECT Id, Name, FirstName, LastName, isPersonAccount,Type, RecordType.Name, LastModifiedDate, LastModifiedBy.Name, rue__c, codePostal__c, ville__c, pays__c, '
                        +   'Owner.Name, AccountNumber, telephoneDomicile__c, telephoneMobile__c, autreTelephone__c, optinTelephoneDomicileKparK__c, optinTelephoneMobileKparK__c, '
                        +   'Localisation__Latitude__s, Localisation__Longitude__s, email__c, x__c, y__c,profession__c, '
                        +   'nbAppelsSortants__c, nbPhonings__c, dateDernierAppelSortantKparK__c, nomFichierSource__c FROM Account '
                        + 'WHERE IsDeleted=false AND fichiersOpposition__c = null ';
            // Joignabilité
            if(recType.IsPersonType)
                conditions += ' AND (PersonOtherPhone != \'\' OR PersonMobilePhone != \'\' OR PersonHomePhone != \'\' OR Phone != \'\') ';
            else
                conditions += ' AND (contactParDefaut__r.OtherPhone != \'\' OR contactParDefaut__r.MobilePhone != \'\' OR contactParDefaut__r.HomePhone != \'\' OR Phone != \'\') ';
            // Magasin
            if(String.isNotBlank(magasin) && magasin != '0') {
                system.debug('## magasin : ' + magasin );
                codeMagasins = TerritoryUtils.getMagasinsKStore(magasin);
                
                conditions += ' AND (';
                for (Integer i = 0; i < codeMagasins.size(); i++) {
                    String codeMagasin = codeMagasins[i];
                    if (i == 0)
                        conditions += 'codeMagasinTechnique__c =\''+ codeMagasin +'\'';
                    else
                        conditions += ' OR codeMagasinTechnique__c =\''+ codeMagasin +'\'';
                    historiqueParametres += 'codeMagasinTechnique__c=' + codeMagasin +';';
                }
                conditions += ')';
            }
            if(String.isNotBlank(argument.get('typeEnregistrement'))){
                conditions+= ' AND RecordTypeId =\''+ typeE +'\'';
                historiqueParametres += 'RecordType='+typeE+';';
            } else {
                conditions+= ' AND RecordTypeId !=\''+ RT_AccEntity +'\' AND RecordTypeId !=\''+ RT_AccProvider +'\'';
                historiqueParametres += 'RecordType!='+RT_AccEntity+';RecordType!='+RT_AccProvider+';';
            }
            if(String.isNotBlank(argument.get('typeCompte'))){
                conditions+= ' AND Type =\''+ argument.get('typeCompte') +'\'';
                historiqueParametres += 'Type='+argument.get('typeCompte')+';';
            }
            if(String.isNotBlank(argument.get('proprietaireId'))){
                conditions+= ' AND OwnerId=\''+ argument.get('proprietaireId') +'\'';
                historiqueParametres += 'Owner='+argument.get('proprietaireId')+';';
            }      
            // Recherche par géocodage des rues si extension définit
            if(String.isNotBlank(argument.get('extension'))) 
            {
                if(!rues.isEmpty())
                {
                    conditions+= ' AND (';
                    historiqueParametres += 'Localisation__c=(';
                    for(Integer i=0; rues.size() > i; i++){
                        String rue=rues[i];                                         
                        // On tente le géocodage
                        Utils_Cartographie.GoogleMapsJSONComponents goeResult = Utils_Cartographie.getGeoGoogleMaps(rue, argument.get('cp'), argument.get('ville'),false);
                        if(goeResult!=null && goeResult.partial_match!=true) {  
                            Utils_Cartographie.GoogleMapsJSONLatLng latLng = goeResult.geometry.location;       
                            if(i!=0) conditions+= ' OR ';
                            conditions += 'DISTANCE(Localisation__c, GEOLOCATION(' + latLng.lat + ', ' + latLng.lng + '), \'km\') < ' + Integer.valueOf(argument.get('extension'));
                            historiqueParametres += 'Loc=' + latLng.lat + ', ' + latLng.lng + ';';
                        } else {
                            addressError.add(rue+' '+argument.get('cp')+' '+argument.get('ville'));
                        }   
                    }
                    conditions+= ')';
                    historiqueParametres += ');';
                }
            }
            //Sinon, recherche par rue
            else 
            {   
                // Compte personnel - filtre sur champs person
                if(recType.IsPersonType == true){
                    Boolean addORLogic = false;
                    if(!rues.isEmpty()){
                        conditions+= ' AND (';
                        historiqueParametres += 'rue__c=(';
                        for(String rue : rues){
                            if(addORLogic){
                                conditions+= ' OR ';
                                addORLogic = false;
                            }
                            if(String.isNotBlank(rue)){
                                conditions+= 'PersonMailingStreet LIKE \'%'+ rue +'%\'';
                                historiqueParametres += 'PersonMailingStreet='+rue+';';
                                addORLogic = true;
                            }
                        }
                        conditions+= ')';
                        historiqueParametres += ');';
                    }
                    if(String.isNotBlank(argument.get('ville'))){
                        conditions+= ' AND PersonMailingCity LIKE \'%'+ argument.get('ville') +'%\'';
                        historiqueParametres += 'PersonMailingCity='+argument.get('ville')+';';
                    }
                    if(String.isNotBlank(argument.get('cp'))){
                        conditions+= ' AND PersonMailingPostalCode = \''+ argument.get('cp') +'\'';
                        historiqueParametres += 'PersonMailingPostalCode='+argument.get('cp')+';';
                    }
                } else {
                    // Compte pro - filtre sur champs custom
                    Boolean addORLogic = false;
                    if(!rues.isEmpty()){
                        conditions+= ' AND (';
                        historiqueParametres += 'rue__c=(';
                        for(String rue : rues){
                            if(addORLogic){
                                conditions+= ' OR ';
                                addORLogic = false;
                            }
                            if(String.isNotBlank(rue)){
                                conditions+= 'BillingStreet LIKE \'%'+ rue +'%\'';
                                historiqueParametres += 'BillingStreet='+rue+';';
                                addORLogic = true;
                            }
                        }
                        conditions+= ')';
                        historiqueParametres += ');';
                    }
                    if(String.isNotBlank(argument.get('ville'))){
                        conditions+= ' AND BillingCity LIKE \'%'+ argument.get('ville') +'%\'';
                        historiqueParametres += 'BillingCity='+argument.get('ville')+';';
                    }
                    if(String.isNotBlank(argument.get('cp'))){
                        conditions+= ' AND BillingPostalCode = \''+ argument.get('cp') +'\'';
                        historiqueParametres += 'BillingPostalCode='+argument.get('cp')+';';
                    }
                }
            }
            if(String.isNotBlank(argument.get('fichierSource')) && argument.get('fichierSource') != '0'){
                conditions+= ' AND nomFichierSource__c LIKE \'%'+ argument.get('fichierSource') +'%\'';
                historiqueParametres += 'nomFichierSource__c='+argument.get('fichierSource')+';';
            }            
            if(String.isNotBlank(argument.get('dernierAppel'))){
                String[] splitedDernierAppel = (argument.get('dernierAppel')).split(' ');
                String splitedDernierAppel0 = splitedDernierAppel[0];
                // On applique le filtre
                if('Aucun' != splitedDernierAppel0) {
                    Integer nbDeMois = Integer.valueOf(splitedDernierAppel0);
                    nbDeMois = (nbDeMois == 1) ? 12 : nbDeMois;
                    Date today = System.today();
                    today = today.addMonths(-nbDeMois);
                    conditions += ' AND (dateDernierAppelSortantKparK__c = null OR dateDernierAppelSortantKparK__c < ' + today.year();
                    if(today.month() < 10) conditions+= '-0' + today.month(); else conditions+= '-' + today.month();
                    if(today.day() < 10) conditions+= '-0' + today.day(); else conditions+= '-' + today.day();
                    conditions += 'T00:00:00z)';
                }
                historiqueParametres += 'datedernierappel='+argument.get('dernierAppel')+';';
            }

            // Si produit mais pas d'option
            if(String.isNotBlank(produit) && String.isBlank(option)){
                system.debug('## produit : ' + produit );
                historiqueParametres += 'produit='+produit+';';

                // Récupère tous les comptes avec un devis possédant le produit
                Set<Id> compteListWithProduct = new Set<Id>();
                for(Quote quote : [SELECT compte__c, autreCompte__c
                                    FROM Quote
                                    WHERE Id IN (SELECT QuoteId
                                                 FROM QuoteLineItem
                                                 WHERE IsDeleted=false AND PricebookEntry.Product2.Name = :produit)
                                        AND (Status = :Constants.StatutDevisTransmis 
                                            OR Status = :Constants.StatutDevisVenduAttente
                                            OR Status = :Constants.StatutDevisVenduEnregistre
                                            OR Status = :Constants.StatutDevisVenduIncontournable)
                                      AND (RecordTypeId = :DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_RO) 
                                            OR RecordTypeId = :DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_TRANSMISVENDU))
                                      AND compte__r.RecordTypeId = :typeE
                                      AND compte__r.codeMagasinTechnique__c IN :codeMagasins]) {
                    if(quote.compte__c != null)
                        compteListWithProduct.add(quote.compte__c);
                    if(quote.autreCompte__c != null)
                        compteListWithProduct.add(quote.autreCompte__c);
                }
                // Ajout de la condition sur les comptes des devis
                String Id_compte = '';
                if(!compteListWithProduct.isEmpty()) {
                    for(Id compteRequete : compteListWithProduct) {
                        if(compteRequete != null) Id_compte += '\'' + compteRequete + '\',';
                    }
                    Id_compte = Id_compte.substring(0, (Id_compte.length()-1));
                    conditions+= ' AND Id IN ( '+ Id_compte + ' ) ';
                } else {
                    return listAccountsAll;
                }
            }
            
            // Si produit et option
            else if(String.isNotBlank(produit) && String.isNotBlank(option)) {
                system.debug('## produit : ' + produit );
                system.debug('## option : ' + option);
                historiqueParametres += 'produit='+produit+';option='+option+';';
                                
                // Récupère toutes les lignes de devis possédant l'option 
                List<Option__c> optionList = [SELECT Id, ligneDevis__c
                                              FROM Option__c
                                              WHERE Codeoption__c = :option
                                                AND ligneDevis__c IN (
                                                    SELECT Id
                                                    FROM QuoteLineItem
                                                    WHERE IsDeleted=false AND PricebookEntry.Product2.Name = :produit
                                                        AND (
                                                            Quote.status = :Constants.StatutDevisTransmis 
                                                            OR Quote.status = :Constants.StatutDevisVenduAttente
                                                            OR Quote.status = :Constants.StatutDevisVenduEnregistre
                                                            OR Quote.status = :Constants.StatutDevisVenduIncontournable
                                                        )
                                                        AND (Quote.RecordTypeId = :DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_RO) 
                                                            OR Quote.RecordTypeId = :DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_TRANSMISVENDU))
                                                        AND Quote.compte__r.RecordTypeId = :typeE
                                                        AND Quote.compte__r.codeMagasinTechnique__c IN :codeMagasins
                                                )
                                             ];
                
                if(!optionList.isEmpty())
                {
                    system.debug('#### optionList found : '+optionList);
                    for (Option__c optionFilter : optionList)
                    {
                        optionListLigneDevis.add(optionFilter.ligneDevis__c);
                    }
                    
                    // Récupère tous les comptes avec un devis possédant le produit
                    if(!optionListLigneDevis.isEmpty()) 
                    {
                        Set<Id> compteListWithProduct = new Set<Id>();
                        for(Quote quote : [SELECT compte__c, autreCompte__c
                                           FROM Quote
                                           WHERE Id IN (SELECT QuoteId FROM QuoteLineItem WHERE Id IN :optionListLigneDevis)
                                             AND (Status = :Constants.StatutDevisTransmis 
                                                OR Status = :Constants.StatutDevisVenduAttente
                                                OR Status = :Constants.StatutDevisVenduEnregistre
                                                OR Status = :Constants.StatutDevisVenduIncontournable)
                                             AND (RecordTypeId = :DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_RO) 
                                                OR RecordTypeId = :DAL.getRecordTypeIdByDevName('Quote', Constants.RT_QUOTE_TRANSMISVENDU))
                                             AND compte__r.RecordTypeId = :typeE
                                             AND compte__r.codeMagasinTechnique__c IN :codeMagasins
                                           ORDER BY dateDevis__c
                                           LIMIT :Integer.valueOf(accountAvecProduitLimit)
                                          ]) 
                        {
                            system.debug('## quote found : '+quote);
                            if(quote.compte__c != null) 
                                compteListWithProduct.add( quote.compte__c );
                            if(quote.autreCompte__c != null)
                                compteListWithProduct.add( quote.autreCompte__c );
                        }
                        
                        // Ajout de la condition sur les comptes des devis
                        String Id_compte = '';
                        if(!compteListWithProduct.isEmpty()) {
                            for(Id compteRequete : compteListWithProduct) {
                                if(compteRequete != null) Id_compte += '\'' + compteRequete + '\',';
                            }
                            
                            Id_compte = Id_compte.substring(0, (Id_compte.length()-1)); //on retire la virgule en trop en fin de chaîne
                            conditions+= ' AND Id IN ( '+ Id_compte + ' ) ';
                        } else {
                            return listAccountsAll;
                        }
                    }
                } else {
                    return listAccountsAll;
                }
            }
            historiqueParametres = historiqueParametres.substring(0, (historiqueParametres.length()-1));
            conditions += ' AND (PersonMailingCountry = \'FRANCE\' OR BillingCountry = \'FRANCE\') ';
            soqlQuery+= conditions + ' ORDER BY dateDernierAppelSortantKparK__c ASC NULLS FIRST LIMIT ' + searchLimit;
            system.debug('## SOQL ==> ' + soqlQuery);

            // Exécution requête
            List<Account> resultSOQL = database.query(soqlQuery);
            
            // Filtre les comptes selon leur disponibilité dans la liste de phone
            if(!resultSOQL.isEmpty()) {
                List<PhoningVendeur__c> pho = [SELECT Id, compte__c, isProcessed__c FROM PhoningVendeur__c WHERE IsDeleted=false AND compte__c IN :resultSOQL];
                for(Account acc : resultSOQL) {
                    Event nullEvent = new Event();
                    nullEvent = null;
                    Utils_InnerClasses.CustomCompte accCustom = new Utils_InnerClasses.CustomCompte(nullEvent,acc);
                    accCustom.RueGeocode=String.join(addressError,'|');
                    Boolean isInDatabase = false;
                    for(PhoningVendeur__c ph : pho){
                        if(accCustom.Id == ph.compte__c && ph.isProcessed__c) 
                            isInDatabase = true;
                    }
                    if(!isInDatabase) 
                        listAccountsAll.add(accCustom);
                
                    // Insertion des stats                
                    if(!(acc.optinTelephoneDomicileKparK__c == false && acc.optinTelephoneMobileKparK__c == false)){
                        nbAccount++;
                    }
                }
            }
            ajouteStatsRecherche(historiqueParametres, nbAccount);
            
            // Retour des résultats
            system.debug('### FIN recupereCompte');
            return listAccountsAll;
        } 
        catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
        
    /**
    * @description Méthode exécutée lors de la validation de la liste des comptes
    *               Création d'une liste de phone
    *               Création d'un phone pour chaque compte
    * @param argument Critères utilisés pour la recherche
    * @param compteSearched Liste des comptes (custom)
    * @param secteurId Id du secteur
    * @param nameListe Nom de la liste de phone
    * @return Id de la liste de phones créée
    */
    @RemoteAction
    public static ListePhoningVendeur__c creerListePhones(Map<String,String> argument, String compteSearchedJSON, string secteurId, String nameListe) {     
        system.debug('### DEBUT creerListePhones');
        // Liste des phones à créer
        List<PhoningVendeur__c> phones = new List<PhoningVendeur__c>();
        List<Utils_InnerClasses.CustomCompte> compteSearched = new List<Utils_InnerClasses.CustomCompte>();
        try {
            if(String.isNotBlank(compteSearchedJSON))
                compteSearched = (List<Utils_InnerClasses.CustomCompte>)JSON.deserialize(compteSearchedJSON, List<Utils_InnerClasses.CustomCompte>.class);
            if(null != compteSearched && !compteSearched.isEmpty()) {
                system.debug('## Nom liste : '+nameListe);
            
                String typeEnregistrement = (argument != null) ? 
                                                ((argument.get('typeEnregistrement') == null || argument.get('typeEnregistrement') == '') ? null : argument.get('typeEnregistrement')) :
                                                    null;
            
                // Création de l'objet liste de phone
                ListePhoningVendeur__c liste = new ListePhoningVendeur__c();
            
                // Date et heure du jour        
                Datetime now = Datetime.now();
                String formattedDate = now.format('YYYY/MM/DD HH:mm:ss'); 
            
                // Mise à jour des champs de la liste de phone
                if(String.isBlank(nameListe)) {
                    nameListe = (UserInfo.getFirstName() == null ? '' : UserInfo.getFirstName()) + ' ' 
                            + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName()) + ' - ' + formattedDate;
                }
                liste.name = nameListe;
                liste.user__c = UserInfo.getUserId();
                liste.recordType_Filtre__c = typeEnregistrement;
                liste.typeCompte_Filtre__c = (argument != null) ?
                                                ((argument.get('typeCompte') == null || argument.get('typeCompte') == '') ? null : argument.get('typeCompte')) : 
                                                    null;
                liste.proprietaire_Filtre__c = (argument != null) ?
                                                ((argument.get('proprietaireId') == null || argument.get('proprietaireId') == '' || argument.get('proprietaireId') == '000000000000000') ? null : argument.get('proprietaireId')) : 
                                                    null;
                liste.rue1_Filtre__c = getArgumentValue(argument, 'rue');
                liste.codePostal_Filtre__c = (argument != null) ?
                                            ((argument.get('cp') == null || argument.get('cp') == '') ? null : Integer.valueOf(argument.get('cp'))) : 
                                                    null;
                liste.rue2_Filtre__c = getArgumentValue(argument, 'rue2');
                liste.rue3_Filtre__c = getArgumentValue(argument, 'rue3');
                liste.ville_Filtre__c = getArgumentValue(argument, 'ville');
                liste.dernierAppel_Filter__c = getArgumentValue(argument, 'dernierAppel');
            
                // Création de la liste de phone via les critères géographiques
                if(null != secteurId) {
                    // Récupération de la sectorisation
                    Sectorisation__c sector = [SELECT Id, codeRegion__c, codeMagasin__c, codeDV__c FROM Sectorisation__c WHERE Id = :secteurId LIMIT 1];
                    liste.DR_Filtre__c = sector.codeRegion__c;
                    liste.DV_Filtre__c = sector.codeDV__c;
                    liste.magasin_Filtre__c = sector.codeMagasin__c;
                } 
                // Création de la liste de phone via les critères de compte
                else {
                    liste.DR_Filtre__c = getArgumentValue(argument, 'region');
                    liste.DV_Filtre__c = getArgumentValue(argument, 'dv');
                    liste.magasin_Filtre__c = getArgumentValue(argument, 'magasin');
                }
            
                // Création de la liste de phone
                insert liste;
            
                // Récupération des comptes personnels et pro
                for(Utils_InnerClasses.CustomCompte compte : compteSearched) {
                    // Création de l'objet phone
                    PhoningVendeur__c phone = new PhoningVendeur__c();
                
                    // Mise à jour des champs de l'objet phone
                    phone.liste__c = liste.Id;
                    phone.name = compte.Name + ' - ' + liste.name;
                    phone.compte__c = compte.Id;
                    phones.add(phone);
                }

                // Création des phones
                if(!phones.isEmpty()) {
                    insert phones;
                }
                system.debug('### FIN creerListePhones');
                // Retourne l'id de la liste créée
                return liste;
            }
            return null;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Export PDF
    * @return PageReference Page Visualforce
    */
    public PageReference exportPDF(){
        system.debug('### DEBUT exportPDF');
        if(dataExport != null) {
            // Init
            initializeExport();
            // Affichage PDF
            PageReference pExport = Page.VF_ListeDePhonesPDF;
            pExport.setRedirect(false);
            system.debug('### FIN exportPDF');
            return pExport;
        } else{
            log.addErrorMessage(System.Label.ldp_erreur_exportPDFVide);
            return null;
        }
    }

    /**
    * @description Export CSV
    * @return PageReference Page Visualforce
    */
    public PageReference exportCSV(){
        system.debug('### DEBUT exportCSV');

        if(dataExport != null) {
            // Init
            initializeExport();
            // Affichage EXCEL
            PageReference pExport = Page.VF_ListeDePhonesCSV;
            fileName = 'exportComptes_' + Datetime.now().format('yyyyMMdd');
            pExport.setRedirect(false);
            system.debug('### FIN exportCSV');
            return pExport;
        } else{
            log.addErrorMessage(System.Label.ldp_erreur_exportCSVVide);
            return null;
        }
    }
    
    /**
    * @description Initialise les données pour l'export CSV ou PDF
    */
    private void initializeExport(){
        listAccountsExport1 = new List<Account>();
        listAccountsExport2 = new List<Account>();
        listAccountsExport3 = new List<Account>();
        // Formatage des résultats pour l'export
        Integer compteur = 0;
        List<Account> accountList = formatValeursExport();
        system.debug('## Taille liste export des comptes : ' + accountList.size());
        for(Account acc : accountList) {
            compteur++;
            if(compteur <= 1000)
                listAccountsExport1.add(acc);
            else if (compteur > 1000 && compteur <= 2000)
                listAccountsExport2.add(acc);
            else if (compteur > 2000 && compteur <= 3000)
                listAccountsExport3.add(acc);
        }
        system.debug('## Taille liste export 1 : ' + listAccountsExport1.size());
        system.debug('## Taille liste export 2 : ' + listAccountsExport2.size());
        system.debug('## Taille liste export 3 : ' + listAccountsExport3.size());

        // Mise à jour des stats
        ajouteStatsExport(accountList.size());
    }

    /**
    * @description Recupération des comptes trouvés pour l'export
    * @return List<Account> Liste des comptes à exporter
    */
    private List<Account> formatValeursExport() {
        List<Account> listAccountsExport = new List<Account>();
        List<String> accountIdExport = new List<String>();

        // Récupération des comptes envoyés par la page VF
        system.debug('## Données export : ' + dataExport);
        accountIdExport = (List<String>)JSON.deserialize(dataExport, List<String>.class);
        Map<String,Account> accountMap = new Map<String,Account>([SELECT Id, Name, FirstName, LastName,Type, rue__c, codePostal__c, ville__c, pays__c, Owner.Name, AccountNumber, 
                                telephoneDomicile__c, telephoneMobile__c, autreTelephone__c, optinTelephoneDomicileKparK__c, optinTelephoneMobileKparK__c, x__c, y__c,profession__c,
                                email__c, nbPhonings__c, nbAppelsSortants__c, dateDernierAppelSortantKparK__c FROM Account WHERE Id IN :accountIdExport]);
        // Préparation selon données triés
        for(String accId : accountIdExport) {
            Account accToExport=accountMap.get(accId);
            if(accToExport.optinTelephoneDomicileKparK__c == false && accToExport.optinTelephoneMobileKparK__c == false) {
                system.debug(accToExport);
            } else {
                // Formatage des données pour l'export
                listAccountsExport.add(formatAccountForExport(accToExport));
            }
        }

        return listAccountsExport;
    }

    /**
    * @description Formate les champs d'un compte en vue de l'export
    * @param accountForExport Compte à formatter
    * @return Account Compte formatté
    */
    private static Account formatAccountForExport(Account accountToExport) {
        // nbPhonings__c
        if(accountToExport.nbPhonings__c == null) {
            accountToExport.nbPhonings__c = 0;
        }
        else accountToExport.nbPhonings__c = Integer.valueOf(accountToExport.nbPhonings__c); //pour éviter que l'export afiche "2.0 appels"
        // nbAppelsSortants__c
        if(accountToExport.nbAppelsSortants__c == null) {
            accountToExport.nbAppelsSortants__c = 0;
        }
        else accountToExport.nbAppelsSortants__c = Integer.valueOf(accountToExport.nbAppelsSortants__c);


        return accountToExport;
    }

    public Double offset{get{
        //Milliseconds to Day
        return UserInfo.getTimeZone().getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}

    ////////////////////////////////////////////////////////
    // CRITERE GEOGRAPHIQUE + CREATION DE LISTE DE PHONES //
    ////////////////////////////////////////////////////////
    
    /**
    * @description REMOTEACTION - Récupération des coordonées en X et Y du secteur
    * @param sectorName Nom du secteur
    * @return Utils_Cartographie.Sector Objet contenant les points cartographique (WGS84) du secteur
    */
    @RemoteAction
    public static Utils_Cartographie.Sector getSectorCoord(String sectorName) {
        try {
            return Utils_Cartographie.getSectorCoord(sectorName);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description REMOTEACTION - Recherche de comptes via critères géographiques selon les filtres Type ou RDV/Service
    * Retourne tous les comptes trouvés via les filtres
    * @param codeMagasin Code du magasin (secteur)
    * @param types Type de compte à rechecher (Client, prospect etc...)
    * @param rdvType Type de RDV à rechecher
    * @param xleft Longitude du bord gauche de la carte (Coordonnée WGS84)
    * @param xright Longitude du bord droit de la carte (Coordonnée WGS84)
    * @param ytop Latitude du bord haut de la carte (Coordonnée WGS84)
    * @param ybottom Latitude du bord bas de la carte (Coordonnée WGS84)
    * @return Map<string, Set<Utils_InnerClasses.CustomCompte>> Objet contenant les comptes selon leur type/rdv
    */
    @RemoteAction
    public static Map<string,Set<Utils_InnerClasses.CustomCompte>> getTypeComptes(string codeMagasin, List<string> types, String rdvType, Decimal latitude_min, Decimal latitude_max, Decimal longitude_max, Decimal longitude_min) {
        system.debug('### DEBUT getTypeComptes');
        try {
            Map<string,Set<Utils_InnerClasses.CustomCompte>> objectToReturn = new Map<string,Set<Utils_InnerClasses.CustomCompte>>();
            Map<string,Set<Utils_InnerClasses.CustomCompte>> objectToReturnFinal = new Map<string,Set<Utils_InnerClasses.CustomCompte>>();
            Set<string> compteTypes = new Set<string>();
            Set<Id> accsIds = new Set<Id>();
            Integer compteur = 0;
            Map<String, String> filterTypeMap =  new Map<String, String> {'Piste' => Constants.ACCOUNT_TYPE_PISTE, 'PreContact' => Constants.ACCOUNT_TYPE_PRECONTACT, 
                                                                          'Contact' => Constants.ACCOUNT_TYPE_CONTACT, 'Prospect' => Constants.ACCOUNT_TYPE_PROSPECT, 
                                                                          'Client' => Constants.ACCOUNT_TYPE_CLIENT, 'ExClient' => Constants.ACCOUNT_TYPE_EXCLIENT};

            system.debug('## Filtres type : '+types);  
            if(String.isBlank(rdvType)){
                // Recherche par type de compte
                for(String ct : types){
                    objectToReturn.put(ct, getComptesNoRDV(codeMagasin,latitude_min,latitude_max,longitude_max,longitude_min,filterTypeMap.get(ct)));
                }
            } else {   
                // Recherche par RDV                     
                if(types.isEmpty()) {
                    compteTypes = new Set<String>(filterTypeMap.values());
                } else {
                    for(String ct : types){
                        compteTypes.add(filterTypeMap.get(ct));
                    }
                }
                
                if((rdvType == Constants.EVENT_TYPE_R1 || rdvType == Constants.EVENT_TYPE_R2 || rdvType == Constants.EVENT_TYPE_RP) && objectToReturn.size() < mapDotLimits)
                    objectToReturn.put(rdvType, getComptesRDVProchainList(codeMagasin,latitude_min,latitude_max,longitude_max,longitude_min,rdvType,compteTypes));
                if(rdvType == 'Prospections' && objectToReturn.size() < mapDotLimits)
                    objectToReturn.put(rdvType, getProspectionsProchaineList(codeMagasin,latitude_min,latitude_max,longitude_max,longitude_min,compteTypes));
                if((rdvType == 'Metrages' || rdvType == 'Installations' || rdvType == 'InterventionsSAV') && objectToReturn.size() < mapDotLimits)
                    objectToReturn.put(rdvType, getComptesRDVbyTypeList(codeMagasin,latitude_min,latitude_max,longitude_max,longitude_min,rdvType,compteTypes));
            }
            // Récupération des IDs des comptes
            for(String clef : objectToReturn.keySet()){
                for(Utils_InnerClasses.CustomCompte cuco : objectToReturn.get(clef)){
                    accsIds.add(cuco.Id);
                }
            }
            // Filtre les comptes selon leur disponibilité dans la liste de phone
            if(!accsIds.isEmpty()) {
                List<PhoningVendeur__c> pho = [SELECT Id, compte__c, isProcessed__c FROM PhoningVendeur__c WHERE IsDeleted=false AND compte__c IN :accsIds];
                for(String clef : objectToReturn.keySet()){
                    Set<Utils_InnerClasses.CustomCompte> customCompteLibres = new Set<Utils_InnerClasses.CustomCompte>();
                    for(Utils_InnerClasses.CustomCompte cuco : objectToReturn.get(clef)){
                        if(compteur < mapDotLimits){
                            Boolean isInDatabase = false;
                            for(PhoningVendeur__c ph : pho){
                                if(cuco.Id == ph.compte__c && ph.isProcessed__c){
                                    isInDatabase = true;
                                }
                            }
                            if(!isInDatabase){
                                customCompteLibres.add(cuco);
                                compteur++;
                            }
                        }
                    }
                    objectToReturnFinal.put(clef, customCompteLibres);
                }
            }

            system.debug('## Taille finale : '+objectToReturnFinal.values().size());
            system.debug('### FIN getTypeComptes');
            return objectToReturnFinal;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description REMOTEACTION - Recherche de comptes via critères géographiques
    * Retourne tous les comptes affichés sur la carte
    * @param comptesId Liste des Ids des comptes
    * @return Set<Utils_InnerClasses.CustomCompte> Objet contenant les comptes
    */
    @RemoteAction
    public static Set<Utils_InnerClasses.CustomCompte> getAllComptes(List<String> comptesId ) {
        system.debug('### DEBUT getAllComptes');
        Integer searchAccLimit = Integer.valueOf(PropertiesUtils.getIntegerValue('ldp.search.accountmax', 100));
        Event nullEvent = new Event();
        nullEvent = null;
        try {
            Set<Utils_InnerClasses.CustomCompte> objectToReturn = new Set<Utils_InnerClasses.CustomCompte>();
            List<Account> comptesList = new List<Account>();
            // Récupération des comptes 
            comptesList = [SELECT Id, Type, Name, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, 
                                codePostal__c, OwnerId, Owner.Name, email__c,autreTelephone__c,telephoneDomicile__c, x__c, y__c,profession__c ,
                                telephoneMobile__c,optinTelephoneDomicileKparK__c,optinTelephoneMobileKparK__c,nbPhonings__c,nbAppelsSortants__c, 
                                dateDernierAppelSortantKparK__c,AccountNumber
                            FROM Account 
                            WHERE Id IN :comptesId LIMIT :searchAccLimit];
            if(!comptesList.isEmpty()) {
                for(Account compte : comptesList) {
                    objectToReturn.add(new Utils_InnerClasses.CustomCompte(nullEvent, compte));
                }
            }
            
            system.debug('## Taille : '+objectToReturn.size());
            system.debug('### FIN getAllComptes');
            return objectToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Récupération des comptes du secteur choisi
    * @param codeMagasin Code du magasins (secteur)
    * @param latitude_min Coordonnée latitude minimale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_max Coordonnée longitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param comptesType Type des comptes a rechercher
    * @return Set<Utils_InnerClasses.CustomCompte> Liste des comptes rechercher
    */
    private static Set<Utils_InnerClasses.CustomCompte> getComptesNoRDV(string codeMagasin, Decimal latitude_min, Decimal latitude_max, Decimal longitude_max, Decimal longitude_min, String comptesType) {
        system.debug('### DEBUT getComptesNoRDV');
        system.debug('## Type : '+comptesType);
        Event nullEvent = new Event();
        nullEvent = null;

        try {
            Set<Utils_InnerClasses.CustomCompte> objectToReturn = new Set<Utils_InnerClasses.CustomCompte>();
            List<Account> comptesList = new List<Account>();
            // Récupération des comptes 
            comptesList = [SELECT Id, Type, Name, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, 
                                codePostal__c, OwnerId, Owner.Name, email__c,autreTelephone__c,telephoneDomicile__c, 
                                telephoneMobile__c,optinTelephoneDomicileKparK__c,optinTelephoneMobileKparK__c,nbPhonings__c,nbAppelsSortants__c, 
                                dateDernierAppelSortantKparK__c,AccountNumber, x__c, y__c,profession__c
                            FROM Account 
                            WHERE Type = :comptesType 
                            AND fichiersOpposition__c = null 
                            AND IsDeleted = false 
                            AND (autreTelephone__c != '' OR telephoneMobile__c != '' OR telephoneDomicile__c != '' OR Phone != '') 
                            AND codeMagasinTechnique__c = :codeMagasin
                            AND (Localisation__Longitude__s = NULL
                                OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                    AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                            LIMIT :mapDotLimits];

            if(!comptesList.isEmpty()) {
                for(Account compte : comptesList) {
                    objectToReturn.add(new Utils_InnerClasses.CustomCompte(nullEvent, compte));
                }
            }
            
            system.debug('## Taille : '+objectToReturn.size());
            system.debug('### FIN getComptesNoRDV');
            return objectToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description  Récupération des comptes des prochains RDV R1, R2 ou R+ du secteur choisi
    * @param codeMagasin Code du magasins (secteur)
    * @param latitude_min Coordonnée latitude minimale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_max Coordonnée longitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param rdvType Type des RDV a rechercher
    * @param comptesType Type des comptes a rechercher
    * @return Set<Utils_InnerClasses.CustomCompte> Liste des comptes rechercher
    */
    private static Set<Utils_InnerClasses.CustomCompte> getComptesRDVProchainList(string codeMagasin, Decimal latitude_min, Decimal latitude_max, Decimal longitude_max, Decimal longitude_min, String rdvType, Set<string> comptesType) {
        system.debug('### DEBUT getComptesRDVProchainList');
        system.debug('## RDV : '+rdvType);
        system.debug('## Type : '+comptesType);
        try {
            Set<String> compteIds = new Set<String>();
            Set<Utils_InnerClasses.CustomCompte> objectToReturn = new Set<Utils_InnerClasses.CustomCompte>();
            // Date du jour
            Date dateToday = system.today();
            // Date du jour + prochains jours (Ajout d'un jour supplémentaire pour prendre en compte le dernier jour - heure = 00:00:00)
            Date eventDate = dateToday.addDays(futurEventDaysFinal +1);

            // Récupération des événements du type rdv d'aujourd'hui et des prochains jours        
            List<Event> eventsList = [SELECT Id, ActivityDate, Owner.Name, Type, accountId  
                                      FROM Event 
                                      WHERE Type = :rdvType  
                                        AND ActivityDate >= :dateToday AND ActivityDate <= :eventDate
                                        AND isDeleted = false AND isArchived = false
                                        AND ownerId IN (SELECT id FROM User WHERE isActive = TRUE AND codeMagasin__c = :codeMagasin)];
                                        
            // Récupération des ids des comptes liés aux événements
            for(Event e : eventsList) {
                if(e.accountId != null) {
                    compteIds.add(e.accountId);
                }
            }
            
            // Récupération des comptes liés aux événements
            Map<String, Account> comptesMap = new Map<String, Account>([SELECT Id, Type, Name, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, 
                                                                                codePostal__c, OwnerId, Owner.Name, email__c,autreTelephone__c,telephoneDomicile__c, 
                                                                                telephoneMobile__c,optinTelephoneDomicileKparK__c,optinTelephoneMobileKparK__c,nbPhonings__c,nbAppelsSortants__c, 
                                                                                dateDernierAppelSortantKparK__c,AccountNumber, x__c, y__c,profession__c
                                                                         FROM Account 
                                                                         WHERE Id IN :compteIds  
                                                                         AND Type IN :comptesType 
                                                                         AND fichiersOpposition__c = null 
                                                                         AND isDeleted = false 
                                                                         AND (autreTelephone__c != '' OR telephoneMobile__c != '' OR telephoneDomicile__c != '' OR Phone != '')  
                                                                         AND (Localisation__Longitude__s = NULL
                                                                            OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                                                         AND codeMagasinTechnique__c = :codeMagasin
                                                                         LIMIT :mapDotLimits]);
            
            if(!comptesMap.values().isEmpty()) {
                for(Event e : eventsList) {
                    Account compte = comptesMap.get(e.accountId);
                    if(null != compte) objectToReturn.add(new Utils_InnerClasses.CustomCompte(e, compte));
                }
            }
            
            system.debug('## Taille : '+objectToReturn.size());
            system.debug('### FIN getComptesRDVProchainList');
            return objectToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Récupération des comptes ayant un contrat selon leur type, le jour et selon le secteur choisi
    * Métrages, poses et interventions SAV d'aujourd'hui et des prochains jours
    * @param codeMagasin Code du magasins (secteur)
    * @param latitude_min Coordonnée latitude minimale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_max Coordonnée longitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param ptype Type des contrats a rechercher
    * @param comptesType Type des comptes a rechercher
    * @return Set<Utils_InnerClasses.CustomCompte> Liste des comptes rechercher
    */
    private static Set<Utils_InnerClasses.CustomCompte> getComptesRDVbyTypeList(string codeMagasin, Decimal latitude_min, Decimal latitude_max, Decimal longitude_max, Decimal longitude_min, string ptype, Set<string> comptesType) {
        system.debug('### DEBUT getComptesRDVbyTypeList');
        system.debug('## Service : '+ptype);
        system.debug('## Type : '+comptesType);
        Event nullEvent = new Event();
        nullEvent = null;
        try {
            Set<Utils_InnerClasses.CustomCompte> comptesRDV = new Set<Utils_InnerClasses.CustomCompte>();
            List<ServiceAppointment> rdvDeServiceList = new List<ServiceAppointment>();
            Set<String> comptesWithRDV = new Set<String>();
            // Date du jour
            Date dateToday = system.today();
            // Date du jour + prochains jours (Ajout d'un jour supplémentaire pour prendre en compte le dernier jour - heure = 00:00:00)
            Date eventDate = dateToday.addDays(futurEventDaysFinal +1);
        
            // Récupération des rdvDeService selon les types et la date
            if(ptype.equalsIgnoreCase('Metrages')){
                rdvDeServiceList =  [SELECT Id, AccountId FROM ServiceAppointment WHERE SchedStartTime >= :dateToday AND SchedStartTime <= :eventDate
                                        AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                                        AND (WorkType.Name = :Constants.WORKTYPE_METRAGE OR WorkType.Name = :Constants.ACTIVITY_TYPE_CONTROL)];
            }
            if(ptype.equalsIgnoreCase('Installations')){
                rdvDeServiceList =  [SELECT Id, AccountId FROM ServiceAppointment WHERE SchedStartTime >= :dateToday AND SchedStartTime <= :eventDate
                                        AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                                        AND (WorkType.Name = :Constants.WORKTYPE_INSTALLATION OR WorkType.Name = :Constants.ACTIVITY_TYPE_INTERVENTION OR WorkType.Name = :Constants.WORKTYPE_INSTALLATION_ECI)];
            }
            if(ptype.equalsIgnoreCase('InterventionsSAV')){
                rdvDeServiceList =  [SELECT Id, AccountId FROM ServiceAppointment WHERE SchedStartTime >= :dateToday AND SchedStartTime <= :eventDate
                                        AND (Status = :Constants.RDV_FSL_CONFIRME OR Status = :Constants.RDV_FSL_ENCOURS OR Status = :Constants.RDV_FSL_TERMINE OR Status = :Constants.RDV_FSL_DEBRIEFE)
                                        AND (WorkType.Name = :Constants.WORKTYPE_INTERVENTION_SAV OR WorkType.Name = :Constants.ACTIVITY_TYPE_DIAGNOSTIC OR WorkType.Name = :Constants.WORKTYPE_INTERVENTION_SAV_ECI)];
            }
            
            // Récupération des comptes des rdvDeService
            for(ServiceAppointment rdv : rdvDeServiceList) comptesWithRDV.add(rdv.AccountId);
            if(!comptesWithRDV.isEmpty()) {
                for(Account compte : [SELECT Id, Type, Name, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, 
                                            codePostal__c, OwnerId, Owner.Name, email__c,autreTelephone__c,telephoneDomicile__c, 
                                            telephoneMobile__c,optinTelephoneDomicileKparK__c,optinTelephoneMobileKparK__c, 
                                            AccountNumber, x__c, y__c, nbPhonings__c, nbAppelsSortants__c, profession__c, dateDernierAppelSortantKparK__c
                                         FROM Account 
                                         WHERE Id IN :comptesWithRDV 
                                         AND Type IN :comptesType  
                                         AND fichiersOpposition__c = null 
                                         AND isDeleted = false 
                                         AND (autreTelephone__c != '' OR telephoneMobile__c != '' OR telephoneDomicile__c != '' OR Phone != '') 
                                         AND (Localisation__Longitude__s = NULL
                                            OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                         AND codeMagasinTechnique__c = :codeMagasin
                                         LIMIT :mapDotLimits]) {
                    comptesRDV.add(new Utils_InnerClasses.CustomCompte(nullEvent, compte));
                }
            }
            system.debug('## Taille : '+comptesRDV.size());
            system.debug('### FIN getComptesRDVProchainList');
            return comptesRDV;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Récupération des prospections d'aujourd'hui et des prochains jours
    * @param codeMagasin Code du magasins (secteur)
    * @param latitude_min Coordonnée latitude minimale
    * @param latitude_max Coordonnée latitude maximale
    * @param longitude_max Coordonnée longitude maximale
    * @param longitude_min Coordonnée longitude minimale
    * @param comptesType Type des comptes a rechercher
    * @return Set<Utils_InnerClasses.CustomCompte> Liste des comptes rechercher
    */
    private static Set<Utils_InnerClasses.CustomCompte> getProspectionsProchaineList(String codeMagasin, Decimal latitude_min, Decimal latitude_max, Decimal longitude_max, Decimal longitude_min, Set<string> comptesType) {
        system.debug('### DEBUT getProspectionsProchaineList');
        system.debug('## Type : '+comptesType);
        try {
            // Récupération du RecordType 'FRA- Activité Prospection'
            Id RT_RDVProspection = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_PROSPECTION_RT);
            Set<String> compteIds = new Set<String>();
            Set<Utils_InnerClasses.CustomCompte> objectToReturn = new Set<Utils_InnerClasses.CustomCompte>();
            // Date du jour
            Date dateToday = system.today();
            // Date du jour + prochains jours (Ajout d'un jour supplémentaire pour prendre en compte le dernier jour - heure = 00:00:00)
            Date eventDate = dateToday.addDays(futurEventDaysFinal +1);
            
            // Récupération des événements prospection d'aujourd'hui et des prochains jours        
            List<Event> eventsList = [SELECT Id, ActivityDate, Owner.Name, Type, accountId  
                                      FROM Event 
                                      WHERE RecordTypeId = :RT_RDVProspection 
                                        AND ActivityDate >= :dateToday AND ActivityDate <= :eventDate
                                        AND isDeleted = false AND isArchived = false
                                        AND ownerId IN (SELECT id FROM User WHERE isActive = TRUE AND codeMagasin__c = :codeMagasin)];
                                        
            // Récupération des ids des comptes liés aux événements
            for(Event e : eventsList) {
                if(e.accountId != null) {
                    compteIds.add(e.accountId);
                }
            }
            
            // Récupération des comptes liés aux événements
            Map<String, Account> comptesMap = new Map<String, Account>([SELECT Id, Type, Name, Localisation__Latitude__s, Localisation__Longitude__s, rue__c, ville__c, 
                                                                            codePostal__c, OwnerId, Owner.Name, email__c,autreTelephone__c,telephoneDomicile__c, 
                                                                            telephoneMobile__c,optinTelephoneDomicileKparK__c,optinTelephoneMobileKparK__c,nbPhonings__c,nbAppelsSortants__c, 
                                                                            dateDernierAppelSortantKparK__c,AccountNumber, x__c, y__c,profession__c
                                                                         FROM Account 
                                                                         WHERE Id IN :compteIds  
                                                                         AND Type IN :comptesType 
                                                                         AND fichiersOpposition__c = null 
                                                                         AND isDeleted = false 
                                                                         AND (autreTelephone__c != '' OR telephoneMobile__c != '' OR telephoneDomicile__c != '' OR Phone != '') 
                                                                         AND (Localisation__Longitude__s = NULL
                                                                            OR (((Localisation__Longitude__s >= :longitude_min AND Localisation__Longitude__s <= :longitude_max) OR (Localisation__Longitude__s >= :longitude_max AND Localisation__Longitude__s <= :longitude_min))
                                                                                AND Localisation__Latitude__s >= :latitude_min AND Localisation__Latitude__s <= :latitude_max))
                                                                         AND codeMagasinTechnique__c = :codeMagasin
                                                                         LIMIT :mapDotLimits]);
            if(!comptesMap.values().isEmpty()) {
                for(Event e : eventsList) {
                    Account compte = comptesMap.get(e.accountId);
                    if(null != compte) objectToReturn.add(new Utils_InnerClasses.CustomCompte(e, compte));
                }
            }
            
            system.debug('## Taille : '+objectToReturn.size());
            system.debug('### FIN getProspectionsProchaineList');
            return objectToReturn;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Méthode exécutée lors de l'annulation, retour a la page précédente
    * @return PageReference Page Visualforce de la page d'édition du compte
    */
    public static PageReference cancel() {
        PageReference cancelPage = null;
        // Vérification du paramètre retURL
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        if(retURL != null && retURL != '') {
            cancelPage = new PageReference(retURL);
        } else {
            cancelPage = Page.VF_ConsultationListeDePhones;
        }
        return cancelPage;
    }
    
    /**
    * @description Méthode spécifique, permet de retourner la valeur d'un argument de la map
    * @param argument Critères utilisés pour la recherche
    * @param key Clé pour récupérer la valeur
    * @return String '' si argument == null OU argument.get(key) == null OU argument.get(key) == ''
    **/
    private static String getArgumentValue(Map<String,String> argument, string key) {
        return (argument != null) ? ((argument.get(key) == null || argument.get(key) == '') ? '' : argument.get(key)) : '';
    }
    
    /**
    * @description Méthode exécutée après a création de la liste de phone
    * @return PageReference Page Visualforce de la page de consultation des listes de phone
    **/
    public static PageReference redirectToConsultationListe() {
        PageReference consultationListe = Page.VF_ConsultationListeDePhones;    
        return consultationListe;
    }
}