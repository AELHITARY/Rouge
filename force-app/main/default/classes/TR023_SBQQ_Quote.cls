//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR023_SBQQ_Quote
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 16/08/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR023_SBQQ_Quote {

    /**
    * @description Méthode permettant de générer les documents PDF lorsque la date de transmission est alimenté
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void generateDocuments(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }        
        
        System.debug('### DEBUT TR023_SBQQ_Quote : generateDocuments');
        List<String> newQuotesId = new List<String>();
        Map<Id, SBQQ__Quote__c> oldQuotes = (Map<Id, SBQQ__Quote__c>)Trigger.oldMap;

        // A - Initialisation des données intermédiaires 
        for (SBQQ__Quote__c newQuote : (List<SBQQ__Quote__c>)Trigger.new) {
            SBQQ__Quote__c oldQuote = oldQuotes == null ? null : oldQuotes.get(newQuote.Id);

            // On génère les documents seulement si la date de transmission est alimenté ou la date de vente
            if((newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_TRANSMITTED || newQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_SOLD)
                && newQuote.SBQQ__Status__c != oldQuote.SBQQ__Status__c 
                && newQuote.circuitSignatureDevis__c == null 
                && newQuote.circuitSignatureContrat__c == null) 
            {
                System.debug('## Document for : '+newQuote.Id);
                newQuotesId.add(newQuote.Id);
            }
        }

        // Appel de la fonction de génération asynchrone
        if(!newQuotesId.isEmpty()) {
            TR023_SBQQ_Quote.asyncGenerateDocuments(newQuotesId);
        }
        System.debug('### FIN TR023_SBQQ_Quote : generateDocuments');
    }
    
    /**
    * @description Méthode asynchrone afin de générer les documents et les associés aux devis
    * @param newQuotesId Id des devis pour la génération des documents
    */
    @future(callout=true)
    private static void asyncGenerateDocuments(List<String> newQuotesId) {
        System.debug('### DEBUT TR023_SBQQ_Quote : asyncGenerateDocuments');
        Map<String, String> quoteCGVMap = new Map<String, String>();

        List<SBQQ__Quote__c> quotesList = [SELECT Id, NDevis__c, termsAndConditions__c, MontantTVAIntermediaire__c, MontantTVAReduite__c FROM SBQQ__Quote__c WHERE Id IN :newQuotesId];
        
        for(SBQQ__Quote__c devis : quotesList) {
            System.debug('## Generate Documents for: '+devis.Id);
            Blob blobTVA = null;
            // C1 - Création et enregistrement du PDF (DIPC)
            String dateOfDayFormat = Datetime.now().format('dd/MM/YYYY');
            Blob blobDIPC = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(devis.Id, 'DIP '+devis.NDevis__c+' - '+dateOfDayFormat, 'DIP');
            System.debug('## DIPC: '+blobDIPC);
            
            // C2 - Création et enregistrement du PDF (Contrat)
            Blob blobContrat = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(devis.Id, 'Contrat ' + devis.NDevis__c+' - '+dateOfDayFormat, 'Contrat');
            System.debug('## Contrat: '+blobContrat);
            
            // C3 - Création et enregistrement du PDF (Attestation TVA)
            if(devis.MontantTVAIntermediaire__c != 0 || devis.MontantTVAReduite__c != 0) {
                blobTVA = LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDFBlob(devis.Id, 'Attestation TVA ' + devis.NDevis__c+' - '+dateOfDayFormat, 'TVA');
                System.debug('## TVA: '+blobTVA);
            }

            // Lien des documents au devis et vérification des documents par catégorie
            String fileDIPC = LWC_QuoteCPQGeneratePDF.linkDocumentToRecord(devis.Id, 'DIP '+devis.NDevis__c+' - '+dateOfDayFormat, blobDIPC, 'DIP');
            TR023_SBQQ_Quote.deleteCtDocumentByCategory(devis.Id, fileDIPC, 'DIP');
            String fileContrat = LWC_QuoteCPQGeneratePDF.linkDocumentToRecord(devis.Id, 'Contrat '+devis.NDevis__c+' - '+dateOfDayFormat, blobContrat, 'Contrat');
            TR023_SBQQ_Quote.deleteCtDocumentByCategory(devis.Id, fileContrat, 'Contrat');
            if(blobTVA != null){
                String fileTVA = LWC_QuoteCPQGeneratePDF.linkDocumentToRecord(devis.Id, 'Attestation TVA '+devis.NDevis__c+' - '+dateOfDayFormat, blobTVA, 'TVA');
                TR023_SBQQ_Quote.deleteCtDocumentByCategory(devis.Id, fileTVA, 'TVA');
            }

            // Récupération ID des CGV pour copier les PDF
            if(String.isNotBlank(devis.termsAndConditions__c)) {
                System.debug('## CGV: '+devis.termsAndConditions__c);
                quoteCGVMap.put(devis.Id, devis.termsAndConditions__c);
            }
        }

        // C4 - CGV
        if(!quoteCGVMap.isEmpty()) {
            System.debug('## Création des CGV');
            // Création d'une MAP des liens
            Map<String, List<String>> docLinkMap = new Map<String, List<String>>();
            List<String> docLinkList;
            for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :quoteCGVMap.values()]) {
                if(docLinkMap.get(cdLink.LinkedEntityId) == null) {
                    docLinkList = new List<String>();
                } else {
                    docLinkList = docLinkMap.get(cdLink.LinkedEntityId);
                }
                docLinkList.add(cdLink.ContentDocumentId);
                docLinkMap.put(cdLink.LinkedEntityId, docLinkList);
            }
            System.debug('## docLinkMap: '+docLinkMap);
            // Création des CGV
            if(!docLinkMap.isEmpty()) {
                for(SBQQ__Quote__c devis : quotesList) {
                    // Récupération des ID des documents CGV
                    List<String> docCGVList = docLinkMap.get(devis.termsAndConditions__c);
                    if(!docCGVList.isEmpty()) {
                        System.debug('## Suppression des CGV pour le devis: '+devis.Id);
                        Utils_APIMerkure.deleteCtDocumentByCategory(devis.Id, null, 'CGV');
                        for(ContentVersion cdLink : [SELECT Id, ContentDocumentId, PathOnClient, Title, VersionData FROM ContentVersion 
                                                        WHERE ContentDocumentId IN :docCGVList]) {
                            // Insertion ContentVersion
                            ContentVersion cVersion = new ContentVersion();
                            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                            cVersion.PathOnClient = cdLink.PathOnClient;
                            cVersion.Title = cdLink.Title;//Name of the file
                            cVersion.VersionData = cdLink.VersionData;//File content
                            cVersion.category__c = 'CGV';
                            insert cVersion;
                            
                            //After saved the Content Verison, get the ContentDocumentId
                            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                            
                            //Insert ContentDocumentLink
                            ContentDocumentLink fileContentLink = new ContentDocumentLink();
                            fileContentLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                            fileContentLink.LinkedEntityId = devis.Id;//Add attachment parentId
                            fileContentLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                            insert fileContentLink;
                            System.debug('## CGV ContentLink: ' +fileContentLink.Id );
                        }
                    }
                }
            }
        }

        // MAJ des devis
        update quotesList;

        System.debug('### FIN TR023_SBQQ_Quote : asyncGenerateDocuments');
    }

    /**
    * @description Fonctions de suppression si un fichier avec la même catégorie existe déjà lié au record
    * @param quoteId Id du devis
    * @param docId Id du document
    * @param docType Type de document à générer
    * @return String Id de la pièce jointe (ContentDocument)
    */
    public static void deleteCtDocumentByCategory(String quoteId, String docId, String docType){
        //Define the document type
        String documentCategory;
        if(docType.equalsIgnoreCase('TVA')) {
            documentCategory = 'Attestation TVA';
        } else {
            documentCategory = docType;
        }

        // Si un fichier avec la même catégorie existe déjà lié au record, alors on supprime
        Utils_APIMerkure.deleteCtDocumentByCategory(quoteId, docId, documentCategory);
    }
}