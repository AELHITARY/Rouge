//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_OrderAmendmentQuote
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 12/04/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_OrderAmendmentQuote {
    private static final Integer DELAIEXPIRATION = PropertiesUtils.getIntegerValue('maintenance.devis.delaiExpiration', 14);

    /**
    * @description Fonction pour vérifier la présence de ligne de devis sur les lignes de commande
    * @param orderId Id de la commande client initial
    * @return Boolean Vrai si pas de ligne de devis
    */
    @AuraEnabled
    public static Boolean checkOrderItems(Id orderId) {
        System.debug('### DEBUT LWC_OrderAmendmentQuote.checkOrderItems');
        System.debug('## orderId : '+orderId);
        Boolean ordItemWithoutQLI = false;

        try {
            // Affichage erreur si les lignes de commandes sont sans ligne de devis
            List<OrderItem> ordItemList = [SELECT Id, QuoteLineItemId, quoteOption__c 
                                            FROM OrderItem WHERE OrderId = :orderId 
                                            AND parentOrderItem__c = null
                                            AND status__c != :Constants.ORDERITEM_STATUS_CANCELLED];
            for(OrderItem ordItem : ordItemList) {
                if(String.isBlank(ordItem.QuoteLineItemId)) {
                    ordItemWithoutQLI = true;
                }
            }
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_OrderAmendmentQuote.checkOrderItems');
        return ordItemWithoutQLI;
    }

    /**
    * @description Fonction pour créer un devis "Sales" avenant
    * @param orderId Id de la commande client initial
    * @param quoteName Nom du devis avenant
    * @return String Id du devis avenant
    */
    @AuraEnabled
    public static String createQuoteAmendment(Id orderId, String quoteName) {
        System.debug('### DEBUT LWC_OrderAmendmentQuote.createQuoteAmendment');
        System.debug('## orderId : '+orderId);
        System.debug('## quoteName : '+quoteName);
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        List<Option__c> optList = new List<Option__c>();
        Quote quoteAmend = null;

        // Sauvegarde en cas d'erreur
        System.Savepoint sp = Database.setSavepoint();

        try {
            // Récupération infos commande
            Order ordPrimary = [SELECT Id, QuoteId, Quote.amendInitialQuote__c, chantier__r.codeMagasinActuel__c FROM Order WHERE Id = :orderId];

            // Récupération infos devis
            Quote quotePrimary = DAL.getQuoteById(ordPrimary.QuoteId);
            qliList = DAL.getQuoteLineItemList(ordPrimary.QuoteId);
            // Si des lignes de devis sont présentes, on récupére les options
            if (!qliList.isEmpty()) {
                optList = DAL.getOptionList(ordPrimary.QuoteId);
            }

            // Récupération des devis avenant précédent
            /*
            for(Quote prevQuote : [SELECT Id FROM Quote 
                                    WHERE customerOrder__c = :orderId AND amendmentQuote__c = true AND Status LIKE 'Vendu%' 
                                    ORDER BY dateAcceptationClient__c DESC LIMIT 1]) {
                previousQuoteId = prevQuote.Id;
            }
            */

            // Récupération manager si vendeur inactif sinon vendeur du devis précédent
            String newOwnerId = quotePrimary.OwnerId;
            User usr = [SELECT Id, IsActive FROM User WHERE Id = :quotePrimary.OwnerId LIMIT 1];
            if(!usr.IsActive) {                
                // Récupération manager du magasin 
                User manager = TerritoryUtils.getManager(ordPrimary.chantier__r.codeMagasinActuel__c);
                if(manager != null && manager.IsActive) {
                    newOwnerId = manager.Id;
                }
            }

            // A - Clone du devis 
            quoteAmend = quotePrimary.clone(false,true);
            quoteAmend.customerOrder__c = ordPrimary.Id;
            quoteAmend.spilledCustomerOrder__c = null;
            quoteAmend.Id = null;
            quoteAmend.numeroDevis__c = null;    
            quoteAmend.forcageEtat__c = null;
            quoteAmend.RecordTypeId = DAL.getRecordTypeIdByDevName('Quote',Constants.RT_QUOTE_NONTRANSMIS);
            quoteAmend.Status = Constants.StatutDevisNonTransmis;
            quoteAmend.Ref1erdevis__c = quotePrimary.QuoteNumber;
            quoteAmend.dateVerificationRV__c = null;            
            quoteAmend.dateTransmissionClient__c = null;
            quoteAmend.moyenTransmissionClient__c = null;
            quoteAmend.dateAcceptationClient__c = null;
            quoteAmend.validationDAF__c = null;
            quoteAmend.circuitSignatureContrat__c = null;
            quoteAmend.circuitSignatureDevis__c = null;
            quoteAmend.devisTMC__c = false;  
            quoteAmend.OwnerId = newOwnerId;  

            // Mise a jour des champs
            quoteAmend.Name = quoteName;
            quoteAmend.amendInitialQuote__c = String.isNotBlank(ordPrimary.Quote.amendInitialQuote__c) ? ordPrimary.Quote.amendInitialQuote__c : ordPrimary.QuoteId;
            quoteAmend.previousQuote__c = ordPrimary.QuoteId;
            /*
            quoteAmend.amendInitialQuote__c = ordPrimary.QuoteId;
            quoteAmend.previousQuote__c = String.isNotBlank(previousQuoteId) ? previousQuoteId : ordPrimary.QuoteId;
            */
            quoteAmend.dateDevis__c = Date.today();
            quoteAmend.ExpirationDate = quoteAmend.dateDevis__c.addDays(DELAIEXPIRATION);
            
            // Mise à jour date de référence par rapport devis initial
            Quote quoteInitial = [SELECT Id, customerOrder__c, referenceDate__c, QuoteNumber FROM Quote WHERE Id = :quoteAmend.amendInitialQuote__c LIMIT 1];
            quoteAmend.referenceDate__c = quoteInitial.referenceDate__c;
            quoteAmend.Ref1erdevis__c = quoteInitial.QuoteNumber;
            //quoteAmend.customerOrder__c = quoteInitial.customerOrder__c;

            insert quoteAmend;
            System.debug('## Quote Amend : '+quoteAmend);            

            // B - Récupération des lignes de commandes liés aux lignes de devis et options
            Map<String, String> ordItemsQLIMap = new Map<String, String>();
            for(OrderItem oli : [SELECT Id, QuoteLineItemId, quoteOption__c FROM OrderItem 
                                    WHERE QuoteLineItemId IN :qliList AND OrderId = :ordPrimary.Id]) {
                if(String.isBlank(oli.quoteOption__c)) {
                    ordItemsQLIMap.put(oli.QuoteLineItemId, oli.Id);
                } else {
                    ordItemsQLIMap.put(oli.quoteOption__c, oli.Id);
                }
            }

            // C - Clonage des lignes de devis
            List<QuoteLineItem> qliClone = qliList.deepClone(false);
            for(QuoteLineItem qliC : qliClone){
                qliC.quoteId = quoteAmend.Id;
            }
            insert qliClone;
            System.debug('## QLI : '+qliClone);

            // D - Si des lignes ont été clonées, clonage des options
            if (!qliClone.isEmpty()) {
                // Création d'une map des lignes de devis
                Map<id,Integer> qliIndexMap = new Map<id,Integer>();
                for(Integer i=0; i < qliList.size(); i++) {
                    qliIndexMap.put(qliList[i].Id,i);
                }
                // Création d'une map des options
                Map<id,Integer> optIndexMap = new Map<id,Integer>();
                for(Integer i=0; i < optList.size(); i++) {
                    optIndexMap.put(optList[i].Id,i);
                }
                // Clonage des options
                List<Option__c> optClone = optList.deepClone(false);
                for(Option__c opt : optClone){
                    opt.non_configuree__c = false;
                    opt.ligneDevis__c = qliClone[qliIndexMap.get(opt.ligneDevis__c)].Id;
                    opt.codeOptionUnique__c = '';   //Problème d'unicité
                }
                insert optClone;
                System.debug('## Options : '+optClone);
                // Pour toute les lignes, modification des lignes
                for(QuoteLineItem qli : qliList) {
                    qliClone[qliIndexMap.get(qli.Id)].Aconfigurer__c = false;
                    //qliClone[qliIndexMap.get(qli.Id)].amendedOrderProduct__c = ordItemsQLIMap.get(qli.Id);
                    if (String.isBlank(qliClone[qliIndexMap.get(qli.Id)].amendedOrderProduct__c)) {
                        qliClone[qliIndexMap.get(qli.Id)].amendedOrderProduct__c = ordItemsQLIMap.get(qli.Id);
                    }
                    //qliClone[qliIndexMap.get(qli.Id)].amendInitialQuoteline__c = qli.Id;
                    if (String.isBlank(qliClone[qliIndexMap.get(qli.Id)].amendInitialQuoteline__c)) {
                        qliClone[qliIndexMap.get(qli.Id)].amendInitialQuoteline__c = qli.Id;
                    }
                }
                update qliClone;
                // Pour toute les options, modification des options
                for(Option__c opt : optList) {
                    //optClone[optIndexMap.get(opt.Id)].amendedOrderProduct__c = ordItemsQLIMap.get(opt.Id);
                    if (String.isBlank(optClone[optIndexMap.get(opt.Id)].amendedOrderProduct__c)) {
                        optClone[optIndexMap.get(opt.Id)].amendedOrderProduct__c = ordItemsQLIMap.get(opt.Id);
                    }
                }
                update optClone;
            }
        } catch(Exception e) {
            Database.rollback(sp);
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN createQuoteAmendment.createQuoteAmendment');
        return quoteAmend.Id;
    }
    
    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}