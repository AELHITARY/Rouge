//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_QuoteCPQClone 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/05/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_QuoteCPQClone {

    /**
    * @description Fonction pour cloner le devis CPQ
    * @param recordId Id du devis
    * @return String Id du nouveau devis
    */
    @AuraEnabled
    public static String cloneQuote(Id recordId) {
        System.debug('### DEBUT LWC_QuoteCPQClone.cloneQuote');
        System.debug('## recordId : '+recordId);
        SBQQ__Quote__c quoteCPQ;
        SBQQ__Quote__c quoteClone;
        List<SBQQ__QuoteLine__c> quoteLinesList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qliListActive = new List<SBQQ__QuoteLine__c>();

        try {
            // Récupération des données
            quoteCPQ = getQuoteInformation(recordId);
            quoteLinesList = getQuoteLinesInformation(recordId);
            // Récupération des lignes dont le produit est actif
            for(SBQQ__QuoteLine__c quoteLineItem : quoteLinesList){
                if(quoteLineItem.SBQQ__Product__r.IsActive){
                    qliListActive.add(quoteLineItem);
                }
            }
            quoteLinesList = qliListActive;

            // Execution procesus de clonage
            quoteClone = processClone(quoteCPQ, quoteLinesList);

            // Modification du statut du devis original
            if (quoteCPQ.SBQQ__Status__c != Constants.QUOTE_STATUS_CANCELLED && quoteCPQ.SBQQ__Status__c != Constants.QUOTE_STATUS_SOLD) {
                String codeRef = PropertiesUtils.getStringValue('ref.motifAnnulationKparK.code', 'RSL-0016');
                List<Referencial__c> refList = [SELECT Id FROM Referencial__c WHERE KparKReference__c = :codeRef LIMIT 1];
                quoteCPQ.dateAnnulation__c = Date.today();
                quoteCPQ.motifAnnulation__c = refList[0].Id;
                update quoteCPQ;
            }
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_QuoteCPQClone.cloneQuote');
        return quoteClone.Id;
    }

    /**
    * @description Fonction pour récupérer les informations du devis 
    * @param quoteCPQ Objet contenant le devis
    * @param quoteLinesList Objet contenant les lignes du devis
    * @return SBQQ__Quote__c Objet contenant les informations du devis cloné
    */
    public static SBQQ__Quote__c processClone(SBQQ__Quote__c quoteCPQ, List<SBQQ__QuoteLine__c> quoteLinesList) {
        System.debug('### DEBUT LWC_QuoteCPQClone.processClone');
        System.debug('## quoteCPQ : '+quoteCPQ);
        System.debug('## quoteLinesList : '+quoteLinesList);
        SBQQ__Quote__c quoteClone;
        List<SBQQ__QuoteLine__c> qliParentList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qliChildList = new List<SBQQ__QuoteLine__c>();
        Map<String, String> qliParentMap = new Map<String, String>();
        Map<String, String> qliParentMap2 = new Map<String, String>();

        Savepoint sp = Database.setSavepoint();

        try {
            // Clonage du devis
            System.debug('## Clonage du devis : '+quoteCPQ.Id);
            quoteClone = quoteCPQ.clone(false,true,false,false);
            quoteClone.Id = null;
            quoteClone.statusFixed__c = null;
            quoteClone.RecordTypeId = quoteCPQ.RecordTypeId;
            quoteClone.SBQQ__Status__c = Constants.QUOTE_STATUS_TO_CONFIGURE;
            quoteClone.SBQQ__Source__c = quoteCPQ.Id;       
            quoteClone.SBQQ__Primary__c = false;          
            quoteClone.amendmentOrderApproved__c = false;    
            quoteClone.generatedDocument__c = false;    
            quoteClone.techPB__c = false;    
            quoteClone.techQLProcessed__c = false;    
            quoteClone.techQLValidated__c = false;    
            quoteClone.techRemVRP__c = false;    
            quoteClone.SBQQ__Ordered__c = false;    
            quoteClone.approvalInProgress__c = false;  
            quoteClone.quoteIsValid__c = false;  
            quoteClone.dateTransmissionClient__c = null;
            quoteClone.moyenTransmissionClient__c = null;
            quoteClone.dateAcceptationClient__c = null;
            quoteClone.circuitSignatureContrat__c = null;
            quoteClone.circuitSignatureDevis__c = null;
            quoteClone.MontantAcompteAttendu__c = null;  
            quoteClone.MontantAcompte2Attendu__c = null;  
            quoteClone.dateDevis__c = Date.today();  
            quoteClone.referenceDate__c = quoteCPQ.dateDevis__c;  
            quoteClone.CreatedDate__c = Date.today();  
            quoteClone.SBQQ__ExpirationDate__c = null;  
            quoteClone.DateValiditeLaPlusProche__c = null;  
            quoteClone.spilledCustomerOrder__c = null;  
            quoteClone.dateAnnulation__c = null;  
            quoteClone.motifAnnulation__c = null;  
            quoteClone.commStatus__c = null;              
            quoteClone.calculationNeeded__c = true;       
            quoteClone.backupMontantTTCCible__c = null;  
            quoteClone.backupRemCompDevise__c = null;  
            quoteClone.backupRemCompPercent__c = 0;             
            quoteClone.backupCustomerAmount__c = 0;
            quoteClone.opportunityTempId__c = null; 
            insert quoteClone;

            // Clonage des lignes de devis parent
            System.debug('## Clonage des lignes parent : '+quoteCPQ.Id);
            for(SBQQ__QuoteLine__c quoteLineItem : quoteLinesList){
                if(quoteLineItem.SBQQ__RequiredBy__c == null){
                    qliParentList.add(quoteLineItem);
                    String key = quoteLineItem.SBQQ__ProductCode__c + quoteLineItem.qleSortOrder__c; // Clé pour retrouver les lignes parents ProductCode + qleSortOrder__c
                    qliParentMap.put(key, quoteLineItem.Id); 
                }
            }
            List<SBQQ__QuoteLine__c> qliParentClone = new List<SBQQ__QuoteLine__c>();
            for(SBQQ__QuoteLine__c qliP : qliParentList){
                SBQQ__QuoteLine__c newQliP = qliP.clone(false,true,false,false);
                newQliP.SBQQ__Quote__c = quoteClone.Id;
                newQliP.SBQQ__Source__c = qliP.Id;
                newQliP.Id = null;
                // Si c'est une ligne configuré par KBMax, alors indiqué que c'est un clone pour éviter génération d'image
                if (newQliP.KBMAXSB__Id__c > 0) {   
                    newQliP.lineCloned__c = true;
                }
                qliParentClone.add(newQliP);
            }
            insert qliParentClone;

            // Récupération de l'ID des nouveau parents pour les devis enfant
            for(SBQQ__QuoteLine__c qli : qliParentClone){
                String key = qli.SBQQ__ProductCode__c + qli.qleSortOrder__c; // Clé pour retrouver les lignes parents ProductCode + qleSortOrder__c
                System.debug('## key : '+key);
                String oldId = qliParentMap.get(key); // Récupération de l'Id de l'ancienne ligne
                System.debug('## oldId : '+qli.SBQQ__ProductCode__c+' / '+oldId);
                System.debug('## newId : '+qli.SBQQ__ProductCode__c+' / '+qli.Id);
                qliParentMap2.put(oldId, qli.Id); // Map avec les lignes
            }

            // Clonage des lignes de devis enfant
            System.debug('## Clonage des lignes enfant : '+quoteCPQ.Id);
            for(SBQQ__QuoteLine__c quoteLineItem : quoteLinesList){
                if(quoteLineItem.SBQQ__RequiredBy__c != null){
                    qliChildList.add(quoteLineItem);
                }
            }
            List<SBQQ__QuoteLine__c> qliChildClone = new List<SBQQ__QuoteLine__c>();
            for(SBQQ__QuoteLine__c qliC : qliChildList){
                SBQQ__QuoteLine__c newQliC = qliC.clone(false,true,false,false);
                newQliC.SBQQ__Quote__c = quoteClone.Id;
                newQliC.SBQQ__Source__c = qliC.Id;
                newQliC.Id = null;
                System.debug('## Parent oldId : '+qliC.SBQQ__RequiredBy__c);
                System.debug('## Parent newId : '+qliParentMap2.get(qliC.SBQQ__RequiredBy__c));
                newQliC.SBQQ__RequiredBy__c = qliParentMap2.get(qliC.SBQQ__RequiredBy__c);
                qliChildClone.add(newQliC);
            }
            insert qliChildClone;
        } catch(Exception e) {
            Database.rollback(sp);
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_QuoteCPQClone.processClone');
        return quoteClone;
    }

    /**
    * @description Fonction pour récupérer les informations du devis 
    * @param recordId Id du devis
    * @return SBQQ__Quote__c Objet contenant les informations du devis 
    */
    public static SBQQ__Quote__c getQuoteInformation(Id recordId) {
        System.debug('### DEBUT LWC_QuoteCPQClone.getQuoteInformation');
        System.debug('## recordId : '+recordId);
        SBQQ__Quote__c quoteCPQ;

        try {
            // Construction SOQL et récupération infos devis
            List<SBQQ__Quote__c> quoteCPQList = (List<SBQQ__Quote__c>) SchemaUtils.executeQuery('SBQQ__Quote__c', recordId);
            if(!quoteCPQList.isEmpty()) {
                quoteCPQ = quoteCPQList[0];
            }
            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('### FIN LWC_QuoteCPQClone.getQuoteInformation');
        return quoteCPQ;
    }

    /**
    * @description Fonction pour récupérer les informations des lignes 
    * @param recordId Id du devis
    * @return List<SBQQ__QuoteLine__c> Objet contenant les informations des lignes
    */
    public static List<SBQQ__QuoteLine__c> getQuoteLinesInformation(Id quoteId) {
        System.debug('### DEBUT LWC_QuoteCPQClone.getQuoteLinesInformation');
        System.debug('## quoteId : '+quoteId);
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

        try {
            // Construction SOQL et récupération infos des lignes
            Map<String, String> relations = new Map<String, String>();
            relations.put('SBQQ__QuoteLine__c.SBQQ__Product__r', 'Product2');   
            quoteLines = (List<SBQQ__QuoteLine__c>) SchemaUtils.executeQuery('SBQQ__QuoteLine__c', 'SBQQ__Quote__c', quoteId, relations);            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('### FIN LWC_QuoteCPQClone.getQuoteLinesInformation');
        return quoteLines;
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