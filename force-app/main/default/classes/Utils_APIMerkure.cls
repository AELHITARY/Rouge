//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_APIMerkure
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 10/08/2021
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_APIMerkure { 
    // Récupération paramètres de l'API
    public static final String API_HOST = PropertiesUtils.getStringValue('merkure.api.host', '');
    public static final Integer API_TIMEOUT = PropertiesUtils.getIntegerValue('merkure.api.timeout', 120000);
    public static final Boolean API_DEBUG = PropertiesUtils.getBooleanValue('merkure.api.debug', false);
   
    /**
    * @description Fonction principale pour effectuer une demande de génération de document 
    * @param templateId Id Carbone.io du modèle de document
    * @param data Données de l'enregistrement permettant de personnaliser le document
    * @param convertFormat Type du document a générer (PDF, Excel etc...)
    * @param convertOptions Options pour la conversion (utilisable seulement si PDF)
    * @return Blob Données binaire du document  
    */
   public static Blob renderDocument(String templateId, Object data, String convertFormat, Object convertOptions) {
        System.debug('### DEBUT Utils_APIMerkure : renderDocument');
        System.debug('## templateId: '+templateId);
        System.debug('## convertFormat: '+convertFormat);
        System.debug('## convertOptions: '+convertOptions);
        Blob result;
        String url;

        System.debug('## Heap Size Limit: '+Limits.getHeapSize()+' / '+Limits.getLimitHeapSize());
        System.debug('## Callout Limit: '+Limits.getCallouts()+' / '+Limits.getLimitCallouts());
        
        try {
            // Récupération paramètre API
            String apiPath = PropertiesUtils.getStringValue('merkure.api.document.path', '/salesforce/v1/renderDocument');
            
            // Contruction et appel au webservice Merkure
            url = API_HOST + apiPath;
            HttpRequest req = constructHttpHeader(url, 'POST');
            // Ajout du body dans la requête POST
            String payloadString = constructHttpPayload(templateId, data, convertFormat, convertOptions);
            System.debug('## Payload: ' + payloadString);
            req.setBody(payloadString);

            // Flush des données pour réduire la taille mémoire
            payloadString = null;
            
            // Récupération de la réponse
            Blob respBody;
            Http http = new Http();
            HTTPResponse resp = new HTTPResponse();
            if (!Test.isRunningTest()) {
                resp = http.send(req);
                System.debug('## Response HTTP: ' + resp);
                respBody = resp.getBodyAsBlob();
            } else {
                respBody = Blob.valueOf('TEST');
            }
            
            // Vérification de la réponse
            if(!Test.isRunningTest() && resp.getStatusCode() != 200) {
                throw new APIMerkureException('ERREUR : Code = '+ resp.getStatusCode() + ' - Message = '+ resp.getStatus()); // Génère une erreur
            } else {
                result = respBody;
                System.debug('## Response: ' + result);
            }   
            
            System.debug('### FIN Utils_APIMerkure : renderDocument');
        } catch (Exception e) {
            System.debug('ERREUR # Utils_APIMerkure.renderDocument > ' + url + '\n' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        return result;
    }

    /**
    * @description Fonction pour effectuer une demande de génération de document PDF
    * @param templateId Id Carbone.io du modèle de document
    * @param data Données de l'enregistrement permettant de personnaliser le document
    * @return Blob Données binaire du document PDF 
    */
    public static Blob renderDocumentPDF(String templateId, Object data) {
        try {
            return renderDocument(templateId, data, 'pdf', null);
        } catch (Exception e) {
            throw e;
        }
    }

    /**
    * @description Fonction pour effectuer une demande de fusion de plusieurs documents PDF
    * @param filesList Liste des fichiers (ContentVersion) à envoyer 
    * @return Blob Données binaire du document PDF 
    */
    /*public static Blob mergeMultiplePDF(List<ContentVersion> filesList) {
        System.debug('### DEBUT Utils_APIMerkure : mergeMultiplePDF');
        System.debug('## filesList: '+filesList.size());
        Blob result;
        String url;
        
        try {
            // Récupération paramètre API
            String apiPath = PropertiesUtils.getStringValue('merkure.api.mergePDF.path', '/salesforce/v1/mergePDF');
            
            // Création du corp du message en respectant les requêtes multipart/form-data
            Utils_HttpFormBuilder formObject = Utils_HttpFormBuilder.build();
            for(ContentVersion ctVersion : filesList) {
                System.debug('## Fichier: ' + ctVersion);
                String title = ctVersion.Title.remove('/'); // Supprime les / pour éviter conflit avec Merkure (Linux)
                formObject.writeFile( 'file', title, EncodingUtil.base64Encode(ctVersion.VersionData) );
            }
            Blob formBlob = formObject.getFormAsBlob();

            if(API_DEBUG) {
                // ONLY FOR DEBUG - Création du JSON en tant que document
                Document d1 = new Document(Name = 'Merge_BLOB', 
                                            Body = formBlob,
                                            ContentType = 'text/plain',
                                            FolderId = '00lD0000001ygqO',
                                            Type = 'txt');
                insert d1;
            }
            
            // Contruction et appel au webservice Merkure
            url = API_HOST + apiPath;
            String contentType = Utils_HttpFormBuilder.getContentType();
            String contentLength = string.valueOf(formBlob.size());
            HttpRequest req = constructHttpHeader(url, 'POST');
            req.setHeader('Accept', '*');
            req.setHeader('Content-Length', contentLength);
            req.setHeader('Content-Type', contentType);
            req.setBodyAsBlob(formBlob);
            
            // Récupération de la réponse
            Blob respBody;
            Http http = new Http();
            HTTPResponse resp = new HTTPResponse();
            if (!Test.isRunningTest()) {
                resp = http.send(req);
                System.debug('## Response HTTP: ' + resp);
                respBody = resp.getBodyAsBlob();
            } else {
                respBody = Blob.valueOf('TEST');
            }
            
            // Vérification de la réponse
            if(!Test.isRunningTest() && resp.getStatusCode() != 200) {
                throw new APIMerkureException('ERREUR : Code = '+ resp.getStatusCode() + ' - Message = '+ resp.getStatus()); // Génère une erreur
            } else {
                result = respBody;
                System.debug('## Response: ' + result);
            }
            
            System.debug('### FIN Utils_APIMerkure : mergeMultiplePDF');
        } catch (Exception e) {
            System.debug('ERREUR # Utils_APIMerkure.mergeMultiplePDF > ' + url + '\n' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        return result;
    }
    */
    
    /**
    * @description Fonction permettant de construire l'objet pour requête HTTP avec l'entete
    * @param url URL a appeler
    * @param method Méthode de la requête HTTP (GET ou POST)
    * @return HttpRequest Objet contenant les informations de la requête HTTP
    */
    public static HttpRequest constructHttpHeader(String url, String method) {
        HttpRequest req = new HttpRequest();
        try {
            req.setMethod(method);
            req.setTimeout(API_TIMEOUT);
            req.setEndpoint(url); // Ajout URL
            // Ajout header         
            req.setHeader('Connection', 'keep-alive');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/json');
            System.debug('## URL: ' + req.getEndpoint());
        } catch (Exception e) {
            System.debug('ERREUR # Utils_APIMerkure.constructHttpHeader > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        return req;
    }
    
    /**
    * @description Fonction permettant de construire le corps de la requête HTTP
    * @param templateId Id Carbone.io du modèle de document
    * @param data Données de l'enregistrement permettant de personnaliser le document
    * @param convertFormat Type du document a générer (PDF, Excel etc...)
    * @param convertOptions Options pour la conversion (utilisable seulement si PDF)
    * @return String Corps de la requête JSON 
    */
    public static String constructHttpPayload(String templateId, Object data, String convertFormat, Object convertOptions) {        
        String payloadString;
        RenderDocumentRequest payload = new RenderDocumentRequest();
        try {
            payload.templateId = templateId;
            payload.data = data;
            payload.convertFormat = convertFormat;
            payload.convertOptions = convertOptions;
            System.debug('## Heap Size Limit: '+Limits.getHeapSize()+' / '+Limits.getLimitHeapSize());
            System.debug('## Payload : '+payload);
            payloadString = JSON.serialize(payload, true);
            System.debug('## Heap Size Limit: '+Limits.getHeapSize()+' / '+Limits.getLimitHeapSize());
            System.debug('## Payload : '+payload);
            return payloadString;
        } catch (Exception e) {
            System.debug('ERREUR # Utils_APIMerkure.constructHttpPayload > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
    }

     /**
    * @description Fonction permettant de créer une pièce jointe (ContentDocument) d'un document PDF et le lier à un enregistrement
    * @param recId Id de l'enregistrement pour le lien
    * @param fileName Nom du fichier
    * @param document Donnée binaire (BLOB) du document PDF
    * @param documentCategory Catégorie du fichier
    * @return String Id de l'enregistrement ContentDocument
    */
    public static String createContentDocumentForSignea(String recId, String fileName, Blob document, String documentCategory) {
        System.debug('### DEBUT Utils_APIMerkure : createContentDocumentForSignea');
        String result = null;
        String packageOwnerId = PropertiesUtils.getStringValue('signea.package.ownerId', null);
        System.debug('## recId: ' + recId);
        System.debug('## fileName: ' + fileName);
        System.debug('## packageOwnerId: ' + packageOwnerId);
        
        try {
            // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
            deleteCtDocumentByCategory(recId, null, documentCategory);

            // Création de l'objet ContentVersion et ContentDocument (automatiquement avec le ContentVersion)
            ContentVersion contVerFile = new ContentVersion();
            contVerFile.VersionData = document;
            contVerFile.Title = fileName; 
            contVerFile.PathOnClient=fileName;          
            contVerFile.ContentLocation= 'S'; // Indique que le doc est interne à Salesforce
            contVerFile.category__c = documentCategory; // Catégorie du doc
            insert contVerFile;
            System.debug('## ContentVersion: '+contVerFile);
            
            // Récupération de l'ID de l'objet ContentDocument créé automatiquement lors du ContentVersion
            List<ContentVersion> contVerList = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contVerFile.Id];
            if(contVerList.isEmpty()) {
                throw new APIMerkureException('Pas de ContentVersion ayant pour Id : '+ contVerFile.Id); // Génère une erreur
            } else {
                String contentDocId = contVerList[0].ContentDocumentId;
                System.debug('## ContentDocumentId: '+contentDocId);
                // Création du lien (ContentDocumentLink)
                List<ContentDocumentLink> cDeList = new List<ContentDocumentLink>();
                ContentDocumentLink cDe = new ContentDocumentLink();
                cDe.ContentDocumentId = contentDocId;
                cDe.LinkedEntityId = recId;
                cDe.ShareType = (Test.isRunningTest()) ? 'I' : 'V';
                cDe.Visibility = 'AllUsers';
                cDeList.add(cDe);
                System.debug('## ContentDocumentLink: ' + cDe);

                if(!Test.isRunningTest()) {
                    ContentDocumentLink cDe2 = new ContentDocumentLink();
                    cDe2.ContentDocumentId = contentDocId;
                    cDe2.LinkedEntityId = packageOwnerId;
                    cDe2.ShareType = 'V';
                    cDe2.Visibility = 'AllUsers';
                    cDeList.add(cDe2);
                }
                insert cDeList;
                result = contentDocId;
            }
        } catch (Exception e) {
            System.debug('ERREUR # Utils_APIMerkure.createContentDocumentForSignea > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN Utils_APIMerkure : createContentDocumentForSignea');
        return result;
    }
    
    /**
    * @description Fonction permettant de créer une pièce jointe (ContentDocument) d'un document PDF et le lier à un enregistrement
    * @param recId Id de l'enregistrement pour le lien
    * @param fileName Nom du fichier
    * @param document Donnée binaire (BLOB) du document PDF
    * @param documentCategory Catégorie du fichier
    * @param deletePrevDoc Vrai si une suppression des documents avec la même catégorie doit être effectuée
    * @return String Id de l'enregistrement ContentDocument 
    */
    public static String createContentDocument(String recId, String fileName, Blob document, String documentCategory, Boolean deletePrevDoc) {
        System.debug('### DEBUT Utils_APIMerkure : createContentDocument');
        String result = null;
        System.debug('## recId: ' + recId);
        System.debug('## fileName: ' + fileName);
        System.debug('## documentCategory: ' + documentCategory);
        System.debug('## deletePrevDoc: ' + deletePrevDoc);
        
        try {
            // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
            if(deletePrevDoc) {
                deleteCtDocumentByCategory(recId, null, documentCategory);
            }

            // Création de l'objet ContentVersion et ContentDocument (automatiquement avec le ContentVersion)
            ContentVersion contVerFile = new ContentVersion();
            contVerFile.VersionData = document;
            contVerFile.Title = fileName; 
            contVerFile.PathOnClient=fileName;          
            contVerFile.ContentLocation= 'S'; // Indique que le doc est interne à Salesforce
            contVerFile.category__c = documentCategory; // Catégorie du doc
            insert contVerFile;
            System.debug('## ContentVersion: '+contVerFile);
            
            // Récupération de l'ID de l'objet ContentDocument créé automatiquement lors du ContentVersion
            List<ContentVersion> contVerList = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contVerFile.Id];
            if(contVerList.isEmpty()) {
                throw new APIMerkureException('Pas de ContentVersion ayant pour Id : '+ contVerFile.Id); // Génère une erreur
            } else {
                String contentDocId = contVerList[0].ContentDocumentId;
                System.debug('## ContentDocumentId: '+contentDocId);
                // Création du lien (ContentDocumentLink)
                ContentDocumentLink cDe = new ContentDocumentLink();
                cDe.ContentDocumentId = contentDocId;
                cDe.LinkedEntityId = recId;
                cDe.ShareType = 'I';
                cDe.Visibility = 'AllUsers';
                insert cDe;
                System.debug('## ContentDocumentLink: ' + cDe);
                result = contentDocId;
            }
        } catch (Exception e) {
            System.debug('ERREUR # Utils_APIMerkure.createContentDocument > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN Utils_APIMerkure : createContentDocument');
        return result;
    }
    
    /**
    * @description Fonction permettant de créer une pièce jointe (ContentDocument) d'un document PDF et le lier à un enregistrement
    * @param recId Id de l'enregistrement pour le lien
    * @param fileName Nom du fichier
    * @param document Donnée binaire (BLOB) du document PDF
    * @param documentCategory Catégorie du fichier
    * @return String Id de l'enregistrement ContentDocument 
    */
    public static String createContentDocument(String recId, String fileName, Blob document, String documentCategory) {        
        return createContentDocument(recId, fileName, document, documentCategory, true);
    }

    /**
    * @description Fonction permettant de supprimer une pièce jointe lié à un enregistrement ayant la catégorie
    * @param recId Id de l'enregistrement pour le lien
    * @param recId Id du document à ne pas supprimer
    * @param documentCategory Catégorie du fichier
    */
    public static void deleteCtDocumentByCategory(String recId, String docIdDontDelete, String documentCategory) {
        System.debug('### DEBUT Utils_APIMerkure : deleteCtDocumentByCategory');
        // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
        Set<String> docIdToCheck = new Set<String>();
        for(ContentDocumentLink ctLinkToDelete : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recId]) {
            docIdToCheck.add(ctLinkToDelete.ContentDocumentId);
        }
        System.debug('## docIdToCheck: '+docIdToCheck);
        if(!docIdToCheck.isEmpty()) {
            List<ContentDocument> docToDelete = new List<ContentDocument>();
            for(ContentVersion ctVerToDelete : [SELECT Id, ContentDocumentId FROM ContentVersion 
                                                    WHERE category__c = :documentCategory 
                                                    AND ContentDocumentId IN :docIdToCheck AND ContentDocumentId != :docIdDontDelete]) {
                System.debug('## Document to delete: '+ctVerToDelete.ContentDocumentId);
                docToDelete.add(new ContentDocument(Id = ctVerToDelete.ContentDocumentId));
            }
            if(!docToDelete.isEmpty()) {
                delete docToDelete;
            }
        }
        System.debug('### FIN Utils_APIMerkure : deleteCtDocumentByCategory');
    }
    
    /***************************************************/
    /* OBJET JSON POUR RENDU DOCUMENT                  *
    /***************************************************/
    public class RenderDocumentRequest {
        public String templateId;
        public String convertFormat;
        public Object convertOptions;
        public Object data;
    }
    
    public class APIMerkureException extends Exception { }
}