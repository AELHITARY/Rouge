//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_QuoteCPQGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 06/09/2023
//-- Version     : 1.3
//-- * 1.3 - #1174 : Ajout gestion du type de document devis suite à l'ajout du nouveau bouton "Devis PDF"
//-- * 1.2 - Ajout gestion des pictogrammes produit personnalisés
//-- * 1.1 - Ajout des options pour compresser les images
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_QuoteCPQGeneratePDF {
    public static final String QUOTE_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.quoteCPQ.quote.templateId', '');
    public static final String DIP_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.quoteCPQ.dip.templateId', '');
    public static final String CONTRAT_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.quoteCPQ.contrat.templateId', '');
    public static final String QUOTESAV_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.quoteCPQ.sav.templateId', '');
    public static final String TVA_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.quoteCPQ.tva.templateId', '');
    public static final String DEVIS_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.quoteCPQ.devis.templateId', '');
    public static final Boolean API_DEBUG = PropertiesUtils.getBooleanValue('merkure.api.debug.quote', false);
    
    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure et lier le document à l'enregistrement
    * @param recordId Id du devis
    * @param filename Nom de la pièce jointe
    * @param docType Type du document a générer (DIP ou Contrat ou TVA)
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String renderQuoteDocumentPDF(Id recordId, String filename, String docType) {
        System.debug('### DEBUT LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF');
        System.debug('## recordId: '+recordId);
        System.debug('## docType: '+docType);
        String result;
        Boolean docExist = false;
        List<String> cdocIdList = new List<String>();
        Blob documentBlob = null;

        try {
            // Search existing document
            for(ContentDocumentLink cdLink :  [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                cdocIdList.add(cdLink.ContentDocumentId);
            }
            
            if(!cdocIdList.isEmpty()) {
                // Define the document category
                String documentCategory = defineDocumentCategory(docType);
                List<ContentVersion> docList = [SELECT Title, ContentDocumentId, VersionData FROM ContentVersion 
                                                    WHERE ContentDocumentId IN :cdocIdList AND category__c = :documentCategory];
                if(!docList.isEmpty()) {
                    System.debug('## Document exists: '+docList[0]);
                    result = docList[0].ContentDocumentId;
                    docExist = true;
                }
            }

            // If no document, create a new one
            if(!docExist) {
                // Call Core function to call Merkure API to render the document
                documentBlob = processGeneratePDF(recordId, filename, docType);
                // Link the document to the record
                result = linkDocumentToRecord(recordId, filename, documentBlob, docType);
            }            
        } catch (CalloutException ex) {
            System.debug('ERREUR # LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF > ' + ex.getTypeName() + '\n' + ex.getMessage() + '\n' + ex.getStackTraceString());
            // Si erreur HeapSize, appel asynchrone du PDF
            if(ex.getMessage() != null && ex.getMessage().contains('Exceeded max size limit')) {
                result = 'SizeLimit';
                System.enqueueJob(new QA_GeneratePDFAsync('Quote', recordId, filename, docType));
            } else {
                throw ex;
            }
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }        
        System.debug('## Heap Size Limit: '+Limits.getHeapSize()+' / '+Limits.getLimitHeapSize());
        System.debug('### FIN LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF');
        return result;
    }

    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure seulement (sans lien ni vérification)
    * @param recordId Id du devis
    * @param filename Nom de la pièce jointe
    * @param docType Type du document a générer (DIP ou Contrat ou TVA)
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static Blob renderQuoteDocumentPDFBlob(Id recordId, String filename, String docType) {
        System.debug('### DEBUT LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob');
        System.debug('## recordId: '+recordId);
        System.debug('## docType: '+docType);
        Blob result;

        try {
            // Call Core function to call Merkure API to render the document
            result = processGeneratePDF(recordId, filename, docType);
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob');
        return result;
    }

    /**
    * @description Fonction principale de génération
    * @param recordId Id du devis
    * @param filename Nom de la pièce jointe
    * @param docType Type du document a générer (DIP ou Contrat ou TVA)
    * @return Blob Contenu de la pièce jointe (ContentDocument)
    */
    private static Blob processGeneratePDF(Id recordId, String filename, String docType) {
        QuoteObject data;
        Blob result;

        try {
            // Get and construct Quote Object
            data = getQuoteInformation(recordId, docType);
            // Define the templateId to use            
            String templateId = defineTemplateId(docType);

            // Call Merkure API to render the document
            String convertOptions = '{ MaxImageResolution : 300, ReduceImageResolution  : true }';
            result = Utils_APIMerkure.renderDocument(templateId, data, 'pdf', convertOptions);
        
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
    * @description Fonction pour lier en tant que pièce jointe le document PDF au devis en tant que Salesforce File (ContentDocument)
    * @param recordId Id du devis
    * @param docName Nom de la pièce jointe
    * @param document Binaire du document
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String linkDocumentToRecord(Id recordId, String docName, Blob document, String docType) {
        System.debug('### DEBUT LWC_QuoteCPQGeneratePDF.linkDocumentToRecord');
        System.debug('## recordId : '+recordId);
        System.debug('## docName : '+docName);
        String result;

        try {
            // Define the document category
            String documentCategory = defineDocumentCategory(docType);

            // Link the document link a content document
            String filename = docName + '.pdf';
            result = Utils_APIMerkure.createContentDocument(recordId, filename, document, documentCategory);
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_QuoteCPQGeneratePDF.linkDocumentToRecord');
        return result;
    }

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF au devis en tant que Salesforce File (ContentDocument)
    * @param recordId Id du devis
    * @param docName Nom de la pièce jointe
    * @param document Binaire du document
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String linkDocumentToRecordForSignea(Id recordId, String docName, Blob document, String docType) {
        System.debug('### DEBUT LWC_QuoteCPQGeneratePDF.linkDocumentToRecord');
        System.debug('## recordId : '+recordId);
        System.debug('## docName : '+docName);
        String result;

        try {
            // Define the document category
            String documentCategory = defineDocumentCategory(docType);

            // Link the document link a content document
            String filename = docName + '.pdf';
            result = Utils_APIMerkure.createContentDocumentForSignea(recordId, filename, document, documentCategory);
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_QuoteCPQGeneratePDF.linkDocumentToRecord');
        return result;
    }
    
    /**
    * @description Fonction pour récupérer les informations du devis et des lignes et le transformer en JSON
    * @param recordId Id du devis
    * @param docType Type du document a générer (DIP ou Contrat)
    * @return QuoteObject Objet contenant les informations du devis et des lignes
    */
    public static QuoteObject getQuoteInformation(Id recordId, String docType) {
        System.debug('### DEBUT LWC_QuoteCPQGeneratePDF.getQuoteInformation');
        System.debug('## recordId : '+recordId);
        QuoteObject resultObject = new QuoteObject();
        SBQQ__Quote__c quoteCPQ;
        User quoteOwner;
        String prdAcousticCoefRtId = DAL.getRecordTypeIdByDevName('Referencial__c', 'ProductAcousticCoefficient');
        String prdFeatureRtId = DAL.getRecordTypeIdByDevName('Referencial__c', 'ProductFeature');

        try {
            // Construct SOQL and get Quote information
            Map<String, String> relations = new Map<String, String>();
            relations.put('SBQQ__Quote__c.SBQQ__Account__r', 'Account');
            relations.put('SBQQ__Quote__c.SBQQ__Opportunity2__r.Chantier__r', 'Chantier__c');
            relations.put('SBQQ__Quote__c.SBQQ__Opportunity2__r', 'Opportunity');
            relations.put('SBQQ__Quote__c.financingMethod__r', 'Referencial__c');
            relations.put('SBQQ__Quote__c.termsAndConditions__r', 'Referencial__c');
            List<SBQQ__Quote__c> quoteCPQList = (List<SBQQ__Quote__c>) SchemaUtils.executeQuery('SBQQ__Quote__c', recordId, relations);
            if(!quoteCPQList.isEmpty()) {
                /**
                 * Execute SOQL information
                 */
                List<String> quoteLinesParentId = new List<String>();
                List<String> productsId = new List<String>();
                quoteCPQ = quoteCPQList[0];

                // Construct SOQL and get Quote Owner Information                
                List<User> userList = (List<User>) SchemaUtils.executeQuery('User', 'Id', quoteCPQ.OwnerId);
                quoteOwner = userList[0];
           
                // Construct SOQL and get Parent QuoteLine information
                Map<String, String> relations2 = new Map<String, String>();
                relations2.put('SBQQ__QuoteLine__c.SBQQ__Product__r', 'Product2');       
                // Create query for line
                String soqlQuery = SchemaUtils.getQuery('SBQQ__QuoteLine__c', 'SBQQ__Quote__c', quoteCPQ.Id, relations2);
                soqlQuery += ' AND SBQQ__RequiredBy__c = null AND SBQQ__Quantity__c != 0';
                List<SBQQ__QuoteLine__c> quoteLinesParent = (List<SBQQ__QuoteLine__c>) Database.query(soqlQuery);
                
                // Get Parent QuoteLine Id and Product Id
                for(SBQQ__QuoteLine__c qli : quoteLinesParent) {
                    quoteLinesParentId.add(qli.Id);
                    productsId.add(qli.SBQQ__Product__c);
                }

                // Construct SOQL an get Child QuoteLine information
                Map<String, String> relations3 = new Map<String, String>();
                relations3.put('SBQQ__QuoteLine__c.SBQQ__Product__r', 'Product2');      
                //List<SBQQ__QuoteLine__c> quoteLinesChild = (List<SBQQ__QuoteLine__c>) SchemaUtils.executeQuery('SBQQ__QuoteLine__c', 'SBQQ__RequiredBy__c', quoteLinesParentId, relations3);
                // Create query for line
                String soqlChildQuery = SchemaUtils.getQuery('SBQQ__QuoteLine__c', 'SBQQ__RequiredBy__c', quoteLinesParentId, relations3);
                soqlChildQuery += ' AND SBQQ__Quantity__c != 0';
                List<SBQQ__QuoteLine__c> quoteLinesChild = (List<SBQQ__QuoteLine__c>) Database.query(soqlChildQuery );
                
                // Get Product Id
                for(SBQQ__QuoteLine__c qli : quoteLinesChild) {
                    productsId.add(qli.SBQQ__Product__c);
                }

                // Construct SOQL an get Product Referencial information
                List<Referencial__c> referencialList = (List<Referencial__c>) SchemaUtils.executeQuery('Referencial__c', 'product__c', productsId);
                // Construct SOQL an get Product Certification information
                Map<String, String> relationsProdCertif = new Map<String, String>();
                relationsProdCertif.put('ProductCertification__c.certification__r', 'Referencial__c');
                List<ProductCertification__c> productCertifiList = (List<ProductCertification__c>) SchemaUtils.executeQuery('ProductCertification__c', 'product__c', productsId, relationsProdCertif);

                // Construct SOQL an get Images information
                Map<String, List<String>> docLinkMap = new Map<String, List<String>>();
                Set<String> documentsIdList = new Set<String>();
                List<String> docLinkList = new List<String>();
                for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :quoteLinesParentId]) {
                    if(docLinkMap.get(cdLink.LinkedEntityId) == null) {
                        docLinkList = new List<String>();
                    } else {
                        docLinkList = docLinkMap.get(cdLink.LinkedEntityId);
                    }
                    docLinkList.add(cdLink.ContentDocumentId);
                    documentsIdList.add(cdLink.ContentDocumentId);
                    docLinkMap.put(cdLink.LinkedEntityId, docLinkList);
                }
                System.debug('## docLinkMap: '+docLinkMap);
                System.debug('## documentsIdList: '+documentsIdList);
                // Execute SOQL ContentVersion
                List<ContentVersion> ctVersionList = new List<ContentVersion>();
                if(!documentsIdList.isEmpty()) {
                    //ctVersionList = (List<ContentVersion>) SchemaUtils.executeQuery('ContentVersion', 'ContentDocumentId', documentsIdList);                    
                    ctVersionList = [SELECT Id, ContentBodyId, ContentDocumentId 
                                        FROM ContentVersion WHERE ContentDocumentId IN :documentsIdList AND IsLatest = true];
                }
                System.debug('## ctVersionList: '+ctVersionList);
                // Execute SOQL ContentDistribution
                Map<String, String> docDistribURLMap = new Map<String, String>();
                for(ContentDistribution cdDistribURL : [SELECT Id, ContentDocumentId, DistributionPublicUrl FROM ContentDistribution WHERE ContentDocumentId IN :documentsIdList]) {
                    docDistribURLMap.put(cdDistribURL.ContentDocumentId, cdDistribURL.DistributionPublicUrl);
                }
                System.debug('## docDistribURLMap: '+docDistribURLMap);
                // Execute SOQL Warranties
                List<Entitlement> warrantiesList = [SELECT Id, Name, KparKReference__c, category__c, categoryReference__c, duration__c 
                                                    FROM Entitlement WHERE quoteLineCPQ__c IN :quoteLinesParent];
                System.debug('## warrantiesList: '+warrantiesList);

                /**
                 * Construct QuoteLine object
                 */
                List<QuoteLineObject> quoteLineObjetList = new List<QuoteLineObject>();
                //Custom pictogram Query
                Map<Id,List<CustomProductPictogram__c>> mapCustomPictogram = new Map<Id,List<CustomProductPictogram__c>>();
                string customProductPictogramQuery = SchemaUtils.getQuery('CustomProductPictogram__c', 'product__c', productsId);
                List<CustomProductPictogram__c> customProductPictogramList = Database.query(customProductPictogramQuery);
                System.debug('## CustomPictoList : '+customProductPictogramList);
                //Map custom pictograms found by product
                for(CustomProductPictogram__c customProductPictogram : customProductPictogramList){
                    if(mapCustomPictogram.containsKey(customProductPictogram.product__c)){
                        mapCustomPictogram.get(customProductPictogram.product__c).add(customProductPictogram);
                    }
                    else {
                        List<CustomProductPictogram__c> newValue = new List<CustomProductPictogram__c>{customProductPictogram};
                        mapCustomPictogram.put(customProductPictogram.product__c, newValue);
                    }
                }
                System.debug('## CustomPictoMap : '+mapCustomPictogram);
                for(SBQQ__QuoteLine__c qliParent : quoteLinesParent) {
                    System.debug('## -------------------------------------------------- ##');
                    System.debug('## Parent: '+qliParent);
                    QuoteLineObject quoteLineObjet = new QuoteLineObject();
                    List<SBQQ__QuoteLine__c> childLines = new List<SBQQ__QuoteLine__c>();
                    List<Referencial__c> acousticsCoefList = new List<Referencial__c>();
                    List<Referencial__c> productsFeaturesList = new List<Referencial__c>();
                    List<ProductCertification__c> prdCertificationList = new List<ProductCertification__c>();
                    List<ContentVersion> documentsList = new List<ContentVersion>();

                    quoteLineObjet.QuoteLine = qliParent;
                    // Map childs lines with parent
                    for(SBQQ__QuoteLine__c qliChild : quoteLinesChild) {
                        if(qliChild.SBQQ__RequiredBy__c == qliParent.Id) {
                            System.debug('## Child: '+qliChild);
                            childLines.add(qliChild);
                        }
                    }
                    quoteLineObjet.Options = childLines;
                    // Map product ref with parent
                    for(Referencial__c ref : referencialList) {
                        if(ref.product__c == qliParent.SBQQ__Product__c) {
                            if(ref.RecordTypeId == prdAcousticCoefRtId && ref.active__c) {
                                System.debug('## AcousticsCoef: '+ref);
                                acousticsCoefList.add(ref);
                            } else if(ref.RecordTypeId == prdFeatureRtId && ref.active__c) {
                                System.debug('## ProductsFeatures: '+ref);
                                productsFeaturesList.add(ref);
                            }
                        }
                    }
                    quoteLineObjet.AcousticsCoefficients = acousticsCoefList;
                    quoteLineObjet.ProductsFeatures = productsFeaturesList;                    
                    // Map product certification with parent
                    for(ProductCertification__c prdCert : productCertifiList) {
                        if(prdCert.product__c == qliParent.SBQQ__Product__c && prdCert.active__c) {
                            System.debug('## ProductCertification: '+prdCert);
                            prdCertificationList.add(prdCert);
                        }
                    }
                    quoteLineObjet.ProductsCertifications = prdCertificationList;
                    // Map images coming from KBMax with parent
                    Boolean hasImageKBMax = false;
                    Boolean hasCustomPicto = false;
                    List<ImageObject> imageURLList = new List<ImageObject>();
                    if(docLinkMap.get(qliParent.Id) != null) {
                        System.debug('## Map with document images');
                        // Loop on documentId
                        for(String docId : docLinkMap.get(qliParent.Id)) {
                            System.debug('## ContentDocumentId: '+docId);
                            if(docDistribURLMap.get(docId) != null) {
                                // Get public URL object
                                String ctDistribLink = docDistribURLMap.get(docId);
                                List<String> valueList = ctDistribLink.split('/');
                                // Loop on document version                            
                                for(ContentVersion ctVersion : ctVersionList) {
                                    if(ctVersion.ContentDocumentId == docId) {
                                        ImageObject imgObj = new ImageObject();
                                        System.debug('## ContentVersion: '+ctVersion);
                                        String urlImage = System.URL.getOrgDomainUrl().toExternalForm()+
                                            '/sfc/dist/version/renditionDownload?rendition=ORIGINAL_Png&versionId='+ctVersion.Id.to15()+
                                            '&operationContext=DELIVERY&contentId='+ctVersion.ContentBodyId.to15()+
                                            '&page=0&d=/a/'+valueList[7]+'/'+valueList[8]+'&oid=00D'+valueList[5];
                                        System.debug('## Image URL: '+urlImage);
                                        imgObj.url = urlImage;
                                        imageURLList.add(imgObj);
                                        hasImageKBMax = true;
                                    }
                                }
                            }
                        }
                    }
                    // If no image for KBMax , look for corresponding custom pictogram
                    System.debug('## product:'+qliParent.SBQQ__Product__c+' nbVantaux:'+qliParent.NombreVantaux__c);
                    if(hasImageKBMax == false && qliParent.NombreVantaux__c !=null){
                        ImageObject imgObj = new ImageObject();
                        //Get only customPictogram corresponding to current parentline product
                        List<CustomProductPictogram__c> quoteCustomProductPictogramList = mapCustomPictogram.get(qliParent.SBQQ__Product__c);
                        System.debug('## CorrespondingCustomPictogramList:'+quoteCustomProductPictogramList);
                        System.debug('## childLines:'+childLines);
                        //Retrieve the most approrpiate pictogram depending on leaf and options
                        CustomProductPictogram__c customProductPictogram = getCustomPictogramFromProduct(qliParent.NombreVantaux__c,quoteCustomProductPictogramList,childLines);
                        System.debug('## customProductPictogram :'+customProductPictogram);

                        if(customProductPictogram!=null && String.isNotBlank(customProductPictogram.pictogramFileLink__c)) {
                            imgObj.url = customProductPictogram.pictogramFileLink__c;
                            System.debug('## imgObj :'+customProductPictogram.pictogramFileLink__c);
                            imageURLList.add(imgObj);
                            hasCustomPicto=true;
                        }
                    }
                    // If no image from KBMax and no custom pictogram, get default image from the Product2
                    if(hasImageKBMax == false && hasCustomPicto == false && String.isNotBlank(qliParent.SBQQ__Product__r.image__c)) {
                        ImageObject imgObj = new ImageObject();
                        System.debug('## Product2 Image: '+qliParent.SBQQ__Product__r.image__c);
                        imgObj.url = qliParent.SBQQ__Product__r.image__c;
                        imageURLList.add(imgObj);
                    }
                    quoteLineObjet.Images = imageURLList;
                    // Construct Warranties Map
                    Map<String, List<WarrantyObject>> warrantiesMap = new Map<String, List<WarrantyObject>>();
                    for(Entitlement warranty : warrantiesList) {
                        warrantiesMap = constructWarrantiesMap(warranty.category__c, warranty.Name, warranty.duration__c, warrantiesMap);
                    }
                    // Construct Warranties object
                    List<WarrantiesObject> warrantiesObjList = new List<WarrantiesObject>();
                    for(String key : warrantiesMap.keySet()) {
                        WarrantiesObject warObj = new WarrantiesObject();
                        warObj.categorie = key;
                        warObj.warranties = warrantiesMap.get(key);
                        warrantiesObjList.add(warObj);
                    }
                    quoteLineObjet.Warranties = warrantiesObjList;
                    quoteLineObjetList.add(quoteLineObjet);
                }

                /**
                 * Construct Entities object
                 */               
                EntityObject salesEntityObject = new EntityObject();
                EntityObject serviceEntityObject = new EntityObject(); 
                // Get Entities ID and construct
                List<String> entitiesId = new List<String>();
                if(quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.serviceEntity__c != null) {
                    entitiesId.add(quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.serviceEntity__c);
                }
                if(quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.salesEntity__c != null) {
                    entitiesId.add(quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.salesEntity__c);
                }
                // Construct SOQL and get Entities information
                List<Account> entitiesList = (List<Account>) SchemaUtils.executeQuery('Account', entitiesId);
                for(Account acc : entitiesList) {
                    if(acc.Id == quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.salesEntity__c) {
                        salesEntityObject.Entity = acc;
                    } else if(acc.Id == quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.serviceEntity__c) {
                        serviceEntityObject.Entity = acc;
                    }
                }
                // Construct SOQL and get Entities Certification information
                Map<String, String> relationsEntCertif = new Map<String, String>();
                relationsEntCertif.put('EntityCertification__c.certification__r', 'Referencial__c');
                List<EntityCertification__c> entityCertifiList = (List<EntityCertification__c>) SchemaUtils.executeQuery('EntityCertification__c', 'entity__c', entitiesId, relationsEntCertif);
                // Map entity certification with parent
                List<EntityCertification__c> salesEntityCertificationList = new List<EntityCertification__c>();
                List<EntityCertification__c> serviceEntityCertificationList = new List<EntityCertification__c>();
                for(EntityCertification__c entCert : entityCertifiList) {
                    System.debug('## EntityCertification: '+entCert);
                    if(entCert.active__c) {
                        if(entCert.entity__c == quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.salesEntity__c) {
                            salesEntityCertificationList.add(entCert);
                        } else if(entCert.entity__c == quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.serviceEntity__c) {
                            serviceEntityCertificationList.add(entCert);
                        }
                    }
                }
                serviceEntityObject.EntityCertifications = serviceEntityCertificationList;
                salesEntityObject.EntityCertifications = salesEntityCertificationList;
                // Construct SOQL and get Entities BankAccount information
                Map<String, String> relationsEntBankAcc = new Map<String, String>();
                relationsEntBankAcc.put('BankAccountVisibility__c.bankAccount__r', 'Referencial__c');
                List<BankAccountVisibility__c> entityBankAccVisList = (List<BankAccountVisibility__c>) SchemaUtils.executeQuery('BankAccountVisibility__c', 'entity__c', entitiesId, relationsEntBankAcc);
                // Map entity bank account with parent
                Referencial__c salesEntityBankAcc = null;
                Referencial__c serviceEntityBankAcc = null;
                for(BankAccountVisibility__c entBankAccVis : entityBankAccVisList) {
                    System.debug('## BankAccountVisibility: '+entBankAccVis);
                    if(entBankAccVis.active__c) {
                        if(entBankAccVis.bankAccount__r.active__c && entBankAccVis.entity__c == quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.salesEntity__c) {
                            if(entBankAccVis.defaultBankAccount__c) {
                                salesEntityBankAcc = entBankAccVis.bankAccount__r;
                            }
                            if(salesEntityBankAcc == null) {
                                salesEntityBankAcc = entBankAccVis.bankAccount__r;
                            }
                        } else if(entBankAccVis.bankAccount__r.active__c && entBankAccVis.entity__c == quoteCPQ.SBQQ__Opportunity2__r.Chantier__r.serviceEntity__c) {
                            if(entBankAccVis.defaultBankAccount__c) {
                                serviceEntityBankAcc = entBankAccVis.bankAccount__r;
                            }
                            if(serviceEntityBankAcc == null) {
                                serviceEntityBankAcc = entBankAccVis.bankAccount__r;
                            }
                        }
                    }
                }
                serviceEntityObject.BankAccount = serviceEntityBankAcc;
                salesEntityObject.BankAccount = salesEntityBankAcc;

                /**
                 * Construct global object
                 */
                resultObject.Quote = quoteCPQ;
                resultObject.Owner = quoteOwner;
                resultObject.QuoteLines = quoteLineObjetList;
                resultObject.ServiceEntity = serviceEntityObject;
                resultObject.SalesEntity = salesEntityObject;
                resultObject.documentType = docType;                
            }
            
        } catch(Exception e) {
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN LWC_QuoteCPQGeneratePDF.getQuoteInformation');
        return resultObject;
    }

    /**
    * @description Fonction pour construire la map des garanties par catégorie
    * @param categorie Catégorie de la garantie
    * @param libelle Libellé de la garantie
    * @param duration Durée de la garantie
    * @param warrantiesMap Map des garanties par catégorie
    * @return Map<String, List<WarrantyObject>> Map des garanties par catégorie mise à jour
    */
    public static Map<String, List<WarrantyObject>> constructWarrantiesMap(String categorie, String libelle, Decimal duration, Map<String, List<WarrantyObject>> warrantiesMap) {
        // If libelle exists
        if(String.isNotBlank(libelle)) {
            // Create the warranty list
            List<WarrantyObject> warrantiesList = new List<WarrantyObject>();
            WarrantyObject warranty = new WarrantyObject();
            warranty.libelle = libelle; 
            warranty.duration = duration;
            if(warrantiesMap.get(categorie) == null) {
                warrantiesList = new List<WarrantyObject>();
            } else {
                warrantiesList = warrantiesMap.get(categorie);
            }
            warrantiesList.add(warranty);
            warrantiesMap.put(categorie, warrantiesList);
        }
        return warrantiesMap;
    }

    /**
    * @description Fonction pour récupérer le Pictogramme personnalisé correspondant à la ligne de de devis et au produit
    * @param productId Id du produit
    * @param qliParentId Id de la ligne de devis
    * @param leaf Nombre Vantaux de la ligne de devis
    * @return CustomProductPictogram__c Pictogramme personnalisé
    */
    public static CustomProductPictogram__c getCustomPictogramFromProduct(String leaf, List<CustomProductPictogram__c> customProductPictogramList, List<SBQQ__QuoteLine__c> childQuoteLineslist){
        CustomProductPictogram__c customProductPictogram = null;

        if(customProductPictogramList!=null && !customProductPictogramList.isEmpty()){
            
            Set<Id> productOptionsList = new Set<Id>();
            if(childQuoteLineslist !=null && !childQuoteLineslist.isEmpty()){
                for(SBQQ__QuoteLine__c childQuoteLine : childQuoteLineslist){
                    productOptionsList.Add(childQuoteLine.SBQQ__Product__r.Id);
                }
            }
            System.debug('## productOptionsList : '+productOptionsList);

            //recherche du pictogramme avec le plus d'options correspondantes sur même nb Vantaux
            customProductPictogram = getCorrespondingPictogramFromProductOptions(customProductPictogramList,productOptionsList, leaf);
            
            if(customProductPictogram == null){
                System.debug('## Not found with nb Vantaux');
                //Si non trouvé recherche pictogramme avec le plus d'options correspondantes et nb Vantaux vide
                customProductPictogram = getCorrespondingPictogramFromProductOptions(customProductPictogramList,productOptionsList, '');
            }
            System.debug('## customProducPicto:'+customProductPictogram);
        }

        return customProductPictogram;
    }

    /**
    * @description Fonction pour récupérer le Pictogramme personnalisé ayant le plus de correspondance par rapport aux options 
    * @param customProductPictogramList Liste des pictogramme personnalisé existant sur le produit
    * @param productOptions Set d'Id des produits en options sur la ligne de devis
    * @param leaf Nombre Vantaux de la ligne de devis
    * @return CustomProductPictogram__c Pictogramme personnalisé
    */
    public static CustomProductPictogram__c getCorrespondingPictogramFromProductOptions(List<CustomProductPictogram__c> customProductPictogramList, Set<Id> productOptions, String leaf){
        CustomProductPictogram__c result = null;
        Map<Integer, CustomProductPictogram__c> customPictogramMap = new Map<Integer, CustomProductPictogram__c>();

        //Parcours des pictogrammes du produit 
        for(CustomProductPictogram__c customPictogram : customProductPictogramList){
            //Si Nb vantaux renseigné en paramètre on récupère uniquement les picto qui on un nb Vantaux correspondant
            //Si Nb Vantaux en paramètre vide on récupère uniquement les picto sans nb Vantaux renseigné
            if((leaf!='' && customPictogram.leaf__c == leaf) || (leaf == '' && String.isEmpty(customPictogram.leaf__c))){
                //Si présence de produits en options sur la ligne on vérifie chaque niveau
                if(!productOptions.isEmpty() && productOptions.Contains(customPictogram.productOptionLevel1__c)){
                    if(productOptions.Contains(customPictogram.productOptionLevel2__c)){
                        if(productOptions.Contains(customPictogram.productOptionLevel3__c)){
                            if(productOptions.Contains(customPictogram.productOptionLevel4__c)){
                                //Pictogramme avec 4 options correspondantes
                                customPictogramMap.put(4,customPictogram);
                                break;
                            }
                            else if(customPictogram.productOptionLevel4__c == null && !customPictogramMap.containsKey(3)){
                                //Pictogramme avec 3 options correspondantes (niveau 1,2,3) et 4ème option vide
                                customPictogramMap.put(3,customPictogram);
                            }
                        }
                        else if(customPictogram.productOptionLevel3__c == null && !customPictogramMap.containsKey(2)){
                            //Pictogramme avec 2 options correspondantes (niveau 1,2) et 3ème et 4ème options vides
                            customPictogramMap.put(2,customPictogram);
                        }
                    }
                    else if(customPictogram.productOptionLevel2__c == null && !customPictogramMap.containsKey(1)){
                        //Pictogramme avec 1 option correspondante (niveau 1) et les 3 autres options vides
                        customPictogramMap.put(1,customPictogram);
                    }
                }               
                else if(customPictogram.productOptionLevel1__c == null && !customPictogramMap.containsKey(0)){
                    //Pictogramme sans options 
                    customPictogramMap.put(0,customPictogram);
                }
            }
        }
        System.debug('## customPictogramMap:'+customPictogramMap);

        //Détermine le pictogramme à renvoyer en prenant le plus haut niveau trouvé 
        if(!customPictogramMap.isEmpty()){
            for(Integer i=4; i>=0;i--){
                if(customPictogramMap.containsKey(i) && customPictogramMap.get(i)!=null){
                    System.debug('## customPictogram found with key:'+i);
                    result = customPictogramMap.get(i);
                    break;
                }
            }
        }

        return result;
    }

    private static String defineTemplateId(String docType) {
        String templateId;
        // Define the templateId to use          
        if(docType.equalsIgnoreCase('DIP')) {
            templateId = DIP_TEMPLATE_ID;
        } else if(docType.equalsIgnoreCase('Contrat')) {
            templateId = CONTRAT_TEMPLATE_ID;
        } else if(docType.equalsIgnoreCase('TVA')) {
            templateId = TVA_TEMPLATE_ID;
        } else if(docType.equalsIgnoreCase('Devis SAV')){
            templateId = QUOTESAV_TEMPLATE_ID;
        } else if(docType.equalsIgnoreCase('Devis')){
            templateId = DEVIS_TEMPLATE_ID;
        } 
        else {
            templateId = QUOTE_TEMPLATE_ID;
        }
        System.debug('## templatedId :'+templateId);
        return templateId;
    }

    private static String defineDocumentCategory(String docType) {
        // Define the document category
        String documentCategory;
        if(docType.equalsIgnoreCase('TVA')) {
            documentCategory = 'Attestation TVA';
        } else {
            documentCategory = docType;
        }
        return documentCategory;
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
    public class QuoteObject {
        public String documentType;
        public SBQQ__Quote__c Quote;
        public User Owner;
        public List<QuoteLineObject> QuoteLines;
        public EntityObject ServiceEntity;
        public EntityObject SalesEntity;
    }
    public class QuoteLineObject {
        public SBQQ__QuoteLine__c QuoteLine;
        public List<SBQQ__QuoteLine__c> Options;
        public List<ProductCertification__c> ProductsCertifications;
        public List<Referencial__c> AcousticsCoefficients;
        public List<Referencial__c> ProductsFeatures;
        public List<WarrantiesObject> Warranties;
        public List<ImageObject> Images;
    }
    public class EntityObject {
        public Account Entity;
        public List<EntityCertification__c> EntityCertifications;
        public Referencial__c BankAccount;
    }
    public class ImageObject {
        public String url;
    }
    public class WarrantiesObject {
        public String categorie;
        public List<WarrantyObject> warranties;
    }    
    public class WarrantyObject {
        public String libelle;
        public Double duration;
    }
}