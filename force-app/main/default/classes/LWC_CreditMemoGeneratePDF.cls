//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CreditMemoGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/01/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CreditMemoGeneratePDF {
    public static final String TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.creditmemo.templateId', '');

    /**
    * @description Fonction pour afficher le PDF si existant
    * @param recordId Id de la facture
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String searchExistingDocumentPDF(Id recordId) {
        System.debug('### DEBUT LWC_CreditMemoGeneratePDF.searchExistingDocumentPDF');
        System.debug('## recordId : '+recordId);
        String result;

        try {
            // Search existing document
            List<ContentDocumentLink> ctLinkList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            if(!ctLinkList.isEmpty()) {
                result = ctLinkList[0].ContentDocumentId;
            }       
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_CreditMemoGeneratePDF.searchExistingDocumentPDF');
        return result;
    }
    
    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure et lier le document à l'enregistrement
    * @param recordId Id de l'avoir
    * @param filename Nom de la pièce jointe
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String renderDocumentPDF(Id recordId, String filename) {
        System.debug('### DEBUT LWC_CreditMemoGeneratePDF.renderDocumentPDF');
        System.debug('## recordId : '+recordId);
        creditMemoObject data;
        String result;

        try {
            // Get and construct creditMemo Object
            data = getCreditMemoInformation(recordId);
            // Call Merkure API to render the document
            Blob documentBlob = Utils_APIMerkure.renderDocumentPDF(TEMPLATE_ID, data);
            // Link the document to the record
            result = linkDocumentToRecord(recordId, filename, documentBlob);              
            
            //** START - ONLY FOR DEBUG 
            /*Utils_APIMerkure.RenderDocumentRequest payload = new Utils_APIMerkure.RenderDocumentRequest();
            payload.templateId = TEMPLATE_ID;
            payload.data = data;
            String payloadString = JSON.serialize(payload);
            Document d = new Document(Name = 'Avoir_JSON', 
                                        Body = Blob.valueOf(payloadString),
                                        Description = recordId,
                                        ContentType = 'text/plain',
                                        FolderId = '00lD0000001ygqO',
                                        Type = 'txt');
            insert d;*/
            //** END - ONLY FOR DEBUG 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_CreditMemoGeneratePDF.renderDocumentPDF');
        return result;
    }

    /**
    * @description Fonction pour modifier le statut de l'avoir à "Générer" une fois le PDF associé
    * @param recordId Id de l'avoir
    */
    @AuraEnabled
    public static String changeStatusOfcreditMemo(Id recordId) {
        System.debug('### DEBUT LWC_CreditMemoGeneratePDF.changeStatusOfcreditMemo');
        System.debug('## recordId : '+recordId);
        String result;

        try {
            // Check if date exists, dont update if date exists
            CreditMemo__c credMemo = [SELECT Id, creditMemoDate__c FROM CreditMemo__c WHERE Id = :recordId LIMIT 1];
            // Update creditMemo
            if(credMemo.creditMemoDate__c == null) {
                credMemo.creditMemoDate__c = Date.today();
                update credMemo;
            }
            result = 'OK';            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_CreditMemoGeneratePDF.changeStatusOfcreditMemo');
        return result;
    }

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF à l'avoir en tant que Salesforce File (ContentDocument)
    * @param recordId Id de l'avoir
    * @param docName Nom de la pièce jointe
    * @param document Binaire du document
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String linkDocumentToRecord(Id recordId, String docName, Blob document) {
        System.debug('### DEBUT LWC_CreditMemoGeneratePDF.linkDocumentToRecord');
        System.debug('## recordId : '+recordId);
        System.debug('## docName : '+docName);
        String result;

        try {
            // Link the document link a content document
            String filename = docName + '.pdf';
            result = Utils_APIMerkure.createContentDocument(recordId, filename, document,'Facture');
            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_CreditMemoGeneratePDF.linkDocumentToRecord');
        return result;
    }
    
    /**
    * @description Fonction pour récupérer les informations de l'avoir et des lignes et le transformer en JSON
    * @param recordId Id de l'avoir
    * @return CreditMemoObject Objet contenant les informations de l'avoir et des lignes
    */
    public static CreditMemoObject getCreditMemoInformation(Id recordId) {
        System.debug('### DEBUT LWC_CreditMemoGeneratePDF.getCreditMemoInformation');
        System.debug('## recordId : '+recordId);
        CreditMemoObject resultObject = new CreditMemoObject();
        CreditMemo__c creditMemo;

        try {
            // Construct SOQL and get creditMemo information
            Map<String, String> relations = new Map<String, String>();
            relations.put('CreditMemo__c.customerOrder__r', 'Order');
            relations.put('CreditMemo__c.customerOrder__r.Opportunity', 'Opportunity');
            relations.put('CreditMemo__c.billingAccount__r', 'Account');
            List<CreditMemo__c> creditMemoList = (List<CreditMemo__c>) SchemaUtils.executeQuery('CreditMemo__c', recordId, relations);
            if(!creditMemoList.isEmpty()) {
                creditMemo = creditMemoList[0];
           
                // Construct SOQL and get Parent creditMemoLine information
                Map<String, String> relations2 = new Map<String, String>();
                relations2.put('CreditMemoLine__c.product__r', 'Product2');
                relations2.put('CreditMemoLine__c.orderItem__r', 'OrderItem');    
                List<CreditMemoLine__c> creditMemoLines = (List<CreditMemoLine__c>) SchemaUtils.executeQuery('CreditMemoLine__c', 'creditMemo__c', creditMemo.Id, relations2);
                
                /**
                 * Construct CreditMemoLineObject object
                 */
                List<CreditMemoLineObject> creditMemoLineObjectList = new List<CreditMemoLineObject>();
                for(CreditMemoLine__c creditMemoLine : creditMemoLines) {
                    System.debug('## -------------------------------------------------- ##');
                    System.debug('## Parent: '+creditMemoLine);
                    CreditMemoLineObject creditMemoLineObject = new CreditMemoLineObject();
                    List<CreditMemoLine__c> childLines = new List<CreditMemoLine__c>();

                    creditMemoLineObject.creditMemoLine = creditMemoLine;
                    creditMemoLineObjectList.add(creditMemoLineObject);
                }
                
                /**
                 * Construct Entities object
                 */               
                EntityObject sellerEntityObject = new EntityObject();
                EntityObject headOfficeEntityObject = new EntityObject(); 
                // Get Entities ID and construct
                List<String> entitiesId = new List<String>();
                if(creditMemo.headOffice__c != null) {
                    entitiesId.add(creditMemo.headOffice__c);
                }
                if(creditMemo.seller__c != null) {
                    entitiesId.add(creditMemo.seller__c);
                }
                // Construct SOQL and get Entities information
                List<Account> entitiesList = (List<Account>) SchemaUtils.executeQuery('Account', entitiesId);
                for(Account acc : entitiesList) {
                    if(acc.Id == creditMemo.seller__c) {
                        sellerEntityObject.Entity = acc;
                    } else if(acc.Id == creditMemo.headOffice__c) {
                        headOfficeEntityObject.Entity = acc;
                    }
                }
                // Construct SOQL and get Entities Certification information
                Map<String, String> relationsEntCertif = new Map<String, String>();
                relationsEntCertif.put('EntityCertification__c.certification__r', 'Referencial__c');
                List<EntityCertification__c> entityCertifiList = (List<EntityCertification__c>) SchemaUtils.executeQuery('EntityCertification__c', 'entity__c', entitiesId, relationsEntCertif);
                // Map entity certification with parent
                List<EntityCertification__c> sellerEntityCertificationList = new List<EntityCertification__c>();
                List<EntityCertification__c> headOfficeEntityCertificationList = new List<EntityCertification__c>();
                for(EntityCertification__c entCert : entityCertifiList) {
                    System.debug('## EntityCertification: '+entCert);
                    if(entCert.active__c) {
                        if(entCert.entity__c == creditMemo.seller__c) {
                            sellerEntityCertificationList.add(entCert);
                        } else if(entCert.entity__c == creditMemo.headOffice__c) {
                            headOfficeEntityCertificationList.add(entCert);
                        }
                    }
                }
                headOfficeEntityObject.EntityCertifications = headOfficeEntityCertificationList;
                sellerEntityObject.EntityCertifications = sellerEntityCertificationList;

                // Construct object
                resultObject.creditMemo = creditMemo;
                resultObject.creditMemoLines = creditMemoLineObjectList;
                resultObject.SellerEntity = sellerEntityObject;
                resultObject.HeadOfficeEntity = headOfficeEntityObject;
            }
            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_CreditMemoGeneratePDF.getCreditMemoInformation');
        return resultObject;
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
    
    /***************************************************/
    /* OBJECT JSON                                     *
    /***************************************************/
    public class CreditMemoObject {
        public CreditMemo__c CreditMemo;
        public List<CreditMemoLineObject> CreditMemoLines;
        public EntityObject HeadOfficeEntity;
        public EntityObject SellerEntity;
    }
    public class CreditMemoLineObject {
        public CreditMemoLine__c CreditMemoLine;
    }
    public class EntityObject {
        public Account Entity;
        public List<EntityCertification__c> EntityCertifications;
    }
}