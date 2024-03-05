//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_ChantierMerge
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/01/2018
//-- Version     : 1.2
//-- * 1.2 : RQM-29 - Matrice de dédoublonnage
//-- * 1.1 : Traitement des retours
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_ChantierMerge { 
    public Chantier__c chantier {get;set;}
    public String doublonKeyId {get; set;}
    public String typeURL {get; set;}
    public String doublonsId {get; set;}
    public Map<String, Chantier__c> doublonCheck {get; set;}
    public Chantier__c doublonToMerge {get; set;}
    public String chantierPlusAncien {get; set;}
    public String newChantierJSON {get; set;}
    public String chantierObject {get; set;}
    public String reglesFusionJSONMap {get; set;}
    public String fieldsTypeJSONMap {get; set;}
    
    // DQE  
    public Boolean mergeCustomValueEnabled {get; set;}
    // Champs a afficher sur la page de fusion
    public String typeHabitation{get; set;}
    public String typeResidence {get; set;}
    public Account proprietaire {get; set;}
    public Account autreProprietaire {get; set;}
    public Account locataire {get; set;}
    public Account autreLocataire {get; set;}
    public Account occupant {get; set;}
    public Account autreOccupant {get; set;}
    
    public String chantierProprietaireReformate {get; set;}
    public String chantierAutreProprietaireReformate {get; set;}
    public String chantierLocataireReformate {get; set;}
    public String chantierAutreLocataireReformate {get; set;}
    public String chantierOccupantReformate {get; set;}
    public String chantierAutreOccupantReformate {get; set;}

    public String doublonProprietaireReformate {get; set;}
    public String doublonAutreProprietaireReformate {get; set;}
    public String doublonLocataireReformate {get; set;}
    public String doublonAutreLocataireReformate {get; set;}
    public String doublonOccupantReformate {get; set;}
    public String doublonAutreOccupantReformate {get; set;}

    public Chantier__c chantierCustom {get{
        return new Chantier__c();
    } set;}

    // Picklists a afficher sur la page de fusion
    public List<SelectOption> retrievePicklistValues(Schema.Describefieldresult objectSchema) {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult fieldResult = objectSchema.getSObjectField().getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }
    
    public List<SelectOption> getcaracteristiquesUrbanisme() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Chantier__c.fields.caracteristiquesUrbanisme__c;
        options = retrievePicklistValues(result);
        return options;
    }
    
    public List<SelectOption> getmodesDeChauffe() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Chantier__c.fields.chauffages__c;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> gettypeHabitationList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Chantier__c.fields.typeHabitation__c;
        options = retrievePicklistValues(result);
        return options;
    }
    public List<SelectOption> gettypeResidenceList() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult result = Schema.sObjectType.Chantier__c.fields.typeResidence__c;
        options = retrievePicklistValues(result);
        return options;
    }

    /**
    * @description Constructeur
    * @param stdController Controleur standard
    * @return Ctrl_ChantierMerge Controleur standard
    */
    public Ctrl_ChantierMerge(ApexPages.StandardController stdController) {
        // Init 
        doublonKeyId = ApexPages.currentPage().getParameters().get('doublonKeyId');
        typeURL = ApexPages.currentPage().getParameters().get('type');
        doublonsId = ApexPages.currentPage().getParameters().get('doublonsId');
        chantierObject = ApexPages.currentPage().getParameters().get('chantierObject');
        chantierPlusAncien = ApexPages.currentPage().getParameters().get('cha1');
        system.debug('## doublonKeyId : '+doublonKeyId);
        system.debug('## typeURL : '+typeURL);
        system.debug('## chantierObject : '+chantierObject);
        system.debug('## doublonsId : '+doublonsId);
        chantier = (Chantier__c)JSON.deserialize(chantierObject, Type.forName('Chantier__c'));
        // La deserialization donne un double (type du champ), on cast donc en Integer pour éviter d'affiche "12.0" portes
        chantier.nbPortesEtFenetres__c = (Integer)chantier.nbPortesEtFenetres__c;
        newChantierJSON = String.escapeSingleQuotes(chantierObject);
        
        // Récupération parametre global DQE
        mergeCustomValueEnabled = PropertiesUtils.getBooleanValue('dqe.merge.custom.enabled', false);

        // Recupere le contexte de l utilisateur courant
        UserContext context = UserContext.getContext();
        // Rrecupere le profil
        Profile userProfile = context.getProfile();

        system.debug('## context: '+context);
        system.debug('## User Profile Name: '+userProfile.Name);

        // Requête des champs du doublon
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Chantier__c').getDescribe().fields.getMap();
        String  champsRequete =  'SELECT ';
        for(String field : fieldsMap.keySet()){
            champsRequete += fieldsMap.get(field) + ', ';
        }
        champsRequete += ' proprietaire__r.Name, autreProprietaire__r.Name, locataire__r.Name,';
        champsRequete += ' autreLocataire__r.Name, occupant__r.Name, autreOccupant__r.Name';
        champsRequete += ' FROM Chantier__c WHERE Id = :doublonKeyId LIMIT 1';
        doublonToMerge = database.query(champsRequete);
        
        // Récupération et stockage de la liste des champs ayant une règle de fusion valide
        Map<String, RegleFusion__mdt> reglesFusionMap = new Map<String, RegleFusion__mdt>();
        Map<String, Schema.DisplayType> fieldsTypeMap = new Map<String, Schema.DisplayType>();         
        
        // Requête sur les règles de fusion (ATTENTION :  Si boucle sur cette requête, alors aucune condition n'est prise en compte dans la requête)
        List<RegleFusion__mdt> reglesFusionList = new List<RegleFusion__mdt>();
        reglesFusionList = [SELECT Id, object__c, champ__c, regleManuelle__c, profile__c FROM RegleFusion__mdt WHERE object__c = 'Chantier'];

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

                    // Stockage du type des champs de fusion valide
                    fieldsTypeMap.put(rf.champ__c, fieldsMap.get(rf.champ__c).getDescribe().getType());
                }
            }
        }
        reglesFusionJSONMap = JSON.serialize(reglesFusionMap); 
        fieldsTypeJSONMap = JSON.serialize(fieldsTypeMap);

        // Récupération des comptes du chantier et formatage pour affichage
        List<Id> comptes = new List<Id>();
        comptes.add(chantier.proprietaire__c);
        comptes.add(chantier.autreProprietaire__c);
        comptes.add(chantier.locataire__c);
        comptes.add(chantier.autreLocataire__c);
        comptes.add(chantier.occupant__c);
        comptes.add(chantier.autreOccupant__c);
        Map<Id, String> comptesMap = new Map<Id, String>();
        for(Account cpt : [SELECT Id, Name FROM Account WHERE Id IN :comptes]){
            comptesMap.put(cpt.Id, cpt.Name);
        }
        System.debug('## comptesMap : '+comptesMap);        
        if(chantier.proprietaire__c != null) chantierProprietaireReformate = comptesMap.get(chantier.proprietaire__c);
        if(doublonToMerge.proprietaire__c != null) doublonProprietaireReformate = doublonToMerge.proprietaire__r.Name;
        if(chantier.autreProprietaire__c != null) chantierAutreProprietaireReformate = comptesMap.get(chantier.autreProprietaire__c);
        if(doublonToMerge.autreProprietaire__c != null) doublonAutreProprietaireReformate = doublonToMerge.autreProprietaire__r.Name;
        if(chantier.locataire__c != null) chantierLocataireReformate = comptesMap.get(chantier.locataire__c);
        if(doublonToMerge.locataire__c != null) doublonLocataireReformate = doublonToMerge.locataire__r.Name;
        if(chantier.autreLocataire__c != null) chantierAutreLocataireReformate = comptesMap.get(chantier.autreLocataire__c);
        if(doublonToMerge.autreLocataire__c != null) doublonAutreLocataireReformate = doublonToMerge.autreLocataire__r.Name;
        if(chantier.occupant__c != null) chantierOccupantReformate = comptesMap.get(chantier.occupant__c);
        if(doublonToMerge.occupant__c != null) doublonOccupantReformate = doublonToMerge.occupant__r.Name;
        if(chantier.autreOccupant__c != null) chantierAutreOccupantReformate = comptesMap.get(chantier.autreOccupant__c);
        if(doublonToMerge.autreOccupant__c != null) doublonAutreOccupantReformate = doublonToMerge.autreOccupant__r.Name;
    }

    /**
    * @description  Méthode exécutée lors de l'annulation sur la page de fusion, retour a la page précédente
    * @return PageReference Page Visualforce de la page d'édition ou de détail du chantier
    */
    public PageReference cancelMerge(){
        PageReference caP = null;
        // Vérification du paramétres
        /*if(String.isNotBlank(typeURL) && typeURL == 'detail'){
            caP = Page.VF_ChantierDetails;
        } else if(String.isNotBlank(typeURL) && typeURL == 'edit'){
            caP = Page.VF_ChantierEdit;
        } 
        // Construction URL
        caP.getParameters().put('doublonCheck', doublonsId);
        caP.getParameters().put('chantierTemp', chantierObject);
        */
        return caP;
    }

    /**
    * @description REMOTEACTION - Fonction de fusion manuel de l'objet chantier
    * Appel de la fonction manualMergeChantier de la classe Utils_Dedoublonnage pour les régles de partage (without sharing)
    * @param chaMerged Objet contenant les valeurs saisies par l'utilisateur
    * @param newCha Chantier modifié
    * @param doublonId Id du chantier en doublon
    * @param masterId Id du chantier maitre sélectionné
    * @return String Id du chantier maitre
    */
    @RemoteAction
    public static String manualMerge(Map<String,String> chaMerged, String newCha, String doublonId, String masterId, List<String> fieldlist) {
        try {
            system.debug('### DEBUT manualMerge');
            String chantierId = Utils_Dedoublonnage.manualMergeChantier(chaMerged, newCha, doublonId, masterId, fieldlist);
            system.debug('### FIN manualMerge');
            return chantierId;
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
}