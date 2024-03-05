//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_SBQQ_QuoteLine
//-- Modifié par : Franck GOURDEAUX
//-- Modifié le  : 20/04/2023
//-- Version     : 1.1
//-- * 1.1 : Modification des conditions lignes 154 et 168 sur détermination des délais commerciaux en étapes 2 & 3
//-- * 1.0 :  Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class TR020_SBQQ_QuoteLine {
    
    /**
    * @description Méthode exécutant les règles de validation pour les lignes de devis
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_SBQQ_QuoteLine.applyValidationRules');   
        if (!Trigger.isExecuting) {
            return;
        }

        List<SBQQ__QuoteLine__c> oldQuoteLines = (List<SBQQ__QuoteLine__c>)Trigger.old;
        List<String> quoteIdsList = new List<String>();

        // Pas autorisé à supprimer une ligne si le devis n'est pas à "A configurer" ou si lié à une commmande fournisseur ou à une ligne avenant
        if (Trigger.isDelete) {
            for (SBQQ__QuoteLine__c oldQuoteLine : oldQuoteLines) {
                if(oldQuoteLine.amendInitialQuoteline__c != null && oldQuoteLine.isParent__c){
                    System.debug('## Cannot delete QuoteLine : ' + oldQuoteLine.Id);
                    oldQuoteLine.addError('Une ligne de devis provenant du devis initial ne peux pas être suprimée.');
                } 
                if(oldQuoteLine.quoteLineDeletable__c == false) {
                    System.debug('## Cannot delete QuoteLine : ' + oldQuoteLine.Id);
                    oldQuoteLine.addError(Label.quote_error_cantDeleteQuoteLine);
                }  
            }
        }
        System.debug('### FIN TR020_SBQQ_QuoteLine.applyValidationRules');   
    }
    
    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les lignes de devis CPQ
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_SBQQ_QuoteLine : applyUpdateRules');
        /** A - Initialisation des données intermédiaires **/
        List<SBQQ__QuoteLine__c> quoteLinesItemsRemise = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesItemsCEE = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesAsset = new List<SBQQ__QuoteLine__c>();
        List<String> quoteLinesAssetInitId = new List<String>();
        Map<String, Boolean> quoteLinesReconfMap = new Map<String, Boolean>();
        Map<Id, SBQQ__QuoteLine__c>  oldQuoteLinesItems = (Map<Id, SBQQ__QuoteLine__c>)Trigger.oldMap;
        List<Date> referenceDateList = new List<Date>();
        Map<String, Referencial__c> mapMargin = new Map<String, Referencial__c>();
        Map<String, Referencial__c> mapDelivery = new Map<String, Referencial__c>();
        List<String> quoteLineItemIds = new List<String>();
        Map<String, List<SBQQ__QuoteLine__c>> mapQLIChild = new Map<String, List<SBQQ__QuoteLine__c>>();

        for (SBQQ__QuoteLine__c newQuoteLineItem : (List<SBQQ__QuoteLine__c>)Trigger.new) {
            SBQQ__QuoteLine__c oldQuoteLineItem = oldQuoteLinesItems == null ? null : oldQuoteLinesItems.get(newQuoteLineItem.id);

            if (!AlreadyUsed.isUsed('TR020_SBQQ_QuoteLine.applyUpdateRules', newQuoteLineItem.Id)) {
                // Vérification si actif commandé pour reconfigurable pour les devis avenants
                if((Trigger.isInsert || Trigger.isUpdate) && String.isNotBlank(newQuoteLineItem.amendInitialQuoteline__c) && String.isNotBlank(newQuoteLineItem.Id)) {
                    System.debug('## Check Assets: ' + newQuoteLineItem.Id+ ' / '+newQuoteLineItem.SBQQ__ProductCode__c);
                    quoteLinesAsset.add(newQuoteLineItem);
                    quoteLinesAssetInitId.add(newQuoteLineItem.amendInitialQuoteline__c);
                }

                // Prime CEE
                if(!newQuoteLineItem.eligibleCEE__c) {
                    newQuoteLineItem.montantCEE__c = null;
                } else {
                    quoteLinesItemsCEE.add(newQuoteLineItem);
                }
            }

            // Délai + RBE
            if( (Trigger.isInsert || (Trigger.isUpdate && (newQuoteLineItem.productSubMaterial__c != oldQuoteLineItem.productSubMaterial__c || newQuoteLineItem.productSubFamily__c != oldQuoteLineItem.productSubFamily__c || newQuoteLineItem.referenceDate__c != oldQuoteLineItem.referenceDate__c)))  
                && newQuoteLineItem.referenceDate__c != null ) {
                referenceDateList.add(newQuoteLineItem.referenceDate__c);
            }
            
            if(((Trigger.isInsert && Trigger.isAfter) || Trigger.isUpdate)  && newQuoteLineItem.isParent__c == true 
                && String.isNotBlank(newQuoteLineItem.Id)) 
            {
                quoteLineItemIds.add(newQuoteLineItem.Id);
            }      
            
            newQuoteLineItem.kbmaxAPISent__c = false;
        }
        
        // Récupération des lignes enfants
        if(!quoteLineItemIds.isEmpty()) {
            List<SBQQ__QuoteLine__c> listQLIChild = [SELECT Id, SBQQ__requiredBy__c, minCommercialDelay__c, maxCommercialDelay__c FROM SBQQ__QuoteLine__c WHERE SBQQ__requiredBy__c IN:quoteLineItemIds];
            for (String qId : quoteLineItemIds) {
                List<SBQQ__QuoteLine__c> childsList = new List<SBQQ__QuoteLine__c>();
                for (SBQQ__QuoteLine__c quoteLineT : listQLIChild) {
                    if(quoteLineT.SBQQ__requiredBy__c == qId) {
                        childsList.add(quoteLineT);
                    }
                }
                mapQLIChild.put(qId, childsList);
            }
        }
        
        // Récupération référentiel des marges RBE
        if(!referenceDateList.isEmpty()) {
            System.debug('## Get Referencial for RBE and Delay');  
            String catalogMarginRTId = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_CATALOGMARGIN_RT);
            String providerDeliveryDelayRTId = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);

            // Récupération référentiel RBE et Delai
            List<Referencial__c> refRecordsList = [SELECT Id, margin__c, maxCommercialDelay__c, minCommercialDelay__c, startDate__c, 
                                                        productSubFamily__c, endDate__c, providerDelayType__c, RecordTypeId, productSubMaterial__c 
                                                    FROM Referencial__c 
                                                WHERE (RecordTypeId = :catalogMarginRTId OR RecordTypeId = :providerDeliveryDelayRTId)];
            // Mappging entre le référentiel et les lignes
            for(SBQQ__QuoteLine__c newQuoteLineItem : (List<SBQQ__QuoteLine__c>)Trigger.new) {
                System.debug('## QLI: ' + newQuoteLineItem.Id+' / '+newQuoteLineItem.SBQQ__Product__c+' / '+newQuoteLineItem.SBQQ__ProductCode__c+' / '+newQuoteLineItem.Name
                                +' / '+newQuoteLineItem.productSubMaterial__c+' / '+newQuoteLineItem.productSubFamily__c);
                 // Indique si la ligne à un délai de fournisseur
                Boolean providerDelayRef = false;
                // Défini le type de délai à Standard si pas de valeur
                String qliProviderDelayType = (String.isBlank(newQuoteLineItem.providerDelayType__c)) ? 'Standard' : newQuoteLineItem.providerDelayType__c; 
                System.debug('## Provider Delay Type: ' + qliProviderDelayType);
                // Construction clé pour récupération dans les MAP (car le champ ID est null à a la création)
                String key = newQuoteLineItem.SBQQ__Product__c+''+newQuoteLineItem.SBQQ__ProductOption__c; 
                System.debug('## key: ' + key);

                for(Referencial__c ref : refRecordsList) {
                    // Si réf = RBE
                    if(ref.productSubMaterial__c == newQuoteLineItem.productSubMaterial__c && ref.productSubFamily__c == newQuoteLineItem.productSubFamily__c 
                        && ref.startDate__c <= newQuoteLineItem.referenceDate__c && (ref.endDate__c == null || ref.endDate__c >= newQuoteLineItem.referenceDate__c)
                        && ref.RecordTypeId == catalogMarginRTId
                    ) {
                        mapMargin.put(key, ref);
                    }

                    // Si réf = Delai, On recherche en premier selon Sous-famille et Sous-matiere
                    if(ref.productSubMaterial__c == newQuoteLineItem.productSubMaterial__c && ref.productSubFamily__c == newQuoteLineItem.productSubFamily__c
                        && ref.startDate__c <= newQuoteLineItem.quoteDate__c && (ref.endDate__c == null || ref.endDate__c >= newQuoteLineItem.quoteDate__c)
                        && ref.RecordTypeId == providerDeliveryDelayRTId
                        && ref.providerDelayType__c == qliProviderDelayType
                    ) {
                        providerDelayRef = true;
                        mapDelivery.put(key, ref);
                        System.debug('## Delivery: '+ref);  
                    }
                }
                // Si pas de délai fournisseur, 1 : On recherche de nouveau mais seulement selon Sous-matiere 
                if(!providerDelayRef) {
                    for(Referencial__c ref : refRecordsList) {
                        if(ref.productSubMaterial__c == newQuoteLineItem.productSubMaterial__c && (ref.productSubFamily__c == null || ref.productSubFamily__c.trim() == '')
                            && ref.startDate__c <= newQuoteLineItem.quoteDate__c && (ref.endDate__c == null || ref.endDate__c >= newQuoteLineItem.quoteDate__c)
                            && ref.RecordTypeId == providerDeliveryDelayRTId
                            && ref.providerDelayType__c == qliProviderDelayType
                        ) {
                            providerDelayRef = true;
                            mapDelivery.put(key, ref);
                            System.debug('## Delivery 1: '+ref);  
                        }
                    }
                }
                // Si pas de délai fournisseur, 2 : On recherche de nouveau mais seulement selon Sous-famille
                if(!providerDelayRef) {
                    for(Referencial__c ref : refRecordsList) {
                        if(ref.productSubFamily__c == newQuoteLineItem.productSubFamily__c && (ref.productSubMaterial__c == null || ref.productSubMaterial__c.trim() == '')
                            && ref.startDate__c <= newQuoteLineItem.quoteDate__c && (ref.endDate__c == null || ref.endDate__c >= newQuoteLineItem.quoteDate__c)
                            && ref.RecordTypeId == providerDeliveryDelayRTId
                            && ref.providerDelayType__c == qliProviderDelayType
                        ) {
                            providerDelayRef = true;
                            mapDelivery.put(key, ref);
                            System.debug('## Delivery 2: '+ref);  
                        }
                    }
                }
            } 
        }
        
        // B - Mise à jour des lignes
        for(SBQQ__QuoteLine__c newQuoteLineItem : (List<SBQQ__QuoteLine__c>)Trigger.new) {
            SBQQ__QuoteLine__c oldQuoteLineItem = oldQuoteLinesItems == null ? null : oldQuoteLinesItems.get(newQuoteLineItem.id);
            Decimal maxDelayMaxChild = 0;
            Decimal maxDelayMinChild = 0;

            if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
                System.debug('## ------------------- QLI: ' + newQuoteLineItem.Id+' / '+newQuoteLineItem.SBQQ__ProductCode__c+' / '+newQuoteLineItem.Name);
                List<SBQQ__QuoteLine__c> qliChildren = mapQLIChild.get(newQuoteLineItem.Id);
                // Construction clé pour récupération dans les MAP (car le champ ID est null à a la création)
                String refKey = newQuoteLineItem.SBQQ__Product__c+''+newQuoteLineItem.SBQQ__ProductOption__c; 

                // Assignation RecordType                
                if(Trigger.isInsert ||(Trigger.isUpdate && oldQuoteLineItem != null && oldQuoteLineItem.productType__c != newQuoteLineItem.productType__c)) {
                    System.debug('## RT Change: ' + newQuoteLineItem.SBQQ__ProductCode__c + ' / '+newQuoteLineItem.productType__c);
                    // Assignation du RecordType par rapport au champ "productType__c"
                    newQuoteLineItem.RecordTypeId = DAL.getRecordTypeIdByDevName('SBQQ__QuoteLine__c', newQuoteLineItem.productType__c);
                    System.debug('## RT Id: ' + newQuoteLineItem.RecordTypeId);
                }

                // Indicateur options
                newQuoteLineItem.optionsLineCount__c = (qliChildren != null) ? qliChildren.size() : null;

                // Calcul TVA sur ligne parent
                // Remplace la PR Price320Cal qui ne fonctionne pas correctement pas l'ordre d'exécution des PR se fait après les formules
                if(newQuoteLineItem.PrixNetRemiseTTC__c != null && newQuoteLineItem.SBQQ__PackageTotal__c != null 
                    && String.isBlank(newQuoteLineItem.SBQQ__RequiredBy__c) && newQuoteLineItem.quoteStatus__c == Constants.QUOTE_STATUS_TO_CONFIGURE) 
                {
                    System.debug('## Calculate VAT on line: ' + newQuoteLineItem.PrixNetRemiseTTC__c+' / '+newQuoteLineItem.SBQQ__PackageTotal__c);
                    Decimal vatLine = Math.abs(newQuoteLineItem.PrixNetRemiseTTC__c - newQuoteLineItem.SBQQ__PackageTotal__c).setScale(2);
                    newQuoteLineItem.VATAmountMedium__c = (newQuoteLineItem.rateType__c == 'Intermédiaire') ? vatLine : 0;
                    newQuoteLineItem.VATAmountLow__c = (newQuoteLineItem.rateType__c == 'Réduit') ? vatLine : 0;
                    newQuoteLineItem.VATAmountHigh__c = (newQuoteLineItem.rateType__c == 'Fort') ? vatLine : 0;
                    newQuoteLineItem.packageVATAmount__c = vatLine;
                    System.debug('## VAT: ' + vatLine);
                }
                
                // Calcul RBE (Seulement sur ligne parent)
                if(!mapMargin.isEmpty() && mapMargin.get(refKey) != null && String.isBlank(newQuoteLineItem.SBQQ__RequiredBy__c)) {
                    Referencial__c margin = mapMargin.get(refKey);
                    System.debug('## Margin: ' + margin);
                    
                    if(margin.margin__c != null && newQuoteLineItem.SBQQ__PackageTotal__c != null && newQuoteLineItem.SBQQ__PackageTotal__c != 0) {
                        newQuoteLineItem.catalogMargin__c = (newQuoteLineItem.SBQQ__PackageListTotal__c * margin.margin__c) / 100;
                        newQuoteLineItem.catalogMarginPercent__c = margin.margin__c;
                        Decimal netMargin = newQuoteLineItem.SBQQ__PackageTotal__c - (newQuoteLineItem.SBQQ__PackageListTotal__c * (1 - (margin.margin__c/100)));
                        newQuoteLineItem.netMargin__c = netMargin;
                        //newQuoteLineItem.netMarginPercent__c = 1 - (newQuoteLineItem.SBQQ__PackageTotal__c - netMargin ) / newQuoteLineItem.SBQQ__PackageTotal__c;
                        newQuoteLineItem.netMarginPercent__c = (netMargin / newQuoteLineItem.SBQQ__PackageTotal__c) * 100;
                        System.debug('## catalogMargin: ' + newQuoteLineItem.catalogMargin__c);
                        System.debug('## netMargin: ' + netMargin);
                        System.debug('## netMarginPercent: ' + newQuoteLineItem.netMarginPercent__c);
                    }
                }

                // Calcul Delai
                if(!mapDelivery.isEmpty() && mapDelivery.get(refKey) != null) {
                    Referencial__c delivery = mapDelivery.get(refKey);
                    newQuoteLineItem.maxCommercialDelay__c = delivery.maxCommercialDelay__c;
                    newQuoteLineItem.minCommercialDelay__c = delivery.minCommercialDelay__c;
                    
                    System.debug('## Delivery: '+delivery.Id+' - '+delivery.minCommercialDelay__c+' / '+delivery.maxCommercialDelay__c);
                }
                
                if(qliChildren != null) {
                    for(SBQQ__QuoteLine__c qli : qliChildren) {
                        if(qli.minCommercialDelay__c > maxDelayMinChild) {
                            maxDelayMinChild = qli.minCommercialDelay__c;
                        }
                        if(qli.maxCommercialDelay__c > maxDelayMaxChild) {
                            maxDelayMaxChild = qli.maxCommercialDelay__c;
                        }
                    }
                    newQuoteLineItem.maxDelaymaxChild__c = maxDelayMaxChild;
                    newQuoteLineItem.maxDelayMinChild__c = maxDelayMinChild;
                    System.debug('## Max Delay of child for QLI: ' + maxDelayMinChild+' / '+maxDelayMaxChild);
                }
                
                if(newQuoteLineItem.minCommercialDelay__c != null && newQuoteLineItem.maxDelayMinChild__c != null) {
                    if(newQuoteLineItem.minCommercialDelay__c > newQuoteLineItem.maxDelayMinChild__c) {
                        newQuoteLineItem.minDelayAllLine__c = newQuoteLineItem.minCommercialDelay__c;
                    } else {
                        newQuoteLineItem.minDelayAllLine__c = newQuoteLineItem.maxDelayMinChild__c;
                    }
                } else if(newQuoteLineItem.minCommercialDelay__c == null && newQuoteLineItem.maxDelayMinChild__c != null) {
                    newQuoteLineItem.minDelayAllLine__c = newQuoteLineItem.maxDelayMinChild__c;
                } else if(newQuoteLineItem.minCommercialDelay__c != null && newQuoteLineItem.maxDelayMinChild__c == null) {
                    newQuoteLineItem.minDelayAllLine__c = newQuoteLineItem.minCommercialDelay__c;
                } else {
                    newQuoteLineItem.minDelayAllLine__c = 0;
                }
                
                if(newQuoteLineItem.maxCommercialDelay__c != null && newQuoteLineItem.maxDelaymaxChild__c != null) {
                    if(newQuoteLineItem.maxCommercialDelay__c > newQuoteLineItem.maxDelaymaxChild__c) {
                        newQuoteLineItem.maxDelayAllLine__c = newQuoteLineItem.maxCommercialDelay__c;
                    } else {
                        newQuoteLineItem.maxDelayAllLine__c = newQuoteLineItem.maxDelaymaxChild__c;
                    }
                } else if(newQuoteLineItem.maxCommercialDelay__c == null && newQuoteLineItem.maxDelaymaxChild__c != null) {
                    newQuoteLineItem.maxDelayAllLine__c = newQuoteLineItem.maxDelaymaxChild__c;
                } else if(newQuoteLineItem.maxCommercialDelay__c != null && newQuoteLineItem.maxDelaymaxChild__c == null) {
                    newQuoteLineItem.maxDelayAllLine__c = newQuoteLineItem.maxCommercialDelay__c;
                } else {
                    newQuoteLineItem.maxDelayAllLine__c = 0;
                }
            }
        }

        // Vérification des actifs commandés et création d'une map par ligne
        if(!quoteLinesAsset.isEmpty()) {
            System.debug('## quoteLinesAsset: ' + quoteLinesAsset);
            for(Asset ast : [SELECT Id, providerOLINotCancelledCount__c, orderItem__r.SBQQ__QuoteLine__c 
                                FROM Asset WHERE orderItem__r.SBQQ__QuoteLine__c IN :quoteLinesAssetInitId]) {
                Boolean isOrdered = (quoteLinesReconfMap.get(ast.orderItem__r.SBQQ__QuoteLine__c)) != null ? quoteLinesReconfMap.get(ast.orderItem__r.SBQQ__QuoteLine__c) : false;
                if(ast.providerOLINotCancelledCount__c > 0 && isOrdered == false) {
                    isOrdered = true;
                }
                quoteLinesReconfMap.put(ast.orderItem__r.SBQQ__QuoteLine__c, isOrdered);
            }
            System.debug('## Asset Ordered: ' + quoteLinesReconfMap);
        }
        
        // Vérification des actifs commandés et création d'une map par ligne
        for (SBQQ__QuoteLine__c newQuoteLineItem : quoteLinesAsset) {
            if(quoteLinesReconfMap.get(newQuoteLineItem.amendInitialQuoteline__c) != null) {
                System.debug('## Check QLI Reconfigured: ' + newQuoteLineItem.Id);
                Boolean isOrdered = quoteLinesReconfMap.get(newQuoteLineItem.amendInitialQuoteline__c);
                if(isOrdered) {
                    newQuoteLineItem.reconfigurable__c = 'Non';
                } else {
                    newQuoteLineItem.reconfigurable__c = 'Oui';
                }
                System.debug('## Reconfigured: ' + newQuoteLineItem.reconfigurable__c);
            }
        }

        // Calcul de la prime CEE
        if (!quoteLinesItemsCEE.isEmpty()) {
            setMontantLignesDevisCEE(quoteLinesItemsCEE);
        }
        
        System.debug('### FIN TR020_SBQQ_QuoteLine : applyUpdateRules');
    }

    /**
    * @description Mise à jour des remises CEE pour les lignes de devis CPQ
    * @param newQuoteLinesItems Liste des lignes de devis
    */
    private static void setMontantLignesDevisCEE(List<SBQQ__QuoteLine__c> newQuoteLinesItems) {
        System.debug('### DEBUT TR020_SBQQ_QuoteLine : setMontantLignesDevisCEE');
        Set<String> quoteIds = new Set<String>();
        Set<String> productIdList = new Set<String>();
        Set<String> tvaTypeList = new Set<String>();
        List<CEE_Prime__c> ceePrimeList = new List<CEE_Prime__c>();
        List<ESCIncentive__c> ceeList = new List<ESCIncentive__c>();
        List<TVA_Produit__c> tvaList = new List<TVA_Produit__c>();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        for(SBQQ__QuoteLine__c qli : newQuoteLinesItems){
            quoteIds.add(qli.SBQQ__Quote__c);
            productIdList.add(qli.SBQQ__Product__c);
        }

        // Récupération des primes présentes dans la base
        //ceePrimeList = [SELECT Id, dateDebutValidite__c, dateFinValidite__c, categorie__c, montant__c, produit__c, zone__c FROM CEE_Prime__c];
        tvaList = [SELECT Id, Type__c, produit__c, dateDebut__c, dateFin__c, taux__c 
                        FROM TVA_Produit__c
                        WHERE produit__c IN :productIdList];

        for(TVA_Produit__c tva : tvaList){
            tvaTypeList.add(tva.Type__c);
        }

        ceeList = [SELECT Id, type__c, startDate__c, endDate__c, minIncomes__c, maxIncomes__c, personNumber__c, geography__c, heatingModes__c, customerAmount__c, officialAmount__c, incomeType__c
                    FROM ESCIncentive__c
                    WHERE type__c IN :tvaTypeList];

        // Récupération données pour calcul
        quoteList = [SELECT Id, referenceDate__c, dateDevis__c, RevenusFiscaux__c, NombrePersonnes__c, Zone__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
        //Map<ID,PricebookEntry> pricebookEntryList = new Map<ID, PricebookEntry>([SELECT Id, Product2Id FROM PricebookEntry WHERE id IN :PricebookEntryIdList]);

        //System.debug('TEST1 : '+ceePrimeList + ' '+pricebookEntryList);

        // Calcul de la prime CEE
        for(SBQQ__Quote__c quote : quoteList){
            Utils_CEE.setQliCEE(newQuoteLinesItems, quote, ceeList, tvaList);
        }   

        System.debug('### FIN TR020_SBQQ_QuoteLine : setMontantLignesDevisCEE');
    }
}