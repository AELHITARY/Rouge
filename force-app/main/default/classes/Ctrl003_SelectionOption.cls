//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl003_SelectionOption
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 04/10/2020
//-- Version     : 1.2
//-- * 1.2 - Corection bug collection size limit
//-- * 1.1 - CRM-473 : Ajout control pour option PARRAINAGE et OPCLI
//-- -------------------------------------------------------------------------------------- --
public without sharing class Ctrl003_SelectionOption {

    public List<Selectoption> versionList {get; set;}
    public List<Selectoption> optionVersionList {get; set;}
    public string versionLibelle{get;set;}
    public string optionVersionLibelle{get;set;}
    public QuoteLineItem qli {get;set;}
    public TreeNode root{get;set;}
    public List<SelectableOption> selectableOptionList{get; set;}
    public Boolean isSearched{get; set;}
    public String incompatibleOptJSON {get{
        return JSON.serialize(getIncompatibilites());
    } set;}

    private Map<string,List<SelectableOption>> optListMap;
    private Map<id, ReferentielOptions__c> refOptMap;
    private Map<id,IncentivePromotion__c> incentiveMap;
    private List<Pack__c> optVersList;
    private List<Pack__c> packList;
    private List<Pack__c> categList;
    private List<Pack__c> optList;
    private List<Option__c> optQuoteLineList; // Options déjà présente de la ligne
    private Id IdRevision;
    private Integer typeRegrOptVers = 3;
    private Integer typeRegrPack = 4;
    private Integer typeRegrCateg = 5;
    private Map<String,TreeNode> categMap;
    private Map<String,Option__c> newOptionMap;

    private Quote quote {get;set;}
    private static String CODE_PARRAINAGE = 'PARRAINAGE';
    private static String CODE_OPCLI = 'OPCLI';

    // ERRORS
    public Utils_logger log {get; set;}

    /**
    * @description Constructeur
    * @param ctrl Context du controleur standard
    */
    public Ctrl003_SelectionOption(Apexpages.Standardcontroller ctrl){
        System.debug('### Ctrl003_SelectionOption');
        log = new Utils_logger();
        String quoteLineItemId;        
        Id recordId = ctrl.getId();
        System.debug('## recordId: '+recordId);

        // Si l'ID est une ligne de devis
        if(recordId != null && recordId.getSobjectType() == QuoteLineItem.getSObjectType()) {
            System.debug('## recordId = quoteLineItemId');
            quoteLineItemId = recordId;
        } else {
            System.debug('## qliId = quoteLineItemId');
            quoteLineItemId = Apexpages.currentPage().getParameters().get('qliId');
        }
        System.debug('## quoteLineItemId: '+quoteLineItemId);

        // Récupération de la ligne de devis actuelle
        if(String.isBlank(quoteLineItemId)) {
            List<Option__c> options = [SELECT Id, ligneDevis__c FROM Option__c WHERE Id =:ctrl.getId() LIMIT 1];
            if(!options.isEmpty()) {
                quoteLineItemId = options[0].ligneDevis__c;
            }
        }
        qli = DAL.getQuoteLineItemById(quoteLineItemId);
        System.debug('## qli: '+qli);

        if(qli != null) {            
            // Récupération du Devis
            quote = DAL.getQuoteById(qli.QuoteId);
            System.debug('## quote: '+quote);

            // Récupération du Pack
            List<Revision_Pack__c> revisionPackList = DAL.getRevisionPackList(qli);
            if(revisionPackList.size()==0){
                log.addErrorMessage(Label.option_erreur_no_revision_pack);
                return;
            } else 
                log.clear();

            IdRevision = revisionPackList[0].Id;
            isSearched = false;
            initVersionList();
            optionVersionList = new List<Selectoption>();
            optionVersionList.add(new Selectoption('','-- Aucun --'));
            // Récupération des options déjà présente pour init version présente puis les supprimer
            optQuoteLineList = DAL.getOptionListByqli(qli);
            setSelectedOptionVersion();
            initOptionMap();
            initAllTree(true);
        } else {
            log.addErrorMessage(Label.option_erreur_no_ligne_devis);
            return;         
        }
    }

    /**
    * @description Initialisation des versions d'option à afficher
    */
    private void setSelectedOptionVersion(){
        if(!optQuoteLineList.isEmpty()){
            List<Pack__c> pListOptVers = DAL.getPackOptionVersion(optQuoteLineList, IdRevision);
            if(!pListOptVers.isEmpty()){
                List<Pack__c> pListVers = DAL.getPackVersion(pListOptVers, IdRevision);
                if(!pListVers.isEmpty()){
                    versionLibelle = pListVers[0].CodePere__r.Libelleoption__c;
                    initOptionVersionList();
                    optionVersionLibelle = pListOptVers[0].codefils__r.Codeoption__c;
                }
            }
        }
    }

    /**
    * @description Initialisation des codes d'option
    */
    private void initOptionMap(){
        newOptionMap = new Map<String,Option__c>();
        for(Option__c o : optQuoteLineList) {
            newOptionMap.put(o.Codeoption__c,o);
        }
        System.debug('## OPTION MAP: '+ newOptionMap);
    }

    /**
    * @description Fonction Sauvegarde (Ajout des options sélectionné)
    * @return PageReference Référence de la page Visualforce
    */
    public PageReference AjouterOPT() {
        // Si pas d'options, on ne fait rien
        if(optListMap == null)
            return null;

        List<Option__c> toDelete = optQuoteLineList; // Liste des options à supprimer
        List<Option__c> toInsert = new List<Option__c>();
        System.debug('## SELECT OPT LIST '+selectableOptionList);
        for(List<SelectableOption> tempList : optListMap.values()){
            for(SelectableOption so : tempList){
                if(so.selected)
                    toInsert.add(so.opt);
            }
        }
        addOptVersToMap();
        Option__c optVers = getOptionVersiontoInsert();
        if(optVers != null)
            toInsert.add(optVers);

        // CRM-473 - WDO - Récupération des options du devis et gestion erreur
        List<Option__c> quoteOptionsList = [SELECT Id, codeoption__c, option__r.OptionPromotionnelle__c, option__r.typePromotion__r.name
                                            FROM Option__c o
                                            WHERE ligneDevis__r.quoteId = :quote.Id AND Id NOT IN :toDelete];
        for(Option__c optionsQLI : toInsert){
            // if(optionsQLI.codeoption__c.containsIgnoreCase(CODE_OPCLI))
            //     presenceOptionCliente = true;
            for(Option__c quoteOptions : quoteOptionsList) {
                // Calcul le nombre d'option cliente
                // if(quoteOptions.codeoption__c.containsIgnoreCase(CODE_OPCLI))
                //     nbOptionCliente++;
                // ERREUR : Si la ligne contient PARRAINAGE et qu'une autre ligne de devis du même devis contient une option PARRAINAGE ou OPCLIxxx ou OP Market
                if(optionsQLI.codeoption__c == CODE_PARRAINAGE &&
                    (quoteOptions.codeoption__c == CODE_PARRAINAGE || quoteOptions.codeoption__c.containsIgnoreCase(CODE_OPCLI) || Utils_Configurator.isOPMarket(quoteOptions))) {
                    log.addErrorMessage(Label.option_erreur_choix_parrainage);
                    return null;
                } else
                    log.clear();
                // ERREUR : Si la ligne contient l'option OPCLI et qu'une autre ligne de devis du même devis contient une option PARRAINAGE ou OP Market
                if(optionsQLI.codeoption__c.containsIgnoreCase(CODE_OPCLI) &&
                    /* >>> F.G., le 27/06/2014
                    (quoteOptions.codeoption__c == CODE_PARRAINAGE || (!optionsQLI.codeoption__c.equalsIgnoreCase(quoteOptions.codeoption__c) && Utils_Configurator.isOPMarket(quoteOptions)))) {
                       --- F.G., le 27/06/2014 */
                    (quoteOptions.codeoption__c == CODE_PARRAINAGE)) {   
                    /* <<< F.G., le 27/06/2014 */  
                    log.addErrorMessage(System.Label.option_erreur_choix_opcli);
                    return null;
                } else
                    log.clear();
            }
        }

        try{
            // Modification des options
            delete toDelete;
            upsert toInsert;
            
            // Mise à jour des prix
            changeQuoteLIPrice(toInsert);
            TR022_Quote.setBonusAndRemises(new List<Quote>{quote}); 
        } catch(Exception err){
            System.debug('ERREUR # Ctrl003_SelectionOption : AjouterOPT (' + err + ') Ligne : ' + String.valueOf(err.getLineNumber()) + ' !');
            log.addErrorMessage(err.getMessage());
            return null;
        }

        return Annuler();
    }

    /**
    * @description Modification du prix du devis selon les nouvelles options
    * @param optListNew Liste des nouveaux options ajoutées à la ligne
    */
    private void changeQuoteLIPrice(List<Option__c> optListNew){
        optListNew = DAL.getOptionList(optListNew);
        Decimal price = 0;
        Decimal remiseEnseigne = 0;
        List<Option__c> optRefPromoList = new List<Option__c>();

        // Pour chaque options, on vérifie si elles sont des promotions, on calcul le prix et on ajoute dans une liste
        for(Option__c o : optListNew) {
            if(Utils_Configurator.isReferencePromotion(o.option__r))
                optRefPromoList.add(o);
            else if((o.PrixHT__c != null) && (Utils_Configurator.isRemiseEnseigne(o)) != true)
                price += o.PrixHT__c;
        }

        // Mise à jour du prix des options si promotion
        if(qli.PrixunitaireHTtarifoptions__c == null)
            qli.PrixunitaireHTtarifoptions__c = 0;
        if(qli.unitprice == null)
            qli.unitprice = 0;
        Decimal totalPrice = price + qli.unitprice;
        for (Option__c o : optRefPromoList) {
            o.PrixunitaireHT__c = o.Valorisation__c / 100 * totalPrice;
        }
        update optRefPromoList;

        // Calcul de la remise
        optListNew = DAL.getOptionList(optListNew);
        for(Option__c o : optListNew){
            if(Utils_Configurator.isRemiseEnseigne(o)) {
                remiseEnseigne = (remiseEnseigne + ((o.PrixHT__c * qli.Quantity) * (1 + (qli.tvaPourcentage__c / 100)))).setScale(2);
            }
        }

        // Mise à jour de la ligne de devis
        qli.Aconfigurer__c = false;
        qli.PrixunitaireHTtarifoptions__c = price;
        qli.remise_enseigne__c = remiseEnseigne;
        qli.Version__c = versionLibelle;
        update qli;
    }

    /**
    * @description Construit l'option de version (parent) de la ligne de devis
    * @return Option__c L'option parent
    */
    private Option__c getOptionVersiontoInsert(){
        Pack__c optVers = getOptionVersion();
        if(optVers == null)
            return null;
        Option__c opt = new Option__c();
        opt.LibelleOption__c = optVers.CodeFils__r.LibelleOption__c;
        opt.ligneDevis__c = qli.Id;
        opt.Codeoption__c = optVers.CodeFils__r.codeOption__c;
        opt.Option__c = optVers.CodeFils__c;
        opt.Option_de_Version__c = true;
        opt.Pack__c = versionLibelle;
        ReferentielOptions__c refOpt = refOptMap.get(optVers.codeFils__c);
        if(refOpt.Tarifs_Option__r.size() > 0 )
            opt.valorisation__c = refOpt.Tarifs_Option__r[0].Valorisationdeloption__c;
        opt.Quantite__c = 1;
        return opt;
    }

    /**
    * @description Fonction Annulation (retour page précédente)
    * @return PageReference Référence de la page Visualforce
    */
    public Pagereference Annuler(){
        Pagereference p = null;
        string retURL = Apexpages.currentPage().getParameters().get('retURL');
        if(retURL != null)
            p = new Pagereference(retURL);
        else {
            p = new PageReference('/'+qli.id);
        }
        p.setRedirect(true);
        return p;
    }

    /**
    * @description Fonction pour récupérer toutes les options disponible pour la ligne de devis
    */
    private void initAllOptions(){
        refOptMap = getTarifOption();
        initIncentives();
        optListMap = new Map<string,List<SelectableOption>>();
        for(String categName : categMap.keySet()){
            optListMap.put(categName, initOneCategory(categName,refOptMap));
        }
    }

    /**
    * @description Fonction pour construire une option selon la référence de l'option et le pack
    * @param refOpt Référence de l'option
    * @param p Pack de l'option
    * @param packName Nom du pack de l'option
    * @return Option__c Option selon la référence et le pack
    */
    private Option__c initOneOption(ReferentielOptions__c refOpt, Pack__c p, String packName){
        if(refOpt == null || !Utils_Configurator.afficherOption(quote, refOpt, qli))
            return null;
        Decimal valorisation = Utils_Configurator.getValorisation(quote, refOpt, incentiveMap);//getValorisation(refOpt);
        System.debug('## REF OPT A AFFICHER Valorisation : '+refOpt.CodeOption__c+' '+valorisation);
        if(valorisation == null && refOpt.OptionPromotionnelle__c && refOpt.CodeOption__c != Constants.EcoPrime){
            System.debug('## REF OPT A AFFICHER FALSE : '+refOpt.CodeOption__c+' '+valorisation);
            return null;
        }
        Option__c opt = newOptionMap.get(p.CodeFils__r.codeOption__c);
        if(opt != null){
            Option__c optClone = opt.clone(false, true);
            optClone.non_configuree__c = false;
            return optClone;
        }
        opt = new Option__c();
        opt.non_configuree__c = false;
        opt.LibelleOption__c = p.CodeFils__r.LibelleOption__c;
        opt.ligneDevis__c = qli.Id;
        opt.Quantite__c = 0;
        opt.Categorie__c = p.codepere__r.LibelleOption__c;
        opt.Pack__c = packName;
        opt.Codeoption__c = p.CodeFils__r.codeOption__c;
        opt.Option__c = p.CodeFils__c;
        opt.valorisation__c = valorisation;
        if(p.FilsAutoselectionnable__c && newOptionMap.size() == 0)
            opt.Quantite__c = 1;
        return opt;
    }

    /**
    * @description Fonction pour initialiser les incentives du devis
    */
    private void initIncentives(){
        Quote q = DAL.getQuoteById(qli.quoteId);
        incentiveMap = Utils_Configurator.initIncentives(q,refOptMap);
    }

    /**
    * @description Fonction pour initialiser la liste des catégories des options
    * @param categName Nom de la catégorie parent
    * @param refOptMap Map des références des options
    * @return List<SelectableOption> Liste des catégories des options
    */
    private List<SelectableOption> initOneCategory(String categName, Map<Id, ReferentielOptions__c> refOptMap){
        TreeNode categ = categMap.get(categName);
        List<SelectableOption> toReturn = new List<SelectableOption>();
        for(TreeNode node : categ.FileList){
            Pack__c p = node.pack;
            ReferentielOptions__c refOpt = refOptMap.get(p.codeFils__c);
            Option__c opt = initOneOption(refOpt, p, categ.pack.codepere__r.LibelleOption__c);
            if(opt != null){
                SelectableOption so = new SelectableOption(opt,(opt.Quantite__c > 0), p);
                toReturn.add(so);
            }
        }
        return toReturn;
    }

    private void initSelectOption(){
        selectableOptionList = new List<SelectableOption>();
        for(List<SelectableOption> tempList : optListMap.values()){
                selectableOptionList.addAll(tempList);
        }
    }

    private void initVersionList(){
        versionList = new List<Selectoption>();
        List<Pack__c> rootList = DAL.getPackVersionList(IdRevision);
        versionList.add(new Selectoption('','--Aucun--'));
        for(Pack__c p : rootList){
            versionList.add(new Selectoption(p.CodeFils__r.LibelleOption__c,p.CodeFils__r.LibelleOption__c));
        }
    }

    private void initPackList(){
        if(versionLibelle==null || versionLibelle==''){
            packList = new List<Pack__c>();
            return;
        }
        packList = DAL.getPackList(versionLibelle, IdRevision);
        System.debug('## LIST PACK : ' + packList.size());
    }

    public Pagereference initOptionVersionList(){
        System.debug('## INIT PACKLIST');
        initPackList();
        Set<id> optVersionIds = new Set<id>();
        for(Pack__c p : packList){
            optVersionIds.add(p.CodeFils__c);
        }
        optVersList = DAL.getOptionVersionList(optVersionIds, IdRevision);
        optionVersionList = new List<Selectoption>();
        optionVersionList.add(new Selectoption('','--Aucun--'));
        for(Pack__c p : optVersList)
            optionVersionList.add(new Selectoption(p.CodeFils__r.CodeOption__c,p.CodeFils__r.LibelleOption__c));
        System.debug('## INITIATION TREE');
        initTree();
        return null;
    }

    private void initCategList(){
        Set<id> PackIds = new Set<id>();
        for(Pack__c p : packList)
            packIds.add(p.CodeFils__c);
        categList = DAL.getCategList(packIds, IdRevision);
    }

    private void initOptList(){
        Set<id> categIds = new Set<id>();
        for(Pack__c p : categList)
            categIds.add(p.CodeFils__c);
        optList = DAL.getOptionSelectList(categIds, IdRevision);
    }


    public List<Incompatibilit_Options__c> getIncompatibilites(){
        List<Pack__c> optionInc = optList;
        if(optVersList != null)
            optionInc.addAll(optVersList);
        List<Incompatibilit_Options__c> incompList = DAL.getIncompatibilitesOptions(optionInc);
        return incompList;
    }
    
    private Set<String> getOptionVersionSet(){
        Set<string> optVerSet = new set<string>();
        for(Pack__c p : optVersList){
            optVerSet.add(p.codePere__c);
        }
        return optVerSet;
    }

    // Construction et affichage des PACK, CATEGORIE et OPTIONS
    //-----------------------------------------------------------
    public Pagereference initAllTree(boolean firstCall){
        System.debug('## VERSION LIBELLE : '+versionLibelle);
        if(versionLibelle == null || versionLibelle == '')//|| optionVersionLibelle == null || optionVersionLibelle == ''
            return null;
        if(!firstCall)
            newOptionMap = new Map<String,Option__c>();

        // Récupération des pack, catégories et des options
        initCategList();
        initOptList();
        root = new TreeNode('ROOT', true);
        Map<String,TreeNode> packMap = new Map<String,TreeNode>();

        // Affichage des pack selon la révision
        Set<string> optVerSet = getOptionVersionSet();
        for(Pack__c p : packList){
            if(!optVerSet.contains(p.CodeFils__c)){
                TreeNode packNode = root.addFolder(p.CodeFils__r.LibelleOption__c);
                packMap.put(p.CodeFils__r.LibelleOption__c, packNode);
            }
        }

        // Affichage des catégories
        categMap = new Map<String,TreeNode>();
        for(Pack__c p : categList){
            TreeNode packNode = packMap.get(p.CodePere__r.LibelleOption__c);
            TreeNode categNode = packNode.addFolder(p.CodeFils__r.LibelleOption__c);
            categNode.setPack(p);
            categNode.classOpt = p.codeFils__r.codeOption__c;
            categMap.put(p.CodeFils__r.codeOption__c, categNode);
        }

        // Affichage des options
        Map<String,TreeNode> optMap = new Map<String,TreeNode>();
        for(Pack__c p : optList) {
            // CRM-473 - WDO - Affichage de l'option Parrainage ssi origine devis = PARRAINAGE
            // Affichage option OPTCLI ssi origine devis != PARRAINAGE
            Boolean afficheOption = true;
            String source = quote.source__c == null ? '' : quote.source__c;
            String callSource = quote.callSource__c == null ? '' : quote.callSource__c;
            if(p.CodeFils__r.Codeoption__c == CODE_PARRAINAGE && !(source.containsIgnoreCase(CODE_PARRAINAGE) || callSource.containsIgnoreCase(CODE_PARRAINAGE))) {
                afficheOption = false;
            } 
            /* >>> F.G., le 03/06/14 - le filleul est éligible à la meilleure des deux promotions (remise parrainage ou promo en cours). 
            else if (p.CodeFils__r.Codeoption__c.containsIgnoreCase(CODE_OPCLI) && (source.containsIgnoreCase(CODE_PARRAINAGE) || callSource.containsIgnoreCase(CODE_PARRAINAGE))) {
                afficheOption = false;
            }
            <<< F.G., le 03/06/14 */

            if(afficheOption) {
                TreeNode categNode = categMap.get(p.CodePere__r.codeOption__c);
                TreeNode optNode = categNode.addFolder(p.CodeFils__r.LibelleOption__c);
                optNode.setPack(p);
                optMap.put(p.CodeFils__r.LibelleOption__c, optNode);
            }
            // CRM-473 - WDO
        }
        System.debug('## SEARCHED IS DONE');
        isSearched = true;
        initAllOptions();
        initSelectOption();
        return null;
    }

    public Pagereference initTree(){
        System.debug('## INITIATION TREE INSIDE');
        return initAllTree(false);
    }

    private Pack__c getOptionVersion(){
        for(Pack__c p : optVersList){
            if(p.CodeFils__r.CodeOption__c == optionVersionLibelle)
                return p;
        }
        return null;
    }

    private Map<id,ReferentielOptions__c> getTarifOption(){
        Set<string> idOptSet = DAL.makeSet(optList, 'codeFils__c');
        return DAL.getRefOptMap(qli, idOptSet);
    }

    private void addOptVersToMap(){
        set<string> idOptSet = new set<string>();
        Pack__c optVers = getOptionVersion();
        if(optVers != null)
            idOptSet.add(optVers.codeFils__c);
        Map<id,ReferentielOptions__c> refVersOpt = DAL.getRefOptMap(qli, idOptSet);
        refOptMap.putAll(refVersOpt);
    }

    /********************************************************************************/
    /********************** SOUS CLASSES ********************************************/
    /********************************************************************************/
    public with sharing class TreeNode {
        public String NameFile{get;set;}
        public Pack__c pack;
        public List<TreeNode> FileList{get;set;}
        public boolean isFolder{get;set;}
        public string classOpt{get; set;}

        public TreeNode(string newName,boolean isFolderNode){
            NameFile = newName;
            FileList = new List<TreeNode>();
            isFolder = isFolderNode;
        }

        public TreeNode addFolder(string newName){
            TreeNode nodeObj = new TreeNode(newName, true);
            FileList.add(nodeObj);
            return nodeObj;
        }

        public void addFile(string newName){
            TreeNode nodeObj = new TreeNode(newName, false);
            FileList.add(nodeObj);
        }

        public void setPack(Pack__c myPack){
            pack = myPack;
        }

        public string getClass(){
            if(isFolder)
                return 'folder';
            return 'file';
        }

        public boolean getIsCollapsible(){
            return (FileList.size() > 0 || isFolder);
        }
    }

    public class SelectableOption{
        public Option__c opt{get;set;}
        public Pack__c pack{get; private set;}
        public Boolean selected{get;set;}

        public selectableOption(Option__c myOpt, Boolean isSelected,Pack__c myPack){
            opt = myOpt;
            selected = isSelected;
            pack = myPack;
        }

        public boolean getIsRadio(){
            return (pack.Mode_de_Selection__c == 1);
        }

        public String getClassName(){
            return pack.codePere__r.codeoption__c;
        }

        public String getCodeOpt(){
            return pack.codefils__r.codeoption__c;
        }

        public boolean getIsEditable(){
            return (pack.codeFils__r.LibelleModifiable__c || pack.codeFils__r.Valorisationmodifiable__c || pack.codeFils__r.Quantitemodifiable__c);
        }

        public boolean getIsSubstituable(){
            return pack.FilsSubstituable__c;
        }
    }

    public string getLoseModif(){
        return Constants.msgLoseModifications;
    }

    public string getChooseOpt(){
        return Constants.msgChooseOpt;
    }

    public string getChooseVersion(){
        return Constants.msgChooseVersion;
    }

    public string getIncompatibleOpt(){
        return Constants.msgIncompatibleOpt;
    }

    public string getIncompatibleOptVers(){
        return Constants.msgIncompatibleOptVers;
    }
}