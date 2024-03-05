//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_OrderItem
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 22/09/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_OrderItem {
    private static final String RT_PNC_PROVIDERID = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_PNC_PROVIDER_RT);
    private static final String RT_PUBLICHOLIDAY = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PUBLICHOLIDAY_RT);
    private static final String RT_PROVIDERDELIVERYDELAY = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_PROVIDERDELIVERYDELAY_RT);

    /**
    * @description Méthode exécutant les règles de validation pour les lignes de commande
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyValidationRules(UserContext userContext) {
        System.debug('### DEBUT TR020_OrderItem.applyValidationRules');
        
        /** 1.1 - Init data **/
        List<OrderItem> customerOrderItem = new List<OrderItem>();
        List<OrderItem> providerOrderItem = new List<OrderItem>();

        /** 1.2 - Application des règles de validation (NO DELETE) **/
        if (Trigger.isBefore && Trigger.isUpdate) { 
            List<OrderItem> newOrderItems = (List<OrderItem>)Trigger.new;
            Map<Id, OrderItem> newOrderItemMap = (Map<Id, OrderItem>)Trigger.newMap;
            for(OrderItem newOrderItem : newOrderItems){
                if(newOrderItem.orderRecordType__c == Constants.ORDER_RT_PROVIDER) {
                    providerOrderItem.add(newOrderItem);
                }
                else if(newOrderItem.orderRecordType__c == Constants.ORDER_RT_CUSTOMER) {
                    customerOrderItem.add(newOrderItem);
                }
            }

            //Ligne de commandes fournisseurs
            if(!providerOrderItem.isEmpty() && userContext != null){
                for (OrderItem newOrderItem : providerOrderItem) {
                    //Si le Profil est: K/K - K par K (Données)
                    if(userContext != null && userContext.getProfile().Name == 'K/K - K par K (Données)'){
                        newOrderItemMap.get((newOrderItem.Id)).addError('Votre profil ne dispose pas des droits pour modifier une ligne de commande fournisseur');
                    }
                }
            }

            //Ligne de commandes clients
            if(!customerOrderItem.isEmpty() && userContext != null){
                for (OrderItem newOrderItem : customerOrderItem) {
                    //Si le Profil est: K/K - K par K (Réf/Données)
                    if(userContext != null && userContext.getProfile().Name == 'K/K - K par K (Réf/Données)'){
                        newOrderItemMap.get((newOrderItem.Id)).addError('Votre profil ne dispose pas des droits pour modifier une ligne de commande client');
                    }
                }
            }
        }

        /** 1.3 - Application des règles de validation (DELETE) **/        
        if (Trigger.isBefore && Trigger.isDelete) {
            List<OrderItem> oldOrderItems = (List<OrderItem>)Trigger.old;
            for(OrderItem oldOrderItem : oldOrderItems){
                // Ne pas supprimer si la commande ou l'asset est verrouillé
                if(oldOrderItem.isAssetLocked__c  && oldOrderItem.orderRecordType__c == Constants.ORDER_RT_PROVIDER && Trigger.isDelete && Trigger.isBefore){
                    oldOrderItem.addError(Label.asset_msg_cantDeleteProviderOrderItem);
                } else if(oldOrderItem.isOrderLocked__c && Trigger.isDelete && Trigger.isBefore){
                    oldOrderItem.addError(Label.order_msg_cantDeleteOrderItem);
                }
            }
        }
        
        System.debug('### FIN TR020_OrderItem.applyValidationRules');
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les lignes de commande
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }        
        applyDataUpdateRules(userContext);
        applyStatusUpdateRules(userContext);
    }

    /**
    * @description Méthode exécutant les règles de mise à jour du statut pour les lignes de commande
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyStatusUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_OrderItem : applyStatusUpdateRules');
        
        List<OrderItem> newOrderItems = new List<OrderItem>();
        Map<Id, OrderItem> oldOrderItems = (Map<Id, OrderItem>)Trigger.oldMap;
        
        // A - Initialisation des données intermédiaires 
        for (OrderItem newOrderItem : (List<OrderItem>)Trigger.new) {
            //if (!AlreadyUsed.isUsed('TR020_OrderItem.applyStatusUpdateRules', newOrderItem.id)) {
                newOrderItems.add(newOrderItem);
            //}
        }

        for (OrderItem newOrderItem : newOrderItems) {
            OrderItem oldOrderItem = oldOrderItems == null ? null : oldOrderItems.get(newOrderItem.Id);
            
            // Vérification des valeurs pour le changement de statut
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {   
                System.debug('## Change status for orderitem: ' + newOrderItem.Id);
                if(newOrderItem.cancellationDate__c != null || newOrderItem.orderStatus__c == Constants.ORDER_STATUS_CANCELLED) {
                    System.debug('## status 1');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_CANCELLED;
                    newOrderItem.stageName__c = null;
                    if(newOrderItem.cancellationDate__c == null) {
                        newOrderItem.cancellationDate__c = Date.today();
                    }
                } else if(newOrderItem.receivedDate__c != null) {
                    System.debug('## status 2');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_PAID;
                    newOrderItem.stageName__c = 'Facturation';
                } else if(newOrderItem.billingDate__c != null && newOrderItem.deliveryDate__c != null) {
                    System.debug('## status 3');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_BILLED;
                    newOrderItem.stageName__c = 'Facturation';
                } else if (newOrderItem.deliveryDate__c != null) {
                    System.debug('## status 4');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_RECEIVED;
                    newOrderItem.stageName__c = 'Livraison';
                } else if (newOrderItem.deliveryDate__c == null && newOrderItem.billingDate__c != null) {
                    System.debug('## status 5');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_BILLEDNOTDELIVERED;
                    newOrderItem.stageName__c = 'Livraison';
                } else if (newOrderItem.shippingDate__c != null) {
                    System.debug('## status 6');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_SENT;
                    newOrderItem.stageName__c = 'Livraison';
                } else if (newOrderItem.manufacturingEnd__c != null) {                            
                    System.debug('## status 7');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_BUILT;
                    newOrderItem.stageName__c = 'Fabrication';
                } else if (newOrderItem.manufacturingStart__c != null) {                            
                    System.debug('## status 8');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_BUILDING;
                    newOrderItem.stageName__c = 'Fabrication';
                } else if(newOrderItem.confirmationDate__c != null) {                            
                    System.debug('## status 9');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_CONFIRMED;
                    newOrderItem.stageName__c = 'Confirmation';
                } else if (newOrderItem.transmissionDate__c != null) {
                    System.debug('## status 10');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_TRANSMITTED;
                    newOrderItem.stageName__c = 'Confirmation';
                } else if (newOrderItem.activationDate__c != null) {
                    System.debug('## status 11');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_VALIDATED;
                    newOrderItem.stageName__c = 'Enregistrement';
                } else {
                    System.debug('## status 12');
                    newOrderItem.status__c = Constants.ORDERITEM_STATUS_REGISTERED;
                    newOrderItem.stageName__c = 'Enregistrement';
                }
                System.debug('## OrderItem Status: '+newOrderItem.status__c);
            }
        }
        System.debug('### FIN TR020_OrderItem : applyStatusUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour de données pour les lignes de commande
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyDataUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_OrderItem : applyDataUpdateRules');
        
        List<OrderItem> newOrderItems = new List<OrderItem>();
        Map<Id, OrderItem> oldOrderItems = (Map<Id, OrderItem>)Trigger.oldMap;
        List<String> qliCPQList = new List<String>();
        List<String> assetsIdList = new List<String>();
        List<String> entityIds = new List<String>();
        List<String> providerIds = new List<String>();
        List<EntityProviderParameters__c> entityProviderParametersList = new List<EntityProviderParameters__c>();
        Map<String, SBQQ__QuoteLine__c> qliCPQMap = new Map<String, SBQQ__QuoteLine__c>();
        Map<String, Asset> assetsMap = new Map<String, Asset>();
        List<Referencial__c> refPublicHolidayList = new List<Referencial__c>();
        List<Referencial__c> refDelayList = new List<Referencial__c>();
        List<Case> listCaseToInsert = new List<Case>();
        
        // A - Initialisation des données intermédiaires 
        for (OrderItem newOrderItem : (List<OrderItem>)Trigger.new) {
            //if (!AlreadyUsed.isUsed('TR020_OrderItem.applyDataUpdateRules', newOrderItem.id)) {
                newOrderItems.add(newOrderItem);
            
                // Création d'une ligne de commande à partir d'une ligne de devis CPQ
                if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newOrderItem.SBQQ__QuoteLine__c ) 
                    && newOrderItem.orderRecordType__c == Constants.ORDER_RT_CUSTOMER && String.isBlank(newOrderItem.InitialQuoteLine__c )) 
                {
                    qliCPQList.add(newOrderItem.SBQQ__QuoteLine__c);
                }

                // Alimentation des informations de l'actif sur la ligne de commande fournisseur
                if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newOrderItem.asset__c) && newOrderItem.orderRecordType__c == Constants.ORDER_RT_PROVIDER) {
                    assetsIdList.add(newOrderItem.asset__c);
                }
                // Ligne de commande fournisseur
                if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert) && newOrderItem.orderRecordType__c == Constants.ORDER_RT_PROVIDER) {
                    providerIds.add(newOrderItem.orderProviderId__c);
                    entityIds.add(newOrderItem.orderAccountId__c);
                }
            //}
        }       

        // B - Récupération des enregistrements
        if(!qliCPQList.isEmpty()) {
            for (SBQQ__QuoteLine__c qli : [SELECT Id, packageVATAmount__c, TauxTVAPercent__c , RemiseComplementaire__c, SBQQ__PackageListTotal__c, 
                                            PrixNetRemiseTTC__c, Hauteur__c, NombreVantaux__c, SBQQ__ProductName__c, SortOrder__c, SBQQ__ListPrice__c,
                                            ProductType__c, SBQQ__ProductCode__c, SBQQ__Bundle__c, SBQQ__PackageTotal__c, Largeur__c, unit__c, purchasePrice__c,
                                            caseItem__r.case__r.ProductId, PrixUnitaire__c, RemiseEnseigne__c, comment__c, QuoteLineQuantity__c, SBQQ__Quantity__c,
                                            SBQQ__Description__c, locationPrecision__c, location__c, prixLigneNetDePromoTTC__c, amendInitialQuoteline__c, CoefficientThermique__c,
                                            LibelleProduit__c,quoteLineLabelManual__c
                                            FROM SBQQ__QuoteLine__c WHERE Id IN :qliCPQList]) {
                qliCPQMap.put(qli.Id, qli);
            }
            System.debug('## qliCPQMap: ' + qliCPQMap);
        }
        if(!assetsIdList.isEmpty()) {
            for (Asset ast : [SELECT Id, leaf__c, height__c, width__c, locationPrecision__c, location__c, 
                                    Product2.Name, RecordType.DeveloperName, orderItem__r.QuoteLineItemId, orderItem__r.SBQQ__QuoteLine__c 
                                    FROM Asset WHERE Id IN :assetsIdList]) {
                assetsMap.put(ast.Id, ast);
            }
            System.debug('## assetsMap: ' + assetsMap);
        }
        
        // Récupération du référentiel des délais
        if(!providerIds.isEmpty() && !entityIds.isEmpty()) {
            refPublicHolidayList = [SELECT Id, startDate__c FROM Referencial__c WHERE RecordTypeId =: RT_PUBLICHOLIDAY];
            refDelayList = [SELECT Id, startDate__c, endDate__c, productSubMaterial__c, productSubFamily__c,
                                    providerDelayType__c, contractualDelay__c, concertedDelay__c
                            FROM Referencial__c
                            WHERE RecordTypeId = :RT_PROVIDERDELIVERYDELAY AND (endDate__c > TODAY OR endDate__c = null) AND startDate__c <= TODAY];
            entityProviderParametersList = [SELECT Id, deliveryDays__c, provider__c, entity__c FROM entityProviderParameters__c 
                                            WHERE entity__c IN: entityIds AND provider__c IN: providerIds AND stageName__c = 'En cours'];
        }

        System.debug('## newOrderItems: ' + newOrderItems);
        for (OrderItem newOrderItem : newOrderItems) {
            OrderItem oldOrderItem = oldOrderItems == null ? null : oldOrderItems.get(newOrderItem.Id);
            System.debug('## ------------------- OLI: ' + newOrderItem.Id+' / '+newOrderItem.productCode__c+' / '+newOrderItem.OrderItemNumber);
            
            // COMMANDE CLIENT - Alimentation des données OrderItem
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newOrderItem.SBQQ__QuoteLine__c ) 
                && newOrderItem.orderRecordType__c == Constants.ORDER_RT_CUSTOMER && qliCPQMap.get(newOrderItem.SBQQ__QuoteLine__c) != null) 
            {
                SBQQ__QuoteLine__c qli = qliCPQMap.get(newOrderItem.SBQQ__QuoteLine__c);
                System.debug('## Mise à jour information selon SBQQ__QuoteLine__c : ' + qli.Id);
                System.debug('## PrixUnitaire__c : ' + qli.PrixUnitaire__c);
                newOrderItem.InitialQuoteLine__c = newOrderItem.SBQQ__QuoteLine__c;
                // Prix catalogue de la ligne de devis/option
                //newOrderItem.ListPrice = qli.SBQQ__ListPrice__c; // GENERE ERREUR CAR LISTE PRICE SUR ORDERITEM DOIT ETRE = PRIX PRICEBOOK
                // Prix unitaire HT hors remise de la ligne de devis/option
                newOrderItem.UnitPrice = (qli.PrixUnitaire__c != null) ? qli.PrixUnitaire__c.setScale(2, RoundingMode.HALF_UP) : 0;
                // Remise enseigne unitaire de la ligne de devis/option
                newOrderItem.enseignDiscount__c = (qli.RemiseEnseigne__c != null) ? qli.RemiseEnseigne__c.setScale(2, RoundingMode.HALF_UP) : null;
                // Remise vendeur/complémentaire unitaire de la ligne de devis/option
                newOrderItem.additionalDiscount__c = (qli.RemiseComplementaire__c != null) ? qli.RemiseComplementaire__c.setScale(2, RoundingMode.HALF_UP) : null;
                // Prix total (auto) Prix unitaire/unitPrice * Quantité/quantity
                //totalPrice =
                //newOrderItem.subtotal__c = (qli.SBQQ__Bundle__c == true) ? qli.SBQQ__PackageTotal__c : null;
                // Montant TVA / VATAmount__c = Montant total (HT)/pretaxAmount__c * Taux TVA/VATRate__c
                newOrderItem.VATAmount__c = (qli.packageVATAmount__c != null) ? qli.packageVATAmount__c.setScale(2, RoundingMode.HALF_UP) : null;
                newOrderItem.VATRate__c = qli.TauxTVAPercent__c;
                // Montant total (TTC) / amount__c = Montant total (HT)/pretaxAmount__c + Montant TVA/VATAmount__c
                newOrderItem.amount__c = (qli.PrixNetRemiseTTC__c != null) ? qli.PrixNetRemiseTTC__c.setScale(2, RoundingMode.HALF_UP) : null;
                // Montant total (HT) / pretaxAmount__c = (Prix unitaire/unitPrice - Remise enseigne/enseignDiscount__c - Remise complémentaire/additionalDiscount__c) * Quantité/quantity // Ancien nom de Sous-total/subTotal__c
                newOrderItem.pretaxAmount__c = (qli.SBQQ__PackageTotal__c != null) ? qli.SBQQ__PackageTotal__c.setScale(2, RoundingMode.HALF_UP) : null;
                newOrderItem.purchasePrice__c = (qli.purchasePrice__c != null) ? qli.purchasePrice__c.setScale(2, RoundingMode.HALF_UP) : null;
                
                /** NE PAS ALIMENTER QUANTITY SINON ERREUR SI AVENANT 
                // Si avenant, on alimente OrderedQuantity sinon Quantity 
                // Si on modifie Quantity en avenant = Erreur
                if(String.isBlank(qli.amendInitialQuoteline__c)) {
                    newOrderItem.Quantity = qli.QuoteLineQuantity__c;
                } */
                newOrderItem.unit__c = qli.unit__c;
                newOrderItem.orderItemQuantity__c = qli.QuoteLineQuantity__c;
                newOrderItem.leaf__c = qli.NombreVantaux__c;
                newOrderItem.width__c = qli.Largeur__c;
                newOrderItem.height__c = qli.Hauteur__c;
                newOrderItem.locationPrecision__c = qli.locationPrecision__c;
                newOrderItem.location__c = qli.location__c;
                if (qli.SBQQ__ProductCode__c.contains('OPLIBR')) {
                    newOrderItem.name__c = qli.quoteLineLabelManual__c;
                } else {
                    newOrderItem.name__c = qli.SBQQ__ProductName__c;
                }
                newOrderItem.productType__c = qli.productType__c;
                newOrderItem.reference__c = qli.SBQQ__ProductCode__c;
                newOrderItem.parentOrderItem__c = newOrderItem.SBQQ__RequiredBy__c;
                newOrderItem.SortOrder__c = qli.SortOrder__c;
                newOrderItem.comment__c = qli.comment__c;
                newOrderItem.Description = qli.SBQQ__Description__c;
                newOrderItem.thermalCoefficients__c = qli.CoefficientThermique__c;
            }
            
            // COMMANDE FOURNISSEUR - Alimentation des données OrderItem
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newOrderItem.asset__c) 
                && newOrderItem.orderRecordType__c == Constants.ORDER_RT_PROVIDER && assetsMap.get(newOrderItem.asset__c) != null) 
            {
                Asset ast = assetsMap.get(newOrderItem.asset__c);
                System.debug('## Mise à jour information selon Asset : ' + ast.Id);
                newOrderItem.height__c = ast.height__c;
                newOrderItem.leaf__c = ast.leaf__c;
                newOrderItem.locationPrecision__c = ast.locationPrecision__c;
                newOrderItem.location__c = ast.location__c;
                newOrderItem.width__c = ast.width__c;
                newOrderItem.name__c = ast.Product2.Name;
                newOrderItem.productType__c = ast.RecordType.DeveloperName;     
                newOrderItem.QuoteLineItemId = ast.orderItem__r.QuoteLineItemId;    
                newOrderItem.SBQQ__QuoteLine__c = ast.orderItem__r.SBQQ__QuoteLine__c;        
            }

            // COMMANDE FOURNISSEUR - Autre traitements
            if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert) && newOrderItem.orderRecordType__c == Constants.ORDER_RT_PROVIDER) {
                // COMMANDE FOURNISSEUR - Calcul du prix unitaire de la ligne
                if(newOrderItem.productCost__c != null) {
                    newOrderItem.UnitPrice = newOrderItem.productCost__c / newOrderItem.Quantity;
                } else if(newOrderItem.estimatedProductCost__c != null) {
                    newOrderItem.UnitPrice = newOrderItem.estimatedProductCost__c / newOrderItem.Quantity;
                } else {
                    newOrderItem.UnitPrice = 0;
                }
                newOrderItem.pretaxAmount__c = newOrderItem.TotalPrice;
                
                // COMMANDE FOURNISSEUR - Délai de livraison
                Referencial__c oliDelivery = null;
                // Indique si la ligne à un délai de fournisseur
                Boolean providerDelayRef = false;
                for(Referencial__c refDelay : refDelayList) {
                    // On recherche en premier selon Sous-famille et Sous-matiere
                    if(refDelay.productSubMaterial__c == newOrderItem.productSubMaterial__c && refDelay.productSubFamily__c == newOrderItem.productSubFamily__c
                        && refDelay.startDate__c <= newOrderItem.orderEffectiveDate__c && (refDelay.endDate__c == null || refDelay.endDate__c >= newOrderItem.orderEffectiveDate__c)
                        && refDelay.providerDelayType__c == 'Standard'
                    ) {
                        providerDelayRef = true;
                        oliDelivery = refDelay;
                        System.debug('## Delivery: '+refDelay);  
                    }
                }
                // Si pas de délai fournisseur, 1 : On recherche de nouveau mais seulement selon Sous-matiere 
                if(!providerDelayRef) {
                    for(Referencial__c refDelay : refDelayList) {
                        if(refDelay.productSubMaterial__c == newOrderItem.productSubMaterial__c
                            && refDelay.startDate__c <= newOrderItem.orderEffectiveDate__c && (refDelay.endDate__c == null || refDelay.endDate__c >= newOrderItem.orderEffectiveDate__c)
                            && refDelay.providerDelayType__c == 'Standard'
                        ) {
                            providerDelayRef = true;
                            oliDelivery = refDelay;
                            System.debug('## Delivery 1: '+refDelay);  
                        }
                    }
                }
                // Si pas de délai fournisseur, 2 : On recherche de nouveau mais seulement selon Sous-famille
                if(!providerDelayRef) {
                    for(Referencial__c refDelay : refDelayList) {
                        if(refDelay.productSubFamily__c == newOrderItem.productSubFamily__c
                            && refDelay.startDate__c <= newOrderItem.orderEffectiveDate__c && (refDelay.endDate__c == null || refDelay.endDate__c >= newOrderItem.orderEffectiveDate__c)
                            && refDelay.providerDelayType__c == 'Standard'
                        ) {
                            providerDelayRef = true;
                            oliDelivery = refDelay;
                            System.debug('## Delivery 2: '+refDelay);  
                        }
                    }
                }
                // Alimentation du délai sur la ligne
                if(oliDelivery != null) {
                    if(oliDelivery.concertedDelay__c != null && oliDelivery.concertedDelay__c > 0) {
                        newOrderItem.contractualDeliveryDelay__c = oliDelivery.concertedDelay__c;
                    } else if(oliDelivery.contractualDelay__c != null && oliDelivery.contractualDelay__c > 0) {
                        newOrderItem.contractualDeliveryDelay__c = oliDelivery.contractualDelay__c;
                    } else {
                        newOrderItem.contractualDeliveryDelay__c = 0;
                    }
                }

                // COMMANDE FOURNISSEUR - Calcul de la date de livraison selon le délai et les jours fériés du fournisseur
                List<Date> listPublicHoliday = new List<Date>();
                for(Referencial__c refPublicHoliday : refPublicHolidayList) {
                    listPublicHoliday.add(refPublicHoliday.startDate__c);
                }
                List<String> deliveryDaysList = new List<String>();
                System.debug('###### newOrderItem.orderServiceEntityId__c' + newOrderItem.orderServiceEntityId__c);
                System.debug('###### newOrderItem.orderProviderId__c' + newOrderItem.orderProviderId__c);
                
                for(EntityProviderParameters__c ePP : entityProviderParametersList) {
                    if(newOrderItem.orderAccountId__c == ePP.entity__c && newOrderItem.orderProviderId__c == ePP.provider__c) {
                        deliveryDaysList.addAll(ePP.deliveryDays__c.split(';'));
                        System.debug('###### ePP.deliveryDays__c' + ePP.deliveryDays__c);
                    }
                }
                if(newOrderItem.contractualDeliveryDelay__c != null && newOrderItem.confirmationDate__c != null && !deliveryDaysList.isEmpty()) {
                    Date potentialContractualDeliveryDate = newOrderItem.confirmationDate__c.addDays(7*newOrderItem.contractualDeliveryDelay__c.intValue());
                    Datetime dtPotential = newOrderItem.confirmationDate__c.addDays(7*newOrderItem.contractualDeliveryDelay__c.intValue());
                    //Détermination de la date contractuelle
                    do {
                        System.debug(listPublicHoliday.contains(potentialContractualDeliveryDate));
                        if(listPublicHoliday.contains(potentialContractualDeliveryDate) == true) {
                            potentialContractualDeliveryDate = potentialContractualDeliveryDate.addDays(1);
                            dtPotential = dtPotential.addDays(1);
                        }
                        if(deliveryDaysList.contains(dtPotential.format('E')) == false) {
                            potentialContractualDeliveryDate = potentialContractualDeliveryDate.addDays(1);
                            dtPotential = dtPotential.addDays(1);
                        }
                        if(listPublicHoliday.contains(potentialContractualDeliveryDate) == false && deliveryDaysList.contains(dtPotential.format('E'))) {
                            newOrderItem.contractualDeliveryDate__c = potentialContractualDeliveryDate;
                        }
                    } while (newOrderItem.contractualDeliveryDate__c == null);
                }
                
                // COMMANDE FOURNISSEUR - Creation NCP Fournisseur si responsabilité NCP Interne = Fabrication
                if(Trigger.isUpdate && newOrderItem.deliveryDate__c != oldOrderItem.deliveryDate__c && oldOrderItem.estimatedDeliveryDate__c != null && newOrderItem.deliveryDate__c != null &&
                  newOrderItem.deliveryDate__c > newOrderItem.estimatedDeliveryDate__c && newOrderItem.Order.maxDeliveryDate__c < date.today()) 
                {
                    Case caseTocreate = new Case(RecordTypeId = RT_PNC_PROVIDERID, OwnerId = newOrderItem.Order.OwnerId, Status = 'Nouveau', AccountId = newOrderItem.orderAccountId__c,
                                                    ContactId = newOrderItem.orderContactId__c, AssetId = newOrderItem.asset__c, Chantier__c = newOrderItem.orderChantierId__c, 
                                                    ProductId = newOrderItem.Product2Id, entity__c = newOrderItem.Order.salesEntity__c, customerOrder__c = newOrderItem.OrderId, Type = 'Produit',
                                                    motif__c = 'Délais non respectés', responsability__c = 'Fabrication', Priority = 'Moyen', providerOrderItem__c = newOrderItem.Id);
                                                    
                    listCaseToInsert.add(caseTocreate);
                }
            }

            // Ligne parent
            if (Trigger.isBefore && Trigger.isUpdate && oldOrderItem != null && oldOrderItem.SBQQ__RequiredBy__c != newOrderItem.SBQQ__RequiredBy__c) {                 
                System.debug('## MAJ Parent OrderItem : ' + newOrderItem.SBQQ__RequiredBy__c);
                newOrderItem.parentOrderItem__c = newOrderItem.SBQQ__RequiredBy__c;
            }
            
            // Alimentation des données OrderItem SAV
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newOrderItem.SBQQ__QuoteLine__c) &&
                newOrderItem.orderType__c.contains('SAV') && qliCPQMap.get(newOrderItem.SBQQ__QuoteLine__c) != null)
            {
                SBQQ__QuoteLine__c qli = qliCPQMap.get(newOrderItem.SBQQ__QuoteLine__c);
                System.debug('### orderType :' + newOrderItem.orderType__c);
                System.debug('### orderType :' + newOrderItem.orderType__c.contains('SAV'));
                System.debug('### newOrderItem.SBQQ__QuoteLine__c :' + newOrderItem.SBQQ__QuoteLine__c);
                System.debug('### newOrderItem.productType__c :' + newOrderItem.productType__c);
                System.debug('### qliCPQMap.get(newOrderItem.SBQQ__QuoteLine__c) :' + qliCPQMap.get(newOrderItem.SBQQ__QuoteLine__c));

                // Menuiserie
                if(newOrderItem.productType__c=='Carpentry'){
                    System.debug('#### qli.caseItem__r.case__r.ProductId:' + qli.caseItem__r.case__r.ProductId);
                    newOrderItem.Product2Id=qli.caseItem__r.case__r.ProductId;
                }
                //Composant
                if(newOrderItem.productType__c=='Component'){
                    newOrderItem.caseItem__c=qli.caseItem__c;
                    System.debug('#### qli.caseItem__c:' + qli.caseItem__c);
                }
            }
        }
        
        if(!listCaseToInsert.isEmpty()) {
            insert listCaseToInsert;
        }
        System.debug('### FIN TR020_OrderItem : applyDataUpdateRules');
    }

    /**
    * @description Méthode exécutant les règles de mise à jour de données pour les lignes de commande legacy (GC)
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyLegacyUpdateRules(UserContext userContext) {
        System.debug('### DEBUT TR020_OrderItem : applyLegacyUpdateRules');
        
        List<OrderItem> newOrderItems = new List<OrderItem>();
        Map<Id, OrderItem> oldOrderItems = (Map<Id, OrderItem>)Trigger.oldMap;
        List<String> pliList = new List<String>();
        Map<String, PricebookEntry> pliMap = new Map<String, PricebookEntry>();
        
        // A - Initialisation des données intermédiaires 
        for (OrderItem newOrderItem : (List<OrderItem>)Trigger.new) {
            // LEGACY - Création d'une ligne de commande pour alimenter PriceBookEntry
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newOrderItem.legacyReference__c) && String.isNotBlank(newOrderItem.Product2Id)) 
            {
                newOrderItems.add(newOrderItem);
                pliList.add(newOrderItem.Product2Id);
            }
        }       

        // B - Récupération des enregistrements
        if(!pliList.isEmpty()) {
            for (PricebookEntry pli : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN :pliList]) {
                pliMap.put(pli.Product2Id, pli);
            }
            System.debug('## pliMap: ' + pliMap);
        }

        System.debug('## newOrderItems: ' + newOrderItems);

        for (OrderItem newOrderItem : newOrderItems) {
            OrderItem oldOrderItem = oldOrderItems == null ? null : oldOrderItems.get(newOrderItem.Id);
       
            // LEGACY - Alimentation PricebookEntry     
            if(Trigger.isInsert && Trigger.isBefore && String.isNotBlank(newOrderItem.legacyReference__c) && pliMap.get(newOrderItem.Product2Id) != null) {
                newOrderItem.PricebookEntryId = pliMap.get(newOrderItem.Product2Id).Id;
                newOrderItem.ListPrice = pliMap.get(newOrderItem.Product2Id).UnitPrice;
            }
            // LEGACY - Alimentation UnitPrice pour OrderItem Provider  
            if(Trigger.isInsert && Trigger.isBefore && newOrderItem.orderRecordType__c == 'ProviderOrder') {
                newOrderItem.UnitPrice = 1;
            }
        }
        System.debug('### FIN TR020_OrderItem : applyLegacyUpdateRules');
    }
}