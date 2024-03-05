//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_SAReportGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 09/03/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_SAReportGeneratePDF {
    public static final String SA_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.sa.report.templateId', '');
    public static final Boolean API_DEBUG = PropertiesUtils.getBooleanValue('merkure.api.debug', false);

    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure et lier le document à l'enregistrement
    * @param recordId Id du RDV
    * @param filename Nom de la pièce jointe
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String renderSADocumentPDF(Id recordId, String filename) {
        System.debug('### DEBUT LWC_SAReportGeneratePDF.renderSADocumentPDF');
        System.debug('## recordId: '+recordId);
        System.debug('## filename: '+filename);
        String result;
        Blob documentBlob = null;

        try {
            // Call Core function to call Merkure API to render the document
            documentBlob = processGeneratePDF(recordId, filename);
            // Link the document to the record
            result = linkDocumentToRecord(recordId, filename, documentBlob);   
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }        
        System.debug('### FIN LWC_SAReportGeneratePDF.renderSADocumentPDF');
        return result;
    }

    /**
    * @description Fonction principale de génération
    * @param recordId Id du RDV
    * @param filename Nom de la pièce jointe
    * @return Blob Contenu de la pièce jointe (ContentDocument)
    */
    private static Blob processGeneratePDF(Id recordId, String filename) {
        ResultObject data;
        Blob result;

        try {
            // Get and construct ServiceAppointment Object
            data = getSAInformation(recordId);

            // Define the templateId to use            
            String templateId = SA_TEMPLATE_ID;

            // Call Merkure API to render the document
            result = Utils_APIMerkure.renderDocumentPDF(templateId, data);
        
            // ONLY FOR DEBUG - Création du JSON en tant que document
            if(API_DEBUG) {
                String payloadString = Utils_APIMerkure.constructHttpPayload(templateId, data, 'pdf', null);
                System.debug('## Payload: ' + payloadString);

                Document d = new Document(Name = filename, 
                                            Body = Blob.valueOf(payloadString),
                                            ContentType = 'text/plain',
                                            FolderId = '00lD0000001ygqO',
                                            Type = 'txt');
                insert d;
            }
        } catch(Exception e) {
            throw e;
        }
        return result;
    }

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF au RDV en tant que Salesforce File (ContentDocument)
    * @param recordId Id du RDV
    * @param docName Nom de la pièce jointe
    * @param document Binaire du document
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String linkDocumentToRecord(Id recordId, String docName, Blob document) {
        System.debug('### DEBUT LWC_SAReportGeneratePDF.linkDocumentToRecord');
        System.debug('## recordId : '+recordId);
        System.debug('## docName : '+docName);
        String result;

        try {
            // Link the document link a content document
            String filename = docName + '.pdf';
            result = Utils_APIMerkure.createContentDocument(recordId, filename, document, 'Procès verbal');
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_SAReportGeneratePDF.linkDocumentToRecord');
        return result;
    }
    
    /**
    * @description Fonction pour récupérer les informations du RDV et le transformer en JSON
    * @param recordId Id du RDV
    * @return ResultObject Objet contenant les informations du RDV
    */
    public static ResultObject getSAInformation(Id recordId) {
        System.debug('### DEBUT LWC_SAReportGeneratePDF.getSAInformation');
        System.debug('## recordId : '+recordId);
        ResultObject resultObject = new ResultObject();
        ServiceAppointment saRecord;

        try {
            // Construct SOQL and get ServiceAppointment information
            Map<String, String> relations = new Map<String, String>();
            relations.put('customerOrder__r', 'Order');
            relations.put('customerOrder__r.serviceEntity__r', 'Account');
            relations.put('Chantier__r', 'Chantier__c');
            relations.put('Account', 'Account');
            List<ServiceAppointment> saList = (List<ServiceAppointment>) SchemaUtils.executeQuery('ServiceAppointment', recordId, relations);
            if(!saList.isEmpty()) {
                saRecord = saList[0];

                /**
                 * Construct global object
                 */
                resultObject.ServiceAppointment = saRecord;     

                // Récupération des ressources
                Map<String, String> relations2 = new Map<String, String>();
                relations2.put('ServiceResource', 'ServiceResource');
                for(AssignedResource ar : (List<AssignedResource>) SchemaUtils.executeQuery('AssignedResource', 'ServiceAppointmentId', recordId, relations2)) {
                    if(ar.Id == saRecord.firstPrincipalResource__c) {
                        resultObject.Resource1 = ar.ServiceResource;
                    } else {
                        resultObject.Resource2 = ar.ServiceResource;
                    }
                }        
            }
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_SAReportGeneratePDF.getSAInformation');
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
    public class ResultObject {
        public ServiceAppointment ServiceAppointment;
        public ServiceResource Resource1;
        public ServiceResource Resource2;
    }
}