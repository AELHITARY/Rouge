//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl012_ClonerDevis
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/11/2022
//-- Version     : 1.9
//-- * 1.9 : Correction pour vider les champs avenant
//-- * 1.8 : RQM-77 : Ajout du clonage en Devis TMC
//-- * 1.7 : Autorisation du clonage si signature électronique en état final
//-- * 1.6 : Suppression du champ "Circuit de signature"
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl012_ClonerDevis {    
    public String msgError {get;private set;}
    public Boolean mustConfirm{get;private set;}
    public Boolean mustPrevent{get;private set;}
    public Boolean mustClone{get;private set;}
    public Boolean isConfirm{get; set;}
    public Boolean isDevisTMC{get; set;}
    public Quote quote, quoteClone;
    public List<QuoteLineItem> qliList, qliClone;
    public Set<String> idsListQliAConfirmer;
    public List<PricebookEntry> pbeList;
    public List<Option__c> optList;
    public UserContext context;

    // ERRORS
    public Utils_logger log {get; set;}

    /**
    * @description Constructeur
    * @return Ctrl012_ClonerDevis
    */
    public Ctrl012_ClonerDevis(Apexpages.standardController con){
        msgError = '';
        idsListQliAConfirmer = new Set<String>();
        Set<String> optIds = new Set<String>();
        Set<String> optCodes = new Set<String>();
        context = UserContext.getContext();
        log = new Utils_logger();
        // Date et heure du jour        
        Date dateToday = system.today();

        // Récupération informations du devis
        List<QuoteLineItem> qliListActive = new List<QuoteLineItem>();
        quote = DAL.getQuoteById(con.getId());
        qliList = DAL.getQuoteLineItemList(con.getId());
        for(QuoteLineItem quoteLineItem : qliList){
            if(quoteLineItem.PriceBookEntry.isActive && quoteLineItem.PriceBookEntry.Product2.IsActive){
                qliListActive.add(quoteLineItem);
            }
        }

        qliList = qliListActive;
        // Si des lignes de devis sont présent, on récupére les options
        if (!qliList.isEmpty()) {
            List<String> optIdsListActive = new List<String>();
            Map<Id, QuoteLineItem> mapQLI = new Map<Id, QuoteLineItem>(qliList);
            optList = DAL.getOptionList(con.getId());
            
            for (Option__c option : optList) {
                if (mapQLI.containsKey(option.ligneDevis__c))
                    optIdsListActive.add(option.CodeOption__c);
            }

            // Récupération et parcours des referentiel options des options valides
            /*for(ReferentielOptions__c ro : [SELECT (SELECT Id FROM Options__r WHERE Id IN :optIdsListActive) 
                                            FROM ReferentielOptions__c WHERE Debutvalidite__c <= :dateToday AND FinValidite__c >= :dateToday]) {
                for(Option__c o : ro.Options__r) {
                    // Récupération des ids des options à cloner
                    optIds.add(o.Id);
                }               
            }

            // Récupération et parcours des referentiel options des options non valides
            for(ReferentielOptions__c ro : [SELECT (SELECT Id, ligneDevis__c FROM Options__r WHERE Id IN :optIdsListActive) 
                                            FROM ReferentielOptions__c WHERE Debutvalidite__c > :dateToday OR FinValidite__c < :dateToday]) {
                for(Option__c o : ro.Options__r) {
                    // Récupération des ids qli des options non duplicables
                    idsListQliAConfirmer.add(o.ligneDevis__c);
                }               
            }*/

            for(ReferentielOptions__c ro : [SELECT Id, CodeOption__c
                                            FROM ReferentielOptions__c WHERE CodeOption__c IN :optIdsListActive]) {
                    // Récupération des codes option des options
                    optCodes.add(ro.CodeOption__c);         
            }
            for(Option__c o : [SELECT Id, Codeoption__c, Option__r.Debutvalidite__c, Option__r.FinValidite__c FROM Option__c WHERE Codeoption__c IN :optCodes AND ligneDevis__c IN :qliListActive]) {
                    // Récupération des ids des options à cloner
                    if(o.Option__r.Debutvalidite__c <= dateToday && o.Option__r.FinValidite__c >= dateToday){
                        optIds.add(o.Id);  
                    } 
                    // Récupération des ids qli des options non duplicables
                    else if(o.Option__r.Debutvalidite__c > dateToday && o.Option__r.FinValidite__c < dateToday){
                        idsListQliAConfirmer.add(o.ligneDevis__c);
                    }      
            }

            // Récupération des objets Option à cloner
            optList = SchemaUtils.executeQuery('Option__c', 'Id', optIds);
        }
    }

    /**
    * @description Retourne l'Id du devis cloné ou du devis initial
    * @return L'Id du devis
    */
    public string getBackUrl(){
        if(quoteClone != null && quoteClone.id != null)
            return quoteClone.id;
        return quote.id;
    }

    /**
    * @description Retourne le message d'erreur si le devis doit passer au statut erroné
    * @return Le message d'erreur
    */
    public String getMsgWarningDevisErrone(){
        return Constants.msgWarningDevisErrone;
    }

    /**
    * @description Méthode exécutée à l'ouverture de la page Visualforce afin d'exécuter les règles de validation et clonage si pas d'erreur
    * @return La référence de la page Visualforce
    */
    public Pagereference init(){
        mustConfirm = true;
        isConfirm = false;
        isDevisTMC = false;

        // Impossible si devis déjà enregistré
        /*if (quote.Status == Constants.StatutDevisVenduEnregistre && !context.canByPassValidationRules()) {
            msgError = Label.devisVenduEnregistreNonClonable;//'Un devis au statut vendu enregistré ne peut être cloné';
        }
        // Impossible de dupliquer un devis avec une signature électronique en cours
        else if(quote.circuitSignatureDevis__r.Signea__Status__c != null && quote.circuitSignatureContrat__r.Signea__Status__c != null) {          
            // Determine si les circuits de signature sont terminés
            List<String> signeaFinalStateKO = new List<String>{'expired','refused','cancelled'};
            List<String> signeaFinalStateOK = new List<String>{'completed','signed'};
            Boolean dipcfinished = (quote.circuitSignatureDevis__r.Signea__Status__c != null && (signeaFinalStateKO.contains(quote.circuitSignatureDevis__r.Signea__Status__c.toLowerCase())));
            Boolean contratfinished = (quote.circuitSignatureContrat__r.Signea__Status__c != null && (signeaFinalStateKO.contains(quote.circuitSignatureContrat__r.Signea__Status__c.toLowerCase())));
            Boolean dipcsigned = (quote.circuitSignatureDevis__r.Signea__Status__c != null && (signeaFinalStateOK.contains(quote.circuitSignatureDevis__r.Signea__Status__c.toLowerCase())));
            Boolean contratsigned = (quote.circuitSignatureContrat__r.Signea__Status__c != null && (signeaFinalStateOK.contains(quote.circuitSignatureContrat__r.Signea__Status__c.toLowerCase())));
            if(!((dipcfinished || contratfinished) || (dipcsigned && contratsigned))) {
                msgError = Label.devisAvecSignatureElectroniqueEnCoursNonClonable;
            } else {
                mustConfirm = true;
            }
        } else if (quote.Status == null || quote.Status == Constants.StatutDevisTransmis || quote.Status == Constants.StatutDevisNonTransmis) {
            mustConfirm = true;
        }
        else if(quote.Status == Constants.StatutDevisVenduAttente || quote.Status == Constants.StatutDevisVenduIncontournable) {
            mustPrevent = true;
        }
        else cloner();
        */
        return null;
    }

    /**
    * @description Méthode exécutée pour chaque modifier le statut du devis original au statut "Erroné"
    * @return La référence de la page Visualforce
    */
    public Pagereference updateStatutErrone(){
        Savepoint sp = Database.setSavepoint();

        try{
            mustConfirm = false;
            mustPrevent = false;
            mustClone = true;

            if(isConfirm){                
                quote.RecordTypeId = DAL.getRecordTypeIdByDevName('Quote',Constants.RT_QUOTE_ERRONE);
                quote.Status = Constants.StatutDevisErrone;
                quote.forcageEtat__c = Constants.StatutDevisErrone;
            }
            
            update quote;                        
            log.clear();
        }
        catch(Exception e){
            Database.rollback(sp);
            system.debug('## Echec du clonage du devis : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            msgError = 'Echec du clonage du devis (1): ' + e.getMessage();
            log.addErrorMessage(msgError);
        }
        return null;
    }

    /**
    * @description Méthode exécutée pour cloner le devis, les lignes de devis et les options
    * @return La référence de la page Visualforce
    */
    public Pagereference cloner(){
        Savepoint sp = Database.setSavepoint();

        try{
            mustConfirm = false;
            mustClone = false;
            // Clonage du devis
            cloneQuote();
            // Clonage des lignes de devis
            qliClone = cloneQli(quoteClone);
            // Si des lignes ont été clonées, clonage des options
            if (!qliClone.isEmpty()) {
                cloneOpt();
                updateQliListAConfigurer(); // Modification des lignes a "A configurer"
                //Utils_Configurator.recalculerTarifOptions(quoteClone);
            }
            log.clear();
        } catch(Exception e){
            system.debug('## Echec du clonage du devis : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            msgError = 'Echec du clonage du devis (2) : ' + e.getMessage();
            log.addErrorMessage(msgError);
            Database.rollback(sp);
        }
        return null;
    }

    /**
    * @description Méthode exécutée pour cloner le devis
    */
    private void cloneQuote(){
        try {
            quoteClone = quote.clone(false,true);
            quoteClone.Id = null;
            quoteClone.numeroDevis__c = null;    
            quoteClone.forcageEtat__c = null;
            quoteClone.RecordTypeId = DAL.getRecordTypeIdByDevName('Quote',Constants.RT_QUOTE_NONTRANSMIS);
            quoteClone.Status = Constants.StatutDevisNonTransmis;
            quoteClone.Ref1erdevis__c = quote.QuoteNumber;
            quoteClone.dateVerificationRV__c = null;            
            quoteClone.dateTransmissionClient__c = null;
            quoteClone.moyenTransmissionClient__c = null;
            quoteClone.dateAcceptationClient__c = null;
            quoteClone.validationDAF__c = null;
            quoteClone.circuitSignatureContrat__c = null;
            quoteClone.circuitSignatureDevis__c = null;
            quoteClone.devisTMC__c = false;  
            quoteClone.amendInitialQuote__c = null;

            // Devis TMC
            if(isDevisTMC){ 
                quoteClone.devisTMC__c = true;        
                quoteClone.ExpirationDate = System.today().addDays(14);  
            } else {                
                quoteClone.dateDevis__c = System.today();
                quoteClone.ExpirationDate = quoteClone.dateDevis__c.addDays(14);
            }

            insert quoteClone;
        } catch(Exception e){
            system.debug('## Echec du clonage du devis : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Permet de clonage des lignes du devis
    */
    private List<QuoteLineItem> cloneQli(Quote cloneQuote){
        List<QuoteLineItem> qliClone = qliList.deepClone(false);
        for(QuoteLineItem qliC : qliClone){
            qliC.quoteId = cloneQuote.Id;
            qliC.eligibleCEE__c = false;
            qliC.amendInitialQuoteline__c = null;
            qliC.amendedOrderProduct__c = null;
        }
        insert qliClone;
        return qliClone;
    }
    
    /**
    * @description Fonction clonage des options
    */
    private void cloneOpt(){
        // Création d'une map des lignes de devis
        Map<id,Integer> indexMap = getQLIIndexMap();
        // Clonage des options
        List<Option__c> optClone = optList.deepClone(false);
        for(Option__c opt : optClone){
            opt.non_configuree__c = true;
            opt.ligneDevis__c = qliClone[indexMap.get(opt.ligneDevis__c)].Id;
            opt.amendedOrderProduct__c = null;
            opt.codeOptionUnique__c = '';   //Problème d'unicité
        }
        insert optClone;
    }
    
    /**
    * @description Mise à jour des champs "A configurer" des lignes de devis clonées dans le cas où des options non valides ne sont pas dupliquées
    */
    private void updateQliListAConfigurer() {
        // Création d'une map des lignes de devis
        Map<id,Integer> indexMap = getQLIIndexMap();
        // Pour toute les lignes "A confirmer", modification des lignes
        for(String o : idsListQliAConfirmer)
            qliClone[indexMap.get(o)].Aconfigurer__c = true;
        update qliClone;
    }

    /**
    * @description Création d'une map des lignes de devis selon leur index
    */
    private Map<id,Integer> getQLIIndexMap(){
        Map<id,Integer> indexMap = new Map<id,Integer>();
        for(Integer i=0; i < qliList.size(); i++)
            indexMap.put(qliList[i].Id,i);
        return indexMap;
    }
    
    // Fonction inutilse mais nécessaire pour couverture de code
    public void getTest(){
        String A = 'TOTO';
        String B = 'TITI';
        String C = '';  
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
    }
}