//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_SBQQ_QuoteLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/09/2023
//-- Version     : 1.2
//-- * 1.2 : Correctif pour afficher correctement les coefficients acoustiques quand valeur vide
//-- * 1.1 : Demande #1175 - Ajout méthode updateAcousticCoefficients
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR022_SBQQ_QuoteLine {

    /**
    * @description Mise à jour du montant de la prime CEE des devis
    * @param quoteLineItemList Liste des lignes de devis
    */
    /*
    public static void setMontantTotalCEE(List<SBQQ__QuoteLine__c> quoteLineItemList) {
        if (!Trigger.isExecuting)
            return;

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.setMontantTotalCEE');
        List<SBQQ__Quote__c> quote = new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        Set<String> quoteIdList = new Set<String>();
        Set<String> productIdList = new Set<String>();
        Set<String> tvaTypeList = new Set<String>();
        List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
        List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
        List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
        List<String> quoteIds = new List<String>();
        
        // récupération des devis associés et de toutes leur lignes
        if(quoteLineItemList != null){
            for(SBQQ__QuoteLine__c qli : quoteLineItemList){
                System.debug('qli.montantCEE__c : '+qli.montantCEE__c);
                if (!AlreadyUsed.isUsed('TR022_SBQQ_QuoteLine.setMontantTotalCEE', qli.SBQQ__Quote__c)) 
                    quoteIds.add(qli.SBQQ__Quote__c);
            }
            quote = [SELECT Id, zone__c, referenceDate__c, RevenusFiscaux__c, NombrePersonnes__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
            if(!quote.isEmpty()){

                qliList = [SELECT Id, SBQQ__Quote__c, Quantite__c, SBQQ__Product__c, eligibleCEE__c, TauxTVAPercent__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds];

                for(SBQQ__QuoteLine__c qli : qliList){
                    productIdList.add(qli.SBQQ__Product__c);
                }

                // Récupération des primes présentes dans la base
                //ceePrimeList = [SELECT Id, dateDebutValidite__c, dateFinValidite__c, montant__c, produit__c, zone__c FROM CEE_Prime__c];
                tvaList = [SELECT Id, Type__c, produit__c, dateDebut__c, dateFin__c, taux__c 
                                FROM TVA_Produit__c
                                WHERE produit__c IN :productIdList];

                for(TVA_Produit__c tva : tvaList){
                    tvaTypeList.add(tva.Type__c);
                }

                ceeList = [SELECT Id, type__c, startDate__c, endDate__c, minIncomes__c, maxIncomes__c, personNumber__c, 
                                    geography__c, heatingModes__c, customerAmount__c, officialAmount__c, incomeType__c
                            FROM ESCIncentive__c
                            WHERE type__c IN :tvaTypeList];

                // Calcul de la prime CEE
                for(SBQQ__Quote__c q : quote){
                    Utils_CEE.setQuoteCEE(qliList, q, ceeList, tvaList);
                }

                update quote;
            }
        }
        System.debug('### FIN TR022_SBQQ_QuoteLine.setMontantTotalCEE');
    }
    */

    /**
    * @description Fonction pour effectuer l'appel API à KBMax pour récupérer les images
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void sendGetKBMaxImages(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.sendGetKBMaxImages');
        List<SBQQ__QuoteLine__c> quoteLineItemList = new List<SBQQ__QuoteLine__c>();
        List<String> quoteLineItemListId = new List<String>();
        List<ContentDocument> contentDocumentToDelete = new List<ContentDocument>();
        Map < String, String > headerValues = new Map < String, String> ();
        Map<Id, SBQQ__QuoteLine__c>  oldQuoteLinesItems = (Map<Id, SBQQ__QuoteLine__c>)Trigger.oldMap;
        
        try {
            // A - Initialisation des données intermédiaires 
            for (SBQQ__QuoteLine__c newQLI : (List<SBQQ__QuoteLine__c>)Trigger.new) {
                
                System.debug('newQLI.KBMAXSB__Id__c '+ newQLI.KBMAXSB__Id__c);
                if (newQLI.KBMAXSB__Id__c > 0) {   
                    SBQQ__QuoteLine__c oldQLI = oldQuoteLinesItems == null ? null : oldQuoteLinesItems.get(newQLI.id);

                    // Génération d'image à la création d'une ligne non clonée, et à la modification
                    //System.debug('oldQLI.KBMAXSB__Id__c '+ oldQLI.KBMAXSB__Id__c);
                    System.debug('newQLI.KBMAXSB__Id__c '+ newQLI.KBMAXSB__Id__c);
                    System.debug('Trigger.isInsert '+ Trigger.isInsert);
                    System.debug('Trigger.isUpdate '+ Trigger.isUpdate);
                   // System.debug('oldQLI.kbmaxAPISent__c '+ oldQLI.kbmaxAPISent__c);
                    System.debug('newQLI.kbmaxAPISent__c '+ newQLI.kbmaxAPISent__c);
                    if ((Trigger.isInsert && newQLI.lineCloned__c == false && newQLI.kbmaxAPISent__c == false && !AlreadyUsed.isUsed2('TR022_SBQQ_QuoteLine.sendGetKBMaxImages', String.valueOf(newQLI.KBMAXSB__Id__c))) 
                        || (Trigger.isUpdate && newQLI.kbmaxAPISent__c == false && oldQLI.kbmaxAPISent__c == false && newQLI.KBMAXSB__Id__c != oldQLI.KBMAXSB__Id__c
                            && !AlreadyUsed.isUsed2('TR022_SBQQ_QuoteLine.sendGetKBMaxImages', String.valueOf(newQLI.KBMAXSB__Id__c)))
                    ) { 
                        quoteLineItemList.add(newQLI);   
                        if(String.isNotBlank(newQLI.Id)) {
                            quoteLineItemListId.add(newQLI.Id);
                        }
                    }
                }
            }

            // B - Traitement
            if(!quoteLineItemList.isEmpty()){
                for(SBQQ__QuoteLine__c newQLI : quoteLineItemList) {
                    System.debug('## QLI: ' + newQLI.Id); 
                    // Pour chaque lignes, on vérifie l'ID KBMax
                    if (newQLI.KBMAXSB__Id__c > 0) {                        
                        System.debug('## Submit Image to KBMAX KBMAXSB__Id__c: ' + newQLI.KBMAXSB__Id__c); 
                        newQLI.kbmaxAPISent__c = true;
                        if (!Test.isRunningTest()) {      
                            // Appel à la fonction API de KBMax                  
                            KBMAXSB.KbmaxClient.submitQuoteByQuoteLineKbmaxId(newQLI.KBMAXSB__Id__c, headerValues);
                        }
                    }
                }

                // Récupération des images existantes pour suppression
                System.debug('## QuoteLineItem for document deletion: ' + quoteLineItemListId); 
                if(!quoteLineItemListId.isEmpty()){
                    for(ContentDocumentLink cdLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :quoteLineItemListId]) {
                        contentDocumentToDelete.add(new ContentDocument(Id = cdLink.ContentDocumentId));
                    }
                    System.debug('## ContentDocument to delete: ' + contentDocumentToDelete); 
                    if(!contentDocumentToDelete.isEmpty()) {
                        delete contentDocumentToDelete;
                    }
                }
                /*if(!quoteLineItemList.isEmpty()) {
                    update quoteLineItemList;
                }*/
            }
        } catch(exception e) {
            System.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN TR022_SBQQ_QuoteLine.sendGetKBMaxImages');
    }

    /**
    * @description Fonction pour effectuer l'action de récupération des images originale sur les lignes clonées
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void getOriginalImageClonedLine(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.getOriginalImageClonedLine');
        List<SBQQ__QuoteLine__c> quoteLineItemList = new List<SBQQ__QuoteLine__c>();
        Map<String, String> sourceLinesMap = new Map<String, String>();
        
        try {
            // A - Initialisation des données intermédiaires 
            for (SBQQ__QuoteLine__c newQLI : (List<SBQQ__QuoteLine__c>)Trigger.new) {
                // A la création d'une ligne non clonée, récupération des images originale
                if (Trigger.isInsert && Trigger.isAfter && newQLI.lineCloned__c && newQLI.KBMAXSB__Id__c > 0
                    && String.isNotBlank(newQLI.SBQQ__Source__c) && !AlreadyUsed.isUsed('TR022_SBQQ_QuoteLine.getOriginalImageClonedLine', newQLI.Id)) 
                {  
                    System.debug('## Id: '+newQLI.Id+' Source: '+newQLI.SBQQ__Source__c);
                    sourceLinesMap.put(newQLI.Id, newQLI.SBQQ__Source__c);
                    quoteLineItemList.add(newQLI);
                }
            }

            // Appel de la fonction de génération asynchrone
            if(!sourceLinesMap.isEmpty()) {
                System.debug('## Récupération des liens des images');
                // Création d'une MAP des liens
                Map<String, List<String>> docLinkMap = new Map<String, List<String>>();
                List<String> docLinkList;
                for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :sourceLinesMap.values()]) {
                    if(docLinkMap.get(cdLink.LinkedEntityId) == null) {
                        docLinkList = new List<String>();
                    } else {
                        docLinkList = docLinkMap.get(cdLink.LinkedEntityId);
                    }
                    docLinkList.add(cdLink.ContentDocumentId);
                    docLinkMap.put(cdLink.LinkedEntityId, docLinkList);
                }
                System.debug('## docLinkMap: '+docLinkMap);
    
                // Création des images clonées
                if(!docLinkMap.isEmpty()) {
                    for(SBQQ__QuoteLine__c newQLI : quoteLineItemList) {
                        // Récupération des ID des images originales
                        List<String> originalImageList = docLinkMap.get(newQLI.SBQQ__Source__c);
                        if(originalImageList != null && !originalImageList.isEmpty()) {
                            for(ContentVersion cdLink : [SELECT Id, ContentDocumentId, PathOnClient, Title, VersionData, category__c FROM ContentVersion 
                                                            WHERE ContentDocumentId IN :originalImageList]) {
                                // Insertion ContentVersion
                                ContentVersion cVersion = new ContentVersion();
                                cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                                cVersion.PathOnClient = cdLink.PathOnClient;
                                cVersion.Title = cdLink.Title;//Name of the file
                                cVersion.VersionData = cdLink.VersionData;//File content
                                cVersion.category__c = cdLink.category__c;
                                insert cVersion;
                                
                                //After saved the Content Verison, get the ContentDocumentId
                                Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                                
                                //Insert ContentDocumentLink
                                ContentDocumentLink fileContentLink = new ContentDocumentLink();
                                fileContentLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                                fileContentLink.LinkedEntityId = newQLI.Id;//Add attachment parentId
                                fileContentLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                                insert fileContentLink;
                                System.debug('## New image ContentLink: ' +fileContentLink.Id );
                            }
                        }
                    }
                }
            }
        } catch(exception e) {
            System.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN TR022_SBQQ_QuoteLine.getOriginalImageClonedLine');
    }  

    /**
    * @description Fonction pour mettre à jour les tries des lignes afin de regrouper les lignes parents/enfants
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void updateSortOrder(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.updateSortOrder');
        List<SBQQ__QuoteLine__c> quoteLineItemList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLineItemToUp = new List<SBQQ__QuoteLine__c>();
        List<String> quoteIds = new List<String>();
        
        try {
            // A - Initialisation des données intermédiaires 
            for (SBQQ__QuoteLine__c newQLI : (List<SBQQ__QuoteLine__c>)Trigger.new) {
                if(String.isNotBlank(newQLI.SBQQ__RequiredBy__c) && String.isBlank(newQLI.SortOrder__c)) {
                    System.debug('## QLI: ' +newQLI.Id+' / ' +newQLI.Name+' / ' +newQLI.SBQQ__Bundle__c+' / ' +newQLI.SBQQ__Number__c+' / ' +newQLI.SBQQ__RequiredBy__c);
                    quoteIds.add(newQLI.SBQQ__Quote__c);
                }
            }
            
            // B - Traitement
            if(!quoteIds.isEmpty()) {
                quoteLineItemList = [SELECT Id, SBQQ__RequiredBy__c, SBQQ__Number__c FROM SBQQ__QuoteLine__c 
                                                WHERE SBQQ__Quote__c = :quoteIds ORDER BY Name];
                // Création d'une MAP Parent/Enfant
                Map<String, List<String>> parentChildMap = new Map<String, List<String>>();
                List<String> childsList;
                for(SBQQ__QuoteLine__c qli : quoteLineItemList) {
                    if(String.isNotBlank(qli.SBQQ__RequiredBy__c)) {
                        if(parentChildMap.get(qli.SBQQ__RequiredBy__c) == null) {
                            childsList = new List<String>();
                        } else {
                            childsList = parentChildMap.get(qli.SBQQ__RequiredBy__c);
                        }
                        childsList.add(qli.Id);
                        parentChildMap.put(qli.SBQQ__RequiredBy__c, childsList);
                    }
                }
                System.debug('## parentChildMap: ' +parentChildMap);

                // Mise à jour du trie
                Integer indexParent = 1;
                for (SBQQ__QuoteLine__c parentQLI : quoteLineItemList) {
                    // Récupération des parents et MAJ du trie
                    if(String.isBlank(parentQLI.SBQQ__RequiredBy__c)) {
                        System.debug('## Parent: '+parentQLI.Id+' / '+indexParent);
                        SBQQ__QuoteLine__c newParentQLI = new SBQQ__QuoteLine__c(Id = parentQLI.Id, SortOrder__c = String.valueOf(indexParent));   
                        quoteLineItemToUp.add(newParentQLI);
                        // Récupération des enfants et MAJ du trie
                        if(parentChildMap.get(parentQLI.Id) != null) {
                            Integer indexChild = 1;
                            for (String childQLIId : parentChildMap.get(parentQLI.Id)) {
                                System.debug('## Child: '+childQLIId+' / '+indexChild);
                                String sortText = indexParent+'-'+indexChild;
                                SBQQ__QuoteLine__c newChildQLI = new SBQQ__QuoteLine__c(Id = childQLIId, SortOrder__c = sortText);   
                                quoteLineItemToUp.add(newChildQLI);
                                indexChild++;
                            }
                        }
                        System.debug('## ------------------');
                        indexParent++;
                    }
                }
            }

            // C - Mise à jour
            if(!quoteLineItemToUp.isEmpty()) {
                update quoteLineItemToUp;
            }
        } catch(exception e) {
            System.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN TR022_SBQQ_QuoteLine.updateSortOrder');
    }

    /**
    * @description Mise à jour des garanties des lignes de devis CPQ
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void createWarrantiesRecords(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.createWarrantiesRecords');
        Set<Id> ligneDevisIdList = new Set<Id>();
        List<SBQQ__QuoteLine__c> quoteLineToUpdate = new List<SBQQ__QuoteLine__c>();
        
        try {
            for (SBQQ__QuoteLine__c newQLI : (List<SBQQ__QuoteLine__c>)Trigger.new) {
                if (Trigger.isAfter && (Trigger.isInsert ) 
                    && String.isNotBlank(newQLI.Id) 
                    && !AlreadyUsed.isUsed('TR022_SBQQ_QuoteLine.createWarrantiesRecords', newQLI.Id)) 
                {
                    ligneDevisIdList.add(newQLI.Id);
                }
            }
            // Appel de la fonction asynchrone pour gérer les garanties
            if(!ligneDevisIdList.isEmpty()) {
                QA_CreateWarrantiesRecordsAsync createWarrantiesRecordsAsync = new QA_CreateWarrantiesRecordsAsync(ligneDevisIdList);
                System.enqueueJob(createWarrantiesRecordsAsync);
            }
        } catch(exception e) {
            System.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
        System.debug('### FIN TR022_SBQQ_QuoteLine.createWarrantiesRecords');
    }
    
    /**
    * @description Supprime les garanties si une ligne de devis est supprimée
    * @param qliList Liste des lignes supprimées
    */
    public static void deleteWarrantiesRecords(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.deleteWarrantiesRecords');
        Set<String> quoteLineDeletedId = new Set<String>();

        for (SBQQ__QuoteLine__c oldQli : (List<SBQQ__QuoteLine__c>)Trigger.old) {
            if (Trigger.isDelete && String.isNotBlank(oldQli.Id)) {
                quoteLineDeletedId.add(oldQli.Id);
            }
        }
        System.debug('## QuoteLine supprimées: '+quoteLineDeletedId);
        
        // SOQL - On récupère les garanties à supprimer
        if(!quoteLineDeletedId.isEmpty()) {
            List<Entitlement> warrantiesToDelete = [SELECT Id FROM Entitlement WHERE quoteLineCPQ__c IN :quoteLineDeletedId];
            if(!warrantiesToDelete.isEmpty()) {
                System.debug('## Suppression des garanties: '+warrantiesToDelete);
                delete warrantiesToDelete;
            }
        }
        System.debug('### FIN TR022_SBQQ_QuoteLine.deleteWarrantiesRecords');
    }

    /**
    * @description Supprime les lignes de devis enfant si une ligne de devis est supprimée
    * @param qliList Liste des lignes supprimées
    */
    public static void deleteChildrenQuoteLines(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.deleteChildrenQuoteLines');
        Set<String> quoteLineDeletedId = new Set<String>();

        for (SBQQ__QuoteLine__c oldQli : (List<SBQQ__QuoteLine__c>)Trigger.old) {
            if (Trigger.isDelete && String.isNotBlank(oldQli.Id) && oldQli.isParent__c) {
                quoteLineDeletedId.add(oldQli.Id);
            }
        }
        System.debug('## QuoteLine parent supprimées: '+quoteLineDeletedId);
        
        // SOQL - On récupère les lignes enfant à supprimer
        if(!quoteLineDeletedId.isEmpty()) {
            List<SBQQ__QuoteLine__c> childrenQLToDelete = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c IN :quoteLineDeletedId];
            if(!childrenQLToDelete.isEmpty()) {
                System.debug('## Suppression des lignes enfant: '+childrenQLToDelete);
                Database.delete(childrenQLToDelete, false);
            }
        }
        System.debug('### FIN TR022_SBQQ_QuoteLine.deleteChildrenQuoteLines');
    }
    
    /**
    * @description Mise à jour de la ligne parent
    * @param qliList Liste des lignes supprimées
    */
    public static void updateParentQuoteLine(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.updateParentQuoteLine');
        
        List<SBQQ__QuoteLine__c> quoteLineItemParentList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLineItemToUp = new List<SBQQ__QuoteLine__c>();
        List<String> quoteIds = new List<String>();
        
        // A - Initialisation des données intermédiaires 
        for (SBQQ__QuoteLine__c newQLI : (List<SBQQ__QuoteLine__c>)Trigger.new) {
            if(String.isNotBlank(newQLI.SBQQ__RequiredBy__c) && !AlreadyUsed.isUsed('TR022_SBQQ_QuoteLine.updateParentQuoteLine', newQLI.Id)) {
                System.debug('## QLI: ' +newQLI.Id+' / ' +newQLI.Name+' / ' +newQLI.SBQQ__Bundle__c+' / ' +newQLI.SBQQ__Number__c+' / ' +newQLI.SBQQ__RequiredBy__c);
                quoteIds.add(newQLI.SBQQ__RequiredBy__c);
            }
        }
                
        // SOQL - On récupère les lignes parents à modifier
        if(!quoteIds.isEmpty()) {
            quoteLineItemParentList = [SELECT Id, minDelayAllLine__c, maxDelayAllLine__c FROM SBQQ__QuoteLine__c WHERE Id IN: quoteIds];
        }

        // B - Traitement
        for (SBQQ__QuoteLine__c newQLI : (List<SBQQ__QuoteLine__c>)Trigger.new) {
            if(!quoteIds.isEmpty()) {
                for(SBQQ__QuoteLine__c qliParent : quoteLineItemParentList) {
                    if(qliParent.Id == newQLI.SBQQ__RequiredBy__c) {
                        System.debug('## QLI: ' +newQLI.Id+' / ' +newQLI.Name+' / ' +newQLI.minCommercialDelay__c+' / ' +newQLI.maxCommercialDelay__c);
                        System.debug('## qliParent: ' +qliParent.Id+' / ' +qliParent.minDelayAllLine__c+' / ' +qliParent.maxDelayAllLine__c);
                        if(newQLI.minCommercialDelay__c > qliParent.minDelayAllLine__c || newQLI.maxCommercialDelay__c > qliParent.maxDelayAllLine__c) {
                            if(newQLI.minCommercialDelay__c > qliParent.minDelayAllLine__c) {
                                qliParent.minDelayAllLine__c = newQLI.minCommercialDelay__c;
                            }
                            if(newQLI.maxCommercialDelay__c > qliParent.maxDelayAllLine__c) {
                                qliParent.maxDelayAllLine__c = newQLI.maxCommercialDelay__c;
                            }
                            if(!quoteLineItemToUp.contains(qliParent)){
                                quoteLineItemToUp.add(qliParent); 
                                System.debug('## Add to the list: ' +qliParent.Id);
                            }
                        }
                    }
                }
            }
        }
     
        if(!quoteLineItemToUp.isEmpty()) {
            update quoteLineItemToUp;
        }
        
        System.debug('### FIN TR022_SBQQ_QuoteLine.updateParentQuoteLine');
    }

    /**
    * @description Suppression des commissions prévisionelles
    * @param userContext Contexte utilisateur
    */
    public static void deleteCommissionsPrev(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.deleteCommissionsPrev');
        
        List<NRV10Commission__c> commissionsToDelete = new List<NRV10Commission__c>();
        List<NRV10Commission__c> commissionsList = new List<NRV10Commission__c>();
        List<String> quoteLineIds = new List<String>();
        
        // A - Initialisation des données intermédiaires 
        for (SBQQ__QuoteLine__c oldQLI : (List<SBQQ__QuoteLine__c>)Trigger.old) {
            if(!AlreadyUsed.isUsed('TR022_SBQQ_QuoteLine.deleteCommissionsPrev', oldQLI.Id)) {
                System.debug('## QLI: ' +oldQLI.Id+' / ' +oldQLI.Name+' / ' +oldQLI.SBQQ__Bundle__c+' / ' +oldQLI.SBQQ__Number__c+' / ' +oldQLI.SBQQ__RequiredBy__c);
                quoteLineIds.add(oldQLI.Id);
            }
        }

        system.debug('quoteLineIds : '+quoteLineIds);
                
        // SOQL - On récupère les commissions
        if(!quoteLineIds.isEmpty()) {
            commissionsList = [SELECT Id, quoteLine__c, status__c, productCom__c
                                    FROM NRV10Commission__c 
                                    WHERE quoteLine__c IN: quoteLineIds OR productCom__c IN: quoteLineIds];
        }

        // B - Traitement
        for (SBQQ__QuoteLine__c oldQLI : (List<SBQQ__QuoteLine__c>)Trigger.old) {
            if(!quoteLineIds.isEmpty()) {
                for(NRV10Commission__c com : commissionsList) {
                    if(com.quoteLine__c == oldQLI.Id || com.productCom__c == oldQLI.Id){      
                        if(com.status__c == Constants.COMMISSION_STATUS_PREVISIONEL){
                            commissionsToDelete.add(com);
                        }   
                    }
                }
            }
        }
        
        if(!commissionsToDelete.isEmpty()) {
            delete commissionsToDelete;
        }
        
        System.debug('### FIN TR022_SBQQ_QuoteLine.deleteCommissionsPrev');
    }

    /**
    * @description Met à jour le champ Coefficients Acoustiques de la ligne de devis parente à la création / modification d'une des lignes de devis en option
    * @param userContext Contexte utilisateur
    */
    public static void updateAcousticCoefficients(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_SBQQ_QuoteLine.updateAcousticCoefficients');
        Set<Id> parentQuoteLineItemIdList = new Set<Id>();
        List<SBQQ__QuoteLine__c> quoteLineItemToUp = new List<SBQQ__QuoteLine__c>();
        Set<Id> productIdList = new Set<Id>();
        Map<String, List<SBQQ__QuoteLine__c>> mapQLIChild = new Map<String, List<SBQQ__QuoteLine__c>>();
        Map<Id,List<Referencial__c>> mapAccousticCoefficients = new Map<Id,List<Referencial__c>>();
        

        // A - Initialisation des données intermédiaires 
        for (SBQQ__QuoteLine__c newQLI : (List<SBQQ__QuoteLine__c>)Trigger.new) {
            if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) 
                    && String.isNotBlank(newQLI.Id)
                    && newQLI.SBQQ__RequiredBy__c !=null 
                    && !AlreadyUsed.isUsed('TR022_SBQQ_QuoteLine.updateAccousticCoefficients', newQLI.Id)) 
            {
                //Liste des Id des ligne de devis parents
                parentQuoteLineItemIdList.add(newQLI.SBQQ__RequiredBy__c);                
            }
        }

        if(!parentQuoteLineItemIdList.isEmpty()) {

            //Récupération de toutes les ligne de devis en option pour chaque ligne de devis parente
            List<SBQQ__QuoteLine__c> listQLIChild = [SELECT Id, SBQQ__requiredBy__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__requiredBy__c IN:parentQuoteLineItemIdList];
            for (String qId : parentQuoteLineItemIdList) {
                List<SBQQ__QuoteLine__c> childsList = new List<SBQQ__QuoteLine__c>();
                for (SBQQ__QuoteLine__c quoteLineT : listQLIChild) {
                    if(quoteLineT.SBQQ__requiredBy__c == qId) {
                        childsList.add(quoteLineT);
                    }
                }
                mapQLIChild.put(qId, childsList);
            }
            System.debug('## mapQLIChild:'+mapQLIChild);

            // Récupération des informations des lignes parentes
            List<SBQQ__QuoteLine__c> listParentQLI = [SELECT Id, Name, SBQQ__Product__c, AccousticsCoefficients__c, SBQQ__ProductCode__c FROM SBQQ__QuoteLine__c WHERE Id IN:parentQuoteLineItemIdList];
            if(listParentQLI!=null && !listParentQLI.isEmpty()){
                for(SBQQ__QuoteLine__c qliParent : listParentQLI){
                    //Liste des produits associés aux lignes de devis parentes
                    productIdList.Add(qliParent.SBQQ__Product__c);
                }
            }

            //Récupération Référentiel Coéfficients Acoustiques
            if(!mapQLIChild.isEmpty() && !productIdList.isEmpty()){
                String accousticCoefficientRTId = DAL.getRecordTypeIdByDevName('Referencial__c', 'ProductAcousticCoefficient');
                System.debug('## productIdList :'+productIdList);
                //Récupération des réferentiel correspondant aux produits associés aux ligne de devis parentes
                List<Referencial__c> refRecordsList = [SELECT Id, product__c, option__c, valueRW__c, valueRATR__c, valueRA__c
                                                        FROM Referencial__c 
                                                    WHERE RecordTypeId = :accousticCoefficientRTId AND product__c IN:productIdList];
                if(!refRecordsList.isEmpty()){
                    for(Referencial__c refrecord : refRecordsList){
                        if(!mapAccousticCoefficients.ContainsKey(refrecord.product__c)){
                            List<Referencial__c> newValue = new List<Referencial__c>{refrecord};
                            mapAccousticCoefficients.put(refrecord.product__c, newValue);
                        }
                        else {
                            mapAccousticCoefficients.get(refrecord.product__c).add(refrecord);
                        }
                    }
                }
            }
            System.debug('## mapAccousticCoefficients'+mapAccousticCoefficients);

            // B - Traitement
            //Pour chaque ligne de devis parent récupérées
            for(SBQQ__QuoteLine__c parentQLI : listParentQLI){
                System.debug('## ------------------- QLI: ' + parentQLI.Id+' / '+parentQLI.SBQQ__ProductCode__c+' / '+parentQLI.Name);
                //Liste des lignes en options
                List<SBQQ__QuoteLine__c> qliChildren = mapQLIChild.get(parentQLI.Id);
                if(!mapAccousticCoefficients.isEmpty() && qliChildren!=null){
                    System.debug('## check AccousticCoef');
                    String acousticCoefficientValues = '';
                    //récpération des coefficients correspondants au produit de la ligne parent
                    List<Referencial__c> refAcousticCoefficients = mapAccousticCoefficients.get(parentQLI.SBQQ__Product__c);
                    if(refAcousticCoefficients!=null){
                        //Pour chaque referentiels recupérés
                        for(Referencial__c refRecord : refAcousticCoefficients){
                            //Vérif si option présente sur ligne de devis
                            for(SBQQ__QuoteLine__c qliChild : qliChildren){
                                if(qliChild.SBQQ__Product__c == refRecord.option__c){
                                    //Si option correspond on récupère les valeurs et on arrete la boucle (pas possible d'avoir plusieurs options correspondantes avec coeff acoustiques)
                                    if(refRecord.valueRW__c != null){
                                        acousticCoefficientValues += 'Rw: '+refRecord.valueRW__c + 'dB';
                                        if(refRecord.valueRA__c !=null || refRecord.valueRATR__c !=null){
                                            acousticCoefficientValues += ' ; ';
                                        }
                                    }
                                    if(refRecord.valueRA__c != null){
                                        acousticCoefficientValues += 'Ra: '+refRecord.valueRA__c + 'dB';
                                        if(refRecord.valueRATR__c !=null){
                                            acousticCoefficientValues += ' ; ';
                                        }
                                    }
                                    if(refRecord.valueRATR__c != null){
                                        acousticCoefficientValues += 'Ratr: '+refRecord.valueRATR__c + 'dB';
                                    }
                                    System.debug('## acousticCoeff found :'+acousticCoefficientValues);
                                    break;
                                }                                
                            }
                            if(acousticCoefficientValues != ''){
                                break;
                            }
                        }
                    }

                    //Si valeur de coeff acoustiques différente sur la ligne parent on met à a jour la valeur
                    if(parentQLI.AccousticsCoefficients__c != acousticCoefficientValues){
                        parentQLI.AccousticsCoefficients__c = acousticCoefficientValues;
                        quoteLineItemToUp.Add(parentQLI);
                    }
                }

            }
        }

        // C - Mise à jour des lignes de devis
        if(!quoteLineItemToUp.isEmpty()) {
            update quoteLineItemToUp;
        }

        System.debug('### FIN TR022_SBQQ_QuoteLine.updateAcousticCoefficients');
    }
}