//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_ClonerLigneDevis
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 18/11/2022
//-- Version     : 1.2
//-- * 1.2 : Correction pour vider les champs avenant
//-- * 1.1 : Modification pour ligneDevis__c et codeOptionUnique__c
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_ClonerLigneDevis {
    public String msgError {get;private set;}
    private QuoteLineItem quoteLineItem;
    private QuoteLineItem qliClone;
    private List<Option__c> optionList;

    /**
    * @description Constructeur
    * @param con Constructeur standard
    * @return Ctrl_ClonerLigneDevis 
    */
    public Ctrl_ClonerLigneDevis(Apexpages.standardController con){
        msgError = '';

        // Récupération informations de la ligne de devis et des options
        quoteLineItem = DAL.getQuoteLineItemById(con.getId());
        optionList = DAL.getOptionListByqli(quoteLineItem);
    }

    /**
    * @description Fonctione de clonage
    * @return Pagereference Page Visualforce
    */
    public Pagereference cloner(){
        PageReference ref = null;
        Savepoint sp = Database.setSavepoint();

        try{
            // Clonage Ligne de devis
            qliClone = cloneQuoteLineItem();
            cloneOpt(qliClone);
            ref = new Apexpages.standardcontroller(qliClone).view();
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Echec du clonage de la ligne de devis : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            msgError = 'Echec du clonage de la ligne de devis : ' + e.getMessage();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, msgError);
            ApexPages.addmessage(myMsg);
        }
        return ref;
    }

    /**
    * @description Fonction clonage ligne de devis
    * @return QuoteLineItem Ligne de devis clonée
    */
    private QuoteLineItem cloneQuoteLineItem(){
        QuoteLineItem quoteLineItemClone = quoteLineItem.clone(false,true);
        quoteLineItemClone.amendInitialQuoteline__c = null;
        quoteLineItemClone.amendedOrderProduct__c = null;
        upsert quoteLineItemClone;
        return quoteLineItemClone;
    }

    /**
    * @description Fonction clonage des options
    * @param qliClone Ligne de devis clonée
    */
    private void cloneOpt(QuoteLineItem qliClone){
        List<Option__c> optClone = optionList.deepClone(false);
        for(Option__c opt : optClone){
            opt.non_configuree__c = true;
            opt.ligneDevis__c = qliClone.Id;
            opt.codeOptionUnique__c = '';   // Problème d'unicité
            opt.amendedOrderProduct__c = null;
        }
        insert optClone;
    }
}