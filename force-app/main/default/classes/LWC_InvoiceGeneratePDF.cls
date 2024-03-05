//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_InvoiceGeneratePDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 14/04/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_InvoiceGeneratePDF {
    public static final String INVOICE_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.invoice.templateId', '');
    public static final String PAIDINVOICE_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.paidInvoice.templateId', '');
    public static final String ADVANCE_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.advanceInvoice.templateId', '');
    public static final String PROFORMA_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.proformaInvoice.templateId', '');
    public static final Integer INVOICELINE_SIZELIMIT = PropertiesUtils.getIntegerValue('merkure.invoice.JSONSizeLimit', 30);
    public static final Boolean API_DEBUG = PropertiesUtils.getBooleanValue('merkure.api.debug', false);
    public static final String INVOICE_SAV_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.invoice.SAV.templateId', '');
    public static final String PAIDINVOICE_SAV_TEMPLATE_ID = PropertiesUtils.getStringValue('merkure.paidinvoice.SAV.templateId', '');
    public static final String COMMANDE_CLIENT = Constants.ORDER_TYPE_COMMANDE_CLIENT;
    public static final String RECOMMANDE_CLIENT = Constants.ORDER_TYPE_RECOMMANDE_CLIENT;
    public static final String COMMANDE_SAV = Constants.ORDER_TYPE_COMMANDE_SAV;

    
    /**
    * @description Fonction pour afficher le PDF si existant
    * @param recordId Id de la facture
    * @param docType Type du document a générer (Facture ou Acompte)
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String searchExistingDocumentPDF(Id recordId, String docType) {
        System.debug('### DEBUT LWC_InvoiceGeneratePDF.searchExistingDocumentPDF');
        System.debug('## recordId : '+recordId);
        String result;
        List<String> cdocIdList = new List<String>();

        try {
            // Search existing document
            for(ContentDocumentLink cdLink :  [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                cdocIdList.add(cdLink.ContentDocumentId);
            }
            
            if(!cdocIdList.isEmpty()) {
                List<ContentVersion> docList = [SELECT Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :cdocIdList AND category__c = :docType];
                if(!docList.isEmpty()) {
                    result = docList[0].ContentDocumentId;
                } 
            }
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_InvoiceGeneratePDF.searchExistingDocumentPDF');
        return result;
    }

    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure et lier le document à l'enregistrement
    * @param recordId Id de la facture
    * @param filename Nom de la pièce jointe
    * @param docType Type du document a générer (Facture ou Acompte)
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String renderDocumentPDF(Id recordId, String filename, String docType) {
        System.debug('### DEBUT LWC_InvoiceGeneratePDF.renderDocumentPDF');
        System.debug('## recordId : '+recordId);
        InvoiceObject data;
        String result;

        try {
            // Get and construct Invoice Object
            data = getInvoiceInformation(recordId);
            // Define the templateId to use            
            String templateId = defineTemplateId(data.Invoice.customerOrder__r.Type, docType, data.Invoice.customerOrder__r.netBalance__c);
            // Call Merkure API to render the document
            if(data.InvoiceLines.size() > 30) {
                System.enqueueJob(new QA_GeneratePDFAsync('Invoice', recordId, filename, docType));
                result = 'SizeLimit';
            } else {
                Blob documentBlob = Utils_APIMerkure.renderDocumentPDF(templateId, data);
                // if Proforma, link to Order instead of to Invoice
                if(docType.containsIgnoreCase('Proforma')) {
                    recordId = data.Invoice.customerOrder__c;
                }
                // Link the document to the record
                result = linkDocumentToRecord(recordId, filename, documentBlob, docType);         
            }
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
            System.debug('ERREUR # LWC_InvoiceGeneratePDF.renderDocumentPDF > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_InvoiceGeneratePDF.renderDocumentPDF');
        return result;
    }

    /**
    * @description Fonction pour générer le document PDF en utilisant l'API de Merkure et lier le document à l'enregistrement
    * @param recordId Id de la facture
    * @param filename Nom de la pièce jointe
    * @param docType Type du document a générer (Facture ou Acompte)
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String renderDocumentPDFAsync(Id recordId, String filename, String docType) {
        System.debug('### DEBUT LWC_InvoiceGeneratePDF.renderDocumentPDF');
        System.debug('## recordId : '+recordId);
        InvoiceObject data;
        String result;

        try {
            // Get and construct Invoice Object
            data = getInvoiceInformation(recordId);
            // Define the templateId to use            
            String templateId = defineTemplateId(data.Invoice.customerOrder__r.Type, docType,data.Invoice.customerOrder__r.netBalance__c);
            // Call Merkure API to render the document
            Blob documentBlob = Utils_APIMerkure.renderDocumentPDF(templateId, data);
            // if Proforma, link to Order instead of to Invoice
            if(docType.containsIgnoreCase('Proforma')) {
                recordId = data.Invoice.customerOrder__c;
            }
            // Link the document to the record
            result = linkDocumentToRecord(recordId, filename, documentBlob, docType);      
        } catch(Exception e) {
            System.debug('ERREUR # LWC_InvoiceGeneratePDF.renderDocumentPDF > ' + e.getTypeName() + '\n' + e.getMessage() + '\n' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_InvoiceGeneratePDF.renderDocumentPDF');
        return result;
    }

    private static String defineTemplateId(String orderType, String docType, Decimal SoldeNet) {
        String templateId;
        System.debug('docType'+docType);
        // Define the templateId to use          
        if(docType.equalsIgnoreCase('Facture')) {
            if (orderType == COMMANDE_CLIENT || orderType == RECOMMANDE_CLIENT) {
                templateId = INVOICE_TEMPLATE_ID;
                System.debug('Client');
            }else if (orderType == COMMANDE_SAV) {
                if(SoldeNet != 0){                    
                    templateId = INVOICE_SAV_TEMPLATE_ID;
                }else {
                    templateId = PAIDINVOICE_SAV_TEMPLATE_ID;
                }
                System.debug('SAV');
            }            
        }else if(docType.equalsIgnoreCase('Facture acquittée')) {
            if ((orderType == COMMANDE_CLIENT || orderType == RECOMMANDE_CLIENT)) {
                templateId = PAIDINVOICE_TEMPLATE_ID;
                System.debug('Client aq');
            }else if (orderType == COMMANDE_SAV) {
                templateId = INVOICE_SAV_TEMPLATE_ID;
                System.debug('SAV aq');
            }            
        } else if(docType.containsIgnoreCase('Proforma')) {
            templateId = PROFORMA_TEMPLATE_ID;
        } else {
            templateId = ADVANCE_TEMPLATE_ID;
        }
        return templateId;
    }

    /**
    * @description Fonction pour modifier le statut de la facture à "Générer" en alimentant la date si non alimentée
    * @param recordId Id de la facture
    */
    @AuraEnabled
    public static String changeStatusOfInvoice(Id recordId) {
        System.debug('### DEBUT LWC_InvoiceGeneratePDF.changeStatusOfInvoice');
        System.debug('## recordId : '+recordId);
        String result;

        try {
            // Check if date exists, dont update if date exists
            Invoice__c inv = [SELECT Id, invoiceDate__c FROM Invoice__c WHERE Id = :recordId LIMIT 1];
            // Update invoice
            if(inv.invoiceDate__c == null) {
                inv.invoiceDate__c = Date.today();
                update inv;
            }
            result = 'OK';
            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_InvoiceGeneratePDF.changeStatusOfInvoice');
        return result;
    }

    /**
    * @description Fonction pour lier en tant que pièce jointe le document PDF à la facture en tant que Salesforce File (ContentDocument)
    * @param recordId Id de la facture
    * @param docName Nom de la pièce jointe
    * @param document Binaire du document
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static String linkDocumentToRecord(Id recordId, String docName, Blob document, String docType) {
        System.debug('### DEBUT LWC_InvoiceGeneratePDF.linkDocumentToRecord');
        System.debug('## recordId : '+recordId);
        System.debug('## docName : '+docName);
        System.debug('## docType : '+docType);
        String result;

        try {
            // Link the document link to the content document
            String filename = docName + '.pdf';
            result = Utils_APIMerkure.createContentDocument(recordId, filename, document, docType);
            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_InvoiceGeneratePDF.linkDocumentToRecord');
        return result;
    }
    
    /**
    * @description Fonction pour récupérer les informations de la facture et des lignes et le transformer en JSON
    * @param recordId Id de la facture
    * @return InvoiceObject Objet contenant les informations de la facture et des lignes
    */
    public static InvoiceObject getInvoiceInformation(Id recordId) {
        System.debug('### DEBUT LWC_InvoiceGeneratePDF.getInvoiceInformation');
        System.debug('## recordId : '+recordId);
        InvoiceObject resultObject = new InvoiceObject();
        Invoice__c invoice;
        List<InvoiceLine__c> invoiceLines = new List<InvoiceLine__c>();

        try {
            // Construct SOQL and get Invoice information
            Map<String, String> relations = new Map<String, String>();
            relations.put('Invoice__c.customerOrder__r', 'Order');
            relations.put('Invoice__c.customerOrder__r.Opportunity', 'Opportunity');
            relations.put('Invoice__c.billingAccount__r', 'Account');
            List<Invoice__c> invoiceList = (List<Invoice__c>) SchemaUtils.executeQuery('Invoice__c', recordId, relations);
            if(!invoiceList.isEmpty()) {
                List<String> invoiceLinesParentId = new List<String>();
                invoice = invoiceList[0];
           
                // Construct SOQL and get Parent InvoiceLine information
                Map<String, String> relations2 = new Map<String, String>();
                relations2.put('InvoiceLine__c.product__r', 'Product2');
                relations2.put('InvoiceLine__c.orderItem__r', 'OrderItem');    
                // Create query for line
                String soqlQuery = SchemaUtils.getQuery('InvoiceLine__c', 'invoice__c', invoice.Id, relations2);
                soqlQuery += ' AND parentLine__c = null';
                List<InvoiceLine__c> invoiceLinesParent = (List<InvoiceLine__c>) Database.query(soqlQuery);
                
                // Get Parent InvoiceLine Id 
                for(InvoiceLine__c invoiceLineParent : invoiceLinesParent) {
                    invoiceLinesParentId.add(invoiceLineParent.Id);
                }

                // Construct SOQL an get Child InvoiceLine information 
                List<InvoiceLine__c> invoiceLinesChild = (List<InvoiceLine__c>) SchemaUtils.executeQuery('InvoiceLine__c', 'parentLine__c', invoiceLinesParentId, relations2);
                
                /**
                 * Construct InvoiceLine object
                 */
                List<InvoiceLineObject> invoiceLineObjectList = new List<InvoiceLineObject>();
                for(InvoiceLine__c invoiceLineParent : invoiceLinesParent) {
                    System.debug('## -------------------------------------------------- ##');
                    System.debug('## Parent: '+invoiceLineParent);
                    InvoiceLineObject invoiceLineObject = new InvoiceLineObject();
                    List<InvoiceLine__c> childLines = new List<InvoiceLine__c>();

                    invoiceLineObject.InvoiceLine = invoiceLineParent;
                    // Map childs lines with parent
                    for(InvoiceLine__c qliChild : invoiceLinesChild) {
                        if(qliChild.parentLine__c == invoiceLineParent.Id) {
                            System.debug('## Child: '+qliChild);
                            childLines.add(qliChild);
                        }
                    }
                    invoiceLineObject.Childs = childLines;
                    invoiceLineObjectList.add(invoiceLineObject);
                }
                
                /**
                 * Construct Entities object
                 */               
                EntityObject sellerEntityObject = new EntityObject();
                EntityObject headOfficeEntityObject = new EntityObject(); 
                // Get Entities ID and construct
                List<String> entitiesId = new List<String>();
                if(invoice.headOffice__c != null) {
                    entitiesId.add(invoice.headOffice__c);
                }
                if(invoice.seller__c != null) {
                    entitiesId.add(invoice.seller__c);
                }
                // Construct SOQL and get Entities information
                List<Account> entitiesList = (List<Account>) SchemaUtils.executeQuery('Account', entitiesId);
                for(Account acc : entitiesList) {
                    if(acc.Id == invoice.seller__c) {
                        sellerEntityObject.Entity = acc;
                    } else if(acc.Id == invoice.headOffice__c) {
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
                        if(entCert.entity__c == invoice.seller__c) {
                            sellerEntityCertificationList.add(entCert);
                        } else if(entCert.entity__c == invoice.headOffice__c) {
                            headOfficeEntityCertificationList.add(entCert);
                        }
                    }
                }
                headOfficeEntityObject.EntityCertifications = headOfficeEntityCertificationList;
                sellerEntityObject.EntityCertifications = sellerEntityCertificationList;
                // Construct SOQL and get Entities BankAccount information
                Map<String, String> relationsEntBankAcc = new Map<String, String>();
                relationsEntBankAcc.put('BankAccountVisibility__c.bankAccount__r', 'Referencial__c');
                List<BankAccountVisibility__c> entityBankAccVisList = (List<BankAccountVisibility__c>) SchemaUtils.executeQuery('BankAccountVisibility__c', 'entity__c', entitiesId, relationsEntBankAcc);
                // Map entity bank account with parent
                Referencial__c sellerEntityBankAcc = null;
                Referencial__c headOfficeEntityBankAcc = null;
                for(BankAccountVisibility__c entBankAccVis : entityBankAccVisList) {
                    System.debug('## BankAccountVisibility: '+entBankAccVis);
                    if(entBankAccVis.active__c) {
                        if(entBankAccVis.bankAccount__r.active__c && entBankAccVis.entity__c == invoice.seller__c) {
                            if(entBankAccVis.defaultBankAccount__c) {
                                sellerEntityBankAcc = entBankAccVis.bankAccount__r;
                            }
                            if(sellerEntityBankAcc == null) {
                                sellerEntityBankAcc = entBankAccVis.bankAccount__r;
                            }
                        } else if(entBankAccVis.bankAccount__r.active__c && entBankAccVis.entity__c == invoice.headOffice__c) {
                            if(entBankAccVis.defaultBankAccount__c) {
                                headOfficeEntityBankAcc = entBankAccVis.bankAccount__r;
                            } 
                            if(headOfficeEntityBankAcc == null) {
                                headOfficeEntityBankAcc = entBankAccVis.bankAccount__r;
                            }
                        }
                    }
                }
                headOfficeEntityObject.BankAccount = headOfficeEntityBankAcc;
                sellerEntityObject.BankAccount = sellerEntityBankAcc;

                // Construct object
                resultObject.Invoice = invoice;
                resultObject.InvoiceLines = invoiceLineObjectList;
                resultObject.SellerEntity = sellerEntityObject;
                resultObject.HeadOfficeEntity = headOfficeEntityObject;
            }
            
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_InvoiceGeneratePDF.getInvoiceInformation');
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
    public class InvoiceObject {
        public Invoice__c Invoice;
        public List<InvoiceLineObject> InvoiceLines;
        public EntityObject HeadOfficeEntity;
        public EntityObject SellerEntity;
    }
    public class InvoiceLineObject {
        public InvoiceLine__c InvoiceLine;
        public List<InvoiceLine__c> Childs;
    }
    public class EntityObject {
        public Account Entity;
        public List<EntityCertification__c> EntityCertifications;
        public Referencial__c BankAccount;
    }
}