//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_caseTemplt
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 11/05/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public class Ctrl_caseTemplt {
    public Id caseId {get;set;}
    public Boolean showTable {get;set;}
    public Boolean showAttachmentTable {get;set;}

    public List<ProviderReInvoiceItem__c> getncps()
    {
        System.debug('### DEBUT Ctrl_caseTemplt.getncps');
        System.debug('## caseId: '+caseId);
        List<ProviderReInvoiceItem__c> ncp;
        if(String.isNotBlank(caseId)) {
            ncp = [SELECT Name, demandedDate__c, description__c, demandedAmount__c, quantity__c, type__c, unit__c,
                    invoicedAmount__c, invoicedDate__c FROM ProviderReInvoiceItem__c WHERE ProviderProductNonCompliance__c =: caseId];
            System.debug('## ncp: '+ncp);
            if(ncp.size() > 0) {
                showTable = true;
            } else {
                showTable = false;
            }
        }
        System.debug('## showTable: '+showTable);
        System.debug('### FIN Ctrl_caseTemplt.getncps');
        return ncp;
    }

    public List<Case> getcases()
    {
        System.debug('### DEBUT Ctrl_caseTemplt.getcases');
        System.debug('## caseId: '+caseId);
        List<Case> case1;
        if(String.isNotBlank(caseId)) {
            case1 = [SELECT Id, providerReInvoiceItemCount__c, demandedAmount__c, 
                        demandedDate__c, invoicedAmount__c, invoicedDate__c FROM Case WHERE Id =: caseId];
            System.debug('## case1: '+case1);
        }
        System.debug('### FIN Ctrl_caseTemplt.getcases');
        return case1;
    }

    public List<ImageObject> getattachments()
    {
        System.debug('### DEBUT Ctrl_caseTemplt.getattachments');
        System.debug('## caseId: '+caseId);
        List<ImageObject> result = new List<ImageObject>();

        if(String.isNotBlank(caseId)) {
            // Construct SOQL an get Images information
            Map<String, List<String>> docLinkMap = new Map<String, List<String>>();
            Set<String> documentsIdList = new Set<String>();
            List<String> docLinkList = new List<String>();
            for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:caseId]) {
                /*if(docLinkMap.get(cdLink.LinkedEntityId) == null) {
                    docLinkList = new List<String>();
                } else {
                    docLinkList = docLinkMap.get(cdLink.LinkedEntityId);
                }
                docLinkList.add(cdLink.ContentDocumentId);
                docLinkMap.put(cdLink.LinkedEntityId, docLinkList);*/
                documentsIdList.add(cdLink.ContentDocumentId);
            }
            System.debug('## docLinkMap: '+docLinkMap);
            System.debug('## documentsIdList: '+documentsIdList);

            if(!documentsIdList.isEmpty()) {
                // Execute SOQL ContentVersion
                List<ContentVersion> ctVersionList = new List<ContentVersion>();
                if(!documentsIdList.isEmpty()) {
                    ctVersionList = [SELECT Id, ContentDocumentId, ContentDocument.FileExtension, ContentDocument.Title, ContentDocument.ContentSize,
                                        ContentBodyId FROM ContentVersion WHERE ContentDocumentId IN :documentsIdList];
                }
                System.debug('## ctVersionList: '+ctVersionList);

                // Execute SOQL ContentDistribution
                Map<String, String> docDistribURLMap = new Map<String, String>();
                for(ContentDistribution cdDistribURL : [SELECT Id, ContentDocumentId, DistributionPublicUrl FROM ContentDistribution WHERE ContentDocumentId IN :documentsIdList]) {
                    docDistribURLMap.put(cdDistribURL.ContentDocumentId, cdDistribURL.DistributionPublicUrl);
                }
                System.debug('## docDistribURLMap: '+docDistribURLMap);

                System.debug('## Map with document images');
                // Loop on documentId
                for(String docId : documentsIdList) {
                    System.debug('## ContentDocumentId: '+docId);
                    // Loop on document version                            
                    for(ContentVersion ctVersion : ctVersionList) {
                        if(ctVersion.ContentDocumentId == docId) {
                            System.debug('## ContentVersion: '+ctVersion);
                            ImageObject imgObj = new ImageObject();
                            imgObj.extension = ctVersion.ContentDocument.FileExtension;
                            imgObj.fileName = ctVersion.ContentDocument.Title;
                            imgObj.size = (ctVersion.ContentDocument.ContentSize / 1024); // Convert to kilo octets
                            if(docDistribURLMap.get(docId) != null) {
                                // Get public URL object
                                String ctDistribLink = docDistribURLMap.get(docId);
                                System.debug('## Image URL: '+ctDistribLink);
                                imgObj.url = ctDistribLink;
                            }
                            result.add(imgObj);
                        }
                    }
                }
            }
        }

        if(result.size() > 0) {
            showAttachmentTable = true;
        } else {
            showAttachmentTable = false;
        }
        System.debug('### FIN Ctrl_caseTemplt.getattachments');
        return result;
    }

    public class ImageObject {
        public String fileName {get;set;}
        public String extension {get;set;}
        public Decimal size {get;set;}
        public String url {get;set;}
    }
}