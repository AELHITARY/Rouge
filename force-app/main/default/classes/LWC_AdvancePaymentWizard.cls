//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_AdvancePaymentWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 19/10/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_AdvancePaymentWizard {
    
    /**
    * @description Récupération de la liste des commandes client
    * @param recordId Id de l'enregistrement
    * @param isOrgFin True si l'assistant est sur un organisme de financement
    * @return Liste des commandes
    */
    @AuraEnabled(cacheable = true)
    public static List<Order> getCustomerOrders(String recordId, Boolean isOrgFin, String bankAccountId, Date pieceDate){
       System.debug('### DEBUT LWC_AdvancePaymentWizard.getCustomerOrders'); 
       System.debug('## recordId: '+recordId); 
       System.debug('## isOrgFin: '+isOrgFin); 
       System.debug('## bankAccountId : '+ bankAccountId);
       System.debug('## pieceDate : '+ pieceDate);
       List<Order> result = new List<Order>();
       List<Order> ordersList = new List<Order>();

        try {
            if(String.isNotBlank(recordId)) {  
                String orderRTId = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER); 
                if(isOrgFin) {
                    ordersList = [SELECT  Id, Name, OrderNumber, AccountId, ActivatedDate, amount__c, expectedAdvancePaymentAmount__c, shippingCost__c, Type, isLegacy__c, legacyStatus__c,
                                        advancePaymentAmount1__c , advancePaymentAmount2__c, receivedAdvancePaymentAmount__c, billingName__c, toLabel(Status)
                                    FROM Order 
                                    WHERE RecordTypeId = :orderRTId AND financingMethod__r.fundingAgency__c = :recordId
                                    AND Status != :Constants.ORDER_STATUS_CANCELLED AND Status != :Constants.ORDER_STATUS_CLOSED
                                    AND Type != 'Avenant' 
                                    AND ActivatedDate >= 2002-01-01T00:00:00.000+0000
                                    AND isAdvPaymAmountSumInfAdvPaymentAmountSum__c = true
                                    AND serviceEntity__c IN (SELECT entity__c FROM BankAccountVisibility__c WHERE bankAccount__c =:bankAccountId 
                                    AND startDate__c <= :pieceDate AND (endDate__c = null OR endDate__c >= :pieceDate))
                                    AND ((isLegacy__c = false) 
                                        OR (isLegacy__c = true 
                                            AND legacyStatus__c != 'Résilié' 
                                            AND legacyStatus__c != 'Soldé'
                                            AND legacyStatus__c != 'Soldé NC'
                                            AND legacyStatus__c != 'En SAV depuis le'))
                                    ORDER BY OrderNumber];
                } else {
                    ordersList = [SELECT  Id, Name, OrderNumber, ActivatedDate, amount__c, expectedAdvancePaymentAmount__c, shippingCost__c,
                                        advancePaymentAmount1__c , advancePaymentAmount2__c, receivedAdvancePaymentAmount__c, billingName__c, toLabel(Status)
                                    FROM Order 
                                    WHERE RecordTypeId = :orderRTId AND AccountId = :recordId
                                    AND Status != :Constants.ORDER_STATUS_CANCELLED AND Status != :Constants.ORDER_STATUS_CLOSED
                                    AND serviceEntity__c IN (SELECT entity__c FROM BankAccountVisibility__c WHERE bankAccount__c =:bankAccountId 
                                    AND startDate__c <= :pieceDate AND (endDate__c = null OR endDate__c >= :pieceDate))
                                    AND isAdvPaymAmountSumInfAdvPaymentAmountSum__c = true ORDER BY OrderNumber];
                }
                for(Order ord : ordersList) {   
                    // Modification des champs pour affichage
                    System.debug('## Order: '+ord.Id); 
                    System.debug('## receivedAdvancePaymentAmount__c: '+ord.receivedAdvancePaymentAmount__c); 
                    System.debug('## expectedAdvancePaymentAmount__c: '+ord.expectedAdvancePaymentAmount__c); 
                    Decimal advAmount = (ord.receivedAdvancePaymentAmount__c == null) ? 0 : ord.receivedAdvancePaymentAmount__c;
                    Decimal montantaEnCaisser = (ord.shippingCost__c == null || ord.shippingCost__c != 0) ? 0 : ord.shippingCost__c;
                    System.debug('## advAmount: '+advAmount); 
                    ord.advancePaymentAmount1__c = advAmount;
                    ord.shippingCost__c = montantaEnCaisser;
                    ord.shippingCost__c = ord.expectedAdvancePaymentAmount__c - advAmount;  // Utilisation du champ temp pour définir l'acompte à percevoir  
                    result.add(ord);   
                }          
            }
            System.debug('## result: '+result); 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.getCustomerOrders'); 
        return result;
    }
    
    /**
    * @description Récupération de la bankAccountId
    * @param inputEntityId Id de l'entité
    * @param pieceDate date de la piece
    * @return bankAccountId
    */
    @AuraEnabled(cacheable = true)
    public static String getBankAccount(String inputEntityId, Date pieceDate) {
        System.debug('### DEBUT LWC_AdvancePaymentWizard.getBankAccount'); 
        System.debug('## inputEntityId: '+inputEntityId);
        System.debug('## pieceDate: '+pieceDate);
        String bankAccId = null;
        Integer nbBankAccount = 0;
        String bankAccountId;
        
        for(BankAccountVisibility__c bkvisibility : [SELECT Id, startDate__c, endDate__c, bankAccount__c, entity__c, bankAccount__r.Name 
                                                        FROM BankAccountVisibility__c WHERE entity__c =: inputEntityId 
                                                        AND startDate__c <= :pieceDate AND (endDate__c > :pieceDate OR endDate__c = null)]) 
        {
            nbBankAccount++;        
            bankAccountId = bkvisibility.bankAccount__c;   
            System.debug('## Potential bankAccountId: '+bankAccountId);
        }                    
        // Alimentation du compte bancaire seulement s'il existe un seul compte bancaire actif                      
        if(nbBankAccount == 1) {
            System.debug('## Update bank account by order entity: '+bankAccountId);
            bankAccId = bankAccountId;
        } else if(nbBankAccount > 1) {
            bankAccId = 'MoreThanOne';
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.getBankAccount'); 
        return bankAccId;
    }  
    
    /**
    * @description Récupération de la bankAccountName
    * @param bankAccountId Id de la bank
    * @return bankAccountId
    */
    @AuraEnabled(cacheable = true)
    public static String getBankAccountName(String bankAccountId) {
        Referencial__c bankAccount = [SELECT Id, Name FROM Referencial__c WHERE id =: bankAccountId];
        String bankAccountName = bankAccount.Name;
        return bankAccountName;
    }   

    /**
    * @description Récupération de la liste des factures
    * @param recordId Id de l'enregistrement
    * @param isOrgFin True si l'assistant est sur un organisme de financement
    * @return Liste des factures
    */
    @AuraEnabled(cacheable = true)
    public static List<Invoice__c> getInvoices(String recordId, Boolean isOrgFin, String bankAccountId, Date pieceDate){
       System.debug('### DEBUT LWC_AdvancePaymentWizard.getInvoices'); 
       System.debug('## recordId: '+recordId);
       System.debug('## bankAccountId : '+ bankAccountId); 
       System.debug('## pieceDate : '+ pieceDate);
       List<Invoice__c> result = new List<Invoice__c>();
       List<Invoice__c> invoicesList = new List<Invoice__c>();

        try {
            if(String.isNotBlank(recordId)) {  
                String invoiceRTId = DAL.getRecordTypeIdByDevName('Invoice__c', Constants.INVOICE_INVOICE_RT);
                List<BankAccountVisibility__c> ServiceEntity = [SELECT entity__c FROM BankAccountVisibility__c WHERE bankAccount__c =:bankAccountId 
                AND startDate__c <= :pieceDate AND (endDate__c = null OR endDate__c >= :pieceDate)];
                System.debug('ServiceEntity '+ServiceEntity); 
                List<Id> bankVisibilityId = new List<Id>();
                //Récupération des Id des entités de service de la commande associée qui ont la visibilité sur le compte bancaire à la date de la pièce (de l'encaissement composite) 
                for (BankAccountVisibility__c bankVisibility : ServiceEntity) {
                    bankVisibilityId.add(bankVisibility.entity__c);
                }
                System.debug('bankVisibilityId '+bankVisibilityId);
                if(isOrgFin) {
                    invoicesList = [SELECT  Id, Name, customerOrderNumber__c, invoiceReference__c, invoiceDate__c, 
                                        toPerceiveAmount__c , perceivedAmount__c, customerOrder__c, cancellationDate__c, isLegacy__c, 
                                        customerOrder__r.legacyStatus__c, customerOrder__r.netBalance__c,amount__c,priceReduction__c, billingAccount__c
                                    FROM Invoice__c 
                                    WHERE RecordTypeId = :invoiceRTId AND customerOrder__r.financingMethod__r.fundingAgency__c = :recordId
                                    AND invoiceReference__c != null AND invoiceDate__c >= 2022-01-01
                                    AND paymentDate__c = null AND toPerceiveAmount__c > 0
                                    AND cancellationDate__c = null
                                    AND (customerOrder__r.netBalance__c < -0.03 OR customerOrder__r.netBalance__c > 0.03)
                                    AND ((isLegacy__c = false) 
                                        OR (isLegacy__c = true AND customerOrder__r.legacyStatus__c != 'Résilié' 
                                                                AND customerOrder__r.legacyStatus__c != 'Soldé'
                                                                AND customerOrder__r.legacyStatus__c != 'Soldé NC'
                                                                AND customerOrder__r.legacyStatus__c != 'En SAV depuis le'))];
                } else {
                    invoicesList = [SELECT  Id, Name, customerOrderNumber__c, invoiceReference__c, invoiceDate__c, 
                                        toPerceiveAmount__c , perceivedAmount__c, customerOrder__c,amount__c,priceReduction__c  
                                    FROM Invoice__c 
                                    WHERE RecordTypeId = :invoiceRTId AND billingAccount__c = :recordId
                                    AND customerOrder__r.serviceEntity__c IN :bankVisibilityId
                                    AND invoiceReference__c != null AND paymentDate__c = null AND toPerceiveAmount__c > 0];
                                    System.debug('invoicesList '+invoicesList);  
                }
                for(Invoice__c inv : invoicesList) {
                    System.debug('## Montant à encaisser: '+inv.priceReduction__c);  
                    Decimal perceivedAmount = (inv.perceivedAmount__c == null) ? 0 : inv.perceivedAmount__c;
                    Decimal priceReduction = (inv.priceReduction__c == null|| inv.priceReduction__c != 0 ) ? 0 : inv.priceReduction__c;
                    inv.perceivedAmount__c = perceivedAmount;
                    System.debug('## Montant deja percu: '+inv.perceivedAmount__c ); 
                    inv.priceReduction__c = priceReduction;                 
                    inv.priceReduction__c = inv.toPerceiveAmount__c - perceivedAmount; // Champ utiliser pour capturer la valeur de Montant à encaisser 
                    System.debug('## Montant à encaisser: '+inv.priceReduction__c); 
                    result.add(inv);   
                }          
            }
            System.debug('## result: '+result); 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.getInvoices'); 
        return result;
    }

    /**
    * @description Récupération du mode de réglement par défaut
    * @param isOrgFin True si l'assistant est sur un organisme de financement
    * @return Mode de réglement par défaut
    */
    @AuraEnabled(cacheable = true)
    public static Referencial__c getDefaultPaymentMethod(Boolean isOrgFin){
       System.debug('### DEBUT LWC_AdvancePaymentWizard.getDefaultPaymentMethod'); 
       Referencial__c result = null;
       String refDefaultValue = null;

        try {
            if(isOrgFin) {
                refDefaultValue = PropertiesUtils.getStringValue('ref.paymentMethodBankTransfer.code', 'PAY-0012');
            } else {
                refDefaultValue = PropertiesUtils.getStringValue('ref.paymentMethodBankCheck.code', 'PAY-0004');
            }
            String refRTId = DAL.getRecordTypeIdByDevName('Referencial__c', 'PaymentMethod'); 
            for(Referencial__c ref : [SELECT  Id, Name, requiredExternalBankAccount__c, minPayableAmount__c, maxPayableAmount__c
                                        FROM Referencial__c 
                                        WHERE RecordTypeId = :refRTId AND KparKReference__c = :refDefaultValue LIMIT 1]) {     
                result = ref;
            }  
            System.debug('## result: '+result); 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.getDefaultPaymentMethod'); 
        return result;
    }

    /**
    * @description Récupération des infos du mode de réglement
    * @return Mode de réglement par défaut
    */
    @AuraEnabled(cacheable = true)
    public static Referencial__c getPaymentMethodInfos(String recordId){
       System.debug('### DEBUT LWC_AdvancePaymentWizard.getPaymentMethodInfos'); 
       Referencial__c result = null;

        try {
            for(Referencial__c ref : [SELECT  Id, Name, requiredExternalBankAccount__c, minPayableAmount__c, maxPayableAmount__c
                                        FROM Referencial__c WHERE Id = :recordId LIMIT 1]) {     
                result = ref;
            }  
            System.debug('## result: '+result); 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.getPaymentMethodInfos'); 
        return result;
    }

    /**
    * @description Création des pièces comptables
    * @return Ok si pas d'erreur
    */
    @AuraEnabled
    public static String createAccountingPieces(String recordId, String inputEntityId, Boolean isOrgFin, String bankAccountId, Date pieceDate, Date accountingDate, Decimal amount,
                                                String paymentMethodId, String externalBank, String externalReference, List<Order> customerOrdersData, List<Invoice__c> invoicesData) {
        System.debug('### DEBUT LWC_AdvancePaymentWizard.createAccountingPieces'); 
        System.debug('## recordId: '+ recordId);
        System.debug('## inputEntityId: '+ inputEntityId);
        System.debug('## bankAccountId: '+ bankAccountId);
        System.debug('## pieceDate: '+ pieceDate);
        System.debug('## accountingDate: '+ accountingDate);
        System.debug('## amount: '+ amount);
        System.debug('## paymentMethodId: '+ paymentMethodId);
        System.debug('## externalBank: '+ externalBank);
        System.debug('## externalReference: '+ externalReference);
        System.debug('## customerOrdersData: '+ customerOrdersData);
        System.debug('## invoicesData: '+ invoicesData);
        
        String result = null; 
        List<AccountingPiece__c> piecesToIns = new List<AccountingPiece__c>();
        List<Order> ordToUp = new List<Order>();
        List<Invoice__c> invToUp = new List<Invoice__c>();
        List<BankAccountVisibility__c> listbankAcc = new List<BankAccountVisibility__c>();

        Savepoint sp = Database.setSavepoint();

        try{
            
            if(String.isNotBlank(recordId)){
                String RT_AP_RECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_RECEIPT_RT);
                String RT_AP_COMPOSITERECEIPT = DAL.getRecordTypeIdByDevName('AccountingPiece__c',Constants.ACCOUNTINGPIECE_COMPOSITERECEIPT_RT);

                // Création encaissement composite
                AccountingPiece__c compPiece = new AccountingPiece__c();
                compPiece.RecordTypeId = RT_AP_COMPOSITERECEIPT;
                compPiece.account__c = recordId;
                compPiece.inputEntity__c = inputEntityId;
                compPiece.entityBankAccount__c = bankAccountId;
                compPiece.pieceDate__c = pieceDate;
                compPiece.dueDate__c = (accountingDate == null) ? pieceDate : accountingDate;
                compPiece.paymentMethod__c = paymentMethodId;
                compPiece.amount__c = amount;
                compPiece.externalBank__c = externalBank;
                compPiece.externalReference__c = externalReference;
                insert compPiece;
                System.debug('## blocked: '+compPiece.isAccountingPieceLocked__c);
                System.debug('## Composite Receipt: '+ compPiece);

                // Création des pièces par commande/acomptes
                for(Order newOrder : customerOrdersData) {
                    System.debug('## Receipt for Order: '+ newOrder.Id+' / '+newOrder.shippingCost__c);
                    if(newOrder.shippingCost__c != null && newOrder.shippingCost__c != 0) {
                        // Création encaissement 
                        AccountingPiece__c childPiece = new AccountingPiece__c();
                        childPiece.RecordTypeId = RT_AP_RECEIPT;
                        childPiece.parent__c = compPiece.Id;
                        childPiece.order__c = newOrder.Id;
                        childPiece.inputEntity__c = inputEntityId;
                        childPiece.entityBankAccount__c = bankAccountId;
                        childPiece.pieceDate__c = pieceDate;
                        childPiece.dueDate__c = compPiece.dueDate__c;
                        childPiece.paymentMethod__c = paymentMethodId;
                        childPiece.amount__c = newOrder.shippingCost__c; // stocké le montant a encaisser sur la pièce comptable
                        childPiece.externalBank__c = externalBank;
                        childPiece.externalReference__c = externalReference;
                        childPiece.accountingDate__c =accountingDate;
                        if (isOrgFin) {                            
                            childPiece.account__c = newOrder.AccountId;
                        } else {
                            childPiece.account__c = recordId;
                        }
                        piecesToIns.add(childPiece);
                        // Mise à jour commande
                        //ordToUp.add(new Order(Id = newOrder.Id, receivedAdvancePaymentAmount__c=newOrder.shippingCost__c));
                        System.debug('## newOrder: '+ ordToUp);
                        System.debug('## Receipt: '+ childPiece);
                    }
                }

                // Création des pièces par factures
                for(Invoice__c newInvoice : invoicesData) {
                    System.debug('## Receipt for Invoice: '+ newInvoice.Id+' / '+newInvoice.perceivedAmount__c);
                    if(newInvoice.priceReduction__c != null && newInvoice.priceReduction__c != 0) {
                        // Création encaissement 
                        AccountingPiece__c childPiece = new AccountingPiece__c();
                        childPiece.RecordTypeId = RT_AP_RECEIPT;
                        childPiece.parent__c = compPiece.Id;
                        childPiece.invoice__c = newInvoice.Id;
                        childPiece.order__c = newInvoice.customerOrder__c;
                        childPiece.inputEntity__c = inputEntityId;
                        childPiece.entityBankAccount__c = bankAccountId;
                        childPiece.pieceDate__c = pieceDate;
                        childPiece.dueDate__c = compPiece.dueDate__c;
                        childPiece.paymentMethod__c = paymentMethodId;
                        childPiece.amount__c = newInvoice.priceReduction__c;
                        childPiece.externalBank__c = externalBank;
                        childPiece.externalReference__c = externalReference;
                        childPiece.accountingDate__c =accountingDate; 
                        if (isOrgFin) {                            
                            childPiece.account__c = newInvoice.billingAccount__c;
                        } else {
                            childPiece.account__c = recordId;
                        }
                        piecesToIns.add(childPiece);
                        // Mise à jour facture
                        //invToUp.add(new Invoice__c(Id = newInvoice.Id, perceivedAmount__c=newInvoice.priceReduction__c));
                        System.debug('## Receipt: '+ childPiece);
                    }
                }     
                // Insertion et alimentation des dates comtables sur les pieces comptables;
                if(!piecesToIns.isEmpty()) {
                    insert piecesToIns;                
                }
                //update des dates comptables sur la pièce parent
                AccountingPiece__c parentpiece = [SELECT Id,accountingDate__c FROM AccountingPiece__c WHERE Id = :compPiece.Id LIMIT 1];
                parentpiece.accountingDate__c = accountingDate;
                update parentpiece; 
                
                /*// MAJ des commandes 
                if(!ordToUp.isEmpty()) {
                    update ordToUp;
                    System.debug('## newOrderUpdate: '+ ordToUp);
                }
                // MAJ des factures
                if(!invToUp.isEmpty()) {
                    update invToUp;
                    System.debug('## newInvoiceUpdate: '+ invToUp);
                } */
                result = 'OK';
            }
        }
        catch(Exception e) {
            Database.rollback(sp); // Rollback des modifications
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.createAccountingPieces');
        return result;
         
    }

    /**
    * @description Mise à jour de la liste des commandes avec les nouvelles valeurs
    * @param newValues Nouvelles valeurs issues de draftValues à mettre à jour dans les orders actuels
    * @param ordersData Liste des orders actuel
    */
    @AuraEnabled
    public static List<Order> updateDatatableOrders(List<Map<String,String>> newValues, List<Order> ordersData){
        System.debug('### DEBUT LWC_AdvancePaymentWizard.updateDatatableOrders');
        System.debug('## newValues: '+newValues);
        System.debug('## ordersData: '+ordersData);
        List<Order> result = new List<Order>();
        List<Order> arrangedResult = new List<Order>();
        Map<String,Order> ordersMap = new Map<String,Order>();

        try{
            // Liste des Id des Orders déjà modifiés via les nouvelles valeurs
            List<String> orderIdDone = new List<String>();
            for(Order ord : ordersData){
                System.debug('## ord: '+ord.Id);
                ordersMap.put(String.valueOf(ord.Id),ord);
            }

            // Mise à jour des données avec les nouvelles valeurs
            for(Map<String,String> newOrderValues : newValues){
                System.debug('## newOrderValues: '+newOrderValues);
                Order order = ordersMap.get(newOrderValues.get('Id'));
                orderIdDone.add(newOrderValues.get('Id'));

                if(newOrderValues.containsKey('shippingCost__c')) {
                    order.shippingCost__c = String.isNotBlank(newOrderValues.get('shippingCost__c')) ? Decimal.valueOf(newOrderValues.get('shippingCost__c')) : null;
                    System.debug('## order.shippingCost__c : '+order.shippingCost__c);
                }
                System.debug('## Add Order to list: '+order.Id);
                result.add(order);
            }

            //Ajout des orders qui n'ont pas été modifiée
            for(String orderId : ordersMap.keySet()){
                if(!orderIdDone.contains(orderId)){
                    result.add(ordersMap.get(orderId));
                }
            }
            System.debug('## result: '+result);
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.updateDatatableOrders');
        return result;
    }

    /**
    * @description Mise à jour de la liste des factures avec les nouvelles valeurs
    * @param newValues Nouvelles valeurs issues de draftValues à mettre à jour dans les factures actuels
    * @param invoicesData Liste des factures actuel
    */
    @AuraEnabled
    public static List<Invoice__c> updateDatatableInvoices(List<Map<String,String>> newValues, List<Invoice__c> invoicesData){
        System.debug('### DEBUT LWC_AdvancePaymentWizard.updateDatatableInvoices');
        List<Invoice__c> result = new List<Invoice__c>();
        List<Invoice__c> arrangedResult = new List<Invoice__c>();
        Map<String,Invoice__c> invoicesMap = new Map<String,Invoice__c>();

        try{
            // Liste des Id des factures déjà modifiés via les nouvelles valeurs
            List<String> invIdDone = new List<String>();
            for(Invoice__c inv : invoicesData){
                System.debug('## Invoice: '+inv.Id);
                invoicesMap.put(String.valueOf(inv.Id),inv);
            }

            // Mise à jour des données avec les nouvelles valeurs
            for(Map<String,String> newInvoiceValues : newValues){
                Invoice__c inv = invoicesMap.get(newInvoiceValues.get('Id'));
                invIdDone.add(newInvoiceValues.get('Id'));

                if(newInvoiceValues.containsKey('priceReduction__c')) {
                    inv.priceReduction__c = String.isNotBlank(newInvoiceValues.get('priceReduction__c')) ? Decimal.valueOf(newInvoiceValues.get('priceReduction__c')) : null;
                    System.debug('## inv.priceReduction__c : '+inv.priceReduction__c); // Montant à encaisser saisie sur la facture
                }   
                System.debug('## Add Invoice to list: '+inv.Id);
                result.add(inv);
            }

            //Ajout des factures qui n'ont pas été modifiée
            for(String invoiceId : invoicesMap.keySet()){
                if(!invIdDone.contains(invoiceId)){
                    result.add(invoicesMap.get(invoiceId));
                }
            }
            System.debug('## result: '+result);
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_AdvancePaymentWizard.updateDatatableInvoices');
        return result;
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
    
    /**
    * @description Vérification de la visibilité de compte bancaire saisi par l'entité saisie à la date de la pièce.
    * @param inputEntityId Id d'entité saisie
    * @param bankAccountId Id du compte bancaire saisie
    * @param pieceDate la date de la pièce
    * @return boolean si une visibilité existe ou non.
    */
    @AuraEnabled(cacheable = true)
    public static Boolean getVisibilityVerification(String inputEntityId, String bankAccountId, Date pieceDate) {
        System.debug('### DEBUT LWC_AdvancePaymentWizard.getVisibilityVerification');
        System.debug('inputEntityId : '+ inputEntityId);
        System.debug('bankAccountId : '+ bankAccountId);
        System.debug('pieceDate : '+ pieceDate);
        Boolean result;
        String permissionSetName = 'BypassBankVisibility_EndDate';
        List<BankAccountVisibility__c> visibilityList = new List<BankAccountVisibility__c>();
        List<PermissionSetAssignment> permissionAssignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                                                                AND PermissionSet.Name  =:permissionSetName LIMIT 1];
        System.debug('permissionAssignmentExist : '+ !permissionAssignments.isEmpty());
        try { 
            if (inputEntityId != null && bankAccountId != null) {
                if (!permissionAssignments.isEmpty()) {
                    visibilityList =[SELECT Id, entity__c,bankAccount__c, startDate__c, endDate__c 
                                    FROM BankAccountVisibility__c 
                                    WHERE bankAccount__c =:bankAccountId AND entity__c =:inputEntityId
                                    AND startDate__c <= :pieceDate];
                    System.debug('visibilityList : '+ visibilityList);
                }            
                else {
                    visibilityList =[SELECT Id, entity__c,bankAccount__c, startDate__c, endDate__c 
                                    FROM BankAccountVisibility__c 
                                    WHERE bankAccount__c =:bankAccountId AND entity__c =:inputEntityId
                                    AND startDate__c <= :pieceDate AND (endDate__c = null OR endDate__c >= :pieceDate)];
                    System.debug('visibilityList : '+ visibilityList);                
                }
                if (!visibilityList.isEmpty()) {
                    result = true;
                }else {
                    result = false;
                }                
            }
            System.debug('## result: '+result); 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }      
        System.debug('### FIN LWC_AdvancePaymentWizard.getVisibilityVerification');
        return result;
    } 
}