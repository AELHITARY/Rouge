//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_AccountMerge
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/01/2018
//-- Version     : 1.2
//-- * 1.2 : RQM-29 - Matrice de dédoublonnage
//-- * 1.1 : CRM-748 - Traitement des retours DQE
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_AccountMerge { 
    public Account doublonToMerge {get; set;}
    public String doublonKeyId {get; set;}
    public String typeURL {get; set;}
    public String doublonsId {get; set;}
    public Account account {get; set;}
    public String newAccountJSON {get; set;}
    public String accountObject {get; set;}
    public String comptePlusAncien {get; set;}
    public Boolean personAccount {get; set;}
    public Boolean isCall {get; set;}
    public Boolean isSale {get; set;}
    public String reglesFusionJSONMap {get; set;}
    public String fieldsTypeJSONMap {get; set;}
    //public String accountValueJSONMap {get; set;}
    //public String doublonValueJSONMap {get; set;}
    
    // DQE  
    public String licenceDQE {get; set;}
    public Boolean phoneDQEEnabled {get; set;}
    public Boolean emailDQEEnabled {get; set;}
    public Boolean mergeCustomValueEnabled {get; set;}
    // Champs é afficher sur la page de fusion
    public Account mergeCustom {get; set;}
    public String salutation {get; set;}
    public String accountCallSource {get; set;}
    public String AccountSource {get; set;}
    public String accountCity {get; set;}
    public String accountStreet {get; set;}
    public String canalPrefere {get; set;}
    public String personBirthdate {get; set;}
    public String CSP {get; set;}
    public String NPAI {get; set;}
    public String formeJuridique {get; set;}

    public String accPersonBirthdateReformate {get; set;}
    public String accConjointReformate {get; set;}
    public String accParentIdReformate {get; set;}
    public String doublonPersonBirthdateReformate {get; set;}
    public String doublonConjointReformate {get; set;}
    public String doublonParentIdReformate {get; set;}

    // Champs de type lookup
    public Account accountCustom {get{
        return new Account();
    } set;}
    
    // Picklists a afficher sur la page de fusion
    public List<SelectOption> retrievePicklistValues(Schema.Describefieldresult objectSchema) {
        List<SelectOption> options = new List<SelectOption>();
        List<Schema.PicklistEntry> ple = objectSchema.getSObjectField().getDescribe().getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    public List<SelectOption> getsalutationList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.Salutation;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> getaccountCallSourceList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.accountCallSource__c;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> getAccountSourceList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.AccountSource;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> getcanalPrefereList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.canalPrefere__c;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> getfichierOpposition() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.fichiersOpposition__c;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> getCSPList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.CSP__c;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> getNPAIList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.NPAI__c;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> getformeJuridiqueList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Account.fields.Ownership;
        options = retrievePicklistValues(result);
        return options;
    }

    /**
    * @description Constructeur
    * @param stdController Controleur standard
    * @return Ctrl_AccountMerge Controleur standard
    */
    public Ctrl_AccountMerge(ApexPages.StandardController stdController) {
        // Init 
        doublonKeyId = ApexPages.currentPage().getParameters().get('doublonKeyId');
        typeURL = ApexPages.currentPage().getParameters().get('type');
        doublonsId = ApexPages.currentPage().getParameters().get('doublonsId');
        accountObject = ApexPages.currentPage().getParameters().get('accountObject');
        personAccount = Boolean.valueOf(ApexPages.currentPage().getParameters().get('pAcc'));
        comptePlusAncien = ApexPages.currentPage().getParameters().get('cpt1');
        account = (Account)JSON.deserialize(accountObject, Type.forName('Account'));
        newAccountJSON = String.escapeSingleQuotes(accountObject);
        system.debug('## doublonKeyId : '+doublonKeyId);
        system.debug('## typeURL : '+typeURL);
        system.debug('## accountObject : '+accountObject);
        system.debug('## doublonsId : '+doublonsId);
        System.debug('## personAccount : '+personAccount);

        // Récupération info des enregistrements liés
        Account conj=null;
        Account primAccount=null;
        if(account.conjoint__c != null) conj = [SELECT Id, Name, nom__c FROM Account WHERE Id = :account.conjoint__c LIMIT 1];
        if(account.ParentId != null) primAccount = [SELECT Id, Name FROM Account WHERE Id = :account.ParentId LIMIT 1];

        // Recupere le contexte de l utilisateur courant
        UserContext context = UserContext.getContext();
        // Recupere le role associé
        isCall = context.isCallUser();
        isSale = context.isSaleUser();
        // Rrecupere le profil
        Profile userProfile = context.getProfile();

        system.debug('## context: '+context);
        system.debug('## User Profile Name: '+userProfile.Name);
        system.debug('## isCall: '+isCall);
        system.debug('## isSale: '+isSale);

        // Récupération paramétre global DQE
        licenceDQE = PropertiesUtils.getStringValue('dqe.adresse.licence', '');
        phoneDQEEnabled = PropertiesUtils.getBooleanValue('dqe.quality.phone.enabled', false);
        emailDQEEnabled = PropertiesUtils.getBooleanValue('dqe.quality.email.enabled', false);
        mergeCustomValueEnabled = PropertiesUtils.getBooleanValue('dqe.merge.custom.enabled', false);

        // Récupération information du doublon
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
        String  champsRequete =  'SELECT ';
        for(String field : fieldsMap.keySet()){
            if (field != 'Name') { 
                champsRequete += fieldsMap.get(field) + ', ';
            }
        }
        champsRequete += 'conjoint__r.Name, Parent.Name, ';
        if(!account.IsPersonAccount) champsRequete += 'Name, ';
        champsRequete = champsRequete.substring(0, champsRequete.length()-2);
        champsRequete += ' FROM Account WHERE Id = :doublonKeyId LIMIT 1';
        doublonToMerge = database.query(champsRequete);

        // Reformatage des champs complexes
        if(!String.isEmpty(account.rue__c)) {
            accountStreet = account.rue__c;
        }
        else if(personAccount) accountStreet = account.PersonMailingStreet;
        else accountStreet = account.BillingStreet;

        if(account.PersonBirthdate != null) accPersonBirthdateReformate = dateFormatToString(account.PersonBirthdate);
        if(doublonToMerge.PersonBirthdate != null) doublonPersonBirthdateReformate = dateFormatToString(doublonToMerge.PersonBirthdate);

        if(conj != null) accConjointReformate = conj.Name;
        if(primAccount != null) accParentIdReformate = primAccount.Name;
        if(doublonToMerge.conjoint__c != null) doublonConjointReformate = doublonToMerge.conjoint__r.Name;
        if(doublonToMerge.ParentId != null) doublonParentIdReformate = doublonToMerge.Parent.Name;

        // Récupération des règles de fusion sur chaque métadata
        Map<String, RegleFusion__mdt> reglesFusionMap = new Map<String, RegleFusion__mdt>();
        Map<String, Schema.DisplayType> fieldsTypeMap = new Map<String, Schema.DisplayType>();
        String accountMetadataType = 'Compte B2C';
        if(!personAccount) 
            accountMetadataType = 'Compte B2B';

        // Requête sur les règles de fusion (ATTENTION :  Si boucle sur cette requête, alors aucune condition n'est prise en compte dans la requête)
        List<RegleFusion__mdt> reglesFusionList = new List<RegleFusion__mdt>();
        reglesFusionList = [SELECT Id, object__c, champ__c, regleManuelle__c, profile__c FROM RegleFusion__mdt WHERE object__c = :accountMetadataType];

        // Stockage de la liste des champs ayant une règle de fusion valide
        for(RegleFusion__mdt rf : reglesFusionList){
            if(rf.regleManuelle__c != null && (rf.profile__c == null || 
                                              (rf.profile__c != null && rf.profile__c.containsIgnoreCase(userProfile.Name)) ||
                                              (rf.profile__c != null && context.isCallUser() && rf.profile__c.containsIgnoreCase('isCall')) ||
                                              (rf.profile__c != null && context.isSaleUser() && rf.profile__c.containsIgnoreCase('isSale')) ||
                                              (rf.profile__c != null && context.isSupportUser() && rf.profile__c.containsIgnoreCase('isSupport')) ||
                                              (rf.profile__c != null && context.isChatterUser() && rf.profile__c.containsIgnoreCase('isChatter')))){
                if(fieldsMap.containsKey(rf.champ__c)){
                    reglesFusionMap.put(rf.champ__c, rf);
                    /*accountValueMap.put(rf.champ__c, account.get(rf.champ__c));
                    doublonValueMap.put(rf.champ__c, doublonToMerge.get(rf.champ__c));*/

                    // Stockage du type des champs de fusion valide
                    fieldsTypeMap.put(rf.champ__c, fieldsMap.get(rf.champ__c).getDescribe().getType());
                }
            }
        }
        reglesFusionJSONMap = JSON.serialize(reglesFusionMap); 
        fieldsTypeJSONMap = JSON.serialize(fieldsTypeMap); 

        //accountValueJSONMap = JSON.serialize(accountValueMap); 
        //doublonValueJSONMap = JSON.serialize(doublonValueMap); 
    }

    /**
    * @description  Méthode exécutée lors de l'annulation sur la page de fusion, retour a la page précédente
    * @return PageReference Page Visualforce de la page d'édition ou de détail du compte
    */
    public PageReference cancelMerge(){
        PageReference caP = null;
        // Vérification du paramètres
        /*if(String.isNotBlank(typeURL) && typeURL == 'detail'){
            caP = Page.VF_AccountVueDetails;
        } else if(String.isNotBlank(typeURL) && typeURL == 'edit'){
            caP = Page.VF_AccountEdition;
        } 
        caP.getParameters().put('doublonCheck', doublonsId);
        caP.getParameters().put('accountTemp', accountObject);
        System.debug('accountObject : '+ accountObject);
        */
        return caP;
    }
    
    /**
    * @description REMOTEACTION - Fonction de fusion manuel de l'objet compte
    * Appel de la fonction manualMergeAccount de la classe Utils_Dedoublonnage pour les régles de partage (without sharing)
    * @param accMerged Objet contenant les valeurs saisies par l'utilisateur
    * @param newAcc Compte modifié
    * @param doublonId Id du compte en doublon
    * @param masterId Id du compte maitre sélectionné
    * @param personAccount True si le compte est un compte personnel
    * @return String Id du compte maitre
    */
    @RemoteAction
    public static String manualMerge(Map<String,String> accMerged, String newAcc, String doublonId, String masterId, String personAccount, List<String> fieldlist) {
        try {
            system.debug('### DEBUT manualMerge');
            String accountId = Utils_Dedoublonnage.manualMergeAccount(accMerged, newAcc, doublonId, masterId, personAccount, fieldlist);
            system.debug('### FIN manualMerge');
            return accountId;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Reformatage de date en string
    * @param dateToFormat Date a reformater en string
    * @return String Date
    */
    public String dateFormatToString(Date dateToFormat){
        String stringResult;
        stringResult = (dateToFormat.day() < 10 ? '0' + dateToFormat.day() : dateToFormat.day().format()) +
                 '/' + (dateToFormat.month() < 10 ? '0' + dateToFormat.month() : dateToFormat.month().format()) +
                 '/' + (dateToFormat.year());
        return stringResult;
    }

}